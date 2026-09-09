# washopenresearch 0.4.0

## Breaking changes

- The scraped author email addresses are removed from every dataset. The
  columns `first_author_email` and `correspondence_author_email` no longer
  exist in `washdev`, `ploswater`, `uncnewsletter`, `ws` or `jwh`. They were
  published up to and including v0.3.0. The addresses are personal data and
  earn nothing analytically, since the research questions use author country,
  `das_type`, keyword frequency and supplementary counts. A CC BY table of
  corresponding author addresses is a ready-made mailing list, which is the
  concrete harm. The addresses remain in `data-raw/` for provenance; code that
  read either column needs updating. Addresses that authors wrote into the
  statements themselves are masked in place, keeping the domain so the
  statement still reads correctly (52 statements across the five datasets).

- The flat-file exports in `inst/extdata/` are no longer built into the
  installed package. They are still generated and still live in the repository
  and the Zenodo deposit, but shipping a CSV and an XLSX per dataset for six
  datasets would push the built tarball past the 5 MB CRAN guidance. Calls to
  `system.file("extdata", ..., package = "washopenresearch")` no longer resolve;
  read the datasets directly instead, for example `data(ws)`. `inst/CITATION`
  is unaffected and still ships, so `citation("washopenresearch")` is unchanged.

- Access tokens are stripped from repository URLs. A few statements carried a
  Zenodo pre-signed link (`?token=<JWT>`) granting access to an otherwise
  restricted record; the token is replaced and the record URL kept, following
  the same reasoning as the expired Silverchair signatures in #10.

## New features

- Two new datasets covering the remaining IWA journals scraped in the same run
  as `washdev` (#32-#34). `ws` holds all 4,884 articles of Water Supply from
  2001 to 2026, and `jwh` holds all 2,013 articles of the Journal of Water and
  Health from 2003 to 2026, both collected with `data-raw/iwa_scraping.R` and
  sharing the `washdev` schema. Together with `washdev` and `ploswater` this
  takes the corpus to 8,506 screened articles. Data availability statements
  were mapped to the shared `das_type` levels for 1,596 of 1,623 statements in
  `ws` and 717 of 733 in `jwh`; the unmapped tail keeps the full statement text
  and is listed in `data-raw/ws-das-review.csv` and
  `data-raw/jwh-das-review.csv` (#12).

- A fourth IWA journal, AQUA, was scraped in the same run but is not exported.
  539 of its 1,819 rows carry `has_das` TRUE while `das` and `das_type` are
  empty, so the statement text was never captured and the dataset's central
  variable would ship empty. It needs a re-scrape first.


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

- Expired pre-signed CDN links in `washdev$supp_url` are rewritten to stable DOI
  URLs, and Google Scholar alert redirects in `uncnewsletter$paper_url` are
  decoded to their target URLs (#10). The 343 Silverchair links carried a
  January 2024 expiry, and the high-entropy signature tokens tripped secret
  scanners; the article DOI is recovered from the link path, so no re-collection
  is needed. Two helpers in `data-raw/helpers.R`, `canonicalize_silverchair_url()`
  and `decode_scholar_redirect()`, do the rewrites reproducibly.
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
