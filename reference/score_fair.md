# Score a paper's data management against the FAIR principles

Scores each paper on the four FAIR dimensions (Findable, Accessible,
Interoperable, Reusable) from the data-sharing fields the package
already records. Each dimension is scored 0, 1, or 2, and `fair_total`
is their sum (0 to 8). The rubric is deliberately simple and documented
so the scoring is reproducible and open to criticism (issue \#19); it is
a screening instrument, not a certified FAIR assessment.

## Usage

``` r
score_fair(data)
```

## Arguments

- data:

  A data frame with the columns `has_das`, `das_type`, `das_repo_url`,
  `das_repo_name`, and `supp_file_type`. The washdev, uncnewsletter, and
  ploswater datasets all carry these. `das_repo_name` is optional; when
  absent, the repository signal falls back to `das_repo_url`.

## Value

`data` with five integer columns added: `fair_findable`,
`fair_accessible`, `fair_interoperable`, `fair_reusable`, and
`fair_total`.

## Details

The four dimensions are scored as follows.

**Findable** (persistent identifier and registered location):

- 2: the data is in a registered repository (`das_repo_name` is set) and
  a repository link or dataset DOI is present.

- 1: a data location is stated (`das_type` is "available in online
  repository", or a `das_repo_url` is present) but without a recognised
  repository, or the data is in the paper or its supplement.

- 0: no data location (no DAS, "on request", or "not shareable").

**Accessible** (can a reader get the data without a barrier):

- 2: a repository or supplement link is present (`das_repo_url` or
  `supp_url`), so the data is directly retrievable.

- 1: the data is stated to be in the paper or supplement but no link is
  recorded.

- 0: "on request", "not shareable", or no DAS.

**Interoperable** (open, machine-readable shared formats), from
`supp_file_type`:

- 2: any open machine-readable format (csv, txt, tsv, json, xml).

- 1: structured but proprietary formats only (xlsx, docx, sav, dta).

- 0: unstructured only (pdf, images), or no shared files.

**Reusable** (license and repository metadata). Because a license column
is not yet collected for these datasets, this dimension is scored from
the repository signal as a lower bound:

- 2: data in a recognised repository (`das_repo_name` set), which
  normally carries a license and rich metadata.

- 1: a data location is stated but not in a recognised repository.

- 0: no shared data.

When a `license` column is added (see issue \#19), raise this dimension
to use it directly.

Note that Accessible scores the shared files, not the authors' intent. A
paper whose `das_type` is "on request" or "not shareable" can still
score 2 on Accessible if it ships a supplement with a `supp_url`,
because that supplement is directly retrievable. The `das_type` value
stays visible alongside the score, so a restricted-data paper that still
shares a supplement is distinguishable from a fully open one.

## Examples

``` r
scored <- score_fair(ploswater)
table(scored$fair_total)
#> 
#>   0   2   3   4   5   6   7   8 
#>  94  11  27  47 136  45  71   3 
```
