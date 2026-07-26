# Chained runner for the three whole-journal IWA scrapes (#32, #33, #34).
# Runs jwh, then aqua, then ws in sequence so they never compete for the
# same IP and trip the Silverchair throttle. Each journal is resumable, so
# re-running this script after an interruption continues where it left off.
# A cooldown gap between journals lets any end-of-journal throttle clear.
#
# Slow and unattended by design (user decision, 2026-07-24). Expect many
# hours total. Run detached from the package root:
#   nohup Rscript data-raw/run_iwa_scrapes.R > data-raw/iwa_scrapes.log 2>&1 &

source("data-raw/iwa_scraping.R")

COOLDOWN_BETWEEN_JOURNALS <- 300  # seconds

order <- c("jwh", "aqua", "ws")

for (k in seq_along(order)) {
  slug <- order[k]
  message("\n===== ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          " starting ", slug, " (", k, "/", length(order), ") =====")
  result <- tryCatch(
    scrape_iwa_journal(JOURNALS[[slug]]),
    error = function(e) {
      message("!! ", slug, " aborted: ", conditionMessage(e))
      NULL
    }
  )
  if (!is.null(result)) {
    message("===== finished ", slug, ": ", nrow(result), " total rows =====")
  }
  if (k < length(order)) {
    message("cooldown ", COOLDOWN_BETWEEN_JOURNALS, "s before next journal")
    Sys.sleep(COOLDOWN_BETWEEN_JOURNALS)
  }
}

message("\n===== all IWA scrapes complete: ",
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " =====")
