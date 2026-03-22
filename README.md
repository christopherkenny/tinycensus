
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tinycensus

<!-- badges: start -->

<!-- badges: end -->

`tinycensus` is a lightweight, metadata-driven interface to the [US
Census Bureau API](https://www.census.gov/data/developers.html). It is
designed to stay small while still covering a broad set of aggregate
datasets, including ACS, decennial census products, population
estimates, county business patterns, time-series endpoints, and other
datasets exposed through the Census discovery catalog.

The package is built around a generic query engine plus a small set of
convenience wrappers. The goal is to make common Census workflows easy
without pulling in a large dependency stack.

## Installation

You can install the development version of tinycensus from GitHub with:

``` r
# install.packages("pak")
pak::pak("christopherkenny/tinycensus")
```

## What it does

- Discovers Census datasets from the live API catalog
- Retrieves metadata for variables, groups, geographies, and example
  queries
- Pulls tabular results with one generic interface
- Provides wrappers for common products like ACS and decennial census
- Accepts flexible geography inputs like `"NY"`, `"New York"`, and
  `"36"`
- Returns optional `sf` output through `tinytiger`

## API key

You can use many endpoints without a key for light exploration, but a
Census API key is recommended for regular usage.

``` r
tinycensus::tc_set_key("YOUR-KEY")
```

To write the key to a `.Renviron` file for future sessions, set
`install = TRUE` and supply the target path explicitly:

``` r
tinycensus::tc_set_key(
  "YOUR-KEY",
  install = TRUE,
  r_env = file.path(Sys.getenv("HOME"), ".Renviron")
)
```

You can also check whether a key is available:

``` r
library(tinycensus)

tc_has_key()
#> [1] TRUE
```

## Discover datasets

``` r
tc_datasets(year = 2024, family = "acs")[1:5, c("year", "dataset", "title")]
#> # A tibble: 5 × 3
#>    year dataset           title                                                 
#>   <int> <chr>             <chr>                                                 
#> 1  2024 acs/acs1          ACS 1-Year Detailed Tables                            
#> 2  2024 acs/acs1/cprofile ACS 1-Year Comparison Profiles                        
#> 3  2024 acs/acs1/profile  ACS 1-Year Data Profiles                              
#> 4  2024 acs/acs1/pums     2024 American Community Survey: 1-Year Estimates - Pu…
#> 5  2024 acs/acs1/pumspr   2024 American Community Survey: 1-Year Estimates - Pu…
```

## Flexible geography inputs

State inputs can be abbreviations, names, or FIPS codes directly in the
query interface:

``` r
tc_get_acs(
  year = 2024,
  variables = "B01001_001E",
  geography = "state",
  state = c("NY", "Delaware", "36")
)
#> tinycensus result: "acs/acs5" (2024)
#> # A tibble: 2 × 4
#>   NAME     B01001_001E state GEOID
#>   <chr>          <dbl> <chr> <chr>
#> 1 Delaware     1021191 10    10   
#> 2 New York    19852366 36    36
```

County normalization is geography-vintage aware. That means `tinycensus`
uses the county definitions implied by the dataset rather than assuming
that the request year alone determines valid county codes. For example,
ACS 2024 uses current county equivalents, while decennial 2020 products
keep 2020 county definitions. If you need to override that behavior for
a specific dataset, use `geography_vintage =`.

## Pull data with wrappers

The ACS wrapper makes common requests compact:

``` r
tc_get_acs(
  year = 2024,
  variables = c("B01001_001E", "B19013_001E"),
  geography = "state",
  state = c("NY", "Delaware")
)
#> tinycensus result: "acs/acs5" (2024)
#> # A tibble: 2 × 5
#>   NAME     B01001_001E B19013_001E state GEOID
#>   <chr>          <dbl>       <dbl> <chr> <chr>
#> 1 Delaware     1021191       84954 10    10   
#> 2 New York    19852366       85974 36    36
```

You can do the same with a decennial dataset:

``` r
tc_get_decennial(
  year = 2020,
  dataset = "pl",
  variables = "P1_001N",
  geography = "county",
  state = "Delaware"
)
#> tinycensus result: "dec/pl" (2020)
#> # A tibble: 3 × 5
#>   NAME                        P1_001N state county GEOID
#>   <chr>                         <dbl> <chr> <chr>  <chr>
#> 1 Kent County, Delaware        181851 10    001    10001
#> 2 New Castle County, Delaware  570719 10    003    10003
#> 3 Sussex County, Delaware      237378 10    005    10005
```

## Use the generic interface

`tc_get()` is the core engine. Wrappers like `tc_get_acs()` mainly
prefill dataset details.

``` r
tc_get(
  dataset = "acs/acs5",
  year = 2024,
  variables = "B01001_001E",
  geography = "state",
  state = c("NY", "Delaware")
)
#> tinycensus result: "acs/acs5" (2024)
#> # A tibble: 2 × 4
#>   NAME     B01001_001E state GEOID
#>   <chr>          <dbl> <chr> <chr>
#> 1 Delaware     1021191 10    10   
#> 2 New York    19852366 36    36
```

## Inspect metadata

Metadata helpers make it easier to explore unfamiliar datasets before
you query them.

``` r
vars <- tc_variables("acs/acs5", 2024)
vars[
  vars$name %in% c("B01001_001E", "B19013_001E"),
  c("name", "label", "concept")
]
#> # A tibble: 2 × 3
#>   name        label                                                      concept
#>   <chr>       <chr>                                                      <chr>  
#> 1 B01001_001E Estimate!!Total:                                           Sex by…
#> 2 B19013_001E Estimate!!Median household income in the past 12 months (… Median…
```

``` r
tc_geography("acs/acs5", 2024)[1:10, c("geography", "summary_level")]
#> # A tibble: 10 × 2
#>    geography                 summary_level
#>    <chr>                     <chr>        
#>  1 us                        010          
#>  2 region                    020          
#>  3 division                  030          
#>  4 state                     040          
#>  5 county                    050          
#>  6 county subdivision        060          
#>  7 subminor civil division   067          
#>  8 place/remainder (or part) 070          
#>  9 tract                     140          
#> 10 block group               150
```

## Time-series datasets

The package also supports discovery-catalog time-series endpoints:

``` r
tc_get_timeseries(
  dataset = "intltrade/exports/hs",
  year = NULL,
  variables = "ALL_VAL_MO",
  predicates = list(time = "2024-01", CTY_CODE = "2010")
)
#> tinycensus result: "timeseries/intltrade/exports/hs" (NA)
#> # A tibble: 1 × 3
#>    ALL_VAL_MO time    CTY_CODE
#>         <dbl> <chr>   <chr>   
#> 1 26439153527 2024-01 2010
```

## Optional geometry with tinytiger

When `geometry = TRUE`, `tinycensus` fetches the tabular result first
and then joins matching geometry from `tinytiger`.

``` r
tc_get_acs(
  year = 2024,
  variables = "B01001_001E",
  geography = "state",
  state = c("NY", "Delaware"),
  geometry = TRUE
)
#> tinycensus result: "acs/acs5" (2024)
#> Simple feature collection with 2 features and 4 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -79.76259 ymin: 38.45113 xmax: -71.77749 ymax: 45.01586
#> Geodetic CRS:  NAD83
#>   GEOID     NAME B01001_001E state                       geometry
#> 1    10 Delaware     1021191    10 MULTIPOLYGON (((-75.50949 3...
#> 2    36 New York    19852366    36 MULTIPOLYGON (((-74.72623 4...
```

## Current scope

`tinycensus` is currently focused on aggregate Census API datasets. That
means the package is aimed at products like ACS, decennial, PEP, CBP,
and similar tabular endpoints available through the Census discovery
feed. Microdata-specific ergonomics are not the focus of the current
development version.
