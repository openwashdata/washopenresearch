# Build the standalone HTML review app for the datapapers screening step
# (issue #28). Injects data-raw/datapapers_worklist.csv into
# data-raw/datapapers_review_template.html and writes
# data-raw/datapapers_review.html, a single file that runs from disk with no
# server. Decisions made in the app persist in the browser's localStorage and
# export as data-raw/datapapers_decisions.csv, which
# data-raw/apply_datapapers_decisions.R merges into the screening sheet.
#
# Run from the package root:
#   Rscript data-raw/make_datapapers_review_app.R

library(dplyr)
library(readr)
library(jsonlite)

source("data-raw/helpers.R")

worklist <- read_csv("data-raw/datapapers_worklist.csv", show_col_types = FALSE)
screening <- read_csv("data-raw/datapapers_screening.csv", show_col_types = FALSE)

# Only candidates still pending a decision go into the app; DOIs already
# filled in the screening sheet (via apply_datapapers_decisions.R) drop out,
# so rebuilding after each applied batch yields the remaining queue.
# Rows with an abstract come first: they are the fastest to judge.
papers <- worklist |>
  anti_join(screening |> filter(!is.na(include)), by = "doi") |>
  arrange(desc(has_abstract), journal, published_year, title) |>
  select(doi, journal, published_year, title,
         matched_in_title, matched_in_abstract,
         has_abstract, title_only_no_abstract,
         query_term, first_author_name, first_author_affiliation, abstract)

# Highlight terms: split "water AND sanitation" into its words; longest first
# so phrase matches ("water quality") win over their parts ("water").
terms <- datapapers_search_terms() |>
  unname() |>
  strsplit(" AND ", fixed = TRUE) |>
  unlist() |>
  unique() |>
  (\(x) x[order(-nchar(x))])()

inject <- function(template, placeholder, json) {
  # "</" inside a JSON string would close the <script> tag early
  json <- gsub("</", "<\\\\/", json, fixed = TRUE)
  parts <- strsplit(template, placeholder, fixed = TRUE)[[1]]
  stopifnot(length(parts) == 2)
  paste0(parts[1], json, parts[2])
}

template <- readChar("data-raw/datapapers_review_template.html",
                     file.size("data-raw/datapapers_review_template.html"))

html <- template |>
  inject("__PAPERS_JSON__", toJSON(papers, dataframe = "rows", na = "null")) |>
  inject("__TERMS_JSON__", toJSON(terms)) |>
  inject("__META_JSON__", toJSON(list(built = as.character(Sys.Date())),
                                 auto_unbox = TRUE))

writeLines(html, "data-raw/datapapers_review.html", useBytes = TRUE)

message(nrow(papers), " pending candidates written to ",
        "data-raw/datapapers_review.html (", sum(papers$has_abstract),
        " with abstract shown first). Open it in a browser to review.")
