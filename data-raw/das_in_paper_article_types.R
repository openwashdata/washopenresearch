# Cross-check the in-paper DAS claims against article types (issue #47
# tier 2, first heuristic). Editorials, errata, and reviews make the claim
# "all relevant data are included in the paper" trivially true, so the
# no-supplement population from das_in_paper_support() overstates how many
# research papers rest their data on printed tables alone.
#
# Article types come from OpenAlex (one `type` per DOI, batch-fetched 50 DOIs
# per request, ~52 requests for the full claim set) with a title-pattern
# fallback for front-matter OpenAlex types as plain articles. The DOI-to-type
# lookup is committed as a snapshot so reruns cost no requests.
#
# Run from the package root:
#   Rscript data-raw/das_in_paper_article_types.R
#
# Outputs:
#   data-raw/das-in-paper-claim-types.csv (per claim: source, doi, support
#     category, openalex type, title flag, trivially-true verdict)
#   data-raw/das-in-paper-support-by-type.csv (cross-tab)

library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(httr)

devtools::load_all(quiet = TRUE)

MAILTO <- "lars@lse.de"
API_KEY <- Sys.getenv("OPENALEX_API_KEY")

read_iwa <- function(path) {
  read_csv(path, col_types = cols(.default = col_character())) |>
    mutate(is_supp = as.logical(is_supp), num_supp = as.integer(num_supp))
}

sources <- list(
  washdev = washdev,
  jwh = read_iwa("data-raw/jwh.csv"),
  aqua = read_iwa("data-raw/aqua.csv"),
  ws = read_iwa("data-raw/ws.csv")
)

claims <- imap_dfr(sources, function(d, name) {
  das_in_paper_support(d) |>
    filter(!is.na(das_in_paper_support)) |>
    mutate(source = name, doi = str_to_lower(doi)) |>
    select(source, doi, title, das_in_paper_support)
})

# --- OpenAlex type per DOI, cached as a committed snapshot -------------------

lookup_path <- "data-raw/das-in-paper-claim-types-lookup.csv"

fetch_types <- function(dois) {
  dois <- unique(dois[!is.na(dois) & nzchar(dois)])
  chunks <- split(dois, ceiling(seq_along(dois) / 50))
  map_dfr(chunks, function(chunk) {
    for (try in 1:3) {
      resp <- tryCatch(
        GET("https://api.openalex.org/works",
            query = c(list(filter = paste0("doi:", paste(chunk, collapse = "|")),
                           select = "doi,type", `per-page` = 50,
                           mailto = MAILTO),
                      if (nzchar(API_KEY)) list(api_key = API_KEY)),
            timeout(120)),
        error = function(e) NULL)
      if (!is.null(resp) && status_code(resp) == 200) break
      Sys.sleep(2 * try)
    }
    stopifnot(!is.null(resp), status_code(resp) == 200)
    results <- content(resp)$results
    Sys.sleep(0.2)
    tibble(
      doi = map_chr(results, ~ str_remove(.x$doi %||% NA_character_,
                                          "^https://doi\\.org/")),
      openalex_type = map_chr(results, ~ .x$type %||% NA_character_)
    )
  })
}

if (file.exists(lookup_path)) {
  types <- read_csv(lookup_path, col_types = cols(.default = col_character()))
  message("Using committed type lookup (", nrow(types), " DOIs). ",
          "Delete ", lookup_path, " to re-fetch.")
} else {
  types <- fetch_types(claims$doi) |> mutate(doi = str_to_lower(doi))
  write_csv(types, lookup_path)
  message("Fetched ", nrow(types), " types from OpenAlex.")
}

# --- Title fallback: front matter OpenAlex often types as plain articles ----

front_matter_rx <- paste0(
  "^\\s*(editorial|erratum|corrigendum|correction|obituary|preface|foreword|",
  "book review|comment on|reply to|response to|discussion of|closure to)")

claims <- claims |>
  left_join(types, by = "doi") |>
  mutate(
    title_front_matter = str_detect(str_to_lower(coalesce(title, "")),
                                    front_matter_rx),
    # Types whose in-paper claim is trivially true: nothing beyond the text
    # itself was ever expected (front matter), or the paper synthesises
    # published sources rather than reporting primary data (review).
    trivially_true = title_front_matter |
      coalesce(openalex_type, "") %in%
        c("editorial", "erratum", "letter", "paratext", "review")
  )

write_csv(claims |> select(-title),
          "data-raw/das-in-paper-claim-types.csv")

by_type <- claims |>
  count(das_in_paper_support, openalex_type, name = "n") |>
  arrange(das_in_paper_support, desc(n))
write_csv(by_type, "data-raw/das-in-paper-support-by-type.csv")

# --- Report ------------------------------------------------------------------

no_supp <- claims |> filter(das_in_paper_support == "no supplement")
message("\nOf ", nrow(claims), " in-paper claims, ", nrow(no_supp),
        " have no supplement. Within those:")
no_supp |>
  count(openalex_type, name = "n") |>
  arrange(desc(n)) |>
  pwalk(function(openalex_type, n)
    message(sprintf("  %-12s %5d", coalesce(openalex_type, "no match"), n)))
message("Trivially true (front matter or review): ",
        sum(no_supp$trivially_true), " of ", nrow(no_supp),
        sprintf(" (%.1f%%)", 100 * mean(no_supp$trivially_true)))
message("Residual substantive no-supplement claims: ",
        sum(!no_supp$trivially_true))
