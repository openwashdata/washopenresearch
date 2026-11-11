# The country lookup: United Nations English names, and the two extra tries
# for a value the lookup does not know.

# Assembled with the escape, so that the typographic apostrophe is visible
lao_typographic <- "Lao People\u2019s Democratic Republic"

test_that("a name the lookup knows comes back as the UN name", {
  expect_equal(to_un_country_name("Uganda"), "Uganda")
  expect_equal(to_un_country_name("South Korea"), "Republic of Korea")
  expect_true(is.na(to_un_country_name(NA_character_)))
  expect_true(is.na(to_un_country_name("Idaho")))
})

test_that("a typographic apostrophe is read as the plain one", {
  expect_equal(plain_apostrophes(lao_typographic), "Lao People's Democratic Republic")
  expect_equal(to_un_country_name(lao_typographic), "Lao People's Democratic Republic")
})

test_that("a name the lookup knows is not changed by the extra tries", {
  # The lookup returns this name with its typographic apostrophe
  ivory_coast <- "C\u00f4te d\u2019Ivoire"
  expect_equal(to_un_country_name(ivory_coast), lookup_un_country_name(ivory_coast))
  known <- c("Georgia", "Ireland", "Mexico", "United States of America")
  expect_equal(to_un_country_name(known), lookup_un_country_name(known))
})

test_that("a country at the end of a value without a comma is found", {
  expect_equal(
    to_un_country_name("Texas United States of America"),
    "United States of America"
  )
  expect_equal(to_un_country_name("Aotearoa New Zealand"), "New Zealand")
  expect_equal(country_at_end("Vientiane Lao People's Democratic Republic"),
               "Lao People's Democratic Republic")
})

test_that("the longest name at the end wins", {
  # "Guinea" and "New Guinea" are at the end too
  expect_equal(country_at_end("Port Moresby Papua New Guinea"), "Papua New Guinea")
})

test_that("a country name tied to the word before it does not count", {
  expect_true(is.na(to_un_country_name("New Mexico")))
  expect_true(is.na(to_un_country_name("University of Georgia")))
  # A misspelt long name must not become the country its last word names
  expect_true(is.na(to_un_country_name(
    "United Kingdom of Great Britian and Northern Ireland"
  )))
})

test_that("values without a country at the end stay missing", {
  expect_true(all(is.na(country_at_end(c("Idaho", "Suomi-Finland", NA, "")))))
  expect_equal(
    to_un_country_name(c("Kenya", "Nairobi Kenya", NA, "Nowhere")),
    c("Kenya", "Kenya", NA, NA)
  )
})
