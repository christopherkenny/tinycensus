test_that('tc_get_decennial supports wide output', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('decennial_tidy')

  out <- tc_get_decennial(
    year = 2020,
    dataset = 'pl',
    variables = 'P1_001N',
    geography = 'county',
    state = 'Delaware'
  )

  expect_s3_class(out, 'tbl_df')
  expect_true('P1_001N' %in% names(out))
  expect_true(all(out$state == '10'))
})

test_that('tc_get_decennial accepts NAME in requested variables', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('decennial_name_variable')

  out <- tc_get_decennial(
    year = 2020,
    dataset = 'dhc',
    variables = c('NAME', 'P1_001N'),
    geography = 'block group',
    within = list(state = '36', county = '027', tract = '220300')
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c('NAME', 'P1_001N') %in% names(out)))
})

test_that('tc_get_decennial fills wildcard parent geographies when supported', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('decennial_block_group_wildcard_parent')

  out <- tc_get_decennial(
    geography = 'block group',
    variables = c(
      tot_male_youth = 'P18_005N',
      tot_male_adult = 'P18_015N',
      tot_male_senior = 'P18_025N',
      tot_female_youth = 'P18_036N',
      tot_female_adult = 'P18_046N',
      tot_female_senior = 'P18_056N'
    ),
    year = 2020,
    state = 'FL',
    county = 'Gadsden',
    dataset = 'dhc'
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c(
    'tract',
    'block group',
    'tot_male_youth',
    'tot_female_senior'
  ) %in% names(out)))
  expect_true(all(out$state == '12'))
  expect_true(all(out$county == '039'))
  expect_true(nrow(out) > 1)
})

test_that('tc_get_decennial supports block geometry with wildcard tract parents', {
  skip_if_not_installed('vcr')
  skip_if_not_installed('sf')
  skip_if_offline()
  vcr::local_cassette('decennial_block_geometry')

  out <- tc_get_decennial(
    geography = 'block',
    variables = c(
      tot_male_youth = 'P18_005N',
      tot_male_adult = 'P18_015N',
      tot_male_senior = 'P18_025N',
      tot_female_youth = 'P18_036N',
      tot_female_adult = 'P18_046N',
      tot_female_senior = 'P18_056N'
    ),
    year = 2020,
    state = 'FL',
    county = 'Gadsden',
    dataset = 'dhc',
    geometry = TRUE
  )

  expect_true(inherits(out, 'sf'))
  expect_true(inherits(out, 'tbl_df'))
  expect_true(all(c('GEOID', 'tract', 'block', 'tot_male_youth') %in% names(out)))
  expect_true(all(out$state == '12'))
  expect_true(all(out$county == '039'))
  expect_true(nrow(out) > 1)
})

test_that('tc_get_decennial preserves named variable aliases', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('decennial_named_aliases')

  out <- tc_get_decennial(
    year = 2020,
    dataset = 'pl',
    variables = c(pop = 'P1_001N', pop_hisp = 'P2_002N'),
    geography = 'state',
    state = 'DE'
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c('pop', 'pop_hisp') %in% names(out)))
  expect_false(any(c('P1_001N', 'P2_002N') %in% names(out)))
})

test_that('tc_get_decennial handles chunked variable requests with stable aliases and order', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('decennial_chunked_variables')

  vars <- tc_variables('dec/dhc', 2020)
  vars <- vars$name[grepl('^[A-Z0-9]+_[0-9]+N$', vars$name)][1:55]
  aliases <- stats::setNames(vars, paste0('metric_', seq_along(vars)))
  control_aliases <- aliases[c(1, 25, 49)]

  out <- tc_get_decennial(
    year = 2020,
    dataset = 'dhc',
    variables = aliases,
    geography = 'state',
    state = c('DE', 'NY')
  )

  control <- tc_get_decennial(
    year = 2020,
    dataset = 'dhc',
    variables = control_aliases,
    geography = 'state',
    state = c('DE', 'NY')
  )

  alias_names <- names(aliases)
  control_names <- names(control_aliases)

  expect_s3_class(out, 'tbl_df')
  expect_true(all(alias_names %in% names(out)))
  expect_identical(names(out)[names(out) %in% alias_names], alias_names)
  expect_equal(out$GEOID, control$GEOID)
  expect_equal(out[control_names], control[control_names])
  expect_equal(anyDuplicated(out$GEOID), 0L)
})
