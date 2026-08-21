# Measure behavioral-layer coverage for the in-scope journals (issue #38
# step 4: which journals have OBSERVED data-sharing practice in an existing
# open dataset, so bespoke DAS scraping is only needed for the residual).
#
# Sources:
# - PLOS Open Science Indicators v11 (figshare 10.6084/m9.figshare.21687686):
#   per-article Data_Shared etc. for ~155k PLOS articles plus a ~31k
#   cross-publisher comparator set. PLOS articles map to journals via the DOI
#   (10.1371/journal.<code>); comparator DOIs carry no journal field, so they
#   are resolved to OpenAlex source ids in batched works lookups (50 DOIs per
#   list call, ~630 calls, cached and resumable).
# - AAAS/Science Open Science Metrics (Dryad 10.5061/dryad.zkh1893qt):
#   OPTIONAL. Dryad's download sits behind a bot-check interstitial, so this
#   script only reads the CSV if it has been downloaded by hand into
#   cache/AAAS_Open_Science_Metrics_data_2021_to_2024.csv; otherwise it is
#   skipped with a message. Science is not an in-scope journal, so skipping
#   costs only the small PLOS/T&F comparator overlap.
# - Our own scrapes (washdev + jwh/aqua/ws, #32-#34): the four whole_journal
#   rows already have full per-article DAS ground truth.
#
# Run pull_journal_identifiers.R first, and unzip the OSI archive into
# cache/ (cache/Data files/*.csv); the zip download is scripted below.
#
# Output: behavioral-coverage.csv, one row per in-scope journal.
#
# Dependencies: httr, dplyr, readr, purrr, stringr, tidyr

library(httr)
library(dplyr)
library(readr)
library(purrr)
library(stringr)

MAILTO <- "lars@lse.de"
API_KEY <- Sys.getenv("OPENALEX_API_KEY")

DIR <- "data-raw/washbiblio"
CACHE <- file.path(DIR, "cache")
OSI_ZIP <- file.path(CACHE, "PLOS-OSI-Dataset_v11.zip")
OSI_PLOS <- file.path(CACHE, "Data files", "PLOS-Dataset_v11_Jun26.csv")
OSI_COMP <- file.path(CACHE, "Data files", "Comparator-Dataset_v11_Jun26.csv")
AAAS_CSV <- file.path(CACHE, "AAAS_Open_Science_Metrics_data_2021_to_2024.csv")
COMP_MAP <- file.path(CACHE, "osi-comparator-sources.rds")

if (!file.exists(OSI_PLOS)) {
  if (!file.exists(OSI_ZIP)) {
    download.file("https://ndownloader.figshare.com/files/66066221",
                  OSI_ZIP, mode = "wb", quiet = TRUE)
  }
  unzip(OSI_ZIP, exdir = CACHE)
}

journals <- read_csv(file.path(DIR, "journal-identifiers.csv"),
                     show_col_types = FALSE)

# --- PLOS articles: journal from the DOI ------------------------------------
# latin-1: the comparator file (and possibly others) contains non-UTF-8 bytes.

plos <- read_csv(OSI_PLOS, show_col_types = FALSE, guess_max = Inf,
                 locale = locale(encoding = "latin1"))

plos_counts <- plos |>
  mutate(code = str_match(DOI, "10\\.1371/journal\\.([a-z]+)")[, 2]) |>
  count(code, name = "n_plos_osi")

# The two PLOS journals in scope, by their OpenAlex venue names.
plos_code_venue <- tibble(
  code = c("pone", "pntd"),
  venue = c("PLoS ONE", "PLoS neglected tropical diseases")
)

n_pwat <- plos_counts$n_plos_osi[plos_counts$code == "pwat"]
message("PLOS OSI also holds ", n_pwat, " PLOS Water articles ",
        "(the ploswater dataset's journal; not in the 50-journal list)")

# --- Comparator articles: resolve DOIs to OpenAlex sources ------------------

comp <- read_csv(OSI_COMP, show_col_types = FALSE, guess_max = Inf,
                 locale = locale(encoding = "latin1"))

comp_dois <- comp$DOI |>
  str_to_lower() |>
  unique() |>
  discard(\(d) is.na(d) | !str_detect(d, "^10\\.") | str_detect(d, "[|,]"))

resolved <- if (file.exists(COMP_MAP)) readRDS(COMP_MAP) else
  tibble(doi = character(), source_id = character())

todo <- setdiff(comp_dois, resolved$doi)
batches <- split(todo, ceiling(seq_along(todo) / 50))
message(length(comp_dois), " comparator DOIs, ", length(todo),
        " unresolved, ", length(batches), " batches")

resolve_batch <- function(dois) {
  query <- list(
    filter = paste0("doi:", paste(dois, collapse = "|")),
    `per-page` = 50,
    select = "doi,primary_location",
    mailto = MAILTO
  )
  if (nzchar(API_KEY)) query$api_key <- API_KEY
  resp <- GET("https://api.openalex.org/works", query = query, timeout(120))
  stop_for_status(resp)
  results <- content(resp, as = "parsed", type = "application/json")$results
  map_dfr(results, \(w) tibble(
    doi = str_remove(w$doi %||% "", "https://doi.org/"),
    source_id = sub("https://openalex.org/", "",
                    w$primary_location$source$id %||% NA_character_)
  ))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

for (i in seq_along(batches)) {
  hit <- NULL
  for (attempt in 1:4) {
    hit <- tryCatch(resolve_batch(batches[[i]]), error = \(e) {
      message("batch ", i, " failed: ", conditionMessage(e))
      NULL
    })
    if (!is.null(hit)) break
    Sys.sleep(c(5, 15, 60)[min(attempt, 3)])
  }
  if (is.null(hit)) stop("batch ", i, " failing after 4 attempts")
  # DOIs OpenAlex does not know get an NA source row so they are never re-asked.
  missing <- setdiff(batches[[i]], hit$doi)
  resolved <- bind_rows(resolved, hit,
                        tibble(doi = missing, source_id = NA_character_))
  if (i %% 25 == 0 || i == length(batches)) {
    saveRDS(resolved, COMP_MAP)
    message("batch ", i, "/", length(batches), " (",
            sum(!is.na(resolved$source_id)), " resolved)")
  }
  Sys.sleep(0.3)
}
saveRDS(resolved, COMP_MAP)

comp_counts <- resolved |>
  filter(source_id %in% journals$source_id) |>
  count(source_id, name = "n_osi_comparator")

# --- AAAS/Science metrics (optional, hand-downloaded) -----------------------

no_aaas <- tibble(source_id = character(), n_aaas = integer())
aaas_counts <- if (!file.exists(AAAS_CSV)) {
  message("AAAS CSV not in cache/, skipping (download by hand from ",
          "https://datadryad.org/dataset/doi:10.5061/dryad.zkh1893qt)")
  no_aaas
} else {
  aaas <- read_csv(AAAS_CSV, show_col_types = FALSE, guess_max = Inf)
  doi_col <- intersect(c("DOI", "doi"), names(aaas))
  if (length(doi_col) == 0) {
    message("AAAS CSV has no DOI column (a bot-check HTML page saved as ",
            ".csv looks like this); skipping. Re-download it by hand.")
    no_aaas
  } else {
    aaas_dois <- str_to_lower(str_remove(aaas[[doi_col[1]]],
                                         "https://doi.org/"))
    resolved |>
      filter(doi %in% aaas_dois, source_id %in% journals$source_id) |>
      count(source_id, name = "n_aaas")
  }
}

# --- Assemble ---------------------------------------------------------------

share <- read_csv(file.path(DIR, "journal_wash_share.csv"),
                  show_col_types = FALSE)

out <- journals |>
  select(source_id, venue) |>
  left_join(share |> select(source_id, decision), by = "source_id") |>
  left_join(plos_code_venue |>
              left_join(plos_counts, by = "code") |>
              select(venue, n_plos_osi),
            by = "venue") |>
  left_join(comp_counts, by = "source_id") |>
  left_join(aaas_counts, by = "source_id") |>
  mutate(
    across(c(n_plos_osi, n_osi_comparator, n_aaas), \(x) coalesce(x, 0L)),
    own_scrape = decision == "whole_journal",
    any_behavioral = own_scrape | n_plos_osi > 0 | n_osi_comparator > 0 |
      n_aaas > 0
  ) |>
  select(-decision)

write_csv(out, file.path(DIR, "behavioral-coverage.csv"))

message("Behavioral coverage: ", sum(out$any_behavioral), "/", nrow(out),
        " journals have at least one observed-practice source")
message("Residual (no behavioral source): ",
        paste(out$venue[!out$any_behavioral], collapse = "; "))
