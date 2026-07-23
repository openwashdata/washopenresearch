# Backfill the doi column for legacy washdev and uncnewsletter rows via
# Crossref (issue #20). The R washdev scraper collects doi for newly scraped
# rows, but 932 legacy washdev rows and all uncnewsletter rows have none.
# ploswater has doi natively and is not touched here.
#
# Run from the package root:
#   Rscript data-raw/backfill_dois.R
#
# Requires network access to api.crossref.org. Outputs two committed files that
# data_processing.R reads back in, so the backfill is reproducible and any
# ambiguous match is visible in git rather than hidden in a hand-edit:
#   data-raw/washdev-doi-backfill.csv       (paperid, doi)
#   data-raw/uncnewsletter-doi-backfill.csv (paperid, doi)
# plus review files for rows that did not match, for manual follow-up:
#   data-raw/washdev-doi-review.csv
#   data-raw/uncnewsletter-doi-review.csv

library(dplyr)
library(stringr)
library(purrr)
library(readr)
library(rcrossref)

# Normalise a title for matching: lowercase, strip punctuation and whitespace.
# Crossref and the scraper differ on punctuation, casing, and trailing spaces,
# so comparison is on this reduced form, not the display title.
norm_title <- function(x) {
  x |>
    str_to_lower() |>
    str_replace_all("&", " and ") |>
    str_replace_all("[^a-z0-9]+", " ") |>
    str_squish()
}

# --- washdev: match by volume + issue + normalised title --------------------
# The journal has two ISSNs over its history (2043-9083, 2408-9362); query both
# and union. One paginated fetch per ISSN, then a local join.

message("Fetching washdev works from Crossref ...")
washdev_issns <- c("2043-9083", "2408-9362")

fetch_journal <- function(issn) {
  out <- tryCatch(
    cr_journals(issn = issn, works = TRUE, cursor = "*",
                cursor_max = 5000, limit = 1000),
    error = function(e) {
      warning("Crossref fetch failed for ", issn, ": ", conditionMessage(e))
      NULL
    }
  )
  works <- pluck(out, "data")
  if (is.null(works) || nrow(works) == 0) return(NULL)
  works |>
    filter(!is.na(volume), !is.na(issue), !is.na(title)) |>
    transmute(
      cr_doi = str_to_lower(doi),
      volume = suppressWarnings(as.integer(volume)),
      issue = str_extract(issue, "^[0-9]+") |> as.integer(),
      title_key = norm_title(title)
    )
}

cr_washdev <- map_dfr(washdev_issns, fetch_journal) |>
  filter(str_detect(cr_doi, "10\\.2166/washdev")) |>
  distinct(volume, issue, title_key, .keep_all = TRUE)

message("  ", nrow(cr_washdev), " washdev works with volume+issue+title from Crossref")

load("data/washdev.rda")
washdev_todo <- washdev |>
  filter(is.na(doi)) |>
  transmute(paperid, volume, issue = as.integer(issue),
            title_key = norm_title(title))

washdev_matched <- washdev_todo |>
  left_join(cr_washdev, by = c("volume", "issue", "title_key")) |>
  select(paperid, doi = cr_doi)

washdev_backfill <- washdev_matched |> filter(!is.na(doi))
washdev_review <- washdev |>
  semi_join(washdev_matched |> filter(is.na(doi)), by = "paperid") |>
  select(paperid, volume, issue, title)

write_csv(washdev_backfill, "data-raw/washdev-doi-backfill.csv")
write_csv(washdev_review, "data-raw/washdev-doi-review.csv")
message("washdev: ", nrow(washdev_backfill), " matched, ",
        nrow(washdev_review), " left for review (data-raw/washdev-doi-review.csv)")

# --- uncnewsletter: match by per-row title search ---------------------------
# uncnewsletter papers span many journals, so there is no single ISSN to fetch.
# Query Crossref per row with a bibliographic title search and accept the top
# hit only when its normalised title is a close match, to avoid false DOIs.

load("data/uncnewsletter.rda")

# Similarity on normalised titles via character 3-grams (Jaccard). A high
# threshold keeps a wrong top-hit from being accepted as a DOI.
trigrams <- function(s) {
  s <- str_remove_all(s, " ")
  if (nchar(s) < 3) return(s)
  vapply(1:(nchar(s) - 2), function(i) substr(s, i, i + 2), character(1))
}
title_similarity <- function(a, b) {
  ga <- unique(trigrams(a)); gb <- unique(trigrams(b))
  if (length(ga) == 0 || length(gb) == 0) return(0)
  length(intersect(ga, gb)) / length(union(ga, gb))
}
SIM_THRESHOLD <- 0.6

# Note: the bibliographic query must be passed via flq as a named field, not as
# a direct cr_works(query.bibliographic=) argument, which silently returns
# unrelated results. Fetch a few candidates and keep the best title match,
# preferring a journal article over a preprint version of the same work.
lookup_doi <- function(query_title) {
  # Crossref intermittently answers 429 even at polite spacing; without a
  # retry those rows land in the review file as false "no hit"s.
  hits <- NULL
  for (attempt in 1:3) {
    Sys.sleep(0.5 * attempt)
    hits <- tryCatch(
      cr_works(flq = c(`query.bibliographic` = query_title), limit = 5)$data,
      error = function(e) NULL
    )
    if (!is.null(hits) && nrow(hits) > 0) break
  }
  if (is.null(hits) || nrow(hits) == 0) {
    return(tibble(doi = NA_character_, sim = NA_real_))
  }
  scored <- hits |>
    filter(!is.na(title)) |>
    mutate(
      clean_title = str_replace_all(title, "<[^>]+>", ""),
      sim = vapply(clean_title,
                   function(t) title_similarity(norm_title(query_title), norm_title(t)),
                   numeric(1)),
      is_article = !is.na(type) & type == "journal-article"
    )
  if (nrow(scored) == 0) return(tibble(doi = NA_character_, sim = NA_real_))
  best <- scored |>
    arrange(desc(sim), desc(is_article)) |>
    slice(1)
  tibble(doi = str_to_lower(best$doi), sim = best$sim)
}

message("Querying Crossref for ", nrow(uncnewsletter), " uncnewsletter titles ...")
unc_results <- uncnewsletter |>
  transmute(paperid, title) |>
  mutate(res = map(title, lookup_doi)) |>
  tidyr::unnest(res)

unc_backfill <- unc_results |>
  filter(!is.na(doi), sim >= SIM_THRESHOLD) |>
  select(paperid, doi)
unc_review <- unc_results |>
  filter(is.na(doi) | sim < SIM_THRESHOLD) |>
  select(paperid, title, doi, sim)

write_csv(unc_backfill, "data-raw/uncnewsletter-doi-backfill.csv")
write_csv(unc_review, "data-raw/uncnewsletter-doi-review.csv")
message("uncnewsletter: ", nrow(unc_backfill), " matched at sim >= ",
        SIM_THRESHOLD, ", ", nrow(unc_review),
        " left for review (data-raw/uncnewsletter-doi-review.csv)")
