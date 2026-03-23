# Retrieve Population Estimates Program data

Retrieve Population Estimates Program data

## Usage

``` r
tc_get_pep(
  geography = NULL,
  variables = NULL,
  table = NULL,
  year,
  dataset = NULL,
  product = NULL,
  breakdown = NULL,
  within = NULL,
  predicates = NULL,
  breakdown_labels = FALSE,
  summary_var = NULL,
  geometry = FALSE,
  keep_geo_vars = FALSE,
  key = tc_get_key(),
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  geography_vintage = NULL,
  ...
)
```

## Arguments

- geography:

  Census geography name.

- variables:

  Optional character vector of variable names.

- table:

  Optional table or group identifier. Mutually exclusive with
  `variables`.

- year:

  Dataset year.

- dataset:

  PEP dataset path, such as `"population"` or `"components"`. A leading
  `"pep/"` is optional.

- product:

  Optional PEP product alias. Supported values are `"population"`,
  `"components"`, `"housing"`, and `"characteristics"`.

- breakdown:

  Optional characteristics breakdown variables. Supported values are
  `"AGE"`, `"AGEGROUP"`, `"SEX"`, `"HISP"`, and `"RACE"`.

- within:

  Optional named list of parent geographies.

- predicates:

  Optional named list of additional predicates.

- breakdown_labels:

  Should label variables for supported breakdowns be added
  automatically?

- summary_var:

  Optional summary variable to append as `summary_estimate` /
  `summary_moe`.

- geometry:

  Should geometry be joined after retrieval?

- keep_geo_vars:

  Should source geometry attributes be retained?

- key:

  Optional Census API key.

- refresh:

  Should cached metadata be refreshed?

- cache:

  Should discovery metadata be cached locally?

- ucgid:

  Optional `ucgid` predicate.

- geography_vintage:

  Optional geography vintage used for input normalization.

- ...:

  Geography values such as `state = "NY"` or `county = "001"`.

## Value

A tibble or `sf` object.

## Examples

``` r
if (FALSE) { # tinycensus::tc_has_key()
tc_get_pep(
  year = 2021,
  product = "population",
  geography = "state",
  state = c("NY", "Delaware")
)
}
```
