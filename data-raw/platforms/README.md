# WASH data platforms evaluation (issue #26)

Evidence for the platforms section of
`vignettes/articles/data-availability-washdev.Rmd`. All facts were verified
against live sources on 2026-07-23; each carries a source URL in the CSVs.

## Files

- `platforms.csv` - scoping sheet, one row per platform, with the canonical
  facts (operator, URL, coverage, content model) and an in/borderline/out
  scope decision with a reason. Thirteen platforms screened; mWater and
  Project W are the two the paper is built around.
- `rubric.csv` - long-format evaluation, one row per platform and rubric item,
  across three dimensions: access, documentation, research_linkage. Filled in
  full for the in-scope platforms (mWater, Project W) and where the research
  verified specifics for WPdx and IBNET. "Not found" is recorded literally
  where a public page did not state a fact.
- `scan_platform_mentions.R` - scans the `das` text and repository-link columns
  of the package datasets for each platform's domain and name. Run from the
  package root.
- `platform_mentions.csv` - output of the scan: per platform and dataset, the
  count of data availability statements that mention it in text and in a
  repository link.
- `vignette-intro-draft.md` - the drafted prose plus review notes, kept for
  reference. The same prose is already in the vignette.

## Key finding

Across 1,782 papers (washdev, uncnewsletter, ploswater), neither mWater nor
Project W is mentioned once in a data availability statement. The only
platforms mentioned are general (not WASH-specific): DHS (twelve papers),
HDX (three), MICS (two), and one IBNET link.

## Project W facts

Project W is beta and sign-in gated, so its own public pages are thin. The
launch year (2022 pilot), the waitlist access model, and the restrictive
terms of use were verified through the Wayback Machine and Aquaya's own
milestones and terms pages, not the live catalogue. An exact launch date, the
post-waitlist registration policy, and whether an API or DOIs exist behind the
login remain "not found" and could only be confirmed with an account.

## Refresh with datapapers (2026-08-20)

Rerun after `datapapers` was built (issue #28): the scan now covers all four
datasets and the per-platform hits are unchanged. The first rerun exposed a
gap: the dataset shipped with `data_repo_url` NA for all 8 papers because the
repository-link backfill planned for issue #27 never happened. The links were
then backfilled the same day via `data-raw/datapapers_repo_fixes.csv` (each
row records its source: Crossref relations, DataCite, or the article's
availability section), applied in `03_datapapers_process.R`. Result: seven of
the eight data papers deposit in general repositories (GBIF twice, IEEE
DataPort, Figshare, Dryad, NCBI BioProject, Zenodo), one shares its data only
in the article tables and supplement, and none uses a WASH sector platform.
The vignette's 1,782 count stays as written (it names the three DAS-carrying
datasets; `datapapers` has no `das` column); the data-paper finding is added
as its own sentence.
