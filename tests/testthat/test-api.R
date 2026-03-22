test_that("acs variable queries return wide output", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("acs_tidy")

  out <- tc_get_acs(
    year = 2024,
    variables = "B01001_001E",
    geography = "state",
    state = c("NY", "Delaware")
  )

  expect_s3_class(out, "tbl_df")
  expect_true("B01001_001E" %in% names(out))
  expect_equal(sort(out$state), c("10", "36"))
  expect_true(all(!is.na(out$NAME)))
})

test_that("acs table queries return parsed estimates and summary variables", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("acs_table")

  out <- tc_get_acs(
    year = 2024,
    table = "B01001",
    summary_var = "B01001_001E",
    geography = "state",
    state = "NY"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("B01001_002E", "B01001_002M", "summary_estimate", "summary_moe") %in% names(out)))
  expect_false(is.na(out$summary_estimate[[1]]))
})

test_that("acs wide output supports geometry and keep_geo_vars", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("acs_geometry_keep")

  minimal <- tc_get_acs(
    year = 2024,
    variables = "B01001_001E",
    geography = "state",
    state = c("NY", "Delaware"),
    geometry = TRUE
  )

  rich <- tc_get_acs(
    year = 2024,
    variables = "B01001_001E",
    geography = "state",
    state = c("NY", "Delaware"),
    geometry = TRUE,
    keep_geo_vars = TRUE
  )

  expect_true(inherits(minimal, "sf"))
  expect_true(inherits(rich, "sf"))
  expect_false("STATEFP" %in% names(minimal))
  expect_true("STATEFP" %in% names(rich))
})

test_that("decennial queries support wide output", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("decennial_tidy")

  out <- tc_get_decennial(
    year = 2020,
    dataset = "pl",
    variables = "P1_001N",
    geography = "county",
    state = "Delaware"
  )

  expect_s3_class(out, "tbl_df")
  expect_true("P1_001N" %in% names(out))
  expect_true(all(out$state == "10"))
})

test_that("flows retrieval works with wide output", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("flows_tidy")

  out <- tc_get_flows(
    geography = "county",
    year = 2018,
    state = "NY",
    county = "001"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c(
    "origin_geoid",
    "destination_geoid",
    "moved_in",
    "moved_in_moe",
    "moved_out",
    "moved_out_moe",
    "moved_net",
    "moved_net_moe"
  ) %in% names(out)))
})

test_that("pep queries use the product interface", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("pep_states")

  out <- tc_get_pep(
    year = 2021,
    dataset = "population",
    variables = "POP_2021",
    geography = "state",
    state = c("NY", "Delaware")
  )

  expect_s3_class(out, "tbl_df")
  expect_true("POP_2021" %in% names(out))
  expect_equal(sort(out$state), c("10", "36"))
})

test_that("cbp queries use the product interface", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("cbp_states")

  out <- tc_get_cbp(
    year = 2021,
    variables = "ESTAB",
    geography = "state",
    state = c("NY", "DE")
  )

  expect_s3_class(out, "tbl_df")
  expect_true("ESTAB" %in% names(out))
  expect_equal(sort(out$state), c("10", "36"))
})

test_that("timeseries queries use explicit filters", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("timeseries_explicit")

  out <- tc_get_timeseries(
    dataset = "intltrade/exports/hs",
    variables = "ALL_VAL_MO",
    time = "2024-01",
    predicates = list(CTY_CODE = "2010")
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("ALL_VAL_MO", "time", "CTY_CODE") %in% names(out)))

  expect_error(
    tc_get_timeseries(
      dataset = "intltrade/exports/hs",
      variables = "ALL_VAL_MO",
      time = "2024-01",
      predicates = list(time = "2024-01", CTY_CODE = "2010")
    ),
    "either .*time.* or .*predicates"
  )
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
