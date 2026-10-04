# data-raw: pipeline and provenance

This directory contains everything needed to rebuild the package datasets
from their sources. The work is split into two stages with a hard line
between them.

| Stage | What it does | Needs network | How it runs |
|---|---|---|---|
| Acquisition | Fetches articles from the journals and writes the raw snapshots | yes | by hand, one command for all sources |
| Build | Turns the committed raw snapshots and sheets into the package datasets, the exports and the review sheets | no | `targets` pipeline |

The build never fetches anything, so it gives the same result on any
machine, and continuous integration can run it.

All scripts are run **from the package root** and are non-interactive.

## Run order

1. Acquisition, when new articles are wanted:
   `caffeinate -i Rscript data-raw/update_sources.R` (see "Acquisition").
   The run adds to the raw snapshot of each live source.
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

``` sh
caffeinate -i Rscript data-raw/update_sources.R
```

This one command is the monthly acquisition. It runs the four IWA journals
one after the other, with a cooldown of five minutes in between, then PLOS
Water. `caffeinate -i` keeps the Mac awake; the run takes hours when many
articles are new. Naming sources runs a subset, for example
`Rscript data-raw/update_sources.R jwh ploswater`.

| Source | Scraper, run by the update command | Raw snapshot |
|---|---|---|
| Journal of Water, Sanitation and Hygiene for Development, Journal of Water and Health, AQUA, Water Supply | `iwa_scraping.R <washdev\|jwh\|aqua\|ws>` | `washdev.csv`, `jwh.csv`, `aqua.csv`, `ws.csv` |
| PLOS Water | `ploswater.R` | `ploswater.csv` |

Each scraper runs as its own R process, because the IWA scraper and the PLOS
Water downloader define helper functions with the same names. A source that
fails does not stop the others. Its failure is printed, and the command
exits with status 1 at the end. Run the command again to continue; every
scraper picks up where it stopped.

`update-log.csv` gets one row per journal and run: `date`, `journal`,
`issues_added`, `rows_added`, and `finished` (`FALSE` when the scraper
stopped with an error or could not read every page). The release notes of a
monthly update take their coverage table from it.

The IWA scraper drives a headless Chrome session, because iwaponline.com
blocks plain HTTP clients and throttles bursts of requests. It runs slowly
by design.

A run of the IWA scraper is incremental:

- It lists the journal's issues again from the newest known publication
  year and merges them into the cached manifest (`<journal>_issues.csv`).
  A year whose issue list does not load holds the manifest back, so the
  next run asks for it again.
- It scrapes every issue that is in the manifest but not in the raw
  snapshot. That covers new issues and issues an earlier run lost.
- It reads the two most recent numbered issues in the snapshot again and
  fetches the articles that were added late.
- An issue is stored complete or not at all. When a page does not load, or
  loads as something other than the page asked for (the site's "Not Found"
  page, for example), nothing of the issue is stored, the run exits with
  status 1, and the next run tries again. No row is written for an article
  that was not read.
- An issue without articles is logged as permanently empty
  (`<journal>_empty_issues.log`) only once it is two years older than the
  newest volume, because the site lists an issue before its articles are
  online.

The functions that decide what a run fetches are in `scrape_plan.R` and are
tested without network in `data-raw/tests/`. The snapshot is read as text
and written back after every issue that added articles, so the rows already
in it do not change and an interrupted run can be started again.

The download links of supplementary files on iwaponline.com are signed and
work for about three weeks. The raw snapshot keeps the file path only. The
signed links go to `data-raw/private/<journal>-signed-supp-links.csv`,
which is not committed, and `suppfiles_download.R` reads them there.

The PLOS Water downloader needs no browser. It lists all articles through
the PLOS search API, in a fixed sort order, downloads the XML of those whose
DOI is not in the snapshot yet, and appends them. The snapshot holds one row
per DOI.

Two sources are frozen. They are still built, but no longer updated:

- `uncnewsletter`: the newsletter ceased publication in May 2024. The
  snapshot combines scraped links with manual annotation.
- `datapapers`: harvested once from Crossref and Europe PMC
  (`01_datapapers_acquire.R`, `02_datapapers_screen.R`) and screened by hand
  (`make_datapapers_worklist.R`, `make_datapapers_review_app.R`,
  `apply_datapapers_decisions.R`). Screening is closed; candidates without a
  decision stay out of the build.

### Identification, pacing and robots.txt

Every client identifies the project:
`washopenresearch/<version> (https://github.com/openwashdata/washopenresearch; <contact>)`,
built by `client_user_agent()` in `data-raw/client.R` from the version in
`DESCRIPTION` and the address in `WASHOPENRESEARCH_CONTACT`. The PLOS Water
downloader sends it as its user agent. The IWA scraper appends it to the
headless browser's own user agent, which stays as it is and says
HeadlessChrome. The update command refuses to start when the address is
unset, and records the string in `update-log.csv` with every row.

Before the first request of a run, each host's `robots.txt` is read once
(`host_policy()`): the paths the run visits are checked for this client, a
disallowed path stops the run with the rule quoted, and a `Crawl-delay`
becomes the minimum pause between requests to that host. On 2026-10-04,
iwaponline.com allowed the issue and article paths and set no delay;
journals.plos.org allowed the article file path and set a delay of 30
seconds, so a PLOS Water increment fetches one article every 30 seconds (a
few per month; a full download from nothing would take four hours);
api.plos.org has no robots.txt, and its published limit of 300 requests per
hour is far above the five a run needs.

Pacing: the IWA scraper pauses a jittered 8 to 15 seconds between pages
(`IWA_PAUSE_RANGE`), 1 to 3 seconds after each load, and five minutes
between journals (`IWA_COOLDOWN`); the PLOS Water downloader pauses one
second between search pages and the crawl delay between article files;
every other client waits one second between requests unless a published
limit says more.

If a site refuses the identified client, the run fails and says so. There
is no fallback user agent and no workaround.

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

### Environment variables

Set them in `~/.Renviron`. Nothing is read from the repository, and no
address or key is committed; a test in `data-raw/tests/` scans the scripts
for both.

| Variable | Read by | Purpose, where to get it |
|---|---|---|
| `WASHOPENRESEARCH_CONTACT` | every client (`client.R`): the scrapers, the update command, the Crossref, Europe PMC and OpenAlex scripts | the contact address in the user agent and in Crossref's polite pool. Required; nothing is fetched without it |
| `OPENALEX_API_KEY` | `das_in_paper_article_types.R`, the coverage assessment scripts | a registered OpenAlex key lifts the free daily budget (https://openalex.org) |
| `OPENPOLICYFINDER_KEY` | `coverage-assessment/pull_oa_policies.R` | the Jisc Open Policy Finder API key (https://openpolicyfinder.jisc.ac.uk) |
| `IWA_PAUSE_RANGE` | `iwa_scraping.R` | "min,max" seconds between page fetches, default `8,15` |
| `IWA_COOLDOWN` | `update_sources.R` | seconds between two IWA journals, default 300 |
| `BACKFILL_DOIS_OVERWRITE` | `backfill_dois.R` | `yes` to rewrite the frozen DOI backfill sheets |

The routes of the article-level dataset (#76) add their keys to this table
as they arrive.

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
- **No author contact addresses.** The raw snapshots have had no author
  email columns since version 0.5.0, and the scrapers do not collect them.
  A contact address printed after an affiliation is masked when it is
  scraped. The git history was not rewritten, so commits up to and
  including v0.4.0 still hold these values, and the archive of v0.0.1 on
  Zenodo holds the email columns of `washdev.csv`. Addresses that authors
  wrote inside a statement stay in the raw statement text, which is the
  published statement. The build masks them before a dataset or a review
  sheet is written.
- **No credentials in the raw snapshots.** The scrapers drop access tokens
  from the URLs of a statement, replace a password stated in a statement by
  `[removed]`, and keep only the file path of the signed download links of
  supplementary files. The git history was not rewritten, so commits up to
  and including v0.4.0 still hold such values.

## Files

| File | Role | Maintained by |
|---|---|---|
| `build.R` | entry point of the build | code review |
| `check_reproducible.R` | compares a rebuild with the committed datasets | code review |
| `run_tests.R`, `tests/` | tests of the pipeline code | code review |
| `removed-keys.csv` | articles deliberately removed from a dataset, with the reason | humans (curation) |
| `pipeline/` | build, shared and writer functions of the pipeline | code review |
| `helpers.R` | shared helpers (strict CSV reader, country cleaning, email masking, journal and term lists) | code review |
| `update_sources.R` | entry point of the monthly acquisition | code review |
| `monthly-data-update.md` | checklist of the monthly data update; a workflow opens it as an issue on the 5th of each month | code review |
| `update-log.csv` | what each acquisition run added, one row per journal and run | `update_sources.R` |
| `iwa_scraping.R`, `scrape_plan.R` | scraper of the four IWA journals, and the tested functions that decide what a run fetches | code review |
| `washdev.csv`, `ws.csv`, `jwh.csv`, `aqua.csv` | raw snapshots of the iwaponline.com scrapes | scrapers |
| `*_issues.csv` | cached list of journal issues per IWA journal | scrapers |
| `ploswater.csv` | raw snapshot of the PLOS Water download | `ploswater.R` |
| `private/` | signed supplement links and other files that are not committed | scrapers |
| `unc-article-url-manual-collection.csv` | scraped URLs plus manual annotation of UNC newsletter articles | frozen |
| `journalwash4d.xlsx`, `journalwash4d_cleaned.xlsx` | early manual collection for the washdev source; not referenced by any script, kept for provenance | frozen |
| `datapapers_raw.csv` | committed snapshot of the Crossref and Europe PMC harvest | frozen |
| `datapapers_screening.csv` | one row per candidate: `doi, title, journal, published_year, auto_relevant, include, reason` | frozen |
| `datapapers_country_fixes.csv`, `datapapers_repo_fixes.csv` | corrections for data papers, keyed on `doi` | humans (curation) |
| `washdev-country-fixes.csv`, `washdev-supp-type-fixes.csv`, `uncnewsletter-supp-fixes.csv` | decision sheets keyed on `paperid` | humans (curation) |
| `*-doi-backfill.csv`, `*-doi-review.csv` | Crossref DOI matches and the rows that did not match | frozen |
| `journal_wash_share.csv` | the measured 1996 to 2026 WASH share and the indexing decision per candidate journal (#18, `docs/adr/0001`), written once on 2026-07-23 | frozen |
| `*-das-review.csv`, `*-country-review.csv` | review sheets | the build |
| `dictionary.csv` | data dictionary rendered in the README and pkgdown site | with each schema change |

The remaining scripts (`fair_scores.R`, `das_in_paper_*.R`, `suppfiles_*.R`,
`coverage-assessment/`, `platforms/`) are analyses that read the built datasets.
They are not part of the build pipeline.
