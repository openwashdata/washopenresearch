# Changelog

## washopenresearch 0.1.0

### Breaking changes

- `washdev` and `uncnewsletter` no longer contain list-columns
  ([\#8](https://github.com/openwashdata/washopenresearch/issues/8)).
  The multi-value variables `supp_file_type`, `supp_url`,
  `das_repo_url`, and `keywords` are now character columns in which
  multiple values are separated by `"; "`. Flat-file exports such as
  [`write.csv()`](https://rdrr.io/r/utils/write.table.html) now work
  directly on both datasets. Code that used
  [`tidyr::unnest()`](https://tidyr.tidyverse.org/reference/unnest.html)
  or [`unlist()`](https://rdrr.io/r/base/unlist.html) on these columns
  should split the strings instead, for example with
  `tidyr::separate_rows(supp_file_type, sep = "; ")` or
  `stringr::str_split(keywords, "; ")`.
- `Depends` was raised from R (\>= 2.10) to R (\>= 3.5), required by the
  serialization format of the regenerated data files.

### Minor improvements and fixes

- The CSV and XLSX exports in `inst/extdata/` now show multi-value cells
  as `"; "`-separated strings instead of R code literals such as
  `c("pdf", "docx")`.
- The variable descriptions in the package documentation and the data
  dictionary describe the new delimited format and the correct variable
  types.
- The article “Missed Opportunity: where is WASH research data gone?”
  uses
  [`tidyr::separate_rows()`](https://tidyr.tidyverse.org/reference/separate_rows.html)
  in place of
  [`tidyr::unnest()`](https://tidyr.tidyverse.org/reference/unnest.html)
  to expand `supp_file_type`.
- The word cloud figure in the README has alt text.

## washopenresearch 0.0.1

- Initial release with the `washdev` and `uncnewsletter` datasets on
  data availability statements in WASH research publications.
