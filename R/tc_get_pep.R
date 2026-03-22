tc_pep_dataset <- function(dataset = "population") {
  dataset <- tc_null_if_empty(dataset) %||% "population"
  if (grepl("^pep/", dataset)) {
    return(dataset)
  }

  paste0("pep/", dataset)
}

#' Retrieve Population Estimates Program data
#'
#' @param year Dataset year.
#' @param variables Optional character vector of variable names.
#' @param table Optional table or group identifier. Mutually exclusive with
#'   `variables`.
#' @param geography Census geography name.
#' @param within Optional named list of parent geographies.
#' @param predicates Optional named list of additional predicates.
#' @param dataset PEP dataset path, such as `"population"` or
#'   `"components"`. A leading `"pep/"` is optional.
#' @param summary_var Optional summary variable to append as
#'   `summary_estimate` / `summary_moe`.
#' @param key Optional Census API key.
#' @param geometry Should geometry be joined after retrieval?
#' @param keep_geo_vars Should source geometry attributes be retained?
#' @param refresh Should cached metadata be refreshed?
#' @param cache Should discovery metadata be cached locally?
#' @param ucgid Optional `ucgid` predicate.
#' @param geography_vintage Optional geography vintage used for input
#'   normalization.
#' @param ... Geography values such as `state = "NY"` or `county = "001"`.
#'
#' @return A tibble or `sf` object.
#' @export
#' @examplesIf tc_has_key()
#' tc_get_pep(
#'   year = 2021,
#'   dataset = "population",
#'   variables = "POP_2021",
#'   geography = "state",
#'   state = c("NY", "Delaware")
#' )
tc_get_pep <- function(
  year,
  variables = NULL,
  table = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  dataset = "population",
  summary_var = NULL,
  key = tc_get_key(),
  geometry = FALSE,
  keep_geo_vars = FALSE,
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  geography_vintage = NULL,
  ...
) {
  tc_product_query(
    dataset = tc_pep_dataset(dataset),
    year = year,
    variables = variables,
    table = table,
    geography = geography,
    within = within,
    predicates = predicates,
    key = key,
    geometry = geometry,
    keep_geo_vars = keep_geo_vars,
    summary_var = summary_var,
    refresh = refresh,
    cache = cache,
    ucgid = ucgid,
    geography_vintage = geography_vintage,
    ...
  )
}
