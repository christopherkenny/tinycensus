# Retrieve variables for a Census table

Retrieve variables for a Census table

## Usage

``` r
tc_table_variables(dataset, table, year = NULL, refresh = FALSE)
```

## Arguments

- dataset:

  A Census dataset identifier like `"acs/acs5"`.

- table:

  Table or group identifier.

- year:

  Optional dataset year.

- refresh:

  Should cached metadata be refreshed?

## Value

A tibble of variable metadata for the requested table.
