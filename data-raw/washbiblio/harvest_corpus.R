# Harvest the WASH & FSM bibliometric corpus (1996-2026) from OpenAlex.
#
# Status: SKELETON. Structure and queries are complete; run on a machine with
# outbound network access (OpenAlex was blocked in the drafting sandbox).
#
# Outputs, in order of production:
#   1. researcher_ranking.csv  -- answers issue #18 step 1 (empirical top authors)
#   2. venue_ranking.csv       -- answers issue #18 step 3 (journals weighted by
#                                 prominent-researcher output)
#   3. journal_wash_share.csv  -- answers issue #18 step 4, REPLACES the estimated
#                                 share table in the issue thread with real numbers
#   4. works.csv / authorships.csv -- the corpus itself (schema in SCHEMA.md)
#
# Dependencies: openalexR (CRAN), dplyr, tidyr, readr, purrr, countries
# OpenAlex polite pool: set options(openalexR.mailto = "you@example.org")

library(openalexR)
library(dplyr)
library(tidyr)
library(readr)
library(purrr)
library(countries)

options(openalexR.mailto = "lars@lse.de")

FROM <- "1996-01-01"
TO   <- "2026-12-31"

keywords <- read_csv("data-raw/washbiblio/wash-keywords.csv")

# Build an OpenAlex full-text search string from the keyword list.
# Quote multi-word terms; OR them together. High-recall terms (WASH, E. coli)
# rely on the downstream venue/relevance filter to control precision.
search_string <- keywords$keyword |>
  (\(k) ifelse(grepl(" ", k), paste0('"', k, '"'), k))() |>
  paste(collapse = " OR ")

# --- Step 1: empirical researcher ranking -----------------------------------
# Group WASH-matching works by author; keep the top authors by works count and,
# separately, by citation count. Union with the curated seed (issue #18) offline.
researcher_ranking <- oa_fetch(
  entity = "works",
  search = search_string,
  from_publication_date = FROM,
  to_publication_date = TO,
  group_by = "authorships.author.id",
  verbose = TRUE
)
# TODO: join author display names, drop false positives against the seed list,
# write researcher_ranking.csv

# --- Step 2: index the prominent researchers' publications ------------------
# For each retained author.id: oa_fetch(entity="works", author.id=..., from/to),
# accumulate into a single works frame. (Loop omitted from skeleton.)

# --- Step 3: venue ranking --------------------------------------------------
# Group the union of those works by primary venue.
venue_ranking <- oa_fetch(
  entity = "works",
  search = search_string,
  from_publication_date = FROM,
  to_publication_date = TO,
  group_by = "primary_location.source.id",
  verbose = TRUE
)
# TODO: attach venue display names + total-output denominators, write venue_ranking.csv

# --- Step 4: WASH-share per candidate journal -------------------------------
# share = (works in journal matching WASH keywords) / (total works in journal),
# both over 1996-2026. This replaces the estimated share table in issue #18.
wash_share <- function(source_id) {
  matched <- oa_fetch(entity = "works", search = search_string,
                      primary_location.source.id = source_id,
                      from_publication_date = FROM, to_publication_date = TO,
                      count_only = TRUE)
  total <- oa_fetch(entity = "works",
                    primary_location.source.id = source_id,
                    from_publication_date = FROM, to_publication_date = TO,
                    count_only = TRUE)
  tibble(source_id = source_id,
         matched = matched$count, total = total$count,
         share = matched$count / total$count)
}
# candidate_sources <- venue_ranking$id[1:40]
# journal_wash_share <- map_dfr(candidate_sources, wash_share)
# write_csv(journal_wash_share, "data-raw/washbiblio/journal_wash_share.csv")

# --- Step 5: apply the decision rule (issue #18) ----------------------------
# share > 0.50                         -> index whole journal
# share <= 0.50 & matched > 100 & DAS  -> index keyword-filtered slice
# else                                  -> article-level OpenAlex capture only

# --- Corpus tables (works + authorships), per SCHEMA.md ---------------------
# Fetch full records for the matched corpus and flatten into the two tables.
# oa_fetch(..., output = "list") then map to works/authorships rows;
# normalize institution_country with countries::country_name(to = "UN_en").
