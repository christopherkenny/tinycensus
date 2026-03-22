tc_normalize_geography_name <- function(x) {
  x <- tc_null_if_empty(x)
  if (is.null(x)) {
    return(NULL)
  }

  x <- tc_clean_name(x)
  if (x %in% names(tc_geography_aliases)) {
    return(unname(tc_geography_aliases[[x]]))
  }

  x
}

tc_normalize_within <- function(within) {
  if (is.null(within)) {
    return(list())
  }

  if (length(within) == 0L) {
    return(list())
  }

  if (
    !is.list(within) || is.null(names(within)) || any(!nzchar(names(within)))
  ) {
    cli::cli_abort("{.arg within} must be a named list.")
  }

  names(within) <- vapply(
    names(within),
    tc_normalize_geography_name,
    character(1)
  )

  if (anyDuplicated(names(within))) {
    cli::cli_abort(
      "Normalized {.arg within} geography names must be unique."
    )
  }

  within
}

tc_normalize_geo_value <- function(
  geography,
  value,
  within = list(),
  year = NULL,
  refresh = FALSE
) {
  if (is.null(value)) {
    return(NULL)
  }

  if (geography == "state") {
    return(normalize_state(value))
  }

  if (geography == "county") {
    state <- within[["state"]] %||%
      cli::cli_abort(
        "County values require a {.arg state} value or {.arg within = list(state = ...)}."
      )
    return(normalize_county(value, state = state, year = year))
  }

  as.character(value)
}

tc_geography_record <- function(dataset, year, geography, refresh = FALSE) {
  meta <- tc_geography(dataset, year, refresh = refresh)
  idx <- meta$geography == geography

  if (!any(idx)) {
    cli::cli_abort(
      "Geography {.val {geography}} is not available for dataset {.val {dataset}} in {.val {year}}."
    )
  }

  meta[idx, , drop = FALSE][1, , drop = FALSE]
}

tc_collect_geography_inputs <- function(geography, within, dots) {
  geography <- tc_normalize_geography_name(geography)
  within <- tc_normalize_within(within)
  if (!length(dots)) {
    return(list(geography = geography, values = NULL, within = within))
  }

  dot_names <- names(dots)
  if (is.null(dot_names) || any(!nzchar(dot_names))) {
    cli::cli_abort("All geography inputs passed through `...` must be named.")
  }

  dot_names <- vapply(dot_names, tc_normalize_geography_name, character(1))
  if (anyDuplicated(dot_names)) {
    cli::cli_abort(
      "Normalized geography inputs passed through `...` must be unique."
    )
  }
  names(dots) <- dot_names

  if (is.null(geography) && length(dots) == 1L) {
    geography <- dot_names[[1]]
  } else if (is.null(geography) && length(dots) > 1L) {
    cli::cli_abort(
      "Supply an explicit {.arg geography} when providing multiple geography inputs in `...`."
    )
  }

  values <- NULL
  if (!is.null(geography) && geography %in% dot_names) {
    values <- dots[[geography]]
    dots[[geography]] <- NULL
  }

  within[names(dots)] <- dots
  list(geography = geography, values = values, within = within)
}

tc_build_geoid <- function(data, geography) {
  if (is.null(geography)) {
    return(data)
  }

  columns <- tc_geoid_map[[geography]]
  if (is.null(columns) || !all(columns %in% names(data))) {
    return(data)
  }

  geoid <- do.call(paste0, unname(as.list(data[columns])))
  data$GEOID <- geoid
  data
}
