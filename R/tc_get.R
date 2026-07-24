tc_build_get_clause <- function(
  variables,
  group = NULL,
  include_name = TRUE
) {
  parts <- character()

  if (isTRUE(include_name)) {
    parts <- c(parts, 'NAME')
  }

  if (!is.null(group)) {
    return(c(parts, paste0('group(', group, ')')))
  }

  c(parts, variables)
}

tc_label_variable_base <- function(variable) {
  if (!grepl('_LABEL$', variable)) {
    return(NULL)
  }

  sub('_LABEL$', '', variable)
}

tc_prepare_special_variables <- function(
  dataset,
  year,
  variables = NULL,
  geography = NULL,
  refresh = FALSE,
  meta = NULL
) {
  variables <- tc_null_if_empty(variables)
  if (is.null(variables)) {
    return(list(
      variables = NULL,
      include_name = !is.null(geography),
      label_map = tibble::tibble(
        label = character(),
        code = character(),
        keep_code = logical()
      ),
      alias_map = tibble::tibble(
        variable = character(),
        alias = character()
      )
    ))
  }

  include_name <- !is.null(geography)
  requested <- unname(as.character(variables))
  aliases <- names(variables)
  alias_map <- tibble::tibble(
    variable = requested,
    alias = if (is.null(aliases)) {
      requested
    } else {
      ifelse(nzchar(aliases), aliases, requested)
    }
  )

  if (!is.null(geography) && 'NAME' %in% requested) {
    requested <- setdiff(requested, 'NAME')
    alias_map <- alias_map[alias_map$variable != 'NAME', , drop = FALSE]
  }

  meta <- meta %||% tc_variables(dataset, year, refresh = refresh)
  label_vars <- requested[grepl('_LABEL$', requested)]
  label_map <- vector('list', length(label_vars))

  if (length(label_vars)) {
    for (i in seq_along(label_vars)) {
      label_var <- label_vars[[i]]
      code_var <- tc_label_variable_base(label_var)

      if (is.null(code_var) || !code_var %in% meta$name) {
        cli::cli_abort(
          'Unknown variable(s): {.val {label_var}}.'
        )
      }

      values <- tc_values(
        dataset = dataset,
        year = year,
        variable = code_var,
        refresh = refresh
      )

      if (!all(c('code', 'label') %in% names(values)) || !nrow(values)) {
        cli::cli_abort(
          'Variable {.val {code_var}} does not expose encoded labels, so {.val {label_var}} is not available.'
        )
      }

      label_map[[i]] <- tibble::tibble(
        label = label_var,
        code = code_var,
        keep_code = code_var %in% variables
      )
    }

    label_map <- tibble::as_tibble(do.call(rbind, label_map))
    requested <- unique(c(setdiff(requested, label_vars), label_map$code))
  } else {
    label_map <- tibble::tibble(
      label = character(),
      code = character(),
      keep_code = logical()
    )
  }

  list(
    variables = requested,
    include_name = include_name,
    label_map = label_map,
    alias_map = alias_map
  )
}

tc_dataset_supports_name <- function(dataset) {
  !grepl('^pdb/', dataset)
}

tc_prepare_predicates <- function(predicates) {
  if (is.null(predicates)) {
    return(list())
  }

  if (!is.list(predicates)) {
    if (
      is.atomic(predicates) &&
        !is.null(names(predicates)) &&
        all(nzchar(names(predicates)))
    ) {
      return(as.list(predicates))
    }

    cli::cli_abort('{.arg predicates} must be a named list.')
  }

  if (is.list(predicates) && length(predicates) == 0L) {
    return(list())
  }

  if (
    is.null(names(predicates)) ||
      !all(nzchar(names(predicates)))
  ) {
    cli::cli_abort('{.arg predicates} must be a named list.')
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

  if (grepl('^dec/', dataset)) {
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
  geography_vintage = NULL,
  meta = NULL,
  groups = NULL,
  geography_meta = NULL
) {
  if (is.null(group) && (is.null(variables) || !length(variables))) {
    cli::cli_abort('Supply either {.arg variables} or {.arg group}.')
  }

  if (!is.null(ucgid) && !is.null(geography)) {
    cli::cli_abort(
      '{.arg ucgid} is mutually exclusive with {.arg geography} and parent geography inputs.'
    )
  }

  meta <- meta %||% tc_variables(dataset, year, refresh = refresh)
  allow_name <- !is.null(geography) && tc_dataset_supports_name(dataset)

  if (!is.null(variables)) {
    missing_vars <- setdiff(variables, c(meta$name, if (allow_name) 'NAME'))
    if (length(missing_vars)) {
      cli::cli_abort('Unknown variable(s): {.val {missing_vars}}.')
    }
  }

  if (!is.null(group)) {
    groups <- groups %||% tc_groups(dataset, year, refresh = refresh)
    if (!group %in% groups$name) {
      cli::cli_abort(
        'Unknown group {.val {group}} for dataset {.val {dataset}}.'
      )
    }
  }

  if (!is.null(geography)) {
    geography <- tc_normalize_geography_name(geography)
    geo_row <- if (is.null(geography_meta)) {
      tc_geography_record(dataset, year, geography, refresh = refresh)
    } else {
      idx <- geography_meta$geography == geography
      if (!any(idx)) {
        cli::cli_abort(
          'Geography {.val {geography}} is not available for dataset {.val {dataset}} in {.val {year}}.'
        )
      }
      geography_meta[idx, , drop = FALSE][1, , drop = FALSE]
    }
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
      wildcard <- geo_row$wildcard[[1]] %||% character()
      wildcard_missing <- intersect(missing, wildcard)

      if (length(wildcard_missing)) {
        within[wildcard_missing] <- rep(list('*'), length(wildcard_missing))
        missing <- setdiff(missing, wildcard_missing)
      }

      if (length(missing)) {
        cli::cli_abort(
          'Geography {.val {geography}} requires parent geography input(s): {.val {missing}}.'
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

  include_name <- isTRUE(name) && allow_name

  get_clause <- tc_build_get_clause(
    variables = variables,
    group = group,
    include_name = include_name
  )

  params <- list(get = paste(get_clause, collapse = ','))

  if (!is.null(ucgid)) {
    params$ucgid <- as.character(ucgid)
  } else if (!is.null(geography)) {
    params[['for']] <- paste0(
      geography,
      ':',
      if (is.null(values)) {
        '*'
      } else {
        paste(as.character(values), collapse = ',')
      }
    )

    if (length(within)) {
      within_parts <- paste0(
        names(within),
        ':',
        vapply(
          within,
          function(x) paste(as.character(x), collapse = ','),
          character(1)
        )
      )
      params[['in']] <- paste(within_parts, collapse = ' ')
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
    paste0(tc_api_base(), '/', year, '/', dataset)
  }

  tc_build_url(base_url, params = params)
}

tc_parse_census_response <- function(
  resp,
  dataset,
  year,
  geography = NULL,
  refresh = FALSE,
  meta = NULL
) {
  out <- tc_json_matrix_to_tibble(resp)
  meta <- meta %||% tc_variables(dataset, year, refresh = refresh)
  shared <- intersect(names(out), meta$name)

  for (column in shared) {
    type <- meta$predicate_type[match(column, meta$name)]
    out[[column]] <- tc_guess_numeric(out[[column]], type = type)
  }

  tc_build_geoid(out, geography = geography)
}

tc_apply_value_labels <- function(
  data,
  dataset,
  year,
  label_map,
  refresh = FALSE
) {
  if (is.null(label_map) || !nrow(label_map)) {
    return(data)
  }

  out <- data

  for (i in seq_len(nrow(label_map))) {
    code_var <- label_map$code[[i]]
    label_var <- label_map$label[[i]]

    values <- tc_values(
      dataset = dataset,
      year = year,
      variable = code_var,
      refresh = refresh
    )
    labels <- stats::setNames(values$label, values$code)
    out[[label_var]] <- unname(labels[as.character(out[[code_var]])])

    if (!isTRUE(label_map$keep_code[[i]])) {
      out[[code_var]] <- NULL
    }
  }

  out
}

tc_apply_aliases <- function(data, alias_map) {
  if (is.null(alias_map) || !nrow(alias_map)) {
    return(data)
  }

  out <- data
  alias_map <- alias_map[alias_map$variable %in% names(out), , drop = FALSE]
  alias_map <- alias_map[!duplicated(alias_map$alias), , drop = FALSE]
  alias_map <- alias_map[alias_map$variable != alias_map$alias, , drop = FALSE]

  if (!nrow(alias_map)) {
    return(out)
  }

  conflicts <- alias_map$alias %in% setdiff(names(out), alias_map$variable)
  if (any(conflicts)) {
    cli::cli_abort(
      'Variable alias(es) conflict with existing output columns: {.val {alias_map$alias[conflicts]}}.'
    )
  }

  names(out)[match(alias_map$variable, names(out))] <- alias_map$alias
  out
}

tc_execute_query <- function(
  dataset,
  year,
  params,
  geography = NULL,
  refresh = FALSE,
  endpoint = NULL,
  meta = NULL
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
    refresh = refresh,
    meta = meta
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

tc_stabilize_geography_order <- function(data, geography = NULL) {
  if (is.null(geography) || !'GEOID' %in% names(data)) {
    return(data)
  }

  data[order(data$GEOID), , drop = FALSE]
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
  meta = NULL,
  groups = NULL,
  geography_meta = NULL,
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
        geography_vintage = geography_vintage,
        meta = meta,
        groups = groups,
        geography_meta = geography_meta
      )

      tc_execute_query(
        dataset = dataset,
        year = year,
        params = params,
        geography = geography,
        refresh = refresh,
        endpoint = dataset_info$endpoint[[1]],
        meta = meta
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
      geography_vintage = geography_vintage,
      meta = meta,
      groups = groups,
      geography_meta = geography_meta
    )

    out <- tibble::as_tibble(
      tc_execute_query(
        dataset = dataset,
        year = year,
        params = params,
        geography = geography,
        refresh = refresh,
        endpoint = dataset_info$endpoint[[1]],
        meta = meta
      )
    )
  }

  out <- tc_stabilize_geography_order(out, geography = geography)

  attr(out, 'dataset') <- dataset
  attr(out, 'year') <- year
  attr(out, 'geography') <- geography
  attr(out, 'within') <- tc_normalize_within(geo_inputs$within)
  out
}

tc_metric_info <- function(variable) {
  if (grepl('(EA|PEA|NA)$', variable)) {
    return(list(
      variable = sub('(EA|PEA|NA)$', '', variable),
      role = 'annotation'
    ))
  }

  if (grepl('(MA|PMA)$', variable)) {
    return(list(variable = sub('(MA|PMA)$', '', variable), role = 'annotation'))
  }

  if (grepl('E$', variable)) {
    return(list(variable = sub('E$', '', variable), role = 'estimate'))
  }

  if (grepl('M$', variable)) {
    return(list(variable = sub('M$', '', variable), role = 'moe'))
  }

  if (grepl('N$', variable)) {
    return(list(variable = sub('N$', '', variable), role = 'estimate'))
  }

  list(variable = variable, role = 'estimate')
}

tc_is_measure_variable <- function(variable) {
  grepl('(EA|PEA|NA|MA|PMA|E|M|N)$', variable)
}

tc_metric_map <- function(variables) {
  info <- lapply(variables, tc_metric_info)
  tibble::tibble(
    raw_variable = variables,
    variable = vapply(info, `[[`, character(1), 'variable'),
    role = vapply(info, `[[`, character(1), 'role')
  )
}

tc_companion_variables <- function(dataset, year, variables, refresh = FALSE, meta = NULL) {
  meta <- meta %||% tc_variables(dataset, year, refresh = refresh)
  expanded <- unique(as.character(variables))

  for (variable in variables) {
    if (grepl('E$', variable)) {
      companion <- sub('E$', 'M', variable)
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

  if (info$role == 'moe') {
    estimate_col <- sub('M$', 'E', summary_var)
    moe_col <- summary_var
  } else if (grepl('E$', summary_var)) {
    moe_col <- sub('E$', 'M', summary_var)
  }

  list(
    raw = unique(c(estimate_col, moe_col)),
    estimate = estimate_col,
    moe = moe_col
  )
}

tc_validate_summary_var <- function(
  summary_var,
  dataset,
  year,
  table = NULL,
  refresh = FALSE,
  meta = NULL
) {
  summary_var <- tc_null_if_empty(summary_var)
  if (is.null(summary_var)) {
    return(invisible(NULL))
  }

  meta <- meta %||% tc_variables(dataset, year, refresh = refresh)
  info <- tc_metric_info(summary_var)
  target <- if (info$role == 'moe') {
    sub('M$', 'E', summary_var)
  } else {
    summary_var
  }

  if (!target %in% meta$name) {
    cli::cli_abort(
      'Unknown {.arg summary_var} {.val {summary_var}} for dataset {.val {dataset}}.'
    )
  }

  if (!is.null(table)) {
    table_vars <- meta$name[meta$group == table]
    if (!target %in% table_vars) {
      cli::cli_abort(
        '{.arg summary_var} must belong to table {.val {table}} when {.arg table} is supplied.'
      )
    }
  }

  invisible(NULL)
}

tc_add_summary_columns <- function(data, summary_var = NULL) {
  summary_cols <- tc_summary_columns(summary_var)

  if (!length(summary_cols$raw)) {
    return(data)
  }

  if (
    !is.null(summary_cols$estimate) && summary_cols$estimate %in% names(data)
  ) {
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
  refresh = FALSE,
  meta = NULL
) {
  map <- tc_metric_map(names(data))
  keep <- map$role != 'annotation'
  out <- data[, map$raw_variable[keep], drop = FALSE]
  meta <- meta %||% tc_variables(dataset, year, refresh = refresh)
  shared <- intersect(names(out), meta$name)
  measure_cols <- shared[
    meta$predicate_type[match(shared, meta$name)] %in%
      c(
        'int',
        'integer',
        'float',
        'numeric'
      )
  ]
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
      '{.arg variables} and {.arg table} are mutually exclusive.'
    )
  }

  if (is.null(variables) && is.null(table)) {
    cli::cli_abort('Supply either {.arg variables} or {.arg table}.')
  }

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
  meta <- tc_variables(dataset, year, refresh = refresh)
  groups <- if (!is.null(table)) {
    tc_groups(dataset, year = year, refresh = refresh)
  } else {
    NULL
  }
  geography_meta <- if (!is.null(geo_inputs$geography)) {
    tc_geography(dataset, year = year, refresh = refresh)
  } else {
    NULL
  }
  specials <- tc_prepare_special_variables(
    dataset = dataset,
    year = year,
    variables = variables,
    geography = geo_inputs$geography,
    refresh = refresh,
    meta = meta
  )
  variables <- tc_null_if_empty(specials$variables)

  tc_validate_summary_var(
    summary_var = summary_var,
    dataset = dataset,
    year = year,
    table = table,
    refresh = refresh,
    meta = meta
  )

  request_vars <- variables
  if (!is.null(request_vars)) {
    request_vars <- tc_companion_variables(
      dataset,
      year,
      request_vars,
      refresh = refresh,
      meta = meta
    )
  }

  if (!is.null(summary_var)) {
    request_vars <- unique(c(
      request_vars,
      tc_companion_variables(dataset, year, summary_var, refresh = refresh, meta = meta)
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
    meta = meta,
    groups = groups,
    geography_meta = geography_meta,
    ...
  )

  geography <- attr(raw, 'geography')
  out <- tc_shape_product_wide(
    raw,
    dataset = dataset,
    year = year,
    summary_var = summary_var,
    refresh = refresh,
    meta = meta
  )
  out <- tc_apply_value_labels(
    out,
    dataset = dataset,
    year = year,
    label_map = specials$label_map,
    refresh = refresh
  )
  out <- tc_apply_aliases(out, specials$alias_map)

  if (isTRUE(geometry)) {
    if (is.null(geography)) {
      cli::cli_abort('Geometry requires an explicit {.arg geography}.')
    }
    out <- tc_add_geometry(
      out,
      geography = geography,
      year = year,
      keep_geo_vars = keep_geo_vars
    )
  }

  tc_add_attributes(
    out,
    dataset = dataset,
    year = year,
    geography = geography
  )
}
