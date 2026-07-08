# Scrape article metadata from the Journal of Water, Sanitation and Hygiene
# for Development (https://iwaponline.com/washdev).
#
# R port of inst/python/washdev_scraping_selenium.py (issue #11). Uses a
# headless Chrome session via {chromote} because iwaponline.com sits behind
# Cloudflare and blocks plain HTTP clients. Overriding the "HeadlessChrome"
# user agent is enough to pass the challenge.
#
# The scraper is incremental: it reads data-raw/washdev.csv, determines the
# last volume and issue present, scrapes only newer issues, and appends.
# Progress is written back to the CSV after every issue, so an interrupted
# run can be resumed by sourcing the script again.
#
# Differences from the Python version, both deliberate:
# - A `doi` column is collected from the citation_doi meta tag (new).
# - When supplements have mixed file types, all types are recorded joined
#   by " & " (one per file, e.g. "docx & xlsx") instead of the literal
#   "misc", which previously required manual repair in data_processing.R.
#
# Run from the package root:
#   Rscript data-raw/washdev_scraping.R

library(chromote)
library(rvest)
library(xml2)
library(dplyr)
library(purrr)
library(stringr)
library(readr)
library(tibble)

JOURNAL_NAME <- "Journal of Water, Sanitation & Hygiene for Development"
SITE_ROOT <- "https://iwaponline.com"
ISSUE_ROOT <- "https://iwaponline.com/washdev/issue"
DAS_ONLINE_BOILERPLATE <-
  "All relevant data are available from an online repository or repositories"

# Browser session ---------------------------------------------------------

start_browser <- function() {
  session <- ChromoteSession$new()
  ua <- session$Browser$getVersion()$userAgent
  session$Network$setUserAgentOverride(
    userAgent = gsub("HeadlessChrome", "Chrome", ua)
  )
  session
}

#' Navigate to a URL and return the rendered HTML.
#'
#' Polls until the document is complete and no Cloudflare challenge text is
#' present, then sleeps 1-3 seconds (as the Python scraper did) to stay
#' polite. Returns NA_character_ if the page never settles.
fetch_page <- function(session, url, max_polls = 15L, poll_s = 3) {
  session$Page$navigate(url, wait_ = FALSE)
  html <- NA_character_
  for (i in seq_len(max_polls)) {
    Sys.sleep(poll_s)
    ready <- session$Runtime$evaluate("document.readyState")$result$value
    html <- session$Runtime$evaluate(
      "document.documentElement.outerHTML"
    )$result$value
    challenged <- grepl("Just a moment|Verifying you are human", html)
    if (identical(ready, "complete") && !challenged) break
    if (i == max_polls) {
      warning("Page did not settle: ", url, call. = FALSE)
      html <- NA_character_
    }
  }
  Sys.sleep(runif(1, 1, 3))
  html
}

# Small helpers ------------------------------------------------------------

node_exists <- function(node) !inherits(node, "xml_missing")

#' Format a character vector the way pandas wrote Python lists to the raw
#' CSV, e.g. "['a', 'b']" or "[]", so old and new rows share one format and
#' data_processing.R parses both identically.
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

# Issue schedule -----------------------------------------------------------

#' Number of issues in a volume. Volumes 1-10 (2011-2020) had 4 issues,
#' volume 11 (2021) had 6, volume 12 (2022) onward is monthly.
issues_in_volume <- function(volume) {
  if (volume <= 10) 4L else if (volume == 11) 6L else 12L
}

# Issue table of contents --------------------------------------------------

#' Parse one issue's table-of-contents page into the overview columns:
#' one row per article with paperid, volume, issue, url, journal, title,
#' published_year. Returns a zero-row tibble when the page has no article
#' list (an issue that does not exist yet).
parse_issue_page <- function(html, volume, issue) {
  empty <- tibble(
    paperid = integer(), volume = integer(), issue = integer(),
    url = character(), journal = character(), title = character(),
    published_year = integer()
  )
  if (is.na(html)) return(empty)
  page <- read_html(html)
  article_list <- html_element(page, "#ArticleList")
  if (!node_exists(article_list)) return(empty)
  links <- html_elements(article_list, "a[href*='/washdev/article/']")
  # The Python scraper kept only <a> tags without a class attribute; the
  # classed ones are PDF/citation links pointing at the same articles
  links <- links[is.na(html_attr(links, "class"))]
  if (length(links) == 0) return(empty)
  tibble(
    paperid = map_chr(links, \(a) xml_attr(xml_parent(a), "data-resource-id-access")),
    volume = volume,
    issue = issue,
    url = paste0(SITE_ROOT, html_attr(links, "href")),
    journal = JOURNAL_NAME,
    title = str_trim(html_text(links)),
    published_year = volume + 2010L
  )
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
  supp_type <- if (length(supp_types) == 0) {
    NA_character_
  } else {
    paste(supp_types, collapse = " & ")
  }
  list(
    is_supp = node_exists(html_element(page, "h2#supplementary-data")),
    num_supp = length(supp_nodes),
    supp_file_type = supp_type,
    supp_url = py_list(map_chr(
      supp_nodes, \(node) html_attr(html_element(node, "a"), "href")
    ))
  )
}

#' Extract name, affiliation, country, email, and ORCID from one author
#' info card (a div.info-card-author node).
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
    aff <- str_trim(aff)
    country <- last(str_split_1(aff, ", "))
    country <- str_split_1(country, " Email")[1]
  } else {
    aff <- NA_character_
    country <- NA_character_
  }
  email_node <- html_element(card, "a[href^='mailto']")
  orcid_node <- html_element(card, "a[id^='contrib-orcid']")
  list(
    name = name,
    affiliation = aff,
    affiliation_country = country,
    email = if (node_exists(email_node)) html_text(email_node) else NA_character_,
    orcid = if (node_exists(orcid_node)) html_attr(orcid_node, "href") else NA_character_
  )
}

parse_authors <- function(page) {
  na_author <- list(
    name = NA_character_, affiliation = NA_character_,
    affiliation_country = NA_character_, email = NA_character_,
    orcid = NA_character_
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
    first_author_email = first$email,
    first_author_orcid = first$orcid,
    correspondence_author_name = corresp$name,
    correspondence_author_affiliation = corresp$affiliation,
    correspondence_author_affiliation_country = corresp$affiliation_country,
    correspondence_author_email = corresp$email,
    correspondence_author_orcid = corresp$orcid
  )
}

#' Repository URL from the DAS text, for statements that start with the
#' standard online-repository sentence. Three regexes in decreasing order
#' of strictness, as in the Python version: a URL inside parentheses, any
#' URL, anything inside parentheses.
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
    if (node_exists(body)) das_text <- str_trim(html_text(body))
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

#' Fetch and parse one article. On failure returns a one-row tibble of NAs
#' so the issue keeps its remaining articles.
scrape_article <- function(session, url) {
  tryCatch(
    parse_article_page(fetch_page(session, url)),
    error = function(e) {
      warning("Failed to parse ", url, ": ", conditionMessage(e), call. = FALSE)
      parse_article_page("<html></html>")
    }
  )
}

# Raw CSV round trip -------------------------------------------------------

read_washdev_raw <- function(path) {
  read_csv(path, show_col_types = FALSE, name_repair = "unique_quiet") |>
    rename(row_index = 1)
}

#' Write the raw table back in the format pandas produced: an unnamed
#' index as the first column.
write_washdev_raw <- function(data, path) {
  write_csv(data, path, na = "")
  lines <- read_lines(path)
  lines[1] <- sub("^row_index", "", lines[1])
  write_lines(lines, path)
}

# Main ---------------------------------------------------------------------

#' Scrape all issues newer than the ones in the raw CSV and append them.
#' `end_vol` defaults to the volume implied by the current year. For the
#' final volume, scraping stops at the first issue that has no article
#' list (not yet published).
update_washdev_raw <- function(raw_path = "data-raw/washdev.csv",
                               end_vol = as.integer(format(Sys.Date(), "%Y")) - 2010L) {
  existing <- read_washdev_raw(raw_path)
  last_vol <- max(existing$volume)
  last_issue <- max(existing$issue[existing$volume == last_vol])
  message("Raw data covers up to volume ", last_vol, " issue ", last_issue)

  session <- start_browser()
  on.exit(session$parent$close(), add = TRUE)

  for (vol in last_vol:end_vol) {
    first_issue <- if (vol == last_vol) last_issue + 1L else 1L
    for (iss in seq_len(issues_in_volume(vol))) {
      if (iss < first_issue) next
      message("Scraping volume ", vol, " issue ", iss, " ...")
      overview <- parse_issue_page(
        fetch_page(session, paste(ISSUE_ROOT, vol, iss, sep = "/")),
        volume = vol, issue = iss
      )
      if (nrow(overview) == 0) {
        message("  no articles found, stopping volume ", vol)
        break
      }
      metadata <- map(overview$url, \(u) scrape_article(session, u)) |>
        list_rbind()
      new_rows <- bind_cols(overview, metadata) |>
        mutate(
          paperid = as.integer(paperid),
          row_index = max(existing$row_index) + row_number()
        )
      existing <- bind_rows(existing, new_rows)
      write_washdev_raw(existing, raw_path)
      message("  added ", nrow(new_rows), " articles (total ", nrow(existing), ")")
    }
  }
  invisible(existing)
}

# Runs only when executed directly (Rscript data-raw/washdev_scraping.R),
# not when the file is source()d for its functions
if (sys.nframe() == 0 && !interactive()) {
  update_washdev_raw()
}
