# Apply the FAIR rubric (score_fair(), issue #19) across the three datasets and
# summarise the distribution per dataset and per year. This is a reporting
# script, not part of the package build; it documents how the rubric behaves on
# the current data and produces the headline numbers for the vignette.
#
# Run from the package root:
#   Rscript data-raw/fair_scores.R
#
# Output: data-raw/fair-scores-summary.csv (per dataset and year, mean of each
# FAIR dimension and the total).

library(dplyr)
library(purrr)
library(readr)

devtools::load_all(quiet = TRUE)

datasets <- list(washdev = washdev, uncnewsletter = uncnewsletter, ploswater = ploswater)

scored <- imap_dfr(datasets, function(d, name) {
  score_fair(d) |>
    mutate(dataset = name) |>
    select(dataset, published_year,
           fair_findable, fair_accessible, fair_interoperable,
           fair_reusable, fair_total)
})

summary_by_year <- scored |>
  summarise(
    n = n(),
    across(starts_with("fair_"), ~ round(mean(.x), 2)),
    .by = c(dataset, published_year)
  ) |>
  arrange(dataset, published_year)

write_csv(summary_by_year, "data-raw/fair-scores-summary.csv")

message("FAIR score means by dataset:")
scored |>
  summarise(n = n(), across(starts_with("fair_"), ~ round(mean(.x), 2)),
            .by = dataset) |>
  pwalk(function(dataset, n, fair_findable, fair_accessible,
                 fair_interoperable, fair_reusable, fair_total) {
    message(sprintf("  %-14s n=%4d  F=%.2f A=%.2f I=%.2f R=%.2f  total=%.2f",
                    dataset, n, fair_findable, fair_accessible,
                    fair_interoperable, fair_reusable, fair_total))
  })
