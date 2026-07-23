# Merge decisions exported from the review app (issue #28) into the committed
# screening sheet. Reads data-raw/datapapers_decisions.csv (doi, include,
# reason; produced by the Export button in datapapers_review.html) and fills
# include/reason in data-raw/datapapers_screening.csv for those DOIs.
#
# The decisions file is the reviewer's own choices, so it overwrites any
# earlier value for the same DOI; rows not in the decisions file are left
# untouched. Re-running is idempotent.
#
# Run from the package root:
#   Rscript data-raw/apply_datapapers_decisions.R

library(dplyr)
library(readr)

decisions_path <- "data-raw/datapapers_decisions.csv"
screening_path <- "data-raw/datapapers_screening.csv"

if (!file.exists(decisions_path)) {
  stop("Missing ", decisions_path, ". Export decisions from ",
       "data-raw/datapapers_review.html first (Export CSV button) and save ",
       "the download there.", call. = FALSE)
}

decisions <- read_csv(
  decisions_path,
  col_types = cols(doi = col_character(), include = col_logical(),
                   reason = col_character())
)
stopifnot(!any(duplicated(decisions$doi)), !any(is.na(decisions$include)))

screening <- read_csv(
  screening_path,
  col_types = cols(
    doi = col_character(), title = col_character(), journal = col_character(),
    published_year = col_integer(), auto_relevant = col_logical(),
    include = col_logical(), reason = col_character()
  )
)

unknown <- setdiff(decisions$doi, screening$doi)
if (length(unknown) > 0) {
  stop(length(unknown), " decision DOI(s) not present in the screening sheet, ",
       "first: ", unknown[1], call. = FALSE)
}

updated <- screening |>
  left_join(decisions, by = "doi", suffix = c("", "_new")) |>
  mutate(
    include = coalesce(include_new, include),
    reason = if_else(!is.na(include_new), reason_new, reason),
    include_new = NULL, reason_new = NULL
  )

write_csv(updated, screening_path, na = "")

message(nrow(decisions), " decisions applied to ", screening_path, ": now ",
        sum(updated$include %in% TRUE), " included, ",
        sum(updated$include %in% FALSE), " excluded, ",
        sum(is.na(updated$include)), " pending.")
