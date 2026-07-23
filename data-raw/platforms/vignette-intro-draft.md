# Draft intro paragraphs for the vignette (issue #26)

Target: a new section in `vignettes/articles/data-availability-washdev.Rmd`.
Facts come from `platforms.csv`, `rubric.csv`, and `platform_mentions.csv`,
all accessed 2026-07-23.

---

## Where WASH data is meant to go

The WASH sector has built its own places to put data. Two of them are the
largest. The first is mWater, a free platform where people collect water,
sanitation, and health data with survey tools and can share it. mWater has run
since 2012, covers 198 countries, and holds records for more than four million
sites. The second is Project W, a catalogue built by the Aquaya Institute that
gathers WASH datasets from more than 900 organisations into one searchable
place across 190 or more geographies. mWater generates data. Project W compiles
data that already exists.

Both platforms let researchers store or find data, but they document it
unevenly. mWater lets you download record-level data, offers an API, and
provides a data dictionary, so the data can be reused by machine. It does not
assign a license to the shared public data, and it gives datasets no DOI or
version, so a paper cannot cite an mWater dataset the way it cites a journal
article. Project W is harder to assess because it is still in beta and asks you
to sign in before you use it. We could not confirm from its public pages
whether it offers downloads, an API, a license, or persistent identifiers.

The platforms exist, but WASH authors rarely point to them. We searched the
data availability statements of 1,782 papers in this package (the washdev,
uncnewsletter, and ploswater datasets) for mentions of thirteen WASH data
platforms. Neither mWater nor Project W appears once. The platforms that do
appear are the large household-survey programmes and general repositories that
are not WASH-specific: the Demographic and Health Surveys (twelve papers),
the Humanitarian Data Exchange (three papers), and the Multiple Indicator
Cluster Surveys (two papers). So when WASH authors do share data through a
platform, they reach for a general one rather than a sector platform. The
sector built mWater and Project W to hold WASH data, and the published record
so far routes around both. That gap is the missed opportunity this article is
about.

---

## Notes for review (not part of the vignette prose)

- The 1,782 figure is washdev (1,173) + uncnewsletter (173) + ploswater (436).
  Once datapapers is built, rerun `scan_platform_mentions.R` and update the
  count and the per-platform hits, since datapapers is exactly the population
  most likely to cite a data platform.
- Project W's launch year, access model, and licensing are all "not found" in
  `rubric.csv`. If you have an account, we can confirm them and firm up the
  second paragraph.
- The DHS count is papers with a genuine dhsprogram.com link in the DAS,
  verified by spot-check. The prose says "twelve papers"; the table splits it
  as eight washdev plus four ploswater.
