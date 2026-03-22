#' Retrieve County Business Patterns data
#'
#' @inheritParams tc_get
#' @param dataset A `cbp` dataset identifier. Defaults to `"cbp"`.
#'
#' @return A tibble or `sf` object.
#' @export
#' @examplesIf tc_has_key()
#' tc_get_cbp(
#'   year = 2021,
#'   variables = "ESTAB",
#'   geography = "state",
#'   state = c("NY", "DE")
#' )
tc_get_cbp <- function(dataset = "cbp", ...) {
  tc_get(dataset = dataset, ...)
}
