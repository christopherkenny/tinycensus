# tinycensus

`tinycensus` is a lightweight, metadata-driven interface to the [US
Census Bureau API](https://www.census.gov/data/developers.html). It is
designed to stay small while still covering a broad set of aggregate
datasets, with first-class support for ACS, decennial census products,
PEP, CBP, migration flows, time-series endpoints, and related discovery
metadata.

The package is built around product-specific interfaces rather than one
generic user-facing query function. The goal is to make common Census
workflows easy without pulling in a large dependency stack.

The basic pattern is:

1.  discover a dataset, table, or variable with the metadata helpers
2.  retrieve data with a product-specific wrapper
3.  optionally join geometry with `tinytiger`

## Installation

You can install the development version of tinycensus from GitHub with:

``` r
# install.packages("pak")
pak::pak("christopherkenny/tinycensus")
```

## What it does

- Discovers Census datasets from the live API catalog
- Retrieves metadata for variables, tables, geographies, and example
  queries
- Provides product-specific retrieval for ACS, decennial census, PEP,
  CBP, flows, and time-series datasets
- Searches variables and retrieves encoded value metadata
- Accepts flexible geography inputs like `"NY"`, `"New York"`, and
  `"36"`
- Returns optional `sf` output through `tinytiger`

## Core workflows

The main entry points are:

- [`tc_get_acs()`](https://christopherkenny.github.io/tinycensus/reference/tc_get_acs.md)
  for ACS products
- [`tc_get_decennial()`](https://christopherkenny.github.io/tinycensus/reference/tc_get_decennial.md)
  for decennial census products
- [`tc_get_pep()`](https://christopherkenny.github.io/tinycensus/reference/tc_get_pep.md)
  for population estimates
- [`tc_get_cbp()`](https://christopherkenny.github.io/tinycensus/reference/tc_get_cbp.md)
  for County Business Patterns
- [`tc_get_flows()`](https://christopherkenny.github.io/tinycensus/reference/tc_get_flows.md)
  for ACS migration flows
- [`tc_get_timeseries()`](https://christopherkenny.github.io/tinycensus/reference/tc_get_timeseries.md)
  for discovery-catalog time-series endpoints

For metadata discovery, start with
[`tc_datasets()`](https://christopherkenny.github.io/tinycensus/reference/tc_datasets.md),
[`tc_variables()`](https://christopherkenny.github.io/tinycensus/reference/tc_variables.md),
[`tc_tables()`](https://christopherkenny.github.io/tinycensus/reference/tc_tables.md),
and
[`tc_search_variables()`](https://christopherkenny.github.io/tinycensus/reference/tc_search_variables.md).

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

The same interface also works with less-common geographies when the
dataset supports them, such as places, congressional districts,
metropolitan areas, and school districts.

## Retrieve Census data

The ACS wrapper makes common requests compact:

``` r
tc_get_acs(
  year = 2024,
  variables = "B19013_001E",
  geography = "state",
  state = c("NY", "Delaware")
)
#> # A tibble: 2 × 4
#>   NAME     B19013_001E state GEOID
#>   <chr>          <dbl> <chr> <chr>
#> 1 Delaware       84954 10    10   
#> 2 New York       85974 36    36
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
#> # A tibble: 3 × 5
#>   NAME                        P1_001N state county GEOID
#>   <chr>                         <dbl> <chr> <chr>  <chr>
#> 1 Kent County, Delaware        181851 10    001    10001
#> 2 New Castle County, Delaware  570719 10    003    10003
#> 3 Sussex County, Delaware      237378 10    005    10005
```

You can also request a full ACS table directly:

``` r
tc_get_acs(
  year = 2024,
  table = "B01001",
  geography = "state",
  state = "Delaware"
)
#> # A tibble: 1 × 102
#>   NAME   B01001_001E B01001_001M B01001_002E B01001_002M B01001_003E B01001_003M
#>   <chr>        <dbl> <chr>             <dbl> <chr>             <dbl> <chr>      
#> 1 Delaw…     1021191 -555555555       494652 170               27816 143        
#> # ℹ 95 more variables: B01001_004E <dbl>, B01001_004M <chr>, B01001_005E <dbl>,
#> #   B01001_005M <chr>, B01001_006E <dbl>, B01001_006M <chr>, B01001_007E <dbl>,
#> #   B01001_007M <chr>, B01001_008E <dbl>, B01001_008M <chr>, B01001_009E <dbl>,
#> #   B01001_009M <chr>, B01001_010E <dbl>, B01001_010M <chr>, B01001_011E <dbl>,
#> #   B01001_011M <chr>, B01001_012E <dbl>, B01001_012M <chr>, B01001_013E <dbl>,
#> #   B01001_013M <chr>, B01001_014E <dbl>, B01001_014M <chr>, B01001_015E <dbl>,
#> #   B01001_015M <chr>, B01001_016E <dbl>, B01001_016M <chr>, …
```

## Inspect metadata

Metadata helpers make it easier to explore unfamiliar datasets before
you query them. For most workflows,
[`tc_tables()`](https://christopherkenny.github.io/tinycensus/reference/tc_tables.md)
is the best way to browse table-level metadata;
[`tc_groups()`](https://christopherkenny.github.io/tinycensus/reference/tc_groups.md)
remains available as a lower-level helper for the raw Census API
concept.

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

``` r
tc_tables("acs/acs5", 2024)[1:5, c("name", "description")]
#> # A tibble: 5 × 2
#>   name   description                                                            
#>   <chr>  <chr>                                                                  
#> 1 B17015 Poverty Status in the Past 12 Months of Families by Family Type by Soc…
#> 2 B18104 Sex by Age by Cognitive Difficulty                                     
#> 3 B17016 Poverty Status in the Past 12 Months of Families by Family Type by Wor…
#> 4 B18105 Sex by Age by Ambulatory Difficulty                                    
#> 5 B17017 Poverty Status in the Past 12 Months by Household Type by Age of House…
```

``` r
tc_search_variables("acs/acs5", 2024, query = "median household income")[
  1:5,
  c("name", "label", "concept")
]
#> # A tibble: 5 × 3
#>   name         label                                                     concept
#>   <chr>        <chr>                                                     <chr>  
#> 1 B19013_001E  Estimate!!Median household income in the past 12 months … Median…
#> 2 B19013A_001E Estimate!!Median household income in the past 12 months … Median…
#> 3 B19013B_001E Estimate!!Median household income in the past 12 months … Median…
#> 4 B19013C_001E Estimate!!Median household income in the past 12 months … Median…
#> 5 B19013D_001E Estimate!!Median household income in the past 12 months … Median…
```

## Migration flows

``` r
tc_get_flows(
  geography = "county",
  year = 2018,
  state = "NY",
  county = "001",
  geometry = "destination"
)
#> Warning in st_point_on_surface.sfc(geom$geometry): st_point_on_surface may not
#> give correct results for longitude/latitude data
#> Simple feature collection with 316 features and 10 fields (with 8 geometries empty)
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -146.3702 ymin: 18.13797 xmax: -65.7906 ymax: 64.85516
#> Geodetic CRS:  NAD83
#> First 10 features:
#>     destination_geoid origin_geoid             origin_name
#> 309              <NA>        36001 Albany County, New York
#> 310              <NA>        36001 Albany County, New York
#> 311              <NA>        36001 Albany County, New York
#> 312              <NA>        36001 Albany County, New York
#> 313              <NA>        36001 Albany County, New York
#> 314              <NA>        36001 Albany County, New York
#> 315              <NA>        36001 Albany County, New York
#> 316              <NA>        36001 Albany County, New York
#> 1               01103        36001 Albany County, New York
#> 2               02090        36001 Albany County, New York
#>                         destination_name moved_in moved_in_moe moved_out
#> 309                               Africa       45           33        NA
#> 310                                 Asia     1203          329        NA
#> 311                      Central America      232          260        NA
#> 312                            Caribbean       18           24        NA
#> 313                               Europe      495          300        NA
#> 314                    U.S. Island Areas       28           45        NA
#> 315                     Northern America       18           19        NA
#> 316                        South America      255          303        NA
#> 1                 Morgan County, Alabama        0           28        14
#> 2   Fairbanks North Star Borough, Alaska        0           28        21
#>     moved_out_moe moved_net moved_net_moe                   geometry
#> 309            NA        NA            NA                POINT EMPTY
#> 310            NA        NA            NA                POINT EMPTY
#> 311            NA        NA            NA                POINT EMPTY
#> 312            NA        NA            NA                POINT EMPTY
#> 313            NA        NA            NA                POINT EMPTY
#> 314            NA        NA            NA                POINT EMPTY
#> 315            NA        NA            NA                POINT EMPTY
#> 316            NA        NA            NA                POINT EMPTY
#> 1              22       -14            22  POINT (-86.83417 34.4932)
#> 2              27       -21            27 POINT (-146.3702 64.85516)
```

## Other products

``` r
tc_get_pep(
  year = 2021,
  dataset = "population",
  variables = "POP_2021",
  geography = "state",
  state = c("NY", "Delaware")
)
#> # A tibble: 2 × 4
#>   NAME     POP_2021 state GEOID
#>   <chr>       <dbl> <chr> <chr>
#> 1 Delaware  1003384 10    10   
#> 2 New York 19835913 36    36
```

``` r
tc_get_cbp(
  year = 2021,
  variables = "ESTAB",
  geography = "state",
  state = c("NY", "DE")
)
#> # A tibble: 2 × 4
#>   NAME      ESTAB state GEOID
#>   <chr>     <dbl> <chr> <chr>
#> 1 Delaware  28553 10    10   
#> 2 New York 535758 36    36
```

## Time-series datasets

The package also supports discovery-catalog time-series endpoints:

``` r
tc_get_timeseries(
  dataset = "intltrade/exports/hs",
  variables = "ALL_VAL_MO",
  time = "2024-01",
  predicates = list(CTY_CODE = "2010")
)
#> # A tibble: 1 × 3
#>    ALL_VAL_MO CTY_CODE time   
#>         <dbl> <chr>    <chr>  
#> 1 26439153527 2010     2024-01
```

## Optional geometry with tinytiger

When `geometry = TRUE`, `tinycensus` fetches the tabular result first
and then joins matching geometry from `tinytiger`. Set
`keep_geo_vars = TRUE` if you want the original geometry attributes as
well.

``` r
tc_get_acs(
  year = 2024,
  variables = "B01001_001E",
  geography = "state",
  state = c("NY", "Delaware"),
  geometry = TRUE,
  keep_geo_vars = TRUE
)
#> Simple feature collection with 2 features and 18 fields
#> Geometry type: MULTIPOLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -79.76259 ymin: 38.45113 xmax: -71.77749 ymax: 45.01586
#> Geodetic CRS:  NAD83
#>   GEOID     NAME B01001_001E state REGION DIVISION STATEFP  STATENS     GEOIDFQ
#> 1    10 Delaware     1021191    10      3        5      10 01779781 0400000US10
#> 2    36 New York    19852366    36      1        2      36 01779796 0400000US36
#>   STUSPS geo_NAME LSAD MTFCC FUNCSTAT        ALAND      AWATER    INTPTLAT
#> 1     DE Delaware   00 G4000        A   5046692239  1399219008 +38.9985661
#> 2     NY New York   00 G4000        A 122049155860 19256755462 +42.9133974
#>       INTPTLON                       geometry
#> 1 -075.4416440 MULTIPOLYGON (((-75.50949 3...
#> 2 -075.5962723 MULTIPOLYGON (((-74.72623 4...
```

## Current scope

`tinycensus` is currently focused on aggregate Census API datasets. That
means the package is aimed at products like ACS, decennial, PEP, CBP,
and similar tabular endpoints available through the Census discovery
feed. Microdata-specific ergonomics are not the focus of the current
development version.
