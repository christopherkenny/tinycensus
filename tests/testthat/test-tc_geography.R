test_that('county inputs normalize through public wrappers', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_county_name_normalization')

  out <- tc_get_acs(
    year = 2022,
    variables = 'B01001_001E',
    geography = 'county',
    state = 'NY',
    county = 'Albany County'
  )

  expect_s3_class(out, 'tbl_df')
  expect_identical(out$county, '001')
  expect_identical(out$state, '36')
})

test_that('public wrappers honor geography_vintage for county normalization', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_geography_vintage')

  out <- tc_get_acs(
    year = 2022,
    variables = 'B01001_001E',
    geography = 'county',
    state = 'CO',
    county = 'Broomfield County',
    geography_vintage = 2002
  )

  expect_s3_class(out, 'tbl_df')
  expect_identical(out$county, '014')

  expect_error(
    tc_get_acs(
      year = 2022,
      variables = 'B01001_001E',
      geography = 'county',
      state = 'CO',
      county = 'Broomfield County',
      geography_vintage = 2001
    ),
    'Could not match county'
  )
})

test_that('within accepts named atomic vectors through public wrappers', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_block_group_within_vector')

  out <- tc_get_acs(
    year = 2020,
    variables = 'B19013_001E',
    geography = 'block group',
    within = c(state = '26', county = '161', tract = '400100')
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c('state', 'county', 'tract', 'block group') %in% names(out)))
})
