#' Score a paper's data management against the FAIR principles
#'
#' Scores each paper on the four FAIR dimensions (Findable, Accessible,
#' Interoperable, Reusable) from the data-sharing fields the package already
#' records. Each dimension is scored 0, 1, or 2, and `fair_total` is their sum
#' (0 to 8). The rubric is deliberately simple and documented so the scoring is
#' reproducible and open to criticism (issue #19); it is a screening instrument,
#' not a certified FAIR assessment.
#'
#' @details
#' The four dimensions are scored as follows.
#'
#' \strong{Findable} (persistent identifier and registered location):
#' \itemize{
#'   \item 2: the data is in a registered repository (`das_repo_name` is set)
#'     and a repository link or dataset DOI is present.
#'   \item 1: a data location is stated (`das_type` is "available in online
#'     repository", or a `das_repo_url` is present) but without a recognised
#'     repository, or the data is in the paper or its supplement.
#'   \item 0: no data location (no DAS, "on request", or "not shareable").
#' }
#'
#' \strong{Accessible} (can a reader get the data without a barrier):
#' \itemize{
#'   \item 2: a repository or supplement link is present (`das_repo_url` or
#'     `supp_url`), so the data is directly retrievable.
#'   \item 1: the data is stated to be in the paper or supplement but no link is
#'     recorded.
#'   \item 0: "on request", "not shareable", or no DAS.
#' }
#'
#' \strong{Interoperable} (open, machine-readable shared formats), from
#' `supp_file_type`:
#' \itemize{
#'   \item 2: any open machine-readable format (csv, txt, tsv, json, xml).
#'   \item 1: structured but proprietary formats only (xlsx, docx, sav, dta).
#'   \item 0: unstructured only (pdf, images), or no shared files.
#' }
#'
#' \strong{Reusable} (license and repository metadata). Because a license column
#' is not yet collected for these datasets, this dimension is scored from the
#' repository signal as a lower bound:
#' \itemize{
#'   \item 2: data in a recognised repository (`das_repo_name` set), which
#'     normally carries a license and rich metadata.
#'   \item 1: a data location is stated but not in a recognised repository.
#'   \item 0: no shared data.
#' }
#' When a `license` column is added (see issue #19), raise this dimension to use
#' it directly.
#'
#' Note that Accessible scores the shared files, not the authors' intent. A
#' paper whose `das_type` is "on request" or "not shareable" can still score 2
#' on Accessible if it ships a supplement with a `supp_url`, because that
#' supplement is directly retrievable. The `das_type` value stays visible
#' alongside the score, so a restricted-data paper that still shares a
#' supplement is distinguishable from a fully open one.
#'
#' @param data A data frame with the columns `has_das`, `das_type`,
#'   `das_repo_url`, `das_repo_name`, and `supp_file_type`. The washdev,
#'   uncnewsletter, and ploswater datasets all carry these. `das_repo_name` is
#'   optional; when absent, the repository signal falls back to `das_repo_url`.
#'
#' @return `data` with five integer columns added: `fair_findable`,
#'   `fair_accessible`, `fair_interoperable`, `fair_reusable`, and `fair_total`.
#'
#' @examples
#' scored <- score_fair(ploswater)
#' table(scored$fair_total)
#'
#' @export
score_fair <- function(data) {
  needed <- c("has_das", "das_type", "supp_file_type")
  missing <- setdiff(needed, names(data))
  if (length(missing)) {
    stop("score_fair() needs column(s): ", paste(missing, collapse = ", "),
         call. = FALSE)
  }

  das_type <- as.character(data$das_type)
  repo_url <- if ("das_repo_url" %in% names(data)) data$das_repo_url else NA_character_
  repo_name <- if ("das_repo_name" %in% names(data)) data$das_repo_name else NA_character_
  supp_url <- if ("supp_url" %in% names(data)) data$supp_url else NA_character_
  supp_type <- data$supp_file_type

  has_repo_name <- !is.na(repo_name) & nzchar(repo_name)
  has_repo_url <- !is.na(repo_url) & nzchar(repo_url)
  has_supp_url <- !is.na(supp_url) & nzchar(supp_url)
  in_repo_das <- !is.na(das_type) & das_type == "available in online repository"
  in_paper_das <- !is.na(das_type) & das_type == "in paper"
  barrier_das <- !is.na(das_type) & das_type %in% c("on request", "not shareable")

  findable <- dplyr::case_when(
    has_repo_name & (has_repo_url | in_repo_das) ~ 2L,
    in_repo_das | has_repo_url | in_paper_das ~ 1L,
    TRUE ~ 0L
  )

  accessible <- dplyr::case_when(
    has_repo_url | has_supp_url ~ 2L,
    in_paper_das ~ 1L,
    barrier_das | is.na(das_type) ~ 0L,
    TRUE ~ 0L
  )

  open_fmt <- "\\b(csv|txt|tsv|json|xml)\\b"
  struct_fmt <- "\\b(xlsx|xls|docx|doc|sav|dta|rds|parquet)\\b"
  supp_lc <- tolower(ifelse(is.na(supp_type), "", supp_type))
  interoperable <- dplyr::case_when(
    grepl(open_fmt, supp_lc) ~ 2L,
    grepl(struct_fmt, supp_lc) ~ 1L,
    TRUE ~ 0L
  )

  reusable <- dplyr::case_when(
    has_repo_name ~ 2L,
    in_repo_das | has_repo_url | in_paper_das ~ 1L,
    TRUE ~ 0L
  )

  data$fair_findable <- findable
  data$fair_accessible <- accessible
  data$fair_interoperable <- interoperable
  data$fair_reusable <- reusable
  data$fair_total <- findable + accessible + interoperable + reusable
  data
}
