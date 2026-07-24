test_that('tc_get_acs returns wide output for variable queries', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_tidy')

  out <- tc_get_acs(
    year = 2024,
    variables = 'B01001_001E',
    geography = 'state',
    state = c('NY', 'Delaware')
  )

  expect_s3_class(out, 'tbl_df')
  expect_true('B01001_001E' %in% names(out))
  expect_equal(sort(out$state), c('10', '36'))
  expect_true(!anyNA(out$NAME))
})

test_that('tc_get_acs returns table queries with summary variables', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_table')

  out <- tc_get_acs(
    year = 2024,
    table = 'B01001',
    summary_var = 'B01001_001E',
    geography = 'state',
    state = 'NY'
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c(
    'B01001_002E',
    'B01001_002M',
    'summary_estimate',
    'summary_moe'
  ) %in% names(out)))
  expect_false(is.na(out$summary_estimate[[1]]))
})

test_that('tc_get_acs supports geometry and keep_geo_vars', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_geometry_keep')

  minimal <- tc_get_acs(
    year = 2024,
    variables = 'B01001_001E',
    geography = 'state',
    state = c('NY', 'Delaware'),
    geometry = TRUE
  )

  rich <- tc_get_acs(
    year = 2024,
    variables = 'B01001_001E',
    geography = 'state',
    state = c('NY', 'Delaware'),
    geometry = TRUE,
    keep_geo_vars = TRUE
  )

  expect_true(inherits(minimal, 'sf'))
  expect_true(inherits(rich, 'sf'))
  expect_true(inherits(minimal, 'tbl_df'))
  expect_true(inherits(rich, 'tbl_df'))
  expect_false('STATEFP' %in% names(minimal))
  expect_true('STATEFP' %in% names(rich))
})

test_that('tc_get_acs errors clearly for invalid variables', {
  skip_if_offline()

  expect_error(
    tc_get_acs(
      year = 2024,
      variables = 'NOT_A_REAL_VARIABLE',
      geography = 'state',
      state = 'NY'
    ),
    'Unknown variable'
  )
})

test_that('tc_get_acs validates summary_var against dataset and table inputs', {
  expect_error(
    tc_get_acs(
      year = 2024,
      variables = 'B01001_001E',
      summary_var = 'NOT_A_REAL_VARIABLE',
      geography = 'state',
      state = 'NY'
    ),
    'Unknown .*summary_var'
  )

  expect_error(
    tc_get_acs(
      year = 2024,
      table = 'B01001',
      summary_var = 'B19013_001E',
      geography = 'state',
      state = 'NY'
    ),
    'must belong to table'
  )
})

test_that('tc_get_acs keeps ucgid separate from explicit geography inputs', {
  expect_error(
    tc_get_acs(
      year = 2024,
      variables = 'B01001_001E',
      geography = 'state',
      state = 'NY',
      ucgid = '0400000US36'
    ),
    'mutually exclusive'
  )
})

test_that('tc_get_acs validates geography inputs through the public interface', {
  expect_error(
    tc_get_acs(
      year = 2024,
      variables = 'B01001_001E',
      county = '001',
      counties = '003'
    ),
    'must be unique'
  )

  expect_error(
    tc_get_acs(
      year = 2024,
      variables = 'B01001_001E',
      state = 'NY',
      county = '001'
    ),
    'Supply an explicit .*geography'
  )
})

test_that('tc_get_acs supports less-common geography aliases', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_less_common_geographies')

  cd <- tc_get_acs(
    year = 2024,
    variables = 'B01001_001E',
    geography = 'congressional districts',
    state = 'NY'
  )

  place <- tc_get_acs(
    year = 2024,
    variables = 'B01001_001E',
    geography = 'places',
    state = 'Delaware'
  )

  expect_s3_class(cd, 'tbl_df')
  expect_s3_class(place, 'tbl_df')
  expect_true('congressional district' %in% names(cd))
  expect_true('place' %in% names(place))
  expect_true(all(cd$state == '36'))
  expect_true(all(place$state == '10'))
})

test_that('tc_get_acs accepts NAME in requested variables', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_name_variable')

  out <- tc_get_acs(
    year = 2022,
    variables = c('NAME', 'B01001_001E', 'B19013_001E'),
    geography = 'place',
    state = '01'
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c('NAME', 'B01001_001E', 'B19013_001E') %in% names(out)))
})

test_that('tc_get_acs preserves named variable aliases', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_named_aliases')

  out <- tc_get_acs(
    year = 2022,
    variables = c(total_pop = 'B01001_001E', med_income = 'B19013_001E'),
    geography = 'state',
    state = 'DE'
  )

  expect_s3_class(out, 'tbl_df')
  expect_true(all(c('total_pop', 'med_income') %in% names(out)))
  expect_false(any(c('B01001_001E', 'B19013_001E') %in% names(out)))
})

test_that('tc_get_acs handles chunked variable requests with stable aliases and order', {
  skip_if_not_installed('vcr')
  skip_if_offline()
  vcr::local_cassette('acs_chunked_variables')

  vars <- tc_variables('acs/acs5', 2022)
  vars <- vars$name[grepl('^[A-Z0-9]+_[0-9]+E$', vars$name)][1:55]
  aliases <- stats::setNames(vars, paste0('metric_', seq_along(vars)))
  control_aliases <- aliases[c(1, 25, 49)]

  out <- tc_get_acs(
    year = 2022,
    variables = aliases,
    geography = 'state',
    state = c('DE', 'NY')
  )

  control <- tc_get_acs(
    year = 2022,
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

test_that('tc_get_acs geometry preserves row order across supported geographies', {
  skip_if_not_installed('vcr')
  skip_if_not_installed('sf')
  skip_if_offline()
  vcr::local_cassette('acs_geometry_geographies')

  expect_geometry_roundtrip <- function(tabular, spatial, geo_cols, geo_var) {
    expect_true(inherits(spatial, 'sf'))
    expect_true(inherits(spatial, 'tbl_df'))
    expect_identical(spatial$GEOID, tabular$GEOID)
    spatial_df <- sf::st_drop_geometry(spatial)
    for (col in geo_cols) {
      expect_equal(spatial_df[[col]], tabular[[col]])
    }
    expect_equal(anyDuplicated(names(spatial)), 0L)
    expect_true(geo_var %in% names(spatial))
  }

  tract_tab <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'tract',
    state = 'NY',
    county = '061'
  )
  tract_sf <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'tract',
    state = 'NY',
    county = '061',
    geometry = TRUE,
    keep_geo_vars = TRUE
  )
  expect_geometry_roundtrip(
    tract_tab,
    tract_sf,
    c('GEOID', 'NAME', 'state', 'county', 'tract', 'B19013_001E'),
    'TRACTCE'
  )

  block_group_tab <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'block group',
    state = 'NY',
    county = '061',
    tract = '000100'
  )
  block_group_sf <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'block group',
    state = 'NY',
    county = '061',
    tract = '000100',
    geometry = TRUE,
    keep_geo_vars = TRUE
  )
  expect_geometry_roundtrip(
    block_group_tab,
    block_group_sf,
    c('GEOID', 'NAME', 'state', 'county', 'tract', 'block group', 'B19013_001E'),
    'BLKGRPCE'
  )

  county_subdivision_tab <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'county subdivision',
    state = 'NY',
    county = '119'
  )
  county_subdivision_sf <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'county subdivision',
    state = 'NY',
    county = '119',
    geometry = TRUE,
    keep_geo_vars = TRUE
  )
  expect_geometry_roundtrip(
    county_subdivision_tab,
    county_subdivision_sf,
    c('GEOID', 'NAME', 'state', 'county', 'county subdivision', 'B19013_001E'),
    'COUSUBFP'
  )

  congressional_district_tab <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'congressional district',
    state = 'NY',
    `congressional district` = c('01', '02')
  )
  congressional_district_sf <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'congressional district',
    state = 'NY',
    `congressional district` = c('01', '02'),
    geometry = TRUE,
    keep_geo_vars = TRUE
  )
  expect_geometry_roundtrip(
    congressional_district_tab,
    congressional_district_sf,
    c('GEOID', 'NAME', 'state', 'congressional district', 'B19013_001E'),
    'STATEFP'
  )

  zcta_tab <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'zcta',
    zcta = c('10001', '10002')
  )
  zcta_sf <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'zcta',
    zcta = c('10001', '10002'),
    geometry = TRUE,
    keep_geo_vars = TRUE
  )
  expect_geometry_roundtrip(
    zcta_tab,
    zcta_sf,
    c('GEOID', 'NAME', 'zip code tabulation area', 'B19013_001E'),
    'GEOID20'
  )

  cbsa_tab <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'cbsa',
    cbsa = c('10580', '35620')
  )
  cbsa_sf <- tc_get_acs(
    year = 2022,
    variables = 'B19013_001E',
    geography = 'cbsa',
    cbsa = c('10580', '35620'),
    geometry = TRUE,
    keep_geo_vars = TRUE
  )
  expect_geometry_roundtrip(
    cbsa_tab,
    cbsa_sf,
    c(
      'GEOID',
      'NAME',
      'metropolitan statistical area/micropolitan statistical area',
      'B19013_001E'
    ),
    'CBSAFP'
  )
})
