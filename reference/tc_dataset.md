# Retrieve a single Census dataset record

Retrieve a single Census dataset record

## Usage

``` r
tc_dataset(dataset, year = NULL, refresh = FALSE)
```

## Arguments

- dataset:

  A Census dataset identifier like `"acs/acs5"`.

- year:

  Optional year. When omitted, the latest available year is used.

- refresh:

  Should cached metadata be refreshed?

## Value

A tibble with one row.

## Examples

``` r
if (FALSE) { # tinycensus::tc_has_key()
tc_dataset("acs/acs5", 2024, refresh = TRUE)
}
```
