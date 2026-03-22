#' Retrieve Decennial Census data
#'
#' @inheritParams tc_get
#' @param dataset Decennial dataset path, such as `"pl"` or `"dhc"`.
#'
#' @return A tibble or `sf` object.
#' @export
#' @examplesIf tc_has_key()
#' tc_get_decennial(
#'   year = 2020,
#'   dataset = "pl",
#'   variables = "P1_001N",
#'   geography = "county",
#'   state = "Delaware"
#' )
tc_get_decennial <- function(
  year,
  variables = NULL,
  group = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  dataset = "pl",
  key = tc_get_key(),
  geometry = FALSE,
  output = c("wide", "long"),
  name = TRUE,
  refresh = FALSE,
  cache = TRUE,
  ucgid = NULL,
  ...
) {
  dataset <- sub("^dec/", "", dataset)

  tc_get(
    dataset = paste0("dec/", dataset),
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
