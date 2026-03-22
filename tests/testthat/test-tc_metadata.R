test_that("tc_datasets returns catalog results", {
  skip_if_offline()
  out <- tc_datasets(year = 2024, family = "acs")

  expect_s3_class(out, "tbl_df")
  expect_true(nrow(out) > 0)
  expect_true(all(grepl("^https://", out$endpoint)))
})

test_that("metadata helpers return variables geographies and tables", {
  skip_if_offline()
  vars <- tc_variables("acs/acs5", 2024)
  geo <- tc_geography("acs/acs5", 2024)
  tables <- tc_tables("acs/acs5", 2024)
  table_vars <- tc_table_variables("acs/acs5", "B01001", 2024)

  expect_true("B01001_001E" %in% vars$name)
  expect_true("state" %in% geo$geography)
  expect_true("B01001" %in% tables$name)
  expect_true("B01001_001E" %in% table_vars$name)
})

test_that("tc_search_variables returns matching variables", {
  skip_if_offline()
  out <- tc_search_variables("acs/acs5", 2024, query = "median household income")

  expect_s3_class(out, "tbl_df")
  expect_true(any(out$name == "B19013_001E"))
})

test_that("tc_search_variables treats queries as literal strings", {
  skip_if_offline()
  out <- tc_search_variables("acs/acs5", 2024, query = "B01001_001E", fields = "name")

  expect_true(any(out$name == "B01001_001E"))
})
