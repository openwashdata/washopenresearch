# Build the uncnewsletter dataset from the manually annotated collection.
# The newsletter ceased publication in May 2024, so this is a frozen source
# covering papers from 2020 to 2023 (issue #17).

uncnewsletter_raw_col_types <- function() {
  readr::cols(
    paperid = readr::col_double(),
    published_year = readr::col_double(),
    is_supp = readr::col_logical(),
    num_supp = readr::col_double(),
    num_authors = readr::col_double(),
    has_das = readr::col_logical(),
    citations = readr::col_double(),
    .default = readr::col_character()
  )
}

# Unpack the list literals the annotators' spreadsheet export left in the
# das_repo_url and keywords columns into list-columns.
unpack_uncnewsletter_lists <- function(data) {
  data |>
    dplyr::mutate(
      das_repo_url = stringr::str_extract(das_repo_url, "(?<=\\[)(.*?)(?=\\]\\s*)"),
      das_repo_url = strsplit(das_repo_url, ","),
      keywords = dplyr::na_if(keywords, "[]"),
      keywords = stringr::str_replace_all(keywords, " ", ""),
      keywords = stringr::str_replace_all(keywords, "\"", "'"),
      keywords = purrr::map(keywords, function(x) {
        stringr::str_extract_all(x, pattern = "(?<=')[^', ]*?(?='\\s*)")[[1]]
      })
    )
}

build_uncnewsletter <- function(raw_file, supp_fixes_file, doi_backfill_file) {
  data <- read_strict_csv(raw_file, uncnewsletter_raw_col_types()) |>
    dplyr::mutate(paper_info = NULL) |>
    dplyr::filter(!is.na(title)) |>
    dplyr::mutate(
      supp_file_type = stringr::str_to_lower(supp_file_type),
      num_supp = tidyr::replace_na(num_supp, 0),
      # Google Scholar alert redirects are decoded to the target URL (#10)
      paper_url = decode_scholar_redirect(paper_url)
    ) |>
    dplyr::rename(supp_url = supp_link)

  data <- apply_decisions(
    data,
    read_paperid_sheet(supp_fixes_file, data),
    c("num_supp", "supp_file_type")
  )

  data <- data |>
    dplyr::mutate(
      supp_file_type = strsplit(supp_file_type, " & "),
      supp_url = as.list(supp_url)
    ) |>
    unpack_uncnewsletter_lists() |>
    dplyr::mutate(dplyr::across(
      c(supp_file_type, supp_url, das_repo_url, keywords),
      collapse_list_col
    )) |>
    dplyr::mutate(
      das_type = stringr::str_replace(das_type, "data not sharable", "not shareable"),
      das_type = stringr::str_replace(
        das_type, "no datasets were generated during the study", "no data generated"
      ),
      das_type = das_type_factor(das_type),
      first_author_affiliation_country =
        to_un_country_name(first_author_affiliation_country),
      correspondence_author_affiliation_country =
        to_un_country_name(correspondence_author_affiliation_country)
    )

  # DOIs come from a Crossref title search (issue #20); the collection
  # itself has no DOI column.
  backfill <- read_paperid_sheet(doi_backfill_file, data)
  data |>
    dplyr::left_join(backfill, by = "paperid") |>
    drop_author_emails()
}
