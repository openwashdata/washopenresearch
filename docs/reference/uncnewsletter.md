# Dataset about data availability in the UNC Water Newsletter

Dataset about data availability in the UNC Water Newsletter

## Usage

``` r
uncnewsletter
```

## Format

### `uncnewsletter`

- url_source:

  Publisher website of the paper

- paperid:

  ID number of the paper on the journal website

- issue_url:

  Volume number of the journal

- paper_url:

  Official website url of the paper

- url_source:

  Publisher website of the paper

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
  there are multiple

- num_authors:

  Number of the authors

- first_author_name:

  Name of the first author

- first_author_affiliation:

  Academic affiliation of the first author

- first_author_affiliation_country:

  Country of the first author directly parsed from
  first_author_affiliation variable encoded with United Nation names

- first_author_email:

  Email of the first author

- first_author_orcid:

  ORCID of the first author

- correspondence_author_name:

  Name of the correspondence author

- correspondence_author_affiliation:

  Academic affiliation of the correspondence author

- correspondence_author_affiliation_country:

  Country or region of the correspondence author directly parsed from
  correspondence_author_affiliation variable encoded with United Nation
  names

- correspondence_author_email:

  Email of the correspondence author

- correspondence_author_orcid:

  ORCID of the correspondence author

- has_das:

  Whether the paper has a data availability statement

- das:

  Original data availability statement of the paper. NA if it does not
  have a data availability statement.

- das_type:

  Type of the data availability statement including in paper(data in
  full paper scope like supplementary material or appendix or main
  content) on request(data available on request to the authors)
  available in online repository(data is shared in a public online
  repository) not shareable(data is not shareable). NA if it does not
  have a data availability statement.

- das_repo_url:

  Website urls of the data if the relevant data of the paper is shared
  on a public repository, separated by "; " when there are multiple

- keywords:

  Keywords of the paper, separated by "; "
