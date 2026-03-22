# Retrieve encoded values metadata for a Census variable

Retrieve encoded values metadata for a Census variable

## Usage

``` r
tc_values(dataset, year = NULL, variable, refresh = FALSE)
```

## Arguments

- dataset:

  A Census dataset identifier like `"acs/acs5"`.

- year:

  Optional dataset year.

- variable:

  Variable name.

- refresh:

  Should cached metadata be refreshed?

## Value

A tibble of value codes and labels.
