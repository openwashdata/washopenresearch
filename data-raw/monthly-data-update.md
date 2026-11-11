The monthly data update: fetch what the journals published since the last release, rebuild the datasets and publish a new version. `data-raw/README.md` describes every step.

## Fetch and build

- [ ] `git switch dev && git pull`
- [ ] Fetch the release tags, which the build compares against: `git fetch origin --tags --force`
- [ ] Restore the pinned packages if `renv.lock` changed, or if `Rscript -e 'renv::load(); renv::status()'` reports packages that are not installed (a new clone, a moved clone, a new R version): `Rscript -e 'renv::load(); renv::restore()'`
- [ ] Fetch what is new, with the machine kept awake: `caffeinate -i Rscript data-raw/update_sources.R ploswater`. The four IWA journals are on hold (see "IWA journals on hold" in `data-raw/README.md`). Do not run the command without a source name until that section says otherwise
- [ ] Read the last rows of `data-raw/update-log.csv`. Run the command again for every journal with `finished` = `FALSE`, at most twice. If a site refuses the client, stop and do not retry
- [ ] Rebuild the datasets: `Rscript data-raw/build.R`
- [ ] Read the diff of the review sheets (`data-raw/*-das-review.csv`, `data-raw/*-country-review.csv`). To act on a row, add it to a decision sheet and rebuild. "Sheets" in `data-raw/README.md` lists the decision sheet of each dataset

## Release

- [ ] Bump the minor version and set the date in `DESCRIPTION`, and the version in `inst/CITATION`
- [ ] Regenerate the documentation and the README: `devtools::document()`, `devtools::build_readme()`
- [ ] Write the changelog entry in `NEWS.md`, with the coverage table from the new README and the rows this run added from `data-raw/update-log.csv`
- [ ] Regenerate the citation metadata: `washr::update_zenodo_json()`, `cffr::cff_write()`
- [ ] Optional preview of the package site: `pkgdown::build_site()`. `docs/` is not committed, and the pkgdown workflow builds and deploys the site after the merge
- [ ] Run the tests of the pipeline code and the package check: `Rscript data-raw/run_tests.R`, `devtools::check()`
- [ ] Commit, then confirm that the committed data follows from the committed inputs: `Rscript data-raw/check_reproducible.R`
- [ ] Push `dev` and open the pull request from `dev` into `main`. Both workflows are green
- [ ] Merge, tag the version and publish the GitHub release
- [ ] Confirm that the new version is on Zenodo under [10.5281/zenodo.11185699](https://doi.org/10.5281/zenodo.11185699)
- [ ] Sync dev with main and push origin/dev
