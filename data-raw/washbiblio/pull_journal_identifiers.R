# Pull identifiers and empirical OA flags for the in-scope journals (issue #38
# step 1). One OpenAlex source GET per journal supplies the ISSN join key that
# every policy-layer source (Open Policy Finder, TOP Factor) needs, plus the
# empirical OA-model base (is_oa, is_in_doaj, apc_usd). A second group_by call
# per journal adds the works-level oa_status mix (gold/hybrid/green/bronze/
# closed) over the 1996-2026 harvest window.
#
# Input:  journal_wash_share.csv (50 journals: 46 filtered_slice_conditional
#         + 4 whole_journal)
# Output: journal-identifiers.csv, one row per journal
#
# ~100 requests total (2 per journal), all list-priced; cached in cache/ so an
# aborted run resumes without re-spending.
#
# Dependencies: httr, dplyr, readr, purrr, tidyr

library(httr)
library(dplyr)
library(readr)
library(purrr)
library(tidyr)

MAILTO <- "lars@lse.de"
API_KEY <- Sys.getenv("OPENALEX_API_KEY")
FROM <- "1996-01-01"
TO   <- "2026-12-31"

DIR <- "data-raw/washbiblio"
CACHE <- file.path(DIR, "cache")
dir.create(CACHE, showWarnings = FALSE)

`%||%` <- function(a, b) if (is.null(a)) b else a

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

with_retry <- function(fn, tries = 4, waits = c(5, 15, 60)) {
  for (i in seq_len(tries)) {
    result <- tryCatch(fn(), error = \(e) {
      message("request failed: ", conditionMessage(e))
      NULL
    })
    if (!is.null(result)) return(result)
    if (i < tries) {
      message("retrying in ", waits[min(i, length(waits))], "s")
      Sys.sleep(waits[min(i, length(waits))])
    }
  }
  stop("request still failing after ", tries, " attempts")
}

oa_get <- function(url, query = list()) {
  query$mailto <- MAILTO
  if (nzchar(API_KEY)) query$api_key <- API_KEY
  resp <- GET(url, query = query, timeout(120))
  stop_for_status(resp)
  content(resp, as = "parsed", type = "application/json")
}

fetch_source <- function(sid) {
  src <- oa_get(paste0("https://api.openalex.org/sources/", sid))
  tibble(
    source_id      = sid,
    display_name   = src$display_name %||% NA_character_,
    issn_l         = src$issn_l %||% NA_character_,
    issns          = paste(map_chr(src$issn, identity), collapse = ";"),
    publisher      = src$host_organization_name %||% NA_character_,
    source_type    = src$type %||% NA_character_,
    is_oa          = src$is_oa %||% NA,
    is_in_doaj     = src$is_in_doaj %||% NA,
    apc_usd        = src$apc_usd %||% NA_integer_,
    works_count    = src$works_count %||% NA_integer_,
    homepage_url   = src$homepage_url %||% NA_character_
  )
}

fetch_oa_mix <- function(sid) {
  body <- oa_get("https://api.openalex.org/works", query = list(
    filter = paste0("primary_location.source.id:", sid,
                    ",from_publication_date:", FROM,
                    ",to_publication_date:", TO),
    group_by = "oa_status"
  ))
  map_dfr(body$group_by, \(g) tibble(
    source_id = sid,
    oa_status = g$key %||% NA_character_,
    n = g$count
  ))
}

journals <- read_csv(file.path(DIR, "journal_wash_share.csv"),
                     show_col_types = FALSE)

identifiers <- step_cache("identifiers_sources", \() {
  map_dfr(journals$source_id, \(sid) {
    message("source ", sid)
    with_retry(\() fetch_source(sid))
  })
})

oa_mix <- step_cache("identifiers_oa_mix", \() {
  map_dfr(journals$source_id, \(sid) {
    message("oa_status mix ", sid)
    with_retry(\() fetch_oa_mix(sid))
  })
})

oa_mix_wide <- oa_mix |>
  filter(oa_status %in% c("gold", "hybrid", "green", "bronze", "closed",
                          "diamond")) |>
  mutate(oa_status = paste0("n_", oa_status)) |>
  pivot_wider(names_from = oa_status, values_from = n, values_fill = 0L)

out <- journals |>
  select(source_id, venue, decision) |>
  left_join(identifiers, by = "source_id") |>
  left_join(oa_mix_wide, by = "source_id")

write_csv(out, file.path(DIR, "journal-identifiers.csv"))

message("Wrote ", nrow(out), " journals; ",
        sum(!is.na(out$issn_l)), " with an ISSN-L, ",
        sum(out$issns == "" | is.na(out$issns)), " with no ISSN at all")
