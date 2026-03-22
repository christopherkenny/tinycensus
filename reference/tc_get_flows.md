# Retrieve ACS migration flows

Retrieve ACS migration flows

## Usage

``` r
tc_get_flows(
  geography,
  year = 2018,
  variables = NULL,
  breakdown = NULL,
  state = NULL,
  county = NULL,
  msa = NULL,
  key = tc_get_key(),
  geometry = FALSE
)
```

## Arguments

- geography:

  Flows geography.

- year:

  ACS migration flows year.

- variables:

  Optional additional variables.

- breakdown:

  Optional breakdown variables.

- state:

  Optional state input.

- county:

  Optional county input.

- msa:

  Optional metropolitan area codes.

- key:

  Optional Census API key.

- geometry:

  Should centroid geometry be joined?

## Value

A tibble or `sf` object.
