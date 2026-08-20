# Apply the in-paper claim classification (das_in_paper_support(), issue #47
# tier 1) across washdev and the three IWA journal snapshots and summarise how
# the modal "data in paper" DAS category is actually backed. This is a
# reporting script, not part of the package build; it produces the headline
# split for issue #47 and the vignette.
#
# Run from the package root:
#   Rscript data-raw/das_in_paper_support.R
#
# Output: data-raw/das-in-paper-support-summary.csv (per source, count and
# share of each support category among in-paper claims).

library(dplyr)
library(purrr)
library(readr)

devtools::load_all(quiet = TRUE)

# The IWA snapshots are read with explicit col_types: the type guesser would
# otherwise drop DAS text columns that start with thousands of NAs.
read_iwa <- function(path) {
  read_csv(path, col_types = cols(.default = col_character())) |>
    mutate(
      is_supp = as.logical(is_supp),
      num_supp = as.integer(num_supp)
    )
}

sources <- list(
  washdev = washdev,
  jwh = read_iwa("data-raw/jwh.csv"),
  aqua = read_iwa("data-raw/aqua.csv"),
  ws = read_iwa("data-raw/ws.csv")
)

classified <- imap_dfr(sources, function(d, name) {
  das_in_paper_support(d) |>
    mutate(source = name) |>
    select(source, das_in_paper_support)
})

claims <- classified |> filter(!is.na(das_in_paper_support))

summary_by_source <- claims |>
  count(source, das_in_paper_support, name = "n") |>
  mutate(share = round(n / sum(n), 3), .by = source) |>
  arrange(source, desc(n))

write_csv(summary_by_source, "data-raw/das-in-paper-support-summary.csv")

message("In-paper claims: ", nrow(claims), " of ", nrow(classified),
        " papers across ", length(sources), " sources.")
message("Support for the claim, all sources pooled:")
claims |>
  count(das_in_paper_support, name = "n") |>
  mutate(share = round(100 * n / sum(n), 1)) |>
  arrange(desc(n)) |>
  pwalk(function(das_in_paper_support, n, share) {
    message(sprintf("  %-24s %5d  (%.1f%%)", das_in_paper_support, n, share))
  })
