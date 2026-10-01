# data-raw: pipeline and provenance

This directory contains everything needed to rebuild the package datasets
from their sources. All scripts are run **from the package root** and are
non-interactive:

``` sh
Rscript data-raw/<script>.R
```

## Environment

The build pipeline and the scrapers run against the package versions pinned
in `renv.lock`. The lockfile covers only those scripts (the allowlist is in
`.renvignore`); packages used for the README, the vignettes or the analysis
scripts are not locked.

No `.Rprofile` autoloader is committed. Starting R in this repository uses
your normal library, so `R CMD check`, r-universe builds and devtools
sessions are unaffected. Scripts that need the pinned packages call
`renv::load()` before attaching anything.

Restore the pinned packages once after cloning, and again whenever
`renv.lock` changes:

``` sh
Rscript -e 'renv::load(); renv::restore()'
```

Run every renv command after `renv::load()`, as above. Without it,
`renv::restore()` and `renv::snapshot()` act on your global library. Do not
run `renv::activate()` or `renv::init()`: both write the autoloader this
repository leaves out.

After a pipeline or scraper script starts using a new package, update the
lockfile:

``` sh
RENV_LOCKFILE_VERSION=1 Rscript -e 'renv::load(); renv::snapshot()'
```

`RENV_LOCKFILE_VERSION=1` keeps the compact lockfile format (package,
version, source, hash). The default format copies each package's full
`DESCRIPTION` into the lockfile, including author and maintainer email
addresses, which do not belong in this repository.

## Run order

### `datapapers` (issue #28)

| Step | Script | Input | Output |
|---|---|---|---|
| 1 | `01_datapapers_acquire.R` | Crossref + Europe PMC APIs | `datapapers_raw.csv` (committed snapshot) |
| 2 | `02_datapapers_screen.R` | `datapapers_raw.csv` | `datapapers_screening.csv` (decision sheet) |
| — | *manual screening* | `datapapers_screening.csv` | fill `include` + `reason`, commit |
| 3 | `03_datapapers_process.R` | snapshot + decision sheets | `data/datapapers.rda`, `inst/extdata/datapapers.{csv,xlsx}` |

After step 3, finish the package integration:
`devtools::document()`, re-knit `README.Rmd`, and update the counts in
`DESCRIPTION`'s `Description` field if needed.

Step 1 needs network access to `api.crossref.org` and `www.ebi.ac.uk`
(Europe PMC). Steps 2 and 3 run offline from the committed files.

### `washdev` and `uncnewsletter` (legacy sources)

| Step | Script | Input | Output |
|---|---|---|---|
| 1 | `inst/python/washdev_scraping.py` (+ `_selenium.py`) | iwaponline.com | `washdev.csv` |
| 1 | `inst/python/uncnewsletter_scraping.py` + manual annotation | UNC newsletter archive | `unc-article-url-manual-collection.csv` |
| 2 | `data_processing.R` | the two snapshots above | `data/*.rda`, `inst/extdata/*.{csv,xlsx}` |

## Design principles

- **Everything starts from a script.** The acquisition query itself is code,
  so anyone can re-run it and diff the committed snapshot.
- **Snapshots are committed.** API results and scrapes change over time; the
  committed snapshot (with `retrieval_date` and `query_term` recorded per
  row for `datapapers`) is the reproducible input for downstream steps.
- **Manual decisions live in data files, not code.** Inclusion screening and
  country corrections for `datapapers` are CSV decision sheets keyed on DOI
  (`datapapers_screening.csv`, `datapapers_country_fixes.csv`); scripts join
  on them and never overwrite a filled decision. (The legacy
  `data_processing.R` still uses hard-coded ID vectors for `washdev` /
  `uncnewsletter`; new manual decisions should use decision sheets.)
- **No list-columns in saved objects** (issue #8): multi-value fields are
  collapsed to `"; "`-delimited strings via `collapse_list_col()` before
  `use_data()`.

## Files

| File | Role | Maintained by |
|---|---|---|
| `helpers.R` | shared helpers (`collapse_list_col()`, country cleaning, journal/term lists) sourced by all processing scripts | code review |
| `washdev.csv` | snapshot of the iwaponline.com scrape (see `inst/python/`) | re-scrape |
| `unc-article-url-manual-collection.csv` | scraped URLs + manual annotation of UNC newsletter articles | annotators |
| `journalwash4d.xlsx`, `journalwash4d_cleaned.xlsx` | early manual collection for the washdev source; not referenced by any script, kept for provenance | frozen |
| `datapapers_raw.csv` | committed snapshot of the Crossref/Europe PMC harvest | `01_datapapers_acquire.R` |
| `datapapers_screening.csv` | one row per candidate: `doi, title, journal, published_year, auto_relevant, include, reason` | humans (screening) |
| `datapapers_country_fixes.csv` | `doi, first_author_affiliation_country` for papers whose affiliation cannot be standardised automatically | humans (curation) |
| `dictionary.csv` | data dictionary rendered in the README and pkgdown site | with each schema change |
