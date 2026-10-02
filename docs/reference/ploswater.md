# Dataset about data availability in PLOS Water

Article metadata for all articles published in PLOS Water since its
first volume (2022), collected through the public PLOS search API and
each article's JATS XML. Data availability statements are mandatory at
PLOS, so `has_das` is TRUE for research articles throughout; the
interesting variation lies in `das_type`, `das_repo_url`, and
`das_repo_name`. All article types are included; use `article_type` to
restrict to research articles.

## Usage

``` r
ploswater
```

## Format

### `ploswater`

- paperid:

  DOI of the paper, identical to the doi variable

- volume:

  Volume number of the journal; volume 1 is 2022

- issue:

  Issue number of the journal

- paper_url:

  Official website url of the paper

- journal:

  Full name of the journal

- title:

  Title of the paper

- published_year:

  Year of publication

- is_supp:

  Whether the paper has supplementary materials

- num_supp:

  Number of supplementary material files

- supp_file_type:

  File types of the supplementary materials, separated by "; " when
  there are multiple

- supp_url:

  Website urls of the supplementary materials, separated by "; " when
  there are multiple. These links are stable download endpoints, they do
  not expire.

- num_authors:

  Number of the authors

- first_author_name:

  Name of the first author

- first_author_affiliation:

  Academic affiliation of the first author

- first_author_affiliation_country:

  Country of the first author parsed from first_author_affiliation,
  encoded with United Nations names

- first_author_orcid:

  ORCID of the first author

- correspondence_author_name:

  Name of the correspondence author

- correspondence_author_affiliation:

  Academic affiliation of the correspondence author

- correspondence_author_affiliation_country:

  Country of the correspondence author parsed from
  correspondence_author_affiliation, encoded with United Nations names

- correspondence_author_orcid:

  ORCID of the correspondence author

- has_das:

  Whether the paper has a data availability statement

- das:

  Original data availability statement of the paper. NA if it does not
  have a data availability statement.

- das_type:

  Type of the data availability statement including available in online
  repository(data is shared in a public online repository) in paper(data
  in full paper scope like supplementary material or appendix or main
  content) on request(data available on request to the authors) not
  shareable(data is not shareable) no data generated(the study produced
  no datasets). NA if it does not have a data availability statement or
  no classification rule matched.

- das_repo_url:

  Website urls and dataset DOIs mentioned in the data availability
  statement, separated by "; " when there are multiple

- das_repo_name:

  Recognized data repositories behind das_repo_url (e.g. zenodo, dryad,
  figshare, osf, github, dataverse), separated by "; " when there are
  multiple

- keywords:

  Subject terms of the paper from the PLOS search API, separated by ";
  ". PLOS Water articles carry no author keywords in their XML.

- url_source:

  Publisher website of the paper

- doi:

  DOI of the paper

- article_type:

  Article type, e.g. "Research Article", "Opinion", "Review"

- publication_date:

  Date of publication (ISO 8601)

## Details

The dataset is updated monthly. Each data release adds the articles
published since the last one.
