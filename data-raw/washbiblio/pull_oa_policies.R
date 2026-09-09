# Query the Jisc Open Policy Finder (ex-Sherpa Romeo) for the OA policy of
# each in-scope journal (issue #38 step 2, the "Policy - OA" layer: what OA
# route does the journal/publisher PERMIT). Joins by ISSN, which
# pull_journal_identifiers.R supplies; run that first.
#
# API: GET https://api.openpolicyfinder.jisc.ac.uk/retrieve
#   ?item-type=publication&format=Json&filter=[["issn","equals","<issn>"]]
# Auth: x-api-key header. Register at openpolicyfinder.jisc.ac.uk, store the
# key as OPENPOLICYFINDER_KEY in ~/.Renviron (same pattern as
# OPENALEX_API_KEY). The legacy v2.sherpa.ac.uk endpoints die April 2026; this
# targets the replacement API only.
#
# The response keeps the Sherpa v2 publication schema (publisher_policy ->
# permitted_oa pathways). Raw JSON is cached per ISSN in cache/opf/ so the
# tidy extraction below can be reworked without re-fetching.
#
# Input:  journal-identifiers.csv
# Output: oa-policies.csv, one row per journal x policy x permitted-OA pathway
#         (journals with no Open Policy Finder record keep one all-NA row, so
#         coverage gaps are visible rather than silently dropped)
#
# Dependencies: httr, jsonlite, dplyr, readr, purrr

library(httr)
library(jsonlite)
library(dplyr)
library(readr)
library(purrr)

OPF_KEY <- Sys.getenv("OPENPOLICYFINDER_KEY")
if (!nzchar(OPF_KEY)) {
  stop("OPENPOLICYFINDER_KEY is not set. Add it to ~/.Renviron as\n",
       "  OPENPOLICYFINDER_KEY=<your key>\n",
       "and restart R (or run readRenviron('~/.Renviron')).")
}

DIR <- "data-raw/washbiblio"
OPF_CACHE <- file.path(DIR, "cache", "opf")
dir.create(OPF_CACHE, recursive = TRUE, showWarnings = FALSE)

`%||%` <- function(a, b) if (is.null(a)) b else a

# Fetch one ISSN's publication record, raw JSON cached on disk. Returns the
# parsed list, or NULL when the API has no record for that ISSN.
opf_fetch <- function(issn) {
  path <- file.path(OPF_CACHE, paste0(issn, ".json"))
  if (file.exists(path)) {
    body <- read_json(path)
  } else {
    resp <- RETRY(
      "GET", "https://api.openpolicyfinder.jisc.ac.uk/retrieve",
      query = list(
        `item-type` = "publication",
        format = "Json",
        filter = sprintf('[["issn","equals","%s"]]', issn)
      ),
      add_headers(`x-api-key` = OPF_KEY),
      timeout(60), times = 4, pause_base = 5
    )
    stop_for_status(resp)
    writeLines(content(resp, as = "text", encoding = "UTF-8"), path)
    body <- read_json(path)
    Sys.sleep(1)
  }
  items <- body$items
  if (length(items) == 0) return(NULL)
  items[[1]]
}

# Flatten one publication record into one row per publisher_policy x
# permitted_oa pathway. Field access is defensive throughout: the schema is
# inherited from Sherpa v2 and not every record carries every field.
opf_tidy <- function(item, issn) {
  first_chr <- function(x, field) {
    if (length(x) == 0) return(NA_character_)
    as.character(x[[1]][[field]] %||% NA_character_)
  }
  collapse <- function(x) {
    if (length(x) == 0) return(NA_character_)
    paste(unlist(x), collapse = ";")
  }
  base <- tibble(
    issn_queried   = issn,
    opf_id         = item$id %||% NA_integer_,
    opf_title      = first_chr(item$title, "title"),
    listed_in_doaj = item$listed_in_doaj %||% NA_character_,
    opf_publisher  = {
      pubs <- item$publishers
      if (length(pubs) == 0) NA_character_
      else first_chr(pubs[[1]]$publisher$name, "name")
    }
  )
  policies <- item$publisher_policy
  if (length(policies) == 0) {
    return(mutate(base, policy_id = NA_integer_, oa_prohibited = NA_character_,
                  article_version = NA_character_, license = NA_character_,
                  embargo_amount = NA_integer_, embargo_units = NA_character_,
                  additional_oa_fee = NA_character_, locations = NA_character_,
                  named_repositories = NA_character_,
                  prerequisite_funders = NA_character_))
  }
  map_dfr(policies, \(pol) {
    pathways <- pol$permitted_oa
    pol_base <- mutate(base,
      policy_id     = pol$id %||% NA_integer_,
      oa_prohibited = pol$open_access_prohibited %||% NA_character_
    )
    if (length(pathways) == 0) {
      return(mutate(pol_base, article_version = NA_character_,
                    license = NA_character_, embargo_amount = NA_integer_,
                    embargo_units = NA_character_,
                    additional_oa_fee = NA_character_,
                    locations = NA_character_,
                    named_repositories = NA_character_,
                    prerequisite_funders = NA_character_))
    }
    map_dfr(pathways, \(pw) mutate(pol_base,
      article_version   = collapse(pw$article_version),
      license           = collapse(map(pw$license, "license")),
      embargo_amount    = pw$embargo$amount %||% NA_integer_,
      embargo_units     = pw$embargo$units %||% NA_character_,
      additional_oa_fee = pw$additional_oa_fee %||% NA_character_,
      locations         = collapse(pw$location$location),
      named_repositories   = collapse(pw$location$named_repository),
      prerequisite_funders = collapse(
        map(pw$prerequisites$prerequisite_funders, \(f) f$funder_metadata$name %||% NULL)
      )
    ))
  })
}

journals <- read_csv(file.path(DIR, "journal-identifiers.csv"),
                     show_col_types = FALSE)

# Try the ISSN-L first, then the remaining ISSNs, until one returns a record.
policies <- map_dfr(seq_len(nrow(journals)), \(i) {
  j <- journals[i, ]
  candidates <- unique(na.omit(c(j$issn_l, strsplit(j$issns %||% "", ";")[[1]])))
  candidates <- candidates[nzchar(candidates)]
  message(j$venue, " (", length(candidates), " ISSN(s))")
  hit <- NULL
  for (issn in candidates) {
    item <- opf_fetch(issn)
    if (!is.null(item)) {
      hit <- opf_tidy(item, issn)
      break
    }
  }
  if (is.null(hit)) {
    message("  no Open Policy Finder record")
    hit <- tibble(issn_queried = NA_character_)
  }
  mutate(hit, source_id = j$source_id, venue = j$venue, .before = 1)
})

write_csv(policies, file.path(DIR, "oa-policies.csv"))

covered <- policies |> filter(!is.na(issn_queried)) |> distinct(source_id)
message("Coverage: ", nrow(covered), "/", nrow(journals),
        " journals have an Open Policy Finder record")
uncovered <- setdiff(journals$source_id, covered$source_id)
if (length(uncovered) > 0) {
  message("Uncovered: ",
          paste(journals$venue[journals$source_id %in% uncovered],
                collapse = "; "))
}
