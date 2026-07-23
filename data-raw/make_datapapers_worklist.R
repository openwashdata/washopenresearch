# Build a review working file of the auto-relevant datapapers candidates
# (issue #28). Not part of the pipeline: this is a one-off aid for the manual
# screening step. It never writes datapapers_screening.csv.
#
# Output: data-raw/datapapers_worklist.csv, one row per auto_relevant == TRUE
# candidate, with a matched_terms column showing which WASH search terms hit
# and where (title vs abstract), so a reviewer can separate genuine WASH data
# papers from incidental matches like "wastewater of a gold mine".
#
# Run from the package root:
#   Rscript data-raw/make_datapapers_worklist.R

library(dplyr)
library(stringr)
library(readr)
library(purrr)

source("data-raw/helpers.R")

raw <- read_csv("data-raw/datapapers_raw.csv", show_col_types = FALSE)
screening <- read_csv("data-raw/datapapers_screening.csv", show_col_types = FALSE)

terms <- datapapers_search_terms()

# For each term, the regex that the screening step uses ("water AND sanitation"
# becomes "water.*sanitation"), plus a readable label.
term_regex <- terms |>
  str_replace_all(fixed(" AND "), ".*") |>
  str_to_lower() |>
  (\(x) paste0("\\b", x, "\\b"))()
term_labels <- names(terms)

# Which terms match in a given piece of text, returned "; "-collapsed.
matched_in <- function(text) {
  if (is.na(text) || text == "") return(NA_character_)
  text <- str_to_lower(text)
  hits <- term_labels[map_lgl(term_regex, ~ str_detect(text, .x))]
  if (length(hits) == 0) NA_character_ else paste(hits, collapse = "; ")
}

worklist <- raw |>
  semi_join(screening |> filter(auto_relevant), by = "doi") |>
  mutate(
    matched_in_title = map_chr(title, matched_in),
    matched_in_abstract = map_chr(abstract, matched_in),
    has_abstract = !is.na(abstract) & abstract != "",
    # A title-only match with no abstract is the weakest signal and the most
    # common false-positive shape; flag it so it gets a closer read.
    title_only_no_abstract = !is.na(matched_in_title) & !has_abstract
  ) |>
  transmute(
    doi, journal, published_year,
    title,
    matched_in_title,
    matched_in_abstract,
    has_abstract,
    title_only_no_abstract,
    query_term,          # the search term(s) that retrieved the paper at harvest
    first_author_name,
    first_author_affiliation,
    data_repo_doi,       # a linked dataset DOI is a strong "real data paper" cue
    abstract,
    include = NA,        # fill TRUE to keep; leave blank to drop
    reason = NA_character_
  ) |>
  arrange(desc(title_only_no_abstract), journal, published_year)

write_csv(worklist, "data-raw/datapapers_worklist.csv", na = "")

message(nrow(worklist), " auto-relevant candidates written to ",
        "data-raw/datapapers_worklist.csv")
message(sum(worklist$has_abstract), " have an abstract; ",
        sum(worklist$title_only_no_abstract), " are title-only matches ",
        "(the weakest signal, sorted to the top).")
message(sum(!is.na(worklist$data_repo_doi)), " carry a linked dataset DOI.")
