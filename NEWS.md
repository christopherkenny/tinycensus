# tinycensus 0.0.0.9000

* Initial development release.
* Added generic Census API access with `census_get()`.
* Added dataset discovery helpers for datasets, variables, groups, geographies, and examples.
* Added convenience wrappers for ACS, decennial census, population estimates, county business patterns, and time-series datasets.
* Added flexible geography inputs, including state names, abbreviations, and FIPS codes, with county normalization helpers.
* Added optional spatial output through `tinytiger`.
* Added `testthat` and `vcr` test coverage for metadata, tabular queries, input normalization, and geometry workflows.
