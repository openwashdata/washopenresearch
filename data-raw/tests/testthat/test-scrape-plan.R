# What a run of the IWA scraper fetches is decided by pure functions
# (data-raw/scrape_plan.R), tested here without network.

# A journal with two volumes; `issues` are "volume/issue" strings.
manifest_of <- function(issues) {
  parts <- strsplit(issues, "/")
  volume <- as.integer(vapply(parts, `[[`, character(1), 1))
  tibble::tibble(
    volume = volume,
    issue = vapply(parts, `[[`, character(1), 2),
    url = paste0("https://iwaponline.com/ws/issue/", issues),
    published_year = 2000L + volume
  )
}

# A raw snapshot with `articles` articles in each of `issues`, read as text
# like the scraper reads it.
snapshot_of <- function(issues, articles = 2L) {
  parts <- strsplit(rep(issues, each = articles), "/")
  tibble::tibble(
    paperid = as.character(seq_along(parts)),
    volume = vapply(parts, `[[`, character(1), 1),
    issue = vapply(parts, `[[`, character(1), 2)
  )
}

plan_summary <- function(plan) stats::setNames(plan$action, plan$key)

test_that("with nothing new, only the two most recent issues are re-read", {
  issues <- c("1/1", "1/2", "2/1", "2/2")
  plan <- plan_scrape(manifest_of(issues), snapshot_of(issues))
  expect_identical(plan_summary(plan), c("2/1" = "recheck", "2/2" = "recheck"))
})

test_that("a new journal issue is scraped", {
  plan <- plan_scrape(
    manifest_of(c("1/1", "1/2", "2/1", "2/2")),
    snapshot_of(c("1/1", "1/2", "2/1"))
  )
  expect_identical(
    plan_summary(plan),
    c("1/2" = "recheck", "2/1" = "recheck", "2/2" = "scrape")
  )
})

test_that("an issue in the manifest but missing from the snapshot is scraped", {
  # Water Supply volume 3 issue 4 was lost to a browser crash in the first run
  plan <- plan_scrape(
    manifest_of(c("3/3", "3/4", "3/5-6", "4/1")),
    snapshot_of(c("3/3", "3/5-6", "4/1"))
  )
  expect_identical(
    plan_summary(plan),
    c("3/4" = "scrape", "3/5-6" = "recheck", "4/1" = "recheck")
  )
})

test_that("an issue logged as empty is not planned again", {
  plan <- plan_scrape(
    manifest_of(c("1/1", "1/S1", "2/1")),
    snapshot_of(c("1/1", "2/1")),
    empty_keys = "1/S1"
  )
  expect_identical(plan_summary(plan), c("1/1" = "recheck", "2/1" = "recheck"))
})

test_that("issues are planned in publication order, whatever the manifest order", {
  plan <- plan_scrape(
    manifest_of(c("2/10", "2/2", "1/S1", "1/1", "2/1")),
    snapshot_of(c("1/1", "2/1", "2/2"))
  )
  expect_identical(plan$key, c("1/S1", "2/1", "2/2", "2/10"))
  expect_identical(plan$action, c("scrape", "recheck", "recheck", "scrape"))
})

test_that("`only` visits exactly the named issues", {
  plan <- plan_scrape(
    manifest_of(c("1/1", "1/2", "2/1", "2/2")),
    snapshot_of(c("1/1", "2/1", "2/2")),
    empty_keys = "1/2",
    only = c("1/1", "1/2")
  )
  expect_identical(plan_summary(plan), c("1/1" = "recheck", "1/2" = "scrape"))
})

test_that("a first run without a snapshot scrapes every issue", {
  expect_identical(
    plan_summary(plan_scrape(manifest_of(c("1/1", "1/2")), NULL)),
    c("1/1" = "scrape", "1/2" = "scrape")
  )

  no_snapshot <- snapshot_of(character())
  plan <- plan_scrape(manifest_of(c("1/1", "1/2")), no_snapshot)
  expect_identical(plan_summary(plan), c("1/1" = "scrape", "1/2" = "scrape"))
})

test_that("only articles not yet in the snapshot are fetched", {
  overview <- tibble::tibble(paperid = c("11", "12", "13"), title = c("a", "b", "c"))
  snapshot <- tibble::tibble(paperid = c("11", "12", "99"))
  # A late article in a recent issue
  expect_identical(new_articles(overview, snapshot)$paperid, "13")
  # Nothing new
  expect_identical(nrow(new_articles(overview[1:2, ], snapshot)), 0L)
  # First run
  expect_identical(new_articles(overview, NULL), overview)
})

test_that("an empty issue is final only two years after its volume", {
  manifest <- manifest_of(c("1/1", "1/S1", "2/1", "2/12", "3/1"))
  # A supplement issue of an old volume that never had articles online
  expect_true(empty_is_final(2001L, manifest))
  # An issue of the current volume that the site lists before its articles
  expect_false(empty_is_final(2003L, manifest))
  # At the turn of the year the last issue of the previous volume can still
  # be empty when the new volume is already listed
  expect_false(empty_is_final(2002L, manifest))
})

test_that("supplement issues do not take the place of a recent issue", {
  # A supplement issue sorts after the numbered issues of its volume. It
  # would be re-read for the rest of the year in place of a regular issue.
  issues <- c("2/4", "2/5", "2/6", "2/S1")
  plan <- plan_scrape(manifest_of(issues), snapshot_of(issues))
  expect_identical(plan_summary(plan), c("2/5" = "recheck", "2/6" = "recheck"))
})

test_that("a refreshed issue list is merged into the cached manifest", {
  cached <- manifest_of(c("1/1", "1/2", "2/1"))
  discovered <- manifest_of(c("2/1", "2/2", "3/1"))
  discovered$url[1] <- "https://iwaponline.com/ws/issue/2/1-moved"
  merged <- merge_manifest(cached, discovered)
  expect_identical(
    issue_key(merged$volume, merged$issue),
    c("1/1", "1/2", "2/1", "2/2", "3/1")
  )
  # The site's current address wins over the cached one
  expect_identical(merged$url[3], "https://iwaponline.com/ws/issue/2/1-moved")
  expect_identical(names(merged), names(cached))
})

test_that("an issue list that failed to load holds the manifest back", {
  cached <- manifest_of(c("1/1", "1/2", "2/1"))
  # The list of 2002 (volume 2) did not load, the list of 2003 did. Taking
  # volume 3 in would move the refresh past 2002, and its new issues would
  # never be asked for again.
  merged <- merge_manifest(cached, manifest_of("3/1"), failed_years = 2002L)
  expect_identical(issue_key(merged$volume, merged$issue), c("1/1", "1/2", "2/1"))
  # Issues up to the failed year still come in
  merged <- merge_manifest(cached, manifest_of(c("2/2", "3/1")), failed_years = 2002L)
  expect_identical(issue_key(merged$volume, merged$issue), c("1/1", "1/2", "2/1", "2/2"))
  # A first run keeps nothing later than the failed year either
  merged <- merge_manifest(NULL, manifest_of(c("1/1", "3/1")), failed_years = 2002L)
  expect_identical(issue_key(merged$volume, merged$issue), "1/1")
})

test_that("the issue list is enumerated from the newest known year", {
  expect_identical(refresh_from_year(manifest_of(c("1/1", "2/1", "3/1")), NA), 2003L)
  expect_identical(refresh_from_year(manifest_of(c("1/1", "2/1")), 1996L), 2002L)
  # No cached manifest: the journal's configured start, or everything
  expect_identical(refresh_from_year(NULL, 1996L), 1996L)
  expect_identical(refresh_from_year(NULL, NA), NA_integer_)
  expect_identical(refresh_from_year(manifest_of(character()), NA), NA_integer_)
})

test_that("a manifest is derived from a raw snapshot", {
  snapshot <- snapshot_of(c("1/1", "1/2", "2/1"))
  snapshot$published_year <- as.character(2010L + as.integer(snapshot$volume))
  manifest <- manifest_from_snapshot(snapshot, "washdev", "https://iwaponline.com")
  expect_identical(manifest, tibble::tibble(
    volume = c(1L, 1L, 2L),
    issue = c("1", "2", "1"),
    url = paste0("https://iwaponline.com/washdev/issue/", c("1/1", "1/2", "2/1")),
    published_year = c(2011L, 2011L, 2012L)
  ))
})

test_that("new rows are written like the rows already in the snapshot", {
  rows <- tibble::tibble(
    paperid = "7", volume = 2L, is_supp = TRUE, num_supp = 0L,
    published_year = 2026, das = NA_character_
  )
  expect_identical(
    as_snapshot_text(rows),
    tibble::tibble(
      paperid = "7", volume = "2", is_supp = "TRUE", num_supp = "0",
      published_year = "2026", das = NA_character_
    )
  )
})

test_that("the raw snapshots survive being read and written back unchanged", {
  # The scraper reads a snapshot as text and writes it back with the new
  # rows, so the rows already in it must come out byte for byte as they are.
  for (name in c("washdev", "ws", "jwh", "aqua")) {
    path <- testthat::test_path("..", "..", paste0(name, ".csv"))
    rewritten <- tempfile(fileext = ".csv")
    write_snapshot(read_snapshot(path), rewritten)
    expect_identical(
      readBin(rewritten, "raw", file.size(rewritten)),
      readBin(path, "raw", file.size(path)),
      label = paste0(name, ".csv read and written back")
    )
  }
})
