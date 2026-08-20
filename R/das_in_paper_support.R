#' Classify how a "data in paper" claim is backed by the supplement fields
#'
#' The stock statement "all relevant data are included in the paper or its
#' supplementary information" is the modal data availability statement across
#' the IWA journal snapshots. As a single category it is nearly uninformative:
#' it covers papers whose complete dataset genuinely fits in the printed
#' tables as well as papers whose tables hold only summary statistics
#' (issue #47). This function scores the claim jointly with the supplement
#' fields already recorded, so "in paper plus xlsx supplement" is
#' distinguished from "in paper, nothing attached".
#'
#' @details
#' A paper makes the in-paper claim when `das_type` is the normalized value
#' `"in paper"` (washdev style) or contains the stock phrasing
#' "included in the paper" / "included in the article" (the IWA journal
#' snapshots keep the raw sentence in `das_type`). Papers without the claim
#' get `NA`.
#'
#' Claims are classified by the strongest attachment that could carry the
#' data, using the same format tiers as [score_fair()]:
#' \itemize{
#'   \item `"open supplement"`: an open machine-readable format is attached
#'     (csv, txt, tsv, json, xml).
#'   \item `"structured supplement"`: structured but proprietary formats only
#'     (xlsx, xls, docx, doc, sav, dta, rds, parquet).
#'   \item `"unstructured supplement"`: a supplement exists but only as pdf
#'     or images, or its format is unknown.
#'   \item `"no supplement"`: nothing is attached; the claim rests entirely
#'     on the printed tables and figures.
#' }
#'
#' The classification is structural: it says where the claimed data could
#' be, not whether it is actually there. Verifying the content of printed
#' tables and supplement files is the follow-up work in issue #47.
#'
#' @param data A data frame with the columns `das_type` and `supp_file_type`.
#'   `is_supp`, `num_supp`, and `supp_url` are used when present to detect
#'   supplements with an unknown format. The washdev, uncnewsletter, and
#'   ploswater datasets and the IWA journal snapshots in `data-raw/` all
#'   carry these.
#'
#' @return `data` with one character column added: `das_in_paper_support`.
#'   `NA` for papers that do not make the in-paper claim.
#'
#' @examples
#' classified <- das_in_paper_support(washdev)
#' table(classified$das_in_paper_support, useNA = "ifany")
#'
#' @export
das_in_paper_support <- function(data) {
  needed <- c("das_type", "supp_file_type")
  missing <- setdiff(needed, names(data))
  if (length(missing)) {
    stop("das_in_paper_support() needs column(s): ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  das_type <- as.character(data$das_type)
  supp_type <- tolower(ifelse(is.na(data$supp_file_type), "",
                              data$supp_file_type))
  supp_url <- if ("supp_url" %in% names(data)) data$supp_url else NA_character_
  is_supp <- if ("is_supp" %in% names(data)) data$is_supp else NA
  num_supp <- if ("num_supp" %in% names(data)) data$num_supp else NA_integer_

  claim <- !is.na(das_type) & (
    das_type == "in paper" |
      grepl("included in the (paper|article)", das_type, ignore.case = TRUE)
  )

  # The IWA snapshots serialize supp_url as a list literal, "[]" when empty,
  # so emptiness cannot be tested with nzchar() alone.
  has_supp_url <- !is.na(supp_url) & nzchar(supp_url) &
    !grepl("^\\s*\\[\\s*\\]\\s*$", supp_url)
  has_supp <- (is_supp %in% TRUE) |
    (!is.na(num_supp) & num_supp > 0) |
    has_supp_url |
    nzchar(supp_type)

  open_fmt <- "\\b(csv|txt|tsv|json|xml)\\b"
  struct_fmt <- "\\b(xlsx|xls|docx|doc|sav|dta|rds|parquet)\\b"

  data$das_in_paper_support <- dplyr::case_when(
    !claim ~ NA_character_,
    grepl(open_fmt, supp_type) ~ "open supplement",
    grepl(struct_fmt, supp_type) ~ "structured supplement",
    has_supp ~ "unstructured supplement",
    TRUE ~ "no supplement"
  )
  data
}
