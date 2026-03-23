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

test_that("tc_get_decennial accepts NAME in requested variables", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("decennial_name_variable")

  out <- tc_get_decennial(
    year = 2020,
    dataset = "dhc",
    variables = c("NAME", "P1_001N"),
    geography = "block group",
    within = list(state = "36", county = "027", tract = "220300")
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("NAME", "P1_001N") %in% names(out)))
})

test_that("tc_get_decennial preserves named variable aliases", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("decennial_named_aliases")

  out <- tc_get_decennial(
    year = 2020,
    dataset = "pl",
    variables = c(pop = "P1_001N", pop_hisp = "P2_002N"),
    geography = "state",
    state = "DE"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("pop", "pop_hisp") %in% names(out)))
  expect_false(any(c("P1_001N", "P2_002N") %in% names(out)))
})
