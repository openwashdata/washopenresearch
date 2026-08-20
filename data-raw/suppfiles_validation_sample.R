# Draw a stratified validation sample for the supplement content heuristics
# (issue #47 tier 3). The parser's classes are structural guesses; before the
# distribution goes in the paper a human rates a sample and the agreement is
# measured. Stratified by predicted class so the rarer classes (observation
# tables, figures) are represented, not swamped by prose-only files.
#
# Run from the package root (deterministic, seed fixed):
#   Rscript data-raw/suppfiles_validation_sample.R
#
# Output: data-raw/suppfiles/validation_sample.csv with empty human_class and
# human_notes columns. Rate each file by opening local_path and enter one of:
# observation tables / summary tables / figures / prose only. The sheet is
# the committed record, same pattern as the screening decision sheets.

library(dplyr)
library(readr)

set.seed(47)

TARGET <- c("observation tables" = 9, "summary tables" = 8,
            "prose only" = 8, "figures" = 5)

parsed <- read_csv("data-raw/suppfiles/suppfiles_parsed.csv",
                   show_col_types = FALSE) |>
  filter(parse_status == "ok")

sample_sheet <- parsed |>
  filter(content_class %in% names(TARGET)) |>
  group_split(content_class) |>
  lapply(function(g) {
    n <- min(TARGET[[unique(g$content_class)]], nrow(g))
    g[sample.int(nrow(g), n), ]
  }) |>
  bind_rows() |>
  transmute(
    source, doi, file_name, format,
    predicted_class = content_class,
    n_tables, max_table_rows, n_sheets,
    local_path = file.path("data-raw/suppfiles/files", source,
                           gsub("[/]", "_", sub("^10\\.", "10.", doi)),
                           file_name),
    human_class = NA_character_,
    human_notes = NA_character_
  ) |>
  arrange(source, doi)

# local_path above is reconstructed; take the authoritative one from the
# manifest instead.
manifest <- read_csv("data-raw/suppfiles/manifest.csv",
                     show_col_types = FALSE) |>
  select(doi, file_name, manifest_path = local_path)
sample_sheet <- sample_sheet |>
  left_join(manifest, by = c("doi", "file_name")) |>
  mutate(local_path = manifest_path, manifest_path = NULL)

out <- "data-raw/suppfiles/validation_sample.csv"
if (file.exists(out)) {
  stop(out, " already exists; it may hold ratings. Delete it explicitly ",
       "to redraw.", call. = FALSE)
}
write_csv(sample_sheet, out)
message("Wrote ", nrow(sample_sheet), " files to rate in ", out)
