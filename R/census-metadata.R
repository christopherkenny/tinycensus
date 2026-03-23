tc_cache_dir <- function(...) {
  parts <- c(rappdirs::user_cache_dir("tinycensus"))

  do.call(file.path, c(as.list(parts), list(...)))
}

tc_cache_path <- function(...) {
  file.path(tc_cache_dir(...))
}

tc_cache_read <- function(path) {
  if (!file.exists(path)) {
    return(NULL)
  }

  tryCatch(
    readRDS(path),
    error = function(...) {
      unlink(path)
      NULL
    }
  )
}

tc_cache_write <- function(object, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(object, path)
  invisible(object)
}

tc_http_error_context <- function(context = NULL) {
  if (is.null(context) || !length(context)) {
    return(NULL)
  }

  bits <- vapply(
    names(context),
    function(name) {
      value <- context[[name]]
      if (is.null(value) || length(value) == 0L || all(is.na(value))) {
        return(NA_character_)
      }
      paste0(name, ": ", paste(value, collapse = ", "))
    },
    character(1)
  )
  bits <- bits[!is.na(bits)]
  if (!length(bits)) {
    return(NULL)
  }

  paste(bits, collapse = "; ")
}

tc_abort_http_error <- function(resp, url, context = NULL) {
  body <- tryCatch(
    httr2::resp_body_string(resp),
    error = function(...) ""
  )
  body <- gsub("<[^>]+>", "", body)
  body <- gsub("[{}]", "", body)
  body <- trimws(body)
  status <- httr2::resp_status(resp)
  context_text <- tc_http_error_context(context)

  if (!nzchar(body) && identical(status, 204L)) {
    body <- "No records were returned for the requested query."
  }

  cli::cli_abort(c(
    "Census API request failed with status {.val {status}}.",
    x = if (nzchar(body)) body else "No error body returned.",
    i = "{.url {url}}",
    i = if (!is.null(context_text)) context_text else NULL
  ))
}

tc_request_json <- function(url, simplifyVector = TRUE, context = NULL) {
  req <- httr2::request(url) |>
    httr2::req_user_agent(
      "tinycensus (https://github.com/christopherkenny/tinycensus)"
    ) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_error(is_error = function(resp) FALSE)

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) >= 400) {
    tc_abort_http_error(resp, url = url, context = context)
  }

  httr2::resp_body_json(resp, simplifyVector = simplifyVector)
}

tc_fetch_json <- function(url, context = NULL) {
  tc_request_json(url, simplifyVector = TRUE, context = context)
}

tc_fetch_json_list <- function(url, context = NULL) {
  tc_request_json(url, simplifyVector = FALSE, context = context)
}

tc_normalize_link <- function(x) {
  if (is.null(x) || !nzchar(x)) {
    return(NA_character_)
  }

  sub("^http://", "https://", x)
}

tc_catalog_is_valid <- function(x) {
  if (!inherits(x, "data.frame")) {
    return(FALSE)
  }

  required <- c(
    "year",
    "dataset",
    "endpoint",
    "variables_url",
    "groups_url",
    "geography_url",
    "examples_url"
  )

  if (!all(required %in% names(x))) {
    return(FALSE)
  }

  if (!nrow(x)) {
    return(FALSE)
  }

  endpoint_ok <- is.na(x$endpoint) | grepl("^https://", x$endpoint)
  dataset_ok <- nzchar(x$dataset)

  all(endpoint_ok) && all(dataset_ok)
}

tc_dataset_catalog <- function(refresh = FALSE, cache = TRUE) {
  cache_path <- tc_cache_path("metadata", "catalog.rds")
  cached <- if (isTRUE(cache) && !isTRUE(refresh)) {
    tc_cache_read(cache_path)
  } else {
    NULL
  }

  if (!is.null(cached) && tc_catalog_is_valid(cached)) {
    return(cached)
  }

  json <- tc_fetch_json_list(
    "https://api.census.gov/data.json",
    context = list(endpoint = "data.json")
  )
  catalog <- json[["dataset"]]

  out <- tibble::tibble(
    year = vapply(
      catalog,
      function(x) as.integer(x$c_vintage %||% NA),
      integer(1)
    ),
    dataset = vapply(
      catalog,
      function(x) paste(tc_parse_list_column(x$c_dataset), collapse = "/"),
      character(1)
    ),
    title = vapply(
      catalog,
      function(x) x$title %||% NA_character_,
      character(1)
    ),
    description = vapply(
      catalog,
      function(x) x$description %||% NA_character_,
      character(1)
    ),
    endpoint = vapply(
      catalog,
      function(x) {
        distribution <- x$distribution

        if (is.null(distribution) || !length(distribution)) {
          return(NA_character_)
        }

        tc_normalize_link(distribution[[1]][["accessURL"]] %||% "")
      },
      character(1)
    ),
    geography_url = vapply(
      catalog,
      function(x) tc_normalize_link(x$c_geographyLink %||% ""),
      character(1)
    ),
    variables_url = vapply(
      catalog,
      function(x) tc_normalize_link(x$c_variablesLink %||% ""),
      character(1)
    ),
    groups_url = vapply(
      catalog,
      function(x) tc_normalize_link(x$c_groupsLink %||% ""),
      character(1)
    ),
    examples_url = vapply(
      catalog,
      function(x) tc_normalize_link(x$c_examplesLink %||% ""),
      character(1)
    ),
    is_available = vapply(
      catalog,
      function(x) isTRUE(x$c_isAvailable),
      logical(1)
    ),
    is_microdata = vapply(
      catalog,
      function(x) isTRUE(x$c_isMicrodata),
      logical(1)
    ),
    is_aggregate = vapply(
      catalog,
      function(x) isTRUE(x$c_isAggregate),
      logical(1)
    ),
    is_timeseries = vapply(
      catalog,
      function(x) {
        distribution <- x$distribution

        if (is.null(distribution) || !length(distribution)) {
          return(FALSE)
        }

        grepl(
          "/timeseries/",
          distribution[[1]][["accessURL"]] %||% "",
          fixed = TRUE
        )
      },
      logical(1)
    )
  )

  out <- out[order(out$dataset, out$year), ]

  if (isTRUE(cache)) {
    tc_cache_write(out, cache_path)
  }

  out
}

tc_resolve_dataset <- function(
  dataset,
  year = NULL,
  refresh = FALSE,
  cache = TRUE
) {
  if (!is.character(dataset) || length(dataset) != 1L || !nzchar(dataset)) {
    cli::cli_abort("{.arg dataset} must be a single non-empty string.")
  }

  catalog <- tc_dataset_catalog(refresh = refresh, cache = cache)
  matches <- catalog[catalog$dataset == dataset, , drop = FALSE]

  if (!nrow(matches)) {
    cli::cli_abort(
      "Dataset {.val {dataset}} was not found in the Census discovery catalog."
    )
  }

  if (is.null(year) || (length(year) == 1L && is.na(year))) {
    matches <- matches[matches$is_available, , drop = FALSE]
    matches <- matches[order(matches$year, decreasing = TRUE), , drop = FALSE]
    return(matches[1, , drop = FALSE])
  }

  idx <- matches$year == as.integer(year)
  if (!any(idx)) {
    cli::cli_abort(
      "Dataset {.val {dataset}} is not available for year {.val {year}}."
    )
  }

  matches[idx, , drop = FALSE][1, , drop = FALSE]
}

tc_metadata_cache <- function(dataset, year, type) {
  safe_dataset <- gsub("[^A-Za-z0-9]+", "_", dataset)
  tc_cache_path("metadata", paste0(type, "_", safe_dataset, "_", year, ".rds"))
}

tc_fetch_metadata <- function(
  dataset,
  year,
  type,
  refresh = FALSE,
  cache = TRUE
) {
  dataset_info <- tc_resolve_dataset(
    dataset,
    year,
    refresh = refresh,
    cache = cache
  )
  url <- dataset_info[[paste0(type, "_url")]]
  if (is.na(url)) {
    cli::cli_abort(
      "No {.val {type}} metadata endpoint is available for {.val {dataset}} in {.val {year}}."
    )
  }

  cache_path <- tc_metadata_cache(dataset, year, type)
  cached <- if (isTRUE(cache) && !isTRUE(refresh)) {
    tc_cache_read(cache_path)
  } else {
    NULL
  }

  if (!is.null(cached)) {
    return(cached)
  }

  json <- tc_fetch_json(
    url,
    context = list(dataset = dataset, year = year, metadata = type)
  )

  if (isTRUE(cache)) {
    tc_cache_write(json, cache_path)
  }

  json
}

#' List Census datasets from the discovery catalog
#'
#' @param year Optional year filter.
#' @param family Optional dataset family filter, such as `"acs"` or `"pep"`.
#' @param available Should only available datasets be returned?
#' @param refresh Should cached metadata be refreshed?
#'
#' @return A tibble of Census API datasets.
#' @export
#' @examplesIf tinycensus::tc_has_key()
#' tc_datasets(year = 2024, family = "acs", refresh = TRUE)
tc_datasets <- function(
  year = NULL,
  family = NULL,
  available = TRUE,
  refresh = FALSE
) {
  out <- tc_dataset_catalog(refresh = refresh, cache = TRUE)

  if (!is.null(year)) {
    out <- out[out$year %in% as.integer(year), , drop = FALSE]
  }

  if (!is.null(family)) {
    pattern <- paste0("^", family, "(/|$)")
    out <- out[grepl(pattern, out$dataset), , drop = FALSE]
  }

  if (isTRUE(available)) {
    out <- out[out$is_available, , drop = FALSE]
  }

  tibble::as_tibble(out)
}

#' Retrieve a single Census dataset record
#'
#' @param dataset A Census dataset identifier like `"acs/acs5"`.
#' @param year Optional year. When omitted, the latest available year is used.
#' @param refresh Should cached metadata be refreshed?
#'
#' @return A tibble with one row.
#' @export
#' @examplesIf tinycensus::tc_has_key()
#' tc_dataset("acs/acs5", 2024, refresh = TRUE)
tc_dataset <- function(dataset, year = NULL, refresh = FALSE) {
  tibble::as_tibble(tc_resolve_dataset(
    dataset,
    year,
    refresh = refresh,
    cache = TRUE
  ))
}

#' Retrieve Census variable metadata
#'
#' @param dataset A Census dataset identifier like `"acs/acs5"`.
#' @param year Optional dataset year.
#' @param refresh Should cached metadata be refreshed?
#'
#' @return A tibble of variable metadata.
#' @export
#' @examplesIf tinycensus::tc_has_key()
#' tc_variables("acs/acs5", 2024, refresh = TRUE)
tc_variables <- function(dataset, year = NULL, refresh = FALSE) {
  dataset_info <- tc_resolve_dataset(
    dataset,
    year,
    refresh = refresh,
    cache = TRUE
  )
  year <- dataset_info$year[[1]]
  json <- tc_fetch_metadata(
    dataset,
    year,
    "variables",
    refresh = refresh,
    cache = TRUE
  )
  variables <- as.list(json$variables)
  groups <- tryCatch(
    tc_groups(dataset, year = year, refresh = refresh),
    error = function(...) NULL
  )

  group_universe <- if (!is.null(groups) && nrow(groups)) {
    stats::setNames(groups$universe, groups$name)
  } else {
    character()
  }

  out <- tibble::tibble(
    name = names(variables),
    label = vapply(
      variables,
      function(x) x$label %||% NA_character_,
      character(1)
    ),
    concept = vapply(
      variables,
      function(x) x$concept %||% NA_character_,
      character(1)
    ),
    predicate_type = vapply(
      variables,
      function(x) x$predicateType %||% NA_character_,
      character(1)
    ),
    group = vapply(
      variables,
      function(x) x$group %||% NA_character_,
      character(1)
    ),
    universe = vapply(
      variables,
      function(x) {
        group <- x$group %||% NA_character_
        if (is.na(group) || !nzchar(group) || identical(group, "N/A")) {
          return(NA_character_)
        }
        if (!group %in% names(group_universe)) {
          return(NA_character_)
        }
        group_universe[[group]] %||% NA_character_
      },
      character(1)
    ),
    required = vapply(variables, function(x) isTRUE(x$required), logical(1)),
    attributes = I(lapply(variables, function(x) {
      tc_parse_list_column(x$attributes)
    }))
  )

  out[order(out$name), ]
}

tc_variable_metadata_url <- function(dataset, year, variable) {
  dataset_info <- tc_resolve_dataset(dataset, year, cache = TRUE)
  variables_url <- dataset_info$variables_url[[1]]

  if (is.na(variables_url)) {
    cli::cli_abort(
      "No variable metadata endpoint is available for {.val {dataset}} in {.val {year}}."
    )
  }

  paste0(sub("variables\\.json$", "variables/", variables_url), variable, ".json")
}

#' Retrieve raw Census group metadata
#'
#' @inheritParams tc_variables
#'
#' @return A tibble of group metadata from the Census API.
#'
#' @details
#' This is a lower-level metadata helper. For most ACS and decennial workflows,
#' [tc_tables()] is the more natural entry point because Census "groups" usually
#' correspond to user-facing tables.
#' @export
#' @examplesIf tinycensus::tc_has_key()
#' tc_groups("acs/acs5", 2024, refresh = TRUE)
tc_groups <- function(dataset, year = NULL, refresh = FALSE) {
  dataset_info <- tc_resolve_dataset(
    dataset,
    year,
    refresh = refresh,
    cache = TRUE
  )
  year <- dataset_info$year[[1]]
  json <- tc_fetch_metadata(
    dataset,
    year,
    "groups",
    refresh = refresh,
    cache = TRUE
  )
  groups <- json[["groups"]]

  tibble::tibble(
    name = groups$name %||% NA_character_,
    description = groups$description %||% NA_character_,
    universe = groups[["universe "]] %||%
      groups[["universe"]] %||%
      NA_character_,
    variables_url = vapply(groups$variables, tc_normalize_link, character(1))
  )
}

#' Retrieve Census table metadata
#'
#' @inheritParams tc_groups
#'
#' @return A tibble of table metadata.
#'
#' @details
#' This is the preferred helper for exploring ACS and decennial table-level
#' metadata. It wraps the Census API's group metadata in a table-oriented
#' interface.
#' @export
tc_tables <- function(dataset, year = NULL, refresh = FALSE) {
  out <- tc_groups(dataset, year = year, refresh = refresh)
  tibble::as_tibble(out)
}

#' Retrieve variables for a Census table
#'
#' @param dataset A Census dataset identifier like `"acs/acs5"`.
#' @param table Table or group identifier.
#' @param year Optional dataset year.
#' @param refresh Should cached metadata be refreshed?
#'
#' @return A tibble of variable metadata for the requested table.
#' @export
tc_table_variables <- function(
  dataset,
  table,
  year = NULL,
  refresh = FALSE
) {
  if (!is.character(table) || length(table) != 1L || !nzchar(table)) {
    cli::cli_abort("{.arg table} must be a single non-empty string.")
  }

  vars <- tc_variables(dataset, year = year, refresh = refresh)
  out <- vars[vars$group == table, , drop = FALSE]

  if (!nrow(out)) {
    cli::cli_abort(
      "Table {.val {table}} was not found for dataset {.val {dataset}}."
    )
  }

  tibble::as_tibble(out[order(out$name), , drop = FALSE])
}

tc_parse_geography_requires <- function(entry) {
  if (!is.null(entry$requires)) {
    return(tc_parse_list_column(entry$requires))
  }

  if (!is.null(entry[["in"]])) {
    return(vapply(
      entry[["in"]],
      function(x) x$name %||% NA_character_,
      character(1)
    ))
  }

  character()
}

tc_parse_geography_wildcard <- function(entry) {
  if (!is.null(entry$wildcard)) {
    return(tc_parse_list_column(entry$wildcard))
  }

  if (!is.null(entry[["in"]])) {
    wildcard <- vapply(
      entry[["in"]],
      function(x) isTRUE(x$wildcard),
      logical(1)
    )
    return(vapply(
      entry[["in"]][wildcard],
      function(x) x$name %||% NA_character_,
      character(1)
    ))
  }

  character()
}

#' Retrieve Census geography metadata
#'
#' @inheritParams tc_variables
#'
#' @return A tibble of geography metadata.
#' @export
#' @examplesIf tinycensus::tc_has_key()
#' tc_geography("acs/acs5", 2024, refresh = TRUE)
tc_geography <- function(dataset, year = NULL, refresh = FALSE) {
  dataset_info <- tc_resolve_dataset(
    dataset,
    year,
    refresh = refresh,
    cache = TRUE
  )
  year <- dataset_info$year[[1]]
  json <- tc_fetch_metadata(
    dataset,
    year,
    "geography",
    refresh = refresh,
    cache = TRUE
  )
  geographies <- json[["fips"]]

  tibble::tibble(
    geography = geographies$name %||% NA_character_,
    summary_level = geographies$geoLevelDisplay %||% NA_character_,
    requires = I(
      geographies$requires %||%
        replicate(nrow(geographies), character(), simplify = FALSE)
    ),
    wildcard = I(
      geographies$wildcard %||%
        replicate(nrow(geographies), character(), simplify = FALSE)
    ),
    optional_with_wildcard_for = geographies$optionalWithWCFor %||%
      rep(NA_character_, nrow(geographies)),
    example = geographies$exampleValue %||%
      rep(NA_character_, nrow(geographies))
  )
}

#' Retrieve Census example query metadata
#'
#' @inheritParams tc_variables
#'
#' @return A list of example query metadata.
#' @export
#' @examplesIf tinycensus::tc_has_key()
#' tc_examples("acs/acs5", 2024, refresh = TRUE)
tc_examples <- function(dataset, year = NULL, refresh = FALSE) {
  dataset_info <- tc_resolve_dataset(
    dataset,
    year,
    refresh = refresh,
    cache = TRUE
  )
  year <- dataset_info$year[[1]]
  tc_fetch_metadata(dataset, year, "examples", refresh = refresh, cache = TRUE)
}

#' Search Census variable metadata
#'
#' @param dataset A Census dataset identifier like `"acs/acs5"`.
#' @param year Optional dataset year.
#' @param query Search string.
#' @param fields Metadata fields to search.
#' @param ignore_case Should matching ignore case?
#' @param refresh Should cached metadata be refreshed?
#'
#' @return A tibble of matching variables.
#' @export
tc_search_variables <- function(
  dataset,
  year = NULL,
  query,
  fields = c("name", "label", "concept"),
  ignore_case = TRUE,
  refresh = FALSE
) {
  if (!is.character(query) || length(query) != 1L || !nzchar(query)) {
    cli::cli_abort("{.arg query} must be a single non-empty string.")
  }

  fields <- unique(fields)
  valid_fields <- c("name", "label", "concept")
  if (!all(fields %in% valid_fields)) {
    cli::cli_abort(
      "{.arg fields} must be drawn from {.val {valid_fields}}."
    )
  }

  vars <- tc_variables(dataset, year, refresh = refresh)
  text <- apply(
    vars[, fields, drop = FALSE],
    1,
    function(x) paste(stats::na.omit(x), collapse = " ")
  )
  if (isTRUE(ignore_case)) {
    query <- tolower(query)
    text <- tolower(text)
  }
  keep <- grepl(query, text, fixed = TRUE)
  tibble::as_tibble(vars[keep, , drop = FALSE])
}

#' Retrieve encoded values metadata for a Census variable
#'
#' @param dataset A Census dataset identifier like `"acs/acs5"`.
#' @param year Optional dataset year.
#' @param variable Variable name.
#' @param refresh Should cached metadata be refreshed?
#'
#' @return A tibble of value codes and labels.
#' @export
tc_values <- function(dataset, year = NULL, variable, refresh = FALSE) {
  if (!is.character(variable) || length(variable) != 1L || !nzchar(variable)) {
    cli::cli_abort("{.arg variable} must be a single non-empty string.")
  }

  dataset_info <- tc_resolve_dataset(dataset, year, refresh = refresh, cache = TRUE)
  year <- dataset_info$year[[1]]
  url <- tc_variable_metadata_url(dataset, year, variable)
  json <- tc_fetch_json(
    url,
    context = list(dataset = dataset, year = year, variable = variable)
  )

  values <- json$values$item
  if (is.null(values) || !length(values)) {
    cli::cli_abort(
      "No encoded values metadata is available for {.val {variable}} in {.val {dataset}} ({.val {year}})."
    )
  }

  tibble::tibble(
    code = names(values),
    label = unname(unlist(values, use.names = FALSE))
  )
}
