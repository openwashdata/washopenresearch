# Harvest the WASH & FSM bibliometric rankings (1996-2026) from OpenAlex.
#
# Status: RUNNABLE (steps 1-5). The corpus pull (works/authorships tables,
# SCHEMA.md) is deferred to the standalone washbiblio package, issue #22.
#
# Outputs, in order of production:
#   1. researcher_ranking.csv  -- answers issue #18 step 1 (empirical top authors)
#   2. venue_ranking.csv       -- answers issue #18 step 3 (journals weighted by
#                                 prominent-researcher output)
#   3. journal_wash_share.csv  -- answers issue #18 step 4, REPLACES the estimated
#                                 share table in the issue thread with real numbers,
#                                 and carries the step-5 decision per journal
#
# Matching uses the title_and_abstract.search filter, not fulltext search:
# fulltext matches ~9.6M works with noisy author rankings; title+abstract
# matches ~2.1M and surfaces the expected WASH researchers.
#
# OpenAlex bills per request (Feb 2026 pricing): search calls $0.001, list
# calls $0.0001, free budget $0.10/day keyless; a registered key
# (OPENALEX_API_KEY in ~/.Renviron) lifts that to $1/day. A full run is ~175
# requests, ~$0.06. Every network step is cached in cache/ so an aborted run
# resumes without re-spending; delete cache/ to force a fresh harvest.
#
# Dependencies: openalexR (>= 3.1.0), httr, dplyr, tidyr, readr, purrr

library(openalexR)
library(httr)
library(dplyr)
library(tidyr)
library(readr)
library(purrr)

options(openalexR.mailto = "lars@lse.de")

# openalexR sends the key as an HTTP header, which the usage-priced API may
# ignore; oa_group_top200() attaches it as a query parameter, which registers
# reliably. The oa_fetch calls are cheap list calls that fit keyless anyway.
API_KEY <- Sys.getenv("OPENALEX_API_KEY")
if (nzchar(API_KEY)) options(openalexR.apikey = API_KEY)

MAILTO <- "lars@lse.de"
FROM <- "1996-01-01"
TO   <- "2026-12-31"

# An author from the top-200 group_by is kept unless WASH-matched works are
# under this share of their career output (false-positive guard, e.g. authors
# of one viral non-WASH paper that mentions water quality in the abstract).
LOW_SHARE_THRESHOLD <- 0.10

# Venues from the two rankings to push through the wash_share() count pass.
N_CANDIDATE_JOURNALS <- 40

# Small dedicated journals never crack the volume-dominated top ranks, but
# they are exactly the whole-journal candidates the decision rule looks for.
# Journals whose matched works reach this share of their ALL-TIME output
# (approximate denominator; the share pass computes the real 1996-2026 one)
# join the candidate set regardless of rank.
APPROX_SHARE_SCREEN <- 0.25

DIR <- "data-raw/washbiblio"
CACHE <- file.path(DIR, "cache")
dir.create(CACHE, showWarnings = FALSE)
writeLines("*", file.path(CACHE, ".gitignore"))

keywords <- read_csv(file.path(DIR, "wash-keywords.csv"), show_col_types = FALSE)

# Build an OpenAlex search string from the keyword list. Quote multi-word
# terms; OR them together. High-recall terms (WASH, E. coli) rely on the
# downstream venue/relevance filter to control precision.
search_string <- keywords$keyword |>
  (\(k) ifelse(grepl(" ", k), paste0('"', k, '"'), k))() |>
  paste(collapse = " OR ")

# --- Helpers ----------------------------------------------------------------

# Cache each network step so a failed later step never re-spends earlier ones.
step_cache <- function(name, fn) {
  path <- file.path(CACHE, paste0(name, ".rds"))
  if (file.exists(path)) {
    message("cache hit: ", name)
    return(readRDS(path))
  }
  result <- fn()
  saveRDS(result, path)
  result
}

# openalexR reports HTTP 429 (rate/budget exceeded) as an EMPTY result rather
# than an error, so an empty return must be retried like a failure.
with_retry <- function(fn, ok = NULL, tries = 4, waits = c(5, 15, 60)) {
  if (is.null(ok)) {
    ok <- \(x) !is.null(x) && (!is.data.frame(x) || nrow(x) > 0)
  }
  for (i in seq_len(tries)) {
    result <- tryCatch(fn(), error = \(e) {
      message("request failed: ", conditionMessage(e))
      NULL
    })
    if (ok(result)) return(result)
    if (i < tries) {
      message("empty or failed result, retrying in ", waits[min(i, length(waits))], "s")
      Sys.sleep(waits[min(i, length(waits))])
    }
  }
  stop("request still failing after ", tries, " attempts")
}

# Top-200 group_by via a direct GET. Do NOT route these through oa_fetch: its
# group_by branch cursor-pages ALL groups (millions of author ids here), which
# takes hours and burns the request budget. The first page is the top 200
# groups sorted by count, which is all a ranking needs.
oa_group_top200 <- function(group_by, extra_filter = NULL) {
  filter <- paste(c(
    paste0("title_and_abstract.search:", search_string),
    paste0("from_publication_date:", FROM),
    paste0("to_publication_date:", TO),
    extra_filter
  ), collapse = ",")
  query <- list(filter = filter, group_by = group_by,
                per_page = 200, mailto = MAILTO)
  if (nzchar(API_KEY)) query$api_key <- API_KEY
  resp <- GET("https://api.openalex.org/works", query = query, timeout(120))
  stop_for_status(resp)
  content(resp, as = "parsed", type = "application/json")$group_by |>
    map_dfr(\(g) tibble(
      key = g$key %||% NA_character_,
      key_display_name = g$key_display_name %||% NA_character_,
      count = g$count
    ))
}

strip_id <- function(x) sub("https://openalex.org/", "", x, fixed = TRUE)

# --- Step 1: empirical researcher ranking (~5 requests) ---------------------
# Top 200 authors by WASH-matched works, with career metadata to separate
# genuinely prominent WASH researchers from incidental matches.

author_groups <- step_cache("step1_author_groups", \() with_retry(\()
  oa_group_top200("authorships.author.id")
))

author_meta <- step_cache("step1_author_meta", \() with_retry(\()
  oa_fetch(entity = "authors", identifier = strip_id(author_groups$key),
           verbose = TRUE)
))

researcher_ranking <- author_groups |>
  transmute(author_id = strip_id(key), matched_works = count) |>
  left_join(
    author_meta |>
      transmute(author_id = strip_id(id), author_name = display_name,
                total_works = works_count, cited_by_count, orcid),
    by = "author_id"
  ) |>
  mutate(
    matched_share = matched_works / total_works,
    flag_low_share = !is.na(matched_share) & matched_share < LOW_SHARE_THRESHOLD,
    retained = !flag_low_share
  ) |>
  arrange(desc(matched_works)) |>
  mutate(rank = row_number()) |>
  select(rank, author_id, author_name, matched_works, total_works,
         matched_share, cited_by_count, orcid, flag_low_share, retained)

write_csv(researcher_ranking, file.path(DIR, "researcher_ranking.csv"))
message(sum(researcher_ranking$retained), " of ", nrow(researcher_ranking),
        " authors retained")

# --- Step 2: venues of the retained researchers (~85 requests) --------------
# Venue counts of everything the retained authors published 1996-2026, via
# group_by directly (no works fetch needed). openalexR chunks the id filter
# in batches of 50; a work co-authored across two batches counts twice, which
# is acceptable for a ranking.

retained_ids <- researcher_ranking |> filter(retained) |> pull(author_id)

researcher_venue_groups <- step_cache("step2_researcher_venues", \() with_retry(\()
  oa_fetch(entity = "works",
           author.id = retained_ids,
           from_publication_date = FROM, to_publication_date = TO,
           group_by = "primary_location.source.id",
           verbose = TRUE)
))

researcher_venues <- researcher_venue_groups |>
  filter(!is.na(key), key != "unknown") |>
  summarise(researcher_works = sum(count), .by = key) |>
  arrange(desc(researcher_works)) |>
  slice_head(n = 200)

# --- Step 3: venue ranking, both ways (1 request + metadata) ----------------
# (a) venues by keyword-matched works; (b) venues by retained-researcher
# output. A venue prominent on either axis is a candidate journal.

venue_groups <- step_cache("step3_venue_groups", \() with_retry(\()
  oa_group_top200("primary_location.source.id")
))

venue_union <- full_join(
  venue_groups |>
    filter(!is.na(key), key != "unknown") |>
    transmute(source_id = strip_id(key), grouped_name = key_display_name,
              matched_works = count),
  researcher_venues |>
    transmute(source_id = strip_id(key), researcher_works),
  by = "source_id"
) |>
  mutate(rank_matched = min_rank(desc(matched_works)),
         rank_researcher = min_rank(desc(researcher_works)))

source_meta <- step_cache("step3_source_meta", \() with_retry(\()
  oa_fetch(entity = "sources", identifier = venue_union$source_id,
           verbose = TRUE)
))

venue_ranking <- venue_union |>
  left_join(
    source_meta |>
      transmute(source_id = strip_id(id), venue = display_name,
                source_type = type, venue_total_works = works_count),
    by = "source_id"
  ) |>
  mutate(
    venue = coalesce(venue, grouped_name),
    best_rank = pmin(rank_matched, rank_researcher, na.rm = TRUE)
  ) |>
  arrange(best_rank)

# Candidates for the share pass: journals only. This is where PubMed, Zenodo,
# SSRN, Figshare, Research Square and conference series drop out.
candidate_ids <- venue_ranking |>
  filter(source_type == "journal") |>
  slice_head(n = N_CANDIDATE_JOURNALS) |>
  pull(source_id)

candidate_ids <- venue_ranking |>
  filter(source_type == "journal",
         matched_works / venue_total_works >= APPROX_SHARE_SCREEN) |>
  pull(source_id) |>
  union(candidate_ids)

venue_ranking <- venue_ranking |>
  mutate(is_candidate = source_id %in% candidate_ids) |>
  select(source_id, venue, source_type, matched_works, rank_matched,
         researcher_works, rank_researcher, venue_total_works, is_candidate)

write_csv(venue_ranking, file.path(DIR, "venue_ranking.csv"))
message(length(candidate_ids), " candidate journals for the share pass")

# --- Step 4: WASH share per candidate journal (~81 requests) ----------------
# share = matched works / total works in the journal over 1996-2026. Cached
# per journal: a mid-pass failure only re-requests the journals not yet done.

count_ok <- \(x) is.list(x) && is.numeric(x$count)

wash_share <- function(source_id) {
  matched <- with_retry(\() oa_fetch(
    entity = "works",
    title_and_abstract.search = search_string,
    primary_location.source.id = source_id,
    from_publication_date = FROM, to_publication_date = TO,
    count_only = TRUE
  ), ok = count_ok)
  total <- with_retry(\() oa_fetch(
    entity = "works",
    primary_location.source.id = source_id,
    from_publication_date = FROM, to_publication_date = TO,
    count_only = TRUE
  ), ok = count_ok)
  tibble(source_id = source_id,
         matched = matched$count, total = total$count) |>
    mutate(share = matched / total)
}

journal_wash_share <- map_dfr(candidate_ids, \(id) {
  step_cache(paste0("step4_share_", id), \() wash_share(id))
})

# --- Step 5: apply the decision rule (issue #18, 0 requests) ----------------
# share > 0.50                  -> index whole journal
# share <= 0.50 & matched > 100 -> keyword-filtered slice, conditional on an
#                                  accessible DAS (das_confirmed is a manual
#                                  follow-up column, left NA here)
# else                          -> article-level OpenAlex capture only

journal_wash_share <- journal_wash_share |>
  left_join(venue_ranking |> select(source_id, venue, source_type),
            by = "source_id") |>
  mutate(
    decision = case_when(
      share > 0.5 ~ "whole_journal",
      share <= 0.5 & matched > 100 ~ "filtered_slice_conditional",
      .default = "article_level"
    ),
    das_confirmed = NA
  ) |>
  arrange(desc(share)) |>
  select(source_id, venue, source_type, matched, total, share,
         decision, das_confirmed)

write_csv(journal_wash_share, file.path(DIR, "journal_wash_share.csv"))
message("decision counts: ",
        paste(capture.output(table(journal_wash_share$decision)), collapse = " "))

# --- Corpus tables (works + authorships), per SCHEMA.md ---------------------
# DEFERRED to the standalone washbiblio package (issue #22): fetch full records
# for the matched corpus per the step-5 decisions and flatten into the two
# tables. oa_fetch(..., output = "list") then map to works/authorships rows;
# normalize institution_country with countries::country_name(to = "UN_en").
