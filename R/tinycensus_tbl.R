#' Print a `tinycensus_tbl`
#'
#' @param x A `tinycensus_tbl`.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#' @export
#' @examples
#' x <- tibble::tibble(NAME = "Delaware", value = 1)
#' class(x) <- c("tinycensus_tbl", class(x))
#' attr(x, "dataset") <- "acs/acs5"
#' attr(x, "year") <- 2024
#' print(x)
print.tinycensus_tbl <- function(x, ...) {
  dataset <- attr(x, "dataset")
  year <- attr(x, "year")
  cli::cli_text("tinycensus result: {.val {dataset}} ({.val {year}})")
  NextMethod()
}
