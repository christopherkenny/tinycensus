tc_geometry_year <- function(year) {
  current <- as.integer(format(Sys.Date(), "%Y"))
  max(min(as.integer(year), current), 2011L)
}

tc_geometry_bind <- function(parts) {
  if (!length(parts)) {
    cli::cli_abort("No geometry was available for the requested result.")
  }

  if (length(parts) == 1L) {
    return(parts[[1]])
  }

  do.call(rbind, parts)
}

tc_fetch_geometry <- function(data, geography, year) {
  tiger_year <- tc_geometry_year(year)

  if (geography == "state") {
    geom <- tinytiger::tt_states(year = tiger_year)
    geom$GEOID <- geom$STATEFP
    return(geom)
  }

  if (geography == "county") {
    parts <- lapply(tc_unique(data$state), function(state) {
      geom <- tinytiger::tt_counties(state = state, year = tiger_year)
      geom$GEOID <- paste0(geom$STATEFP, geom$COUNTYFP)
      geom
    })
    return(tc_geometry_bind(parts))
  }

  if (geography == "tract") {
    combos <- unique(data[c("state", "county")])
    parts <- lapply(seq_len(nrow(combos)), function(i) {
      geom <- tinytiger::tt_tracts(
        state = combos$state[[i]],
        county = combos$county[[i]],
        year = tiger_year
      )
      geom$GEOID <- paste0(geom$STATEFP, geom$COUNTYFP, geom$TRACTCE)
      geom
    })
    return(tc_geometry_bind(parts))
  }

  if (geography == "block group") {
    combos <- unique(data[c("state", "county")])
    parts <- lapply(seq_len(nrow(combos)), function(i) {
      geom <- tinytiger::tt_block_groups(
        state = combos$state[[i]],
        county = combos$county[[i]],
        year = tiger_year
      )
      geom$GEOID <- paste0(
        geom$STATEFP,
        geom$COUNTYFP,
        geom$TRACTCE,
        geom$BLKGRPCE
      )
      geom
    })
    return(tc_geometry_bind(parts))
  }

  if (geography == "place") {
    parts <- lapply(tc_unique(data$state), function(state) {
      geom <- tinytiger::tt_places(state = state, year = tiger_year)
      geom$GEOID <- paste0(geom$STATEFP, geom$PLACEFP)
      geom
    })
    return(tc_geometry_bind(parts))
  }

  if (geography == "zip code tabulation area") {
    geom <- tinytiger::tt_zcta(year = tiger_year)
    if (!"GEOID" %in% names(geom) && "ZCTA5CE20" %in% names(geom)) {
      geom$GEOID <- geom$ZCTA5CE20
    }
    return(geom)
  }

  if (geography == "congressional district") {
    parts <- lapply(tc_unique(data$state), function(state) {
      geom <- tinytiger::tt_congressional_districts(
        state = state,
        year = tiger_year
      )
      district <- if ("CD119FP" %in% names(geom)) {
        geom$CD119FP
      } else if ("CD118FP" %in% names(geom)) {
        geom$CD118FP
      } else {
        geom$CDFP
      }
      geom$GEOID <- paste0(geom$STATEFP, district)
      geom
    })
    return(tc_geometry_bind(parts))
  }

  cli::cli_abort(
    "Geometry is not yet supported for geography {.val {geography}} through {.pkg tinytiger}."
  )
}

tc_add_geometry <- function(data, geography, year) {
  if (!"GEOID" %in% names(data)) {
    cli::cli_abort(
      "Geometry requests require a deterministic `GEOID` for the requested geography."
    )
  }

  geom <- tc_fetch_geometry(data, geography = geography, year = year)
  keep <- unique(c("GEOID", "geometry"))
  geom <- geom[keep[keep %in% names(geom)]]

  merge(geom, data, by = "GEOID", all.y = TRUE, sort = FALSE)
}
