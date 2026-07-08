#' Dataset about data availability in the Journal of Water, Sanitation and Hygiene for Development
#'
#' @format ## `washdev`
#'
#' \describe{
#'   \item{paperid}{ID number of the paper on the journal website}
#'   \item{volume}{Volume number of the journal}
#'   \item{issue}{Issue number of the journal}
#'   \item{paper_url}{Official website url of the paper}
#'   \item{journal}{Full name of the journal}
#'   \item{title}{Title of the paper}
#'   \item{published_year}{Year of publication}
#'   \item{is_supp}{Whether the paper has supplementary materials}
#'   \item{num_supp}{Number of supplementary material files}
#'   \item{supp_file_type}{File types of the supplementary materials, separated by "; " when there are multiple}
#'   \item{supp_url}{Website urls of the supplementary materials, separated by "; " when there are multiple}
#'   \item{num_authors}{Number of the authors}
#'   \item{first_author_name}{Name of the first author}
#'   \item{first_author_affiliation}{Academic affiliation of the first author}
#'   \item{first_author_affiliation_country}{Country of the first author parsed from first_author_affiliation, encoded with United Nations names}
#'   \item{first_author_email}{Email of the first author}
#'   \item{first_author_orcid}{ORCID of the first author}
#'   \item{correspondence_author_name}{Name of the correspondence author}
#'   \item{correspondence_author_affiliation}{Academic affiliation of the correspondence author}
#'   \item{correspondence_author_affiliation_country}{Country of the correspondence author parsed from correspondence_author_affiliation, encoded with United Nations names}
#'   \item{correspondence_author_email}{Email of the correspondence author}
#'   \item{correspondence_author_orcid}{ORCID of the correspondence author}
#'   \item{has_das}{Whether the paper has a data availability statement}
#'   \item{das}{Original data availability statement of the paper.  NA if it does not have a data availability statement.}
#'   \item{das_type}{Type of the data availability statement including in paper(data in full paper scope like supplementary material or appendix or main content) on request(data available on request to the authors) available in online repository(data is shared in a public online repository) not shareable(data is not shareable). NA if it does not have a data availability statement.}
#'   \item{das_repo_url}{Website urls of the data if the relevant data of the paper is shared on a public repository, separated by "; " when there are multiple}
#'   \item{keywords}{Keywords of the paper, separated by "; "}
#'   \item{url_source}{Publisher website of the paper}
#'   \item{doi}{DOI of the paper. Collected since the R port of the scraper; NA for articles scraped earlier, to be backfilled via Crossref.}
#' }
"washdev"
