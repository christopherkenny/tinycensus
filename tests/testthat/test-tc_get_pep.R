test_that("tc_get_pep uses the product interface", {
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

test_that("tc_get_pep supports product aliases for characteristics", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("pep_characteristics_breakdown")

  out <- tc_get_pep(
    year = 2023,
    product = "characteristics",
    breakdown = "RACE",
    breakdown_labels = TRUE,
    geography = "state",
    state = "NY"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("POP", "POPGROUP", "POPGROUP_LABEL") %in% names(out)))
  expect_true(any(nzchar(out$POPGROUP_LABEL)))
})

test_that("tc_get_pep supports older characteristics products", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("pep_characteristics_legacy")

  out <- tc_get_pep(
    year = 2019,
    product = "characteristics",
    breakdown = c("SEX", "HISP"),
    breakdown_labels = TRUE,
    geography = "state",
    state = "LA"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("POP", "SEX", "HISP", "SEX_LABEL", "HISP_LABEL") %in% names(out)))
  expect_true(any(nzchar(stats::na.omit(out$SEX_LABEL))))
  expect_true(any(nzchar(stats::na.omit(out$HISP_LABEL))))
})

test_that("tc_get_pep returns product defaults when variables are omitted", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("pep_product_defaults")

  out <- tc_get_pep(
    year = 2019,
    product = "components",
    geography = "county",
    state = "NY",
    county = "Queens"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("BIRTHS", "DEATHS", "NETMIG", "NATURALINC") %in% names(out)))
})

test_that("tc_get_pep supports national housing defaults", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("pep_housing_us_default")

  out <- tc_get_pep(
    year = 2019,
    product = "housing",
    geography = "us"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("DATE_CODE", "DATE_DESC", "HUEST") %in% names(out)))
  expect_true(nrow(out) >= 1)
})

test_that("tc_get_pep supports legacy AGEGROUP characteristics", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("pep_characteristics_agegroup")

  out <- tc_get_pep(
    year = 2019,
    product = "characteristics",
    breakdown = "AGEGROUP",
    geography = "state",
    state = "LA"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("POP", "AGEGROUP") %in% names(out)))
  expect_true(nrow(out) > 0)
})

test_that("tc_get_pep validates dataset and product inputs", {
  expect_error(
    tc_get_pep(
      year = 2023,
      dataset = "population",
      product = "population",
      variables = "POP",
      geography = "state",
      state = "NY"
    ),
    "mutually exclusive"
  )

  expect_error(
    tinycensus:::tc_pep_dataset(
      product = "characteristics",
      year = 2019,
      breakdown = c("AGE", "AGEGROUP")
    ),
    "cannot include both"
  )
})
