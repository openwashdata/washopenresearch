# washopenresearch

The package that records, for scientific articles in water, sanitation and hygiene (WASH) research, whether and how the authors made their data available. Articles enter either because their journal is indexed whole or because a DOI list found them one by one.

## Language

**Whole-journal dataset**:
A dataset that holds every article of one journal, scraped or fetched from the journal itself (washdev, ws, jwh, aqua, ploswater).
_Avoid_: journal dataset, curated dataset, filtered slice

**Article-level dataset**:
The dataset of articles found by the DOI list, wherever they were published (working name `washarticles`). An article in a whole-journal dataset is never in it.
_Avoid_: corpus, bibliometric dataset, washbib data

**DOI list release**:
A tagged version of the list of WASH article DOIs that openwashdata/washbib publishes, with the signals and the tier per DOI. The article-level dataset records which release it consumed.
_Avoid_: discovery output, candidate list (that is the washbib intermediate)

**Signal**:
One of the independent ways washbib recognises a WASH article: keyword match in title and abstract, authorship by a retained researcher, two or more references to washdev or ploswater articles.
_Avoid_: filter, criterion

**Tier**:
The class of a DOI by how many signals fired: A for two or more, B for the keyword signal alone, C for one of the other two alone. Tier C is listed but not fetched until reviewed.
_Avoid_: confidence, rank

**Route**:
One sanctioned way of fetching an article's statement and supplement facts, tried in a fixed order (PLOS API, Europe PMC, Springer Nature, MDPI, Elsevier, Wiley, ACS by agreement, open access copy). Every row says which route produced it.
_Avoid_: source, scraper, backend

**Not retrieved**:
The recorded outcome for a DOI that no route reached. It is a finding about publisher openness, reported in the coverage table, never a dropped row.
_Avoid_: missing, failed, skipped

**Candidate**:
A work that at least one signal found, before tiering and validation decide whether it enters the DOI list. Lives in washbib.
_Avoid_: hit, match

**Overlap**:
An article that is both in a whole-journal dataset and on the DOI list. It stays in the whole-journal dataset only, and the article-level coverage table counts it.
_Avoid_: duplicate
