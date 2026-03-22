test_that("county inputs normalize through internal helpers with vintage support", {
  expect_equal(tinycensus:::normalize_county("1", state = "NY"), "001")
  expect_equal(
    tinycensus:::normalize_county("Albany County", state = "NY"),
    "001"
  )

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
})

test_that("geography vintages can differ from dataset year", {
  expect_equal(
    tinycensus:::tc_resolve_geography_vintage("dec/dhc", 2022),
    2020
  )
  expect_equal(
    tinycensus:::tc_resolve_geography_vintage("acs/acs5", 2022),
    2022
  )
})

test_that("less-common geography aliases normalize cleanly", {
  expect_equal(
    tinycensus:::tc_normalize_geography_name("metro division"),
    "metropolitan division"
  )
  expect_equal(
    tinycensus:::tc_normalize_geography_name("CSA"),
    "combined statistical area"
  )
  expect_equal(
    tinycensus:::tc_normalize_geography_name("PUMAs"),
    "public use microdata area"
  )
  expect_equal(
    tinycensus:::tc_normalize_geography_name("elementary school districts"),
    "school district (elementary)"
  )
})
