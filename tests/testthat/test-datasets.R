# Shape and content guarantees for the exported datasets.
# The package had no tests before v0.4.0; these cover the two things that
# would be expensive to get wrong: a dataset silently losing rows, and the
# author email columns coming back.

test_that("datasets have the expected number of rows", {
  expect_equal(nrow(washdev), 1173)
  expect_equal(nrow(ws), 4884)
  expect_equal(nrow(jwh), 2013)
  expect_equal(nrow(ploswater), 436)
  expect_equal(nrow(uncnewsletter), 173)
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
    ploswater = ploswater, uncnewsletter = uncnewsletter
  )
  for (name in names(datasets)) {
    data <- datasets[[name]]
    text_columns <- names(data)[vapply(data, is.character, logical(1))]
    found <- vapply(
      text_columns,
      function(column) any(grepl(pattern, data[[column]])),
      logical(1)
    )
    expect_false(any(found), label = paste0(name, " has no inline address"))
  }
})

test_that("no URL carries an access token", {
  # A pre-signed Zenodo link grants access to a restricted record, so the
  # token is stripped and the bare record URL kept. Same reasoning as the
  # expired Silverchair signatures in #10.
  datasets <- list(
    washdev = washdev, ws = ws, jwh = jwh,
    ploswater = ploswater, uncnewsletter = uncnewsletter
  )
  for (name in names(datasets)) {
    data <- datasets[[name]]
    text_columns <- names(data)[vapply(data, is.character, logical(1))]
    found <- vapply(
      text_columns,
      function(column) any(grepl("token=eyJ|access_token=", data[[column]])),
      logical(1)
    )
    expect_false(any(found), label = paste0(name, " has no access token"))
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
