test_that("county normalization accepts fips values", {
  expect_equal(tinycensus:::normalize_county("1", state = "NY"), "001")
  expect_equal(tinycensus:::normalize_county("005", state = "36"), "005")
})

test_that("county normalization matches names with state context", {
  expect_equal(
    tinycensus:::normalize_county("Albany County", state = "NY"),
    "001"
  )
})

test_that("county normalization uses bundled vintage-aware tables", {
  expect_equal(nrow(tinycensus:::tc_counties_for_year(2005)), 3141)
  expect_equal(nrow(tinycensus:::tc_counties_for_year(2015)), 3142)
  expect_equal(nrow(tinycensus:::tc_counties_for_year(2024)), 3144)
})

test_that("county normalization respects within-decade changes", {
  expect_error(
    tinycensus:::normalize_county(
      "Broomfield County",
      state = "CO",
      year = 2001
    ),
    "Could not match county"
  )
  expect_equal(
    tinycensus:::normalize_county(
      "Broomfield County",
      state = "CO",
      year = 2002
    ),
    "014"
  )

  expect_equal(
    tinycensus:::normalize_county(
      "Wade Hampton Census Area",
      state = "AK",
      year = 2015
    ),
    "270"
  )
  expect_equal(
    tinycensus:::normalize_county(
      "Kusilvak Census Area",
      state = "AK",
      year = 2016
    ),
    "158"
  )

  expect_equal(
    tinycensus:::normalize_county(
      "Fairfield County",
      state = "CT",
      year = 2021
    ),
    "001"
  )
  expect_equal(
    tinycensus:::normalize_county(
      "Capitol Planning Region",
      state = "CT",
      year = 2022
    ),
    "110"
  )
})

test_that("geography vintage can differ from dataset release year", {
  expect_equal(
    tinycensus:::tc_resolve_geography_vintage("dec/dhc", 2022),
    2020
  )
  expect_equal(
    tinycensus:::tc_resolve_geography_vintage("acs/acs5", 2022),
    2022
  )
  expect_equal(
    tinycensus:::normalize_county(
      "Fairfield County",
      state = "CT",
      year = tinycensus:::tc_resolve_geography_vintage("dec/dhc", 2022)
    ),
    "001"
  )
})
