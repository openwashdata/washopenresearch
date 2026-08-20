# washopenresearch (development version)

# washopenresearch 0.3.0

## New features

- New function `das_in_paper_support()` classifies how a "data in paper"
  data availability statement is backed by the recorded supplement fields
  (#47). The modal claim "all relevant data are included in the paper or its
  supplementary information" splits into `"no supplement"` (the claim rests
  on the printed tables alone), `"unstructured supplement"` (pdf or images
  only), `"structured supplement"` (docx, xlsx and similar), and
  `"open supplement"` (csv, txt, json, xml). Across washdev and the three
  IWA journal snapshots (2,599 claims), 71.5% have no supplement, 26.5% a
  structured one, 2.1% an unstructured one, and none an open format.
  `data-raw/das_in_paper_support.R` reproduces the summary in
  `data-raw/das-in-paper-support-summary.csv`. A follow-up cross-check
  against OpenAlex article types (`data-raw/das_in_paper_article_types.R`,
  committed DOI-to-type lookup) shows the no-supplement claims are almost
  entirely substantive research articles: only 0.5% are front matter or
  reviews, so the article-type filter proposed in #47 does not shrink the
  population. Verifying the remaining 1,847 bare claims requires reading
  the articles' tables.
- Supplement content audit (#47 tier 3): the 741 supplementary files of the
  IWA snapshots whose pre-signed CDN links were still valid were downloaded
  (checksummed manifest in `data-raw/suppfiles/manifest.csv`; the signatures
  lapse 2026-08-18 to 2026-08-30, so 572 further links were already dead)
  and classified with transparent structural heuristics
  (`data-raw/suppfiles_parse.R`: pandoc-converted docx tables, readxl/xlsx
  sheet metrics). Of the 290 in-paper claims whose structured supplement was
  in hand, 54% share prose only, 21% summary tables, and 20% tables shaped
  like observations (`data-raw/das_in_paper_suppfile_audit.R`). xlsx files
  are the exception: 25 of 29 hold observation-shaped sheets. Heuristics are
  recorded per file and await validation against a manual sample.
- New scripted acquisition pipeline for a fourth dataset, `datapapers`, covering
  WASH-related data papers in seven dedicated data journals (Scientific Data,
  Data in Brief, Gates Open Research, F1000Research, GigaScience, GigaByte,
  and Data (MDPI)) (#28). The pipeline lives in
  `data-raw/01_datapapers_acquire.R` (Crossref/Europe PMC harvest with a
  committed raw snapshot), `data-raw/02_datapapers_screen.R` (relevance
  screening captured in a committed decision sheet keyed on DOI), and
  `data-raw/03_datapapers_process.R` (harmonisation to the shared schema and
  export). The first harvest and screening round yielded 8 papers, shipped
  as the new `datapapers` dataset with CSV and XLSX exports in
  `inst/extdata/`.

## Minor improvements and fixes

- `datapapers` now carries the repository links its papers deposit to:
  `data_repo_url` and `data_repo` were NA for all 8 papers because the
  Crossref relation metadata was empty and the fallback planned for #27
  never ran. The links were verified against Crossref relations, DataCite
  resource types, and the articles' availability sections, and are recorded
  in `data-raw/datapapers_repo_fixes.csv`, applied during processing. Seven
  papers use general repositories (GBIF, IEEE DataPort, Figshare, Dryad,
  NCBI BioProject, Zenodo); none uses a WASH sector platform.
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
