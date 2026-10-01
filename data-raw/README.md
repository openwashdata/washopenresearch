# data-raw: pipeline and provenance

This directory contains everything needed to rebuild the package datasets
from their sources. The work is split into two stages with a hard line
between them.

| Stage | What it does | Needs network | How it runs |
|---|---|---|---|
| Acquisition | Fetches articles from the journals and writes the raw snapshots | yes | by hand, one script per source |
| Build | Turns the committed raw snapshots and sheets into the package datasets, the exports and the review sheets | no | `targets` pipeline |

The build never fetches anything, so it gives the same result on any
machine, and continuous integration can run it.

All scripts are run **from the package root** and are non-interactive.

## Run order

1. Acquisition, when new articles are wanted: one command per source (see
   "Acquisition"). Each run adds to the raw snapshot of its source.
2. `Rscript data-raw/build.R`: rebuilds the datasets, exports and review
   sheets from the snapshots and sheets.
3. Read the review sheets. To act on a row, add it to a decision sheet and
   run the build again.
4. `Rscript data-raw/check_reproducible.R`, after committing the rebuilt
   data: confirms the committed datasets follow from the committed inputs.

## Build

``` sh
Rscript data-raw/build.R
```

This rebuilds whatever is out of date and writes:

- `data/<dataset>.rda`, the dataset the package ships
- `inst/extdata/<dataset>.csv` and `.xlsx`, the flat-file exports
- `data-raw/<dataset>-das-review.csv` and `-country-review.csv`, the review
  sheets of `washdev`, `ws`, `jwh`, `aqua` and `ploswater` (see below)

Only targets whose inputs changed are rebuilt, and a file is rewritten only
when its content changes, so a build on a fresh clone leaves `git status`
clean. A changed `renv.lock` counts as a changed input of every dataset.

The pipeline is defined in `_targets.R` at the package root; its functions
live in `data-raw/pipeline/`, one build function per dataset.

| Dataset | Raw snapshot | Sheets it reads | Build function |
|---|---|---|---|
| `washdev` | `washdev.csv` | `washdev-country-fixes.csv`, `washdev-supp-type-fixes.csv`, `washdev-doi-backfill.csv` | `build_iwa()` |
| `ws` | `ws.csv` | none | `build_iwa()` |
| `jwh` | `jwh.csv` | none | `build_iwa()` |
| `aqua` | `aqua.csv` | none | `build_iwa()` |
| `ploswater` | `ploswater.csv` | none | `build_ploswater()` |
| `uncnewsletter` | `unc-article-url-manual-collection.csv` | `uncnewsletter-supp-fixes.csv`, `uncnewsletter-doi-backfill.csv` | `build_uncnewsletter()` |
| `datapapers` | `datapapers_raw.csv` | `datapapers_screening.csv`, `datapapers_country_fixes.csv`, `datapapers_repo_fixes.csv` | `build_datapapers()` |

After a build that changed a dataset, finish the package integration:
`devtools::document()`, re-knit `README.Rmd`, and update the counts in the
`Description` field of `DESCRIPTION` if needed.

### Validation gate

Every built dataset passes through `validate_dataset()` before anything is
written. The build stops, naming every broken rule, when a dataset

- has columns that differ from `dictionary.csv`,
- repeats a key (`paperid`, or `doi` for `ploswater` and `datapapers`),
- holds a list column, an email column, an email address inside text, or
  an access token in a URL,
- flags an article as having a data availability statement without the
  statement text,
- has a country value that is not a UN country name,
- is frozen and changed its row count, or
- lost an article that was in the last release. An article may only leave a
  dataset through a row in `removed-keys.csv` (dataset, key, reason).

The rules are tested in `data-raw/tests/`; run them with
`Rscript data-raw/run_tests.R`.

### Checking reproducibility

``` sh
Rscript data-raw/check_reproducible.R           # against HEAD
Rscript data-raw/check_reproducible.R v0.4.0    # against a tag
```

Rebuilds every dataset and compares it with `data/<dataset>.rda` as
committed at the git ref. It exits with status 1 and prints the differences
when a dataset does not match, or when `data/` holds a dataset the pipeline
does not build.

## Acquisition

| Source | Command | Raw snapshot |
|---|---|---|
| Journal of Water, Sanitation and Hygiene for Development | `Rscript data-raw/washdev_scraping.R` | `washdev.csv` |
| Water Supply, Journal of Water and Health, AQUA | `Rscript data-raw/run_iwa_scrapes.R` (or `Rscript data-raw/iwa_scraping.R <ws\|jwh\|aqua>` for one journal) | `ws.csv`, `jwh.csv`, `aqua.csv` |
| PLOS Water | `Rscript data-raw/ploswater.R` | `ploswater.csv` |

The IWA scrapers drive a headless Chrome session, because iwaponline.com
blocks plain HTTP clients and throttles bursts of requests. They run slowly
by design and can be resumed after an interruption.

Two sources are frozen. They are still built, but no longer updated:

- `uncnewsletter`: the newsletter ceased publication in May 2024. The
  snapshot combines scraped links with manual annotation.
- `datapapers`: harvested once from Crossref and Europe PMC
  (`01_datapapers_acquire.R`, `02_datapapers_screen.R`) and screened by hand
  (`make_datapapers_worklist.R`, `make_datapapers_review_app.R`,
  `apply_datapapers_decisions.R`). Screening is closed; candidates without a
  decision stay out of the build.

## Environment

The build pipeline and the scrapers run against the package versions pinned
in `renv.lock`. The lockfile covers only those scripts (the allowlist is in
`.renvignore`); packages used for the README, the vignettes or the analysis
scripts are not locked.

No `.Rprofile` autoloader is committed. Starting R in this repository uses
your normal library, so `R CMD check`, r-universe builds and devtools
sessions are unaffected. Scripts that need the pinned packages call
`renv::load()` before attaching anything, and the pipeline refuses to run
without it.

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

## Sheets

Three kinds of CSV sheet sit next to the raw snapshots. They differ in who
writes them.

| Kind | Written by | Read by the build | Files |
|---|---|---|---|
| Decision sheet | a person | yes | `*-fixes.csv`, `datapapers_*_fixes.csv`, `datapapers_screening.csv` |
| Frozen input | a script, once | yes | `*-doi-backfill.csv` |
| Review sheet | the build | no | `*-das-review.csv`, `*-country-review.csv` |

**Decision sheets** hold manual corrections, one row per article, keyed on
`paperid` (or on `doi` for `datapapers`). A filled cell replaces the built
value; an empty cell means no decision for that column. The build stops when
a sheet repeats a key or names an article the dataset does not have.

**Frozen inputs** are the Crossref DOI matches written by `backfill_dois.R`.
The script refuses to run again, because it would overwrite both sheets,
and for `washdev` keep matches for the few rows still without a DOI only.
Setting `BACKFILL_DOIS_OVERWRITE=yes` lifts the refusal.

**Review sheets** list what the automatic steps could not resolve: data
availability statements no rule mapped to a `das_type`, and affiliations
whose country could not be standardised. Nothing is reclassified silently.
To act on a row, add a decision to a decision sheet and rebuild; never edit
a review sheet, the next build overwrites it.

## Design principles

- **Everything starts from a script.** The acquisition query itself is code,
  so anyone can re-run it and diff the committed snapshot.
- **Snapshots are committed.** API results and scrapes change over time; the
  committed snapshot is the reproducible input for the build.
- **Manual decisions live in data files, not code.** Corrections are rows in
  a decision sheet keyed on an article identifier, so a correction cannot
  land on the wrong article when rows are added or reordered.
- **Column types are stated, never guessed.** Every raw snapshot and sheet is
  read with explicit column types, and a cell that does not parse stops the
  build. A guessed type once read a statement column as logical and dropped
  539 statements.
- **No list-columns in saved objects** (issue #8): multi-value fields are
  collapsed to `"; "`-delimited strings via `collapse_list_col()` before a
  dataset is saved.
- **No author email addresses in the datasets.** The email columns are
  dropped and addresses inside text columns are masked before a dataset or
  a review sheet is written.

## Files

| File | Role | Maintained by |
|---|---|---|
| `build.R` | entry point of the build | code review |
| `check_reproducible.R` | compares a rebuild with the committed datasets | code review |
| `run_tests.R`, `tests/` | tests of the pipeline code | code review |
| `removed-keys.csv` | articles deliberately removed from a dataset, with the reason | humans (curation) |
| `pipeline/` | build, shared and writer functions of the pipeline | code review |
| `helpers.R` | shared helpers (strict CSV reader, country cleaning, email masking, journal and term lists) | code review |
| `washdev.csv`, `ws.csv`, `jwh.csv`, `aqua.csv` | raw snapshots of the iwaponline.com scrapes | scrapers |
| `*_issues.csv` | cached list of journal issues per IWA journal | scrapers |
| `ploswater.csv` | raw snapshot of the PLOS Water download | `ploswater.R` |
| `unc-article-url-manual-collection.csv` | scraped URLs plus manual annotation of UNC newsletter articles | frozen |
| `journalwash4d.xlsx`, `journalwash4d_cleaned.xlsx` | early manual collection for the washdev source; not referenced by any script, kept for provenance | frozen |
| `datapapers_raw.csv` | committed snapshot of the Crossref and Europe PMC harvest | frozen |
| `datapapers_screening.csv` | one row per candidate: `doi, title, journal, published_year, auto_relevant, include, reason` | frozen |
| `datapapers_country_fixes.csv`, `datapapers_repo_fixes.csv` | corrections for data papers, keyed on `doi` | humans (curation) |
| `washdev-country-fixes.csv`, `washdev-supp-type-fixes.csv`, `uncnewsletter-supp-fixes.csv` | decision sheets keyed on `paperid` | humans (curation) |
| `*-doi-backfill.csv`, `*-doi-review.csv` | Crossref DOI matches and the rows that did not match | frozen |
| `*-das-review.csv`, `*-country-review.csv` | review sheets | the build |
| `dictionary.csv` | data dictionary rendered in the README and pkgdown site | with each schema change |

The remaining scripts (`fair_scores.R`, `das_in_paper_*.R`, `suppfiles_*.R`,
`washbiblio/`, `platforms/`) are analyses that read the built datasets. They
are not part of the build pipeline.
