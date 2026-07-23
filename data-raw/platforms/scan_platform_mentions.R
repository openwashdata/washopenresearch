# Scan the washopenresearch datasets for mentions of WASH data platforms
# (issue #26). Answers the linkage question: when WASH authors write a data
# availability statement, do they point to the sector's data platforms?
#
# Scans the data availability statement text (`das`) and the parsed repository
# links (`das_repo_url`) of washdev, uncnewsletter, ploswater, and (when built)
# datapapers for each platform's domain and name, and writes a hit-count table.
#
# Run from the package root:
#   Rscript data-raw/platforms/scan_platform_mentions.R
#
# Output: data-raw/platforms/platform_mentions.csv (one row per platform x
# dataset, with das-text hits and repo-url hits). This is descriptive evidence
# for the vignette, not a package dataset.

library(dplyr)
library(stringr)
library(purrr)
library(readr)

platforms <- read_csv("data-raw/platforms/platforms.csv", show_col_types = FALSE)

# Match patterns per platform: the bare registrable domain (for das_repo_url)
# and name/domain variants (for free-text das). Kept deliberately specific so
# generic words ("water", "data") do not inflate the counts.
platform_patterns <- tribble(
  ~platform,                      ~domain,              ~name_regex,
  "mWater",                       "mwater\\.co",        "\\bmwater\\b",
  "Project W",                    "projectwdata\\.net", "project\\s*w\\b|projectwdata",
  "WPdx",                         "waterpointdata\\.org", "waterpointdata|water point data exchange|wpdx",
  "IBNET",                        "ib-net\\.org",       "ib-?net",
  "JMP",                          "washdata\\.org",     "washdata\\.org|joint monitoring programme|\\bjmp\\b",
  "GLAAS",                        "glaas\\.who\\.int",  "glaas",
  "SDG 6 Data Portal",            "sdg6data\\.org",     "sdg6data",
  "DHS Program",                  "dhsprogram\\.com",   "dhsprogram|demographic and health survey",
  "MICS",                         "mics\\.unicef\\.org", "mics\\.unicef|multiple indicator cluster survey",
  "World Bank Microdata Library", "microdata\\.worldbank\\.org", "microdata\\.worldbank",
  "HDX",                          "humdata\\.org",      "humdata|humanitarian data exchange",
  "Akvo",                         "akvo\\.org",         "\\bakvo\\b",
  "KoboToolbox",                  "kobotoolbox\\.org",  "kobotoolbox|\\bkobo\\b"
)

datasets <- c("washdev", "uncnewsletter", "ploswater")
# Include datapapers once it has been built (issue #28).
if (file.exists("data/datapapers.rda")) datasets <- c(datasets, "datapapers")

load_dataset <- function(name) {
  e <- new.env()
  load(file.path("data", paste0(name, ".rda")), envir = e)
  get(name, envir = e)
}

# Count, within one dataset, how many rows mention a platform in the DAS text
# and how many carry its domain in a repository-link column.
scan_dataset <- function(name) {
  x <- load_dataset(name)
  das <- if ("das" %in% names(x)) str_to_lower(coalesce(x$das, "")) else character(nrow(x))
  # Any column that holds repository/data links, joined per row for matching.
  link_cols <- intersect(c("das_repo_url", "data_repo_url"), names(x))
  links <- if (length(link_cols)) {
    apply(as.data.frame(x)[link_cols], 1,
          \(v) str_to_lower(paste(coalesce(v, ""), collapse = " ")))
  } else {
    character(nrow(x))
  }
  pmap_dfr(platform_patterns, function(platform, domain, name_regex) {
    tibble(
      platform = platform,
      dataset = name,
      n_rows = nrow(x),
      das_text_hits = sum(str_detect(das, name_regex)),
      repo_url_hits = sum(str_detect(links, domain))
    )
  })
}

mentions <- map_dfr(datasets, scan_dataset) |>
  arrange(platform, dataset)

write_csv(mentions, "data-raw/platforms/platform_mentions.csv")

totals <- mentions |>
  summarise(das_text_hits = sum(das_text_hits),
            repo_url_hits = sum(repo_url_hits),
            .by = platform) |>
  arrange(desc(das_text_hits + repo_url_hits))

message("Scanned ", length(datasets), " datasets for ",
        nrow(platform_patterns), " platforms.")
message("Platforms with any mention:")
totals |>
  filter(das_text_hits + repo_url_hits > 0) |>
  pwalk(\(platform, das_text_hits, repo_url_hits)
        message("  ", platform, ": ", das_text_hits, " DAS-text, ",
                repo_url_hits, " repo-URL"))
if (sum(totals$das_text_hits + totals$repo_url_hits) == 0) {
  message("  none. No WASH platform is referenced in any dataset's DAS or repo links.")
}
