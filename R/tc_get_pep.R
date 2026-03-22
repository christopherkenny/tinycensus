#' Retrieve Population Estimates Program data
#'
#' @inheritParams tc_get
#' @param dataset A `pep/...` dataset identifier.
#'
#' @return A tibble or `sf` object.
#' @export
#' @examplesIf tc_has_key()
#' tc_get_pep(
#'   dataset = "pep/population",
#'   year = 2021,
#'   variables = "POP_2021",
#'   geography = "state",
#'   state = c("NY", "Delaware")
#' )
tc_get_pep <- function(dataset, ...) {
  dataset <- if (grepl("^pep/", dataset)) dataset else paste0("pep/", dataset)
  tc_get(dataset = dataset, ...)
}
