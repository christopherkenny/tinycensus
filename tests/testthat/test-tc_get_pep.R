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
