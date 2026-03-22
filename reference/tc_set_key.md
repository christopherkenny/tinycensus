# Set the Census API key

Adds a Census API key to the current session and, optionally, to a
`.Renviron` file.

## Usage

``` r
tc_set_key(key, overwrite = FALSE, install = FALSE, r_env = NULL)
```

## Arguments

- key:

  Character scalar API key.

- overwrite:

  Should an existing `CENSUS_API_KEY` entry in `.Renviron` be
  overwritten?

- install:

  Should the key be added to a `.Renviron` file?

- r_env:

  Path to the `.Renviron` file when `install = TRUE`.

## Value

Invisibly returns the key.

## Examples

``` r
if (FALSE) { # \dontrun{
tc_set_key("YOUR-API-KEY")
tc_set_key(
  "YOUR-API-KEY",
  install = TRUE,
  overwrite = TRUE,
  r_env = "~/.Renviron"
)
} # }
```
