# Retrieve Census table metadata

Retrieve Census table metadata

## Usage

``` r
tc_tables(dataset, year = NULL, refresh = FALSE)
```

## Arguments

- dataset:

  A Census dataset identifier like `"acs/acs5"`.

- year:

  Optional dataset year.

- refresh:

  Should cached metadata be refreshed?

## Value

A tibble of table metadata.

## Details

This is the preferred helper for exploring ACS and decennial table-level
metadata. It wraps the Census API's group metadata in a table-oriented
interface.
