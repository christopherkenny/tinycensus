test_that('tc_get_flows returns wide output', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('flows_tidy')

  out <- tc_get_flows(
    geography = 'county',
    year = 2018,
    state = 'NY',
    county = '001'
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c(
    'origin_geoid',
    'destination_geoid',
    'moved_in',
    'moved_in_moe',
    'moved_out',
    'moved_out_moe',
    'moved_net',
    'moved_net_moe'
  ) %in% names(out)))
})

test_that('tc_get_flows validates geography-specific inputs', {
  expect_error(
    tc_get_flows(
      geography = 'county subdivision',
      year = 2018,
      state = c('NY', 'NJ'),
      county = '001'
    ),
    'require exactly one .*state'
  )

  expect_error(
    tc_get_flows(
      geography = 'county',
      year = 2018,
      msa = '10580'
    ),
    'msa.*only supported'
  )
})

test_that('tc_get_flows defaults to destination geometry and preserves row order', {
  skip_if_not_installed('vcr')
  skip_if_not_installed('sf')
  skip_if_offline()
  vcr::local_cassette('flows_geometry')

  tabular <- tc_get_flows(
    geography = 'county',
    year = 2018,
    state = 'NY',
    county = '001'
  )

  spatial <- tc_get_flows(
    geography = 'county',
    year = 2018,
    state = 'NY',
    county = '001',
    geometry = TRUE,
    keep_geo_vars = TRUE
  )

  expect_true(inherits(spatial, 'sf'))
  expect_equal(spatial$origin_geoid, tabular$origin_geoid)
  expect_equal(spatial$destination_geoid, tabular$destination_geoid)
  expect_true('geo_STATEFP' %in% names(spatial))
  expect_false('destination_geometry' %in% names(spatial))
})

test_that('tc_get_flows can use origin geometry explicitly', {
  skip_if_not_installed('vcr')
  skip_if_not_installed('sf')
  skip_if_offline()
  vcr::local_cassette('flows_geometry')

  origin <- tc_get_flows(
    geography = 'county',
    year = 2018,
    state = 'NY',
    county = '001',
    geometry = 'origin',
    keep_geo_vars = TRUE
  )

  expect_true(inherits(origin, 'sf'))
  expect_true('geo_STATEFP' %in% names(origin))
})

test_that('tc_get_flows validates geometry role', {
  expect_error(
    tc_get_flows(
      geography = 'county',
      year = 2018,
      state = 'NY',
      county = '001',
      geometry = 'both'
    ),
    'geometry.*must be one of'
  )
})

test_that('tc_get_flows can add labels for supported breakdowns', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('flows_breakdown_labels')

  out <- tc_get_flows(
    geography = 'county subdivision',
    breakdown = 'RACE',
    breakdown_labels = TRUE,
    year = 2015,
    state = 'NY',
    county = '119'
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c('RACE', 'RACE_LABEL') %in% names(out)))
  expect_true(any(nzchar(stats::na.omit(out$RACE_LABEL))))
})

test_that('tc_get_flows accepts refresh for interface consistency', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('flows_tidy')

  out <- tc_get_flows(
    geography = 'county',
    year = 2018,
    state = 'NY',
    county = '001',
    refresh = TRUE
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(nrow(out) > 0)
})
