tc_flows_query_geography <- function(geography, year) {
  geography <- tc_normalize_geography_name(geography)

  if (
    geography %in%
      c(
        'metropolitan statistical area/micropolitan statistical area',
        'cbsa'
      )
  ) {
    if (year <= 2012L) {
      cli::cli_abort(
        'Metropolitan area flows are only available beginning with 2013-style ACS flows releases.'
      )
    }

    if (year <= 2015L) {
      return('metropolitan statistical areas')
    }

    return('metropolitan statistical area/micropolitan statistical area')
  }

  geography
}

tc_flows_base_url <- function(year) {
  paste0(tc_api_base(), '/', year, '/acs/flows')
}

tc_flows_default_variables <- function() {
  c(
    'GEOID1',
    'GEOID2',
    'FULL1_NAME',
    'FULL2_NAME',
    'MOVEDIN',
    'MOVEDIN_M',
    'MOVEDOUT',
    'MOVEDOUT_M',
    'MOVEDNET',
    'MOVEDNET_M'
  )
}

tc_flows_breakdown_codebook <- function(variable, year) {
  variable <- toupper(variable)

  if (year > 2015L) {
    return(NULL)
  }

  if (identical(variable, 'AGE')) {
    return(tibble::tibble(
      code = sprintf('%02d', 1:15),
      label = c(
        '1 to 4 years',
        '5 to 17 years',
        '18 to 19 years',
        '20 to 24 years',
        '25 to 29 years',
        '30 to 34 years',
        '35 to 39 years',
        '40 to 44 years',
        '45 to 49 years',
        '50 to 54 years',
        '55 to 59 years',
        '60 to 64 years',
        '65 to 69 years',
        '70 to 74 years',
        '75 years and over'
      )
    ))
  }

  if (identical(variable, 'SEX')) {
    return(tibble::tibble(
      code = c('01', '02'),
      label = c('Male', 'Female')
    ))
  }

  if (identical(variable, 'RACE')) {
    return(tibble::tibble(
      code = c('01', '02', '03', '04'),
      label = c(
        'White alone',
        'Black or African American alone',
        'Asian alone',
        'Other race alone or Two or more races'
      )
    ))
  }

  if (identical(variable, 'HISP_ORIGIN')) {
    return(tibble::tibble(
      code = c('01', '02', '03'),
      label = c(
        'White alone, not Hispanic or Latino',
        'Not white alone, not Hispanic or Latino',
        'Hispanic or Latino'
      )
    ))
  }

  NULL
}

tc_flows_add_breakdown_labels <- function(data, breakdown, year) {
  breakdown <- tc_null_if_empty(breakdown)
  if (is.null(breakdown)) {
    return(data)
  }

  out <- data

  for (variable in unique(as.character(breakdown))) {
    if (!variable %in% names(out)) {
      next
    }

    codebook <- tc_flows_breakdown_codebook(variable, year = year)
    if (is.null(codebook)) {
      next
    }

    labels <- stats::setNames(codebook$label, codebook$code)
    label_col <- paste0(variable, '_LABEL')
    formatted <- sprintf('%02d', suppressWarnings(as.integer(out[[variable]])))
    out[[label_col]] <- unname(labels[formatted])
  }

  out
}

tc_flows_validate_inputs <- function(
  geography,
  state = NULL,
  county = NULL,
  msa = NULL,
  breakdown = NULL
) {
  if (!is.null(breakdown) && !is.character(breakdown)) {
    cli::cli_abort('{.arg breakdown} must be a character vector.')
  }

  if (
    !is.null(msa) &&
      !geography %in%
        c(
          'metropolitan statistical area/micropolitan statistical area',
          'cbsa'
        )
  ) {
    cli::cli_abort(
      '{.arg msa} is only supported for metropolitan area flow requests.'
    )
  }

  if (identical(geography, 'county') && !is.null(county)) {
    if (is.null(state) || length(state) != 1L) {
      cli::cli_abort(
        'County flow requests for specific counties require exactly one {.arg state}.'
      )
    }
  }

  if (identical(geography, 'county subdivision')) {
    if (is.null(state)) {
      cli::cli_abort(
        'County subdivision flows require at least one {.arg state}.'
      )
    }

    if (!is.null(county) && length(state) != 1L) {
      cli::cli_abort(
        'County subdivision flow requests with {.arg county} require exactly one {.arg state}.'
      )
    }
  }

  if (
    geography %in%
      c(
        'metropolitan statistical area/micropolitan statistical area',
        'cbsa'
      ) &&
      (!is.null(state) || !is.null(county))
  ) {
    cli::cli_abort(
      'Metropolitan area flows do not accept {.arg state} or {.arg county}.'
    )
  }
}

tc_flows_query <- function(
  year,
  geography,
  variables = NULL,
  breakdown = NULL,
  key = tc_get_key(),
  state = NULL,
  county = NULL,
  msa = NULL
) {
  if (year < 2010L || year > 2018L) {
    cli::cli_abort(
      'ACS migration flows are available for years 2010 through 2018.'
    )
  }

  geography <- tc_normalize_geography_name(geography)
  if (
    !geography %in%
      c(
        'county',
        'county subdivision',
        'metropolitan statistical area/micropolitan statistical area',
        'cbsa'
      )
  ) {
    cli::cli_abort(
      'Flows geography must be county, county subdivision, or metropolitan statistical area.'
    )
  }

  if (!is.null(breakdown) && year > 2015L) {
    cli::cli_abort(
      'Flow breakdown characteristics are only available through 2015.'
    )
  }

  tc_flows_validate_inputs(
    geography = geography,
    state = state,
    county = county,
    msa = msa,
    breakdown = breakdown
  )

  query_geography <- tc_flows_query_geography(geography, year)
  get_vars <- unique(c(tc_flows_default_variables(), breakdown, variables))
  for_area <- paste0(query_geography, ':*')
  in_area <- NULL

  if (!is.null(state)) {
    state <- paste(normalize_state(state), collapse = ',')
  }

  if (!is.null(county)) {
    if (is.null(state)) {
      cli::cli_abort(
        'County flows require {.arg state} when {.arg county} is supplied.'
      )
    }
    county <- paste(
      normalize_county(county, state = state, year = year),
      collapse = ','
    )
  }

  if (!is.null(msa)) {
    msa <- paste(as.character(msa), collapse = ',')
  }

  if (identical(geography, 'county')) {
    if (!is.null(county)) {
      for_area <- paste0('county:', county)
    }
    if (!is.null(state)) {
      in_area <- paste0('state:', state)
    }
  }

  if (identical(geography, 'county subdivision')) {
    if (!is.null(county)) {
      in_area <- paste0('state:', state, ' county:', county)
    } else {
      in_area <- paste0('state:', state)
    }
  }

  if (
    geography %in%
      c(
        'metropolitan statistical area/micropolitan statistical area',
        'cbsa'
      ) &&
      !is.null(msa)
  ) {
    for_area <- paste0(query_geography, ':', msa)
  }

  params <- tc_compact(list(
    get = paste(get_vars, collapse = ','),
    'for' = for_area,
    'in' = in_area,
    key = if (nzchar(key)) key else NULL
  ))

  raw <- tc_fetch_json(
    tc_build_url(tc_flows_base_url(year), params),
    context = list(dataset = 'acs/flows', year = year, geography = geography)
  )
  out <- tc_json_matrix_to_tibble(raw)

  for (column in names(out)) {
    if (!grepl('_NAME$|^GEOID|^STATE|^COUNTY|^MCD|^METRO|^FULL', column)) {
      out[[column]] <- suppressWarnings(as.numeric(out[[column]]))
    }
  }

  out
}

tc_flows_clean_names <- function(data) {
  rename <- c(
    GEOID1 = 'origin_geoid',
    GEOID2 = 'destination_geoid',
    FULL1_NAME = 'origin_name',
    FULL2_NAME = 'destination_name',
    MOVEDIN = 'moved_in',
    MOVEDIN_M = 'moved_in_moe',
    MOVEDOUT = 'moved_out',
    MOVEDOUT_M = 'moved_out_moe',
    MOVEDNET = 'moved_net',
    MOVEDNET_M = 'moved_net_moe'
  )
  hits <- intersect(names(rename), names(data))
  names(data)[match(hits, names(data))] <- rename[hits]

  drop <- c(
    'state',
    'county',
    'county subdivision',
    'metropolitan statistical area/micropolitan statistical area',
    'metropolitan statistical areas'
  )
  data[, setdiff(names(data), drop), drop = FALSE]
}

tc_flows_geometry_keys <- function(geoids, geography) {
  geoids <- unique(stats::na.omit(as.character(geoids)))

  if (identical(geography, 'county')) {
    return(tibble::tibble(
      GEOID = geoids,
      state = substr(geoids, 1, 2),
      county = substr(geoids, 3, 5)
    ))
  }

  if (identical(geography, 'county subdivision')) {
    return(tibble::tibble(
      GEOID = geoids,
      state = substr(geoids, 1, 2),
      county = substr(geoids, 3, 5),
      `county subdivision` = substr(geoids, 6, 10)
    ))
  }

  tibble::tibble(
    GEOID = geoids,
    `metropolitan statistical area/micropolitan statistical area` = geoids
  )
}

tc_flows_geometry_frame <- function(geom, key, keep_geo_vars = FALSE) {
  keep <- if (isTRUE(keep_geo_vars)) {
    names(geom)
  } else {
    unique(c('GEOID', 'geometry'))
  }
  geom <- geom[keep[keep %in% names(geom)]]
  names(geom)[match('GEOID', names(geom))] <- key

  geo_cols <- setdiff(names(geom), c(key, 'geometry'))
  if (length(geo_cols)) {
    names(geom)[match(geo_cols, names(geom))] <- paste0('geo_', geo_cols)
  }

  geom
}

tc_flows_join_geometry <- function(data, geometry, key) {
  index <- seq_len(nrow(data))
  data$..tc_rowid.. <- index
  out <- merge(data, geometry, by = key, all.x = TRUE, sort = FALSE)
  out <- out[order(out$..tc_rowid..), , drop = FALSE]
  out$..tc_rowid.. <- NULL

  out
}

tc_flows_geometry_role <- function(geometry) {
  if (isFALSE(geometry)) {
    return(FALSE)
  }

  if (isTRUE(geometry)) {
    return('destination')
  }

  if (is.character(geometry) && length(geometry) == 1L) {
    if (geometry %in% c('destination', 'origin')) {
      return(geometry)
    }
  }

  cli::cli_abort(
    '{.arg geometry} must be one of {.val FALSE}, {.val TRUE}, {.val "destination"}, or {.val "origin"}.'
  )
}

tc_add_flows_geometry <- function(
  data,
  geography,
  year,
  geometry = 'destination',
  keep_geo_vars = FALSE
) {
  key <- paste0(geometry, '_geoid')
  keys <- tc_flows_geometry_keys(data[[key]], geography = geography)
  geom <- tc_fetch_geometry(keys, geography = geography, year = year)
  geom$geometry <- suppressWarnings(sf::st_point_on_surface(geom$geometry))
  geom <- tc_flows_geometry_frame(
    geom,
    key = key,
    keep_geo_vars = keep_geo_vars
  )
  out <- tc_flows_join_geometry(data, geometry = geom, key = key)
  sf::st_as_sf(out, sf_column_name = 'geometry')
}

#' Retrieve ACS migration flows
#'
#' @param geography Flows geography.
#' @param state Optional state input.
#' @param county Optional county input.
#' @param msa Optional metropolitan area codes.
#' @param year ACS migration flows year.
#' @param variables Optional additional variables.
#' @param breakdown Optional breakdown variables.
#' @param breakdown_labels Should label columns be added for supported coded
#'   breakdown variables?
#' @param geometry Should centroid geometry be joined? Use `TRUE` or
#'   `"destination"` for destination geometry, or `"origin"` for origin geometry.
#' @param keep_geo_vars Should source geometry attributes for the selected
#'   geometry role be retained?
#' @param key Optional Census API key.
#' @param refresh Included for consistency with other retrieval helpers. Flows
#'   data are requested directly and do not currently use cached metadata.
#' @return A tibble or `sf` object.
#' @export
tc_get_flows <- function(
  geography,
  state = NULL,
  county = NULL,
  msa = NULL,
  year = 2018,
  variables = NULL,
  breakdown = NULL,
  breakdown_labels = FALSE,
  geometry = FALSE,
  keep_geo_vars = FALSE,
  key = tc_get_key(),
  refresh = FALSE
) {
  geography <- tc_normalize_geography_name(geography)
  geometry_role <- tc_flows_geometry_role(geometry)

  raw <- tc_flows_query(
    year = year,
    geography = geography,
    variables = variables,
    breakdown = breakdown,
    key = key,
    state = state,
    county = county,
    msa = msa
  )
  out <- tc_flows_clean_names(raw)
  if (isTRUE(breakdown_labels)) {
    out <- tc_flows_add_breakdown_labels(
      out,
      breakdown = breakdown,
      year = year
    )
  }

  if (!identical(geometry_role, FALSE)) {
    out <- tc_add_flows_geometry(
      out,
      geography = geography,
      year = year,
      geometry = geometry_role,
      keep_geo_vars = keep_geo_vars
    )
  }

  tc_add_attributes(
    out,
    dataset = 'acs/flows',
    year = year,
    geography = geography
  )
}
