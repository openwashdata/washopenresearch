# Build the datapapers dataset (issue #28) from the committed harvest and
# the screening and fixes sheets. Screening is closed: papers without a
# decision stay out of the build.

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

build_datapapers <- function(raw_file, screening_file,
                             country_fixes_file, repo_fixes_file) {
  screening <- read_strict_csv(screening_file, readr::cols(
    published_year = readr::col_integer(),
    auto_relevant = readr::col_logical(),
    include = readr::col_logical(),
    .default = readr::col_character()
  ))
  included <- read_strict_csv(raw_file, datapapers_raw_col_types()) |>
    dplyr::inner_join(
      screening |> dplyr::filter(include %in% TRUE) |> dplyr::select(doi),
      by = "doi"
    )

  country_fixes <- read_strict_csv(country_fixes_file, readr::cols(.default = readr::col_character()))
  repo_fixes <- read_strict_csv(repo_fixes_file, readr::cols(
    checked_date = readr::col_date(),
    .default = readr::col_character()
  ))
  check_sheet_keys(country_fixes, included, "doi", country_fixes_file)
  check_sheet_keys(repo_fixes, included, "doi", repo_fixes_file)

  included |>
    dplyr::left_join(
      datapapers_journals() |> dplyr::select(journal, url_source),
      by = "journal"
    ) |>
    dplyr::mutate(
      paper_url = paste0("https://doi.org/", doi),
      # A data paper describes a shared dataset, so the linked repository
      # plays the role of das_repo_url in the other datasets. The harvest's
      # relation metadata is the first source; the fixes sheet supplies links
      # verified against Crossref/DataCite and the article's availability
      # section. Missing in both means the paper deposited nowhere.
      data_repo_url = data_repo_doi_as_url(data_repo_doi)
    ) |>
    apply_country_fixes(repo_fixes, key = "doi", value_col = "data_repo_url") |>
    dplyr::mutate(
      data_repo = parse_repo_name(data_repo_url),
      first_author_affiliation_country =
        stringr::str_extract(first_author_affiliation, "[^,]+$") |>
        stringr::str_squish() |>
        to_un_country_name()
    ) |>
    apply_country_fixes(
      country_fixes, key = "doi", value_col = "first_author_affiliation_country"
    ) |>
    dplyr::arrange(journal, published_year, doi) |>
    dplyr::mutate(paperid = dplyr::row_number()) |>
    dplyr::select(
      paperid, doi, paper_url, url_source, journal, title, published_year,
      num_authors, first_author_name, first_author_affiliation,
      first_author_affiliation_country,
      data_repo_url, data_repo, license, related_paper_doi,
      abstract, query_term, retrieval_date
    )
}
