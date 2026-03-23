# Retrieve Census example query metadata

Retrieve Census example query metadata

## Usage

``` r
tc_examples(dataset, year = NULL, refresh = FALSE)
```

## Arguments

- dataset:

  A Census dataset identifier like `"acs/acs5"`.

- year:

  Optional dataset year.

- refresh:

  Should cached metadata be refreshed?

## Value

A list of example query metadata.

## Examples

``` r
if (FALSE) { # tinycensus::tc_has_key()
tc_examples("acs/acs5", 2024, refresh = TRUE)
}
```
