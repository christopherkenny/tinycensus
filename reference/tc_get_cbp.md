# Retrieve County Business Patterns data

Retrieve County Business Patterns data

## Usage

``` r
tc_get_cbp(
  geography = NULL,
  variables = NULL,
  table = NULL,
  year,
  dataset = "cbp",
  within = NULL,
  predicates = NULL,
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

  A `cbp` dataset identifier. Defaults to `"cbp"`.

- within:

  Optional named list of parent geographies.

- predicates:

  Optional named list of additional predicates.

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
tc_get_cbp(
  year = 2021,
  variables = "ESTAB",
  geography = "state",
  state = c("NY", "DE")
)
}
```
