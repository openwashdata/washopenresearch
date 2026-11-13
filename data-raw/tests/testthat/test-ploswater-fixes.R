# The das_type decision sheet of PLOS Water: a decision replaces the
# classified value, and a sheet with a mistake stops the build.

plos_rows <- function() {
  tibble::tibble(
    doi = c("10.1371/journal.pwat.0000001", "10.1371/journal.pwat.0000002"),
    das_type = factor(c("in paper", NA), levels = das_type_levels())
  )
}

write_fixes <- function(lines, env = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".csv", .local_envir = env)
  writeLines(c("doi,das_type,reason", lines), path)
  path
}

test_that("a decision sets the das_type and keeps the shared levels", {
  path <- write_fixes("10.1371/journal.pwat.0000002,on request,requests go to a committee")
  fixed <- apply_ploswater_das_fixes(plos_rows(), path)
  expect_equal(as.character(fixed$das_type), c("in paper", "on request"))
  expect_equal(levels(fixed$das_type), das_type_levels())
})

test_that("a sheet without rows changes nothing", {
  fixed <- apply_ploswater_das_fixes(plos_rows(), write_fixes(character()))
  expect_equal(fixed, plos_rows())
})

test_that("a das_type outside the shared levels stops the build", {
  path <- write_fixes("10.1371/journal.pwat.0000002,upon request,x")
  expect_error(apply_ploswater_das_fixes(plos_rows(), path), "not one of the shared levels: upon request")
})

test_that("a DOI the dataset does not have stops the build", {
  path <- write_fixes("10.1371/journal.pwat.0009999,on request,x")
  expect_error(apply_ploswater_das_fixes(plos_rows(), path), "the dataset does not have")
})

test_that("the committed sheet names shared levels only", {
  withr::local_dir("../../..")
  sheet <- readr::read_csv("data-raw/ploswater-das-fixes.csv",
                           col_types = readr::cols(.default = readr::col_character()))
  expect_equal(names(sheet), c("doi", "das_type", "reason"))
  expect_true(all(sheet$das_type %in% das_type_levels()))
  expect_false(anyDuplicated(sheet$doi) > 0)
})
