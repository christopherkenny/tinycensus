test_that("acs queries support flexible state inputs", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("acs_states")

  out <- tc_get_acs(
    year = 2024,
    variables = "B01001_001E",
    geography = "state",
    state = c("NY", "Delaware")
  )

  expect_s3_class(out, "tbl_df")
  expect_equal(sort(out$state), c("10", "36"))
  expect_true("B01001_001E" %in% names(out))
})

test_that("decennial county queries normalize inputs", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("decennial_counties")

  out <- tc_get_decennial(
    year = 2020,
    dataset = "pl",
    variables = "P1_001N",
    geography = "county",
    state = "Delaware"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(out$state == "10"))
})

test_that("generic non-acs dataset queries work", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("pep_states")

  out <- tc_get_pep(
    dataset = "pep/population",
    year = 2021,
    variables = "POP_2021",
    geography = "state",
    state = c("NY", "Delaware")
  )

  expect_s3_class(out, "tbl_df")
  expect_true("POP_2021" %in% names(out))
})

test_that("time series queries work", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("timeseries")

  out <- tc_get_timeseries(
    dataset = "intltrade/exports/hs",
    year = NULL,
    variables = "ALL_VAL_MO",
    predicates = list(time = "2024-01", CTY_CODE = "2010")
  )

  expect_s3_class(out, "tbl_df")
  expect_true("ALL_VAL_MO" %in% names(out))
})

test_that("geometry requests use tinytiger", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("acs_geometry")

  out <- tc_get_acs(
    year = 2024,
    variables = "B01001_001E",
    geography = "state",
    state = c("NY", "Delaware"),
    geometry = TRUE
  )

  expect_true(inherits(out, "sf"))
  expect_true("geometry" %in% names(out))
})

test_that("invalid variables error clearly", {
  skip_if_offline()

  expect_error(
    tc_get_acs(
      year = 2024,
      variables = "NOT_A_REAL_VARIABLE",
      geography = "state",
      state = "NY"
    ),
    "Unknown variable"
  )
})
