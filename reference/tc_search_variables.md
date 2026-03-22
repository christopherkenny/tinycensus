# Search Census variable metadata

Search Census variable metadata

## Usage

``` r
tc_search_variables(
  dataset,
  year = NULL,
  query,
  fields = c("name", "label", "concept"),
  ignore_case = TRUE,
  refresh = FALSE
)
```

## Arguments

- dataset:

  A Census dataset identifier like `"acs/acs5"`.

- year:

  Optional dataset year.

- query:

  Search string.

- fields:

  Metadata fields to search.

- ignore_case:

  Should matching ignore case?

- refresh:

  Should cached metadata be refreshed?

## Value

A tibble of matching variables.
