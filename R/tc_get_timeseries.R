tc_timeseries_dataset <- function(dataset) {
  dataset <- tc_null_if_empty(dataset)
  if (is.null(dataset)) {
    cli::cli_abort("{.arg dataset} must be a non-empty string.")
  }

  dataset <- sub("^/+", "", dataset)
  if (!grepl("^timeseries/", dataset)) {
    dataset <- paste0("timeseries/", dataset)
  }

  dataset
}

tc_timeseries_predicates <- function(predicates = NULL, time = NULL) {
  predicates <- tc_prepare_predicates(predicates)

  if (!is.null(time) && "time" %in% names(predicates)) {
    cli::cli_abort(
      "Supply timeseries dates with either {.arg time} or {.arg predicates$time}, not both."
    )
  }

  if (!is.null(time)) {
    predicates$time <- as.character(time)
  }

  predicates
}

#' Retrieve Census time-series data
#'
#' @param dataset A time-series dataset identifier.
#' @param variables Optional character vector of variable names.
#' @param table Optional group or table identifier. Mutually exclusive with
#'   `variables`.
#' @param geography Optional Census geography name.
#' @param within Optional named list of parent geographies.
#' @param predicates Optional named list of filter predicates other than `time`.
#' @param time Optional timeseries date value, such as `"2024-01"`.
#' @param year Optional dataset year. Most timeseries datasets ignore this and
#'   resolve through the discovery catalog.
#' @param key Optional Census API key.
#' @param refresh Should cached metadata be refreshed?
#' @param cache Should discovery metadata be cached locally?
#' @param ucgid Optional `ucgid` predicate.
#' @param ... Geography values such as `state = "NY"` or `county = "001"`.
#'
#' @return A tibble.
#' @export
#' @examplesIf tc_has_key()
#' tc_get_timeseries(
#'   dataset = "intltrade/exports/hs",
#'   variables = "ALL_VAL_MO",
#'   time = "2024-01",
#'   predicates = list(CTY_CODE = "2010")
#' )
tc_get_timeseries <- function(
  dataset,
  variables = NULL,
  table = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  time = NULL,
  year = NULL,
  key = tc_get_key(),
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  ...
) {
  dataset <- tc_timeseries_dataset(dataset)
  predicates <- tc_timeseries_predicates(predicates = predicates, time = time)
  specials <- tc_prepare_special_variables(
    dataset = dataset,
    year = year,
    variables = variables,
    geography = geography,
    refresh = refresh
  )
  variables <- tc_null_if_empty(specials$variables)

  if (is.null(tc_null_if_empty(variables)) && is.null(tc_null_if_empty(table))) {
    cli::cli_abort("Supply either {.arg variables} or {.arg table}.")
  }

  if (!is.null(tc_null_if_empty(variables)) && !is.null(tc_null_if_empty(table))) {
    cli::cli_abort("{.arg variables} and {.arg table} are mutually exclusive.")
  }

  out <- tc_dataset_query_raw(
    dataset = dataset,
    year = year,
    variables = variables,
    group = table,
    geography = geography,
    within = within,
    predicates = predicates,
    key = key,
    refresh = refresh,
    cache = cache,
    ucgid = ucgid,
    ...
  )
  out <- tc_apply_value_labels(
    out,
    dataset = attr(out, "dataset"),
    year = attr(out, "year"),
    label_map = specials$label_map,
    refresh = refresh
  )
  out <- tc_apply_aliases(out, specials$alias_map)

  tc_as_tinycensus_tbl(
    out,
    dataset = attr(out, "dataset"),
    year = attr(out, "year"),
    geography = NULL
  )
}
