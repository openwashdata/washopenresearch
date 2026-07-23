# Process screened data papers into the `datapapers` dataset (issue #28).
#
# Joins the raw harvest with the committed screening decisions, harmonizes the
# columns to the washdev/uncnewsletter schema (see data-raw/dictionary.csv)
# plus data-paper-specific fields, cleans affiliation countries with the
# committed fixes sheet, and writes data/datapapers.rda and the
# inst/extdata exports.
#
# Run from the package root:
#   Rscript data-raw/03_datapapers_process.R

library(dplyr)
library(stringr)
library(readr)
library(countries)

source("data-raw/helpers.R")

raw_path <- "data-raw/datapapers_raw.csv"
screening_path <- "data-raw/datapapers_screening.csv"
fixes_path <- "data-raw/datapapers_country_fixes.csv"

for (path in c(raw_path, screening_path)) {
  if (!file.exists(path)) {
    stop("Missing ", path, ". Run the earlier data-raw/0*_datapapers_*.R ",
         "scripts first.", call. = FALSE)
  }
}

datapapers_raw <- readr::read_csv(raw_path, show_col_types = FALSE)
screening <- readr::read_csv(screening_path, show_col_types = FALSE)
country_fixes <- readr::read_csv(
  fixes_path,
  col_types = cols(doi = col_character(),
                   first_author_affiliation_country = col_character())
)

n_pending <- sum(is.na(screening$include))
if (n_pending > 0) {
  message(n_pending, " screening decisions still pending; those papers are ",
          "excluded from this build.")
}

# Keep included papers only, harmonized to the shared schema -------------------

journals <- datapapers_journals()

datapapers <- datapapers_raw |>
  inner_join(screening |> filter(include %in% TRUE) |> select(doi),
             by = "doi") |>
  left_join(journals |> select(journal, url_source), by = "journal") |>
  mutate(
    paper_url = paste0("https://doi.org/", doi),
    # Data papers exist to describe a shared dataset, so the linked
    # repository DOI/URL plays the role of das_repo_url in the other
    # datasets. Rows without relation metadata get their repository link at
    # screening or in issue #27's download step.
    data_repo_url = if_else(
      !is.na(data_repo_doi) & !str_detect(data_repo_doi, "^https?://"),
      str_replace_all(data_repo_doi, "(^|; )(10\\.)", "\\1https://doi.org/\\2"),
      data_repo_doi
    ),
    data_repo = parse_repo_name(data_repo_url)
  ) |>
  # Clean affiliation countries: automatic standardisation, then the committed
  # fixes sheet for the residual NAs (no hard-coded ID vectors).
  mutate(
    first_author_affiliation_country = str_extract(
      first_author_affiliation, "[^,]+$") |> str_squish() |> to_un_country_name()
  ) |>
  apply_country_fixes(country_fixes, key = "doi",
                      value_col = "first_author_affiliation_country") |>
  arrange(journal, published_year, doi) |>
  mutate(paperid = row_number()) |>
  select(
    paperid, doi, paper_url, url_source, journal, title, published_year,
    num_authors, first_author_name, first_author_affiliation,
    first_author_affiliation_country,
    data_repo_url, data_repo, license, related_paper_doi,
    abstract, query_term, retrieval_date
  ) |>
  mutate(
    across(c(paperid, published_year, num_authors), as.integer)
  )

# Report residual NA countries so the fixes sheet can be extended --------------

residual <- datapapers |>
  filter(is.na(first_author_affiliation_country),
         !is.na(first_author_affiliation)) |>
  select(doi, first_author_affiliation)
if (nrow(residual) > 0) {
  message(nrow(residual), " papers have an affiliation but no standardised ",
          "country. Add rows for them to ", fixes_path, ":")
  print(residual, n = nrow(residual))
}

stopifnot(!any(purrr::map_lgl(datapapers, is.list)))

# Write to R data object and flat-file exports ---------------------------------

usethis::use_data(datapapers, overwrite = TRUE)

readr::write_csv(datapapers, here::here("inst", "extdata", "datapapers.csv"))
openxlsx::write.xlsx(datapapers, here::here("inst", "extdata", "datapapers.xlsx"))
