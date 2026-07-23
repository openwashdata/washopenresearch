# Screen harvested data-paper candidates for WASH relevance (issue #28).
#
# Reads data-raw/datapapers_raw.csv, computes an automatic relevance flag from
# title/abstract keyword matches, and updates the committed decision sheet
# data-raw/datapapers_screening.csv. New candidates are appended with
# include = NA; existing human decisions are never overwritten, so the manual
# screening effort is captured in git and the pipeline stays non-interactive.
#
# Run from the package root:
#   Rscript data-raw/02_datapapers_screen.R
#
# A human then fills `include` (TRUE/FALSE) and `reason` for rows where
# `auto_relevant` alone is not conclusive. Decisions key on DOI, so the sheet
# can be split among contributors and merged.

library(dplyr)
library(stringr)
library(readr)

source("data-raw/helpers.R")

raw_path <- "data-raw/datapapers_raw.csv"
screening_path <- "data-raw/datapapers_screening.csv"

if (!file.exists(raw_path)) {
  stop("Missing ", raw_path, ". Run data-raw/01_datapapers_acquire.R first.",
       call. = FALSE)
}

datapapers_raw <- readr::read_csv(raw_path, show_col_types = FALSE)

# Automatic relevance: does any WASH search term appear in the title or
# abstract? Word-boundary matching keeps "wash" from matching "washer" etc.
term_pattern <- datapapers_search_terms() |>
  unname() |>
  str_replace_all(fixed(" AND "), ".*") |>
  (\(x) paste0("\\b(", paste(x, collapse = "|"), ")\\b"))()

candidates <- datapapers_raw |>
  mutate(
    auto_relevant = str_detect(
      str_to_lower(paste(coalesce(title, ""), coalesce(abstract, ""))),
      str_to_lower(term_pattern)
    )
  ) |>
  select(doi, title, journal, published_year, auto_relevant)

# Merge with existing decisions: never overwrite a filled `include`. ----------

if (file.exists(screening_path)) {
  existing <- readr::read_csv(
    screening_path,
    col_types = cols(
      doi = col_character(),
      title = col_character(),
      journal = col_character(),
      published_year = col_integer(),
      auto_relevant = col_logical(),
      include = col_logical(),
      reason = col_character()
    )
  )
} else {
  existing <- tibble(
    doi = character(), title = character(), journal = character(),
    published_year = integer(), auto_relevant = logical(),
    include = logical(), reason = character()
  )
}

screening <- candidates |>
  left_join(existing |> select(doi, include, reason), by = "doi") |>
  bind_rows(existing |> anti_join(candidates, by = "doi")) |>
  arrange(journal, published_year, doi)

readr::write_csv(screening, screening_path, na = "")

n_pending <- sum(is.na(screening$include))
message(
  nrow(screening), " candidates in ", screening_path, "; ",
  sum(screening$include %in% TRUE), " included, ",
  sum(screening$include %in% FALSE), " excluded, ",
  n_pending, " pending a decision."
)
if (n_pending > 0) {
  message("Fill `include` (TRUE/FALSE) and `reason` for the pending rows, ",
          "then commit the sheet.")
}
