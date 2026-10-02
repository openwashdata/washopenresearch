# The defect that kept AQUA out of v0.4.0: read with guessed column types,
# the statement column comes back as an all-missing logical, because the
# journal's first statement sits beyond the rows the guess looks at. The
# gate must reject that, and the strict reader must not produce it.

aqua_snapshot <- testthat::test_path("..", "..", "aqua.csv")

test_that("the gate rejects AQUA read with guessed column types", {
  guessed <- suppressWarnings(readr::read_csv(aqua_snapshot, show_col_types = FALSE))
  expect_type(guessed$das, "logical")
  violation <- gate_rules()$statement_text(guessed, list())
  expect_match(violation, "539 articles .* have no statement text")
})

test_that("the strict reader keeps every AQUA statement", {
  strict <- read_strict_csv(aqua_snapshot, iwa_raw_col_types())
  expect_type(strict$das, "character")
  expect_null(gate_rules()$statement_text(strict, list()))
  expect_equal(sum(!is.na(strict$das)), 539)
})
