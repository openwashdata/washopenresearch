# Classify how a "data in paper" claim is backed by the supplement fields

The stock statement "all relevant data are included in the paper or its
supplementary information" is the modal data availability statement
across the IWA journal snapshots. As a single category it is nearly
uninformative: it covers papers whose complete dataset genuinely fits in
the printed tables as well as papers whose tables hold only summary
statistics (issue \#47). This function scores the claim jointly with the
supplement fields already recorded, so "in paper plus xlsx supplement"
is distinguished from "in paper, nothing attached".

## Usage

``` r
das_in_paper_support(data)
```

## Arguments

- data:

  A data frame with the columns `das_type` and `supp_file_type`.
  `is_supp`, `num_supp`, and `supp_url` are used when present to detect
  supplements with an unknown format. The washdev, uncnewsletter, and
  ploswater datasets and the IWA journal snapshots in `data-raw/` all
  carry these.

## Value

`data` with one character column added: `das_in_paper_support`. `NA` for
papers that do not make the in-paper claim.

## Details

A paper makes the in-paper claim when `das_type` is the normalized value
`"in paper"` (washdev style) or contains the stock phrasing "included in
the paper" / "included in the article" (the IWA journal snapshots keep
the raw sentence in `das_type`). Papers without the claim get `NA`.

Claims are classified by the strongest attachment that could carry the
data, using the same format tiers as
[`score_fair()`](https://github.com/openwashdata/washopenresearch/reference/score_fair.md):

- `"open supplement"`: an open machine-readable format is attached (csv,
  txt, tsv, json, xml).

- `"structured supplement"`: structured but proprietary formats only
  (xlsx, xls, docx, doc, sav, dta, rds, parquet).

- `"unstructured supplement"`: a supplement exists but only as pdf or
  images, or its format is unknown.

- `"no supplement"`: nothing is attached; the claim rests entirely on
  the printed tables and figures.

The classification is structural: it says where the claimed data could
be, not whether it is actually there. Verifying the content of printed
tables and supplement files is the follow-up work in issue \#47.

## Examples

``` r
classified <- das_in_paper_support(washdev)
table(classified$das_in_paper_support, useNA = "ifany")
#> 
#>           no supplement   structured supplement unstructured supplement 
#>                     212                     139                      12 
#>                    <NA> 
#>                     810 
```
