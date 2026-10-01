# Write built datasets to the files the repository commits: the package data
# file, the flat-file exports, and the review sheets.
#
# Every writer leaves a file alone when its content would not change, so a
# build on a fresh clone leaves the working tree clean. Compressed data files
# and spreadsheets are not byte-stable (a spreadsheet embeds its creation
# time), so "changed" is decided on content, not bytes.

# Put a freshly written temporary file in place, and fail loudly when that
# does not work: a writer that returned the path of a stale file would have
# the pipeline record it as built.
replace_file <- function(fresh, path) {
  if (!file.copy(fresh, path, overwrite = TRUE)) {
    stop("Could not write ", path, call. = FALSE)
  }
  invisible(path)
}

# Save the dataset under its own name unless the file already holds an
# identical object. Returns whether the file was written.
save_rda_if_changed <- function(data, name, path) {
  if (file.exists(path)) {
    on_disk <- new.env()
    load(path, envir = on_disk)
    if (identical(on_disk[[name]], data)) {
      return(FALSE)
    }
  }
  to_save <- new.env()
  assign(name, data, envir = to_save)
  save(list = name, envir = to_save, file = path, compress = "bzip2", version = 3)
  TRUE
}

# Write the CSV unless the file already has the same bytes. Returns whether
# the file was written.
write_csv_if_changed <- function(data, path) {
  fresh <- tempfile(fileext = ".csv")
  on.exit(unlink(fresh))
  readr::write_csv(data, fresh)
  if (file.exists(path) && tools::md5sum(fresh) == tools::md5sum(path)) {
    return(FALSE)
  }
  replace_file(fresh, path)
  TRUE
}

# Reading a spreadsheet back loses type detail (a date and its serial number
# read the same), so this comparison alone cannot prove a spreadsheet is up
# to date. write_dataset() therefore also rewrites it whenever the data file
# or the CSV changed. An unreadable spreadsheet counts as different.
xlsx_content_differs <- function(fresh, path) {
  tryCatch(
    !identical(openxlsx::read.xlsx(fresh), openxlsx::read.xlsx(path)),
    error = function(e) TRUE
  )
}

write_xlsx_if_changed <- function(data, path, force = FALSE) {
  fresh <- tempfile(fileext = ".xlsx")
  on.exit(unlink(fresh))
  openxlsx::write.xlsx(data, fresh)
  if (force || !file.exists(path) || xlsx_content_differs(fresh, path)) {
    replace_file(fresh, path)
  }
  invisible(path)
}

# The package data file plus the CSV and XLSX exports of one dataset.
# Returns the paths, for a `format = "file"` target.
write_dataset <- function(data, name) {
  rda <- file.path("data", paste0(name, ".rda"))
  csv <- file.path("inst", "extdata", paste0(name, ".csv"))
  xlsx <- file.path("inst", "extdata", paste0(name, ".xlsx"))
  rda_written <- save_rda_if_changed(data, name, rda)
  csv_written <- write_csv_if_changed(data, csv)
  write_xlsx_if_changed(data, xlsx, force = rda_written || csv_written)
  c(rda, csv, xlsx)
}

# Review sheets ---------------------------------------------------------------
# Output only: they list what the automatic steps could not resolve, so a
# maintainer can decide. Decisions go into the decision sheets, never here.

# Articles with an affiliation but no standardised country, for either author.
unresolved_countries <- function(data) {
  dplyr::filter(
    data,
    (is.na(first_author_affiliation_country) & !is.na(first_author_affiliation)) |
      (is.na(correspondence_author_affiliation_country) &
         !is.na(correspondence_author_affiliation))
  )
}

# The two review sheets of an IWA journal. A statement no rule mapped keeps
# its full text in das_type, so the unmapped ones are those outside the
# levels the journal's rules map to.
write_iwa_review_sheets <- function(data, name) {
  das_review <- file.path("data-raw", paste0(name, "-das-review.csv"))
  country_review <- file.path("data-raw", paste0(name, "-country-review.csv"))
  mapped <- unique(unname(iwa_config(name)$das_rules))
  data |>
    dplyr::filter(has_das, !das_type %in% mapped) |>
    dplyr::select(paperid, volume, issue, das_type) |>
    write_csv_if_changed(das_review)
  unresolved_countries(data) |>
    dplyr::select(
      paperid, volume, issue,
      first_author_affiliation, correspondence_author_affiliation
    ) |>
    write_csv_if_changed(country_review)
  c(das_review, country_review)
}

# The two review sheets of PLOS Water. A statement no rule classified has a
# missing das_type.
write_ploswater_review_sheets <- function(data) {
  das_review <- "data-raw/ploswater-das-review.csv"
  country_review <- "data-raw/ploswater-country-review.csv"
  data |>
    dplyr::filter(has_das, is.na(das_type)) |>
    dplyr::select(paperid, das) |>
    write_csv_if_changed(das_review)
  unresolved_countries(data) |>
    dplyr::select(paperid, first_author_affiliation, correspondence_author_affiliation) |>
    write_csv_if_changed(country_review)
  c(das_review, country_review)
}
