
<!-- README.md is generated from README.Rmd. Please edit that file -->

# washopenresearch

<!-- badges: start -->

[![License: CC BY
4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

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
correspondence author), (2) supplementary material information, (3) data
availability statement, and (4) semantic information (e.g. keywords)

``` r
library(washopenresearch)
```

### washdev

The dataset `washdev` contains data on open access articles of the
*Journal of Water, Sanitation & Hygiene for Development* (Vol.1 Issue
1 - Vol.13 Issue 11). It has 924 observations from March 2011 to
November 2023.

``` r
washdev |> 
  head() |> 
  gt::gt()
```

<div id="emzvpzfnss" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#emzvpzfnss table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#emzvpzfnss thead, #emzvpzfnss tbody, #emzvpzfnss tfoot, #emzvpzfnss tr, #emzvpzfnss td, #emzvpzfnss th {
  border-style: none;
}
&#10;#emzvpzfnss p {
  margin: 0;
  padding: 0;
}
&#10;#emzvpzfnss .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#emzvpzfnss .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#emzvpzfnss .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#emzvpzfnss .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#emzvpzfnss .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#emzvpzfnss .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#emzvpzfnss .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#emzvpzfnss .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#emzvpzfnss .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#emzvpzfnss .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#emzvpzfnss .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#emzvpzfnss .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#emzvpzfnss .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#emzvpzfnss .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#emzvpzfnss .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#emzvpzfnss .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#emzvpzfnss .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#emzvpzfnss .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#emzvpzfnss .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#emzvpzfnss .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#emzvpzfnss .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#emzvpzfnss .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#emzvpzfnss .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#emzvpzfnss .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#emzvpzfnss .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#emzvpzfnss .gt_left {
  text-align: left;
}
&#10;#emzvpzfnss .gt_center {
  text-align: center;
}
&#10;#emzvpzfnss .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#emzvpzfnss .gt_font_normal {
  font-weight: normal;
}
&#10;#emzvpzfnss .gt_font_bold {
  font-weight: bold;
}
&#10;#emzvpzfnss .gt_font_italic {
  font-style: italic;
}
&#10;#emzvpzfnss .gt_super {
  font-size: 65%;
}
&#10;#emzvpzfnss .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#emzvpzfnss .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#emzvpzfnss .gt_indent_1 {
  text-indent: 5px;
}
&#10;#emzvpzfnss .gt_indent_2 {
  text-indent: 10px;
}
&#10;#emzvpzfnss .gt_indent_3 {
  text-indent: 15px;
}
&#10;#emzvpzfnss .gt_indent_4 {
  text-indent: 20px;
}
&#10;#emzvpzfnss .gt_indent_5 {
  text-indent: 25px;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    &#10;    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="paperid">paperid</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="volume">volume</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="issue">issue</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="url">url</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="journal">journal</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="title">title</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="published_year">published_year</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="is_supp">is_supp</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="num_supp">num_supp</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="supp_file_type">supp_file_type</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="supp_url">supp_url</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="num_authors">num_authors</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_name">first_author_name</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_affiliation">first_author_affiliation</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_affiliation_region">first_author_affiliation_region</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_email">first_author_email</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_orcid">first_author_orcid</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_name">correspondence_author_name</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_affiliation">correspondence_author_affiliation</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_affiliation_region">correspondence_author_affiliation_region</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_email">correspondence_author_email</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_orcid">correspondence_author_orcid</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="has_das">has_das</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="das">das</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="das_type">das_type</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="das_repo_url">das_repo_url</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="keywords">keywords</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="paperid" class="gt_row gt_right">28742</td>
<td headers="volume" class="gt_row gt_right">1</td>
<td headers="issue" class="gt_row gt_right">1</td>
<td headers="url" class="gt_row gt_left">https://iwaponline.com/washdev/article/1/1/1/28742/Editorial</td>
<td headers="journal" class="gt_row gt_left">Journal of Water, Sanitation &amp; Hygiene for Development</td>
<td headers="title" class="gt_row gt_left">Editorial</td>
<td headers="published_year" class="gt_row gt_right">2011</td>
<td headers="is_supp" class="gt_row gt_center">FALSE</td>
<td headers="num_supp" class="gt_row gt_right">0</td>
<td headers="supp_file_type" class="gt_row gt_center">NA</td>
<td headers="supp_url" class="gt_row gt_left">[]</td>
<td headers="num_authors" class="gt_row gt_right">6</td>
<td headers="first_author_name" class="gt_row gt_left">Jamie Bartram</td>
<td headers="first_author_affiliation" class="gt_row gt_left">Journal of Water, Sanitation and Hygiene for Development</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">Sanitation and Hygiene for Development</td>
<td headers="first_author_email" class="gt_row gt_left">NA</td>
<td headers="first_author_orcid" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_name" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_email" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="das_repo_url" class="gt_row gt_left">NA</td>
<td headers="keywords" class="gt_row gt_left">[]</td></tr>
    <tr><td headers="paperid" class="gt_row gt_right">28745</td>
<td headers="volume" class="gt_row gt_right">1</td>
<td headers="issue" class="gt_row gt_right">1</td>
<td headers="url" class="gt_row gt_left">https://iwaponline.com/washdev/article/1/1/3/28745/The-sanitation-ladder-a-need-for-a-revamp</td>
<td headers="journal" class="gt_row gt_left">Journal of Water, Sanitation &amp; Hygiene for Development</td>
<td headers="title" class="gt_row gt_left">The sanitation ladder – a need for a revamp?</td>
<td headers="published_year" class="gt_row gt_right">2011</td>
<td headers="is_supp" class="gt_row gt_center">FALSE</td>
<td headers="num_supp" class="gt_row gt_right">0</td>
<td headers="supp_file_type" class="gt_row gt_center">NA</td>
<td headers="supp_url" class="gt_row gt_left">[]</td>
<td headers="num_authors" class="gt_row gt_right">5</td>
<td headers="first_author_name" class="gt_row gt_left">E. Kvarnström</td>
<td headers="first_author_affiliation" class="gt_row gt_left">Stockholm Environment Institute, Kräftriket 2B, SE-10691 Stockholm, Sweden</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">Sweden</td>
<td headers="first_author_email" class="gt_row gt_left">elisabeth.kvarnstrom@sei.se</td>
<td headers="first_author_orcid" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_name" class="gt_row gt_left">E. Kvarnström</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">Stockholm Environment Institute, Kräftriket 2B, SE-10691 Stockholm, Sweden</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">Sweden</td>
<td headers="correspondence_author_email" class="gt_row gt_left">elisabeth.kvarnstrom@sei.se</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="das_repo_url" class="gt_row gt_left">NA</td>
<td headers="keywords" class="gt_row gt_left">['function-based', 'sanitation technologies', 'sustainability', 'the sanitation ladder']</td></tr>
    <tr><td headers="paperid" class="gt_row gt_right">28743</td>
<td headers="volume" class="gt_row gt_right">1</td>
<td headers="issue" class="gt_row gt_right">1</td>
<td headers="url" class="gt_row gt_left">https://iwaponline.com/washdev/article/1/1/13/28743/Vertical-flow-constructed-wetlands-as-an-emerging</td>
<td headers="journal" class="gt_row gt_left">Journal of Water, Sanitation &amp; Hygiene for Development</td>
<td headers="title" class="gt_row gt_left">Vertical-flow constructed wetlands as an emerging solution for faecal sludge dewatering in developing countries</td>
<td headers="published_year" class="gt_row gt_right">2011</td>
<td headers="is_supp" class="gt_row gt_center">FALSE</td>
<td headers="num_supp" class="gt_row gt_right">0</td>
<td headers="supp_file_type" class="gt_row gt_center">NA</td>
<td headers="supp_url" class="gt_row gt_left">[]</td>
<td headers="num_authors" class="gt_row gt_right">6</td>
<td headers="first_author_name" class="gt_row gt_left">I. M. Kengne</td>
<td headers="first_author_affiliation" class="gt_row gt_left">Laboratory of Plant Biotechnology and Environment, Faculty of Science, University Yaoundé I, PO Box 812, Yaoundé, Cameroon</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">Cameroon</td>
<td headers="first_author_email" class="gt_row gt_left">NA</td>
<td headers="first_author_orcid" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_name" class="gt_row gt_left">E. Soh Kengne</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">Laboratory of Plant Biotechnology and Environment, Faculty of Science, University Yaoundé I, PO Box 812, Yaoundé, Cameroon</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">Cameroon</td>
<td headers="correspondence_author_email" class="gt_row gt_left">ives_kengne@yahoo.fr</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="das_repo_url" class="gt_row gt_left">NA</td>
<td headers="keywords" class="gt_row gt_left">['biosolid accumulation', 'Cyperus papyrus', 'Echinochloa pyramidalis', 'faecal sludge dewatering', 'pollutant removal efficiencies', 'vertical-flow constructed wetlands']</td></tr>
    <tr><td headers="paperid" class="gt_row gt_right">28744</td>
<td headers="volume" class="gt_row gt_right">1</td>
<td headers="issue" class="gt_row gt_right">1</td>
<td headers="url" class="gt_row gt_left">https://iwaponline.com/washdev/article/1/1/20/28744/The-effectiveness-and-sustainability-of-two-demand</td>
<td headers="journal" class="gt_row gt_left">Journal of Water, Sanitation &amp; Hygiene for Development</td>
<td headers="title" class="gt_row gt_left">The effectiveness and sustainability of two demand-driven sanitation and hygiene approaches in Zimbabwe</td>
<td headers="published_year" class="gt_row gt_right">2011</td>
<td headers="is_supp" class="gt_row gt_center">TRUE</td>
<td headers="num_supp" class="gt_row gt_right">1</td>
<td headers="supp_file_type" class="gt_row gt_center">pdf</td>
<td headers="supp_url" class="gt_row gt_left">['https://iwa.silverchair-cdn.com/iwa/content_public/journal/washdev/1/1/10.2166_washdev.2011.015/4/015.pdf?Expires=1706026814&amp;Signature=aK~z72sQJVXyfFFr1x8kN9RfFai9ThHg3Xuauxk4yhZ2TKJ01apTQ20-yTvpmdz5ezdfk8RpPKAfEnMneyaivPS1ZxB1NG9Fl6YR5P6ULq31vJAIlkOtwAFkzjXgjFvZhikW4W7ecfp6fwiPh9k4muyCSc47dVUsVwv~Zj4s8Ap909lcnyQj13Z9wVQce5k2NNNAeEV927OmOpk4D18~3YEZGtZrtjzTzjBvbETyZoCZd6lpPg~1i~N7fAIpunQ~PVEn93~3dyEyaOmvIAgWKFLla-vrOMczNfUOIednf-XOGacBMgJzT2pJKNG0svQv9LChEiXIwtdCNn911zH4yw__&amp;Key-Pair-Id=APKAIE5G5CRDK6RD3PGA']</td>
<td headers="num_authors" class="gt_row gt_right">2</td>
<td headers="first_author_name" class="gt_row gt_left">L. Whaley</td>
<td headers="first_author_affiliation" class="gt_row gt_left">NIWAS (National Institute for Water and Sanitation), Kolakkudipatti, Thottiyam, Trichy District, Tamil Nadu, India. Pin: 621 208</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">India. Pin: 621 208</td>
<td headers="first_author_email" class="gt_row gt_left">lukewhaley1@gmail.com</td>
<td headers="first_author_orcid" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_name" class="gt_row gt_left">L. Whaley</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">NIWAS (National Institute for Water and Sanitation), Kolakkudipatti, Thottiyam, Trichy District, Tamil Nadu, India. Pin: 621 208</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">India. Pin: 621 208</td>
<td headers="correspondence_author_email" class="gt_row gt_left">lukewhaley1@gmail.com</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="das_repo_url" class="gt_row gt_left">NA</td>
<td headers="keywords" class="gt_row gt_left">['behaviour change', 'effectiveness', 'hand washing', 'sanitation', 'sustainability']</td></tr>
    <tr><td headers="paperid" class="gt_row gt_right">28746</td>
<td headers="volume" class="gt_row gt_right">1</td>
<td headers="issue" class="gt_row gt_right">1</td>
<td headers="url" class="gt_row gt_left">https://iwaponline.com/washdev/article/1/1/37/28746/Performance-evaluation-of-different-wastewater</td>
<td headers="journal" class="gt_row gt_left">Journal of Water, Sanitation &amp; Hygiene for Development</td>
<td headers="title" class="gt_row gt_left">Performance evaluation of different wastewater treatment technologies operating in a developing country</td>
<td headers="published_year" class="gt_row gt_right">2011</td>
<td headers="is_supp" class="gt_row gt_center">FALSE</td>
<td headers="num_supp" class="gt_row gt_right">0</td>
<td headers="supp_file_type" class="gt_row gt_center">NA</td>
<td headers="supp_url" class="gt_row gt_left">[]</td>
<td headers="num_authors" class="gt_row gt_right">2</td>
<td headers="first_author_name" class="gt_row gt_left">Sílvia C. Oliveira</td>
<td headers="first_author_affiliation" class="gt_row gt_left">Department of Sanitary and Environmental Engineering, Federal University of Minas Gerais, Av. Antônio Carlos 6627 – Escola de Engenharia, Bloco 1 – sala 4622, 31270-901 – Belo Horizonte, Brazil</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">Brazil</td>
<td headers="first_author_email" class="gt_row gt_left">silvia@desa.ufmg.br</td>
<td headers="first_author_orcid" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_name" class="gt_row gt_left">Sílvia C. Oliveira</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">Department of Sanitary and Environmental Engineering, Federal University of Minas Gerais, Av. Antônio Carlos 6627 – Escola de Engenharia, Bloco 1 – sala 4622, 31270-901 – Belo Horizonte, Brazil</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">Brazil</td>
<td headers="correspondence_author_email" class="gt_row gt_left">silvia@desa.ufmg.br</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="das_repo_url" class="gt_row gt_left">NA</td>
<td headers="keywords" class="gt_row gt_left">['developing countries', 'effluent quality', 'performance evaluation', 'wastewater treatment']</td></tr>
    <tr><td headers="paperid" class="gt_row gt_right">28747</td>
<td headers="volume" class="gt_row gt_right">1</td>
<td headers="issue" class="gt_row gt_right">1</td>
<td headers="url" class="gt_row gt_left">https://iwaponline.com/washdev/article/1/1/57/28747/Impact-of-a-natural-coagulant-pretreatment-for</td>
<td headers="journal" class="gt_row gt_left">Journal of Water, Sanitation &amp; Hygiene for Development</td>
<td headers="title" class="gt_row gt_left">Impact of a natural coagulant pretreatment for colour removal on solar water disinfection (SODIS)</td>
<td headers="published_year" class="gt_row gt_right">2011</td>
<td headers="is_supp" class="gt_row gt_center">FALSE</td>
<td headers="num_supp" class="gt_row gt_right">0</td>
<td headers="supp_file_type" class="gt_row gt_center">NA</td>
<td headers="supp_url" class="gt_row gt_left">[]</td>
<td headers="num_authors" class="gt_row gt_right">2</td>
<td headers="first_author_name" class="gt_row gt_left">Sarah A. Wilson</td>
<td headers="first_author_affiliation" class="gt_row gt_left">Department of Civil Engineering, University of Toronto, 35 St George Street, Toronto, Ontario, M5S 1A4, Canada</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">Canada</td>
<td headers="first_author_email" class="gt_row gt_left">sarahanne.wilson@gmail.com</td>
<td headers="first_author_orcid" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_name" class="gt_row gt_left">Sarah A. Wilson</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">Department of Civil Engineering, University of Toronto, 35 St George Street, Toronto, Ontario, M5S 1A4, Canada</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">Canada</td>
<td headers="correspondence_author_email" class="gt_row gt_left">sarahanne.wilson@gmail.com</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="das_repo_url" class="gt_row gt_left">NA</td>
<td headers="keywords" class="gt_row gt_left">['drinking water', 'E. coli', 'Moringa oleifera', 'point of use', 'pretreatment', 'solar disinfection']</td></tr>
  </tbody>
  &#10;  
</table>
</div>

For an overview of the variable names, see the following table.

<div style="border: 1px solid #ddd; padding: 0px; overflow-y: scroll; height:400px; ">

<table class="table" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;">
variable_name
</th>
<th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;">
variable_type
</th>
<th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;">
description
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
paperid
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
ID number of the paper on the journal website
</td>
</tr>
<tr>
<td style="text-align:left;">
volume
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Volume number of the journal
</td>
</tr>
<tr>
<td style="text-align:left;">
issue
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Issue number of the journal
</td>
</tr>
<tr>
<td style="text-align:left;">
url
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Official website url of the paper
</td>
</tr>
<tr>
<td style="text-align:left;">
journal
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Full name of the journal
</td>
</tr>
<tr>
<td style="text-align:left;">
title
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Title of the paper
</td>
</tr>
<tr>
<td style="text-align:left;">
published_year
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Year of publication
</td>
</tr>
<tr>
<td style="text-align:left;">
is_supp
</td>
<td style="text-align:left;">
logical
</td>
<td style="text-align:left;">
Whether the paper has supplementary materials
</td>
</tr>
<tr>
<td style="text-align:left;">
num_supp
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Number of supplementary material files
</td>
</tr>
<tr>
<td style="text-align:left;">
supp_file_type
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
File type of the supplementary materials
</td>
</tr>
<tr>
<td style="text-align:left;">
supp_url
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Website url of the supplementary materials
</td>
</tr>
<tr>
<td style="text-align:left;">
num_authors
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Number of the authors
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_name
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Name of the first author
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_affiliation
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Academic affiliation of the first author
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_affiliation_region
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Country or region of the first author parsed from
first_author_affiliation variable
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_email
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Email of the first author
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_orcid
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
ORCID of the first author
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_name
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Name of the correspondence author
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_affiliation
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Academic affiliation of the correspondence author
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_affiliation_region
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Country or region of the correspondence author parsed from
correspondence_author_affiliation variable
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_email
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Email of the correspondence author
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_orcid
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
ORCID of the correspondence author
</td>
</tr>
<tr>
<td style="text-align:left;">
has_das
</td>
<td style="text-align:left;">
logical
</td>
<td style="text-align:left;">
Whether the paper has a data availability statement
</td>
</tr>
<tr>
<td style="text-align:left;">
das
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Original data availability statement of the paper
</td>
</tr>
<tr>
<td style="text-align:left;">
das_type
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:left;">
Type of the data availability statement \#todo
</td>
</tr>
<tr>
<td style="text-align:left;">
das_repo_url
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Website url of the data if the relevant data of the paper is shared on a
public repository
</td>
</tr>
<tr>
<td style="text-align:left;">
keywords
</td>
<td style="text-align:left;">
vector
</td>
<td style="text-align:left;">
List of keywords of the paper
</td>
</tr>
</tbody>
</table>

</div>

### uncnewsletter

The dataset `uncnewsletter` contains data on a curated list of articles
published at the Research section of the newsletter North Carolina Water
News.

``` r
uncnewsletter |> 
  head() |> 
  gt::gt()
```

<div id="imatvkqzfc" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#imatvkqzfc table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#imatvkqzfc thead, #imatvkqzfc tbody, #imatvkqzfc tfoot, #imatvkqzfc tr, #imatvkqzfc td, #imatvkqzfc th {
  border-style: none;
}
&#10;#imatvkqzfc p {
  margin: 0;
  padding: 0;
}
&#10;#imatvkqzfc .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#imatvkqzfc .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#imatvkqzfc .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#imatvkqzfc .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#imatvkqzfc .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#imatvkqzfc .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#imatvkqzfc .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#imatvkqzfc .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#imatvkqzfc .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#imatvkqzfc .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#imatvkqzfc .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#imatvkqzfc .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#imatvkqzfc .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#imatvkqzfc .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#imatvkqzfc .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#imatvkqzfc .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#imatvkqzfc .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#imatvkqzfc .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#imatvkqzfc .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#imatvkqzfc .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#imatvkqzfc .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#imatvkqzfc .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#imatvkqzfc .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#imatvkqzfc .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#imatvkqzfc .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#imatvkqzfc .gt_left {
  text-align: left;
}
&#10;#imatvkqzfc .gt_center {
  text-align: center;
}
&#10;#imatvkqzfc .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#imatvkqzfc .gt_font_normal {
  font-weight: normal;
}
&#10;#imatvkqzfc .gt_font_bold {
  font-weight: bold;
}
&#10;#imatvkqzfc .gt_font_italic {
  font-style: italic;
}
&#10;#imatvkqzfc .gt_super {
  font-size: 65%;
}
&#10;#imatvkqzfc .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#imatvkqzfc .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#imatvkqzfc .gt_indent_1 {
  text-indent: 5px;
}
&#10;#imatvkqzfc .gt_indent_2 {
  text-indent: 10px;
}
&#10;#imatvkqzfc .gt_indent_3 {
  text-indent: 15px;
}
&#10;#imatvkqzfc .gt_indent_4 {
  text-indent: 20px;
}
&#10;#imatvkqzfc .gt_indent_5 {
  text-indent: 25px;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    &#10;    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="paper_id">paper_id</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="issue_url">issue_url</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="paper_url">paper_url</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="url_source">url_source</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="journal">journal</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="title">title</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="published_year">published_year</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="is_supp">is_supp</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="num_supp">num_supp</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="supp_file_type">supp_file_type</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="supp_link">supp_link</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="num_authors">num_authors</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_name">first_author_name</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_affiliation">first_author_affiliation</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_affiliation_region">first_author_affiliation_region</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_email">first_author_email</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="first_author_orcid">first_author_orcid</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_name">correspondence_author_name</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_affiliation">correspondence_author_affiliation</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_affiliation_region">correspondence_author_affiliation_region</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_email">correspondence_author_email</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="correspondence_author_orcid">correspondence_author_orcid</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_center" rowspan="1" colspan="1" scope="col" id="has_das">has_das</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="das">das</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="das_type">das_type</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="citations">citations</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="keywords">keywords</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="paper_id" class="gt_row gt_right">198</td>
<td headers="issue_url" class="gt_row gt_left">http://eepurl.com/hWz3Yf</td>
<td headers="paper_url" class="gt_row gt_left">https://aiche.onlinelibrary.wiley.com/doi/abs/10.1002/ep.13800</td>
<td headers="url_source" class="gt_row gt_left">aiche.onlinelibrary.wiley.com</td>
<td headers="journal" class="gt_row gt_left">Environmental Progress &amp; Sustainable Energy</td>
<td headers="title" class="gt_row gt_left">Mitigation of PFAS in U.S. Public Water Systems: Future steps for ensuring safer drinking water</td>
<td headers="published_year" class="gt_row gt_right">2022</td>
<td headers="is_supp" class="gt_row gt_center">TRUE</td>
<td headers="num_supp" class="gt_row gt_right">1</td>
<td headers="supp_file_type" class="gt_row gt_left">docx</td>
<td headers="supp_link" class="gt_row gt_left">https://aiche.onlinelibrary.wiley.com/action/downloadSupplement?doi=10.1002%2Fep.13800&amp;file=ep13800-sup-0001-Supinfo.docx</td>
<td headers="num_authors" class="gt_row gt_right">1</td>
<td headers="first_author_name" class="gt_row gt_left">Alexis Voulgaropoulos</td>
<td headers="first_author_affiliation" class="gt_row gt_left">North Carolina State University</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">USA</td>
<td headers="first_author_email" class="gt_row gt_left">anvoulga@ncsu.edu</td>
<td headers="first_author_orcid" class="gt_row gt_left">0000-0002-5778-354X</td>
<td headers="correspondence_author_name" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_email" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="citations" class="gt_row gt_right">2</td>
<td headers="keywords" class="gt_row gt_left">["drinking water", "environmental policy", "health and safety"]</td></tr>
    <tr><td headers="paper_id" class="gt_row gt_right">89</td>
<td headers="issue_url" class="gt_row gt_left">http://eepurl.com/ieh0rf</td>
<td headers="paper_url" class="gt_row gt_left">https://ajph.aphapublications.org/doi/abs/10.2105/AJPH.2022.307108</td>
<td headers="url_source" class="gt_row gt_left">ajph.aphapublications.org</td>
<td headers="journal" class="gt_row gt_left">American Journal of Public Health</td>
<td headers="title" class="gt_row gt_left">Timing and Trends for Municipal Wastewater, Lab-Confirmed Case, and Syndromic Case Surveillance of COVID-19 in Raleigh, North Carolina</td>
<td headers="published_year" class="gt_row gt_right">2023</td>
<td headers="is_supp" class="gt_row gt_center">TRUE</td>
<td headers="num_supp" class="gt_row gt_right">1</td>
<td headers="supp_file_type" class="gt_row gt_left">docx</td>
<td headers="supp_link" class="gt_row gt_left">https://ajph.aphapublications.org/doi/suppl/10.2105/AJPH.2022.307108/suppl_file/kotlarz_suppl-figures_tables.docx</td>
<td headers="num_authors" class="gt_row gt_right">17</td>
<td headers="first_author_name" class="gt_row gt_left">Nadine Kotlarz</td>
<td headers="first_author_affiliation" class="gt_row gt_left">North Carolina State University</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">USA</td>
<td headers="first_author_email" class="gt_row gt_left">nkotlar@ncsu.ede</td>
<td headers="first_author_orcid" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_name" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_email" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="citations" class="gt_row gt_right">3</td>
<td headers="keywords" class="gt_row gt_left">NA</td></tr>
    <tr><td headers="paper_id" class="gt_row gt_right">200</td>
<td headers="issue_url" class="gt_row gt_left">http://eepurl.com/hWz3Yf</td>
<td headers="paper_url" class="gt_row gt_left">https://aslopubs.onlinelibrary.wiley.com/doi/abs/10.1002/lom3.10469</td>
<td headers="url_source" class="gt_row gt_left">aslopubs.onlinelibrary.wiley.com</td>
<td headers="journal" class="gt_row gt_left">Limnology and Oceanography: Methods</td>
<td headers="title" class="gt_row gt_left">OpenOBS: Open-source, low-cost optical backscatter sensors for water quality and sediment-transport research</td>
<td headers="published_year" class="gt_row gt_right">2022</td>
<td headers="is_supp" class="gt_row gt_center">TRUE</td>
<td headers="num_supp" class="gt_row gt_right">1</td>
<td headers="supp_file_type" class="gt_row gt_left">pdf</td>
<td headers="supp_link" class="gt_row gt_left">https://aslopubs.onlinelibrary.wiley.com/action/downloadSupplement?doi=10.1002%2Flom3.10469&amp;file=lom310469-sup-0001-Supinfo.pdf</td>
<td headers="num_authors" class="gt_row gt_right">4</td>
<td headers="first_author_name" class="gt_row gt_left">Emily F. Eidam</td>
<td headers="first_author_affiliation" class="gt_row gt_left">University of North Carolina</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">USA</td>
<td headers="first_author_email" class="gt_row gt_left">efe@unc.edu</td>
<td headers="first_author_orcid" class="gt_row gt_left">0000-0002-1906-8692</td>
<td headers="correspondence_author_name" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_email" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">TRUE</td>
<td headers="das" class="gt_row gt_left">The code, wiring diagram, hardware bill of materials, and 3D-printed endcap design files are available at https://github.com/tedlanghorst/OpenOBS.</td>
<td headers="das_type" class="gt_row gt_left">available in online repository</td>
<td headers="citations" class="gt_row gt_right">4</td>
<td headers="keywords" class="gt_row gt_left">NA</td></tr>
    <tr><td headers="paper_id" class="gt_row gt_right">77</td>
<td headers="issue_url" class="gt_row gt_left">http://eepurl.com/iiETVr</td>
<td headers="paper_url" class="gt_row gt_left">https://bioone.org/journals/journal-of-coastal-research/volume-39/issue-1/JCOASTRES-D-22-00047.1/Propagation-Characteristics-of-Seismic-Waves-in-Shallow-Sea-Sedimentary-Layers/10.2112/JCOASTRES-D-22-00047.1.short</td>
<td headers="url_source" class="gt_row gt_left">bioone.org</td>
<td headers="journal" class="gt_row gt_left">Journal of Coastal Research</td>
<td headers="title" class="gt_row gt_left">Propagation Characteristics of Seismic Waves in Shallow Sea Sedimentary Layers</td>
<td headers="published_year" class="gt_row gt_right">2023</td>
<td headers="is_supp" class="gt_row gt_center">FALSE</td>
<td headers="num_supp" class="gt_row gt_right">NA</td>
<td headers="supp_file_type" class="gt_row gt_left">NA</td>
<td headers="supp_link" class="gt_row gt_left">NA</td>
<td headers="num_authors" class="gt_row gt_right">5</td>
<td headers="first_author_name" class="gt_row gt_left">Shuang Zhao</td>
<td headers="first_author_affiliation" class="gt_row gt_left">Shenyang Ligong University</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">China</td>
<td headers="first_author_email" class="gt_row gt_left">zslg@sylu.edu.cn</td>
<td headers="first_author_orcid" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_name" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_email" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="citations" class="gt_row gt_right">0</td>
<td headers="keywords" class="gt_row gt_left">NA</td></tr>
    <tr><td headers="paper_id" class="gt_row gt_right">81</td>
<td headers="issue_url" class="gt_row gt_left">http://eepurl.com/ieh0rf</td>
<td headers="paper_url" class="gt_row gt_left">https://elibrary.asabe.org/abstract.asp?aid=53682</td>
<td headers="url_source" class="gt_row gt_left">elibrary.asabe.org</td>
<td headers="journal" class="gt_row gt_left">Journal of the American Society of Agricultural and Biological Engineers</td>
<td headers="title" class="gt_row gt_left">Evaluating the Occurrence and Relative Abundance of Mosquitoes in Rainwater Harvesting Systems</td>
<td headers="published_year" class="gt_row gt_right">2022</td>
<td headers="is_supp" class="gt_row gt_center">FALSE</td>
<td headers="num_supp" class="gt_row gt_right">NA</td>
<td headers="supp_file_type" class="gt_row gt_left">NA</td>
<td headers="supp_link" class="gt_row gt_left">NA</td>
<td headers="num_authors" class="gt_row gt_right">7</td>
<td headers="first_author_name" class="gt_row gt_left">Kathy DeBusk Gee</td>
<td headers="first_author_affiliation" class="gt_row gt_left">Longwood University</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">USA</td>
<td headers="first_author_email" class="gt_row gt_left">geekd@longwood.edu</td>
<td headers="first_author_orcid" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_name" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_email" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">FALSE</td>
<td headers="das" class="gt_row gt_left">NA</td>
<td headers="das_type" class="gt_row gt_left">NA</td>
<td headers="citations" class="gt_row gt_right">0</td>
<td headers="keywords" class="gt_row gt_left">["Container breeding", "Mosquito", "Mosquito larvae", "Rainwater harvesting"]</td></tr>
    <tr><td headers="paper_id" class="gt_row gt_right">97</td>
<td headers="issue_url" class="gt_row gt_left">http://eepurl.com/icBZuL</td>
<td headers="paper_url" class="gt_row gt_left">https://esajournals.onlinelibrary.wiley.com/doi/abs/10.1002/eap.2766</td>
<td headers="url_source" class="gt_row gt_left">esajournals.onlinelibrary.wiley.com</td>
<td headers="journal" class="gt_row gt_left">Ecological Applications</td>
<td headers="title" class="gt_row gt_left">Integrating Principles and Tools of Decision Science into Value-Driven Watershed Planning for Compensatory Mitigation</td>
<td headers="published_year" class="gt_row gt_right">2023</td>
<td headers="is_supp" class="gt_row gt_center">FALSE</td>
<td headers="num_supp" class="gt_row gt_right">NA</td>
<td headers="supp_file_type" class="gt_row gt_left">NA</td>
<td headers="supp_link" class="gt_row gt_left">NA</td>
<td headers="num_authors" class="gt_row gt_right">7</td>
<td headers="first_author_name" class="gt_row gt_left">Georgina M. Sanchez</td>
<td headers="first_author_affiliation" class="gt_row gt_left">North Carolina State University</td>
<td headers="first_author_affiliation_region" class="gt_row gt_left">USA</td>
<td headers="first_author_email" class="gt_row gt_left">gmsanche@ncsu.edu</td>
<td headers="first_author_orcid" class="gt_row gt_left">0000-0002-2365-6200</td>
<td headers="correspondence_author_name" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_affiliation_region" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_email" class="gt_row gt_left">NA</td>
<td headers="correspondence_author_orcid" class="gt_row gt_left">NA</td>
<td headers="has_das" class="gt_row gt_center">TRUE</td>
<td headers="das" class="gt_row gt_left">Cape Fear River Basin (eight-digit Hydrologic Unit Code 03030002) data sets utilized for this research are as follows: NCDMS Tier 1 project sites implemented prior to December 2015 (Division of Mitigation Services, 2019) available from the North Carolina Department of Environmental Quality at https://deq.nc.gov/about/divisions/mitigation-services/dms-planning/dms-web-map; parcel data (NC OneMap Geospatial Portal, 2019) available from NC OneMap at https://www.nconemap.gov/; land-use/land-cover data (Dewitz, 2019) available from the USGS ScienceBase at https://doi.org/10.5066/P96HHBIE; total phosphorus loads (Gurley et al., 2019) available from the USGS ScienceBase at https://doi.org/10.5066/P9UUT74V; hydric soils (Soil Survey Staff, 2019) available from the USDA Natural Resources Conservation Service at https://websoilsurvey.nrcs.usda.gov/; future development probability (Sanchez et al., 2020b) available from the USGS ScienceBase at https://doi.org/10.5066/P95PTP5G.</td>
<td headers="das_type" class="gt_row gt_left">available in online repository</td>
<td headers="citations" class="gt_row gt_right">NA</td>
<td headers="keywords" class="gt_row gt_left">["compensatory mitigation", "decision science", "knowledge coproduction", "natural resources management", "research-management partnerships", "watershed planning"]</td></tr>
  </tbody>
  &#10;  
</table>
</div>

For an overview of the variable descriptions, see the following table.

<div style="border: 1px solid #ddd; padding: 0px; overflow-y: scroll; height:400px; ">

<table class="table" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;">
variable_name
</th>
<th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;">
variable_type
</th>
<th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;">
description
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
paperid
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
ID number of the paper on the journal website
</td>
</tr>
<tr>
<td style="text-align:left;">
volume
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Volume number of the journal
</td>
</tr>
<tr>
<td style="text-align:left;">
issue
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Issue number of the journal
</td>
</tr>
<tr>
<td style="text-align:left;">
url
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Official website url of the paper
</td>
</tr>
<tr>
<td style="text-align:left;">
journal
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Full name of the journal
</td>
</tr>
<tr>
<td style="text-align:left;">
title
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Title of the paper
</td>
</tr>
<tr>
<td style="text-align:left;">
published_year
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Year of publication
</td>
</tr>
<tr>
<td style="text-align:left;">
is_supp
</td>
<td style="text-align:left;">
logical
</td>
<td style="text-align:left;">
Whether the paper has supplementary materials
</td>
</tr>
<tr>
<td style="text-align:left;">
num_supp
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Number of supplementary material files
</td>
</tr>
<tr>
<td style="text-align:left;">
supp_file_type
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
File type of the supplementary materials
</td>
</tr>
<tr>
<td style="text-align:left;">
supp_url
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Website url of the supplementary materials
</td>
</tr>
<tr>
<td style="text-align:left;">
num_authors
</td>
<td style="text-align:left;">
integer
</td>
<td style="text-align:left;">
Number of the authors
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_name
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Name of the first author
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_affiliation
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Academic affiliation of the first author
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_affiliation_region
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Country or region of the first author parsed from
first_author_affiliation variable
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_email
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Email of the first author
</td>
</tr>
<tr>
<td style="text-align:left;">
first_author_orcid
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
ORCID of the first author
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_name
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Name of the correspondence author
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_affiliation
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Academic affiliation of the correspondence author
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_affiliation_region
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Country or region of the correspondence author parsed from
correspondence_author_affiliation variable
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_email
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Email of the correspondence author
</td>
</tr>
<tr>
<td style="text-align:left;">
correspondence_author_orcid
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
ORCID of the correspondence author
</td>
</tr>
<tr>
<td style="text-align:left;">
has_das
</td>
<td style="text-align:left;">
logical
</td>
<td style="text-align:left;">
Whether the paper has a data availability statement
</td>
</tr>
<tr>
<td style="text-align:left;">
das
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Original data availability statement of the paper
</td>
</tr>
<tr>
<td style="text-align:left;">
das_type
</td>
<td style="text-align:left;">
factor
</td>
<td style="text-align:left;">
Type of the data availability statement \#todo
</td>
</tr>
<tr>
<td style="text-align:left;">
das_repo_url
</td>
<td style="text-align:left;">
character
</td>
<td style="text-align:left;">
Website url of the data if the relevant data of the paper is shared on a
public repository
</td>
</tr>
<tr>
<td style="text-align:left;">
keywords
</td>
<td style="text-align:left;">
vector
</td>
<td style="text-align:left;">
List of keywords of the paper
</td>
</tr>
</tbody>
</table>

</div>

## Example

What are the top 10 countries(or regions) the first authors from?

``` r
library(washopenresearch)

washdev |> 
  group_by(first_author_affiliation_region) |>
  summarise(count=n()) |>
  arrange(desc(count)) |>
  head(10) |>
  ggplot() +
    geom_bar(aes(x = first_author_affiliation_region, y = count), stat = "identity")
```

<img src="man/figures/README-unnamed-chunk-8-1.png" width="100%" />

What are the top choices of keywords in WASH Dev?

Each publication may provide a list of keywords, typically 5-7, to
summarize the topics of the article. Here we compile all keywords and
calculate their frequency to be used.

``` r
keywords_freq <- washdev$keywords |>
    purrr::map(function(x) str_extract_all(x, pattern = "(?<=')[^',]*?(?='\\s*)")[[1]]) |>
    unlist() |>
    str_to_lower() |>
  table() |>
  as.data.frame() |>
  as_tibble() |>
  arrange(desc(Freq))

# Top 30 keywords
ggplot(data = head(keywords_freq, 30)) +
  geom_bar(aes(x = reorder(Var1, Freq), y=Freq), stat = "identity") +
  coord_flip() +
  labs(x = "Keywords", y = "Count")
```

<img src="man/figures/README-unnamed-chunk-9-1.png" width="100%" />

## License

Data are available as
[CC-BY](https://github.com/openwashdata/wasteskipsblantyre/blob/main/LICENSE.md).

## Citation

Please cite this package using:

``` r
citation("washopenresearch")
#> To cite package 'washopenresearch' in publications use:
#> 
#>   Zhong M (2024). _washopenresearch: Dataset about open research data
#>   information in Water, Sanitation, and Hygiene_. R package version
#>   0.0.1.
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {washopenresearch: Dataset about open research data information in Water, Sanitation, and Hygiene},
#>     author = {Mian Zhong},
#>     year = {2024},
#>     note = {R package version 0.0.1},
#>   }
```
