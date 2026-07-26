# Build the contact list for author data-request outreach.
#
# Selects every paper in washdev, ploswater, and uncnewsletter whose data
# availability statement is coded as "on request" (datapapers is excluded:
# data papers publish their data by definition), attaches the best available
# contact email (correspondence author, falling back to first author), and
# derives a personal greeting from the contact's family name.
#
# Output (one row per contactable paper, several rows may share an email):
#   data-raw/outreach/outreach_contacts.csv
# Papers whose DAS says "on request" but that have no usable email address
# land in data-raw/outreach/outreach_missing_email.csv for manual follow-up.
#
# Review outreach_contacts.csv before sending: the greeting column is a
# heuristic (last name token, prefixed "Dear Dr") and can be edited freely;
# set the exclude column to any non-empty value to skip a row.
#
# Run from the package root: source("data-raw/outreach/01_build_contact_list.R")

library(readr)
library(dplyr)
library(stringr)
library(purrr)

outreach_dir <- file.path("data-raw", "outreach")

read_dataset <- function(name) {
  read_csv(file.path("inst", "extdata", paste0(name, ".csv")),
           show_col_types = FALSE) |>
    mutate(dataset = name, paperid = as.character(paperid)) |>
    select(dataset, paperid, journal, title, published_year, paper_url, doi,
           das, das_type,
           correspondence_author_name, correspondence_author_email,
           first_author_name, first_author_email)
}

papers <- c("washdev", "ploswater", "uncnewsletter") |>
  map(read_dataset) |>
  list_rbind()

# The coded categories use the literal value "on request"; a handful of rows
# carry the verbatim statement instead (e.g. "available from the corresponding
# author on reasonable request"), so match on the keyword.
on_request <- papers |>
  filter(str_detect(str_to_lower(das_type), "request"))

# "Dear Dr <family name>", taking the last whitespace-separated token of the
# contact name after dropping generational suffixes (Jr., III, ...). Compound
# surnames or wrong titles need a manual edit in the generated CSV; the send
# script uses the greeting column verbatim.
make_greeting <- function(name) {
  clean <- str_remove(str_squish(name), "\\s+(Jr|Sr|II|III|IV)\\.?$")
  family <- str_remove_all(str_extract(clean, "[^\\s]+$"), "[.,]")
  if_else(is.na(family), "Dear Colleague", paste0("Dear Dr ", family))
}

contacts <- on_request |>
  mutate(
    contact_name = coalesce(correspondence_author_name, first_author_name),
    contact_email = str_to_lower(
      coalesce(correspondence_author_email, first_author_email)
    ),
    paper_link = coalesce(
      paper_url,
      if_else(is.na(doi), NA_character_, paste0("https://doi.org/", doi))
    ),
    greeting = make_greeting(contact_name),
    email_ok = str_detect(contact_email, "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"),
    exclude = ""
  ) |>
  arrange(contact_email, dataset, title)

out_cols <- c("exclude", "contact_email", "greeting", "contact_name",
              "dataset", "paperid", "journal", "published_year", "title",
              "paper_link", "doi", "das_type", "das")

contacts |>
  filter(email_ok) |>
  select(all_of(out_cols)) |>
  write_csv(file.path(outreach_dir, "outreach_contacts.csv"))

contacts |>
  filter(!email_ok | is.na(email_ok)) |>
  select(contact_name, dataset, paperid, journal, published_year, title,
         paper_link, doi, das_type) |>
  write_csv(file.path(outreach_dir, "outreach_missing_email.csv"))

n_ok <- sum(contacts$email_ok, na.rm = TRUE)
message(sprintf(
  "%d on-request papers: %d with a contact email (%d unique addresses), %d without.",
  nrow(contacts), n_ok,
  n_distinct(contacts$contact_email[which(contacts$email_ok)]),
  nrow(contacts) - n_ok
))
