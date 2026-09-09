# Join TOP Factor scores onto the in-scope journals (issue #38 step 3, the
# "Policy - data" layer: what data-sharing does the journal REQUIRE). TOP
# Factor scores ~3,200 journals on the 8 TOP transparency standards; the two
# columns this project cares about are Data transparency and Data citation.
#
# Source: top-factor.csv from the COS OSF project https://osf.io/kgnva/
# (file GUID qatkz), downloaded to cache/ on first run. Join is by ISSN
# (any of a journal's ISSNs against TOP's Issn/Eissn), with a normalized
# name match reported as a diagnostic only, never as the join.
#
# Input:  journal-identifiers.csv (run pull_journal_identifiers.R first)
# Output: top-factor-scores.csv, one row per in-scope journal; unmatched
#         journals keep an all-NA score block so coverage gaps stay visible
#
# Dependencies: dplyr, readr, purrr, tidyr, stringr

library(dplyr)
library(readr)
library(purrr)
library(tidyr)
library(stringr)

DIR <- "data-raw/washbiblio"
CACHE <- file.path(DIR, "cache")
TOP_URL <- "https://osf.io/download/qatkz/"
TOP_CSV <- file.path(CACHE, "top-factor.csv")

if (!file.exists(TOP_CSV)) {
  download.file(TOP_URL, TOP_CSV, mode = "wb", quiet = TRUE)
}

top <- read_csv(TOP_CSV, show_col_types = FALSE) |>
  rename_with(\(x) x |> str_to_lower() |> str_replace_all("[^a-z0-9]+", "_"))

journals <- read_csv(file.path(DIR, "journal-identifiers.csv"),
                     show_col_types = FALSE)

norm_name <- function(x) {
  x |>
    str_to_lower() |>
    str_replace_all("&", "and") |>
    str_replace_all("[^a-z0-9 ]", " ") |>
    str_squish() |>
    str_remove("^the ")
}

# One row per (journal, ISSN) on both sides, then join on the ISSN.
ours <- journals |>
  mutate(issn = str_split(issns, ";")) |>
  unnest(issn) |>
  filter(!is.na(issn), nzchar(issn))

theirs <- top |>
  mutate(top_row = row_number()) |>
  pivot_longer(c(issn, eissn), values_to = "issn") |>
  filter(!is.na(issn), nzchar(issn)) |>
  distinct(top_row, issn)

score_cols <- names(top)[str_detect(names(top), "_score$")]

matched <- ours |>
  inner_join(theirs, by = "issn") |>
  distinct(source_id, top_row) |>
  left_join(top |> mutate(top_row = row_number()), by = "top_row")

out <- journals |>
  select(source_id, venue, issn_l, publisher) |>
  left_join(
    matched |>
      select(source_id, top_journal = journal, top_publisher = publisher,
             all_of(score_cols), top_total = total,
             data_transparency_justification, data_citation_justification),
    by = "source_id"
  ) |>
  mutate(top_matched = !is.na(top_journal))

write_csv(out, file.path(DIR, "top-factor-scores.csv"))

message("TOP Factor coverage: ", sum(out$top_matched), "/", nrow(out),
        " journals matched by ISSN")
message("Unmatched: ",
        paste(out$venue[!out$top_matched], collapse = "; "))

# Diagnostic: journals TOP lists under the same normalized name but whose
# ISSNs did not match (a signal of an ISSN discrepancy, not a join to use).
name_only <- journals |>
  filter(!journals$source_id %in% out$source_id[out$top_matched]) |>
  mutate(name_norm = norm_name(venue)) |>
  inner_join(top |> mutate(name_norm = norm_name(journal)), by = "name_norm")
if (nrow(name_only) > 0) {
  message("Name-only near-misses (check ISSNs by hand): ",
          paste(name_only$venue, collapse = "; "))
}
