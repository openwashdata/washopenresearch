# Build an IWA journal dataset (washdev, ws, jwh) from its raw snapshot.
# The journals come off one scraper and share one schema, so one function
# builds all of them. What differs in the processing is listed in
# iwa_config(); which sheets a journal has is wired in _targets.R, because
# every sheet is a tracked input of the pipeline.

# Rules mapping a data availability statement onto the shared das_type
# levels, applied in order. A statement no rule matches keeps its full text
# and is listed in the journal's review sheet.
#
# washdev has its own, older rule set. It is kept as it was when the dataset
# was first published, because changing a rule reclassifies shipped rows.
washdev_das_rules <- function() {
  c(
    "^All relevant data are available from.*" = "available in online repository",
    "^All relevant data used in this study are available from online repositories.*" = "available in online repository",
    ".*available on Zenodo.*" = "available in online repository",
    "^All relevant data are included in the paper.*" = "in paper",
    ".+readers should contact the corresponding author.*" = "on request"
  )
}

# The rule set for every IWA journal added after washdev.
iwa_das_rules <- function() {
  c(
    "^All relevant data are (included in|available)( from)? an? online repositor.*" = "available in online repository",
    "^All relevant data are available from.*" = "available in online repository",
    ".*available on Zenodo.*" = "available in online repository",
    "^All relevant data are available online\\.?$" = "available in online repository",
    "^All relevant data are included in the paper.*" = "in paper",
    ".+readers should contact the corresponding author.*" = "on request",
    ".*available from the corresponding author.*" = "on request"
  )
}

# What differs between the IWA journals.
# - drop_index: washdev.csv was written by the original Python scraper and
#   carries an unnamed leading index column.
# - integer_issue: washdev has no combined issues, so its issue is an integer;
#   the other journals record combined issues such as "1-2" and keep text.
# - split_supp_file_type: washdev lists one file type per supplement file,
#   "; "-delimited like the other multi-value columns; the other journals
#   keep the scraper's " & " separator.
iwa_config <- function(journal) {
  r_scraper_journal <- list(
    drop_index = FALSE,
    integer_issue = FALSE,
    split_supp_file_type = FALSE,
    das_rules = iwa_das_rules()
  )
  configs <- list(
    washdev = list(
      drop_index = TRUE,
      integer_issue = TRUE,
      split_supp_file_type = TRUE,
      das_rules = washdev_das_rules()
    ),
    ws = r_scraper_journal,
    jwh = r_scraper_journal
  )
  if (!journal %in% names(configs)) {
    stop("No IWA configuration for journal '", journal, "'.", call. = FALSE)
  }
  configs[[journal]]
}

# Apply the mapping rules in order; each rule replaces a matching statement
# with its das_type level.
map_das_type <- function(x, rules) {
  for (pattern in names(rules)) {
    x <- stringr::str_replace(x, pattern, rules[[pattern]])
  }
  x
}

# Build one IWA dataset. The three sheet arguments are paths, or NULL for a
# journal that has no such sheet.
build_iwa <- function(raw_file, config,
                      country_fixes_file = NULL,
                      supp_type_fixes_file = NULL,
                      doi_backfill_file = NULL) {
  data <- process_iwa_journal(raw_file, drop_index = config$drop_index)

  if (!is.null(country_fixes_file)) {
    data <- apply_decisions(
      data,
      read_paperid_sheet(country_fixes_file, data),
      c("first_author_affiliation_country",
        "correspondence_author_affiliation_country")
    )
  }

  if (!is.null(supp_type_fixes_file)) {
    data <- apply_decisions(
      data, read_paperid_sheet(supp_type_fixes_file, data), "supp_file_type"
    )
  }
  if (config$split_supp_file_type) {
    data <- dplyr::mutate(data, supp_file_type = strsplit(supp_file_type, " & "))
  }

  data <- data |>
    dplyr::mutate(das_type = das_type_factor(map_das_type(das_type, config$das_rules))) |>
    dplyr::mutate(dplyr::across(
      c(supp_file_type, supp_url, das_repo_url, keywords),
      collapse_list_col
    ))

  if (config$integer_issue) {
    data <- dplyr::mutate(data, issue = as.integer(issue))
  }

  # Backfilled DOIs only fill articles the scraper found no DOI for.
  if (!is.null(doi_backfill_file)) {
    backfill <- read_paperid_sheet(doi_backfill_file, data)
    data <- data |>
      dplyr::left_join(backfill, by = "paperid", suffix = c("", "_backfill")) |>
      dplyr::mutate(doi = dplyr::coalesce(doi, doi_backfill), doi_backfill = NULL)
  }

  drop_author_emails(data)
}
