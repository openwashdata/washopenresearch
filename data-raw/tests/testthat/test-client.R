# The identification string, the robots.txt rules and the credential scan
# of data-raw/client.R. No network: the robots.txt texts are fixtures,
# shortened from the files of iwaponline.com and journals.plos.org.

IWA_ROBOTS <- "
User-agent: 008
Disallow: /

User-agent: *
Disallow: /bin/
Disallow: /DownloadFile/
Disallow: /store/*
Allow: /cassette.axd/stylesheet/
Disallow: /*.axd
Disallow: /sign-in?*
Sitemap: https://example.org/sitemap.xml
"

PLOS_ROBOTS <- "User-agent: *\nCrawl-delay: 30\n\nDisallow: */search\nDisallow: */article/metrics\n"

test_that("the user agent names the project, the version and the contact", {
  expect_equal(
    client_user_agent("someone@example.org", "0.5.0"),
    "washopenresearch/0.5.0 (https://github.com/openwashdata/washopenresearch; someone@example.org)"
  )
})

# The scripts run from the package root; the tests run from this directory
package_root <- function() withr::local_dir("../../..", .local_envir = parent.frame())

test_that("the version comes from DESCRIPTION", {
  package_root()
  expect_match(package_version_string(), "^[0-9]+([.][0-9]+)+$")
})

test_that("nothing identifies without a contact address", {
  package_root()
  withr::local_envvar(WASHOPENRESEARCH_CONTACT = "")
  expect_error(client_contact(), "WASHOPENRESEARCH_CONTACT")
  expect_error(client_user_agent(), "WASHOPENRESEARCH_CONTACT")
})

test_that("the contact comes from the environment", {
  package_root()
  withr::local_envvar(WASHOPENRESEARCH_CONTACT = "role@example.org")
  expect_equal(client_contact(), "role@example.org")
  expect_match(client_user_agent(), "; role@example.org\\)$")
})

test_that("the identifying user agent is what a request sends", {
  req <- httr2::request("https://example.org/") |>
    httr2::req_user_agent(client_user_agent("someone@example.org", "0.5.0"))
  expect_equal(
    req$options$useragent,
    "washopenresearch/0.5.0 (https://github.com/openwashdata/washopenresearch; someone@example.org)"
  )
})

test_that("robots.txt groups, rules and the crawl delay are parsed", {
  groups <- parse_robots(IWA_ROBOTS)
  expect_length(groups, 2)
  expect_equal(groups[[1]]$agents, "008")
  expect_equal(groups[[2]]$agents, "*")
  expect_length(groups[[2]]$rules, 6)
  expect_true(is.na(groups[[2]]$crawl_delay))
  expect_equal(robots_crawl_delay(parse_robots(PLOS_ROBOTS)), 30)
  expect_true(is.na(robots_crawl_delay(groups)))
  expect_length(parse_robots(""), 0)
})

test_that("the client's block is the named one, else the * block", {
  groups <- parse_robots(IWA_ROBOTS)
  expect_equal(robots_group(groups, "008")$agents, "008")
  expect_equal(robots_group(groups)$agents, "*")
  expect_null(robots_group(parse_robots(""), "washopenresearch"))
  two <- parse_robots("User-agent: a\nUser-agent: b\nDisallow: /x\n")
  expect_equal(two[[1]]$agents, c("a", "b"))
})

test_that("prefix, wildcard and anchored rules decide as a crawler would", {
  groups <- parse_robots(IWA_ROBOTS)
  expect_true(robots_allows(groups, "/washdev/issue/1/1"))
  expect_true(robots_allows(groups, "/washdev/article/1/1/1/28742/Editorial"))
  expect_false(robots_allows(groups, "/DownloadFile/123"))
  expect_false(robots_allows(groups, "/store/anything"))
  expect_false(robots_allows(groups, "/x/y.axd"))
  # the longer Allow wins over the shorter wildcard Disallow
  expect_true(robots_allows(groups, "/cassette.axd/stylesheet/site.css"))
  expect_false(robots_allows(groups, "/sign-in?returnurl=x"))
  expect_false(robots_allows(groups, "/washdev/issue", agent = "008"))
  anchored <- parse_robots("User-agent: *\nDisallow: /a$\n")
  expect_false(robots_allows(anchored, "/a"))
  expect_true(robots_allows(anchored, "/ab"))
  plos <- parse_robots(PLOS_ROBOTS)
  expect_false(robots_allows(plos, "/water/search"))
  expect_true(robots_allows(plos, "/water/article/file"))
  expect_true(robots_allows(parse_robots(""), "/anything"))
})

test_that("a disallowed path stops the run with the rule quoted", {
  groups <- parse_robots(IWA_ROBOTS)
  expect_error(
    host_policy("example.org", c("/ok", "/DownloadFile/1"), groups = groups),
    "Disallow: /DownloadFile/"
  )
  expect_message(policy <- host_policy("example.org", "/ok", groups = groups), "1 path allowed")
  expect_equal(policy$pause, 1)
  expect_message(
    plos <- host_policy("example.org", "/water/article/file", groups = parse_robots(PLOS_ROBOTS)),
    "Crawl-delay 30"
  )
  expect_equal(plos$pause, 30)
  expect_equal(host_policy("example.org", "/x", default_pause = 2, groups = list())$pause, 2)
})

test_that("no script carries an address or a credential", {
  package_root()
  files <- list.files("data-raw", pattern = "[.]R$", recursive = TRUE, full.names = TRUE)
  expect_gt(length(files), 20)
  files <- files[!grepl("^data-raw/tests/", files)]
  address <- "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
  credential <- "(?i)(api_?key|token|secret|password)\\s*(=|<-)\\s*[\"'][^\"']{8,}[\"']"
  hits <- unlist(lapply(files, function(file) {
    lines <- readLines(file, warn = FALSE)
    found <- grepl(address, lines, perl = TRUE) | grepl(credential, lines, perl = TRUE)
    if (any(found)) paste0(file, ":", which(found)) else character()
  }))
  expect_length(hits, 0)
})
