# washopenresearch (development version)

## Bug fixes

- `washdev`: eight articles had no author data, and their rows could not be
  told apart from a failed scrape, because the earlier scraper wrote the
  same row in both cases. All eight were scraped again with the scraper
  that writes a row only for a page it has read (#72).

  - Article 99218 (volume 13, issue 12) was incomplete. It now has its nine
    authors, its data availability statement ("in paper"), its keywords and
    the countries of its authors.
  - The corrigendum 96121 (volume 13, issue 7) now has its six authors, the
    name and ORCID iD of its first author, and its DOI.
  - Six rows are confirmed as they were: the two letters to the editor
    30083 and 30084, the corrigendum 30156, the erratum 73058, the
    editorial 80712 and the obituary 90481. Their pages have no author card
    and no data availability statement.
  - The DOI of the letter 30084 is corrected to 10.2166/washdev.2014.103.
    The title search that filled missing DOIs had given it the DOI of the
    other letter with the same title.

## New data

- `washdev`: one article of volume 13, issue 12 that the journal added to
  the issue after the first scrape is new (paperid 99266). The dataset has
  1,174 articles.

# washopenresearch 0.5.0

This release makes the build of the datasets reproducible and prepares
monthly data updates. The data of the six datasets of 0.4.0 changes only
through the fixes listed below, and `aqua` joins as the seventh dataset.
No new journal issues are added yet; the first monthly update follows as
0.6.0.

## Coverage

Five datasets are updated monthly from now on. `uncnewsletter` and
`datapapers` are frozen: still built with every release, no longer
updated.

| Dataset | Updates | Articles | Years | Latest issue |
|---|---|---:|---|---|
| `washdev` | monthly | 1,173 | 2011 to 2026 | Vol. 16 Issue 6 |
| `ws` | monthly | 4,884 | 2001 to 2026 | Vol. 26 Issue 6 |
| `jwh` | monthly | 2,013 | 2003 to 2026 | Vol. 24 Issue 6 |
| `aqua` | monthly | 1,819 | 1998 to 2026 | Vol. 75 Issue 6 |
| `ploswater` | monthly | 434 | 2022 to 2026 | Vol. 5 Issue 7, published up to 2026-07-06 |
| `uncnewsletter` | frozen | 173 | 2020 to 2023 | newsletter ceased in May 2024 |
| `datapapers` | frozen | 8 | 2018 to 2025 | harvested on 23 July 2026 |

## Reproducible build

- The datasets are built by a `targets` pipeline from the raw snapshots and
  decision sheets committed in `data-raw/`, with the package versions
  pinned in `renv.lock`. One command rebuilds everything:
  `Rscript data-raw/build.R`. Manual corrections moved from the code into
  decision sheets keyed on the article identifier.

- A validation gate checks every dataset before anything is written:
  documented columns, a unique key, no email addresses or credentials,
  statement text wherever a statement is flagged, UN country names, and no
  article lost since the last release.

- A workflow on GitHub rebuilds the datasets on every push and pull request
  and fails when they differ from the committed data
  (`data-raw/check_reproducible.R`).

- Zenodo files the release as a dataset in the openwashdata community,
  from the new `.zenodo.json`. The releases 0.1.0, 0.3.0 and 0.4.0 were
  never archived there.

## New features

- New dataset `aqua`: all 1,819 articles of the journal AQUA - Water
  Infrastructure, Ecosystems and Society in the journal's online archive,
  1998 to 2026, with the same columns as `ws` and `jwh`. 539 articles carry
  a data availability statement; 529 of these map to a shared `das_type`
  and the remaining 10 keep their full text and are listed in
  `data-raw/aqua-das-review.csv`.

  The 0.4.0 notes said AQUA needed a re-scrape because its statement text
  had never been captured. That was wrong. The statements were in the raw
  snapshot all along. The build read the snapshot with guessed column
  types, the journal's first statement sits beyond the rows a guess looks
  at, so the statement column was read as logical and came back empty. The
  build now states every column type (#52).

## Bug fixes

- `washdev`: 33 correspondence author countries were three letter ISO codes
  ("IND", "GBR") in a column that otherwise holds United Nations country
  names. 32 are now the UN name. The 33rd, an affiliation in Taiwan, is
  missing, as it already was in the first author column: the UN names have
  no entry for it. The article is listed in
  `data-raw/washdev-country-review.csv`.

- `ploswater`: two articles appeared twice
  (10.1371/journal.pwat.0000024 and 10.1371/journal.pwat.0000520), each as
  two rows identical in every column. The dataset now has 434 rows, one
  per article. The cause was a search query paged without a sort order.

- Credentials are removed from the text of the datasets. Where a statement
  linked a restricted Zenodo record through an access token, the token
  parameter is now dropped and the plain record URL kept; up to v0.4.0 the
  URL kept the parameter with a placeholder value and did not resolve
  (`ploswater`, one article). Where authors wrote a password into their
  statement, such as the login of an FTP site, the password is replaced by
  `[removed]` and the rest of the sentence kept (`ploswater` and `ws`, one
  statement each).

- `ws`: one data availability statement kept an author email address in
  `das_type`. The masking of addresses inside text, introduced in v0.4.0,
  skipped that column because it is a factor. The address is now masked
  there as it already was in `das`.

## Changes

- `washdev`, `ws`, `jwh`: the levels of `das_type` now list the shared
  statement types first ("available in online repository", "in paper",
  "on request"), followed by the statements no rule mapped. Before, the
  three types sat scattered among the statements in alphabetical order.
  Values are unchanged; code that relies on the integer codes of the factor
  needs checking.

- Credentials are removed from the raw snapshots in `data-raw/`, as they
  already were from the datasets. The download links of supplementary files
  in `washdev.csv`, `ws.csv`, `jwh.csv` and `aqua.csv` lose their signed
  query and keep the file path (1,752 links of 1,532 articles, all expired
  since August 2026). In `ploswater.csv` the access tokens in the URLs of
  one statement are dropped. A password that authors wrote into their
  statement is replaced by `[removed]` (`ploswater.csv` and `ws.csv`, one
  statement each). The scrapers apply the same rules to new articles. The
  datasets are unchanged. The git history was not rewritten, so commits up
  to and including v0.4.0 still hold these values.

- The raw snapshots (`washdev.csv`, `ws.csv`, `jwh.csv`, `aqua.csv` and
  `ploswater.csv`) no longer have the columns `first_author_email` and
  `correspondence_author_email`, and the scrapers no longer collect author
  email addresses. Contact addresses that some article pages print after
  the affiliation are masked in the same way as in the datasets
  (`washdev.csv` 10 articles, `aqua.csv` 4), and the scraper masks them in
  new articles. No other value in the snapshots changed, and the datasets
  are unchanged.

  The git history was not rewritten. Commits up to and including v0.4.0
  still hold the removed values, and the archive of v0.0.1 on Zenodo holds
  the email columns of `washdev.csv`. Addresses that authors wrote inside a
  data availability statement stay in the raw statement text, which is the
  published statement, and are masked in the datasets as before.

## Data acquisition

- The scraper of the IWA journals is incremental. A run lists the journal
  issues again from the newest known publication year, scrapes the issues
  that are missing from the raw snapshot, and reads the two most recent
  issues again to fetch articles that were added late. An
  issue that the site lists before its articles are online is asked for
  again on the next run. The functions that decide what a run fetches are
  tested without network.

- The scraper stores an issue complete or not at all, and writes no row for
  an article whose page was not read. A page counts as read only when the
  site served the kind of page that was asked for. Its "Not Found" page
  loads completely too and was taken for an article without authors,
  statement or supplement, or for an issue without articles.

- `washdev` is scraped by the same scraper as `ws`, `jwh` and `aqua`
  (`data-raw/iwa_scraping.R`). The separate `data-raw/washdev_scraping.R`
  and the runner `data-raw/run_iwa_scrapes.R` are removed. The old washdev
  scraper read a throttled page as "no more issues" and stored an
  article that failed to load as an empty row. The index column that the
  first Python scraper left in `data-raw/washdev.csv` is removed. The
  dataset `washdev` is unchanged.

- The signed download links of supplementary files, which work for about
  three weeks, are written to `data-raw/private/`, which is not committed.
  `data-raw/suppfiles_download.R` reads them there.

- One command runs the monthly acquisition for every live source:
  `Rscript data-raw/update_sources.R`. It runs the four IWA journals in
  sequence with a cooldown, then PLOS Water, each as its own R process. A
  source that fails does not stop the others, and `data-raw/update-log.csv`
  records per journal and run how many journal issues and rows were added.

- The PLOS Water downloader can run incrementally. It failed on the second
  run, because it read the existing snapshot with guessed column types and
  could not combine the publication date with the new rows. It now pages
  the search in a fixed sort order and keeps one row per DOI. The two
  repeated rows are removed from `data-raw/ploswater.csv`; the dataset has
  been without them since the fix listed above. The unsorted paging had
  also skipped two articles (10.1371/journal.pwat.0000223 and
  10.1371/journal.pwat.0000302). They enter the dataset with the next data
  update.

- A workflow opens an issue on the 5th of each month with the checklist of
  the monthly data update (`data-raw/monthly-data-update.md`).

## Documentation

- The help pages and the README say which datasets are updated monthly and
  which are frozen, and the README has a coverage table that is computed
  from the datasets.

- `uncnewsletter`: the `citations` column is now described in the help page
  and the data dictionary. It has been in the dataset since its first
  release without documentation. The source of the counts is not recorded.

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
  takes the corpus to 8,403 screened articles. Data availability statements
  were mapped to the shared `das_type` levels for 1,596 of 1,623 statements in
  `ws` and 717 of 733 in `jwh`; the unmapped tail keeps the full statement text
  and is listed in `data-raw/ws-das-review.csv` and
  `data-raw/jwh-das-review.csv` (#12).

- A fourth IWA journal, AQUA, was scraped in the same run but is not exported.
  539 of its 1,819 rows carry `has_das` TRUE while `das` and `das_type` are
  empty, so the statement text was never captured and the dataset's central
  variable would ship empty. It needs a re-scrape first.

- Yash Dubey is added as an author (#31). The contribution predates the R
  port: the Selenium-based scraper and a washdev data update, committed in
  December 2024 under the GitHub Action identity, which is why it was missed
  when the author list was last reviewed.

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
