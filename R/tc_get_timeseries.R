#' Retrieve time-series Census API data
#'
#' @inheritParams tc_get
#' @param dataset A time-series dataset identifier.
#'
#' @return A tibble or `sf` object.
#' @export
#' @examplesIf tc_has_key()
#' tc_get_timeseries(
#'   dataset = "intltrade/exports/hs",
#'   year = NULL,
#'   variables = "ALL_VAL_MO",
#'   predicates = list(time = "2024-01", CTY_CODE = "2010")
#' )
tc_get_timeseries <- function(dataset, ...) {
  dataset <- sub("^/+", "", dataset)
  if (!grepl("^timeseries/", dataset)) {
    dataset <- paste0("timeseries/", dataset)
  }
  tc_get(dataset = dataset, ...)
}
