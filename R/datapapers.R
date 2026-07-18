#' Dataset about WASH data papers published in dedicated data journals
#'
#' Candidate WASH-related data papers harvested from Crossref and Europe PMC
#' for seven data journals (Scientific Data, Data in Brief, Gates Open
#' Research, F1000Research, GigaScience, GigaByte, and Data), screened for
#' relevance with a committed decision sheet. Data papers describe a shared
#' dataset, so the repository link takes the role that the data availability
#' statement variables play in `washdev` and `uncnewsletter`.
#'
#' @format ## `datapapers`
#'
#' \describe{
#'   \item{paperid}{ID number of the paper within this dataset}
#'   \item{doi}{DOI of the data paper}
#'   \item{paper_url}{Official url of the paper (DOI resolver link)}
#'   \item{url_source}{Publisher website of the paper}
#'   \item{journal}{Full name of the journal}
#'   \item{title}{Title of the paper}
#'   \item{published_year}{Year of publication}
#'   \item{num_authors}{Number of the authors}
#'   \item{first_author_name}{Name of the first author}
#'   \item{first_author_affiliation}{Academic affiliation of the first author}
#'   \item{first_author_affiliation_country}{Country of the first author parsed from first_author_affiliation variable encoded with United Nations names}
#'   \item{data_repo_url}{Website urls of the repository holding the dataset the paper describes, separated by "; " when there are multiple}
#'   \item{data_repo}{Name of the data repository (e.g. Zenodo, Dryad, Figshare, OSF, Dataverse) parsed from data_repo_url}
#'   \item{license}{License url of the paper from Crossref metadata}
#'   \item{related_paper_doi}{DOI of a linked research article, if any (e.g. Data in Brief co-submissions), separated by "; " when there are multiple}
#'   \item{abstract}{Abstract of the paper as provided by the metadata source}
#'   \item{query_term}{WASH search term(s) that retrieved the paper, separated by "; "}
#'   \item{retrieval_date}{Date the paper metadata was harvested from the API}
#' }
#' @source Crossref (<https://api.crossref.org>) and Europe PMC
#'   (<https://europepmc.org>); see `data-raw/README.md` for the pipeline.
"datapapers"
