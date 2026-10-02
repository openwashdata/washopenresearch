# Missed Opportunity: where is WASH research data gone?

## Background

In the sector of Water, Sanitation and Hygiene (WASH), very little data
is shared publicly and follows the best practices for reuse. The first
missed opportunity are journal articles and data from researchers which
often involves huge efforts in time, labor, and intelligence. One
strategy to improve this is to implement a **Data Availability
Statement** together with the published journal article. A data
availability statement indicates how the data used in the study is
accessed and shared. For the journal of Water, Sanitation and Hygiene
for Development, 3 options are offered for the authors to decide which
best describes their data:

- All relevant data are included in the paper or its Supplementary
  Information.
- Data cannot be made publicly available; readers should contact the
  corresponding author for details.
- All relevant data are available from an online repository

``` r

# Import useful libraries
## Package installation if you do not have them, uncomment and run the following two lines
## install.packages(c("tidyverse", "devtools", "ggthemes", "gt"))
## devtools::install_github("washopenresearch")
library(washopenresearch)
library(tidyverse)
library(ggthemes)
library(gt)

# This article looks at the articles published from 2011 to 2023. The
# dataset has grown since, so the later years are left out here.
washdev_2023 <- washdev |> 
    filter(published_year <= 2023)
```

Using the dataset `washdev` from the `washopenresearch` data package,
this example investigates the “Data Availability Statement” from 932
articles published in the Journal of Water, Sanitation and Hygiene for
Development from 2011 to 2023.

## Where WASH data is meant to go

The WASH sector has built its own places to put data. Two of them are
the largest. The first is mWater, a free platform where people collect
water, sanitation, and health data with survey tools and can share it.
mWater has run since 2012, covers 198 countries, and holds records for
more than four million sites. The second is Project W, a catalogue built
by the Aquaya Institute that gathers WASH datasets from more than 900
organisations into one searchable place across 190 or more geographies.
mWater generates data. Project W compiles data that already exists.

Both platforms let researchers store or find data, but they document it
unevenly. mWater lets you download record-level data, offers an API, and
provides a data dictionary, so the data can be reused by machine. It
does not assign a license to the shared public data, and it gives
datasets no DOI or version, so a paper cannot cite an mWater dataset the
way it cites a journal article. Project W is harder to assess. It
started as a pilot in 2022 and is still in beta, and it requires a
sign-in, with access granted through a waitlist rather than open
registration. We could not confirm from its public pages whether it
offers downloads, an API, or persistent identifiers. Its terms of use
grant only personal, non-commercial use and set no open license on the
datasets it indexes.

The platforms exist, but WASH authors rarely point to them. We searched
the data availability statements of 1,782 papers in this package (the
`washdev`, `uncnewsletter`, and `ploswater` datasets) for mentions of
thirteen WASH data platforms. Neither mWater nor Project W appears once.
The platforms that do appear are the large household-survey programmes
and general repositories that are not WASH-specific: the Demographic and
Health Surveys (twelve papers), the Humanitarian Data Exchange (three
papers), and the Multiple Indicator Cluster Surveys (two papers). So
when WASH authors do share data through a platform, they reach for a
general one rather than a sector platform. The eight standalone WASH
data papers in the `datapapers` dataset tell the same story: seven
deposit their datasets in general repositories (GBIF, IEEE DataPort,
Figshare, Dryad, NCBI, Zenodo), one shares its data only in the article
tables, and none uses a sector platform, even though these papers exist
for no other reason than to publish a dataset. The sector built mWater
and Project W to hold WASH data, and the published record so far routes
around both. That gap is the missed opportunity this article is about.

## How is WASH research data available in the journal?

In 2020, the journal implemented a policy change to ask for including a
data availability statement (DAS) for publications. In this section, the
goal is to understand the impact of the DAS policy change and the
distribution of different types of DAS.

### 1. Data Preparation

Let’s start by having an overview of the data where we can find relevant
variables like `published_year`, `has_das`, `das_type` to be used for
analysis.

``` r

glimpse(washdev_2023)
#> Rows: 932
#> Columns: 27
#> $ paperid                                   <int> 28742, 28745, 28743, 28744, …
#> $ volume                                    <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
#> $ issue                                     <int> 1, 1, 1, 1, 1, 1, 1, 2, 2, 2…
#> $ paper_url                                 <chr> "https://iwaponline.com/wash…
#> $ journal                                   <chr> "Journal of Water, Sanitatio…
#> $ title                                     <chr> "Editorial", "The sanitation…
#> $ published_year                            <dbl> 2011, 2011, 2011, 2011, 2011…
#> $ is_supp                                   <lgl> FALSE, FALSE, FALSE, TRUE, F…
#> $ num_supp                                  <int> 0, 0, 0, 1, 0, 0, 0, 0, 0, 0…
#> $ supp_file_type                            <chr> NA, NA, NA, "pdf", NA, NA, N…
#> $ supp_url                                  <chr> NA, NA, NA, "https://doi.org…
#> $ num_authors                               <int> 6, 5, 6, 2, 2, 2, 3, 2, 3, 8…
#> $ first_author_name                         <chr> "Jamie Bartram", "E. Kvarnst…
#> $ first_author_affiliation                  <chr> "Journal of Water, Sanitatio…
#> $ first_author_affiliation_country          <chr> NA, "Sweden", "Cameroon", "I…
#> $ first_author_orcid                        <chr> NA, NA, NA, NA, NA, NA, NA, …
#> $ correspondence_author_name                <chr> NA, "E. Kvarnström", "E. Soh…
#> $ correspondence_author_affiliation         <chr> NA, "Stockholm Environment I…
#> $ correspondence_author_affiliation_country <chr> NA, "Sweden", "Cameroon", "I…
#> $ correspondence_author_orcid               <chr> NA, NA, NA, NA, NA, NA, NA, …
#> $ has_das                                   <lgl> FALSE, FALSE, FALSE, FALSE, …
#> $ das                                       <chr> NA, NA, NA, NA, NA, NA, NA, …
#> $ das_type                                  <fct> NA, NA, NA, NA, NA, NA, NA, …
#> $ das_repo_url                              <chr> NA, NA, NA, NA, NA, NA, NA, …
#> $ keywords                                  <chr> NA, "function-based; sanitat…
#> $ doi                                       <chr> "10.2166/washdev.2011.0001",…
#> $ url_source                                <chr> "iwaponline.com", "iwaponlin…
```

We prepare the data by first creating a new variable `das_policy` based
on `published_year` to distinguish whether the publication is before or
after the DAS policy change. Then, we modify the `das_type` to be more
human-readable and add a new type `"missing` for all the publications
that do not have a DAS.

``` r

washdev_das_type <- washdev_2023 |> 
    mutate(das_type = as.character(das_type)) |> 
    mutate(das_policy = case_when(
        published_year < 2020 ~ "pre-2020",
        TRUE ~ "2020 or later"
    )) |> 
    mutate(das_type = case_when(
        das_type == "in paper" ~ "available in paper",
        das_type == "on request" ~ "available on request",
        TRUE ~ das_type
    ))  |>     
    mutate(das_type = case_when(
        is.na(das_type) ~ "missing",
        TRUE ~ das_type
    )) 
```

Now, we can summarize for data availability statement (DAS) type and
policy year.

``` r

washdev_das_type_n <- washdev_das_type |> 
    count(das_policy, das_type) 
washdev_das_type_n
#> # A tibble: 5 × 3
#>   das_policy    das_type                           n
#>   <chr>         <chr>                          <int>
#> 1 2020 or later available in online repository    27
#> 2 2020 or later available in paper               217
#> 3 2020 or later available on request              64
#> 4 2020 or later missing                           61
#> 5 pre-2020      missing                          563
```

### 2. Visualization on Data Availability Statement Types

We use a barplot to visualize the information with the following code.
In addition, we annnotate the policy change to highlight the impact.

``` r

fig_das_type <- washdev_das_type_n |> 
    ggplot(aes(x = reorder(das_type, n), y = n, fill = das_policy)) +
    geom_col(position = position_dodge(), width = 0.6) +
    geom_text(aes(label = n), 
              vjust = 0.5, 
              hjust = -0.5,  
              size = 3,
              position = position_dodge(width = 0.5)
    ) +
    coord_flip() +
    # Add annotation about policy change
    annotate("text", 
             x = 3.77, 
             y = 150, 
             size = 3, 
             label = "after introducing policy\nfor data availability statement", 
             color = "gray20") +
    geom_curve(aes(x = 3.95, y = 142, xend = 3.95, yend = 70), 
               curvature = 0.5, 
               arrow = arrow(type = "closed", length = unit(0.1, "inches")),
               color = "gray20") +
    # Style of the figure
    labs(
        title = "Data Availability Statement",
        subtitle = paste("Analysis of", nrow(washdev_2023), "articles published in Journal of Water, Sanitation and Hygiene for Development (2011 to 2023)"),
        fill = "published year",
        y = "number of publications",
        x = "data availability statement") +
    scale_y_continuous(breaks = seq(0, 600, 100), limits = c(0,600)) +
    scale_fill_colorblind() +
    theme(panel.grid.major.y = element_blank(),
          plot.subtitle = element_text(size = 10))
#> Warning: `scale_fill_colorblind()` was deprecated in ggthemes 5.2.0.
#> This warning is displayed once per session.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.

# https://www.iwapublishing.com/news/iwa-publishing-2020-annual-review
```

``` r

# Display the figure
fig_das_type
```

![](data-availability-washdev_files/figure-html/display_figure-1.png)

- You can see the data availability statements on the vertical axis and
  the number of publications on the horizontal axis

- Colors differentiate between papers published before 2020 and in 2020
  or later, when a policy was introduced that requires authors to select
  one of the three data availability statements

- After that policy was introduced, we still found 17% of papers without
  a data availability statement, while 59% of articles stated that data
  was available in the paper, which could also be as supplementary
  material

## What file types are researchers choosing for supplementary materials?

From the above analysis, we can see that many people opt for data
available within the paper or supplementary materials. What file types
are researchers choosing for supplementary materials? Are they PDF
reports, word documents, or spreadsheets?

Answers to these questions are important to understand the data
accessibility. Data stored and uploaded in pdf reports are less ideal
for reuse and reproducibility. Therefore, in this section, we look at
the supplementary mateirials with the variable `supp_file_type` that
lists out the file types of supplementary materials.

### 1. Data Preparation

We look at the Supplementary Material of all articles published in 2020
or later. In particular, the variable `supp_file_type` stores the file
types of an article as a single string separated by `"; "` when an
article has several files. We use `separate_rows` to expand information
as follows.

``` r

washdev_supp_file_type_n <- washdev_das_type |>
    filter(das_policy == "2020 or later") |>
    select(paperid, das_type, supp_file_type) |>
    separate_rows(supp_file_type, sep = "; ") |>
    mutate(supp_file_type = case_when(
        is.na(supp_file_type) ~ "missing",
        TRUE ~ supp_file_type
    )) |>
    count(das_type, supp_file_type) 
washdev_supp_file_type_n
#> # A tibble: 17 × 3
#>    das_type                       supp_file_type     n
#>    <chr>                          <chr>          <int>
#>  1 available in online repository docx              21
#>  2 available in online repository missing            8
#>  3 available in online repository pdf                2
#>  4 available in online repository xlsx               2
#>  5 available in paper             docx              83
#>  6 available in paper             missing          125
#>  7 available in paper             pdf                7
#>  8 available in paper             png                1
#>  9 available in paper             pptx               4
#> 10 available in paper             xlsx              22
#> 11 available on request           docx              33
#> 12 available on request           missing           29
#> 13 available on request           pdf                2
#> 14 missing                        docx              13
#> 15 missing                        docx, xlsx         4
#> 16 missing                        missing           42
#> 17 missing                        pdf                3
```

### 2. Summary on Supplementary Material File Types

We aggregate each file type to show the distribution of files types used
in the supplementary materials.

``` r

tbl_supp_type <- washdev_supp_file_type_n |> 
    group_by(supp_file_type) |> 
    summarise(n = sum(n)) |> 
    arrange(desc(n)) |> 
    mutate(perc = n / sum(n) * 100) 
```

``` r

# Display the table
tbl_supp_type |> 
    gt() |> 
    tab_header(title = "Supplementary Material",
               subtitle = "Articles published 2020 or later") |>
    tab_style(locations = cells_column_labels(), 
              style = cell_text(weight = "bold")) |>
    fmt_number(columns = c(perc), decimals = 1) |> 
    cols_label(supp_file_type = "file type", n = "n", perc = "%") |> 
    tab_footnote(
        footnote = md("One article can have multiple files."),
        locations = cells_column_labels(columns = n)
        )
```

| Supplementary Material                 |     |      |
|----------------------------------------|-----|------|
| Articles published 2020 or later       |     |      |
| file type                              | n¹  | %    |
| missing                                | 204 | 50.9 |
| docx                                   | 150 | 37.4 |
| xlsx                                   | 24  | 6.0  |
| pdf                                    | 14  | 3.5  |
| docx, xlsx                             | 4   | 1.0  |
| pptx                                   | 4   | 1.0  |
| png                                    | 1   | 0.2  |
| ¹ One article can have multiple files. |     |      |

- Half of the published articles still had no data published alongside
  the article

- But, the most insightful take-away is that not a single file was
  shared in a file type format that would qualify for following FAIR
  principles for data sharing.

- That is something we are hoping to change, where sharing data as CSV
  files would already go a long way.
