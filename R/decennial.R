tc_decennial <- function(geography, variables, year = 2020, state = NULL, county = NULL) {

  req <- httr2::request('https://api.census.gov/data') |>
    httr2::req_url_path_append(year)
}
