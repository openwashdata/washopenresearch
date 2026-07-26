# Send the author data-request emails built by 01_build_contact_list.R.
#
# One email per unique contact address; a contact with several on-request
# papers gets a single message listing all of them. Runs as a dry run by
# default (writes message previews, sends nothing). Every sent message is
# appended to outreach_sent_log.csv and never re-sent, so the script can be
# re-run in batches until the whole list is worked off.
#
# Configuration (environment variables):
#   OUTREACH_FROM            sender address, e.g. yourname@ethz.ch (required)
#   OUTREACH_SENDER_NAME     signature name, e.g. "Lars Schoebitz" (required)
#   OUTREACH_SENDER_AFFIL    signature affiliation line (required)
#   OUTREACH_SMTP_HOST       default "mail.ethz.ch"
#   OUTREACH_SMTP_PORT       default 587 (STARTTLS)
#   OUTREACH_SMTP_USER       SMTP login, defaults to OUTREACH_FROM
#   OUTREACH_SMTP_PASSWORD   SMTP password (only needed for a real run)
#   OUTREACH_DRY_RUN         "false" to actually send; anything else previews
#   OUTREACH_TEST_TO         if set, every message goes to this address instead
#                            of the real recipient (for testing on yourself)
#   OUTREACH_MAX_PER_RUN     max messages per invocation, default 20
#
# Run from the package root: source("data-raw/outreach/02_send_emails.R")

library(readr)
library(dplyr)
library(stringr)
library(glue)
library(blastula)

outreach_dir <- file.path("data-raw", "outreach")
contacts_file <- file.path(outreach_dir, "outreach_contacts.csv")
log_file <- file.path(outreach_dir, "outreach_sent_log.csv")
preview_dir <- file.path(outreach_dir, "previews")

env_or_stop <- function(var) {
  value <- Sys.getenv(var)
  if (!nzchar(value)) stop("Set the ", var, " environment variable.", call. = FALSE)
  value
}

dry_run <- !identical(Sys.getenv("OUTREACH_DRY_RUN", "true"), "false")
test_to <- Sys.getenv("OUTREACH_TEST_TO")
max_per_run <- as.integer(Sys.getenv("OUTREACH_MAX_PER_RUN", "20"))
from <- env_or_stop("OUTREACH_FROM")
sender_name <- env_or_stop("OUTREACH_SENDER_NAME")
sender_affiliation <- env_or_stop("OUTREACH_SENDER_AFFIL")
smtp_host <- Sys.getenv("OUTREACH_SMTP_HOST", "mail.ethz.ch")
smtp_port <- as.integer(Sys.getenv("OUTREACH_SMTP_PORT", "587"))
smtp_user <- Sys.getenv("OUTREACH_SMTP_USER", from)

template <- readLines(file.path(outreach_dir, "email_template.txt"))
subject_template <- str_remove(template[[1]], "^Subject:\\s*")
body_template <- paste(template[-(1:2)], collapse = "\n")

already_sent <- if (file.exists(log_file)) {
  read_csv(log_file, show_col_types = FALSE)$contact_email
} else {
  character(0)
}

recipients <- read_csv(contacts_file, show_col_types = FALSE) |>
  filter(is.na(exclude) | exclude == "") |>
  filter(!contact_email %in% already_sent) |>
  group_by(contact_email) |>
  summarise(
    greeting = first(greeting),
    paper_phrase = if_else(
      n() == 1,
      paste0("article in ", first(journal)),
      "articles"
    ),
    paper_list = paste0(
      "- \"", title, "\" (", published_year, "), ", journal, ": ", paper_link,
      collapse = "\n"
    ),
    n_papers = n(),
    .groups = "drop"
  ) |>
  slice_head(n = max_per_run)

if (nrow(recipients) == 0) {
  message("Nothing to send: every non-excluded contact is already in the log.")
}

if (dry_run) dir.create(preview_dir, showWarnings = FALSE)

for (i in seq_len(nrow(recipients))) {
  r <- recipients[i, ]
  fields <- list(
    greeting = r$greeting,
    paper_phrase = r$paper_phrase,
    paper_list = r$paper_list,
    sender_name = sender_name,
    sender_affiliation = sender_affiliation,
    sender_email = from
  )
  subject <- glue_data(fields, subject_template)
  body <- glue_data(fields, body_template)
  to <- if (nzchar(test_to)) test_to else r$contact_email

  if (dry_run) {
    preview <- file.path(preview_dir, paste0(str_replace_all(to, "[^a-z0-9]", "_"), ".txt"))
    writeLines(c(paste("To:", to), paste("Subject:", subject), "", body), preview)
    message("Preview written: ", preview)
    next
  }

  smtp_send(
    compose_email(body = md(body)),
    from = setNames(from, sender_name),
    to = to,
    subject = subject,
    credentials = creds_envvar(
      pass_envvar = "OUTREACH_SMTP_PASSWORD",
      user = smtp_user,
      host = smtp_host,
      port = smtp_port,
      use_ssl = TRUE
    )
  )
  tibble(
    contact_email = r$contact_email,
    sent_to = to,
    n_papers = r$n_papers,
    subject = as.character(subject),
    sent_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  ) |>
    write_csv(log_file, append = file.exists(log_file))
  message(sprintf("Sent %d/%d: %s", i, nrow(recipients), to))

  # Space the messages out so the batch doesn't trip mail-server rate limits
  # or spam heuristics.
  if (i < nrow(recipients)) Sys.sleep(runif(1, 20, 40))
}
