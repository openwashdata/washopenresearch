# What the raw snapshots must not hold.

raw_snapshots <- c("washdev", "ws", "jwh", "aqua", "ploswater")

# Read every column of a raw snapshot as text, with the encoding repaired as
# the build does it.
read_raw_text <- function(name) {
  raw <- readr::read_csv(
    testthat::test_path("..", "..", paste0(name, ".csv")),
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE, name_repair = "unique_quiet"
  )
  dplyr::mutate(raw, dplyr::across(dplyr::everything(), repair_encoding))
}

# Credentials do not enter a raw snapshot: access tokens in URLs, passwords
# stated in a statement, and the signed query of the supplement download
# links on iwaponline.com.
test_that("no raw snapshot has an access token or a stated password", {
  for (name in raw_snapshots) {
    raw <- read_raw_text(name)
    expect_identical(
      dplyr::mutate(raw, dplyr::across(dplyr::everything(), remove_credentials)),
      raw,
      label = paste0(name, ".csv with credentials removed")
    )
  }
})

test_that("no raw snapshot has a signed download link", {
  for (name in raw_snapshots) {
    raw <- read_raw_text(name)
    signed <- purrr::map_lgl(raw, function(column) {
      any(stringr::str_detect(column, "silverchair-cdn\\.com[^' ]*\\?"), na.rm = TRUE)
    })
    expect_false(any(signed), label = paste0("a signed download link in ", name, ".csv"))
  }
})

test_that("the signed query is dropped and the file path kept", {
  expect_identical(
    strip_silverchair_signature(c(
      "https://iwa.silverchair-cdn.com/iwa/content_public/journal/ws/1/1/10.2166_ws.2001.001/1/file.pdf?Expires=1&Key-Pair-Id=K",
      "https://doi.org/10.2166/ws.2001.001",
      NA
    )),
    c(
      "https://iwa.silverchair-cdn.com/iwa/content_public/journal/ws/1/1/10.2166_ws.2001.001/1/file.pdf",
      "https://doi.org/10.2166/ws.2001.001",
      NA
    )
  )
})

# The raw snapshots hold no structured author addresses. The two author
# email columns were removed from them in 0.5.0 and the scrapers stopped
# collecting them.
test_that("no raw snapshot has an email column", {
  for (name in raw_snapshots) {
    header <- names(read_raw_text(name))
    expect_false(
      any(grepl("email", header, ignore.case = TRUE)),
      label = paste0("an email column in ", name, ".csv")
    )
  }
})

# Some article pages print a contact address after the affiliation. It is
# masked in the raw snapshot like the build masks addresses in text.
# Addresses inside a data availability statement are the published statement
# and stay in the raw text.
test_that("no raw snapshot has an email address in an affiliation column", {
  for (name in raw_snapshots) {
    affiliations <- dplyr::select(read_raw_text(name), dplyr::contains("affiliation"))
    expect_identical(
      dplyr::mutate(affiliations, dplyr::across(dplyr::everything(), redact_inline_emails)),
      affiliations,
      label = paste0("the affiliation columns of ", name, ".csv with addresses masked")
    )
  }
})

# The PLOS Water search was once paged without a sort order and returned two
# articles twice. The downloader keeps one row per DOI.
test_that("the PLOS Water snapshot has one row per DOI", {
  expect_false(anyDuplicated(read_raw_text("ploswater")$doi) > 0)
})
