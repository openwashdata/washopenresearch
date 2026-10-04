# What Crossref and Europe PMC carry for the four IWA journals (#90).
# Read-only exploration behind docs/adr/0002-api-routes-for-the-iwa-journals.md.
# Identified client (WASHOPENRESEARCH_CONTACT), Crossref through the polite
# pool, Europe PMC at the 10 seconds its robots.txt asks for, one PDF link
# request per journal. Writes the tables in this folder. Run from the
# package root with the pinned packages loaded:
#   Rscript data-raw/coverage-assessment/api-routes/api_routes_iwa.R
Sys.setenv(X90_OUT = "data-raw/coverage-assessment/api-routes")

# ---- Crossref: works per ISSN and year, full-text links, link resolution ----
OUT <- Sys.getenv("X90_OUT")
contact <- Sys.getenv("WASHOPENRESEARCH_CONTACT"); stopifnot(nzchar(contact))
ua <- sprintf("washopenresearch/0.5.0 (https://github.com/openwashdata/washopenresearch; %s)", contact)
get_json <- function(url, query = list(), pause = 1) {
  Sys.sleep(pause)
  request(url) |> req_url_query(!!!query) |> req_user_agent(ua) |> req_retry(max_tries = 3) |>
    req_error(is_error = function(r) FALSE) |> req_perform() -> resp
  if (resp_status(resp) != 200) return(NULL)
  resp_body_json(resp)
}
journals <- tribble(
  ~dataset, ~issn, ~note,
  "washdev", "2043-9083", "",
  "jwh",     "1477-8920", "",
  "ws",      "1606-9749", "",
  "aqua",    "2709-8028", "title since 2022",
  "aqua",    "0003-7214", "Journal of Water Supply: Research and Technology-Aqua, before 2022"
)
# Dataset rows per year
load_ds <- function(n) { e <- new.env(); load(sprintf("data/%s.rda", n), envir = e); e[[n]] }
ds <- map(set_names(c("washdev", "jwh", "ws", "aqua")), load_ds)
ds_years <- imap_dfr(ds, \(d, n) count(d, published_year, name = "dataset_rows") |> mutate(dataset = n))
# 1. Crossref works per year per ISSN (polite pool through mailto)
cat("Crossref per-year counts\n")
cr_years <- pmap_dfr(journals, function(dataset, issn, note) {
  map_dfr(1996:2026, function(y) {
    r <- get_json(sprintf("https://api.crossref.org/journals/%s/works", issn),
                  list(filter = sprintf("from-pub-date:%d-01-01,until-pub-date:%d-12-31", y, y), rows = 0, mailto = contact), pause = 0.5)
    tibble(dataset = dataset, issn = issn, published_year = y, crossref_works = if (is.null(r)) NA_integer_ else r$message$`total-results`)
  })
})
year_table <- cr_years |> left_join(ds_years, by = c("dataset", "published_year")) |> mutate(dataset_rows = coalesce(dataset_rows, 0L))
write_csv(year_table, file.path(OUT, "issn-year-counts.csv"))
# 1b. ws anomaly: container titles under 1606-9749
r <- get_json("https://api.crossref.org/journals/1606-9749/works", list(rows = 0, facet = "container-title:*", mailto = contact))
ct <- r$message$facets$`container-title`$values
write_csv(tibble(container_title = names(ct), works = unlist(ct)), file.path(OUT, "ws-container-titles.csv"))
# 2. Full-text links and licence of one 2024 work per ISSN
cat("Crossref links\n")
links <- pmap_dfr(journals, function(dataset, issn, note) {
  r <- get_json(sprintf("https://api.crossref.org/journals/%s/works", issn),
                list(filter = "from-pub-date:2024-01-01,until-pub-date:2024-12-31", rows = 2, select = "DOI,link,license,type", mailto = contact))
  items <- r$message$items
  map_dfr(items, function(it) {
    lk <- it$link %||% list(); lic <- it$license %||% list()
    tibble(dataset = dataset, issn = issn, doi = it$DOI, type = it$type %||% NA,
           n_links = length(lk),
           link_url = paste(map_chr(lk, ~ .x$URL %||% NA), collapse = " | "),
           content_type = paste(map_chr(lk, ~ .x$`content-type` %||% NA), collapse = " | "),
           intended_application = paste(map_chr(lk, ~ .x$`intended-application` %||% NA), collapse = " | "),
           content_version = paste(map_chr(lk, ~ .x$`content-version` %||% NA), collapse = " | "),
           license_url = paste(map_chr(lic, ~ .x$URL %||% NA), collapse = " | "),
           license_version = paste(map_chr(lic, ~ .x$`content-version` %||% NA), collapse = " | "))
  })
})
# has-full-text counts since 2021
hft <- pmap_dfr(journals, function(dataset, issn, note) {
  a <- get_json(sprintf("https://api.crossref.org/journals/%s/works", issn), list(filter = "from-pub-date:2021-01-01", rows = 0, mailto = contact))
  b <- get_json(sprintf("https://api.crossref.org/journals/%s/works", issn), list(filter = "from-pub-date:2021-01-01,has-full-text:true", rows = 0, mailto = contact))
  c2 <- get_json(sprintf("https://api.crossref.org/journals/%s/works", issn), list(filter = "from-pub-date:2021-01-01,full-text.application:text-mining", rows = 0, mailto = contact))
  tibble(dataset, issn, works_2021 = a$message$`total-results`, with_full_text_link = b$message$`total-results`, text_mining_link = c2$message$`total-results`)
})
write_csv(hft, file.path(OUT, "crossref-full-text-2021.csv"))
# 3. Does one full-text link resolve for the identified client (one request per ISSN, no login)
cat("link resolution\n")
res_links <- links |> filter(n_links > 0) |> group_by(issn) |> slice(1) |> ungroup() |> mutate(first_link = sub(" \\|.*$", "", link_url))
resolution <- pmap_dfr(res_links, function(...) {
  row <- list(...); Sys.sleep(8)
  resp <- tryCatch(request(row$first_link) |> req_user_agent(ua) |> req_method("GET") |> req_options(range = "0-2047") |>
                     req_error(is_error = function(r) FALSE) |> req_perform(), error = function(e) NULL)
  tibble(dataset = row$dataset, issn = row$issn, doi = row$doi, url = row$first_link,
         status = if (is.null(resp)) NA_integer_ else resp_status(resp),
         content_type = if (is.null(resp)) NA_character_ else resp_content_type(resp),
         final_url = if (is.null(resp)) NA_character_ else resp_url(resp))
})
write_csv(links, file.path(OUT, "crossref-links-2024.csv")); write_csv(resolution, file.path(OUT, "link-resolution.csv"))
# 4. Europe PMC coverage of 2021+ DOIs per dataset (search API, 10 s crawl delay honoured, 20 DOIs per query)
cat("Europe PMC coverage\n")
epmc_rows <- imap_dfr(ds, function(d, n) {
  dois <- unique(na.omit(d$doi[d$published_year >= 2021]))
  batches <- split(dois, ceiling(seq_along(dois) / 20))
  found <- map_dfr(batches, function(b) {
    q <- paste(sprintf('DOI:"%s"', b), collapse = " OR ")
    r <- get_json("https://www.ebi.ac.uk/europepmc/webservices/rest/search", list(query = q, format = "json", resultType = "lite", pageSize = 25), pause = 10)
    hits <- r$resultList$result %||% list()
    map_dfr(hits, ~ tibble(doi = tolower(.x$doi %||% NA), pmcid = .x$pmcid %||% NA, in_epmc = .x$inEPMC %||% NA, in_pmc = .x$inPMC %||% NA,
                           is_oa = .x$isOpenAccess %||% NA, has_ft = !is.null(.x$fullTextIdList)))
  })
  tibble(dataset = n, dois_2021 = length(dois), found = n_distinct(found$doi), with_pmcid = sum(!is.na(found$pmcid)),
         full_text = sum(found$has_ft), open_access = sum(found$is_oa %in% "Y")) |> mutate(sample_pmcids = list(head(found$pmcid[found$has_ft], 10)))
})
write_csv(select(epmc_rows, -sample_pmcids), file.path(OUT, "epmc-coverage-2021.csv"))
# 5. Data availability section in the full text XML of up to 10 per dataset
cat("DAS sections\n")
das_sections <- pmap_dfr(epmc_rows, function(dataset, sample_pmcids, ...) {
  map_dfr(sample_pmcids, function(id) {
    Sys.sleep(10)
    resp <- request(sprintf("https://www.ebi.ac.uk/europepmc/webservices/rest/%s/fullTextXML", id)) |> req_user_agent(ua) |>
      req_error(is_error = function(r) FALSE) |> req_perform()
    if (resp_status(resp) != 200) return(tibble(dataset, pmcid = id, status = resp_status(resp), das_section = NA, heading = NA))
    x <- read_xml(resp_body_string(resp))
    sec <- xml_find_first(x, "//sec[@sec-type='data-availability']")
    heading <- xml_find_first(x, "//sec[title[contains(translate(., 'DATA', 'data'), 'data availab') or contains(translate(., 'AVAILABILITY', 'availability'), 'availability of data')]]/title")
    tibble(dataset, pmcid = id, status = 200L,
           das_section = !inherits(sec, "xml_missing") || !inherits(heading, "xml_missing"),
           heading = if (!inherits(heading, "xml_missing")) xml_text(heading) else if (!inherits(sec, "xml_missing")) "sec-type data-availability" else NA)
  })
})
write_csv(das_sections, file.path(OUT, "epmc-das-sections.csv"))
cat("done\n")

# ---- Europe PMC: coverage by ISSN and year, and the statement section ----
OUT <- Sys.getenv("X90_OUT"); contact <- Sys.getenv("WASHOPENRESEARCH_CONTACT"); stopifnot(nzchar(contact))
ua <- sprintf("washopenresearch/0.5.0 (https://github.com/openwashdata/washopenresearch; %s)", contact)
epmc <- function(q, pageSize = 1) {
  Sys.sleep(10)
  request("https://www.ebi.ac.uk/europepmc/webservices/rest/search") |>
    req_url_query(query = q, format = "json", resultType = "lite", pageSize = pageSize) |>
    req_user_agent(ua) |> req_retry(max_tries = 3) |> req_perform() |> resp_body_json()
}
journals <- tribble(~dataset, ~issn, "washdev", "2043-9083", "jwh", "1477-8920", "ws", "1606-9749", "aqua", "2709-8028", "aqua_old", "0003-7214")
cat("coverage by ISSN and year\n")
cov <- pmap_dfr(journals, function(dataset, issn) {
  map_dfr(2021:2026, function(y) {
    base <- sprintf("ISSN:%s AND PUB_YEAR:%d", issn, y)
    tibble(dataset, issn, year = y,
           records = epmc(base)$hitCount,
           full_text = epmc(paste(base, "AND HAS_FT:Y"))$hitCount,
           open_access = epmc(paste(base, "AND OPEN_ACCESS:Y"))$hitCount)
  })
})
write_csv(cov, file.path(OUT, "epmc-coverage-by-issn-year.csv")); print(as.data.frame(cov))
cat("DAS sections in open access full texts\n")
das <- pmap_dfr(journals, function(dataset, issn) {
  r <- epmc(sprintf("ISSN:%s AND PUB_YEAR:[2021 TO 2026] AND OPEN_ACCESS:Y", issn), pageSize = 10)
  hits <- r$resultList$result
  if (length(hits) == 0) return(tibble(dataset = dataset, pmcid = NA_character_, status = NA_integer_, das_section = NA, heading = NA_character_))
  map_dfr(hits, function(h) {
    id <- h$pmcid; if (is.null(id)) return(NULL)
    Sys.sleep(10)
    resp <- request(sprintf("https://www.ebi.ac.uk/europepmc/webservices/rest/%s/fullTextXML", id)) |> req_user_agent(ua) |>
      req_error(is_error = function(r) FALSE) |> req_perform()
    if (resp_status(resp) != 200) return(tibble(dataset, pmcid = id, status = resp_status(resp), das_section = NA, heading = NA_character_))
    x <- read_xml(resp_body_string(resp))
    sec <- xml_find_first(x, "//sec[@sec-type='data-availability']")
    heading <- xml_find_first(x, "//sec/title[contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'data availab') or contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'availability of data')]")
    has_sec <- !inherits(sec, "xml_missing"); has_heading <- !inherits(heading, "xml_missing")
    tibble(dataset, pmcid = id, status = 200L, das_section = has_sec || has_heading,
           heading = if (has_heading) xml_text(heading) else if (has_sec) "sec-type data-availability" else NA_character_)
  })
})
write_csv(das, file.path(OUT, "epmc-das-sections.csv")); print(as.data.frame(das)); cat("done\n")
