---
status: accepted
date: 2026-10-04
---

# The IWA journals stay on page crawling for the statement; Crossref carries discovery and the overview

Context: the IWA scraper reads iwaponline.com with a headless browser, and since the client identifies itself (#78) the site refuses it. Issue #90 asked what Crossref and Europe PMC can replace. Measured on 2026-10-04 with `data-raw/coverage-assessment/api-routes/api_routes_iwa.R`; the tables are next to it.

## What Crossref carries

Works per year, Crossref works / dataset rows (the dataset counts the issue year, Crossref the publication date, so single years differ while the totals agree; the 2026 gap is the dataset's lag, which a Crossref count would detect):

| Journal (ISSN) | 2021 | 2022 | 2023 | 2024 | 2025 | 2026 | 1996 to 2026 |
|---|---|---|---|---|---|---|---|
| washdev (2043-9083) | 96 / 98 | 71 / 82 | 85 / 91 | 120 / 113 | 86 / 86 | 70 / 42 | 1208 / 1174 |
| jwh (1477-8920) | 88 / 79 | 128 / 142 | 153 / 148 | 167 / 175 | 104 / 104 | 88 / 63 | 2047 / 2013 |
| ws (1606-9749) | 459 / 348 | 396 / 613 | 338 / 344 | 267 / 266 | 104 / 116 | 99 / 43 | 4993 / 4884 |
| aqua (2709-8028, since 2022) | 0 / 95 | 1 / 100 | 138 / 162 | 165 / 148 | 46 / 52 | 42 / 19 | 392 / 1819 |
| aqua (0003-7214, until 2023) | 96 / 95 | 93 / 100 | 19 / 162 | 0 / 148 | 0 / 52 | 0 / 19 | 1501 / 1819 |

The ISSN 1606-9749 is "Water Supply" (4,985 of its 4,993 works; the earlier count of 34,623 from the journals endpoint counts the whole ISSN family). AQUA needs both ISSNs: 0003-7214 until the 2022 renaming, 2709-8028 since.

Fields: DOI, title, publication dates, volume, issue, authors with affiliations where deposited, ORCID iDs where deposited, the licence URL, the abstract for some works. Every work since 2021 has two registered full-text links, none registered for text mining:

| Journal | DOI (2024) | Links | Content types | Intended application | Licence |
|---|---|---|---|---|---|
| washdev | 10.2166/washdev.2024.261 | 2 | application/pdf | unspecified | syndication | similarity-checking | http://creativecommons.org/licenses/by/4.0/ |
| jwh | 10.2166/wh.2024.095 | 2 | application/pdf | unspecified | syndication | similarity-checking | http://creativecommons.org/licenses/by-nc-nd/4.0/ |
| ws | 10.2166/ws.2024.241 | 2 | application/pdf | unspecified | syndication | similarity-checking | http://creativecommons.org/licenses/by/4.0/ |
| aqua | 10.2166/aqua.2024.321 | 2 | application/pdf | unspecified | syndication | similarity-checking | http://creativecommons.org/licenses/by/4.0/ |

Each PDF link resolves on iwaponline.com and returns 403 (the challenge page) to the identified client, one request per journal:

| Journal | Link | Status |
|---|---|---|
| jwh | `https://iwaponline.com/jwh/article-pdf/22/10/1794/1499004/jwh2024095.pdf` | 403 |
| ws | `https://iwaponline.com/ws/article-pdf/24/11/3954/1511753/ws2024241.pdf` | 403 |
| washdev | `https://iwaponline.com/washdev/article-pdf/14/6/437/1438624/washdev0140437.pdf` | 403 |
| aqua | `https://iwaponline.com/aqua/article-pdf/73/9/1930/1483340/jws2024321.pdf` | 403 |

## What Europe PMC carries

Records by ISSN, 2021 to 2026, against the Crossref works of the same years:

| Journal | Crossref works | Europe PMC records | with full text | open access |
|---|---|---|---|---|
| washdev | 528 | 6 | 6 | 5 |
| jwh | 728 | 635 | 20 | 16 |
| ws | 1663 | 1 | 1 | 1 |
| aqua (2709-8028) | 208 | 1 | 1 | 1 |
| aqua (0003-7214) | 208 | 0 | 0 | 0 |

jwh is indexed (87 percent of its works have a record, it is a MEDLINE journal), but full text exists for 20 of 635, the author manuscripts and open access deposits; washdev, ws and aqua are absent but for a handful. Where an open access full text exists, it carries the statement: of the full texts sampled, washdev 4 of 4, jwh 10 of 10, ws 1 of 1, aqua 1 of 1 have a section titled "DATA AVAILABILITY STATEMENT" (jwh, ws, aqua) or a data availability section (washdev).

## Decision

- Discovery of new articles and the overview fields can come from Crossref by ISSN: it is complete, API-based and cheap, and a monthly count per ISSN tells how far the dataset lags. This replaces the scraper's issue browsing, not its article pages.
- The data availability statement, the supplement list and the keywords of an IWA article are on the article page only. Europe PMC reaches them for about 3 percent of jwh and nearly nothing else. No API carries the statement.
- Therefore the statements of the four IWA journals depend on access to the article pages. With the identified client refused (#78), the paths are: permission from IWA Publishing (the request of the handover's step 7f, or a text and data mining feed), or the statements of new IWA articles recorded as not retrieved until permission exists. The scraper does not get a false user agent back.
- Nothing in the pipeline changes with this record. A Crossref discovery step for the IWA journals is a later ticket, after the permission question is settled.

Refs #90, #78, #35, #76.
