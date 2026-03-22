test_that("tc_get_decennial supports wide output", {
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
