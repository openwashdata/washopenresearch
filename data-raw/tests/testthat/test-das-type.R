# das_type factors: level order is fixed by the build, not by the locale.

test_that("the shared levels lead, in their fixed order, then the statements", {
  x <- c(
    "on request", "Zebra data are with the authors.", "in paper",
    "All relevant data are on a shelf.", NA, "in paper"
  )
  expect_equal(
    levels(das_type_factor_shared_first(x)),
    c("in paper", "on request",
      "All relevant data are on a shelf.", "Zebra data are with the authors.")
  )
})

test_that("values are kept, missing values included", {
  x <- c("on request", NA, "A statement.")
  expect_equal(as.character(das_type_factor_shared_first(x)), x)
  expect_equal(as.character(das_type_factor(x)), x)
})

test_that("a shared level that does not occur is not declared", {
  expect_equal(levels(das_type_factor_shared_first(c("on request", NA))), "on request")
})

test_that("statements sort the same whatever the session collation", {
  x <- c("b statement", "All data", "a statement", "Zenodo", "all data")
  sorted <- withr::with_collate("C", sort_text(x))
  expect_equal(sorted, withr::with_collate("en_US.UTF-8", sort_text(x)))
  expect_equal(sorted, c("a statement", "all data", "All data", "b statement", "Zenodo"))
})
