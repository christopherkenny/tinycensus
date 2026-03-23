# Retrieve Census variable metadata

Retrieve Census variable metadata

## Usage

``` r
tc_variables(dataset, year = NULL, refresh = FALSE)
```

## Arguments

- dataset:

  A Census dataset identifier like `"acs/acs5"`.

- year:

  Optional dataset year.

- refresh:

  Should cached metadata be refreshed?

## Value

A tibble of variable metadata.

## Examples

``` r
if (FALSE) { # tinycensus::tc_has_key()
tc_variables("acs/acs5", 2024, refresh = TRUE)
}
```
