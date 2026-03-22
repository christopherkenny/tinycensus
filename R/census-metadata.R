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

  readRDS(path)
}

tc_cache_write <- function(object, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(object, path)
  invisible(object)
}

tc_fetch_json <- function(url) {
  req <- httr2::request(url) |>
    httr2::req_user_agent(
      "tinycensus (https://github.com/christopherkenny/tinycensus)"
    ) |>
    httr2::req_retry(max_tries = 3)

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) >= 400) {
    cli::cli_abort("Census API request failed for {.url {url}}.")
  }

  httr2::resp_body_json(resp, simplifyVector = TRUE)
}

tc_fetch_json_list <- function(url) {
  req <- httr2::request(url) |>
    httr2::req_user_agent(
      "tinycensus (https://github.com/christopherkenny/tinycensus)"
    ) |>
    httr2::req_retry(max_tries = 3)

  resp <- httr2::req_perform(req)

  if (httr2::resp_status(resp) >= 400) {
    cli::cli_abort("Census API request failed for {.url {url}}.")
  }

  httr2::resp_body_json(resp, simplifyVector = FALSE)
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

  json <- tc_fetch_json_list("https://api.census.gov/data.json")
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

  json <- tc_fetch_json(url)

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
#' @examplesIf tc_has_key()
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
#' @examplesIf tc_has_key()
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
#' @examplesIf tc_has_key()
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
    required = vapply(variables, function(x) isTRUE(x$required), logical(1)),
    attributes = I(lapply(variables, function(x) {
      tc_parse_list_column(x$attributes)
    }))
  )

  out[order(out$name), ]
}

#' Retrieve Census group metadata
#'
#' @inheritParams tc_variables
#'
#' @return A tibble of group metadata.
#' @export
#' @examplesIf tc_has_key()
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
#' @examplesIf tc_has_key()
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
#' @examplesIf tc_has_key()
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
