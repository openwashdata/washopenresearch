# data-raw/coverage-assessment: policy and coverage layers per journal (#38)

For each journal in scope (`data-raw/journal_wash_share.csv`: the 46
filtered-slice candidates and the four whole-journal IWA titles), these
scripts measure three things that are often conflated under "open access":
which open access route the publisher permits (Jisc Open Policy Finder),
which data policy the journal requires (TOP Factor), and which open datasets
already observe practice per article (PLOS Open Science Indicators, the
AAAS/Dryad metrics). The residual, journals no behavioural source covers,
is what bespoke scraping would still have to do. The method and the sources
are recorded on issue #38.

These scripts read the built datasets and the frozen journal share table.
They are not part of the build pipeline and never change a dataset.

## Scripts, in run order

| Script | Step | Writes |
|---|---|---|
| `pull_journal_identifiers.R` | #38 step 1: one OpenAlex source GET per journal for the ISSN join key, the empirical OA flags and the works-level `oa_status` mix | `journal-identifiers.csv` |
| `pull_oa_policies.R` | #38 step 2: queries the Jisc Open Policy Finder by ISSN for each journal's permitted OA policy. Needs `OPENPOLICYFINDER_KEY` in `~/.Renviron`; raw JSON cached under `cache/opf/` | `oa-policies.csv` |
| `join_top_factor.R` | #38 step 3: joins the TOP Factor data policy scores by ISSN (the source CSV is downloaded from the COS OSF project into `cache/`) | `top-factor-scores.csv` |
| `measure_behavioral_coverage.R` | #38 step 4: observed-practice coverage per journal from the PLOS Open Science Indicators dataset (PLOS articles by DOI pattern, the comparator DOIs resolved to OpenAlex sources in batched lookups) and our own whole-journal scrapes. The AAAS/Dryad file is optional and downloaded by hand | `behavioral-coverage.csv` |
| `build_coverage_assessment.R` | #38 step 5: merges the three layers into one row per journal, with `residual_for_35` marking journals no behavioural source covers | `coverage-assessment.csv` |
| `pull_matched_works.R` | the WASH-matched work lists of the three IWA journals taken on in #32 to #34, so the scraped datasets can carry a per-article match flag | `matched-works-{aqua,jwh,ws}.csv` |

Run every script from the package root, for example
`Rscript data-raw/coverage-assessment/pull_journal_identifiers.R`.

## Other files

- `das_platform_mapping.csv`: the journals of the share table with their
  publisher, for the per-platform grouping of #35.
- `wash-keywords.csv`: the 59-term keyword list the matched works were
  computed with. It is frozen here so that the matched-works files stay
  reproducible. The list is maintained in openwashdata/washbib, which has
  extended it since.
- `cache/`: per-request caches, not tracked.

## History

Until 2026-10-04 these files lived in `data-raw/washbiblio/`, next to the
staging of the bibliometric corpus. That staging (the ranking harvest, the
corpus schema, the three ranking tables) moved to openwashdata/washbib, and
the journal share table it produced stays at `data-raw/journal_wash_share.csv`
as the record of the #18 decision (see `docs/adr/0001-journal-share-governs-whole-journal-indexing.md`).
