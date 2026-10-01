# Build pipeline for the package datasets (see data-raw/README.md).
#
# Inputs are the committed raw snapshots and sheets in data-raw/.
# Acquisition (scraping) is not part of this pipeline.

# The pipeline must run against the pinned packages, and by the time this
# file is read it is too late to switch libraries. Entry scripts call
# renv::load() first, for example: Rscript data-raw/check_reproducible.R
if (!nzchar(Sys.getenv("RENV_PROJECT"))) {
  stop(
    "The pinned environment is not loaded. Run the pipeline through an ",
    "entry script, or call renv::load() before targets::tar_make().",
    call. = FALSE
  )
}

library(targets)

# Only the shared helpers and the pipeline functions. Sourcing all of
# data-raw/ would execute the scrapers and the legacy build scripts.
tar_source(c("data-raw/helpers.R", "data-raw/pipeline"))

list(
  # Raw snapshots ------------------------------------------------------------
  tar_target(washdev_raw_file, "data-raw/washdev.csv", format = "file"),
  tar_target(ws_raw_file, "data-raw/ws.csv", format = "file"),
  tar_target(jwh_raw_file, "data-raw/jwh.csv", format = "file"),

  # Decision sheets ----------------------------------------------------------
  tar_target(
    washdev_country_fixes_file, "data-raw/washdev-country-fixes.csv",
    format = "file"
  ),
  tar_target(
    washdev_supp_type_fixes_file, "data-raw/washdev-supp-type-fixes.csv",
    format = "file"
  ),

  # Frozen inputs ------------------------------------------------------------
  # Written once by data-raw/backfill_dois.R; not regenerated.
  tar_target(
    washdev_doi_backfill_file, "data-raw/washdev-doi-backfill.csv",
    format = "file"
  ),

  # Datasets -----------------------------------------------------------------
  tar_target(
    washdev,
    build_iwa(
      washdev_raw_file, iwa_config("washdev"),
      country_fixes_file = washdev_country_fixes_file,
      supp_type_fixes_file = washdev_supp_type_fixes_file,
      doi_backfill_file = washdev_doi_backfill_file
    )
  ),
  tar_target(ws, build_iwa(ws_raw_file, iwa_config("ws"))),
  tar_target(jwh, build_iwa(jwh_raw_file, iwa_config("jwh")))
)
