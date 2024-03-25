## code to prepare `DATASET` dataset goes here
library(readr)
library(stringr)
library(dplyr)


# WASHDEV DATA -----------------------------------------------------------
washdev <- read_csv("data-raw/washdev.csv")[2:28]
# clean country/region names ---------------------------------------------------
## first author
washdev <- washdev |>
  dplyr::mutate(first_author_affiliation_region =
                  str_replace(string = first_author_affiliation_region,
                              pattern = "\\s+E-mail.*",
                              replacement = "")) |>
  dplyr::mutate(first_author_affiliation_region =
                  str_replace(string = first_author_affiliation_region,
                              patter = "Canada .*",
                              replacement = "Canada"))

## correspondence author
washdev <- washdev |>
  dplyr::mutate(correspondence_author_affiliation_region =
                  str_replace(string = correspondence_author_affiliation_region,
                              pattern = "\\s+E-mail.*",
                              replacement = "")) |>
  dplyr::mutate(correspondence_author_affiliation_region =
                  str_replace(string = correspondence_author_affiliation_region,
                              patter = "Canada .*",
                              replacement = "Canada"))

# change data type -------------------------------------------------------------
washdev <- washdev |>
  dplyr::mutate(across(c(paperid, volume, issue, num_supp, num_authors), as.integer)) |>
  dplyr::mutate(across(c(supp_file_type, das_type), as.factor))

# modify das type --------------------------------------------------------------
washdev <- washdev |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "^All relevant data are available from.*", replacement = "available in online repository")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "^All relevant data used in this study are available from online repositories.*", replacement = "available in online repository")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = ".*available on Zenodo.*", replacement = "available in online repository")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "^All relevant data are included in the paper.*", replacement = "in paper")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = ".+readers should contact the corresponding author.*", replacement = "on request"))

# modify supp type into list-column
# washdev <- washdev |>
#  dplyr::mutate(supp_file_type = strsplit(supp_file_type, " & "))
# manually added misc stuff

# UNCNEWSLETTER DATA -----------------------------------------------------------
uncnewsletter <- readr::read_csv("./data-raw/unc-article-url-manual-collection.csv")

## Tidy column format
uncnewsletter <- uncnewsletter |>
  dplyr::mutate(paper_info = NULL) |>
  dplyr::filter(!is.na(title)) |>
  dplyr::mutate(supp_file_type = stringr::str_to_lower(supp_file_type)) |>
  dplyr::mutate(num_supp = tidyr::replace_na(num_supp, 0)) |>
  mutate(supp_file_type = strsplit(supp_file_type, " & "))

# Write to R data object -------------------------------------------------------
usethis::use_data(washdev, overwrite = TRUE)
usethis::use_data(uncnewsletter, overwrite = TRUE)

# Export processed data to csv and xlsx files ----------------------------------
readr::write_csv(washdev, here::here("inst", "extdata", "washdev.csv"))
openxlsx::write.xlsx(washdev, here::here("inst", "extdata", "washdev.xlsx"))

readr::write_csv(uncnewsletter, here::here("inst", "extdata", "uncnewsletter.csv"))
openxlsx::write.xlsx(uncnewsletter, here::here("inst", "extdata", "uncnewsletter.xlsx"))

