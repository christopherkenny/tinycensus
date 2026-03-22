# List Census datasets from the discovery catalog

List Census datasets from the discovery catalog

## Usage

``` r
tc_datasets(year = NULL, family = NULL, available = TRUE, refresh = FALSE)
```

## Arguments

- year:

  Optional year filter.

- family:

  Optional dataset family filter, such as `"acs"` or `"pep"`.

- available:

  Should only available datasets be returned?

- refresh:

  Should cached metadata be refreshed?

## Value

A tibble of Census API datasets.

## Examples

``` r
if (FALSE) { # tc_has_key()
tc_datasets(year = 2024, family = "acs", refresh = TRUE)
}
```
