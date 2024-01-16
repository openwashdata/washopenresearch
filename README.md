
<!-- README.md is generated from README.Rmd. Please edit that file -->

# washopenresearch

<!-- badges: start -->
<!-- badges: end -->

The goal of washopenresearch is to provide an overview of open research
data related to Water Sanitation and Hygiene (WASH). The current version
contains two datasets from the following sources:

- `washdev`: Open access journal [*Journal of Water, Sanitation and
  Hygiene for Development*](https://iwaponline.com/washdev)
- `uncnewsletter`: Research section of the newsletter [North Carolina
  Water
  News](https://waterinstitute.unc.edu/our-work/nc-water-news-newsletter)

TODO: A plot here

## Installation

You can install the development version of washopenresearch from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("openwashdata/washopenresearch")
```

Alternatively, you can download the individual datasets as a CSV or XLSX
file from the table below.

    #> Rows: 54 Columns: 5
    #> ── Column specification ────────────────────────────────────────────────────────
    #> Delimiter: ","
    #> chr (5): directory, file_name, variable_name, variable_type, description
    #> 
    #> ℹ Use `spec()` to retrieve the full column specification for this data.
    #> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

| dataset       | CSV                                                                                                      | XLSX                                                                                                       |
|:--------------|:---------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------|
| washdev       | [Download CSV](https://github.com/openwashdata/washopenresearch/raw/main/inst/extdata/washdev.csv)       | [Download XLSX](https://github.com/openwashdata/washopenresearch/raw/main/inst/extdata/washdev.xlsx)       |
| uncnewsletter | [Download CSV](https://github.com/openwashdata/washopenresearch/raw/main/inst/extdata/uncnewsletter.csv) | [Download XLSX](https://github.com/openwashdata/washopenresearch/raw/main/inst/extdata/uncnewsletter.xlsx) |

## Data

The package provides access to two datasets `washdev` and
`uncnewsletter`. Each dataset collects information on scientific
articles about (1) article metadata (e.g. title, first author,
correspondence author), (2)supplementary material information, (3) data
availability statement, and (4) semantic information (e.g. keywords)

``` r
library(washopenresearch)
```

### washdev

The dataset `washdev` contains data on open access articles of the
*Journal of Water, Sanitation & Hygiene for Development* (Vol.1 Issue
1 - Vol.13 Issue 11). It has 924 observations from March 2011 to
November 2023.

### uncnewsletter

The dataset `uncnewsletter` contains data on a curated list of articles
published at the Research section of the newsletter North Carolina Water
News.

## Example

``` r
library(washopenresearch)
## basic example code
```

## License

Data are available as
[CC-BY](https://github.com/openwashdata/wasteskipsblantyre/blob/main/LICENSE.md).

## Citation

Please cite this package using:

``` r
citation("washopenresearch")
#> Warning in citation("washopenresearch"): could not determine year for
#> 'washopenresearch' from package DESCRIPTION file
#> To cite package 'washopenresearch' in publications use:
#> 
#>   Zhong M (????). _washopenresearch: Dataset about open research data
#>   information in Water, Sanitation, and Hygiene_. R package version
#>   0.0.0.9000.
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {washopenresearch: Dataset about open research data information in Water, Sanitation, and Hygiene},
#>     author = {Mian Zhong},
#>     note = {R package version 0.0.0.9000},
#>   }
```
