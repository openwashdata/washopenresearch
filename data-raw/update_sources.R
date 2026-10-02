# The monthly acquisition: fetch what is new from every live source and
# record what was added.
#
# Runs the IWA journals (washdev, jwh, aqua, ws) one after the other, with a
# cooldown in between so that they never compete for the same IP address and
# trip the site's throttle, then PLOS Water. The UNC newsletter and the data
# papers are frozen and have no acquisition step.
#
# Each scraper runs as its own R process. The IWA scraper and the PLOS Water
# downloader define helper functions with the same names, so in one session
# the later file would silently replace the functions of the earlier one.
#
# A source that fails does not stop the others. Its failure is printed, noted
# in the update log, and the script exits with status 1 at the end.
#
# data-raw/update-log.csv gets one row per journal and run: the date, the
# journal, the journal issues and the rows the run added, and whether the
# scraper finished.
#
# Slow and unattended by design: the IWA scrapers pause between pages. Run
# from the package root and keep the machine awake:
#   caffeinate -i Rscript data-raw/update_sources.R
#
# Run a subset by naming the sources:
#   Rscript data-raw/update_sources.R jwh ploswater

renv::load(quiet = TRUE)

source("data-raw/scrape_plan.R")

# Seconds to wait between two IWA journals, so that a throttle tripped at
# the end of one journal clears before the next starts.
COOLDOWN_BETWEEN_JOURNALS <- as.numeric(Sys.getenv("IWA_COOLDOWN", "300"))

UPDATE_LOG <- "data-raw/update-log.csv"

# The live sources in run order: the scraper script, its arguments and the
# raw snapshot it adds to.
SOURCES <- list(
  washdev = list(script = "data-raw/iwa_scraping.R", args = "washdev", site = "iwa"),
  jwh = list(script = "data-raw/iwa_scraping.R", args = "jwh", site = "iwa"),
  aqua = list(script = "data-raw/iwa_scraping.R", args = "aqua", site = "iwa"),
  ws = list(script = "data-raw/iwa_scraping.R", args = "ws", site = "iwa"),
  ploswater = list(script = "data-raw/ploswater.R", args = character(), site = "plos")
)

# Run one scraper in a fresh R process and return its exit status. Its
# output goes straight to the console.
run_scraper <- function(scraper) {
  system2(file.path(R.home("bin"), "Rscript"), c(scraper$script, scraper$args))
}

snapshot_path <- function(journal) file.path("data-raw", paste0(journal, ".csv"))

# Run the named sources and return the update log rows of this run.
# `run` and `cooldown` are arguments so that the sequence can be exercised
# without network.
update_sources <- function(journals = names(SOURCES), run = run_scraper,
                           cooldown = COOLDOWN_BETWEEN_JOURNALS,
                           log_path = UPDATE_LOG) {
  rows <- list()
  for (k in seq_along(journals)) {
    journal <- journals[[k]]
    scraper <- SOURCES[[journal]]
    message("\n===== ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            " starting ", journal, " (", k, "/", length(journals), ") =====")
    before <- snapshot_counts(snapshot_path(journal))
    # A scraper that cannot even be started counts as a failed source too
    status <- tryCatch(run(scraper), error = function(e) {
      message("!! ", journal, ": ", conditionMessage(e))
      1L
    })
    after <- snapshot_counts(snapshot_path(journal))
    row <- update_log_row(journal, before, after, finished = identical(as.integer(status), 0L))
    if (row$finished) {
      message("===== finished ", journal, ": ", row$issues_added, " journal issues and ",
              row$rows_added, " rows added =====")
    } else {
      message("!! ", journal, " FAILED (exit status ", status, "). ", row$rows_added,
              " rows were added before it stopped. The other sources still run.")
    }
    readr::write_csv(row, log_path, append = file.exists(log_path))
    rows[[journal]] <- row

    next_is_same_site <- k < length(journals) &&
      identical(SOURCES[[journals[[k + 1]]]]$site, scraper$site)
    if (next_is_same_site && cooldown > 0) {
      message("cooldown ", cooldown, "s before the next journal")
      Sys.sleep(cooldown)
    }
  }
  dplyr::bind_rows(rows)
}

# Runs only when executed directly (Rscript data-raw/update_sources.R)
if (sys.nframe() == 0 && !interactive()) {
  wanted <- commandArgs(trailingOnly = TRUE)
  if (length(wanted) == 0) wanted <- names(SOURCES)
  unknown <- setdiff(wanted, names(SOURCES))
  if (length(unknown) > 0) {
    stop("Unknown source: ", paste(unknown, collapse = ", "), ". Known: ",
         paste(names(SOURCES), collapse = ", "), call. = FALSE)
  }
  log <- update_sources(wanted)
  message("\n===== update complete: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " =====")
  print(as.data.frame(log), row.names = FALSE)
  failed <- log$journal[!log$finished]
  if (length(failed) > 0) {
    message("\n!! FAILED: ", paste(failed, collapse = ", "),
            ". Run them again; a run continues where the last one stopped.")
    quit(status = 1)
  }
}
