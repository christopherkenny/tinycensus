# Retrieve County Business Patterns data

Retrieve County Business Patterns data

## Usage

``` r
tc_get_cbp(
  year,
  variables = NULL,
  table = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  dataset = "cbp",
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

  A `cbp` dataset identifier. Defaults to `"cbp"`.

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
if (FALSE) { # tinycensus::tc_has_key()
tc_get_cbp(
  year = 2021,
  variables = "ESTAB",
  geography = "state",
  state = c("NY", "DE")
)
}
```
