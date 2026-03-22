test_that("tc_get_cbp uses the product interface", {
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
