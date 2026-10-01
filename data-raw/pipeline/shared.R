# Pieces every dataset build shares: reading and applying sheets keyed on an
# article identifier, and the das_type factor.

# Refuse a sheet unless every row can be applied to exactly one article of
# `data`. A sheet that repeats a key or names a key the dataset does not have
# is a mistake in the sheet; applying the rest of it would hide that.
check_sheet_keys <- function(sheet, data, key, path) {
  duplicated_keys <- unique(sheet[[key]][duplicated(sheet[[key]])])
  if (length(duplicated_keys) > 0) {
    stop(path, " lists a ", key, " more than once: ",
         paste(duplicated_keys, collapse = ", "), call. = FALSE)
  }
  unknown_keys <- setdiff(sheet[[key]], data[[key]])
  if (length(unknown_keys) > 0) {
    stop(path, " lists a ", key, " the dataset does not have: ",
         paste(unknown_keys, collapse = ", "), call. = FALSE)
  }
  invisible(sheet)
}

# Read a sheet keyed on paperid (a decision sheet or a DOI backfill) and
# check its keys against `data`.
read_paperid_sheet <- function(path, data) {
  sheet <- read_strict_csv(path, readr::cols(
    paperid = readr::col_integer(),
    .default = readr::col_character()
  ))
  check_sheet_keys(sheet, data, "paperid", path)
}

# Read a sheet keyed on doi and check its keys against `data`. Every column
# is read as text.
read_doi_sheet <- function(path, data) {
  sheet <- read_strict_csv(path, readr::cols(.default = readr::col_character()))
  check_sheet_keys(sheet, data, "doi", path)
}

# Apply a decision sheet: every non-missing value in the sheet's columns
# replaces the value of the article with that key. An empty cell means "no
# decision for this column", so the built value stays.
apply_decisions <- function(data, sheet, columns, key = "paperid") {
  rows <- match(sheet[[key]], data[[key]])
  for (column in columns) {
    decided <- !is.na(sheet[[column]])
    values <- sheet[[column]][decided]
    # Sheets are read as text; keep the dataset column's own type, and refuse
    # a value that does not convert instead of writing a missing value.
    converted <- suppressWarnings(methods::as(values, class(data[[column]])[[1]]))
    if (anyNA(converted)) {
      stop(
        "Decision sheet value for column '", column, "' is not a valid ",
        class(data[[column]])[[1]], ": ",
        paste(values[is.na(converted)], collapse = ", "),
        call. = FALSE
      )
    }
    data[[column]][rows[decided]] <- converted
  }
  data
}

# The das_type levels the datasets share, in the order they are listed
# wherever they lead a factor.
das_type_levels <- function() {
  c(
    "available in online repository", "in paper", "on request",
    "not shareable", "no data generated"
  )
}

# Sort text with a collation that does not depend on the session locale.
# sort() and as.factor() use the session collation, so the same data gave
# different level orders on macOS and on a Linux runner.
sort_text <- function(x) {
  stringi::stri_sort(x, locale = "en_US")
}

# Factor of das_type values with all levels in sorted order.
das_type_factor <- function(x) {
  factor(x, levels = sort_text(unique(x[!is.na(x)])))
}

# Factor of das_type values that mix the shared levels with the full text of
# statements no rule mapped. The shared levels that occur come first, in
# their fixed order, then the statements in sorted order, so that the
# categories are not scattered among the statements.
das_type_factor_shared_first <- function(x) {
  present <- unique(x[!is.na(x)])
  shared <- intersect(das_type_levels(), present)
  factor(x, levels = c(shared, sort_text(setdiff(present, shared))))
}
