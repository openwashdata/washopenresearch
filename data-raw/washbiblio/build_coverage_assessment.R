# Combine the three #38 layers into one per-journal coverage assessment
# (issue #38 step 5). For each in-scope journal: does an open source cover
# its permitted OA policy (Open Policy Finder), its required data policy
# (TOP Factor), and its observed practice (PLOS OSI / comparator set / our
# own scrape)? Journals with NO behavioral source are the residual that
# defines the actual bespoke-scraping scope for #35.
#
# Run after pull_oa_policies.R, join_top_factor.R, and
# measure_behavioral_coverage.R.
#
# Output: coverage-assessment.csv, one row per journal.
#
# Dependencies: dplyr, readr

library(dplyr)
library(readr)

DIR <- "data-raw/washbiblio"

identifiers <- read_csv(file.path(DIR, "journal-identifiers.csv"),
                        show_col_types = FALSE)
policies <- read_csv(file.path(DIR, "oa-policies.csv"),
                     show_col_types = FALSE)
top <- read_csv(file.path(DIR, "top-factor-scores.csv"),
                show_col_types = FALSE)
behavioral <- read_csv(file.path(DIR, "behavioral-coverage.csv"),
                       show_col_types = FALSE)

opf <- policies |>
  group_by(source_id) |>
  summarise(
    opf_covered = any(!is.na(issn_queried)),
    opf_n_pathways = sum(!is.na(article_version)),
    .groups = "drop"
  )

out <- identifiers |>
  select(source_id, venue, decision, issn_l, publisher, is_oa, is_in_doaj) |>
  left_join(opf, by = "source_id") |>
  left_join(top |>
              select(source_id, top_matched,
                     top_data_transparency = data_transparency_score,
                     top_data_citation = data_citation_score),
            by = "source_id") |>
  left_join(behavioral |>
              select(source_id, n_plos_osi, n_osi_comparator, n_aaas,
                     own_scrape, any_behavioral),
            by = "source_id") |>
  mutate(
    layers_covered = opf_covered + top_matched + any_behavioral,
    residual_for_35 = !any_behavioral
  )

write_csv(out, file.path(DIR, "coverage-assessment.csv"))

message("Layer coverage over ", nrow(out), " journals: OA policy ",
        sum(out$opf_covered), ", data policy ", sum(out$top_matched),
        ", behavioral ", sum(out$any_behavioral))
message("All three layers: ", sum(out$layers_covered == 3),
        "; no layer at all: ", sum(out$layers_covered == 0))
message("Residual for #35 (no behavioral source): ",
        sum(out$residual_for_35), " journals")
print(out |> filter(residual_for_35) |> select(venue, publisher) |>
        as.data.frame())
