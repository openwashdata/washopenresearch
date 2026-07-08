#' Dataset about data availability in PLOS Water
#'
#' Article metadata for all articles published in PLOS Water since its
#' first volume (2022), collected through the public PLOS search API and
#' each article's JATS XML. Data availability statements are mandatory at
#' PLOS, so `has_das` is TRUE for research articles throughout; the
#' interesting variation lies in `das_type`, `das_repo_url`, and
#' `das_repo_name`. All article types are included; use `article_type`
#' to restrict to research articles.
#'
#' @format ## `ploswater`
#'
#' \describe{
#'   \item{paperid}{DOI of the paper, identical to the doi variable}
#'   \item{volume}{Volume number of the journal; volume 1 is 2022}
#'   \item{issue}{Issue number of the journal}
#'   \item{paper_url}{Official website url of the paper}
#'   \item{journal}{Full name of the journal}
#'   \item{title}{Title of the paper}
#'   \item{published_year}{Year of publication}
#'   \item{is_supp}{Whether the paper has supplementary materials}
#'   \item{num_supp}{Number of supplementary material files}
#'   \item{supp_file_type}{File types of the supplementary materials, separated by "; " when there are multiple}
#'   \item{supp_url}{Website urls of the supplementary materials, separated by "; " when there are multiple. These links are stable download endpoints, they do not expire.}
#'   \item{num_authors}{Number of the authors}
#'   \item{first_author_name}{Name of the first author}
#'   \item{first_author_affiliation}{Academic affiliation of the first author}
#'   \item{first_author_affiliation_country}{Country of the first author parsed from first_author_affiliation, encoded with United Nations names}
#'   \item{first_author_email}{Email of the first author. Only available when the first author is also the correspondence author, because PLOS publishes only the correspondence email.}
#'   \item{first_author_orcid}{ORCID of the first author}
#'   \item{correspondence_author_name}{Name of the correspondence author}
#'   \item{correspondence_author_affiliation}{Academic affiliation of the correspondence author}
#'   \item{correspondence_author_affiliation_country}{Country of the correspondence author parsed from correspondence_author_affiliation, encoded with United Nations names}
#'   \item{correspondence_author_email}{Email of the correspondence author}
#'   \item{correspondence_author_orcid}{ORCID of the correspondence author}
#'   \item{has_das}{Whether the paper has a data availability statement}
#'   \item{das}{Original data availability statement of the paper. NA if it does not have a data availability statement.}
#'   \item{das_type}{Type of the data availability statement including available in online repository(data is shared in a public online repository) in paper(data in full paper scope like supplementary material or appendix or main content) on request(data available on request to the authors) not shareable(data is not shareable) no data generated(the study produced no datasets). NA if it does not have a data availability statement or no classification rule matched.}
#'   \item{das_repo_url}{Website urls and dataset DOIs mentioned in the data availability statement, separated by "; " when there are multiple}
#'   \item{das_repo_name}{Recognized data repositories behind das_repo_url (e.g. zenodo, dryad, figshare, osf, github, dataverse), separated by "; " when there are multiple}
#'   \item{keywords}{Subject terms of the paper from the PLOS search API, separated by "; ". PLOS Water articles carry no author keywords in their XML.}
#'   \item{url_source}{Publisher website of the paper}
#'   \item{doi}{DOI of the paper}
#'   \item{article_type}{Article type, e.g. "Research Article", "Opinion", "Review"}
#'   \item{publication_date}{Date of publication (ISO 8601)}
#' }
"ploswater"
