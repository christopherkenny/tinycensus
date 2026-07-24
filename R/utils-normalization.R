match_state_abb <- function(x) {
  x <- as.character(x)
  idx <- match(toupper(x), tc_state_lookup$abb)
  tc_state_lookup$fips[idx]
}

match_state_name <- function(x) {
  x <- tc_clean_name(as.character(x))
  idx <- match(x, tc_clean_name(tc_state_lookup$name))
  tc_state_lookup$fips[idx]
}

match_state_fips <- function(x) {
  x <- as.character(x)
  idx <- grepl('^\\d{1,2}$', x)
  x[idx] <- sprintf('%02d', as.integer(x[idx]))
  valid <- x %in% tc_state_lookup$fips

  out <- rep(NA_character_, length(x))
  out[valid] <- x[valid]
  out
}

normalize_state <- function(x) {
  x <- as.character(x)
  out <- match_state_fips(x)

  need <- is.na(out)
  out[need] <- match_state_abb(x[need])

  need <- is.na(out)
  out[need] <- match_state_name(x[need])

  if (anyNA(out)) {
    bad <- unique(x[is.na(out)])
    cli::cli_abort('Could not match state input(s): {.val {bad}}.')
  }

  out
}

tc_county_base_year <- function(year) {
  year <- as.integer(year %||% 2020L)

  if (is.na(year)) {
    return(2020L)
  }

  if (year < 2010L) {
    return(2000L)
  }

  if (year < 2020L) {
    return(2010L)
  }

  2020L
}

tc_county_table_name <- function(year) {
  switch(as.character(year),
    '2000' = 'tc_counties_2000',
    '2010' = 'tc_counties_2010',
    '2020' = 'tc_counties_2020',
    cli::cli_abort(
      'No bundled county table is available for year {.val {year}}.'
    )
  )
}

tc_counties_for_year <- function(year) {
  base_year <- tc_county_base_year(year)
  table_name <- tc_county_table_name(base_year)
  out <- switch(table_name,
    tc_counties_2000 = tc_counties_2000,
    tc_counties_2010 = tc_counties_2010,
    tc_counties_2020 = tc_counties_2020
  )
  changes <- tc_county_changes

  if (!nrow(changes)) {
    return(out)
  }

  year <- as.integer(year %||% base_year)

  if (year == base_year) {
    return(out)
  }

  changes <- changes[
    changes$year > base_year & changes$year <= year, ,
    drop = FALSE
  ]

  if (!nrow(changes)) {
    return(out)
  }

  for (i in seq_len(nrow(changes))) {
    row <- changes[i, , drop = FALSE]
    key <- out$state == row$state & out$county == row$county

    if (row$change == 'drop') {
      out <- out[!key, , drop = FALSE]
      next
    }

    if (row$change == 'rename' && any(key)) {
      out$name[key] <- row$name
      next
    }

    if (row$change == 'add' && !any(key)) {
      out <- rbind(out, row[c('state', 'county', 'name')])
    }
  }

  out[order(out$state, out$county), , drop = FALSE]
}

normalize_county <- function(x, state, year = NULL) {
  x <- as.character(x)
  state <- normalize_state(state)
  state <- tc_recycle(state, length(x), arg = 'state')

  out <- rep(NA_character_, length(x))
  numeric_idx <- grepl('^\\d{1,3}$', x)
  out[numeric_idx] <- sprintf('%03d', as.integer(x[numeric_idx]))

  lookup <- tc_counties_for_year(year)
  lookup$county_name <- tc_clean_county_name(lookup$name)
  lookup$name_clean <- tc_clean_name(lookup$name)

  for (i in which(is.na(out))) {
    state_lookup <- lookup[lookup$state == state[[i]], , drop = FALSE]
    county_clean <- tc_clean_county_name(x[[i]])
    hits <- state_lookup$county[state_lookup$county_name == county_clean]

    if (!length(hits)) {
      hits <- state_lookup$county[
        state_lookup$name_clean == tc_clean_name(x[[i]])
      ]
    }

    if (!length(hits)) {
      cli::cli_abort(
        'Could not match county {.val {x[[i]]}} within state {.val {state[[i]]}} for year {.val {year %||% tc_county_base_year(year)}}.'
      )
    }

    if (length(hits) > 1L) {
      cli::cli_abort(
        'County input {.val {x[[i]]}} is ambiguous within state {.val {state[[i]]}} for year {.val {year %||% tc_county_base_year(year)}}.'
      )
    }

    out[[i]] <- hits[[1]]
  }

  out
}
