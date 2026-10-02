# Build the datapapers dataset (issue #28) from the committed harvest and
# the screening and fixes sheets. Screening is closed: papers without a
# decision stay out of the build.

# Column types of the committed Crossref and Europe PMC harvest.
datapapers_raw_col_types <- function() {
  readr::cols(
    published_year = readr::col_integer(),
    retrieval_date = readr::col_date(),
    num_authors = readr::col_integer(),
    # No harvested row has a related paper, and the column shipped as an
    # all-missing logical in v0.4.0. Kept as shipped.
    related_paper_doi = readr::col_logical(),
    .default = readr::col_character()
  )
}

# Column types of the screening sheet: one row per harvested candidate, with
# the screening decision in `include`.
datapapers_screening_col_types <- function() {
  readr::cols(
    published_year = readr::col_integer(),
    auto_relevant = readr::col_logical(),
    include = readr::col_logical(),
    .default = readr::col_character()
  )
}

# The repository link of a harvested row as a URL. The harvest stores bare
# DOIs ("10.5281/..."), several "; "-delimited; a value that is already a URL
# is kept.
data_repo_doi_as_url <- function(data_repo_doi) {
  dplyr::if_else(
    !is.na(data_repo_doi) & !stringr::str_detect(data_repo_doi, "^https?://"),
    stringr::str_replace_all(data_repo_doi, "(^|; )(10\\.)", "\\1https://doi.org/\\2"),
    data_repo_doi
  )
}

# Build the dataset: the screened-in papers of the harvest, harmonised to the
# columns shared with the other datasets plus the data paper fields.
build_datapapers <- function(raw_file, screening_file,
                             country_fixes_file, repo_fixes_file) {
  raw <- read_strict_csv(raw_file, datapapers_raw_col_types())
  screening <- read_strict_csv(screening_file, datapapers_screening_col_types())
  check_sheet_keys(screening, raw, "doi", screening_file)

  included <- dplyr::inner_join(
    raw,
    screening |> dplyr::filter(include %in% TRUE) |> dplyr::select(doi),
    by = "doi"
  )
  country_fixes <- read_doi_sheet(country_fixes_file, included)
  repo_fixes <- read_doi_sheet(repo_fixes_file, included)

  included |>
    dplyr::left_join(
      datapapers_journals() |> dplyr::select(journal, url_source),
      by = "journal"
    ) |>
    dplyr::mutate(
      paper_url = paste0("https://doi.org/", doi),
      # A data paper describes a shared dataset, so the linked repository
      # plays the role of das_repo_url in the other datasets. The harvest's
      # relation metadata is the first source; the fixes sheet holds the links
      # verified against Crossref/DataCite and the article's availability
      # section. Missing in both means the paper deposited nowhere.
      data_repo_url = data_repo_doi_as_url(data_repo_doi)
    ) |>
    apply_decisions(repo_fixes, "data_repo_url", key = "doi") |>
    dplyr::mutate(
      data_repo = parse_repo_name(data_repo_url),
      first_author_affiliation_country =
        stringr::str_extract(first_author_affiliation, "[^,]+$") |>
        stringr::str_squish() |>
        to_un_country_name()
    ) |>
    apply_decisions(country_fixes, "first_author_affiliation_country", key = "doi") |>
    dplyr::arrange(journal, published_year, doi) |>
    dplyr::mutate(paperid = dplyr::row_number()) |>
    dplyr::select(
      paperid, doi, paper_url, url_source, journal, title, published_year,
      num_authors, first_author_name, first_author_affiliation,
      first_author_affiliation_country,
      data_repo_url, data_repo, license, related_paper_doi,
      abstract, query_term, retrieval_date
    ) |>
    drop_author_emails()
}
