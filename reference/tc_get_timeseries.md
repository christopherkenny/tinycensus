# Retrieve Census time-series data

Retrieve Census time-series data

## Usage

``` r
tc_get_timeseries(
  dataset,
  variables = NULL,
  table = NULL,
  predicates = NULL,
  time = NULL,
  year = NULL,
  key = tc_get_key(),
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL
)
```

## Arguments

- dataset:

  A time-series dataset identifier.

- variables:

  Optional character vector of variable names.

- table:

  Optional group or table identifier. Mutually exclusive with
  `variables`.

- predicates:

  Optional named list of filter predicates other than `time`.

- time:

  Optional timeseries date value, such as `"2024-01"`.

- year:

  Optional dataset year. Most timeseries datasets ignore this and
  resolve through the discovery catalog.

- key:

  Optional Census API key.

- refresh:

  Should cached metadata be refreshed?

- cache:

  Should discovery metadata be cached locally?

- ucgid:

  Optional `ucgid` predicate.

## Value

A tibble.

## Examples

``` r
if (FALSE) { # tc_has_key()
tc_get_timeseries(
  dataset = "intltrade/exports/hs",
  variables = "ALL_VAL_MO",
  time = "2024-01",
  predicates = list(CTY_CODE = "2010")
)
}
```
