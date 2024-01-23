## code to prepare `DATASET` dataset goes here
library(readr)
library(stringr)
library(dplyr)


# WASHDEV DATA -----------------------------------------------------------
washdev <- read_csv("data-raw/washdev.csv")[2:28]
# clean country/region names ---------------------------------------------------
## first author
washdev <- washdev |>
  dplyr::mutate(first_author_affiliation_country =
                  str_replace(string = first_author_affiliation_country,
                              pattern = "\\s+E-mail.*",
                              replacement = "")) |>
  dplyr::mutate(first_author_affiliation_country =
                  str_replace(string = first_author_affiliation_country,
                              patter = "Canada .*",
                              replacement = "Canada"))

## correspondence author
washdev <- washdev |>
  dplyr::mutate(correspondence_author_affiliation_country =
                  str_replace(string = correspondence_author_affiliation_country,
                              pattern = "\\s+E-mail.*",
                              replacement = "")) |>
  dplyr::mutate(correspondence_author_affiliation_country =
                  str_replace(string = correspondence_author_affiliation_country,
                              patter = "Canada .*",
                              replacement = "Canada"))

# change data type -------------------------------------------------------------
washdev <- washdev |>
  dplyr::mutate(across(c(paperid, volume, issue, num_supp, num_authors), as.integer)) |>
  dplyr::mutate(across(c(supp_file_type, das_type), as.factor))

# modify das type --------------------------------------------------------------
washdev <- washdev |>
  mutate(das_type = str_replace(das_type, pattern = "^All relevant data are available from.*", replacement = "available in online repository")) |>
  mutate(das_type = str_replace(das_type, pattern = "^All relevant data used in this study are available from online repositories.*", replacement = "available in online repository")) |>
  mutate(das_type = str_replace(das_type, pattern = ".*available on Zenodo.*", replacement = "available in online repository")) |>
  mutate(das_type = str_replace(das_type, pattern = "^All relevant data are included in the paper.*", replacement = "in paper")) |>
  mutate(das_type = str_replace(das_type, pattern = ".+readers should contact the corresponding author.*", replacement = "on request"))

# UNCNEWSLETTER DATA -----------------------------------------------------------
uncnewsletter <- readr::read_csv("./data-raw/unc-article-url-manual-collection.csv")

## Tidy column format
uncnewsletter <- uncnewsletter |>
  dplyr::rename(paperid = `...1`) |>
  dplyr::mutate(paper_info = NULL) |>
  dplyr::mutate(supp_file_type = stringr::str_to_lower(supp_file_type))

usethis::use_data(washdev, overwrite = TRUE)
usethis::use_data(uncnewsletter, overwrite = TRUE)
