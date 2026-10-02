# Dataset about WASH data papers published in dedicated data journals

Candidate WASH-related data papers harvested from Crossref and Europe
PMC for seven data journals (Scientific Data, Data in Brief, Gates Open
Research, F1000Research, GigaScience, GigaByte, and Data), screened for
relevance with a committed decision sheet. Data papers describe a shared
dataset, so the repository link takes the role that the data
availability statement variables play in `washdev` and `uncnewsletter`.

## Format

### `datapapers`

- paperid:

  ID number of the paper within this dataset

- doi:

  DOI of the data paper

- paper_url:

  Official url of the paper (DOI resolver link)

- url_source:

  Publisher website of the paper

- journal:

  Full name of the journal

- title:

  Title of the paper

- published_year:

  Year of publication

- num_authors:

  Number of the authors

- first_author_name:

  Name of the first author

- first_author_affiliation:

  Academic affiliation of the first author

- first_author_affiliation_country:

  Country of the first author parsed from first_author_affiliation
  variable encoded with United Nations names

- data_repo_url:

  Website urls of the repository holding the dataset the paper
  describes, separated by "; " when there are multiple

- data_repo:

  Name of the data repository (e.g. Zenodo, Dryad, Figshare, OSF,
  Dataverse) parsed from data_repo_url

- license:

  License url of the paper from Crossref metadata

- related_paper_doi:

  DOI of a linked research article, if any (e.g. Data in Brief
  co-submissions), separated by "; " when there are multiple

- abstract:

  Abstract of the paper as provided by the metadata source

- query_term:

  WASH search term(s) that retrieved the paper, separated by "; "

- retrieval_date:

  Date the paper metadata was harvested from the API

## Source

Crossref (<https://api.crossref.org>) and Europe PMC
(<https://europepmc.org>); see `data-raw/README.md` for the pipeline.

## Details

This dataset is frozen. It was harvested once, on 23 July 2026, and its
screening is closed. It is still built with every release but no longer
updated.
