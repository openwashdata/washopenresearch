# Build the ploswater dataset from the raw snapshot written by
# data-raw/ploswater.R. Multi-value columns arrive "; "-delimited already,
# so there is no list-column handling here.

# Column types of the raw snapshot.
ploswater_raw_col_types <- function() {
  readr::cols(
    volume = readr::col_integer(),
    issue = readr::col_integer(),
    publication_date = readr::col_date(),
    published_year = readr::col_integer(),
    is_supp = readr::col_logical(),
    num_supp = readr::col_integer(),
    num_authors = readr::col_integer(),
    has_das = readr::col_logical(),
    .default = readr::col_character()
  )
}

# PLOS statements are free-form; these rules map them onto the das_type
# levels shared with the other datasets. Precedence: no data generated >
# online repository > in paper > on request > not shareable. A statement no
# rule catches stays NA and is listed in the review sheet. A statement the
# rules cannot settle is decided by hand in the decision sheet
# data-raw/ploswater-das-fixes.csv, see apply_ploswater_das_fixes().
classify_ploswater_das <- function(has_das, das, das_repo_url) {
  detect <- function(pattern) {
    stringr::str_detect(das, stringr::regex(pattern, ignore_case = TRUE))
  }
  das_type <- dplyr::case_when(
    !has_das ~ NA_character_,
    detect("no (new )?data ?(sets)?( were| was| are| is)? (generated|created|produced|collected)|no data (are |is )?associated|did not (produce|generate|collect) (any )?data|no datasets") ~ "no data generated",
    !is.na(das_repo_url) ~ "available in online repository",
    detect("(available|deposited|accessible|archived|hosted|obtained|downloaded|found)[^.]{0,60}(repositor|zenodo|dryad|figshare|osf|github|dataverse|data exchange|sequence read archive|NCBI)") ~ "available in online repository",
    detect("supplementar[a-z]* (information|material|file|table|document)|supporting information|supplemental (information|material|file|table|document)|uploaded as supplementary|S\\d+ (Dataset|Table|File|Text)") ~ "in paper",
    detect("within (the|this) (paper|manuscript|article|publication)|in (the|this|its) (paper|manuscript|article|published article|publication)|part of the (submitted|summitted) (article|manuscript)|within the (submitted|summitted) manuscript|uploaded along(side)?( with)? (this )?(the )?submission") ~ "in paper",
    detect("upon (reasonable )?request|on request|by request|contact(ing)? the (corresponding )?author") ~ "on request",
    detect("cannot be (shared|made)|not (be )?(publicly )?(available|shared)|restrictions apply|third[- ]party") ~ "not shareable",
    .default = NA_character_
  )
  # All shared levels are declared, whether or not each one occurs.
  factor(das_type, levels = das_type_levels())
}

# Apply the decision sheet of das_type (columns doi, das_type, reason): the
# das_type of a listed article replaces the classified one. The value must
# be one of the shared levels; `reason` says why, for the reader of the
# sheet, and is not used.
apply_ploswater_das_fixes <- function(data, das_fixes_file) {
  sheet <- read_doi_sheet(das_fixes_file, data)
  unknown <- setdiff(sheet$das_type[!is.na(sheet$das_type)], das_type_levels())
  if (length(unknown) > 0) {
    stop(das_fixes_file, " has a das_type that is not one of the shared levels: ",
         paste(unknown, collapse = ", "), call. = FALSE)
  }
  data$das_type <- as.character(data$das_type)
  data <- apply_decisions(data, sheet, "das_type", key = "doi")
  data$das_type <- factor(data$das_type, levels = das_type_levels())
  data
}

# Build the dataset: the shared column layout, the das_type classification,
# the decisions of the das_type decision sheet and standardised countries.
build_ploswater <- function(raw_file, das_fixes_file) {
  data <- read_strict_csv(raw_file, ploswater_raw_col_types()) |>
    # Same column layout as the other datasets; PLOS has no site-specific
    # article number, so the DOI is the identifier.
    dplyr::mutate(paperid = doi, url_source = "journals.plos.org") |>
    dplyr::relocate(
      paperid, volume, issue, paper_url, journal, title, published_year,
      is_supp, num_supp, supp_file_type, supp_url, num_authors,
      dplyr::starts_with("first_author"),
      dplyr::starts_with("correspondence_author"),
      has_das, das, das_repo_url, das_repo_name, keywords,
      url_source, doi, article_type, publication_date
    ) |>
    dplyr::mutate(das_type = classify_ploswater_das(has_das, das, das_repo_url)) |>
    dplyr::relocate(das_type, .after = das) |>
    dplyr::mutate(
      first_author_affiliation_country =
        to_un_country_name(first_author_affiliation_country),
      correspondence_author_affiliation_country =
        to_un_country_name(correspondence_author_affiliation_country)
    ) |>
    drop_author_emails()
  apply_ploswater_das_fixes(data, das_fixes_file)
}
