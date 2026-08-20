# Parse the downloaded supplementary files and classify what each one
# actually shares (issue #47 tier 3). For every file in the download manifest
# this records structural metrics and a first-pass content class:
#
#   "observation tables"  at least one table shaped like rows-as-observations
#                         (many rows, headers free of summary-statistic terms)
#   "summary tables"      tables present, but all of them look like
#                         means/SDs/coefficients rather than the data
#   "figures"             images but no tables
#   "prose only"          neither tables nor images
#   "unparsed"            format the pipeline cannot read (.doc, damaged file)
#
# The heuristics are deliberately transparent and recorded per table/sheet so
# they can be audited and tuned against a manual sample before any use in
# scoring (same philosophy as score_fair(), #19).
#
# docx is converted to GitHub-flavoured markdown with pandoc and the pipe
# tables are measured. xlsx/xls sheets are read with readxl; merged cells are
# counted via openxlsx (xlsx only).
#
# Run from the package root (needs pandoc on PATH):
#   Rscript data-raw/suppfiles_parse.R
#
# Output: data-raw/suppfiles/suppfiles_parsed.csv, one row per file.

library(dplyr)
library(purrr)
library(readr)
library(stringr)

manifest_path <- "data-raw/suppfiles/manifest.csv"
out_path <- "data-raw/suppfiles/suppfiles_parsed.csv"

SUMMARY_RX <- paste0(
  "\\b(mean|median|s\\.?d\\.?|std|standard deviation|variance|cv|iqr|",
  "min|max|range|p[- ]?value|significan|coefficient|estimate|",
  "std\\.? error|confidence|ci\\b|r2|r\\u00b2|anova|t[- ]test|chi)")
OBS_MIN_ROWS <- 15

is_numeric_cell <- function(x) {
  x <- str_trim(x)
  nzchar(x) & str_detect(x, "^[<>~-]?\\s*[0-9][0-9.,eE%\\u00b1\\s-]*$")
}

# --- docx: pandoc to markdown, measure pipe tables ---------------------------

parse_docx <- function(path) {
  md <- tryCatch(
    system2("pandoc", c(shQuote(path), "-t", "gfm"), stdout = TRUE,
            stderr = FALSE),
    error = function(e) NULL, warning = function(w) NULL)
  if (is.null(md)) return(tibble(parse_status = "unparsed"))

  table_line <- str_starts(md, "\\|")
  blocks <- split(md[table_line], cumsum(!table_line)[table_line])
  blocks <- blocks[lengths(blocks) >= 3]  # header + separator + data

  empty_tables <- tibble(n_rows = integer(), n_cols = integer(),
                         numeric_share = numeric(), summary_header = logical())
  tables <- map_dfr(blocks, function(b) {
    header <- str_to_lower(b[1])
    data_rows <- b[-(1:2)]
    cells <- unlist(str_split(str_remove_all(data_rows, "^\\||\\|$"), "\\|"))
    tibble(
      n_rows = length(data_rows),
      n_cols = max(1, str_count(b[1], "\\|") - 1),
      numeric_share = mean(is_numeric_cell(cells)),
      summary_header = str_detect(header, SUMMARY_RX)
    )
  })
  if (!nrow(tables)) tables <- empty_tables

  obs <- nrow(tables) > 0 &&
    any(tables$n_rows >= OBS_MIN_ROWS & !tables$summary_header)
  tibble(
    parse_status = "ok",
    n_tables = nrow(tables),
    max_table_rows = if (nrow(tables)) max(tables$n_rows) else 0L,
    n_images = sum(str_count(md, "!\\[")),
    n_words_prose = sum(str_count(md[!table_line], "\\S+")),
    has_observation_table = obs,
    any_summary_table = any(tables$summary_header %in% TRUE)
  )
}

# --- xlsx/xls: readxl sheets, openxlsx merges --------------------------------

parse_xlsx <- function(path) {
  sheets <- tryCatch(readxl::excel_sheets(path), error = function(e) NULL)
  if (is.null(sheets)) return(tibble(parse_status = "unparsed"))

  per_sheet <- map_dfr(sheets, function(s) {
    x <- tryCatch(
      suppressMessages(readxl::read_excel(path, sheet = s,
                                          col_names = FALSE,
                                          .name_repair = "minimal")),
      error = function(e) NULL)
    if (is.null(x) || !nrow(x)) {
      return(tibble(n_rows = 0L, n_cols = 0L, numeric_share = NA_real_,
                    summary_header = FALSE, n_blocks = 0L))
    }
    m <- as.matrix(x)
    blank_row <- apply(m, 1, function(r) all(is.na(r) | !nzchar(str_trim(r))))
    head_txt <- str_to_lower(paste(m[seq_len(min(2, nrow(m))), ],
                                   collapse = " "))
    tibble(
      n_rows = nrow(m),
      n_cols = ncol(m),
      numeric_share = mean(is_numeric_cell(m[!is.na(m)])),
      summary_header = str_detect(head_txt, SUMMARY_RX),
      n_blocks = sum(diff(c(TRUE, blank_row)) == -1)
    )
  })

  merges <- 0L
  if (str_ends(str_to_lower(path), "xlsx")) {
    merges <- tryCatch({
      wb <- openxlsx::loadWorkbook(path)
      sum(lengths(map(wb$worksheets, ~ .x$mergeCells)))
    }, error = function(e) NA_integer_)
  }

  obs <- any(per_sheet$n_rows >= OBS_MIN_ROWS &
               !per_sheet$summary_header, na.rm = TRUE)
  tibble(
    parse_status = "ok",
    n_sheets = length(sheets),
    max_sheet_rows = max(per_sheet$n_rows),
    n_merged_ranges = merges,
    multi_table_sheet = any(per_sheet$n_blocks > 1, na.rm = TRUE),
    has_observation_table = obs,
    any_summary_table = any(per_sheet$summary_header %in% TRUE)
  )
}

# --- Walk the manifest --------------------------------------------------------

manifest <- read_csv(manifest_path, show_col_types = FALSE) |>
  filter(status == "ok", file.exists(local_path)) |>
  mutate(format = str_to_lower(tools::file_ext(file_name)))

message("Parsing ", nrow(manifest), " files: ",
        paste(capture.output(print(table(manifest$format))), collapse = " "))

parsed <- manifest |>
  select(source, paperid, doi, file_name, format, local_path) |>
  mutate(res = map2(local_path, format, function(p, fmt) {
    switch(fmt,
           docx = parse_docx(p),
           xlsx = ,
           xls  = parse_xlsx(p),
           tibble(parse_status = "not_attempted"))
  })) |>
  tidyr::unnest(res) |>
  select(-local_path)

# Not every run sees every format; make the class inputs exist regardless.
for (col in c("n_tables", "n_sheets", "n_images")) {
  if (!col %in% names(parsed)) parsed[[col]] <- NA_integer_
}
if (!"has_observation_table" %in% names(parsed)) {
  parsed$has_observation_table <- NA
}

parsed <- parsed |>
  mutate(content_class = case_when(
    parse_status != "ok" ~ parse_status,
    has_observation_table ~ "observation tables",
    coalesce(n_tables, n_sheets) > 0 ~ "summary tables",
    coalesce(n_images, 0L) > 0 ~ "figures",
    TRUE ~ "prose only"
  ))

write_csv(parsed, out_path)

message("\nContent classes (docx/xlsx/xls files):")
parsed |>
  filter(format %in% c("docx", "xlsx", "xls")) |>
  count(format, content_class) |>
  pwalk(function(format, content_class, n)
    message(sprintf("  %-5s %-20s %4d", format, content_class, n)))
