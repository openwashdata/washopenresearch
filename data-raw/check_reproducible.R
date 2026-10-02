# Check that the datasets the pipeline builds equal the package data files
# committed at a git ref.
#
# Run from the package root:
#   Rscript data-raw/check_reproducible.R           # against HEAD
#   Rscript data-raw/check_reproducible.R v0.4.0    # against a tag
#
# Builds the dataset targets (not the files they are written to), loads each
# data/<name>.rda as it was at the ref, and compares the objects. Exits with
# status 1 and prints the differences when a dataset does not match.

renv::load(quiet = TRUE)

args <- commandArgs(trailingOnly = TRUE)
ref <- if (length(args) >= 1) args[[1]] else "HEAD"

git <- function(...) {
  out <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(out, "status"))) {
    stop("git ", paste(c(...), collapse = " "), " failed:\n",
         paste(out, collapse = "\n"), call. = FALSE)
  }
  out
}

# The dataset as committed at `ref`, read without touching the working tree.
committed_dataset <- function(name, ref) {
  path <- tempfile(fileext = ".rda")
  on.exit(unlink(path))
  status <- system2(
    "git", c("show", sprintf("%s:data/%s.rda", ref, name)),
    stdout = path, stderr = FALSE
  )
  if (status != 0) {
    stop("Could not read data/", name, ".rda at ", ref, call. = FALSE)
  }
  env <- new.env()
  load(path, envir = env)
  env[[name]]
}

committed <- sub("[.]rda$", "", basename(git("ls-tree", "--name-only", ref, "data/")))
built <- intersect(committed, targets::tar_manifest(fields = "name")$name)
not_built <- setdiff(committed, built)

if (length(built) == 0) {
  stop("No dataset in data/ at ", ref, " is built by the pipeline; ",
       "nothing was compared.", call. = FALSE)
}

# Always rebuild the datasets. The pipeline store does not know when a
# package version changed, so a cached dataset could hide a difference.
# `!!` inlines the names: both calls evaluate the selection in a fresh R
# process, where the variable `built` does not exist.
if (targets::tar_exist_meta()) {
  targets::tar_invalidate(tidyselect::any_of(!!built))
}
targets::tar_make(names = tidyselect::any_of(!!built), reporter = "silent")

differing <- character()
for (name in built) {
  expected <- committed_dataset(name, ref)
  actual <- targets::tar_read_raw(name)
  if (identical(expected, actual)) {
    message("identical: ", name)
  } else {
    differing <- c(differing, name)
    message("DIFFERENT: ", name)
    print(waldo::compare(expected, actual, x_arg = ref, y_arg = "built", max_diffs = 20))
  }
}

# A dataset the pipeline does not build cannot be shown to be reproducible,
# so it fails the check like a difference does.
if (length(not_built) > 0) {
  message("\nIn data/ at ", ref, " but not built by the pipeline: ",
          paste(not_built, collapse = ", "))
}
if (length(differing) > 0) {
  message("\n", length(differing), " of ", length(built),
          " datasets differ from ", ref, ": ", paste(differing, collapse = ", "))
}
if (length(not_built) > 0 || length(differing) > 0) {
  quit(status = 1)
}
message("\nAll ", length(built), " datasets in data/ at ", ref,
        " are identical to what the pipeline builds.")
