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

test_that("tc_get_pdb handles chunked variable requests with stable aliases and order", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("pdb_chunked_variables")

  meta <- tc_variables("pdb/tract", 2024)
  vars <- meta$name[meta$predicate_type %in% c("int", "integer", "float", "numeric")][1:55]
  aliases <- stats::setNames(vars, paste0("metric_", seq_along(vars)))
  control_aliases <- aliases[c(1, 25, 49)]

  out <- tc_get_pdb(
    year = 2024,
    variables = aliases,
    geography = "tract",
    state = "NY",
    county = "061"
  )

  control <- tc_get_pdb(
    year = 2024,
    variables = control_aliases,
    geography = "tract",
    state = "NY",
    county = "061"
  )

  alias_names <- names(aliases)
  control_names <- names(control_aliases)

  expect_s3_class(out, "tbl_df")
  expect_true(all(alias_names %in% names(out)))
  expect_identical(names(out)[names(out) %in% alias_names], alias_names)
  expect_equal(out$GEOID, control$GEOID)
  expect_equal(out[control_names], control[control_names])
  expect_equal(anyDuplicated(out$GEOID), 0L)
})

test_that("tc_get_pdb geometry preserves row order for tract and block group", {
  skip_if_not_installed("vcr")
  skip_if_not_installed("sf")
  skip_if_offline()
  vcr::local_cassette("pdb_geometry")

  expect_geometry_roundtrip <- function(tabular, spatial, cols, geo_var) {
    expect_true(inherits(spatial, "sf"))
    expect_identical(spatial$GEOID, tabular$GEOID)
    spatial_df <- sf::st_drop_geometry(spatial)
    for (col in cols) {
      expect_equal(spatial_df[[col]], tabular[[col]])
    }
    expect_equal(anyDuplicated(names(spatial)), 0L)
    expect_true(geo_var %in% names(spatial))
  }

  tract_tab <- tc_get_pdb(
    year = 2024,
    variables = "Tot_Population_CEN_2020",
    geography = "tract",
    state = "NY",
    county = "061"
  )
  tract_sf <- tc_get_pdb(
    year = 2024,
    variables = "Tot_Population_CEN_2020",
    geography = "tract",
    state = "NY",
    county = "061",
    geometry = TRUE,
    keep_geo_vars = TRUE
  )
  expect_geometry_roundtrip(
    tract_tab,
    tract_sf,
    c("GEOID", "NAME", "state", "county", "tract", "Tot_Population_CEN_2020"),
    "TRACTCE"
  )

  block_group_tab <- tc_get_pdb(
    year = 2024,
    variables = "Tot_Population_CEN_2020",
    geography = "block group",
    state = "NY",
    county = "061",
    tract = "000100"
  )
  block_group_sf <- tc_get_pdb(
    year = 2024,
    variables = "Tot_Population_CEN_2020",
    geography = "block group",
    state = "NY",
    county = "061",
    tract = "000100",
    geometry = TRUE,
    keep_geo_vars = TRUE
  )
  expect_geometry_roundtrip(
    block_group_tab,
    block_group_sf,
    c("GEOID", "NAME", "state", "county", "tract", "block group", "Tot_Population_CEN_2020"),
    "BLKGRPCE"
  )
})
