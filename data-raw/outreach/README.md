# Author outreach: data available "on request"

Toolkit for emailing the corresponding authors of papers whose data
availability statement (DAS) says the data are available on request, asking
them to share the data (and offering to publish it openly via openwashdata).

Covers `washdev`, `ploswater`, and `uncnewsletter`; `datapapers` is excluded
because data papers publish their data by definition.

## Workflow

1. **Build the list** (from the package root):

   ```r
   source("data-raw/outreach/01_build_contact_list.R")
   ```

   Writes `outreach_contacts.csv` (one row per contactable paper; rows
   sharing an email address are combined into a single message at send time)
   and `outreach_missing_email.csv` (on-request papers with no usable
   address, for manual follow-up).

2. **Review and edit `outreach_contacts.csv`.** The `greeting` column is a
   heuristic ("Dear Dr <last name token>") — fix compound surnames, wrong
   titles, etc. by editing the cell; the send script uses it verbatim. Put
   anything in the `exclude` column to skip a row. Watch for typos in the
   scraped addresses (they are taken from the journal pages as-is).

3. **Adjust `email_template.txt`.** First line is the subject; the rest is
   the body. Placeholders: `{greeting}`, `{paper_phrase}`, `{paper_list}`,
   `{sender_name}`, `{sender_affiliation}`, `{sender_email}`.

4. **Dry run** — writes one preview file per recipient to `previews/`,
   sends nothing:

   ```r
   Sys.setenv(
     OUTREACH_FROM = "yourname@ethz.ch",
     OUTREACH_SENDER_NAME = "Your Name",
     OUTREACH_SENDER_AFFIL = "Global Health Engineering, ETH Zurich"
   )
   source("data-raw/outreach/02_send_emails.R")
   ```

5. **Test on yourself** — real send, but every message goes to you:

   ```r
   Sys.setenv(
     OUTREACH_DRY_RUN = "false",
     OUTREACH_TEST_TO = "yourname@ethz.ch",
     OUTREACH_SMTP_PASSWORD = askpass::askpass("ETH password")
   )
   source("data-raw/outreach/02_send_emails.R")
   ```

   Note: in test mode every message is logged against its *real* contact
   address, so delete `outreach_sent_log.csv` after testing or those
   contacts will be skipped in the real run.

6. **Real run** — unset `OUTREACH_TEST_TO`, keep `OUTREACH_DRY_RUN=false`,
   and re-run. Each invocation sends at most `OUTREACH_MAX_PER_RUN`
   (default 20) messages, waits 20–40 s between them, and appends to
   `outreach_sent_log.csv` so contacts are never emailed twice. Re-run over
   several days until the list is worked off.

## ETH Zurich mail settings

The defaults target ETH's authenticated SMTP relay: `mail.ethz.ch`,
port 587 with STARTTLS, logging in with your ETH email address and mail
password. If your mailbox rejects SMTP AUTH (some accounts require an
app-specific password or have legacy SMTP disabled), check the ETH IT
knowledge base or set `OUTREACH_SMTP_HOST`/`PORT`/`USER` to whatever your
mailbox settings page lists. Sending from your real mailbox matters:
replies and bounces land where you can act on them.

## Good-practice notes

- **Batch and pace.** ~170 papers resolve to ~150 unique addresses. Stick
  to the default batch size and delays; a burst of near-identical messages
  from one account is exactly what spam filters and the ETH relay's rate
  limits look for.
- **Ethics.** If you plan to *study* the responses (e.g. publish compliance
  rates for "data available on request" statements, a common meta-research
  design), check ETH Zurich Ethics Commission requirements before sending —
  that turns the emails into research data collection involving people.
  Simply requesting data for reuse needs no approval.
- **Opt-out.** The template includes a no-follow-up sentence; honour it by
  adding an `exclude` marker for anyone who opts out.
- **Bounces.** Expect a fair number — some papers are 10+ years old. The
  `outreach_missing_email.csv` sheet plus bounced addresses are candidates
  for manual address hunting (ORCID, institutional pages).
