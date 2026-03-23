test_that("tc_get_pdb infers datasets from geography", {
  expect_equal(
    tinycensus:::tc_pdb_dataset(geography = "tract"),
    "pdb/tract"
  )
  expect_equal(
    tinycensus:::tc_pdb_dataset(geography = "block group"),
    "pdb/blockgroup"
  )
  expect_equal(
    tinycensus:::tc_pdb_dataset(geography = "county"),
    "pdb/statecounty"
  )
})

test_that("tc_get_pdb retrieves tract-level Planning Database data", {
  skip_if_offline()

  out <- tc_get_pdb(
    year = 2024,
    variables = "Tot_Population_CEN_2020",
    geography = "tract",
    state = "NY",
    county = "061"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c("NAME", "Tot_Population_CEN_2020", "tract", "GEOID") %in% names(out)))
})
