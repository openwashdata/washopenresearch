# What a run of the IWA scraper fetches.
#
# The decisions of a run are pure functions of the issue manifest and the
# raw snapshot, kept apart from the browser code in data-raw/iwa_scraping.R
# so that they can be tested without network (data-raw/tests/). A monthly run
# must find three things: journal issues published since the last run,
# articles added late to the most recent issues, and issues an earlier run
# lost.

issue_key <- function(volume, issue) paste(volume, issue, sep = "/")

# Issues in the order the journal published them. Combined issues ("5-6")
# sort by their first number, supplement issues ("S1") after the numbered
# issues of their volume.
sort_manifest <- function(manifest) {
  number <- suppressWarnings(
    as.integer(stringr::str_extract(manifest$issue, "^[0-9]+"))
  )
  manifest[order(manifest$volume, number, manifest$issue), ]
}

# The publication year from which the site's issue list is enumerated again:
# the newest year the cached manifest knows, since older volumes are
# complete. A year whose list failed to load stays the newest known year,
# see merge_manifest(). Without a cached manifest it is the journal's
# configured start year, or NA for the whole journal.
refresh_from_year <- function(cached, start_year) {
  if (is.null(cached) || nrow(cached) == 0) return(as.integer(start_year))
  max(cached$published_year)
}

# Merge the issues the site lists today into the cached manifest. Where both
# know an issue, the site's current row wins.
#
# `failed_years` are the publication years whose issue list did not load.
# Issues of later years are then held back unless the manifest knows them
# already. Taking them in would move refresh_from_year() past the failed
# year, and its new issues would never be asked for again.
merge_manifest <- function(cached, discovered, failed_years = integer()) {
  if (length(failed_years) > 0) {
    known <- issue_key(discovered$volume, discovered$issue) %in%
      issue_key(cached$volume, cached$issue)
    discovered <- discovered[discovered$published_year <= min(failed_years) | known, ]
  }
  merged <- dplyr::bind_rows(discovered, cached)
  merged <- merged[!duplicated(issue_key(merged$volume, merged$issue)), ]
  sort_manifest(merged)
}

# The manifest of a journal whose snapshot exists but whose issue list was
# never cached (washdev, first scraped by an older scraper).
manifest_from_snapshot <- function(scraped, slug, site_root) {
  issues <- dplyr::distinct(scraped, volume, issue, published_year)
  sort_manifest(tibble::tibble(
    volume = as.integer(issues$volume),
    issue = as.character(issues$issue),
    url = paste(site_root, slug, "issue", issues$volume, issues$issue, sep = "/"),
    published_year = as.integer(issues$published_year)
  ))
}

# The issues a run visits, in publication order, with what to do there:
# - "scrape": the issue is in the manifest but not in the snapshot, because
#   it is new or an earlier run lost it. Issues logged as permanently empty
#   are left out.
# - "recheck": one of the `recheck` most recent numbered issues in the
#   snapshot. Its table of contents is read again to catch articles added
#   late. Supplement issues ("S1") are left out: they sort after the numbered
#   issues of their volume and would take the place of a recent issue for
#   the rest of the year.
# Either way only the articles new_articles() returns are fetched.
#
# `only` names "volume/issue" keys and replaces the plan: exactly those
# issues are visited, whether or not a normal run would. A smoke test of one
# issue uses it.
plan_scrape <- function(manifest, scraped, empty_keys = character(),
                        recheck = 2L, only = NULL) {
  manifest <- sort_manifest(manifest)
  manifest$key <- issue_key(manifest$volume, manifest$issue)
  is_scraped <- manifest$key %in% issue_key(scraped$volume, scraped$issue)
  if (!is.null(only)) {
    manifest$action <- ifelse(is_scraped, "recheck", "scrape")
    return(manifest[manifest$key %in% only, ])
  }
  is_numbered <- grepl("^[0-9]", manifest$issue)
  recent <- utils::tail(manifest$key[is_scraped & is_numbered], recheck)
  manifest$action <- ifelse(
    manifest$key %in% recent, "recheck",
    ifelse(!is_scraped & !manifest$key %in% empty_keys, "scrape", NA_character_)
  )
  manifest[!is.na(manifest$action), ]
}

# The articles of an issue's table of contents that are not in the snapshot.
new_articles <- function(overview, scraped) {
  overview[!overview$paperid %in% scraped$paperid, ]
}

# Whether an issue with an empty table of contents may be logged as
# permanently empty. A logged issue is never visited again, so this waits
# until the issue is two years older than the newest volume. The site lists
# an issue before its articles are online, and at the turn of the year the
# last issue of the previous volume can still be empty.
empty_is_final <- function(published_year, manifest) {
  published_year <= max(manifest$published_year) - 2L
}

# Raw snapshot round trip ----------------------------------------------------

# A snapshot is read as text and written back with the new rows appended.
# Typed columns would be re-formatted on the way out, which rewrites rows
# that did not change.
read_snapshot <- function(path) {
  readr::read_csv(
    path,
    col_types = readr::cols(.default = readr::col_character()),
    # Only an empty cell is missing. A cell that reads "NA" is text.
    na = "", progress = FALSE
  )
}

write_snapshot <- function(data, path) {
  readr::write_csv(data, path, na = "", progress = FALSE)
}

# New rows as text, so that they can be appended to a snapshot read with
# read_snapshot().
as_snapshot_text <- function(rows) {
  dplyr::mutate(rows, dplyr::across(dplyr::everything(), as.character))
}
