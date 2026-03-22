tc_build_get_clause <- function(
  variables,
  group = NULL,
  include_name = TRUE
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

  if (is.list(predicates) && length(predicates) == 0L) {
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
    include_name = isTRUE(name) && !is.null(geography)
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
  resp <- tc_fetch_json(
    url,
    context = list(dataset = dataset, year = year, geography = geography)
  )
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

tc_dataset_query_raw <- function(
  dataset,
  year,
  variables = NULL,
  group = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  key = tc_get_key(),
  name = TRUE,
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  geography_vintage = NULL,
  ...
) {
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

  attr(out, "dataset") <- dataset
  attr(out, "year") <- year
  attr(out, "geography") <- geography
  attr(out, "within") <- tc_normalize_within(geo_inputs$within)
  out
}

tc_metric_info <- function(variable) {
  if (grepl("(EA|PEA|NA)$", variable)) {
    return(list(variable = sub("(EA|PEA|NA)$", "", variable), role = "annotation"))
  }

  if (grepl("(MA|PMA)$", variable)) {
    return(list(variable = sub("(MA|PMA)$", "", variable), role = "annotation"))
  }

  if (grepl("E$", variable)) {
    return(list(variable = sub("E$", "", variable), role = "estimate"))
  }

  if (grepl("M$", variable)) {
    return(list(variable = sub("M$", "", variable), role = "moe"))
  }

  if (grepl("N$", variable)) {
    return(list(variable = sub("N$", "", variable), role = "estimate"))
  }

  list(variable = variable, role = "estimate")
}

tc_is_measure_variable <- function(variable) {
  grepl("(EA|PEA|NA|MA|PMA|E|M|N)$", variable)
}

tc_metric_map <- function(variables) {
  info <- lapply(variables, tc_metric_info)
  tibble::tibble(
    raw_variable = variables,
    variable = vapply(info, `[[`, character(1), "variable"),
    role = vapply(info, `[[`, character(1), "role")
  )
}

tc_companion_variables <- function(dataset, year, variables, refresh = FALSE) {
  meta <- tc_variables(dataset, year, refresh = refresh)
  expanded <- unique(as.character(variables))

  for (variable in variables) {
    if (grepl("E$", variable)) {
      companion <- sub("E$", "M", variable)
      if (companion %in% meta$name) {
        expanded <- unique(c(expanded, companion))
      }
    }
  }

  expanded
}

tc_summary_columns <- function(summary_var) {
  if (is.null(summary_var)) {
    return(list(raw = character(), estimate = NULL, moe = NULL))
  }

  info <- tc_metric_info(summary_var)
  estimate_col <- summary_var
  moe_col <- NULL

  if (info$role == "moe") {
    estimate_col <- sub("M$", "E", summary_var)
    moe_col <- summary_var
  } else if (grepl("E$", summary_var)) {
    moe_col <- sub("E$", "M", summary_var)
  }

  list(
    raw = unique(c(estimate_col, moe_col)),
    estimate = estimate_col,
    moe = moe_col
  )
}

tc_add_summary_columns <- function(data, summary_var = NULL) {
  summary_cols <- tc_summary_columns(summary_var)

  if (!length(summary_cols$raw)) {
    return(data)
  }

  if (!is.null(summary_cols$estimate) && summary_cols$estimate %in% names(data)) {
    data$summary_estimate <- data[[summary_cols$estimate]]
  }

  if (!is.null(summary_cols$moe) && summary_cols$moe %in% names(data)) {
    data$summary_moe <- data[[summary_cols$moe]]
  }

  data[, setdiff(names(data), summary_cols$raw), drop = FALSE]
}

tc_shape_product_wide <- function(
  data,
  dataset,
  year,
  summary_var = NULL,
  refresh = FALSE
) {
  map <- tc_metric_map(names(data))
  keep <- map$role != "annotation"
  out <- data[, map$raw_variable[keep], drop = FALSE]
  meta <- tc_variables(dataset, year, refresh = refresh)
  shared <- intersect(names(out), meta$name)
  measure_cols <- shared[meta$predicate_type[match(shared, meta$name)] %in% c(
    "int",
    "integer",
    "float",
    "numeric"
  )]
  for (column in measure_cols) {
    out[[column]] <- suppressWarnings(as.numeric(out[[column]]))
  }
  tc_add_summary_columns(out, summary_var = summary_var)
}

tc_product_query <- function(
  dataset,
  year,
  variables = NULL,
  table = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  key = tc_get_key(),
  geometry = FALSE,
  keep_geo_vars = FALSE,
  summary_var = NULL,
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  geography_vintage = NULL,
  ...
) {
  variables <- tc_null_if_empty(variables)
  table <- tc_null_if_empty(table)
  summary_var <- tc_null_if_empty(summary_var)

  if (!is.null(variables) && !is.null(table)) {
    cli::cli_abort(
      "{.arg variables} and {.arg table} are mutually exclusive."
    )
  }

  if (is.null(variables) && is.null(table)) {
    cli::cli_abort("Supply either {.arg variables} or {.arg table}.")
  }

  dataset_info <- tc_resolve_dataset(
    dataset,
    year,
    refresh = refresh,
    cache = cache
  )
  year <- dataset_info$year[[1]]

  request_vars <- variables
  if (!is.null(request_vars)) {
    request_vars <- tc_companion_variables(
      dataset,
      year,
      request_vars,
      refresh = refresh
    )
  }

  if (!is.null(summary_var)) {
    request_vars <- unique(c(
      request_vars,
      tc_companion_variables(dataset, year, summary_var, refresh = refresh)
    ))
  }

  raw <- tc_dataset_query_raw(
    dataset = dataset,
    year = year,
    variables = request_vars,
    group = table,
    geography = geography,
    within = within,
    predicates = predicates,
    key = key,
    name = TRUE,
    refresh = refresh,
    cache = cache,
    ucgid = ucgid,
    geography_vintage = geography_vintage,
    ...
  )

  geography <- attr(raw, "geography")
  out <- tc_shape_product_wide(
    raw,
    dataset = dataset,
    year = year,
    summary_var = summary_var,
    refresh = refresh
  )

  if (isTRUE(geometry)) {
    if (is.null(geography)) {
      cli::cli_abort("Geometry requires an explicit {.arg geography}.")
    }
    out <- tc_add_geometry(
      out,
      geography = geography,
      year = year,
      keep_geo_vars = keep_geo_vars
    )
  }

  tc_as_tinycensus_tbl(
    out,
    dataset = dataset,
    year = year,
    geography = geography
  )
}
