# Shape and content guarantees for the exported datasets.
# The package had no tests before v0.4.0; these cover the two things that
# would be expensive to get wrong: a dataset silently losing rows, and the
# author email columns coming back.
#
# The tests state invariants, not a snapshot of one release: the live
# datasets grow with every monthly update, so their row counts have a floor
# and no fixed value.

test_that("frozen datasets keep their row counts", {
  # No acquisition runs for these two sources any more.
  expect_equal(nrow(uncnewsletter), 173)
  expect_equal(nrow(datapapers), 8)
})

test_that("live datasets never fall below their v0.4.0 row counts", {
  expect_gte(nrow(washdev), 1173)
  expect_gte(nrow(ws), 4884)
  expect_gte(nrow(jwh), 2013)
  # 436 rows in v0.4.0, two of them duplicates
  expect_gte(nrow(ploswater), 434)
})

test_that("every article appears once per dataset", {
  expect_false(anyDuplicated(washdev$paperid) > 0)
  expect_false(anyDuplicated(ws$paperid) > 0)
  expect_false(anyDuplicated(jwh$paperid) > 0)
  expect_false(anyDuplicated(uncnewsletter$paperid) > 0)
  expect_false(anyDuplicated(ploswater$doi) > 0)
  expect_false(anyDuplicated(datapapers$doi) > 0)
})

test_that("no dataset carries author email addresses", {
  # Removed in 0.4.0 as personal data that earns nothing analytically.
  # See drop_author_emails() in data-raw/helpers.R.
  datasets <- list(
    washdev = washdev, ws = ws, jwh = jwh,
    ploswater = ploswater, uncnewsletter = uncnewsletter,
    datapapers = datapapers
  )
  for (name in names(datasets)) {
    expect_false(
      any(grepl("email", names(datasets[[name]]), ignore.case = TRUE)),
      label = paste0(name, " has no email column")
    )
  }
})

test_that("no free-text field carries an email address", {
  # Dropping the structured columns is not enough: authors write addresses
  # into the statements themselves. redact_inline_emails() masks the local
  # part and keeps the domain.
  pattern <- "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
  datasets <- list(
    washdev = washdev, ws = ws, jwh = jwh,
    ploswater = ploswater, uncnewsletter = uncnewsletter,
    datapapers = datapapers
  )
  for (name in names(datasets)) {
    data <- datasets[[name]]
    # Text columns and the levels of factor columns: an unmapped statement
    # keeps its full text in das_type, which is a factor.
    text <- unlist(lapply(data, function(column) {
      if (is.character(column)) column else if (is.factor(column)) levels(column)
    }))
    expect_false(any(grepl(pattern, text)), label = paste0(name, " has no inline address"))
  }
})

test_that("no URL carries an access token", {
  # A pre-signed Zenodo link grants access to a restricted record, so the
  # token is stripped and the bare record URL kept. Same reasoning as the
  # expired Silverchair signatures in #10.
  datasets <- list(
    washdev = washdev, ws = ws, jwh = jwh,
    ploswater = ploswater, uncnewsletter = uncnewsletter,
    datapapers = datapapers
  )
  # A JWT after "token=", or any access_token parameter. The "=" sits in a
  # character class so that this file holds no literal a secret scanner
  # reads as a credential assignment.
  leaked_token <- "token[=]eyJ|access_token[=]"
  for (name in names(datasets)) {
    data <- datasets[[name]]
    text_columns <- names(data)[vapply(data, is.character, logical(1))]
    found <- vapply(
      text_columns,
      function(column) any(grepl(leaked_token, data[[column]])),
      logical(1)
    )
    expect_false(any(found), label = paste0(name, " has no access token"))
  }
})

test_that("no statement states a password", {
  # Authors sometimes write the login of an FTP site or a share into their
  # statement. The package does not pass credentials on; the build replaces
  # the password and keeps the sentence.
  datasets <- list(
    washdev = washdev, ws = ws, jwh = jwh,
    ploswater = ploswater, uncnewsletter = uncnewsletter,
    datapapers = datapapers
  )
  stated_password <- "(password|passcode)\\s*[:=]"
  for (name in names(datasets)) {
    data <- datasets[[name]]
    text <- unlist(lapply(data, function(column) {
      if (is.character(column)) column else if (is.factor(column)) levels(column)
    }))
    expect_false(
      any(grepl(stated_password, text, ignore.case = TRUE)),
      label = paste0(name, " states no password")
    )
  }
})

test_that("country columns hold no three letter codes", {
  # The columns are documented as United Nations country names. washdev
  # shipped ISO codes for 33 correspondence authors up to v0.4.0.
  datasets <- list(
    washdev = washdev, ws = ws, jwh = jwh,
    ploswater = ploswater, uncnewsletter = uncnewsletter,
    datapapers = datapapers
  )
  for (name in names(datasets)) {
    data <- datasets[[name]]
    country_columns <- grep("affiliation_country$", names(data), value = TRUE)
    values <- unlist(data[country_columns], use.names = FALSE)
    expect_false(
      any(grepl("^[A-Z]{3}$", values)),
      label = paste0(name, " has no three letter country code")
    )
  }
})

test_that("the IWA datasets share one schema", {
  # washdev, ws and jwh come off the same scraper and are cleaned by
  # process_iwa_journal(), so they must stay column-identical.
  expect_setequal(names(ws), names(washdev))
  expect_setequal(names(jwh), names(washdev))
})

test_that("das_type uses the shared levels where a statement was mapped", {
  shared <- c("available in online repository", "in paper", "on request")
  for (data in list(washdev, ws, jwh)) {
    expect_true(any(levels(data$das_type) %in% shared))
  }
})

test_that("no dataset holds list columns", {
  # List columns break the flat-file exports (issue #8).
  for (data in list(washdev, ws, jwh, ploswater, uncnewsletter, datapapers)) {
    expect_false(any(vapply(data, is.list, logical(1))))
  }
})
