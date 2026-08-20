# Shared helpers for the data-raw processing scripts.
# Source from the package root, e.g. source("data-raw/helpers.R").

# Collapse a list-column into a "; "-delimited character column.
# list-columns break flat-file exports (issue #8), so multi-value fields are
# split into lists for cleaning, then collapsed before the data is saved.
collapse_list_col <- function(x) {
  purrr::map_chr(x, function(values) {
    values <- trimws(values[!is.na(values)])
    values <- values[values != ""]
    if (length(values) == 0) NA_character_ else paste(values, collapse = "; ")
  })
}

# Standardise free-text country names to United Nations English names.
# Non-matches become NA and are handled by a committed fixes sheet
# (see apply_country_fixes()), not by hard-coded ID vectors.
to_un_country_name <- function(x) {
  countries::country_name(x, to = "UN_en", fuzzy_match = FALSE)
}

# Apply manual country corrections from a decision sheet.
# `fixes` has one row per record needing a correction, keyed on `key`
# (e.g. "doi"), with the corrected value in `value_col`. Only rows where the
# automatic standardisation produced NA are overwritten, so re-running the
# automatic step never silently discards a manual decision.
apply_country_fixes <- function(data, fixes, key, value_col) {
  if (nrow(fixes) == 0) {
    return(data)
  }
  fixes <- fixes[, c(key, value_col)]
  names(fixes) <- c(key, ".fixed_value")
  data |>
    dplyr::left_join(fixes, by = key) |>
    dplyr::mutate(
      !!value_col := dplyr::coalesce(.data[[value_col]], .fixed_value),
      .fixed_value = NULL
    )
}

# The data journals harvested for the `datapapers` dataset (issue #28).
# Used by 01_datapapers_acquire.R (which API to query) and
# 03_datapapers_process.R (url_source lookup).
datapapers_journals <- function() {
  dplyr::tribble(
    ~journal,              ~publisher,           ~issn,       ~api,        ~url_source,
    "Scientific Data",     "Nature Portfolio",   "2052-4463", "crossref",  "nature.com",
    "Data in Brief",       "Elsevier",           "2352-3409", "crossref",  "sciencedirect.com",
    "Gates Open Research", "F1000",              "2572-4754", "europepmc", "gatesopenresearch.org",
    "F1000Research",       "F1000",              "2046-1402", "europepmc", "f1000research.com",
    "GigaScience",         "Oxford University Press", "2047-217X", "crossref", "academic.oup.com",
    "GigaByte",            "GigaScience Press",  "2709-4715", "crossref",  "gigabytejournal.com",
    "Data",                "MDPI",               "2306-5729", "crossref",  "mdpi.com"
  )
}

# WASH search terms used for the Crossref/Europe PMC queries and for the
# auto-relevance flag at the screening step. Extending the list is a
# one-line diff; every harvested row records which term(s) matched it.
datapapers_search_terms <- function() {
  c(
    "water sanitation" = "water AND sanitation",
    "hygiene"          = "hygiene",
    "wash"             = "WASH",
    "drinking water"   = "drinking water",
    "wastewater"       = "wastewater",
    "sanitation"       = "sanitation",
    "handwashing"      = "handwashing",
    "latrine"          = "latrine",
    "water quality"    = "water quality",
    "faecal sludge"    = "faecal sludge"
  )
}

# Rewrite an expired Silverchair pre-signed CDN link to a stable DOI URL
# (issue #10). The CDN links (iwa.silverchair-cdn.com/...pdf?Expires=...&
# Signature=...) carry a January 2024 expiry, so they are dead for reusers,
# and the high-entropy Signature trips secret scanners. The article DOI is
# embedded in the path (e.g. .../10.2166_washdev.2011.015/...), so it is
# recovered mechanically with no re-collection. A non-Silverchair value is
# returned unchanged.
canonicalize_silverchair_url <- function(url) {
  is_cdn <- !is.na(url) & stringr::str_detect(url, "silverchair-cdn\\.com")
  doi_token <- stringr::str_match(
    url, "/(10\\.[0-9]+_[a-z0-9]+\\.[0-9]+\\.[0-9]+)/"
  )[, 2]
  doi <- stringr::str_replace(doi_token, "_", "/")
  ifelse(is_cdn & !is.na(doi), paste0("https://doi.org/", doi), url)
}

# Decode the target URL out of a Google Scholar alert redirect (issue #10).
# uncnewsletter carries a few paper_url values of the form
# https://scholar.google.com/scholar_url?url=<target>&...&scisig=... The target
# is URL-encoded in the `url=` parameter; the scisig token also trips secret
# scanners. A value that is not a Scholar redirect is returned unchanged.
decode_scholar_redirect <- function(url) {
  is_scholar <- !is.na(url) & stringr::str_detect(url, "scholar\\.google\\.com/scholar_url")
  target <- stringr::str_match(url, "[?&]url=([^&]+)")[, 2]
  decoded <- vapply(target, function(t) if (is.na(t)) NA_character_ else utils::URLdecode(t),
                    character(1), USE.NAMES = FALSE)
  ifelse(is_scholar & !is.na(decoded), decoded, url)
}

# Parse a repository name from a data-repository URL.
parse_repo_name <- function(url) {
  dplyr::case_when(
    is.na(url) ~ NA_character_,
    stringr::str_detect(url, "zenodo\\.org") ~ "Zenodo",
    stringr::str_detect(url, "datadryad\\.org|doi\\.org/10\\.5061/dryad") ~ "Dryad",
    stringr::str_detect(url, "figshare\\.com|doi\\.org/10\\.6084") ~ "Figshare",
    stringr::str_detect(url, "osf\\.io") ~ "OSF",
    stringr::str_detect(url, "dataverse|doi\\.org/10\\.7910") ~ "Dataverse",
    stringr::str_detect(url, "github\\.com") ~ "GitHub",
    stringr::str_detect(url, "mendeley|doi\\.org/10\\.17632") ~ "Mendeley Data",
    stringr::str_detect(url, "pangaea\\.de") ~ "PANGAEA",
    stringr::str_detect(url, "ncbi\\.nlm\\.nih\\.gov|ebi\\.ac\\.uk") ~ "NCBI/EBI",
    stringr::str_detect(url, "gigadb\\.org") ~ "GigaDB",
    stringr::str_detect(url, "gbif\\.org|doi\\.org/10\\.15468|doi\\.org/10\\.15470") ~ "GBIF",
    stringr::str_detect(url, "ieee-dataport\\.org|doi\\.org/10\\.21227") ~ "IEEE DataPort",
    TRUE ~ "other"
  )
}
