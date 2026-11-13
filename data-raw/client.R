# Identification, pacing and robots.txt for every client this package runs.
#
# Every request names the project, the package version and a contact
# address, so that a site can reach the maintainer instead of blocking the
# client. The address comes from the environment (WASHOPENRESEARCH_CONTACT),
# never from the repository, and nothing is fetched without it.
#
# Before a run, the robots.txt of each host is read once. A path the file
# disallows for this client stops the run with the rule quoted, and a
# Crawl-delay the file sets becomes the minimum pause between requests to
# that host. A host without a robots.txt has no rules.
#
# Sourced by the scrapers (data-raw/iwa_scraping.R, data-raw/ploswater.R),
# the update command and the scripts that call Crossref, Europe PMC and
# OpenAlex. The functions are tested without network in data-raw/tests/.

CONTACT_VAR <- "WASHOPENRESEARCH_CONTACT"
PROJECT_URL <- "https://github.com/openwashdata/washopenresearch"
CLIENT_NAME <- "washopenresearch"

# The package version, from DESCRIPTION at the package root.
package_version_string <- function(description = "DESCRIPTION") {
  unname(read.dcf(description, fields = "Version")[1, "Version"])
}

# The contact address from the environment. Stops with a clear message when
# it is unset: a request without a contact is not sent.
client_contact <- function() {
  contact <- Sys.getenv(CONTACT_VAR)
  if (!nzchar(contact)) {
    stop(
      "Set ", CONTACT_VAR, " to the address that every request identifies ",
      "(for example in ~/.Renviron). Nothing is fetched without it.",
      call. = FALSE
    )
  }
  contact
}

# "washopenresearch/<version> (<project url>; <contact>)"
client_user_agent <- function(contact = client_contact(),
                              version = package_version_string()) {
  sprintf("%s/%s (%s; %s)", CLIENT_NAME, version, PROJECT_URL, contact)
}

# robots.txt ---------------------------------------------------------------

# Parse the text of a robots.txt into groups, one per User-agent block:
# the agent tokens, the Allow and Disallow rules in file order, and the
# Crawl-delay when the block sets one. Comments and unknown fields are
# ignored. Consecutive User-agent lines share one block.
parse_robots <- function(text) {
  lines <- strsplit(paste(text, collapse = "\n"), "\n", fixed = TRUE)[[1]]
  lines <- trimws(sub("#.*$", "", lines))
  lines <- lines[nzchar(lines)]
  groups <- list()
  current <- NULL
  after_agent <- FALSE
  for (line in lines) {
    parts <- regmatches(line, regexec("^([A-Za-z-]+)\\s*:\\s*(.*)$", line))[[1]]
    if (length(parts) == 0) next
    field <- tolower(parts[2])
    value <- trimws(parts[3])
    if (field == "user-agent") {
      if (after_agent && !is.null(current)) {
        current$agents <- c(current$agents, tolower(value))
      } else {
        if (!is.null(current)) groups[[length(groups) + 1]] <- current
        current <- list(agents = tolower(value), rules = list(), crawl_delay = NA_real_)
      }
      after_agent <- TRUE
    } else if (field %in% c("allow", "disallow")) {
      after_agent <- FALSE
      if (is.null(current) || !nzchar(value)) next
      current$rules[[length(current$rules) + 1]] <-
        list(allow = identical(field, "allow"), path = value)
    } else if (field == "crawl-delay") {
      after_agent <- FALSE
      if (is.null(current)) next
      current$crawl_delay <- suppressWarnings(as.numeric(value))
    }
  }
  if (!is.null(current)) groups[[length(groups) + 1]] <- current
  groups
}

# The block that applies to this client: the block whose agent token is
# part of the client token (case-insensitive), else the "*" block, else none.
robots_group <- function(groups, agent = CLIENT_NAME) {
  token <- tolower(agent)
  for (g in groups) {
    named <- setdiff(g$agents, "*")
    if (any(vapply(named, function(a) grepl(a, token, fixed = TRUE), logical(1)))) {
      return(g)
    }
  }
  for (g in groups) if ("*" %in% g$agents) return(g)
  NULL
}

# A robots path pattern as a regular expression anchored at the start:
# "*" matches anything, a trailing "$" anchors the end, the rest is literal.
robots_pattern <- function(path) {
  anchored <- endsWith(path, "$")
  if (anchored) path <- substr(path, 1, nchar(path) - 1)
  pieces <- strsplit(path, "*", fixed = TRUE)[[1]]
  if (length(pieces) == 0) pieces <- ""
  # Every character that is not a word character or a slash is taken
  # literally (a backslash before it is always safe in a perl pattern)
  escaped <- vapply(
    pieces,
    function(p) gsub("([^A-Za-z0-9_/])", "\\\\\\1", p, perl = TRUE),
    character(1)
  )
  paste0("^", paste(escaped, collapse = ".*"), if (anchored) "$" else "")
}

# The decision for one path: the longest matching rule wins, and Allow wins
# when an Allow and a Disallow of the same length match. No matching rule,
# no block for the client, or no robots.txt means allowed. Returns the
# decision and the rule it rests on (NULL when no rule matched).
robots_decision <- function(groups, path, agent = CLIENT_NAME) {
  g <- robots_group(groups, agent)
  if (is.null(g) || length(g$rules) == 0) {
    return(list(allowed = TRUE, rule = NULL, agents = g$agents))
  }
  matched <- Filter(function(r) grepl(robots_pattern(r$path), path, perl = TRUE), g$rules)
  if (length(matched) == 0) return(list(allowed = TRUE, rule = NULL, agents = g$agents))
  lengths <- vapply(matched, function(r) nchar(r$path), integer(1))
  best <- matched[lengths == max(lengths)]
  allows <- vapply(best, function(r) r$allow, logical(1))
  rule <- if (any(allows)) best[[which(allows)[1]]] else best[[1]]
  list(allowed = any(allows), rule = rule, agents = g$agents)
}

robots_allows <- function(groups, path, agent = CLIENT_NAME) {
  robots_decision(groups, path, agent)$allowed
}

# The Crawl-delay of the client's block, in seconds, or NA when none is set.
robots_crawl_delay <- function(groups, agent = CLIENT_NAME) {
  g <- robots_group(groups, agent)
  if (is.null(g)) NA_real_ else g$crawl_delay
}

# The robots.txt of a host, fetched once with the identifying user agent and
# parsed. A missing file, or anything that is not text, means no rules.
fetch_robots <- function(host, user_agent = client_user_agent()) {
  resp <- httr2::request(paste0("https://", host, "/robots.txt")) |>
    httr2::req_user_agent(user_agent) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()
  is_text <- grepl("text/plain", httr2::resp_content_type(resp), fixed = TRUE)
  text <- if (httr2::resp_status(resp) == 200 && is_text) httr2::resp_body_string(resp) else ""
  parse_robots(text)
}

# The access policy of one host for this run. Checks every path the run
# will visit before the first request: a disallowed path stops the run with
# the rule quoted. Prints the result. Returns the host, its parsed robots
# groups and the pause in seconds between requests to it: the Crawl-delay
# when the file sets one and it is longer than `default_pause`.
host_policy <- function(host, paths, default_pause = 1, agent = CLIENT_NAME,
                        groups = fetch_robots(host)) {
  for (path in paths) {
    decision <- robots_decision(groups, path, agent)
    if (!decision$allowed) {
      stop(
        "robots.txt of ", host, " disallows ", path, " for \"",
        paste(decision$agents, collapse = ", "), "\" (rule: Disallow: ",
        decision$rule$path, "). The run stops before any page is fetched.",
        call. = FALSE
      )
    }
  }
  delay <- robots_crawl_delay(groups, agent)
  pause <- max(default_pause, delay, na.rm = TRUE)
  message(
    "robots.txt of ", host, ": ", length(paths), " path",
    if (length(paths) != 1) "s", " allowed",
    if (!is.na(delay)) paste0(", Crawl-delay ", delay, "s"), "; pause ",
    pause, "s between requests"
  )
  list(host = host, groups = groups, pause = pause)
}

# Wait before the next request to a host, as its policy says.
pause_for <- function(policy) Sys.sleep(policy$pause)
