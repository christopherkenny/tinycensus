test_that("catalog helpers return tibbles", {
  skip_if_offline()
  out <- tc_datasets(year = 2024, family = "acs")
  expect_s3_class(out, "tbl_df")
  expect_true(nrow(out) > 0)
  expect_true(all(grepl("^https://", out$endpoint)))
})

test_that("variable and geography metadata can be retrieved", {
  skip_if_offline()
  vars <- tc_variables("acs/acs5", 2024)
  geo <- tc_geography("acs/acs5", 2024)

  expect_true("B01001_001E" %in% vars$name)
  expect_true("state" %in% geo$geography)
})
