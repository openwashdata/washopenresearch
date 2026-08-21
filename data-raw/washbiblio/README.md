# washbiblio — WASH & FSM bibliometric corpus (staging)

Staging area for the bibliometric corpus agreed in
[issue #18](https://github.com/openwashdata/washopenresearch/issues/18).
This work will move to its **own openwashdata package/repository** once the
harvest is validated; it lives here only until that repo exists.

It is a **separate artifact** from the hand-curated washopenresearch datasets
(washdev, uncnewsletter, ploswater): fully script-generated from OpenAlex, no
manual curation, refreshable with one run. Do not merge these tables into the
curated datasets.

## Contents

- `wash-keywords.csv` — keyword list, grouped into blocks (core / sanitation /
  fsm / hygiene / contamination / health / policy). Seed from issue #18.
- `SCHEMA.md` — the two-table corpus schema (`works`, `authorships`) and the
  rationale for capturing author-position + institution-country now (2027
  authorship-equity follow-up).
- `harvest_corpus.R` — OpenAlex harvest script (skeleton; run where outbound
  network is available). Its intermediate outputs answer issue #18 steps 1, 3,
  and 4 with real numbers.
- `pull_journal_identifiers.R` — issue #38 step 1: one OpenAlex source GET per
  in-scope journal for the ISSN join key plus empirical OA flags and the
  works-level oa_status mix. Writes `journal-identifiers.csv`.
- `pull_oa_policies.R` — issue #38 step 2: queries the Jisc Open Policy Finder
  by ISSN for each journal's permitted-OA policy. Needs `OPENPOLICYFINDER_KEY`
  in `~/.Renviron`. Writes `oa-policies.csv`; raw JSON cached in `cache/opf/`.
- `join_top_factor.R` — issue #38 step 3: joins TOP Factor data-policy scores
  by ISSN (source CSV downloaded from the COS OSF project into `cache/`).
  Writes `top-factor-scores.csv`.
- `measure_behavioral_coverage.R` — issue #38 step 4: counts observed-practice
  coverage per journal from the PLOS Open Science Indicators dataset (PLOS
  articles by DOI pattern; the ~31k comparator DOIs resolved to OpenAlex
  sources in batched lookups) plus our own whole-journal scrapes. The
  AAAS/Dryad file is optional and hand-downloaded (bot-check on Dryad).
  Writes `behavioral-coverage.csv`.
- `build_coverage_assessment.R` — issue #38 step 5: merges the three layers
  into `coverage-assessment.csv`, one row per journal, with the
  `residual_for_35` flag marking journals no behavioral source covers.

## Window

1996–2026 (30 years). Rationale in issue #18.

## Planned outputs

1. The corpus, published as a data descriptor (Scientific Data / Data in Brief)
   with its own Zenodo DOI.
2. Substrate for the open-data meta-research manuscript (in preparation,
   builds on washopenresearch).
3. Substrate for a possible 2027 authorship-equity follow-up (separate repo).
