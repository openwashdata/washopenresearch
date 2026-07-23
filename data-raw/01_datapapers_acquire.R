# Acquire candidate WASH data papers from data journals (issue #28).
#
# Queries Crossref (by journal ISSN) and Europe PMC (for the F1000-platform
# journals, whose versioned articles have patchy Crossref coverage) with the
# WASH term list from helpers.R, unions the results, deduplicates on DOI, and
# writes the committed raw snapshot data-raw/datapapers_raw.csv.
#
# Run non-interactively from the package root:
#   Rscript data-raw/01_datapapers_acquire.R
#
# Re-running overwrites the snapshot; the git diff shows what changed since
# the last harvest. Requires network access to api.crossref.org and
# www.ebi.ac.uk (Europe PMC).

library(dplyr)
library(purrr)
library(stringr)
library(readr)
library(tidyr)
library(rcrossref)
library(europepmc)

source("data-raw/helpers.R")

journals <- datapapers_journals()
search_terms <- datapapers_search_terms()
retrieval_date <- format(Sys.Date())

# Crossref ---------------------------------------------------------------------

# One query per journal x term; Crossref relevance-ranks `query` matches, so
# a high `limit` with cursor paging retrieves the full match set for the ISSN.
query_crossref <- function(issn, journal, term_label, term) {
  message("Crossref: ", journal, " / ", term)
  res <- tryCatch(
    rcrossref::cr_works(
      filter = c(issn = issn, type = "journal-article"),
      query = term,
      cursor = "*",
      cursor_max = 10000,
      limit = 1000
    ),
    error = function(e) {
      warning("Crossref query failed for ", journal, " / ", term, ": ",
              conditionMessage(e), call. = FALSE)
      NULL
    }
  )
  works <- purrr::pluck(res, "data")
  if (is.null(works) || nrow(works) == 0) {
    return(NULL)
  }
  tibble(
    doi = works$doi,
    title = works$title,
    journal = journal,
    published_year = suppressWarnings(
      as.integer(str_sub(dplyr::coalesce(works$published.print,
                                         works$published.online,
                                         works$issued), 1, 4))
    ),
    crossref_type = works$type,
    abstract = if ("abstract" %in% names(works)) works$abstract else NA_character_,
    license = purrr::map_chr(
      if ("license" %in% names(works)) works$license else vector("list", nrow(works)),
      \(x) purrr::pluck(x, "URL", 1, .default = NA_character_)
    ),
    author = purrr::map(
      if ("author" %in% names(works)) works$author else vector("list", nrow(works)),
      identity
    ),
    relation = purrr::map(
      if ("relation" %in% names(works)) works$relation else vector("list", nrow(works)),
      identity
    ),
    query_term = term_label,
    retrieval_date = retrieval_date
  )
}

# Europe PMC -------------------------------------------------------------------

query_europepmc <- function(journal, term_label, term) {
  message("Europe PMC: ", journal, " / ", term)
  query <- sprintf('JOURNAL:"%s" AND (%s)', journal, term)
  res <- tryCatch(
    europepmc::epmc_search(query = query, limit = 10000, verbose = FALSE),
    error = function(e) {
      warning("Europe PMC query failed for ", journal, " / ", term, ": ",
              conditionMessage(e), call. = FALSE)
      NULL
    }
  )
  if (is.null(res) || nrow(res) == 0) {
    return(NULL)
  }
  tibble(
    doi = res$doi,
    title = res$title,
    journal = journal,
    published_year = suppressWarnings(as.integer(res$pubYear)),
    crossref_type = NA_character_,
    abstract = NA_character_,
    license = NA_character_,
    author_string = res$authorString,
    num_authors_epmc = purrr::map_int(
      str_split(res$authorString, ",\\s*"),
      \(x) length(x[!is.na(x) & x != ""])
    ),
    query_term = term_label,
    retrieval_date = retrieval_date
  )
}

# Harvest ----------------------------------------------------------------------

crossref_journals <- journals |> filter(api == "crossref")
epmc_journals <- journals |> filter(api == "europepmc")

crossref_raw <- purrr::pmap(
  tidyr::expand_grid(
    crossref_journals |> select(issn, journal),
    tibble(term_label = names(search_terms), term = unname(search_terms))
  ),
  \(issn, journal, term_label, term) query_crossref(issn, journal, term_label, term)
) |>
  purrr::compact() |>
  bind_rows()

epmc_raw <- purrr::pmap(
  tidyr::expand_grid(
    epmc_journals |> select(journal),
    tibble(term_label = names(search_terms), term = unname(search_terms))
  ),
  \(journal, term_label, term) query_europepmc(journal, term_label, term)
) |>
  purrr::compact() |>
  bind_rows()

# Flatten the Crossref list-columns to the snapshot schema ---------------------

flatten_crossref <- function(data) {
  if (nrow(data) == 0) {
    return(data)
  }
  data |>
    mutate(
      num_authors = purrr::map_int(author, \(a) if (is.null(a)) NA_integer_ else nrow(a)),
      first_author_name = purrr::map_chr(author, \(a) {
        if (is.null(a) || nrow(a) == 0) return(NA_character_)
        first <- if ("sequence" %in% names(a)) {
          a[which(a$sequence == "first")[1], ]
        } else {
          a[1, ]
        }
        if (nrow(first) == 0 || is.na(first$family[1])) return(NA_character_)
        str_squish(paste(dplyr::coalesce(first$given[1], ""), first$family[1]))
      }),
      first_author_affiliation = purrr::map_chr(author, \(a) {
        if (is.null(a) || nrow(a) == 0 || !"affiliation.name" %in% names(a)) {
          return(NA_character_)
        }
        first <- if ("sequence" %in% names(a)) {
          a[which(a$sequence == "first")[1], ]
        } else {
          a[1, ]
        }
        purrr::pluck(first, "affiliation.name", 1, .default = NA_character_)
      }),
      # Crossref relation metadata links a data paper to its dataset
      # (isSupplementedBy) and to a related research article (isSupplementTo).
      data_repo_doi = purrr::map_chr(relation, \(r) {
        ids <- purrr::pluck(r, "is-supplemented-by", "id", .default = NULL)
        if (is.null(ids)) NA_character_ else paste(unique(ids), collapse = "; ")
      }),
      related_paper_doi = purrr::map_chr(relation, \(r) {
        ids <- purrr::pluck(r, "is-supplement-to", "id", .default = NULL)
        if (is.null(ids)) NA_character_ else paste(unique(ids), collapse = "; ")
      }),
      author = NULL,
      relation = NULL
    )
}

crossref_flat <- flatten_crossref(crossref_raw)

epmc_flat <- epmc_raw |>
  mutate(
    first_author_name = str_extract(author_string, "^[^,]+"),
    first_author_affiliation = NA_character_,
    data_repo_doi = NA_character_,
    related_paper_doi = NA_character_
  ) |>
  rename(num_authors = num_authors_epmc) |>
  select(-author_string)

# Union, deduplicate on DOI, record every matching query term ------------------

datapapers_raw <- bind_rows(crossref_flat, epmc_flat) |>
  filter(!is.na(doi)) |>
  mutate(doi = str_to_lower(doi)) |>
  group_by(doi) |>
  summarise(
    across(-query_term, \(x) dplyr::first(x[!is.na(x)], default = dplyr::first(x))),
    query_term = paste(sort(unique(query_term)), collapse = "; "),
    .groups = "drop"
  ) |>
  arrange(journal, published_year, doi)

message("Harvested ", nrow(datapapers_raw), " unique candidate papers.")

readr::write_csv(datapapers_raw, "data-raw/datapapers_raw.csv")
