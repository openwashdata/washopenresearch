# washopenresearch (development version)

## New features

- New scripted acquisition pipeline for a fourth dataset, `datapapers`, covering
  WASH-related data papers in seven dedicated data journals (Scientific Data,
  Data in Brief, Gates Open Research, F1000Research, GigaScience, GigaByte,
  and Data (MDPI)) (#28). The pipeline lives in
  `data-raw/01_datapapers_acquire.R` (Crossref/Europe PMC harvest with a
  committed raw snapshot), `data-raw/02_datapapers_screen.R` (relevance
  screening captured in a committed decision sheet keyed on DOI), and
  `data-raw/03_datapapers_process.R` (harmonisation to the shared schema and
  export). The dataset itself is added once the first harvest and screening
  round are complete.

## Minor improvements and fixes

- The list-column collapsing helper and shared country-cleaning steps moved to
  `data-raw/helpers.R`, sourced by all processing scripts.
- `data-raw/README.md` documents the run order and provenance of every
  committed snapshot and decision sheet.

# washopenresearch 0.2.0

## New features

- New dataset `ploswater` with all 436 articles of the journal PLOS Water from its first volume (2022) to July 2026, collected through the public PLOS API (#14). Beyond the shared schema it records `das_repo_url` (links and dataset DOIs in the data availability statement), `das_repo_name` (the recognized repository behind them), `article_type`, and `publication_date` (#15). Data availability statements are mandatory at PLOS: all 333 research articles carry one, and 177 articles link out to a data location.
- `washdev` now covers volume 1 (2011) through volume 16 issue 6 (June 2026) with 1173 observations, up from 932 (#12). The 241 new rows cover volumes 14 to 16.
- `washdev` gains a `doi` column, filled for the newly scraped articles; earlier rows will be backfilled via Crossref (#20).
- Data acquisition is now fully R. The washdev scraper was ported from Python/Selenium to `data-raw/washdev_scraping.R` using chromote and rvest, with incremental updates (#11). The Python tooling in `inst/python/`, including a 17 MB chromedriver binary, was removed (#17).

## Bug fixes

- The manual supplement-type corrections for `uncnewsletter` were indexed against `washdev` paperids and landed on the wrong rows, and `correspondence_author_affiliation_country` was never cleaned because the cleaned values were written into `first_author_affiliation_country`, overwriting it. Both are fixed and `uncnewsletter` was regenerated; country values changed on 56 rows and supplement types on 16 rows (#13).
- Two author names in `washdev` (for example "Inês Freire Machete") carried Mac Roman bytes that made the xlsx export fail; the raw data is repaired at read time (#13).
- `.Rbuildignore` excluded the whole `inst/` directory from the built package, so `citation("washopenresearch")` and the `inst/extdata` files were missing from installed packages. The rule is now scoped correctly (#17).

## Minor improvements

- The data dictionary and roxygen documentation use the actual variable names `first_author_affiliation_country` and `correspondence_author_affiliation_country` for `washdev` (previously documented as `*_affiliation_region`) and document the `url_source` and `doi` variables. The `uncnewsletter` dictionary entry for `issue_url` is corrected from "Volume number of the journal" (integer) to the newsletter issue URL (character).
- `uncnewsletter` is documented as a frozen source: the newsletter ceased publication in May 2024 (#17).
- For newly scraped `washdev` rows, mixed supplementary file types are recorded as " & "-joined lists (one type per file) instead of the literal "misc", which previously required manual repair.
- Data values that no cleaning rule could resolve are written to review files under `data-raw/` (`*-das-review.csv`, `*-country-review.csv`) instead of being fixed by hand, so every correction stays in reproducible R code (#12, #15).

# washopenresearch 0.1.0

## Breaking changes

- `washdev` and `uncnewsletter` no longer contain list-columns (#8). The multi-value variables `supp_file_type`, `supp_url`, `das_repo_url`, and `keywords` are now character columns in which multiple values are separated by `"; "`. Flat-file exports such as `write.csv()` now work directly on both datasets. Code that used `tidyr::unnest()` or `unlist()` on these columns should split the strings instead, for example with `tidyr::separate_rows(supp_file_type, sep = "; ")` or `stringr::str_split(keywords, "; ")`.
- `Depends` was raised from R (>= 2.10) to R (>= 3.5), required by the serialization format of the regenerated data files.

## Minor improvements and fixes

- The CSV and XLSX exports in `inst/extdata/` now show multi-value cells as `"; "`-separated strings instead of R code literals such as `c("pdf", "docx")`.
- The variable descriptions in the package documentation and the data dictionary describe the new delimited format and the correct variable types.
- The article "Missed Opportunity: where is WASH research data gone?" uses `tidyr::separate_rows()` in place of `tidyr::unnest()` to expand `supp_file_type`.
- The word cloud figure in the README has alt text.

# washopenresearch 0.0.1

- Initial release with the `washdev` and `uncnewsletter` datasets on data availability statements in WASH research publications.
