source_rda_object <- function(url, object_name) {
  path <- tempfile(fileext = '.rda')
  utils::download.file(url, path, mode = 'wb', quiet = FALSE)

  env <- new.env(parent = emptyenv())
  load(path, envir = env)
  env[[object_name]]
}

normalize_county_table <- function(x) {
  x <- as.data.frame(
    x[, c('state', 'county', 'name')],
    stringsAsFactors = FALSE
  )
  x$state <- sprintf('%02d', as.integer(x$state))
  x$county <- sprintf('%03d', as.integer(x$county))
  x$name <- as.character(x$name)
  x[order(x$state, x$county), ]
}

fetch_json_matrix <- function(url) {
  req <- httr2::request(url) |>
    httr2::req_user_agent(
      'tinycensus data-raw (https://github.com/christopherkenny/tinycensus)'
    ) |>
    httr2::req_retry(max_tries = 3)

  resp <- httr2::req_perform(req)
  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

fetch_ct_planning_regions <- function() {
  json <- fetch_json_matrix(
    'https://api.census.gov/data/2024/acs/acs5?get=NAME&for=county:*&in=state:09'
  )

  out <- data.frame(
    state = json[-1, 2],
    county = json[-1, 3],
    name = sub(', Connecticut$', '', json[-1, 1]),
    stringsAsFactors = FALSE
  )

  out[order(out$county), ]
}

manual_county_changes <- function() {
  rbind(
    data.frame(
      year = 2002L,
      state = '08',
      county = '014',
      name = 'Broomfield County',
      change = 'add',
      effective_date = '2001-11-15',
      source = 'Census county changes 2000s',
      stringsAsFactors = FALSE
    ),
    data.frame(
      year = 2002L,
      state = '51',
      county = '560',
      name = 'Clifton Forge city',
      change = 'drop',
      effective_date = '2001-07-01',
      source = 'Census county changes 2000s',
      stringsAsFactors = FALSE
    ),
    data.frame(
      year = 2008L,
      state = c('02', '02', '02'),
      county = c('105', '230', '232'),
      name = c(
        'Hoonah-Angoon Census Area',
        'Skagway Municipality',
        'Skagway-Hoonah-Angoon Census Area'
      ),
      change = c('add', 'add', 'drop'),
      effective_date = c('2007-06-20', '2007-06-20', '2007-06-20'),
      source = 'Census county changes 2000s',
      stringsAsFactors = FALSE
    ),
    data.frame(
      year = 2009L,
      state = c('02', '02', '02', '02', '02'),
      county = c('195', '198', '275', '201', '280'),
      name = c(
        'Petersburg Census Area',
        'Prince of Wales-Hyder Census Area',
        'Wrangell City and Borough',
        'Prince of Wales-Outer Ketchikan Census Area',
        'Wrangell-Petersburg Census Area'
      ),
      change = c('add', 'add', 'add', 'drop', 'drop'),
      effective_date = c(
        '2008-06-01',
        '2008-05-19',
        '2008-06-01',
        '2008-05-19',
        '2008-06-01'
      ),
      source = 'Census county changes 2000s',
      stringsAsFactors = FALSE
    ),
    data.frame(
      year = 2014L,
      state = c('02', '51'),
      county = c('195', '515'),
      name = c('Petersburg Borough', 'Bedford city'),
      change = c('rename', 'drop'),
      effective_date = c('2013-01-03', '2013-07-01'),
      source = 'Census county changes 2010s',
      stringsAsFactors = FALSE
    ),
    data.frame(
      year = 2016L,
      state = c('02', '02', '46', '46'),
      county = c('158', '270', '102', '113'),
      name = c(
        'Kusilvak Census Area',
        'Wade Hampton Census Area',
        'Oglala Lakota County',
        'Shannon County'
      ),
      change = c('add', 'drop', 'add', 'drop'),
      effective_date = c(
        '2015-07-01',
        '2015-07-01',
        '2015-05-01',
        '2015-05-01'
      ),
      source = 'Census county changes 2010s',
      stringsAsFactors = FALSE
    ),
    data.frame(
      year = 2020L,
      state = c('02', '02', '02'),
      county = c('063', '066', '261'),
      name = c(
        'Chugach Census Area',
        'Copper River Census Area',
        'Valdez-Cordova Census Area'
      ),
      change = c('add', 'add', 'drop'),
      effective_date = c('2019-01-02', '2019-01-02', '2019-01-02'),
      source = 'Census county changes 2010s',
      stringsAsFactors = FALSE
    )
  )
}

connecticut_changes <- function() {
  current_ct <- fetch_ct_planning_regions()
  old_ct <- tc_counties_2020[tc_counties_2020$state == '09', , drop = FALSE]

  add_rows <- transform(
    current_ct,
    year = 2022L,
    change = 'add',
    effective_date = '2022-01-01',
    source = 'Census county changes 2020s / ACS 2024 county inventory'
  )

  drop_rows <- transform(
    old_ct,
    year = 2022L,
    change = 'drop',
    effective_date = '2022-01-01',
    source = 'Census county changes 2020s'
  )

  rbind(
    add_rows[, c(
      'year',
      'state',
      'county',
      'name',
      'change',
      'effective_date',
      'source'
    )],
    drop_rows[, c(
      'year',
      'state',
      'county',
      'name',
      'change',
      'effective_date',
      'source'
    )]
  )
}

write_county_changes <- function(
  x,
  path = file.path('data-raw', 'county-changes.csv')
) {
  x <- x[order(x$year, x$state, x$county, x$change), ]
  utils::write.csv(x, path, row.names = FALSE, na = '')
  x
}

read_county_changes <- function(
  path = file.path('data-raw', 'county-changes.csv')
) {
  x <- utils::read.csv(path, stringsAsFactors = FALSE)
  x$year <- as.integer(x$year)
  x$state <- sprintf('%02d', as.integer(x$state))
  x$county <- sprintf('%03d', as.integer(x$county))
  x$name <- as.character(x$name)
  x$change <- as.character(x$change)
  x
}

fips_2000 <- source_rda_object(
  'https://raw.githubusercontent.com/christopherkenny/censable/main/data/fips_2000.rda',
  'fips_2000'
)
fips_2010 <- source_rda_object(
  'https://raw.githubusercontent.com/christopherkenny/censable/main/data/fips_2010.rda',
  'fips_2010'
)
fips_2020 <- source_rda_object(
  'https://raw.githubusercontent.com/christopherkenny/censable/main/data/fips_2020.rda',
  'fips_2020'
)

tc_counties_2000 <- normalize_county_table(fips_2000)
tc_counties_2010 <- normalize_county_table(fips_2010)
tc_counties_2020 <- normalize_county_table(fips_2020)

county_changes <- rbind(manual_county_changes(), connecticut_changes())
tc_county_changes <- write_county_changes(county_changes)
tc_county_changes <- read_county_changes()

save(
  tc_counties_2000,
  tc_counties_2010,
  tc_counties_2020,
  tc_county_changes,
  file = file.path('R', 'sysdata.rda'),
  compress = 'xz'
)
