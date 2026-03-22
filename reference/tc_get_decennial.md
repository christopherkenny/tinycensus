# Retrieve Decennial Census data

Retrieve Decennial Census data

## Usage

``` r
tc_get_decennial(
  year,
  variables = NULL,
  table = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  dataset = "pl",
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

  Decennial Census year.

- variables:

  Optional character vector of variable names.

- table:

  Optional table identifier. Mutually exclusive with `variables`.

- geography:

  Census geography name.

- within:

  Optional named list of parent geographies.

- predicates:

  Optional named list of additional predicates.

- dataset:

  Decennial dataset path, such as `"pl"` or `"ddhca"`.

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
tc_get_decennial(
  year = 2020,
  dataset = "pl",
  variables = "P1_001N",
  geography = "county",
  state = "Delaware"
)
}
```
