test_that('tc_get_cbp uses the product interface', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('cbp_states')

  out <- tc_get_cbp(
    year = 2021,
    variables = 'ESTAB',
    geography = 'state',
    state = c('NY', 'DE')
  )

  expect_s3_class(out, 'tbl_df')
  expect_true('ESTAB' %in% names(out))
  expect_equal(sort(out$state), c('10', '36'))
})

test_that('tc_get_cbp supports label variables through encoded values', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('cbp_label_variable')

  out <- tc_get_cbp(
    year = 2021,
    variables = c('EMP', 'ESTAB', 'NAICS2017_LABEL'),
    geography = 'county',
    state = 'DE',
    predicates = list(NAICS2017 = '23')
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c('EMP', 'ESTAB', 'NAICS2017_LABEL') %in% names(out)))
  expect_false('NAICS2017' %in% names(out))
  expect_true(any(nzchar(out$NAICS2017_LABEL)))
})

test_that('tc_get_cbp accepts named atomic vectors for predicates', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('cbp_named_predicates')

  out <- tc_get_cbp(
    year = 2021,
    geography = 'state',
    state = 'TX',
    variables = c(establishments = 'ESTAB'),
    predicates = c(NAICS2017 = '72')
  )

  expect_s3_class(out, 'tbl_df')
  expect_true('establishments' %in% names(out))
})
