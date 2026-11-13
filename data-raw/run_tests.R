# Run the tests of the build pipeline and the scrapers' planning code.
#
# Run from the package root:
#   Rscript data-raw/run_tests.R
#
# These test code in data-raw/, which is not part of the built package, so
# R CMD check cannot run them. The package's own tests in tests/ check the
# exported datasets.

renv::load(quiet = TRUE)

source("data-raw/helpers.R")
source("data-raw/scrape_plan.R")
source("data-raw/client.R")
for (file in list.files("data-raw/pipeline", pattern = "[.]R$", full.names = TRUE)) {
  source(file)
}

testthat::test_dir("data-raw/tests/testthat", stop_on_failure = TRUE)
