# Protocol: article-level capture of WASH research and its data availability statements

Status: proposal, 2026-10-04. Supersedes the "filtered slice by journal share"
idea in issue #35 for generalist journals. Builds on the #18 decision that
journal share governs whole-journal indexing only.

## 0. Goal and non-goals

Goal. Capture WASH research articles wherever they are published, including
journals where WASH is a small fraction of output (ES&T, PLOS NTD, Water
Research, STOTEN, Lancet Global Health, TMIH, AJTMH), and record for each the
same data-availability fields the curated washopenresearch datasets hold.
Absolute yield matters, journal share does not: 2,000 WASH articles in a
journal that is 10 percent WASH are worth having.

Non-goals. Replacing the whole-journal datasets (washdev, ws, jwh, aqua,
ploswater); they stay as they are. Scraping publisher sites that forbid it.
Building a general bibliometric corpus; that is washbib's job.

## 1. Division of labour between the two repositories

washbib (openwashdata/washbib): discovery. Produces a versioned DOI list of
WASH articles with the evidence for each inclusion. Pure OpenAlex work, no
publisher sites touched.

washopenresearch: acquisition and assessment. Consumes a named version of the
DOI list, fetches each article's data availability statement and
supplementary-file facts through sanctioned routes, and publishes the result
as one new dataset. Records which washbib version it consumed.

The join key is the DOI. Neither repository copies the other's code. The
staging folder data-raw/washbiblio in washopenresearch moves to washbib; a
short ADR and the frozen journal_wash_share.csv stay behind as the record of
the #18 decision.

## 2. Discovery (washbib)

2.1 Query signals. Three independent signals, each computed for all OpenAlex
works 1996-2026 of type article or review.

  S1 Keyword. title_and_abstract.search using only the core, sanitation, fsm,
     hygiene and health blocks of wash-keywords.csv. The contamination and
     engineering blocks are excluded from discovery; they are what makes
     Journal of Biological Chemistry look 16 percent WASH.
  S2 Author. Any authorship by a researcher in the retained set of
     researcher_ranking.csv (the low-share screen already removed the false
     positives).
  S3 Citation. Two or more entries in referenced_works that are DOIs of
     washdev or ploswater articles.
  S4 Optional. An OpenAlex topic or subfield specific to WASH, if one exists.
     Check and document; use as a signal, not a replacement.

2.2 Scoring. Tier A: two or more signals. Tier B: S1 alone. Tier C: S2 or S3
alone. Tier A enters the DOI list. Tier B enters after the precision check in
2.3 passes for its journal group. Tier C is kept in the list with a flag but
is not fetched until reviewed.

2.3 Validation, before any fetching.
  Recall: share of washdev and ploswater DOIs recovered by S1, by S2, by S3
  and combined. Target: combined recall at or above 90 percent. If below,
  widen the keyword blocks, never the engineering ones, and rerun.
  Precision: 200 random Tier A plus Tier B works from the generalist journals
  (STOTEN, PLOS ONE, Scientific Reports, ESPR, Water Research), hand-labelled
  WASH yes/no/unsure by two people. Target: Tier A at or above 90 percent,
  Tier B at or above 75 percent. Record the labelled sample in the repo as
  the validation set.
  Both numbers go into the data paper and into every release note.

2.4 Output. One CSV per release, named by date and git tag:
  doi, openalex_id, title, year, journal, issn_l, publisher, type, is_oa,
  oa_status, oa_url, pmcid, signals (semicolon list), tier, n_authors,
  first_author_country, corresponding_author_country if present.
  Plus a summary table: works per journal per tier, and the eight journals
  of interest reported explicitly (ES&T, ES&T Water, PLOS NTD, PLOS ONE,
  STOTEN, Water Research, IJHEH, TMIH, AJTMH, Lancet Global Health).

2.5 Cadence. Quarterly rerun. OpenAlex calls are cached; a rerun costs cents.

## 3. Acquisition (washopenresearch)

3.1 Principle. One fetcher, driven by a DOI list, that tries routes in a fixed
order and records which route produced the statement. Every route is an API
or an open-access copy. No route fetches a publisher HTML page that sits
behind bot detection, and no route presents a false user agent.

3.2 Routes, in order of attempt and of build priority.

  R1 PLOS. Search API plus JATS XML at journals.plos.org, as in
     data-raw/ploswater.R, keyed by DOI instead of journal. Covers PLOS NTD,
     PLOS ONE, PLOS Global Public Health, PLOS Medicine. Mandatory statements,
     CC BY. Build first.
  R2 Europe PMC. REST fullTextXML for any work with a PMC id. JATS with a
     data-availability section where the journal has one. Covers OA health
     journals, BMC, Lancet Global Health OA articles, and NIH- or
     Gates-funded ES&T and Water Research papers deposited as author
     manuscripts. Build second; it reaches across publishers.
  R3 Springer Nature TDM API. Free researcher key, JATS for OA articles,
     standard data availability section. Covers npj Clean Water, ESPR,
     Scientific Reports, BMC titles not already in PMC.
  R4 MDPI. Fully OA; statement section labelled in HTML; most IJERPH and
     Water articles also in PMC via R2. Use the article XML where offered.
  R5 Elsevier Article Retrieval API. Institutional key, TDM terms accepted
     through the institution. Full-text XML with the data availability
     section for subscribed content. Covers Water Research, STOTEN, IJHEH,
     Journal of Environmental Management, Journal of Hazardous Materials.
  R6 Wiley TDM. Crossref click-through token; returns PDF only; statement
     extracted from text. Covers TMIH and Wiley-hosted titles.
  R7 ACS. No API; TDM by written agreement only. Until an agreement exists,
     fetch nothing from pubs.acs.org. Take only OA copies that Unpaywall or
     OpenAlex point to (mostly PMC, already covered by R2). Everything else
     is recorded as not retrieved.
  R8 Fallback. Unpaywall OA PDF, text extraction, regex on a data
     availability heading. Flagged as lower confidence.

  Not retrieved is a valid outcome and is reported, not hidden. A journal
  where 40 percent of statements are reachable stays in the dataset; the
  60 percent is a finding about publisher openness.

3.3 Fields. The ploswater schema (paperid, doi, journal, title,
published_year, volume, issue, num_authors, first and corresponding author
name, affiliation, country, ORCID, has_das, das, das_type, das_repo_url,
das_repo_name, is_supp, num_supp, supp_file_type, supp_url, keywords,
article_type, publication_date) plus:
  source_route (R1 to R8 or not_retrieved),
  discovery_tier (A, B, C) and discovery_signals,
  washbib_release (the version consumed),
  retrieved_at.

3.4 Classification of the statement. Reuse the existing das_type rules and
the review-sheet workflow (data-raw/<dataset>-das-review.csv). Expect more
free-text variety than the IWA boilerplate; budget review time accordingly.
Free text that no rule matches is classified in the review sheet, not left
in das_type.

3.5 Redaction and validation. Same gates as the current pipeline: no email
addresses, no credentials in URLs, no stated passwords, UN country names,
unique key, statement text wherever has_das is TRUE.

3.6 Identification and pacing. Every client sends a user agent of the form
"washopenresearch/<version> (https://github.com/openwashdata/washopenresearch;
<contact address>)". API keys and the contact address come from environment
variables, never from the repo. Pacing follows each API's published limits;
default one request per second where none is published. Each run writes to
update-log.csv as now.

3.7 Cadence. Quarterly, aligned with the washbib release. Incremental: only
DOIs not yet in the dataset, plus a re-fetch of rows whose source_route was
not_retrieved if a new route has been added since.

## 4. Dataset shape and naming

One new dataset in washopenresearch, working name washarticles, documented
in dictionary.csv like the others, exported to CSV and XLSX, with its own
coverage table in the README: WASH articles found per journal, statements
retrieved, by route. It is not merged into the five whole-journal datasets.
A paper that is in both a whole-journal dataset and the DOI list is kept in
the whole-journal dataset only; the article-level dataset records the
overlap count.

## 5. Order of work and acceptance criteria

Phase 1, discovery (washbib). Deliverable: first DOI list release with recall
and precision numbers meeting 2.3, and the per-journal yield table.
Acceptance: combined recall at or above 90 percent on washdev and ploswater;
Tier A precision at or above 90 percent on the labelled sample.

Phase 2, PLOS and Europe PMC routes (washopenresearch). Deliverable: the
fetcher with R1 and R2, run on the Phase 1 list, coverage reported per
journal. Acceptance: every PLOS DOI resolved; Europe PMC coverage reported;
validation gates pass; nothing fetched outside the two APIs.

Phase 3, Springer, MDPI, Elsevier, Wiley routes. Each route is its own
branch and pull request, each with the coverage delta it adds. Elsevier and
Wiley need the institutional and click-through credentials in place first.

Phase 4, ACS. Send the TDM agreement request. If granted, add the route under
its terms; if not, ES&T remains OA-copies-only and the README says so.

Phase 5, first release. Dataset, dictionary entry, README coverage table,
NEWS entry, Zenodo version. Close issue #35 with a note that platform routes
replaced the per-journal check.

## 6. Housekeeping that this protocol depends on

- Move data-raw/washbiblio to washbib; leave an ADR and journal_wash_share.csv.
- Fix the IWA scraper identification (honest user agent, robots.txt check) so
  the project has one consistent access policy across all sources.
- Add the legal-basis and ethics section to the README so the new dataset is
  born documented.
- Put the contact address and all API keys in environment variables and
  document them in data-raw/README.md.

## 7. Prompts, one per phase, for a local Claude Code session

Phase 1 (run in washbib):
  Build an article-level WASH discovery query against OpenAlex, 1996-2026,
  independent of journal, with three signals: S1 title_and_abstract.search
  on the core, sanitation, fsm, hygiene and health blocks of
  wash-keywords.csv only; S2 any author in the retained set of
  researcher_ranking.csv; S3 two or more referenced works among the DOIs of
  washopenresearch's washdev and ploswater datasets. Check whether OpenAlex
  has a WASH topic or subfield and report it as a possible S4. Assign tiers:
  A two or more signals, B S1 alone, C S2 or S3 alone. Measure recall against
  washdev and ploswater DOIs per signal and combined; tune the keyword blocks
  (never adding engineering terms) until combined recall is at least 90
  percent. Export the DOI list with the columns in section 2.4 of the
  protocol, a per-journal per-tier yield table, explicit rows for ES&T,
  ES&T Water, PLOS NTD, PLOS ONE, STOTEN, Water Research, IJHEH, TMIH, AJTMH
  and Lancet Global Health, and a 200-row random Tier A plus B sample from
  the generalist journals for manual precision labelling. Use cached
  responses where present and the polite pool otherwise.

Phase 2 (run in washopenresearch):
  Generalise data-raw/ploswater.R into a DOI-driven statement fetcher per
  section 3 of the protocol. Input: the washbib DOI list release. Routes for
  now: R1 PLOS API plus JATS for PLOS DOIs, R2 Europe PMC fullTextXML for any
  PMC id; everything else recorded as not_retrieved. Output rows in the
  ploswater schema plus source_route, discovery_tier, discovery_signals,
  washbib_release and retrieved_at. Apply the existing redaction and
  validation gates, an identifying user agent from an environment variable,
  and one request per second. Report coverage per journal and per route.
  Do not fetch any publisher HTML page. Tests for the parsers using fixture
  XML, no network in tests.

Phase 3 (one prompt per route, run in washopenresearch):
  Add route R<n> (<publisher>) to the statement fetcher per section 3.2 of
  the protocol, with credentials read from environment variables documented
  in data-raw/README.md. Re-run on rows whose source_route is not_retrieved
  and report the coverage delta per journal. Fixture-based tests, no network.

Phase 4:
  Draft the text and data mining agreement request to ACS Publications for
  Environmental Science & Technology and ES&T Water: metadata and data
  availability statements only, non-commercial research, quarterly,
  identified client, the project description and the openwashdata
  attribution. Until it is granted, confirm the fetcher never contacts
  pubs.acs.org.

Phase 5:
  Prepare the first release of the article-level dataset: dictionary rows,
  README section with the coverage table and the recall and precision
  numbers from washbib, NEWS entry, man page, pkgdown rebuild, and a comment
  closing issue #35 that explains the switch from per-journal checks to
  platform routes.
