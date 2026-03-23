test_that("tc_get_timeseries uses explicit predicates", {
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

test_that("tc_get_timeseries supports geography-style inputs", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("timeseries_geography")

  out <- tc_get_timeseries(
    dataset = "poverty/saipe",
    variables = c("NAME", "SAEPOVRT0_17_PT", "SAEPOVRTALL_PT"),
    geography = "state",
    state = "01",
    time = "from 2000"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("NAME", "SAEPOVRT0_17_PT", "SAEPOVRTALL_PT") %in% names(out)))
  expect_true(all(out$state == "01"))
})

test_that("tc_get_timeseries accepts named atomic vectors for predicates", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("timeseries_predicates_vector")

  out <- tc_get_timeseries(
    dataset = "timeseries/intltrade/exports/hs",
    variables = "ALL_VAL_MO",
    predicates = c(CTY_CODE = "2010"),
    time = "2024-01"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("ALL_VAL_MO", "CTY_CODE", "time") %in% names(out)))
})
