test_that("tc_get_acs returns wide output for variable queries", {
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

test_that("tc_get_acs returns table queries with summary variables", {
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
  expect_true(all(c(
    "B01001_002E",
    "B01001_002M",
    "summary_estimate",
    "summary_moe"
  ) %in% names(out)))
  expect_false(is.na(out$summary_estimate[[1]]))
})

test_that("tc_get_acs supports geometry and keep_geo_vars", {
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

test_that("tc_get_acs errors clearly for invalid variables", {
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

test_that("tc_get_acs validates summary_var against dataset and table inputs", {
  expect_error(
    tc_get_acs(
      year = 2024,
      variables = "B01001_001E",
      summary_var = "NOT_A_REAL_VARIABLE",
      geography = "state",
      state = "NY"
    ),
    "Unknown .*summary_var"
  )

  expect_error(
    tc_get_acs(
      year = 2024,
      table = "B01001",
      summary_var = "B19013_001E",
      geography = "state",
      state = "NY"
    ),
    "must belong to table"
  )
})

test_that("tc_get_acs keeps ucgid separate from explicit geography inputs", {
  expect_error(
    tc_get_acs(
      year = 2024,
      variables = "B01001_001E",
      geography = "state",
      state = "NY",
      ucgid = "0400000US36"
    ),
    "mutually exclusive"
  )
})

test_that("tc_get_acs validates geography inputs through the public interface", {
  expect_error(
    tc_get_acs(
      year = 2024,
      variables = "B01001_001E",
      county = "001",
      counties = "003"
    ),
    "must be unique"
  )

  expect_error(
    tc_get_acs(
      year = 2024,
      variables = "B01001_001E",
      state = "NY",
      county = "001"
    ),
    "Supply an explicit .*geography"
  )
})
