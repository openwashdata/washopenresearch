# Join the parsed supplement classifications back to the in-paper DAS claims
# (issue #47 tier 3). For each claim paper with a downloaded supplement this
# rolls the per-file content classes up to one verdict per paper, by
# precedence: a paper counts as sharing observation tables if any of its
# files does, else summary tables, else figures, else prose only.
#
# Run from the package root, after suppfiles_download.R and
# suppfiles_parse.R:
#   Rscript data-raw/das_in_paper_suppfile_audit.R
#
# Output: data-raw/das-in-paper-suppfile-audit.csv, one row per in-paper
# claim paper that has at least one parsed supplement file.

library(dplyr)
library(readr)
library(stringr)

parsed <- read_csv("data-raw/suppfiles/suppfiles_parsed.csv",
                   show_col_types = FALSE)
claims <- read_csv("data-raw/das-in-paper-claim-types.csv",
                   show_col_types = FALSE)

precedence <- c("observation tables", "summary tables", "figures",
                "prose only", "unparsed", "not_attempted")

paper_class <- parsed |>
  mutate(doi = str_to_lower(doi),
         content_class = factor(content_class, levels = precedence)) |>
  summarise(
    n_files = n(),
    n_files_parsed = sum(parse_status == "ok"),
    paper_class = as.character(sort(content_class)[1]),
    any_observation = any(content_class == "observation tables"),
    .by = c(source, doi)
  )

audit <- claims |>
  inner_join(paper_class, by = c("source", "doi"))

write_csv(audit, "data-raw/das-in-paper-suppfile-audit.csv")

message("In-paper claim papers with parsed supplements: ", nrow(audit))
message("\nPaper-level verdicts by claim support category:")
audit |>
  count(das_in_paper_support, paper_class) |>
  mutate(share = round(100 * n / sum(n), 1), .by = das_in_paper_support) |>
  arrange(das_in_paper_support, desc(n)) |>
  purrr::pwalk(function(das_in_paper_support, paper_class, n, share)
    message(sprintf("  %-24s %-20s %4d (%.1f%%)",
                    das_in_paper_support, paper_class, n, share)))

structured <- audit |> filter(das_in_paper_support == "structured supplement")
message("\nOf the structured-supplement claims with files in hand (",
        nrow(structured), "):")
message("  claim could hold: observation tables in ",
        sum(structured$any_observation), " papers (",
        round(100 * mean(structured$any_observation), 1), "%)")
