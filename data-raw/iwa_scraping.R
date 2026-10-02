# Scrape article metadata from the IWA Publishing journals on iwaponline.com:
# washdev, ws, jwh and aqua (issues #11, #32, #33, #34).
#
# One code path for all four journals. Only the journal's slug, name and
# start year differ (see JOURNALS). The scraper drives a headless Chrome
# session via {chromote}, because iwaponline.com sits behind Cloudflare and
# blocks plain HTTP clients. Overriding the "HeadlessChrome" user agent is
# enough to pass the challenge.
#
# A run is incremental. What it fetches is decided by the functions in
# data-raw/scrape_plan.R, which are tested without network:
# - The issue manifest (data-raw/<slug>_issues.csv) is refreshed on every
#   run. The site's browse widgets are enumerated again from the newest known
#   publication year and merged with the cached manifest, so journal issues
#   published since the last run are found. The #YearsList select holds one
#   option per volume, labelled with its year, and each volume's first issue
#   page holds an #IssuesList select with one option per issue.
# - Issues in the manifest but not in the raw snapshot are scraped.
# - The two most recent issues in the snapshot are read again, and articles
#   added late are fetched.
#
# The scrape is resumable: the raw snapshot is rewritten after every issue
# that added articles. An issue is stored complete or not at all. When one
# of its pages does not load, or loads as something other than the page
# asked for, nothing of the issue is stored, the run ends with exit status
# 1, and the next run tries the issue again. No row is ever written for an
# article whose page was not read.
#
# Issues whose table of contents has no article list are logged to
# data-raw/<slug>_empty_issues.log so they are not fetched forever, but only
# once they are two years older than the newest volume. The site lists an
# issue before its articles are online.
#
# What does not enter a raw snapshot: author email addresses, credentials
# inside a statement, and the signed query of the supplement download links.
# The signed links work for about three weeks. They are written to
# data-raw/private/<slug>-signed-supp-links.csv, which is not committed, for
# data-raw/suppfiles_download.R.
#
# AQUA is scoped to publication years >= 1996: the journal goes back to 1952,
# but the #18 study window (and the venue share that triggered #33) starts in
# 1996. washdev (2011), jwh (2003) and ws (2001) fall inside the window.
#
# Run one journal from the package root, or all sources with
# data-raw/update_sources.R:
#   Rscript data-raw/iwa_scraping.R washdev
#   Rscript data-raw/iwa_scraping.R jwh
#   Rscript data-raw/iwa_scraping.R aqua
#   Rscript data-raw/iwa_scraping.R ws

# The pinned packages, unless a calling script loaded them already
if (!nzchar(Sys.getenv("RENV_PROJECT"))) renv::load(quiet = TRUE)

library(chromote)
library(rvest)
library(xml2)
library(dplyr)
library(purrr)
library(stringr)
library(readr)
library(tibble)

# For the helpers that keep addresses and credentials out of the raw snapshot
source("data-raw/helpers.R")
source("data-raw/scrape_plan.R")

SITE_ROOT <- "https://iwaponline.com"
DAS_ONLINE_BOILERPLATE <-
  "All relevant data are available from an online repository or repositories"

JOURNALS <- list(
  washdev = list(
    slug = "washdev",
    name = "Journal of Water, Sanitation & Hygiene for Development",
    start_year = NA
  ),
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

# Browser session ---------------------------------------------------------

start_browser <- function() {
  session <- ChromoteSession$new()
  ua <- session$Browser$getVersion()$userAgent
  session$Network$setUserAgentOverride(
    userAgent = gsub("HeadlessChrome", "Chrome", ua)
  )
  session
}

# Silverchair throttles bursts of requests with a "Validate User" interstitial
# (distinct from the "Just a moment" Cloudflare challenge). Once tripped it
# persists for a per-path cooldown of a few minutes, so the fix is to slow
# down and wait it out, not to retry hard.
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

#' Navigate to a URL and return the rendered HTML.
#'
#' Polls until the document is complete and no challenge text is present,
#' then sleeps 1-3 seconds to stay polite. When a page will not settle, the
#' sleep escalates and the page is loaded again. Returns NA_character_ if
#' the page never settles.
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

# Small helpers ------------------------------------------------------------

node_exists <- function(node) !inherits(node, "xml_missing")

#' Whether the site served the kind of page that was asked for. The site
#' states the kind in the class of <body>: "pg_issue" on an issue's table of
#' contents, "pg_article" on an article. Its "Not Found" page and a browser
#' error page load completely as well, and carry neither.
is_page_type <- function(html, type) {
  if (is.na(html)) return(FALSE)
  classes <- html_attr(html_element(read_html(html), "body"), "class")
  !is.na(classes) && type %in% str_split_1(classes, "\\s+")
}

#' Format a character vector the way pandas wrote Python lists to the raw
#' CSV, e.g. "['a', 'b']" or "[]". The first washdev rows came from a Python
#' scraper, and the build pipeline parses this one format for all rows.
py_list <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return("[]")
  paste0("['", paste(x, collapse = "', '"), "']")
}

#' First text node directly inside a node, stripped. Mirrors BeautifulSoup's
#' `.next` on an element whose first child is text.
first_text <- function(node) {
  txt <- xml_find_first(node, "./text()[normalize-space()]")
  if (inherits(txt, "xml_missing")) return(NA_character_)
  str_trim(xml_text(txt))
}

# Article metadata ---------------------------------------------------------

parse_supp <- function(page) {
  supp_nodes <- html_elements(page, "div.dataSuppLink")
  supp_types <- map_chr(supp_nodes, function(node) {
    # The file type is the text after the download link: "- docx file"
    txt <- str_trim(paste(xml_text(xml_find_all(node, "./text()")), collapse = " "))
    tokens <- str_split_1(str_trim(txt), "\\s+")
    if (length(tokens) >= 2) tokens[2] else NA_character_
  })
  # When supplements have mixed file types, all types are recorded joined by
  # " & " (one per file, e.g. "docx & xlsx")
  supp_type <- if (length(supp_types) == 0) {
    NA_character_
  } else {
    paste(supp_types, collapse = " & ")
  }
  links <- map_chr(supp_nodes, \(node) html_attr(html_element(node, "a"), "href"))
  list(
    is_supp = node_exists(html_element(page, "h2#supplementary-data")),
    num_supp = length(supp_nodes),
    supp_file_type = supp_type,
    # The download links are pre-signed; only the file path is kept
    supp_url = py_list(strip_silverchair_signature(links)),
    # The links as the page gave them, for keep_signed_links_private(). This
    # column never reaches the raw snapshot.
    supp_url_signed = list(links)
  )
}

#' Extract name, affiliation, country, and ORCID from one author info card
#' (a div.info-card-author node). The author's email address on the card is
#' not collected, because the raw snapshots hold no author contact addresses.
#' Some pages print the address after the affiliation text as well; there it
#' is masked the way the build masks addresses in text.
parse_author_card <- function(card) {
  name <- first_text(html_element(card, "div.info-card-name"))
  aff_node <- html_element(card, "div.aff")
  if (node_exists(aff_node)) {
    # The affiliation div may open with a <span> marker; the affiliation
    # text is then the node right after it
    span <- html_element(aff_node, "span")
    aff <- if (node_exists(span)) {
      xml_text(xml_find_first(aff_node, "./span[1]/following-sibling::node()[1]"))
    } else {
      html_text(aff_node)
    }
    aff <- redact_inline_emails(str_trim(aff))
    country <- last(str_split_1(aff, ", "))
    country <- str_split_1(country, " Email")[1]
  } else {
    aff <- NA_character_
    country <- NA_character_
  }
  orcid_node <- html_element(card, "a[id^='contrib-orcid']")
  list(
    name = name,
    affiliation = aff,
    affiliation_country = country,
    orcid = if (node_exists(orcid_node)) html_attr(orcid_node, "href") else NA_character_
  )
}

parse_authors <- function(page) {
  na_author <- list(
    name = NA_character_, affiliation = NA_character_,
    affiliation_country = NA_character_, orcid = NA_character_
  )
  cards <- html_elements(page, "div.info-card-author")
  first <- if (length(cards) > 0) parse_author_card(cards[[1]]) else na_author
  corresp_marker <- html_element(page, "div.info-author-correspondence")
  corresp <- if (node_exists(corresp_marker)) {
    parse_author_card(xml_parent(corresp_marker))
  } else {
    na_author
  }
  list(
    num_authors = length(html_elements(page, "div.info-card-name")),
    first_author_name = first$name,
    first_author_affiliation = first$affiliation,
    first_author_affiliation_country = first$affiliation_country,
    first_author_orcid = first$orcid,
    correspondence_author_name = corresp$name,
    correspondence_author_affiliation = corresp$affiliation,
    correspondence_author_affiliation_country = corresp$affiliation_country,
    correspondence_author_orcid = corresp$orcid
  )
}

#' Repository URL from the DAS text, for statements that start with the
#' standard online-repository sentence. Three regexes in decreasing order
#' of strictness: a URL inside parentheses, any URL, anything inside
#' parentheses.
extract_das_repo <- function(das_text) {
  if (is.na(das_text) || !startsWith(das_text, DAS_ONLINE_BOILERPLATE)) {
    return(NA_character_)
  }
  rest <- str_sub(das_text, nchar(DAS_ONLINE_BOILERPLATE) + 1)
  for (pattern in c(
    "\\((https?://[^\\s]+)\\)",
    "(https?://[^\\s]+)",
    "\\(([^\\s)]+)\\)"
  )) {
    hit <- str_match(rest, pattern)[, 2]
    if (!is.na(hit)) return(hit)
  }
  NA_character_
}

parse_das <- function(page) {
  heading <- html_element(
    page, "h2[data-section-title='DATA AVAILABILITY STATEMENT']"
  )
  has_das <- node_exists(heading)
  das_text <- NA_character_
  if (has_das) {
    section_id <- html_attr(heading, "id")
    body <- html_element(
      page, sprintf("div[data-section-parent-id='%s']", section_id)
    )
    if (node_exists(body)) {
      das_text <- remove_credentials(str_trim(html_text(body)))
    }
  }
  das_type <- if (!is.na(das_text) && startsWith(das_text, DAS_ONLINE_BOILERPLATE)) {
    DAS_ONLINE_BOILERPLATE
  } else {
    das_text
  }
  list(
    has_das = has_das,
    das = das_text,
    das_type = das_type,
    das_repo_url = extract_das_repo(das_text)
  )
}

parse_keywords <- function(page) {
  group <- html_element(page, "div.kwd-group")
  if (!node_exists(group)) return(py_list(character()))
  py_list(html_text(xml_children(group)))
}

parse_doi <- function(page) {
  meta <- html_element(page, "meta[name='citation_doi']")
  if (node_exists(meta)) html_attr(meta, "content") else NA_character_
}

#' All article-level metadata for one article page, as a one-row tibble.
parse_article_page <- function(html) {
  page <- read_html(html)
  as_tibble(c(
    parse_supp(page),
    parse_authors(page),
    parse_das(page),
    list(keywords = parse_keywords(page), doi = parse_doi(page))
  ))
}

#' Fetch and parse one article. Returns a one-row tibble with the column
#' `fetch_ok`. It is FALSE, and the only column, when the article was not
#' read: the page never loaded, loaded as something other than an article
#' page, or could not be parsed. The caller then stores nothing of the issue
#' and the next run tries again. No row is made up for an article that was
#' not read, because a row of missing values reads as "no statement, no
#' supplement" in the dataset.
scrape_article <- function(session, url, tries = 3) {
  for (attempt in seq_len(tries)) {
    html <- fetch_page(session, url)
    if (is_page_type(html, "pg_article")) break
    if (attempt == tries) {
      if (!is.na(html)) message("  not an article page: ", url)
      return(tibble(fetch_ok = FALSE))
    }
    Sys.sleep(30 * attempt)
  }
  parsed <- tryCatch(parse_article_page(html), error = function(e) {
    message("  could not parse ", url, ": ", conditionMessage(e))
    NULL
  })
  if (is.null(parsed)) return(tibble(fetch_ok = FALSE))
  mutate(parsed, fetch_ok = TRUE)
}

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

#' Enumerate the issues of a journal from the site's own browse widgets,
#' from publication year `start_year` on (NA for all years). One fetch for
#' the year list, one fetch per volume for its issue list.
#' Returns tibble(volume, issue, url, published_year). The years whose
#' issue list did not load are in the attribute "failed_years"; see
#' merge_manifest() for what follows from them.
discover_issues <- function(session, slug, start_year = NA) {
  html <- fetch_page(session, sprintf("%s/%s/issue", SITE_ROOT, slug))
  if (is.na(html)) stop("Could not load the issue browse page for ", slug)
  years <- parse_select_options(read_html(html), "YearsList") |>
    mutate(
      published_year = as.integer(label),
      volume = issue_url_parts(value)$volume
    ) |>
    filter(!is.na(volume), !is.na(published_year))
  if (nrow(years) == 0) stop("The issue browse page for ", slug, " lists no volumes")
  if (!is.na(start_year)) years <- filter(years, published_year >= start_year)
  message("  ", nrow(years), " volumes to enumerate for ", slug)

  failed_years <- integer()
  issues <- map(seq_len(nrow(years)), function(i) {
    if (i > 1) polite_pause()
    vol_url <- paste0(SITE_ROOT, years$value[i])
    html <- fetch_page(session, vol_url)
    if (is.na(html)) {
      message("  !! the issue list of ", years$published_year[i], " did not load")
      failed_years <<- c(failed_years, years$published_year[i])
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
  })
  # Typed, so that a run in which no list loaded still returns the columns
  no_issues <- tibble(
    volume = integer(), issue = character(), url = character(),
    published_year = integer()
  )
  discovered <- bind_rows(no_issues, list_rbind(issues)) |>
    distinct(volume, issue, .keep_all = TRUE)
  attr(discovered, "failed_years") <- failed_years
  discovered
}

read_manifest <- function(path) {
  read_csv(path, col_types = cols(
    volume = col_integer(), issue = col_character(),
    url = col_character(), published_year = col_integer()
  ))
}

#' The issue manifest of a journal, refreshed from the site. The cached
#' manifest is the starting point, or, for a journal that has a snapshot but
#' no cached manifest, the issues in the snapshot. With `refresh = FALSE` the
#' site is not asked, which a smoke test of one issue uses.
#'
#' Returns list(manifest, complete). `complete` is FALSE when the site's
#' issue list could not be read in full. The run then works with what is
#' known, and the next run asks again.
issue_manifest <- function(session, cfg, manifest_path, scraped, refresh = TRUE) {
  cached <- if (file.exists(manifest_path)) {
    read_manifest(manifest_path)
  } else if (!is.null(scraped)) {
    manifest_from_snapshot(scraped, cfg$slug, SITE_ROOT)
  }
  if (!refresh && !is.null(cached)) {
    message("  manifest: ", nrow(cached), " issues (not refreshed)")
    return(list(manifest = cached, complete = TRUE))
  }
  from_year <- refresh_from_year(cached, cfg$start_year)
  message("  listing the issues of ", cfg$slug,
          if (is.na(from_year)) "" else paste(" from", from_year), " ...")
  discovered <- tryCatch(
    discover_issues(session, cfg$slug, from_year),
    error = function(e) {
      # Without a cached manifest there is nothing to work with
      if (is.null(cached)) stop(e)
      message("  !! the issue list could not be read (", conditionMessage(e),
              "); working with the cached manifest")
      NULL
    }
  )
  if (is.null(discovered)) return(list(manifest = cached, complete = FALSE))
  failed_years <- attr(discovered, "failed_years")
  manifest <- merge_manifest(cached, discovered, failed_years)
  write_csv(manifest, manifest_path)
  known <- if (is.null(cached)) 0L else nrow(cached)
  message("  manifest: ", nrow(manifest), " issues (", nrow(manifest) - known, " new)")
  list(manifest = manifest, complete = length(failed_years) == 0)
}

# Issue table of contents --------------------------------------------------

#' Parse one issue's table-of-contents page into the overview columns: one
#' row per article with paperid, volume, issue, url, journal, title,
#' published_year. Returns a zero-row tibble when the page has no article
#' list. published_year comes from the manifest, not from a volume
#' arithmetic rule.
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
  # Only <a> tags without a class attribute; the classed ones are PDF and
  # citation links pointing at the same articles
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

# Signed supplement links --------------------------------------------------

#' Move the signed supplement links out of freshly scraped rows. They are
#' appended to <data_dir>/private/<slug>-signed-supp-links.csv, one row per
#' file, and the column is dropped, so the rows that go on to the raw
#' snapshot hold the file paths only. The private directory is not committed.
keep_signed_links_private <- function(rows, cfg, data_dir) {
  links <- rows$supp_url_signed
  signed <- tibble(
    paperid = rep(rows$paperid, lengths(links)),
    doi = rep(rows$doi, lengths(links)),
    url = as.character(unlist(links)),
    scraped_on = as.character(Sys.Date())
  ) |>
    filter(!is.na(url), url != strip_silverchair_signature(url))
  if (nrow(signed) > 0) {
    private_dir <- file.path(data_dir, "private")
    dir.create(private_dir, showWarnings = FALSE)
    path <- file.path(private_dir, paste0(cfg$slug, "-signed-supp-links.csv"))
    write_csv(signed, path, na = "", append = file.exists(path))
  }
  select(rows, -supp_url_signed)
}

# Main ---------------------------------------------------------------------

#' Scrape one journal. `only` limits the run to specific "volume/issue"
#' strings and `refresh_manifest = FALSE` skips the issue listing (both for
#' smoke tests), `max_issues` caps how many issues this invocation visits,
#' and `data_dir` is the directory of the raw snapshot and the manifest.
#' Returns list(snapshot, skipped), invisibly. `skipped` names what could not
#' be read: issue keys, and "issue list" when the manifest refresh failed.
scrape_iwa_journal <- function(cfg, only = NULL, max_issues = Inf,
                               refresh_manifest = TRUE, data_dir = "data-raw") {
  raw_path <- file.path(data_dir, paste0(cfg$slug, ".csv"))
  manifest_path <- file.path(data_dir, paste0(cfg$slug, "_issues.csv"))
  empty_log <- file.path(data_dir, paste0(cfg$slug, "_empty_issues.log"))

  session <- start_browser()
  on.exit(try(session$parent$close(), silent = TRUE), add = TRUE)

  existing <- if (file.exists(raw_path)) read_snapshot(raw_path)
  listing <- issue_manifest(session, cfg, manifest_path, existing, refresh_manifest)
  manifest <- listing$manifest
  skipped <- if (listing$complete) character() else "issue list"
  empty_keys <- if (file.exists(empty_log)) read_lines(empty_log) else character()

  plan <- plan_scrape(manifest, existing, empty_keys, only = only)
  if (nrow(plan) == 0) {
    message("Nothing to visit for ", cfg$slug)
    return(invisible(list(snapshot = existing, skipped = skipped)))
  }
  plan <- head(plan, max_issues)
  message("Visiting ", nrow(plan), " issues of ", cfg$slug, " (",
          sum(plan$action == "scrape"), " to scrape, ",
          sum(plan$action == "recheck"), " to check for late articles)")

  for (i in seq_len(nrow(plan))) {
    row <- plan[i, ]
    message(format(Sys.time(), "%H:%M:%S"), " ", cfg$slug, " ",
            row$key, " (", i, "/", nrow(plan), ", ", row$action, ") ...")
    final_if_empty <- row$action == "scrape" &&
      empty_is_final(row$published_year, manifest)

    # Headless Chrome occasionally dies mid-navigation (websocketpp EOF /
    # Chromote command timeout). Wrap the issue so a Chrome crash respawns
    # the session and retries the issue once; a second failure skips the
    # issue for a later run rather than killing this one.
    result <- tryCatch(
      scrape_one_issue(session, row, cfg, existing, empty_log, final_if_empty),
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
        scrape_one_issue(session, row, cfg, existing, empty_log, final_if_empty),
        error = function(e) {
          message("  issue failed again after respawn (", conditionMessage(e),
                  "); skipping for later retry")
          list(status = "skip")
        }
      )
    }

    if (result$status == "rows") {
      rows <- keep_signed_links_private(result$rows, cfg, data_dir) |>
        as_snapshot_text()
      if (!is.null(existing) && !setequal(names(rows), names(existing))) {
        stop("The scraped columns differ from the columns of ", raw_path, ": ",
             paste(union(setdiff(names(rows), names(existing)),
                         setdiff(names(existing), names(rows))), collapse = ", "),
             call. = FALSE)
      }
      existing <- bind_rows(existing, rows)
      write_snapshot(existing, raw_path)
      message("  added ", nrow(rows), " articles (total ", nrow(existing), ")")
    }
    # Every other status persists nothing; "empty" may have logged the key.
    if (result$status == "skip") skipped <- c(skipped, row$key)
  }
  if (length(skipped) > 0) {
    message("!! ", cfg$slug, ": could not be read: ",
            paste(skipped, collapse = ", "), ". The next run tries again.")
  }
  invisible(list(snapshot = existing, skipped = skipped))
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

#' Visit one issue with a given session and fetch the articles that are not
#' in the snapshot `scraped`. Returns a list with:
#'   status "rows"  + rows: parsed article rows to persist
#'   status "none"           : every article of the issue is in the snapshot
#'   status "empty"          : TOC loaded, no articles. The key is logged as
#'                             permanently empty only if `final_if_empty`
#'   status "skip"           : the TOC or an article was not read; retry later
#' Chrome-crash errors propagate so the caller can respawn and retry.
scrape_one_issue <- function(session, row, cfg, scraped, empty_log, final_if_empty) {
  toc_html <- fetch_page(session, row$url)
  if (is.na(toc_html)) {
    message("  issue TOC still throttled; skipping for later retry")
    Sys.sleep(120)
    return(list(status = "skip"))
  }
  # An error page has no article list either, and must not pass for an
  # empty issue
  if (!is_page_type(toc_html, "pg_issue")) {
    message("  the page is not an issue page; skipping for later retry")
    return(list(status = "skip"))
  }
  overview <- parse_iwa_issue_page(
    toc_html,
    cfg = cfg, volume = row$volume, issue = row$issue,
    published_year = row$published_year
  )
  if (nrow(overview) == 0) {
    if (final_if_empty) {
      message("  no articles found, logging as empty")
      write_lines(row$key, empty_log, append = TRUE)
    } else {
      message("  no articles found, asking again on the next run")
    }
    return(list(status = "empty"))
  }
  todo <- new_articles(overview, scraped)
  if (nrow(todo) == 0) {
    message("  nothing new (", nrow(overview), " articles, all in the snapshot)")
    return(list(status = "none"))
  }
  metadata <- map(todo$url, function(u) {
    out <- scrape_article(session, u)
    polite_pause()
    out
  }) |>
    list_rbind()
  if (any(!metadata$fetch_ok)) {
    message("  ", sum(!metadata$fetch_ok), "/", nrow(metadata),
            " articles not read; skipping issue for later retry")
    Sys.sleep(120)
    return(list(status = "skip"))
  }
  metadata$fetch_ok <- NULL
  list(status = "rows", rows = bind_cols(todo, metadata))
}

# Runs only when executed directly (Rscript data-raw/iwa_scraping.R <slug>),
# not when the file is source()d for its functions
if (sys.nframe() == 0 && !interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1 || !args[1] %in% names(JOURNALS)) {
    stop("Usage: Rscript data-raw/iwa_scraping.R <", paste(names(JOURNALS), collapse = "|"), ">")
  }
  result <- scrape_iwa_journal(JOURNALS[[args[1]]])
  # An incomplete run is a failed run for the caller (update_sources.R)
  if (length(result$skipped) > 0) quit(status = 1)
}
