tc_acs_dataset <- function(survey = "acs5", product = "detailed") {
  survey <- rlang::arg_match(survey, c("acs1", "acs3", "acs5"))
  product <- rlang::arg_match(
    product,
    c("detailed", "profile", "subject", "comparison")
  )

  suffix <- switch(
    product,
    detailed = "",
    profile = "/profile",
    subject = "/subject",
    comparison = "/cprofile"
  )

  paste0("acs/", survey, suffix)
}

#' Retrieve American Community Survey data
#'
#' @param year ACS year.
#' @param variables Optional character vector of variable names.
#' @param table Optional ACS table identifier. Mutually exclusive with
#'   `variables`.
#' @param geography Census geography name.
#' @param within Optional named list of parent geographies.
#' @param predicates Optional named list of additional predicates.
#' @param survey ACS survey, one of `"acs1"`, `"acs3"`, or `"acs5"`.
#' @param product ACS product, one of `"detailed"`, `"profile"`, `"subject"`,
#'   or `"comparison"`.
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
#' tc_get_acs(
#'   year = 2024,
#'   variables = "B01001_001E",
#'   geography = "state",
#'   state = c("NY", "Delaware")
#' )
tc_get_acs <- function(
  year,
  variables = NULL,
  table = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  survey = c("acs5", "acs1", "acs3"),
  product = c("detailed", "profile", "subject", "comparison"),
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
  survey <- rlang::arg_match(survey)
  product <- rlang::arg_match(product)

  tc_product_query(
    dataset = tc_acs_dataset(survey = survey, product = product),
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
