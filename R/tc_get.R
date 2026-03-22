tc_build_get_clause <- function(
  variables,
  group = NULL,
  include_name = TRUE,
  meta = NULL
) {
  parts <- character()

  if (isTRUE(include_name)) {
    parts <- c(parts, "NAME")
  }

  if (!is.null(group)) {
    return(c(parts, paste0("group(", group, ")")))
  }

  c(parts, variables)
}

tc_prepare_predicates <- function(predicates) {
  if (is.null(predicates)) {
    return(list())
  }

  if (
    !is.list(predicates) ||
      is.null(names(predicates)) ||
      any(!nzchar(names(predicates)))
  ) {
    cli::cli_abort("{.arg predicates} must be a named list.")
  }

  predicates
}

tc_resolve_geography_vintage <- function(
  dataset,
  year,
  geography_vintage = NULL
) {
  if (!is.null(geography_vintage)) {
    return(as.integer(geography_vintage))
  }

  if (grepl("^dec/", dataset)) {
    return(as.integer(year) - (as.integer(year) %% 10L))
  }

  as.integer(year)
}

tc_query_params <- function(
  dataset,
  year,
  variables = NULL,
  group = NULL,
  geography = NULL,
  values = NULL,
  within = list(),
  predicates = NULL,
  key = NULL,
  name = TRUE,
  ucgid = NULL,
  refresh = FALSE,
  geography_vintage = NULL
) {
  if (is.null(group) && (is.null(variables) || !length(variables))) {
    cli::cli_abort("Supply either {.arg variables} or {.arg group}.")
  }

  meta <- tc_variables(dataset, year, refresh = refresh)

  if (!is.null(variables)) {
    missing_vars <- setdiff(variables, meta$name)
    if (length(missing_vars)) {
      cli::cli_abort("Unknown variable(s): {.val {missing_vars}}.")
    }
  }

  if (!is.null(group)) {
    groups <- tc_groups(dataset, year, refresh = refresh)
    if (!group %in% groups$name) {
      cli::cli_abort(
        "Unknown group {.val {group}} for dataset {.val {dataset}}."
      )
    }
  }

  if (!is.null(geography)) {
    geography <- tc_normalize_geography_name(geography)
    geo_row <- tc_geography_record(dataset, year, geography, refresh = refresh)
    within <- tc_normalize_within(within)
    geography_vintage <- tc_resolve_geography_vintage(
      dataset = dataset,
      year = year,
      geography_vintage = geography_vintage
    )
    values <- tc_normalize_geo_value(
      geography,
      values,
      within = within,
      year = geography_vintage,
      refresh = refresh
    )

    requires <- geo_row$requires[[1]]
    if (length(requires)) {
      missing <- setdiff(requires, names(within))
      if (length(missing)) {
        cli::cli_abort(
          "Geography {.val {geography}} requires parent geography input(s): {.val {missing}}."
        )
      }
    }

    within_names <- vapply(
      names(within),
      tc_normalize_geography_name,
      character(1)
    )
    within_values <- lapply(within_names, function(name) {
      tc_normalize_geo_value(
        name,
        within[[name]],
        within = within,
        year = geography_vintage,
        refresh = refresh
      )
    })
    names(within_values) <- within_names
    within <- within_values
  }

  get_clause <- tc_build_get_clause(
    variables = variables,
    group = group,
    include_name = isTRUE(name) && !is.null(geography),
    meta = meta
  )

  params <- list(get = paste(get_clause, collapse = ","))

  if (!is.null(ucgid)) {
    params$ucgid <- as.character(ucgid)
  } else if (!is.null(geography)) {
    params[["for"]] <- paste0(
      geography,
      ":",
      if (is.null(values)) {
        "*"
      } else {
        paste(as.character(values), collapse = ",")
      }
    )

    if (length(within)) {
      within_parts <- paste0(
        names(within),
        ":",
        vapply(
          within,
          function(x) paste(as.character(x), collapse = ","),
          character(1)
        )
      )
      params[["in"]] <- paste(within_parts, collapse = " ")
    }
  }

  predicates <- tc_prepare_predicates(predicates)
  params <- c(params, predicates)

  if (!is.null(key) && nzchar(key)) {
    params$key <- key
  }

  params
}

tc_query_url <- function(dataset, year, params, endpoint = NULL) {
  base_url <- if (!is.null(endpoint) && !is.na(endpoint)) {
    endpoint
  } else {
    paste0(tc_api_base(), "/", year, "/", dataset)
  }

  tc_build_url(base_url, params = params)
}

tc_parse_census_response <- function(
  resp,
  dataset,
  year,
  geography = NULL,
  refresh = FALSE
) {
  out <- tc_json_matrix_to_tibble(resp)
  meta <- tc_variables(dataset, year, refresh = refresh)
  shared <- intersect(names(out), meta$name)

  for (column in shared) {
    type <- meta$predicate_type[match(column, meta$name)]
    out[[column]] <- tc_guess_numeric(out[[column]], type = type)
  }

  tc_build_geoid(out, geography = geography)
}

tc_execute_query <- function(
  dataset,
  year,
  params,
  geography = NULL,
  refresh = FALSE,
  endpoint = NULL
) {
  url <- tc_query_url(
    dataset = dataset,
    year = year,
    params = params,
    endpoint = endpoint
  )
  resp <- tc_fetch_json(url)
  tc_parse_census_response(
    resp,
    dataset = dataset,
    year = year,
    geography = geography,
    refresh = refresh
  )
}

tc_join_chunks <- function(chunks) {
  if (length(chunks) == 1L) {
    return(chunks[[1]])
  }

  Reduce(
    f = function(x, y) {
      by <- intersect(names(x), names(y))
      merge(x, y, by = by, all = TRUE, sort = FALSE)
    },
    x = chunks
  )
}

#' Retrieve data from the Census API
#'
#' @param dataset A Census dataset identifier like `"acs/acs5"`.
#' @param year A dataset year.
#' @param variables Optional character vector of variable names.
#' @param group Optional group or table identifier.
#' @param geography Optional Census geography name.
#' @param within Optional named list of parent geographies.
#' @param predicates Optional named list of additional predicate values.
#' @param key Optional Census API key. Defaults to [tc_get_key()].
#' @param geometry Should the result be joined to `tinytiger` geometry?
#' @param output Output shape, `"wide"` or `"long"`.
#' @param name Should `NAME` be requested when available?
#' @param refresh Should cached metadata be refreshed?
#' @param cache Should discovery metadata be cached locally?
#' @param ucgid Optional `ucgid` predicate.
#' @param geography_vintage Optional geography vintage used for input
#'   normalization when it differs from the dataset release year.
#' @param ... Geography values such as `state = "NY"` or
#'   `county = c("001", "003")`.
#'
#' @return A tibble, or an `sf` object when `geometry = TRUE`.
#' @export
#' @examplesIf tc_has_key()
#' tc_get(
#'   dataset = "acs/acs5",
#'   year = 2024,
#'   variables = "B01001_001E",
#'   geography = "state",
#'   state = c("NY", "Delaware")
#' )
tc_get <- function(
  dataset,
  year,
  variables = NULL,
  group = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  key = tc_get_key(),
  geometry = FALSE,
  output = c("wide", "long"),
  name = TRUE,
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  geography_vintage = NULL,
  ...
) {
  output <- rlang::arg_match(output)
  dataset_info <- tc_resolve_dataset(
    dataset,
    year,
    refresh = refresh,
    cache = cache
  )
  year <- dataset_info$year[[1]]

  geo_inputs <- tc_collect_geography_inputs(
    geography = tc_null_if_empty(geography),
    within = within,
    dots = rlang::list2(...)
  )

  geography <- geo_inputs$geography
  variables <- tc_null_if_empty(variables)
  group <- tc_null_if_empty(group)

  if (!is.null(variables) && isTRUE(name) && "NAME" %in% variables) {
    name <- FALSE
  }

  if (is.null(group) && !is.null(variables) && length(variables) > 49L) {
    chunks <- split(variables, ceiling(seq_along(variables) / 49L))
    result <- lapply(seq_along(chunks), function(i) {
      params <- tc_query_params(
        dataset = dataset,
        year = year,
        variables = chunks[[i]],
        group = NULL,
        geography = geography,
        values = geo_inputs$values,
        within = geo_inputs$within,
        predicates = predicates,
        key = key,
        name = if (i == 1L) name else FALSE,
        ucgid = ucgid,
        refresh = refresh,
        geography_vintage = geography_vintage
      )

      tc_execute_query(
        dataset = dataset,
        year = year,
        params = params,
        geography = geography,
        refresh = refresh,
        endpoint = dataset_info$endpoint[[1]]
      )
    })
    out <- tibble::as_tibble(tc_join_chunks(result))
  } else {
    params <- tc_query_params(
      dataset = dataset,
      year = year,
      variables = variables,
      group = group,
      geography = geography,
      values = geo_inputs$values,
      within = geo_inputs$within,
      predicates = predicates,
      key = key,
      name = name,
      ucgid = ucgid,
      refresh = refresh,
      geography_vintage = geography_vintage
    )

    out <- tibble::as_tibble(
      tc_execute_query(
        dataset = dataset,
        year = year,
        params = params,
        geography = geography,
        refresh = refresh,
        endpoint = dataset_info$endpoint[[1]]
      )
    )
  }

  if (isTRUE(geometry)) {
    if (is.null(geography)) {
      cli::cli_abort("Geometry requires an explicit {.arg geography}.")
    }
    out <- tc_add_geometry(out, geography = geography, year = year)
  }

  if (identical(output, "long")) {
    id_columns <- c(
      "NAME",
      "GEOID",
      geography,
      names(tc_normalize_within(geo_inputs$within))
    )
    measure_columns <- setdiff(names(out), id_columns)
    out <- tc_to_long(out, value_columns = measure_columns)
  }

  tc_as_tinycensus_tbl(
    out,
    dataset = dataset,
    year = year,
    geography = geography
  )
}
