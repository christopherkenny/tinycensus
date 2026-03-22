# Retrieve American Community Survey data

Retrieve American Community Survey data

## Usage

``` r
tc_get_acs(
  year,
  variables = NULL,
  table = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  survey = c("acs5", "acs1", "acs3"),
  product = c("detailed", "profile", "subject", "comparison"),
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

  ACS year.

- variables:

  Optional character vector of variable names.

- table:

  Optional ACS table identifier. Mutually exclusive with `variables`.

- geography:

  Census geography name.

- within:

  Optional named list of parent geographies.

- predicates:

  Optional named list of additional predicates.

- survey:

  ACS survey, one of `"acs1"`, `"acs3"`, or `"acs5"`.

- product:

  ACS product, one of `"detailed"`, `"profile"`, `"subject"`, or
  `"comparison"`.

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
tc_get_acs(
  year = 2024,
  variables = "B01001_001E",
  geography = "state",
  state = c("NY", "Delaware")
)
}
```
