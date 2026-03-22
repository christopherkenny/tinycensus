tc_acs_dataset <- function(survey = "acs5", product = "detailed") {
  survey <- rlang::arg_match(survey, c("acs1", "acs5"))
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
#' @inheritParams tc_get
#' @param survey ACS survey, either `"acs1"` or `"acs5"`.
#' @param product ACS product, such as `"detailed"` or `"profile"`.
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
  group = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  survey = c("acs5", "acs1"),
  product = c("detailed", "profile", "subject", "comparison"),
  key = tc_get_key(),
  geometry = FALSE,
  output = c("wide", "long"),
  name = TRUE,
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  ...
) {
  survey <- rlang::arg_match(survey)
  product <- rlang::arg_match(product)

  tc_get(
    dataset = tc_acs_dataset(survey = survey, product = product),
    year = year,
    variables = variables,
    group = group,
    geography = geography,
    within = within,
    predicates = predicates,
    key = key,
    geometry = geometry,
    output = output,
    name = name,
    refresh = refresh,
    cache = cache,
    ucgid = ucgid,
    ...
  )
}
