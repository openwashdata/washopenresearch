# The validation gate rejects a dataset with a defect and passes a clean one.
# Each case starts from one small clean dataset and introduces exactly one
# defect, so a rejection can only come from the rule under test.

clean_dataset <- function() {
  tibble::tibble(
    paperid = 1:3,
    title = c("Handpump functionality", "Chlorine decay", "Latrine use"),
    first_author_affiliation = c("Makerere University, Uganda", "Eawag, Switzerland", NA),
    first_author_affiliation_country = c("Uganda", "Switzerland", NA),
    has_das = c(TRUE, TRUE, FALSE),
    das = c(
      "All relevant data are included in the paper.",
      paste0("Data are available at https://zenodo.org/records/1?tok", "en=[removed]"),
      NA
    ),
    das_type = factor(c("in paper", "available in online repository", NA))
  )
}

# The dictionary and the removed-keys sheet the gate reads, as temporary
# files matching the clean dataset.
gate_files <- function(data = clean_dataset(), name = "ws", removed = NULL) {
  dictionary <- tempfile(fileext = ".csv")
  readr::write_csv(
    tibble::tibble(
      directory = "data",
      file_name = paste0(name, ".rda"),
      variable_name = names(data),
      variable_type = "x",
      description = "x"
    ),
    dictionary
  )
  removed_keys <- tempfile(fileext = ".csv")
  if (is.null(removed)) {
    removed <- tibble::tibble(dataset = character(), key = character(), reason = character())
  }
  readr::write_csv(removed, removed_keys)
  list(dictionary = dictionary, removed_keys = removed_keys)
}

validate <- function(data, name = "ws", files = gate_files(name = name), released = NULL) {
  validate_dataset(
    data, name, files$dictionary, files$removed_keys,
    released = released, skip = character()
  )
}

test_that("a clean dataset passes and is returned unchanged", {
  data <- clean_dataset()
  expect_identical(validate(data), data)
})

test_that("a column missing from the data dictionary is rejected", {
  data <- clean_dataset()
  files <- gate_files()
  data$citations <- c(4, 0, 2)
  expect_error(validate(data, files = files), "dictionary_columns.*citations")
})

test_that("a dictionary column missing from the dataset is rejected", {
  files <- gate_files()
  data <- dplyr::select(clean_dataset(), -title)
  expect_error(validate(data, files = files), "dictionary_columns.*title")
})

test_that("a repeated key is rejected", {
  data <- clean_dataset()
  data$paperid[3] <- data$paperid[1]
  expect_error(validate(data), "unique_key")
})

test_that("the key is the DOI for ploswater", {
  data <- dplyr::mutate(clean_dataset(), doi = c("10.1/a", "10.1/b", "10.1/b"))
  files <- gate_files(data, name = "ploswater")
  expect_error(validate(data, name = "ploswater", files = files), "unique_key.*doi")
})

test_that("a list column is rejected", {
  data <- clean_dataset()
  files <- gate_files()
  data$title <- as.list(data$title)
  expect_error(validate(data, files = files), "no_list_columns.*title")
})

test_that("an email column is rejected", {
  data <- dplyr::mutate(clean_dataset(), first_author_email = NA_character_)
  expect_error(validate(data, files = gate_files(data)), "no_email_columns")
})

test_that("an address inside a text column is rejected", {
  data <- clean_dataset()
  data$das[1] <- paste0("Data on request from someone", "@", "example.org")
  expect_error(validate(data), "no_inline_addresses.*das")
})

test_that("an address inside a factor level is rejected", {
  data <- clean_dataset()
  levels(data$das_type)[1] <- paste0("Contact someone", "@", "example.org")
  expect_error(validate(data), "no_inline_addresses.*das_type")
})

test_that("an access token in a URL is rejected, a removed one is not", {
  data <- clean_dataset()
  expect_no_error(validate(data))
  data$das[2] <- paste0("https://zenodo.org/records/1?tok", "en=", "abc.def.ghi")
  expect_error(validate(data), "no_access_tokens.*das")
})

test_that("a statement flag without statement text is rejected", {
  data <- clean_dataset()
  data$das[1] <- NA
  expect_error(validate(data), "statement_text")
})

test_that("a country value that is not a UN name is rejected", {
  data <- clean_dataset()
  data$first_author_affiliation_country[1] <- "UGA"
  expect_error(validate(data), "un_country_names.*UGA")
})

test_that("a frozen dataset with a changed row count is rejected", {
  data <- clean_dataset()
  files <- gate_files(data, name = "uncnewsletter")
  expect_error(
    validate(data, name = "uncnewsletter", files = files),
    "frozen_row_count.*expected 173"
  )
})

test_that("an article lost since the last release is rejected", {
  released <- clean_dataset()
  data <- released[-2, ]
  expect_error(validate(data, released = released), "no_lost_keys.*2")
})

test_that("a lost article listed in the removed-keys sheet is accepted", {
  released <- clean_dataset()
  data <- released[-2, ]
  removed <- tibble::tibble(dataset = "ws", key = "2", reason = "retracted")
  files <- gate_files(removed = removed)
  expect_identical(validate(data, files = files, released = released), data)
})

test_that("a dataset the last release did not have is not checked for lost keys", {
  expect_no_error(validate(clean_dataset(), released = NULL))
})

test_that("every broken rule is named in one message", {
  data <- clean_dataset()
  data$paperid[3] <- data$paperid[1]
  data$das[1] <- NA
  error <- tryCatch(validate(data), error = function(e) conditionMessage(e))
  expect_match(error, "unique_key")
  expect_match(error, "statement_text")
})
