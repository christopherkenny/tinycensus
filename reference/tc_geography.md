# Retrieve Census geography metadata

Retrieve Census geography metadata

## Usage

``` r
tc_geography(dataset, year = NULL, refresh = FALSE)
```

## Arguments

- dataset:

  A Census dataset identifier like `"acs/acs5"`.

- year:

  Optional dataset year.

- refresh:

  Should cached metadata be refreshed?

## Value

A tibble of geography metadata.

## Examples

``` r
if (FALSE) { # tinycensus::tc_has_key()
tc_geography("acs/acs5", 2024, refresh = TRUE)
}
```
