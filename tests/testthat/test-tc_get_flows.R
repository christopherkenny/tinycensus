test_that("tc_get_flows returns wide output", {
  skip_if_not_installed("vcr")
  skip_if_offline()
  vcr::local_cassette("flows_tidy")

  out <- tc_get_flows(
    geography = "county",
    year = 2018,
    state = "NY",
    county = "001"
  )

  expect_s3_class(out, "tbl_df")
  expect_true(all(c(
    "origin_geoid",
    "destination_geoid",
    "moved_in",
    "moved_in_moe",
    "moved_out",
    "moved_out_moe",
    "moved_net",
    "moved_net_moe"
  ) %in% names(out)))
})

test_that("tc_get_flows validates geography-specific inputs", {
  expect_error(
    tc_get_flows(
      geography = "county subdivision",
      year = 2018,
      state = c("NY", "NJ"),
      county = "001"
    ),
    "require exactly one .*state"
  )

  expect_error(
    tc_get_flows(
      geography = "county",
      year = 2018,
      msa = "10580"
    ),
    "msa.*only supported"
  )
})

test_that("tc_get_flows geometry helpers preserve row order", {
  skip_if_not_installed("sf")

  data <- tibble::tibble(
    origin_geoid = c("36001", "36003"),
    destination_geoid = c("36005", "36007"),
    moved_in = c(10, 20)
  )
  geom <- sf::st_as_sf(
    tibble::tibble(
      GEOID = c("36003", "36001", "36007", "36005"),
      geometry = sf::st_sfc(
        sf::st_point(c(1, 1)),
        sf::st_point(c(2, 2)),
        sf::st_point(c(3, 3)),
        sf::st_point(c(4, 4)),
        crs = 4326
      ),
      STATEFP = c("36", "36", "36", "36")
    )
  )

  origin <- tinycensus:::tc_flows_geometry_frame(
    geom,
    keep_geo_vars = TRUE,
    prefix = "origin"
  )
  names(origin)[match("GEOID", names(origin))] <- "origin_geoid"

  destination <- tinycensus:::tc_flows_geometry_frame(
    geom,
    keep_geo_vars = TRUE,
    prefix = "destination"
  )
  names(destination)[match("GEOID", names(destination))] <- "destination_geoid"

  out <- tinycensus:::tc_flows_join_geometry(
    data,
    geometry = origin,
    key = "origin_geoid",
    geometry_name = "geometry"
  )
  out <- tinycensus:::tc_flows_join_geometry(
    out,
    geometry = destination,
    key = "destination_geoid",
    geometry_name = "destination_geometry"
  )

  expect_equal(out$origin_geoid, data$origin_geoid)
  expect_equal(out$destination_geoid, data$destination_geoid)
  expect_true(all(c("origin_geo_STATEFP", "destination_geo_STATEFP") %in% names(out)))
})
