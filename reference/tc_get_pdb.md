# Retrieve Census Planning Database data

Retrieve Census Planning Database data

## Usage

``` r
tc_get_pdb(
  geography = NULL,
  variables = NULL,
  table = NULL,
  year,
  dataset = NULL,
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

  Optional `pdb/...` dataset path. When omitted, the dataset is inferred
  from `geography`.

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
tc_get_pdb(
  year = 2024,
  variables = "Tot_Population_CEN_2020",
  geography = "tract",
  state = "NY",
  county = "061"
)
}
```
