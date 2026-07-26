# Pull the WASH-matched work lists for the three whole-journal venues from
# issues #32-#34, so the scraped datasets can carry a per-article
# wash_matched flag (decision recorded on the issues, 2026-07-24).
#
# A work is "matched" when it passes the same title_and_abstract.search
# filter the #18 venue mapping used, restricted to the journal's OpenAlex
# source ID and the 1996-2026 window. The scraped articles are joined on DOI
# against these lists in data_processing.R; articles absent from the list
# are the journal's non-WASH complement.
#
# IWA renamed AQUA and Water Supply, so era_check() first searches the
# sources index for the historical titles to catch split source IDs. The
# known IDs cover 1996-2026 work counts consistent with
# journal_wash_share.csv, so a split would show up as a second source with a
# large work count; add it to SOURCES if one appears.
#
# All requests are cheap list calls (~30 total). The per-source cache makes
# reruns free; delete cache/matched_*.rds to force a refresh.
#
# Run from the package root:
#   Rscript data-raw/washbiblio/pull_matched_works.R

library(httr)
library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(tibble)

DIR <- "data-raw/washbiblio"
CACHE <- file.path(DIR, "cache")
MAILTO <- "lars@lse.de"
API_KEY <- Sys.getenv("OPENALEX_API_KEY")
FROM <- "1996-01-01"
TO <- "2026-12-31"

SOURCES <- list(
  jwh = "S26443501",
  aqua = "S4210228842",
  ws = "S124453322"
)

keywords <- read_csv(file.path(DIR, "wash-keywords.csv"), show_col_types = FALSE)
search_string <- keywords$keyword |>
  (\(k) ifelse(grepl(" ", k), paste0('"', k, '"'), k))() |>
  paste(collapse = " OR ")

oa_get <- function(url, query) {
  query$mailto <- MAILTO
  if (nzchar(API_KEY)) query$api_key <- API_KEY
  for (i in 1:4) {
    resp <- GET(url, query = query, timeout(120))
    if (status_code(resp) != 429) break
    wait <- c(5, 15, 60)[min(i, 3)]
    message("  429, retrying in ", wait, "s")
    Sys.sleep(wait)
  }
  stop_for_status(resp)
  content(resp, as = "parsed", type = "application/json")
}

#' Cursor-page every work for one source that matches the WASH search in
#' the study window. Returns tibble(work_id, doi, title, publication_year).
pull_matched <- function(source_id) {
  filter <- paste(c(
    paste0("primary_location.source.id:", source_id),
    paste0("title_and_abstract.search:", search_string),
    paste0("from_publication_date:", FROM),
    paste0("to_publication_date:", TO)
  ), collapse = ",")
  cursor <- "*"
  pages <- list()
  repeat {
    body <- oa_get("https://api.openalex.org/works", list(
      filter = filter,
      select = "id,doi,title,publication_year",
      `per-page` = 200,
      cursor = cursor
    ))
    pages <- c(pages, list(map_dfr(body$results, \(w) tibble(
      work_id = sub("https://openalex.org/", "", w$id, fixed = TRUE),
      doi = w$doi %||% NA_character_,
      title = w$title %||% NA_character_,
      publication_year = w$publication_year %||% NA_integer_
    ))))
    cursor <- body$meta$next_cursor
    message("  ", sum(map_int(pages, nrow)), " / ", body$meta$count, " works")
    if (is.null(cursor) || length(body$results) == 0) break
  }
  list_rbind(pages)
}

cached <- function(name, fn) {
  path <- file.path(CACHE, paste0(name, ".rds"))
  if (file.exists(path)) return(readRDS(path))
  result <- fn()
  saveRDS(result, path)
  result
}

#' Search the sources index for historical journal titles and report
#' candidates, so a rename split into a second source ID is caught.
era_check <- function() {
  historical <- c(
    "Journal of Water Supply: Research and Technology",
    "Water Science and Technology: Water Supply"
  )
  for (title in historical) {
    body <- oa_get("https://api.openalex.org/sources", list(
      search = title, `per-page` = 10
    ))
    message("Source candidates for '", title, "':")
    walk(body$results, \(s) message(
      "  ", sub("https://openalex.org/", "", s$id, fixed = TRUE),
      "  works=", s$works_count, "  ", s$display_name
    ))
  }
}

era_check()

for (slug in names(SOURCES)) {
  message("Pulling matched works for ", slug, " (", SOURCES[[slug]], ") ...")
  matched <- cached(paste0("matched_", slug), \() pull_matched(SOURCES[[slug]]))
  out <- file.path(DIR, paste0("matched-works-", slug, ".csv"))
  write_csv(matched, out)
  message("  wrote ", nrow(matched), " rows to ", out)
}
