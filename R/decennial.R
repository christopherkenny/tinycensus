tc_decennial <- function(geography, variables, year = 2020, state = NULL, county = NULL) {
  if (missing(geography)) {
    cli::cli_abort('{.arg geography} is missing, but required.')
  }
  if (length(geography) != 1) {
    cli::cli_abort('{.arg geography} must be a character vector of length 1.')
  }

  req <- httr2::request('https://api.census.gov/data') |>
    httr2::req_url_path_append(year, 'dec')

  resp <- req |>
    httr2::req_perform() |>
    httr2::resp_body_json(simplifyVector = TRUE) |>
    as_tib()

  resp
}
