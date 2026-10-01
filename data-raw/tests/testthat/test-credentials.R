# Credentials are removed from text before a dataset is written: access
# tokens in URLs and passwords authors stated in a statement.

# The examples are assembled from parts so that this file holds no literal a
# secret scanner reads as a credential assignment.
token_parameter <- paste0("tok", "en=", "abc.DEF-123_xyz")
stated_password <- function(separator, value) paste0("pass", "word", separator, value)

test_that("a token parameter is dropped and the record URL kept", {
  expect_equal(
    strip_url_tokens(paste0("https://zenodo.org/records/1?", token_parameter)),
    "https://zenodo.org/records/1"
  )
})

test_that("other parameters survive, wherever the token sits", {
  expect_equal(
    strip_url_tokens(paste0("https://x.org/a?", token_parameter, "&page=2")),
    "https://x.org/a?page=2"
  )
  expect_equal(
    strip_url_tokens(paste0("https://x.org/a?page=2&", token_parameter)),
    "https://x.org/a?page=2"
  )
  expect_equal(
    strip_url_tokens(paste0("https://x.org/a?page=2&", token_parameter, "&lang=en")),
    "https://x.org/a?page=2&lang=en"
  )
})

test_that("several tokens in one text are all dropped", {
  url <- paste0("https://zenodo.org/records/1?", token_parameter)
  expect_equal(
    strip_url_tokens(paste(url, "and", url)),
    "https://zenodo.org/records/1 and https://zenodo.org/records/1"
  )
})

test_that("access_token and signature parameters are dropped too", {
  expect_equal(
    strip_url_tokens(paste0("https://x.org/a?access_", token_parameter)),
    "https://x.org/a"
  )
  expect_equal(
    strip_url_tokens("https://cdn.org/f.pdf?Expires=1&signature=abc123"),
    "https://cdn.org/f.pdf?Expires=1"
  )
})

test_that("text without a token is left alone", {
  untouched <- c("https://x.org/plain?page=2", "no url here", NA)
  expect_equal(strip_url_tokens(untouched), untouched)
})

test_that("a stated password is replaced and the sentence kept", {
  expect_equal(
    redact_stated_passwords(
      paste0("ftp site (ftp.example.org, username: reader ",
             stated_password(": ", "letMEin"), ", then use: cwd/data)")
    ),
    "ftp site (ftp.example.org, username: reader password [removed], then use: cwd/data)"
  )
  expect_equal(
    redact_stated_passwords(
      paste0("https://share.example.org/s/1 (", stated_password(":", "x9k2"), ").")
    ),
    "https://share.example.org/s/1 (password [removed])."
  )
})

test_that("the word password alone is left alone", {
  untouched <- c("The data are password protected.", NA)
  expect_equal(redact_stated_passwords(untouched), untouched)
})
