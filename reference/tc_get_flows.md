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
  breakdown_labels = FALSE,
  geometry = FALSE,
  keep_geo_vars = FALSE,
  refresh = FALSE
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

- breakdown_labels:

  Should label columns be added for supported coded breakdown variables?

- geometry:

  Should centroid geometry be joined? Use `TRUE` or `"destination"` for
  destination geometry, or `"origin"` for origin geometry.

- keep_geo_vars:

  Should source geometry attributes for the selected geometry role be
  retained?

- refresh:

  Included for consistency with other retrieval helpers. Flows data are
  requested directly and do not currently use cached metadata.

## Value

A tibble or `sf` object.
