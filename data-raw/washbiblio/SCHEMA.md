# washbiblio corpus schema (draft)

Bibliometric corpus of WASH & FSM research, 1996–2026, harvested from OpenAlex.
This is a **separate data package** from washopenresearch (issue #18 decision):
zero manual curation, fully script-generated, refreshable with one run.

Two flat relational tables, no list-columns (openwashdata convention, cf. #8).
Join key: `work_id`.

## Table 1: `works` (one row per publication)

| variable | type | description |
|---|---|---|
| work_id | character | OpenAlex work ID (e.g. W2041...), primary key |
| doi | character | DOI, lowercased, no https prefix |
| title | character | Work title |
| published_year | integer | Publication year |
| journal | character | Host venue display name |
| source_id | character | OpenAlex source ID of the venue |
| publisher | character | Publisher display name |
| type | character | Work type (article, review, book-chapter, ...) |
| is_oa | logical | Open access status |
| oa_status | character | gold / green / hybrid / bronze / closed |
| cited_by_count | integer | Citation count at harvest time |
| funder | character | Funders, "; "-collapsed |
| matched_block | character | Keyword block(s) that matched, "; "-collapsed (core/sanitation/fsm/...) |
| n_authors | integer | Number of authorships |

## Table 2: `authorships` (one row per author-per-work)

| variable | type | description |
|---|---|---|
| work_id | character | Foreign key to works.work_id |
| author_position | character | first / middle / last |
| author_id | character | OpenAlex author ID |
| author_name | character | Author display name |
| orcid | character | ORCID if present |
| institution | character | First listed institution display name |
| institution_country | character | ISO country of institution, UN_en-normalized |

## Design note: why this schema, now

The `authorships` table with `author_position` + `institution_country` is what the
2027 authorship-equity follow-up paper needs (first/last-author country vs. study-site
country). Capturing it from the first harvest means that paper is a re-analysis, not a
re-harvest. Do not drop these columns to save space.

## Harvest window

1996–2026. Rationale in issue #18: prominence and journal identification are
mismeasured in a 15-year window; OpenAlex metadata degrades before ~1995.

## Matching note

The ranking steps (harvest_corpus.R steps 1-5) match on OpenAlex
`title_and_abstract.search`, not fulltext `search`: fulltext matches ~9.6M
works with noisy author rankings, title+abstract ~2.1M with the expected WASH
researchers on top. The corpus pull for the tables above should use the same
filter so corpus membership matches the rankings.
