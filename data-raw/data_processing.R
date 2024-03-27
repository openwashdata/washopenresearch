## code to prepare `DATASET` dataset goes here
library(readr)
library(stringr)
library(dplyr)
library(countrycode)
library(forcats)
library(countries)

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
                              pattern = "Canada .*",
                              replacement = "Canada")) |>
  dplyr::mutate(first_author_affiliation_country =
                  str_replace(string = first_author_affiliation_country,
                              pattern = "USA?|U\\.S\\.A|((GA|MI|FL|CA).*)|(United States)",
                              replacement = "United States of America")) |>
  dplyr::mutate(first_author_affiliation_country =
                  countries::country_name(first_author_affiliation_country, to = "UN_en", fuzzy_match = FALSE))

### Manual inspection on what affiliation can be fixed
tmp <- washdev |>
  filter(is.na(first_author_affiliation_country), !is.na(first_author_affiliation)) |>
  select(paperid, first_author_affiliation)
print(tmp, n = nrow(tmp))


### Select to-be-fixed ids and annoate the values
ids <- c(28744, 30021, 30022, 29809, 29810, 30281,
         30290, 30308, 30315, 30322, 30328, 30330,
         30323, 30357, 30072, 30431, 30438, 30126,
         30432, 38048, 39044, 39027, 39033, 39028,
         39043, 39034, 39039, 39035, 39014, 74015,
         84262, 93160, 95562)
washdev$first_author_affiliation_country[which(washdev$paperid %in% ids)] <- country_name(c("India", "Brazil", "Norway", "Australia", "Nepal", "Nigeria",
                                                                                           "Fiji Islands", "United States of America", "Nepal", "India", "United Kingdom", "India",
                                                                                           "New Zealand", "Australia", "Canada", "India", "United States of America", "United States of America",
                                                                                           "Mexico", "China", "United Kingdom", "France", "Tanzania", "India",
                                                                                           "Netherlands", "Brazil", "India", "Ethiopia", "South Africa", "Taiwan",
                                                                                           "Nigeria", "The Democratic Republic of Congo", "Sri Lanka"), to = "UN_en")

## correspondence author
washdev <- washdev |>
  dplyr::mutate(correspondence_author_affiliation_country =
                  str_replace(string = correspondence_author_affiliation_country,
                              pattern = "\\s+E-mail.*",
                              replacement = "")) |>
  dplyr::mutate(correspondence_author_affiliation_country =
                  str_replace(string = correspondence_author_affiliation_country,
                              patter = "Canada .*",
                              replacement = "Canada")) |>
  dplyr::mutate(correspondence_author_affiliation_country =
                  str_replace(string = correspondence_author_affiliation_country,
                              pattern = "USA?|U\\.S\\.A|((GA|MI|FL|CA).*)|(United States)",
                              replacement = "United States of America")) |>
  dplyr::mutate(correspondence_author_affiliation_country =
                  countries::country_name(correspondence_author_affiliation_country, to = "UN_en", fuzzy_match = FALSE))

### Manual inspection on what affiliation can be fixed
tmp <- washdev |>
  filter(is.na(correspondence_author_affiliation_country), !is.na(correspondence_author_affiliation)) |>
  select(paperid, correspondence_author_affiliation)
print(tmp, n = nrow(tmp))


### Select to-be-fixed ids and annoate the values
ids <- c(28744, 30021, 30022, 29809, 29810,
         30281, 30290, 30308, 30315, 30322,
         30328, 30330, 30323, 30357, 30072,
         30431, 30438, 30126, 30432, 38048,
         39044, 39027, 39033, 39028, 39043,
         39034, 39039, 39031, 39014, 74015,
         84262, 93160, 95562)
washdev$correspondence_author_affiliation_country[which(washdev$paperid %in% ids)] <-
  country_name(c("India", "Brazil", "Norway", "Australia", "Nepal",
"Nigeria", "Fiji Islands", "United States", "Nepal", "India",
"United Kingdom", "India", "New Zealand", "Australia", "Canada",
"India", "United States", "United States", "Mexico", "China",
"United Kingdom", "France", "Netherlands", "India", "Netherlands",
"Brazil", "India", "Tanzania", "South Africa", "Taiwan",
"Nigeria", "The Democratic Republic of Congo", "Sri Lanka"))

## modify das type -------------------------------------------------------------
washdev <- washdev |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "^All relevant data are available from.*", replacement = "available in online repository")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "^All relevant data used in this study are available from online repositories.*", replacement = "available in online repository")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = ".*available on Zenodo.*", replacement = "available in online repository")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "^All relevant data are included in the paper.*", replacement = "in paper")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = ".+readers should contact the corresponding author.*", replacement = "on request"))

## change data type ------------------------------------------------------------
washdev <- washdev |>
  dplyr::mutate(across(c(paperid, volume, issue, num_supp, num_authors), as.integer)) |>
  dplyr::mutate(across(c(supp_file_type, das_type), as.factor))

# modify supp type into list-column
# washdev <- washdev |>
#  dplyr::mutate(supp_file_type = strsplit(supp_file_type, " & "))
# manually added misc stuff

## create and rename columns to be uniform with other datasets -----------------
washdev <- washdev |>
  dplyr::rename(paper_url = url) |>
  dplyr::mutate(url_source = "iwaponline.com")


# UNCNEWSLETTER DATA -----------------------------------------------------------
uncnewsletter <- readr::read_csv("./data-raw/unc-article-url-manual-collection.csv")

## Tidy column format
uncnewsletter <- uncnewsletter |>
  dplyr::mutate(paper_info = NULL) |>
  dplyr::filter(!is.na(title)) |>
  dplyr::mutate(supp_file_type = stringr::str_to_lower(supp_file_type)) |>
  dplyr::mutate(num_supp = tidyr::replace_na(num_supp, 0)) |>
  dplyr::mutate(supp_file_type = strsplit(supp_file_type, " & "))

## Unify DAS type --------------------------------------------------------------
uncnewsletter <- uncnewsletter |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "data not sharable", replacement = "not shareable")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "no datasets were generated during the study", replacement = "no data generated")) |>
  dplyr::mutate(das_type = as.factor(das_type))

## Make das repo url a column-list ---------------------------------------------
uncnewsletter <- uncnewsletter |>
  dplyr::mutate(das_repo_url = str_extract(das_repo_url, "(?<=\\[)(.*?)(?=\\]\\s*)")) |>
  dplyr::mutate(das_repo_url = strsplit(das_repo_url, ","))

## create and rename columns to be uniform with other datasets -----------------
uncnewsletter <- uncnewsletter |>
  dplyr::rename(supp_url = supp_link)

## Clean country/region names --------------------------------------------------
uncnewsletter <- uncnewsletter |>
  dplyr::mutate(first_author_affiliation_country =
                  countries::country_name(first_author_affiliation_country, to = "UN_en", fuzzy_match = FALSE)) |>
  dplyr::mutate(first_author_affiliation_country =
                  countries::country_name(correspondence_author_affiliation_country, to = "UN_en", fuzzy_match = FALSE))

# Write to R data object -------------------------------------------------------
usethis::use_data(washdev, overwrite = TRUE)
usethis::use_data(uncnewsletter, overwrite = TRUE)

# Export processed data to csv and xlsx files ----------------------------------
readr::write_csv(washdev, here::here("inst", "extdata", "washdev.csv"))
openxlsx::write.xlsx(washdev, here::here("inst", "extdata", "washdev.xlsx"))

readr::write_csv(uncnewsletter, here::here("inst", "extdata", "uncnewsletter.csv"))
openxlsx::write.xlsx(uncnewsletter, here::here("inst", "extdata", "uncnewsletter.xlsx"))

