## code to prepare `DATASET` dataset goes here
library(readr)
library(stringr)
library(dplyr)
library(tidyr)
library(countrycode)
library(forcats)
library(countries)
library(purrr)

# WASHDEV DATA -----------------------------------------------------------
washdev <- read_csv("data-raw/washdev.csv")[2:28]
## create and rename columns to be uniform with other datasets -----------------
washdev <- washdev |>
  dplyr::rename(paper_url = url) |>
  dplyr::mutate(url_source = "iwaponline.com")
## clean country/region names --------------------------------------------------
### first author ---------------------------------------------------------------
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

#### Manual inspection on what affiliation can be fixed ------------------------
tmp <- washdev |>
  filter(is.na(first_author_affiliation_country), !is.na(first_author_affiliation)) |>
  select(paperid, first_author_affiliation)
print(tmp, n = nrow(tmp))


#### Select to-be-fixed ids and annoate the values -----------------------------
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

### correspondence author ------------------------------------------------------
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

#### Manual inspection on what affiliation can be fixed ------------------------
tmp <- washdev |>
  filter(is.na(correspondence_author_affiliation_country), !is.na(correspondence_author_affiliation)) |>
  select(paperid, correspondence_author_affiliation)
print(tmp, n = nrow(tmp))


#### Select to-be-fixed ids and annoate the values  ----------------------------
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
  dplyr::mutate(das_type = as.factor(das_type))

## Make list-columns: supp_file_type, supp_url, das_repo_url, keywords, --------
### modify supp file type ------------------------------------------------------
#### manually added misc stuff -------------------------------------------------
washdev |>
  filter(supp_file_type == "misc") |>
  select(paperid, paper_url)
ids <- c(73830, 76083, 81993, 83399, 84509,
         85555, 86265, 91503, 93020, 96721,
         96974, 97508, 97930, 97590)
missing_type <- c("pdf & docx", "xlsx & docx & pptx", "docx & xlsx", "docx & pdf & docx & docx & pdf & xlsx", "xlsx & docx",
                  "docx & xlsx", "docx & xlsx & xlsx & xlsx", "pdf & xlsx & xlsx & xlsx & xlsx & xlsx & xlsx & xlsx", "xlsx & xlsx", "docx & xlsx & docx",
                  "docx & xlsx", "png & xlsx & docx", "docx & pptx & xlsx", "docx & xlsx & docx & docx")
washdev$supp_file_type[which(washdev$paperid %in% ids)] <- missing_type

washdev <- washdev |>
  dplyr::mutate(supp_file_type = strsplit(supp_file_type, " & ")) |>
#TODO: test on num_supp and supp_file_type should be the same length of each row
  ### modify das repo url ------------------------------------------------------
  dplyr::mutate(das_repo_url = as.list(das_repo_url)) |>
  ### modify supp url ----------------------------------------------------------
  dplyr::mutate(supp_url = na_if(supp_url, "[]")) |>
  dplyr::mutate(supp_url = purrr::map(supp_url, function(x) str_extract_all(x, pattern = "(?<=')[^',]*?(?='\\s*)")[[1]])) |>
  dplyr::mutate(keywords = purrr::map(keywords, function(x) str_extract_all(x, pattern = "(?<=')[^',]*?(?='\\s*)")[[1]]))


# UNCNEWSLETTER DATA -----------------------------------------------------------
uncnewsletter <- readr::read_csv("./data-raw/unc-article-url-manual-collection.csv")

## Tidy column format ----------------------------------------------------------
uncnewsletter <- uncnewsletter |>
  dplyr::mutate(paper_info = NULL) |>
  dplyr::filter(!is.na(title)) |>
  dplyr::mutate(supp_file_type = stringr::str_to_lower(supp_file_type)) |>
  dplyr::mutate(num_supp = tidyr::replace_na(num_supp, 0)) |>
  # create and rename columns to be uniform with other datasets ----------------
  dplyr::rename(supp_url = supp_link)

## Make list-columns: supp_file_type, supp_url, das_repo_ur, keywords ----------
### modify supp type -----------------------------------------------------------
#### manually added misc stuff -------------------------------------------------
uncnewsletter |>
  filter(num_supp >2) |>
  select(paperid, paper_url)

ids <- c(142, 191, 140,
         84, 129, 118,
         133, 141, 112,
         24, 115, 131,
         136, 146, 177,
         195)
missing_type <- c("xlsx & xlsx & docx", "xlsx & xlsx & docx", "docx & xlsx & zip & zip & zip",
                  "pdf & pdf & xlsx & zip & pdf", "pdf & pdf & pdf & pdf & xlsx", "pdf & pdf & pdf & pdf",
                  "docx & tif & tif & tif", "docx & docx & docx", "xlsx & xlsx & xlsx & xlsx & xlsx & pdf",
                  "pdf & xlsx & xlsx", "docx & zip", paste(c(paste(rep("xlsx", 10), collapse = " & "), "docx", "docx"), collapse = " & "),
                  "xlsx & xlsx & docx", "pdf & docx", "xlsx & xlsx & docx",
                   "xlsx & docx & docx")
uncnewsletter$num_supp[which(washdev$paperid == 115)] <- 2
uncnewsletter$num_supp[which(washdev$paperid == 146)] <- 2
uncnewsletter$supp_file_type[which(washdev$paperid %in% ids)] <- missing_type
uncnewsletter <- uncnewsletter |>
  dplyr::mutate(supp_file_type = strsplit(supp_file_type, " & ")) |>
  ### Make supp url a list-column ----------------------------------------------
  dplyr::mutate(supp_url = as.list(supp_url)) |>
  ### Make das repo url a list-column ------------------------------------------
  dplyr::mutate(das_repo_url = str_extract(das_repo_url, "(?<=\\[)(.*?)(?=\\]\\s*)")) |>
  dplyr::mutate(das_repo_url = strsplit(das_repo_url, ",")) |>
  ### Make keywords a list-column ----------------------------------------------
  dplyr::mutate(keywords = purrr::map(keywords, function(x) str_extract_all(x, pattern = "(?<=')[^',]*?(?='\\s*)")[[1]]))

## Unify DAS type --------------------------------------------------------------
uncnewsletter <- uncnewsletter |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "data not sharable", replacement = "not shareable")) |>
  dplyr::mutate(das_type = str_replace(das_type, pattern = "no datasets were generated during the study", replacement = "no data generated")) |>
  dplyr::mutate(das_type = as.factor(das_type))

## Clean country/region names --------------------------------------------------
uncnewsletter <- uncnewsletter |>
  dplyr::mutate(first_author_affiliation_country =
                  countries::country_name(first_author_affiliation_country, to = "UN_en", fuzzy_match = FALSE)) |>
  dplyr::mutate(first_author_affiliation_country =
                  countries::country_name(correspondence_author_affiliation_country, to = "UN_en", fuzzy_match = FALSE))

skimr::skim(uncnewsletter)
# Write to R data object -------------------------------------------------------
usethis::use_data(washdev, overwrite = TRUE)
usethis::use_data(uncnewsletter, overwrite = TRUE)

# Export processed data to csv and xlsx files ----------------------------------
readr::write_csv(washdev, here::here("inst", "extdata", "washdev.csv"))
openxlsx::write.xlsx(washdev, here::here("inst", "extdata", "washdev.xlsx"))

readr::write_csv(uncnewsletter, here::here("inst", "extdata", "uncnewsletter.csv"))
openxlsx::write.xlsx(uncnewsletter, here::here("inst", "extdata", "uncnewsletter.xlsx"))

