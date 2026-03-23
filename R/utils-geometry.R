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

  if (geography == "county subdivision") {
    combos <- unique(data[c("state", "county")])
    parts <- lapply(seq_len(nrow(combos)), function(i) {
      geom <- tinytiger::tt_county_subdivisions(
        state = combos$state[[i]],
        county = combos$county[[i]],
        year = tiger_year
      )
      geom$GEOID <- paste0(geom$STATEFP, geom$COUNTYFP, geom$COUSUBFP)
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

  if (
    geography %in% c(
      "metropolitan statistical area/micropolitan statistical area",
      "cbsa"
    )
  ) {
    geom <- tinytiger::tt_cbsa(year = tiger_year)
    geom$GEOID <- geom$CBSAFP
    return(geom)
  }

  if (geography == "metropolitan division") {
    geom <- tinytiger::tt_metropolitan_divisions(year = tiger_year)
    geom$GEOID <- geom$METDIVFP
    return(geom)
  }

  if (geography == "combined statistical area") {
    geom <- tinytiger::tt_csa(year = tiger_year)
    geom$GEOID <- geom$CSAFP
    return(geom)
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
      cd_col <- grep("^CD[0-9]{3}FP$", names(geom), value = TRUE)
      district <- if (length(cd_col)) {
        geom[[cd_col[[1]]]]
      } else {
        geom$CDFP
      }
      geom$GEOID <- paste0(geom$STATEFP, district)
      geom
    })
    return(tc_geometry_bind(parts))
  }

  if (geography == "school district (elementary)") {
    parts <- lapply(tc_unique(data$state), function(state) {
      geom <- tinytiger::tt_elementary_school_districts(
        state = state,
        year = tiger_year
      )
      geom$GEOID <- paste0(geom$STATEFP, geom$ELSDLEA)
      geom
    })
    return(tc_geometry_bind(parts))
  }

  if (geography == "school district (secondary)") {
    parts <- lapply(tc_unique(data$state), function(state) {
      geom <- tinytiger::tt_secondary_school_districts(
        state = state,
        year = tiger_year
      )
      geom$GEOID <- paste0(geom$STATEFP, geom$SCSDLEA)
      geom
    })
    return(tc_geometry_bind(parts))
  }

  if (geography == "school district (unified)") {
    parts <- lapply(tc_unique(data$state), function(state) {
      geom <- tinytiger::tt_unified_school_districts(
        state = state,
        year = tiger_year
      )
      geom$GEOID <- paste0(geom$STATEFP, geom$UNSDLEA)
      geom
    })
    return(tc_geometry_bind(parts))
  }

  cli::cli_abort(
    "Geometry is not yet supported for geography {.val {geography}} through {.pkg tinytiger}."
  )
}

tc_add_geometry <- function(data, geography, year, keep_geo_vars = FALSE) {
  if (!"GEOID" %in% names(data)) {
    cli::cli_abort(
      "Geometry requests require a deterministic `GEOID` for the requested geography."
    )
  }

  geom <- tc_fetch_geometry(data, geography = geography, year = year)
  keep <- if (isTRUE(keep_geo_vars)) {
    names(geom)
  } else {
    unique(c("GEOID", "geometry"))
  }
  geom <- geom[keep[keep %in% names(geom)]]

  conflicts <- intersect(setdiff(names(geom), c("GEOID", "geometry")), names(data))
  if (length(conflicts)) {
    names(geom)[match(conflicts, names(geom))] <- paste0("geo_", conflicts)
  }

  index <- seq_len(nrow(data))
  data$..tc_rowid.. <- index
  out <- merge(data, geom, by = "GEOID", all.x = TRUE, sort = FALSE)
  out <- out[order(out$..tc_rowid..), , drop = FALSE]
  out$..tc_rowid.. <- NULL
  if ("geometry" %in% names(out) && inherits(out$geometry, "sfc")) {
    return(sf::st_as_sf(out))
  }

  out
}
