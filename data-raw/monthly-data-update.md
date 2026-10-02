The monthly data update: fetch what the journals published since the last release, rebuild the datasets and publish a new version. `data-raw/README.md` describes every step.

## Fetch and build

- [ ] `git switch dev && git pull`
- [ ] Restore the pinned packages if `renv.lock` changed: `Rscript -e 'renv::load(); renv::restore()'`
- [ ] Fetch what is new, with the machine kept awake: `caffeinate -i Rscript data-raw/update_sources.R`
- [ ] Read the last rows of `data-raw/update-log.csv`. Run the command again for every journal with `finished` = `FALSE`
- [ ] Rebuild the datasets: `Rscript data-raw/build.R`
- [ ] Read the diff of the review sheets (`data-raw/*-das-review.csv`, `data-raw/*-country-review.csv`). To act on a row, add it to a decision sheet and rebuild

## Release

- [ ] Bump the minor version and set the date in `DESCRIPTION`, and the version in `inst/CITATION`
- [ ] Regenerate the documentation and the README: `devtools::document()`, `devtools::build_readme()`
- [ ] Write the changelog entry in `NEWS.md`, with the coverage table from the new README and the rows this run added from `data-raw/update-log.csv`
- [ ] Regenerate the citation metadata: `washr::update_zenodo_json()`, `cffr::cff_write()`
- [ ] Rebuild the package site: `pkgdown::build_site()`. Keep `docs/agents/`
- [ ] Run the tests of the pipeline code and the package check: `Rscript data-raw/run_tests.R`, `devtools::check()`
- [ ] Commit, then confirm that the committed data follows from the committed inputs: `Rscript data-raw/check_reproducible.R`
- [ ] Push `dev` and open the pull request from `dev` into `main`. Both workflows are green
- [ ] Merge, tag the version and publish the GitHub release
- [ ] Confirm that the new version is on Zenodo under [10.5281/zenodo.11185699](https://doi.org/10.5281/zenodo.11185699)
- [ ] Sync dev with main and push origin/dev
