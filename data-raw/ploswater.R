# Download article metadata for PLOS Water (issue #14).
#
# No scraping required: the PLOS search API (https://api.plos.org/search,
# Solr syntax) lists every article with volume, issue, dates, authors, and
# subject terms, and each article's full JATS XML is served at
# https://journals.plos.org/water/article/file?id=<DOI>&type=manuscript.
# The XML carries the data availability statement, supplementary material
# entries, affiliations, ORCIDs, and the correspondence author.
#
# Notes:
# - PLOS Water has no author keywords in the XML for most articles; the
#   `keywords` column holds the API's subject terms instead.
# - Data availability statements are mandatory at PLOS, so `has_das` is
#   expected to be TRUE almost everywhere.
# - Multi-value columns are "; "-delimited, matching the format of the
#   published datasets (no list-columns, see #8).
# - All article types are downloaded; `article_type` lets the processing
#   step decide which to keep (opinion pieces rarely have data).
# - Fair use of the API: stay under 300 requests/hour. A full run needs
#   about 5 search requests plus one XML request per article (~440), with
#   a one second pause between article downloads. The XML files come from
#   the journal site, not the API, but the same politeness applies.
#
# Run from the package root:
#   Rscript data-raw/ploswater.R

library(httr2)
library(xml2)
library(dplyr)
library(purrr)
library(stringr)
library(readr)
library(tibble)

SEARCH_URL <- "https://api.plos.org/search"
ARTICLE_XML_URL <- "https://journals.plos.org/water/article/file?id=%s&type=manuscript"
ARTICLE_URL <- "https://journals.plos.org/water/article?id=%s"
JOURNAL_NAME <- "PLOS Water"

# Known data repositories, used to label where DAS-linked data lives
REPO_PATTERNS <- c(
  "zenodo"          = "zenodo\\.org|10\\.5281/zenodo",
  "dryad"           = "datadryad|10\\.5061/dryad",
  "figshare"        = "figshare|10\\.6084/m9\\.figshare",
  "osf"             = "osf\\.io|10\\.17605/osf",
  "github"          = "github\\.com",
  "dataverse"       = "dataverse|10\\.7910/DVN",
  "mendeley data"   = "data\\.mendeley|10\\.17632/",
  "openicpsr/icpsr" = "icpsr",
  "dhs program"     = "dhsprogram\\.com",
  "world bank"      = "microdata\\.worldbank|data\\.worldbank",
  "ncbi/genbank"    = "ncbi\\.nlm\\.nih\\.gov|genbank",
  "pangaea"         = "pangaea\\.de",
  "hydroshare"      = "hydroshare\\.org"
)

# Search API ---------------------------------------------------------------

#' All PLOS Water articles from the search API, one row per article, with
#' the fields needed for the overview columns.
fetch_article_list <- function(rows_per_page = 100) {
  fields <- paste(
    c("id", "title_display", "volume", "issue", "publication_date",
      "author_display", "article_type", "subject"),
    collapse = ","
  )
  start <- 0
  docs <- list()
  repeat {
    resp <- request(SEARCH_URL) |>
      req_url_query(
        q = 'journal:"PLOS Water" AND doc_type:full',
        fl = fields,
        wt = "json",
        rows = rows_per_page,
        start = start
      ) |>
      req_user_agent("washopenresearch data package (openwashdata.org)") |>
      req_perform() |>
      resp_body_json()
    docs <- c(docs, resp$response$docs)
    start <- start + rows_per_page
    if (start >= resp$response$numFound) break
    Sys.sleep(1)
  }
  message("Search API returned ", length(docs), " articles")
  map(docs, function(d) {
    tibble(
      doi = d$id,
      volume = d$volume %||% NA_integer_,
      issue = d$issue %||% NA_integer_,
      paper_url = sprintf(ARTICLE_URL, d$id),
      journal = JOURNAL_NAME,
      title = d$title_display %||% NA_character_,
      publication_date = str_sub(d$publication_date %||% NA_character_, 1, 10),
      published_year = as.integer(str_sub(d$publication_date, 1, 4)),
      article_type = d$article_type %||% NA_character_,
      keywords = paste(unique(unlist(d$subject)), collapse = "; ")
    )
  }) |> list_rbind()
}

# Article XML --------------------------------------------------------------

fetch_article_xml <- function(doi) {
  request(sprintf(ARTICLE_XML_URL, doi)) |>
    req_user_agent("washopenresearch data package (openwashdata.org)") |>
    req_retry(max_tries = 3) |>
    req_perform() |>
    resp_body_string() |>
    read_xml()
}

#' Extract file type markers like "(DOCX)" from a supplementary-material
#' caption; fall back to the mimetype attribute when absent.
supp_file_type <- function(node) {
  marker <- xml_text(xml_find_all(node, ".//caption//p"))
  marker <- str_match(paste(marker, collapse = " "), "\\(([A-Za-z0-9]+)\\)")[, 2]
  if (!is.na(marker)) return(str_to_lower(marker))
  mimetype <- xml_attr(node, "mimetype")
  if (is.na(mimetype)) NA_character_ else basename(mimetype)
}

parse_supp <- function(xml) {
  nodes <- xml_find_all(xml, "//supplementary-material")
  hrefs <- xml_attr(nodes, "href")
  # xlink:href="info:doi/10.1371/journal.pwat.NNNNNNN.sNNN"; the stable
  # download URL is the article-file endpoint with type=supplementary
  supp_doi <- str_remove(hrefs, "^info:doi/")
  supp_url <- sprintf(
    "https://journals.plos.org/water/article/file?id=%s&type=supplementary",
    supp_doi
  )
  list(
    is_supp = length(nodes) > 0,
    num_supp = length(nodes),
    supp_file_type = if (length(nodes) == 0) NA_character_ else
      paste(map_chr(nodes, supp_file_type), collapse = "; "),
    supp_url = if (length(nodes) == 0) NA_character_ else
      paste(supp_url, collapse = "; ")
  )
}

#' Affiliation text for a contrib node, resolved through its aff xref.
contrib_affiliation <- function(xml, contrib) {
  rid <- xml_attr(xml_find_first(contrib, ".//xref[@ref-type='aff']"), "rid")
  if (is.na(rid)) return(NA_character_)
  aff <- xml_find_first(xml, sprintf("//aff[@id='%s']", rid))
  addr <- xml_find_first(aff, ".//addr-line")
  txt <- if (!inherits(addr, "xml_missing")) xml_text(addr) else xml_text(aff)
  str_trim(str_remove(txt, "^[0-9]+\\s*"))
}

contrib_fields <- function(xml, contrib) {
  if (is.null(contrib) || inherits(contrib, "xml_missing")) {
    return(list(
      name = NA_character_, affiliation = NA_character_,
      affiliation_country = NA_character_, orcid = NA_character_
    ))
  }
  given <- xml_text(xml_find_first(contrib, ".//name/given-names"))
  surname <- xml_text(xml_find_first(contrib, ".//name/surname"))
  name <- str_trim(paste(given, surname))
  aff <- contrib_affiliation(xml, contrib)
  country <- if (is.na(aff)) NA_character_ else last(str_split_1(aff, ",\\s*"))
  orcid <- xml_text(xml_find_first(
    contrib, ".//contrib-id[@contrib-id-type='orcid']"
  ))
  list(
    name = name, affiliation = aff,
    affiliation_country = str_trim(country), orcid = orcid
  )
}

parse_authors <- function(xml) {
  contribs <- xml_find_all(
    xml, "//contrib-group/contrib[@contrib-type='author']"
  )
  first <- contrib_fields(
    xml, if (length(contribs) > 0) contribs[[1]] else NULL
  )
  corresp_node <- xml_find_first(
    xml, "//contrib-group/contrib[@contrib-type='author'][@corresp='yes']"
  )
  corresp <- contrib_fields(xml, corresp_node)
  corresp_email <- xml_text(xml_find_first(
    xml, "//author-notes/corresp/email"
  ))
  first_is_corresp <- length(contribs) > 0 &&
    identical(xml_attr(contribs[[1]], "corresp"), "yes")
  list(
    num_authors = length(contribs),
    first_author_name = first$name,
    first_author_affiliation = first$affiliation,
    first_author_affiliation_country = first$affiliation_country,
    # PLOS XML only publishes the correspondence author's email
    first_author_email = if (first_is_corresp) corresp_email else NA_character_,
    first_author_orcid = first$orcid,
    correspondence_author_name = corresp$name,
    correspondence_author_affiliation = corresp$affiliation,
    correspondence_author_affiliation_country = corresp$affiliation_country,
    correspondence_author_email = corresp_email,
    correspondence_author_orcid = corresp$orcid
  )
}

#' URLs and dataset DOIs mentioned in a data availability statement,
#' plus the names of recognized repositories they point to.
das_repositories <- function(das_node, das_text) {
  urls <- character()
  if (!inherits(das_node, "xml_missing")) {
    urls <- xml_attr(xml_find_all(das_node, ".//ext-link"), "href")
  }
  urls <- c(
    urls,
    str_extract_all(das_text, "https?://[^\\s,;)]+")[[1]],
    str_extract_all(das_text, "\\b10\\.\\d{4,}/[^\\s,;)]+")[[1]]
  )
  urls <- unique(str_remove(urls, "[.)]$"))
  repo_names <- names(REPO_PATTERNS)[map_lgl(
    REPO_PATTERNS,
    \(p) any(str_detect(str_to_lower(c(urls, das_text)), p))
  )]
  list(
    das_repo_url = if (length(urls) == 0) NA_character_ else
      paste(urls, collapse = "; "),
    das_repo_name = if (length(repo_names) == 0) NA_character_ else
      paste(repo_names, collapse = "; ")
  )
}

parse_das <- function(xml) {
  node <- xml_find_first(xml, "//custom-meta[@id='data-availability']/meta-value")
  das_text <- if (inherits(node, "xml_missing")) NA_character_ else
    str_squish(xml_text(node))
  c(
    list(has_das = !is.na(das_text), das = das_text),
    das_repositories(node, if (is.na(das_text)) "" else das_text)
  )
}

parse_article_xml <- function(xml) {
  as_tibble(c(parse_supp(xml), parse_authors(xml), parse_das(xml)))
}

# Main ---------------------------------------------------------------------

#' Download everything and write data-raw/ploswater.csv. Skips articles
#' already present in the CSV, so an interrupted run resumes where it
#' stopped. The CSV is checkpointed every 25 articles.
download_ploswater <- function(raw_path = "data-raw/ploswater.csv") {
  overview <- fetch_article_list()
  done <- if (file.exists(raw_path)) {
    read_csv(raw_path, show_col_types = FALSE)
  } else {
    NULL
  }
  todo <- overview |> filter(!doi %in% done$doi)
  message(nrow(todo), " articles to download, ", nrow(overview) - nrow(todo),
          " already present")
  results <- if (is.null(done)) list() else list(done)
  batch <- list()
  for (i in seq_len(nrow(todo))) {
    row <- todo[i, ]
    metadata <- tryCatch(
      parse_article_xml(fetch_article_xml(row$doi)),
      error = function(e) {
        warning("Failed for ", row$doi, ": ", conditionMessage(e), call. = FALSE)
        NULL
      }
    )
    if (!is.null(metadata)) batch <- c(batch, list(bind_cols(row, metadata)))
    if (i %% 25 == 0 || i == nrow(todo)) {
      results <- c(results, batch)
      batch <- list()
      write_csv(list_rbind(results), raw_path, na = "")
      message("  ", i, "/", nrow(todo), " articles done")
    }
    Sys.sleep(1)
  }
  invisible(list_rbind(results))
}

if (sys.nframe() == 0 && !interactive()) {
  download_ploswater()
}
