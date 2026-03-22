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
