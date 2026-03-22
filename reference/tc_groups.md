# Retrieve raw Census group metadata

Retrieve raw Census group metadata

## Usage

``` r
tc_groups(dataset, year = NULL, refresh = FALSE)
```

## Arguments

- dataset:

  A Census dataset identifier like `"acs/acs5"`.

- year:

  Optional dataset year.

- refresh:

  Should cached metadata be refreshed?

## Value

A tibble of group metadata from the Census API.

## Details

This is a lower-level metadata helper. For most ACS and decennial
workflows,
[`tc_tables()`](https://christopherkenny.github.io/tinycensus/reference/tc_tables.md)
is the more natural entry point because Census "groups" usually
correspond to user-facing tables.

## Examples

``` r
if (FALSE) { # tc_has_key()
tc_groups("acs/acs5", 2024, refresh = TRUE)
}
```
