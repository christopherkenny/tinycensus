# Retrieve Population Estimates Program data

Retrieve Population Estimates Program data

## Usage

``` r
tc_get_pep(
  year,
  variables = NULL,
  table = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  dataset = "population",
  summary_var = NULL,
  key = tc_get_key(),
  geometry = FALSE,
  keep_geo_vars = FALSE,
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  geography_vintage = NULL,
  ...
)
```

## Arguments

- year:

  Dataset year.

- variables:

  Optional character vector of variable names.

- table:

  Optional table or group identifier. Mutually exclusive with
  `variables`.

- geography:

  Census geography name.

- within:

  Optional named list of parent geographies.

- predicates:

  Optional named list of additional predicates.

- dataset:

  PEP dataset path, such as `"population"` or `"components"`. A leading
  `"pep/"` is optional.

- summary_var:

  Optional summary variable to append as `summary_estimate` /
  `summary_moe`.

- key:

  Optional Census API key.

- geometry:

  Should geometry be joined after retrieval?

- keep_geo_vars:

  Should source geometry attributes be retained?

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
if (FALSE) { # tc_has_key()
tc_get_pep(
  year = 2021,
  dataset = "population",
  variables = "POP_2021",
  geography = "state",
  state = c("NY", "Delaware")
)
}
```
