---
status: accepted
date: 2026-10-04
---

# Journal share governs whole-journal indexing only

The #18 harvest measured, for 50 candidate journals, the share of 1996 to 2026 works that match the WASH keyword list (`data-raw/journal_wash_share.csv`, written once on 2026-07-23 and not regenerated). A journal whose share is above 0.50 is indexed completely in this package, article by article from the journal site or API (washdev, ws, jwh, aqua, ploswater). Below that share, WASH articles are not captured per journal at all: they are discovered one by one, independent of the journal, through the DOI list that openwashdata/washbib releases (three signals, tiers, recall and precision), and this package fetches their statements through sanctioned routes into the article-level dataset (the protocol in `data-raw/protocol-article-level-wash-capture.md`, issue #76). The earlier idea of keyword-filtered slices per journal, gated by a manual check of statement accessibility (#35), is superseded for generalist journals by that route. Journal share therefore decides one thing only: whether a journal is indexed whole.

## Consequences

- The bibliometric staging that produced the share table lives in washbib; this package keeps the frozen table and nothing else of it.
- A journal's share is never a reason to leave its WASH articles out. Absolute yield counts: 2,000 WASH articles in a journal that is 10 percent WASH are worth having.
- Refs #18, #35, #76; washopenresearch#77 made the move.
