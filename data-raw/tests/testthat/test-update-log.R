# The update log: one row per journal and run, with the user agent, and a
# writer that migrates a log written before that column existed.

test_that("the update log row carries the user agent", {
  row <- update_log_row(
    "jwh", list(issues = 1L, rows = 10L), list(issues = 2L, rows = 15L),
    finished = TRUE, date = as.Date("2026-10-04"), user_agent = "washopenresearch/0.5.0 (x; y)"
  )
  expect_equal(names(row), c("date", "journal", "issues_added", "rows_added", "finished", "user_agent"))
  expect_equal(row$issues_added, 1L)
  expect_equal(row$rows_added, 5L)
  expect_equal(row$user_agent, "washopenresearch/0.5.0 (x; y)")
})

test_that("a log written before the user_agent column is migrated on append", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("date,journal,issues_added,rows_added,finished", "2026-10-02,washdev,3,28,TRUE"), path)
  row <- update_log_row(
    "jwh", list(issues = 0L, rows = 0L), list(issues = 1L, rows = 4L),
    finished = TRUE, date = as.Date("2026-10-04"), user_agent = "ua"
  )
  append_update_log(row, path)
  log <- readr::read_csv(path, show_col_types = FALSE)
  expect_equal(names(log), names(row))
  expect_equal(nrow(log), 2)
  expect_true(is.na(log$user_agent[1]))
  expect_equal(log$user_agent[2], "ua")
  expect_equal(log$rows_added, c(28, 4))
  append_update_log(row, path)
  expect_equal(nrow(readr::read_csv(path, show_col_types = FALSE)), 3)
})

test_that("a new log starts with the full header", {
  path <- withr::local_tempfile(fileext = ".csv")
  row <- update_log_row("ws", list(issues = 0L, rows = 0L), list(issues = 0L, rows = 0L),
                        finished = FALSE, date = as.Date("2026-10-04"), user_agent = "ua")
  append_update_log(row, path)
  expect_equal(readLines(path)[1], "date,journal,issues_added,rows_added,finished,user_agent")
})
