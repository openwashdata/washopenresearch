# Build pipeline for the package datasets (see data-raw/README.md).
#
# Inputs are the committed raw snapshots and sheets in data-raw/.
# Acquisition (scraping) is not part of this pipeline.

# The pipeline must run against the pinned packages, and by the time this
# file is read it is too late to switch libraries. Entry scripts call
# renv::load() first, for example: Rscript data-raw/build.R
if (!nzchar(Sys.getenv("RENV_PROJECT"))) {
  stop(
    "The pinned environment is not loaded. Run the pipeline through an ",
    "entry script, or call renv::load() before targets::tar_make().",
    call. = FALSE
  )
}

library(targets)

# Only the shared helpers and the pipeline functions. Sourcing all of
# data-raw/ would execute the scrapers and the analysis scripts.
tar_source(c("data-raw/helpers.R", "data-raw/pipeline"))

datasets <- c(
  "washdev", "ws", "jwh", "aqua", "ploswater", "uncnewsletter", "datapapers"
)
iwa_journals <- c("washdev", "ws", "jwh", "aqua")

# The two targets of a dataset: <dataset>_built holds what the build
# function returns, and <dataset> is that object once it has passed the
# validation gate. Everything downstream uses the validated one.
#
# The build also depends on renv.lock: the pipeline store cannot see a
# changed package version, and another version of readr or countries can
# change a dataset.
dataset_target <- function(name, command) {
  built <- paste0(name, "_built")
  list(
    tar_target_raw(built, bquote({
      renv_lock_file
      .(substitute(command))
    })),
    tar_target_raw(name, bquote(
      validate_dataset(.(as.symbol(built)), .(name), dictionary_file, removed_keys_file)
    ))
  )
}

# One writer target per dataset, named <dataset>_files: the package data
# file and the CSV and XLSX exports.
dataset_files <- lapply(datasets, function(name) {
  tar_target_raw(
    paste0(name, "_files"),
    bquote(write_dataset(.(as.symbol(name)), .(name))),
    format = "file"
  )
})

# The review sheets of each IWA journal, named <journal>_review_files.
iwa_review_files <- lapply(iwa_journals, function(name) {
  tar_target_raw(
    paste0(name, "_review_files"),
    bquote(write_iwa_review_sheets(.(as.symbol(name)), .(name))),
    format = "file"
  )
})

list(
  tar_target(renv_lock_file, "renv.lock", format = "file"),

  # Raw snapshots ------------------------------------------------------------
  tar_target(washdev_raw_file, "data-raw/washdev.csv", format = "file"),
  tar_target(ws_raw_file, "data-raw/ws.csv", format = "file"),
  tar_target(jwh_raw_file, "data-raw/jwh.csv", format = "file"),
  tar_target(aqua_raw_file, "data-raw/aqua.csv", format = "file"),
  tar_target(ploswater_raw_file, "data-raw/ploswater.csv", format = "file"),
  tar_target(
    uncnewsletter_raw_file, "data-raw/unc-article-url-manual-collection.csv",
    format = "file"
  ),
  tar_target(datapapers_raw_file, "data-raw/datapapers_raw.csv", format = "file"),

  # Inputs of the validation gate --------------------------------------------
  tar_target(dictionary_file, "data-raw/dictionary.csv", format = "file"),
  tar_target(removed_keys_file, "data-raw/removed-keys.csv", format = "file"),

  # Decision sheets ----------------------------------------------------------
  tar_target(
    washdev_country_fixes_file, "data-raw/washdev-country-fixes.csv",
    format = "file"
  ),
  tar_target(
    washdev_supp_type_fixes_file, "data-raw/washdev-supp-type-fixes.csv",
    format = "file"
  ),
  tar_target(
    uncnewsletter_supp_fixes_file, "data-raw/uncnewsletter-supp-fixes.csv",
    format = "file"
  ),
  tar_target(
    datapapers_screening_file, "data-raw/datapapers_screening.csv",
    format = "file"
  ),
  tar_target(
    datapapers_country_fixes_file, "data-raw/datapapers_country_fixes.csv",
    format = "file"
  ),
  tar_target(
    datapapers_repo_fixes_file, "data-raw/datapapers_repo_fixes.csv",
    format = "file"
  ),

  # Frozen inputs ------------------------------------------------------------
  # Written once by data-raw/backfill_dois.R; not regenerated.
  tar_target(
    washdev_doi_backfill_file, "data-raw/washdev-doi-backfill.csv",
    format = "file"
  ),
  tar_target(
    uncnewsletter_doi_backfill_file, "data-raw/uncnewsletter-doi-backfill.csv",
    format = "file"
  ),

  # Datasets -----------------------------------------------------------------
  dataset_target(
    "washdev",
    build_iwa(
      washdev_raw_file, iwa_config("washdev"),
      country_fixes_file = washdev_country_fixes_file,
      supp_type_fixes_file = washdev_supp_type_fixes_file,
      doi_backfill_file = washdev_doi_backfill_file
    )
  ),
  dataset_target("ws", build_iwa(ws_raw_file, iwa_config("ws"))),
  dataset_target("jwh", build_iwa(jwh_raw_file, iwa_config("jwh"))),
  dataset_target("aqua", build_iwa(aqua_raw_file, iwa_config("aqua"))),
  dataset_target("ploswater", build_ploswater(ploswater_raw_file)),
  dataset_target(
    "uncnewsletter",
    build_uncnewsletter(
      uncnewsletter_raw_file,
      supp_fixes_file = uncnewsletter_supp_fixes_file,
      doi_backfill_file = uncnewsletter_doi_backfill_file
    )
  ),
  dataset_target(
    "datapapers",
    build_datapapers(
      datapapers_raw_file,
      screening_file = datapapers_screening_file,
      country_fixes_file = datapapers_country_fixes_file,
      repo_fixes_file = datapapers_repo_fixes_file
    )
  ),

  # Committed outputs --------------------------------------------------------
  dataset_files,
  iwa_review_files,
  tar_target(
    ploswater_review_files, write_ploswater_review_sheets(ploswater),
    format = "file"
  )
)
