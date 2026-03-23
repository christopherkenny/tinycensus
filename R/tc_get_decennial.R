#' Retrieve Decennial Census data
#'
#' @param geography Census geography name.
#' @param variables Optional character vector of variable names.
#' @param table Optional table identifier. Mutually exclusive with `variables`.
#' @param year Decennial Census year.
#' @param dataset Decennial dataset path, such as `"pl"` or `"ddhca"`.
#' @param within Optional named list of parent geographies.
#' @param predicates Optional named list of additional predicates.
#' @param summary_var Optional summary variable to append as
#'   `summary_estimate` / `summary_moe`.
#' @param geometry Should geometry be joined after retrieval?
#' @param keep_geo_vars Should source geometry attributes be retained?
#' @param key Optional Census API key.
#' @param refresh Should cached metadata be refreshed?
#' @param cache Should discovery metadata be cached locally?
#' @param ucgid Optional `ucgid` predicate.
#' @param geography_vintage Optional geography vintage used for input
#'   normalization.
#' @param ... Geography values such as `state = "NY"` or `county = "001"`.
#'
#' @return A tibble or `sf` object.
#' @export
#' @examplesIf tinycensus::tc_has_key()
#' tc_get_decennial(
#'   year = 2020,
#'   dataset = "pl",
#'   variables = "P1_001N",
#'   geography = "county",
#'   state = "Delaware"
#' )
tc_get_decennial <- function(
  geography = NULL,
  variables = NULL,
  table = NULL,
  year,
  dataset = "pl",
  within = NULL,
  predicates = NULL,
  summary_var = NULL,
  geometry = FALSE,
  keep_geo_vars = FALSE,
  key = tc_get_key(),
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  geography_vintage = NULL,
  ...
) {
  dataset <- sub("^dec/", "", dataset)
  dataset <- paste0("dec/", dataset)

  tc_product_query(
    dataset = dataset,
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
