# Download the supplementary files of the IWA journal snapshots while their
# pre-signed CDN links are still valid (issue #47 tier 3). The links carry an
# Expires stamp roughly 3.5 weeks after the July 2026 scrape; at the time of
# writing (2026-08-20) about half are already dead and the rest lapse by
# 2026-08-30. This script grabs every file whose signature is still valid.
# Files behind expired links (and washdev's supplements, whose supp_url was
# rewritten to article DOIs in #10) need a fresh article-page visit and are
# collected separately.
#
# Run from the package root (resumable; already-downloaded files are skipped):
#   Rscript data-raw/suppfiles_download.R
#
# Output:
#   data-raw/suppfiles/manifest.csv - one row per supplement file: paper keys,
#     signature-stripped URL path (the signed query would trip secret
#     scanners, see #10), expiry, HTTP outcome, size, sha256, local path.
#   data-raw/suppfiles/files/<journal>/<doi-slug>/<name> - the files
#     (gitignored; the manifest with checksums is the committed record).

library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(httr)

PAUSE <- c(2, 4)  # seconds between downloads; CDN fetches, not page scrapes
manifest_path <- "data-raw/suppfiles/manifest.csv"
files_root <- "data-raw/suppfiles/files"

snapshots <- c(jwh = "data-raw/jwh.csv", aqua = "data-raw/aqua.csv",
               ws = "data-raw/ws.csv")

# One row per supplement file URL, keyed back to its paper.
file_list <- imap_dfr(snapshots, function(path, src) {
  read_csv(path, col_types = cols(.default = col_character())) |>
    select(paperid, doi, supp_url) |>
    mutate(url = str_extract_all(supp_url, "https://[^'\" \\]]+")) |>
    select(-supp_url) |>
    tidyr::unnest(url) |>
    mutate(source = src)
}) |>
  mutate(
    expires = as.numeric(str_extract(str_extract(url, "Expires=[0-9]+"),
                                     "[0-9]+")),
    url_path = str_remove(url, "\\?.*$"),
    file_name = basename(url_path),
    doi_slug = str_extract(url_path, "10\\.[0-9]+_[^/]+"),
    local_path = file.path(files_root, source,
                           coalesce(doi_slug, "unknown"), file_name)
  ) |>
  distinct(url_path, .keep_all = TRUE)

alive <- file_list |> filter(!is.na(expires), expires > as.numeric(Sys.time()))
message(nrow(file_list), " supplement file links; ", nrow(alive),
        " still valid, ", nrow(file_list) - nrow(alive), " expired.")

done <- if (file.exists(manifest_path)) {
  read_csv(manifest_path, col_types = cols(.default = col_character()))
} else {
  tibble(url_path = character())
}
todo <- alive |> filter(!url_path %in% done$url_path[done$status == "ok"])
message(nrow(todo), " files to download.")

dir.create(files_root, recursive = TRUE, showWarnings = FALSE)

append_manifest <- function(row) {
  write_csv(row, manifest_path, append = file.exists(manifest_path))
}

pwalk(todo, function(paperid, doi, url, source, expires, url_path,
                     file_name, doi_slug, local_path) {
  dir.create(dirname(local_path), recursive = TRUE, showWarnings = FALSE)
  status <- "error"
  for (try in 1:2) {
    resp <- tryCatch(
      GET(url, write_disk(local_path, overwrite = TRUE), timeout(180)),
      error = function(e) NULL)
    if (!is.null(resp) && status_code(resp) == 200) { status <- "ok"; break }
    if (!is.null(resp)) status <- paste0("http_", status_code(resp))
    Sys.sleep(5 * try)
  }
  if (status != "ok" && file.exists(local_path)) unlink(local_path)
  append_manifest(tibble(
    source = source, paperid = paperid, doi = doi,
    url_path = url_path, file_name = file_name,
    expires_utc = format(as.POSIXct(expires, origin = "1970-01-01",
                                    tz = "UTC")),
    status = status,
    bytes = if (status == "ok") file.size(local_path) else NA_real_,
    sha256 = if (status == "ok") digest::digest(file = local_path,
                                                algo = "sha256")
             else NA_character_,
    local_path = local_path,
    downloaded_at = format(Sys.time(), tz = "UTC")
  ))
  Sys.sleep(runif(1, PAUSE[1], PAUSE[2]))
})

final <- read_csv(manifest_path, col_types = cols(.default = col_character()))
message("Manifest: ", nrow(final), " rows, ",
        sum(final$status == "ok"), " ok, ",
        sum(final$status != "ok"), " failed.")
