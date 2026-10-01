# Build the package datasets, the flat-file exports and the review sheets
# from the committed raw snapshots and sheets.
#
# Run from the package root:
#   Rscript data-raw/build.R
#
# Only targets whose inputs changed are rebuilt, and a file is rewritten only
# when its content changes. See data-raw/README.md.

renv::load(quiet = TRUE)

targets::tar_make()
