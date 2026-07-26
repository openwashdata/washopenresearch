# Scrape article metadata from any IWA Publishing journal on iwaponline.com
# (issues #32, #33, #34). Generalizes data-raw/washdev_scraping.R, which is
# sourced for its browser helpers and Silverchair article parsers; only the
# journal-specific parts (slug, name, issue discovery, TOC parsing) live here.
#
# Issue discovery does not hardcode a publication schedule. The /<slug>/issue
# page exposes a #YearsList select (one option per volume, labelled with its
# year) and each volume's first issue page exposes a #IssuesList select (one
# option per issue, including combined issues). The discovered manifest is
# cached to data-raw/<slug>_issues.csv; delete it to force rediscovery.
#
# The scrape is resumable: the raw CSV is rewritten after every completed
# issue, and a resumed run skips (volume, issue) pairs already present.
# Issues whose TOC has no article list are logged to
# data-raw/<slug>_empty_issues.log so they are not refetched forever.
#
# AQUA is scoped to publication years >= 1996: the journal goes back to 1952,
# but the #18 study window (and the venue share that triggered #33) starts in
# 1996. jwh (2003) and ws (2001) fall inside the window entirely.
#
# Run one journal from the package root:
#   Rscript data-raw/iwa_scraping.R jwh
#   Rscript data-raw/iwa_scraping.R aqua
#   Rscript data-raw/iwa_scraping.R ws

source("data-raw/washdev_scraping.R")

# Silverchair throttles bursts of requests with a "Validate User" interstitial
# (distinct from the "Just a moment" Cloudflare challenge the base fetch_page
# already handles). Once tripped it persists for a per-path cooldown of a few
# minutes, so the fix is to slow down and wait it out, not to retry hard. This
# override adds the interstitial to the challenge check and, when a page will
# not settle, escalates the sleep and reloads before giving up. It shadows the
# fetch_page sourced from washdev_scraping.R for the IWA runs only.
CHALLENGE_RE <- "Just a moment|Verifying you are human|Validate User"

# Silverchair blocks bursts, so run slow and unattended (user decision,
# 2026-07-24): pause a jittered interval between every article fetch. Tune
# with the IWA_PAUSE_RANGE env var ("min,max" seconds); default 8-15s keeps
# a full-journal discovery+scrape under the throttle at the cost of hours per
# journal. This is on top of fetch_page's own 1-3s post-load sleep.
PAUSE_RANGE <- {
  raw <- Sys.getenv("IWA_PAUSE_RANGE", "8,15")
  as.numeric(strsplit(raw, ",")[[1]])
}

polite_pause <- function() Sys.sleep(runif(1, PAUSE_RANGE[1], PAUSE_RANGE[2]))

fetch_page <- function(session, url, max_polls = 20L, poll_s = 3,
                       backoffs = c(20, 45, 90, 180)) {
  # One navigation per pass; a failed pass sleeps backoffs[k] before the next.
  # The final pass has no trailing sleep, so there are length(backoffs)+1 tries.
  for (attempt in seq_len(length(backoffs) + 1L)) {
    session$Page$navigate(url, wait_ = FALSE)
    html <- NA_character_
    settled <- FALSE
    for (i in seq_len(max_polls)) {
      Sys.sleep(poll_s)
      ready <- session$Runtime$evaluate("document.readyState")$result$value
      html <- session$Runtime$evaluate(
        "document.documentElement.outerHTML"
      )$result$value
      challenged <- grepl(CHALLENGE_RE, html)
      if (identical(ready, "complete") && !challenged) { settled <- TRUE; break }
    }
    if (settled) {
      Sys.sleep(runif(1, 1, 3))
      return(html)
    }
    if (attempt <= length(backoffs)) {
      wait <- backoffs[attempt]
      message("  throttled at ", url, "; backing off ", wait, "s (attempt ", attempt, ")")
      Sys.sleep(wait)
    }
  }
  warning("Page did not settle after backoff: ", url, call. = FALSE)
  NA_character_
}

#' Fetch and parse one article, distinguishing a throttled fetch (NA html,
#' worth retrying) from a genuine parse failure (bad markup, not worth
#' retrying). Returns a one-row tibble; the `fetch_ok` column is FALSE when
#' the page never loaded, so the caller can decline to persist a half-scraped
#' issue and let the resume logic retry it. Shadows washdev's scrape_article.
scrape_article <- function(session, url, tries = 3) {
  for (attempt in seq_len(tries)) {
    html <- fetch_page(session, url)
    if (is.na(html)) {
      if (attempt < tries) { Sys.sleep(30 * attempt); next }
      return(tibble(fetch_ok = FALSE))
    }
    parsed <- tryCatch(parse_article_page(html), error = function(e) {
      warning("Failed to parse ", url, ": ", conditionMessage(e), call. = FALSE)
      NULL
    })
    if (is.null(parsed)) {
      # Genuine parse failure: keep the row as NAs but mark it fetched so the
      # issue is not retried forever over one malformed article.
      return(mutate(parse_article_page("<html></html>"), fetch_ok = TRUE))
    }
    return(mutate(parsed, fetch_ok = TRUE))
  }
}

JOURNALS <- list(
  jwh = list(
    slug = "jwh",
    name = "Journal of Water and Health",
    start_year = NA
  ),
  aqua = list(
    slug = "aqua",
    name = "AQUA - Water Infrastructure, Ecosystems and Society",
    start_year = 1996L
  ),
  ws = list(
    slug = "ws",
    name = "Water Supply",
    start_year = NA
  )
)

# Issue discovery ----------------------------------------------------------

parse_select_options <- function(page, select_id) {
  opts <- html_elements(page, sprintf("select#%s option", select_id))
  tibble(
    value = html_attr(opts, "value"),
    label = str_squish(html_text(opts))
  )
}

issue_url_parts <- function(url) {
  m <- str_match(url, "/issue/([0-9]+)/([^/?#]+)")
  list(volume = as.integer(m[, 2]), issue = m[, 3])
}

#' Enumerate every issue of a journal from the site's own browse widgets.
#' One fetch for the year list, one fetch per volume for its issue list.
#' Returns tibble(volume, issue, url, published_year).
discover_issues <- function(session, slug, start_year = NA) {
  html <- fetch_page(session, sprintf("%s/%s/issue", SITE_ROOT, slug))
  if (is.na(html)) stop("Could not load the issue browse page for ", slug)
  years <- parse_select_options(read_html(html), "YearsList") |>
    mutate(
      published_year = as.integer(label),
      volume = issue_url_parts(value)$volume
    ) |>
    filter(!is.na(volume), !is.na(published_year))
  if (!is.na(start_year)) years <- filter(years, published_year >= start_year)
  message("  ", nrow(years), " volumes to enumerate for ", slug)

  map(seq_len(nrow(years)), function(i) {
    if (i > 1) polite_pause()
    vol_url <- paste0(SITE_ROOT, years$value[i])
    html <- fetch_page(session, vol_url)
    if (is.na(html)) {
      warning("Issue list did not load for ", vol_url, call. = FALSE)
      return(NULL)
    }
    issues <- parse_select_options(read_html(html), "IssuesList")
    if (nrow(issues) == 0) {
      # A volume with a single issue may render without the select; fall
      # back to the volume's first-issue URL itself
      issues <- tibble(value = years$value[i], label = NA_character_)
    }
    parts <- issue_url_parts(issues$value)
    tibble(
      volume = parts$volume,
      issue = parts$issue,
      url = paste0(SITE_ROOT, issues$value),
      published_year = years$published_year[i]
    )
  }) |>
    list_rbind() |>
    distinct(volume, issue, .keep_all = TRUE) |>
    arrange(volume, suppressWarnings(as.integer(str_extract(issue, "^[0-9]+"))))
}

issue_manifest <- function(session, cfg, manifest_path) {
  if (file.exists(manifest_path)) {
    manifest <- read_csv(manifest_path, show_col_types = FALSE,
                         col_types = cols(issue = col_character()))
    message("  manifest: ", nrow(manifest), " issues (cached)")
    return(manifest)
  }
  message("  discovering issues for ", cfg$slug, " ...")
  manifest <- discover_issues(session, cfg$slug, cfg$start_year)
  write_csv(manifest, manifest_path)
  message("  manifest: ", nrow(manifest), " issues (written to ", manifest_path, ")")
  manifest
}

# Issue table of contents --------------------------------------------------

#' Like washdev's parse_issue_page, with the article-link selector and
#' journal fields parameterized. published_year comes from the manifest, not
#' from a volume arithmetic rule.
parse_iwa_issue_page <- function(html, cfg, volume, issue, published_year) {
  empty <- tibble(
    paperid = character(), volume = integer(), issue = character(),
    url = character(), journal = character(), title = character(),
    published_year = integer()
  )
  if (is.na(html)) return(empty)
  page <- read_html(html)
  article_list <- html_element(page, "#ArticleList")
  if (!node_exists(article_list)) return(empty)
  links <- html_elements(
    article_list, sprintf("a[href*='/%s/article/']", cfg$slug)
  )
  links <- links[is.na(html_attr(links, "class"))]
  if (length(links) == 0) return(empty)
  tibble(
    paperid = map_chr(links, \(a) xml_attr(xml_parent(a), "data-resource-id-access")),
    volume = volume,
    issue = issue,
    url = paste0(SITE_ROOT, html_attr(links, "href")),
    journal = cfg$name,
    title = str_trim(html_text(links)),
    published_year = published_year
  )
}

# Main ---------------------------------------------------------------------

read_raw_if_exists <- function(path) {
  if (!file.exists(path)) return(NULL)
  read_csv(path, show_col_types = FALSE,
           col_types = cols(issue = col_character(), paperid = col_character()))
}

#' Scrape one journal end to end. `only` limits the run to specific
#' "volume/issue" strings (for smoke tests), `max_issues` caps how many
#' issues this invocation processes before returning.
scrape_iwa_journal <- function(cfg, only = NULL, max_issues = Inf) {
  raw_path <- file.path("data-raw", paste0(cfg$slug, ".csv"))
  manifest_path <- file.path("data-raw", paste0(cfg$slug, "_issues.csv"))
  empty_log <- file.path("data-raw", paste0(cfg$slug, "_empty_issues.log"))

  session <- start_browser()
  on.exit(try(session$parent$close(), silent = TRUE), add = TRUE)

  manifest <- issue_manifest(session, cfg, manifest_path)
  existing <- read_raw_if_exists(raw_path)
  done_keys <- if (is.null(existing)) character() else {
    unique(paste(existing$volume, existing$issue, sep = "/"))
  }
  empty_keys <- if (file.exists(empty_log)) read_lines(empty_log) else character()

  manifest <- manifest |>
    mutate(key = paste(volume, issue, sep = "/")) |>
    filter(!key %in% done_keys, !key %in% empty_keys)
  if (!is.null(only)) manifest <- filter(manifest, key %in% only)
  if (nrow(manifest) == 0) {
    message("Nothing to scrape for ", cfg$slug)
    return(invisible(existing))
  }
  manifest <- head(manifest, max_issues)
  message("Scraping ", nrow(manifest), " issues for ", cfg$slug)

  for (i in seq_len(nrow(manifest))) {
    row <- manifest[i, ]
    message(format(Sys.time(), "%H:%M:%S"), " ", cfg$slug, " ",
            row$key, " (", i, "/", nrow(manifest), ") ...")

    # Headless Chrome occasionally dies mid-navigation (websocketpp EOF /
    # Chromote command timeout), which used to abort the whole journal. Wrap
    # the issue so a Chrome crash respawns the session and retries the issue
    # once; a second failure skips the issue for a later resume rather than
    # killing the run.
    result <- tryCatch(
      scrape_one_issue(session, row, cfg, empty_log),
      error = function(e) {
        if (is_chrome_crash(e)) return(structure("crashed", crash_msg = conditionMessage(e)))
        stop(e)
      }
    )
    # scrape_one_issue always returns a list; only the crash handler returns a
    # character sentinel, so is.character(result) uniquely means "Chrome died".
    if (is.character(result)) {
      message("  Chrome crashed (", attr(result, "crash_msg"), "); respawning and retrying issue")
      try(session$parent$close(), silent = TRUE)
      Sys.sleep(30)
      session <- start_browser()
      result <- tryCatch(
        scrape_one_issue(session, row, cfg, empty_log),
        error = function(e) {
          message("  issue failed again after respawn (", conditionMessage(e),
                  "); skipping for later retry")
          list(status = "skip")
        }
      )
    }

    if (result$status == "rows") {
      existing <- bind_rows(existing, result$rows)
      write_csv(existing, raw_path, na = "")
      message("  added ", nrow(result$rows), " articles (total ", nrow(existing), ")")
    }
    # status "empty" and "skip" persist nothing; "empty" already logged the key.
  }
  invisible(existing)
}

#' Detect a Chromote/Chrome-crash error (connection lost, command timeout)
#' as opposed to an ordinary R error, so only the former triggers a respawn.
is_chrome_crash <- function(e) {
  # Two Chrome-death signatures seen so far, both fatal to the session and
  # both worth a respawn+retry rather than aborting the journal:
  #   1. "Chromote: timed out waiting for response to command <X>" (connection
  #      lost mid-navigation; jwh issue 101).
  #   2. CDP error -32001 "Session with given id not found" wrapped as
  #      "error in callback()" (session dropped; aqua issue 79).
  # Match the broad family (any Chromote/CDP/session-lost text) so a new
  # variant of the same class is caught too.
  grepl(paste(
    "Chromote", "websocket", "Page.navigate", "Runtime.evaluate",
    "timed out waiting", "Session with given id not found",
    "-32001", "error in .callback",
    sep = "|"
  ), conditionMessage(e), ignore.case = TRUE)
}

#' Process one issue with a given session. Returns a list with:
#'   status "rows"  + rows: parsed article rows to persist
#'   status "empty"          : TOC loaded, no articles (key logged as empty)
#'   status "skip"           : throttled TOC or throttled articles; retry later
#' Chrome-crash errors propagate so the caller can respawn and retry.
scrape_one_issue <- function(session, row, cfg, empty_log) {
  toc_html <- fetch_page(session, row$url)
  if (is.na(toc_html)) {
    message("  issue TOC still throttled; skipping for later retry")
    Sys.sleep(120)
    return(list(status = "skip"))
  }
  overview <- parse_iwa_issue_page(
    toc_html,
    cfg = cfg, volume = row$volume, issue = row$issue,
    published_year = row$published_year
  )
  if (nrow(overview) == 0) {
    message("  no articles found, logging as empty")
    write_lines(row$key, empty_log, append = TRUE)
    return(list(status = "empty"))
  }
  metadata <- map(overview$url, function(u) {
    out <- scrape_article(session, u)
    polite_pause()
    out
  }) |>
    list_rbind()
  if (any(!metadata$fetch_ok)) {
    message("  ", sum(!metadata$fetch_ok), "/", nrow(metadata),
            " articles still throttled; skipping issue for later retry")
    Sys.sleep(120)
    return(list(status = "skip"))
  }
  metadata$fetch_ok <- NULL
  list(status = "rows", rows = bind_cols(overview, metadata))
}

if (sys.nframe() == 0 && !interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1 || !args[1] %in% names(JOURNALS)) {
    stop("Usage: Rscript data-raw/iwa_scraping.R <", paste(names(JOURNALS), collapse = "|"), ">")
  }
  scrape_iwa_journal(JOURNALS[[args[1]]])
}
