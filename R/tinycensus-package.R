#' tinycensus: Lightweight Interface to the US Census Bureau API
#'
#' `tinycensus` provides lightweight, metadata-driven access to the
#' [US Census Bureau API](https://www.census.gov/data/developers.html). The
#' package is organized around product-specific retrieval helpers such as
#' [tc_get_acs()], [tc_get_decennial()], [tc_get_pep()], [tc_get_cbp()],
#' [tc_get_flows()], and [tc_get_timeseries()], rather than a single generic
#' user-facing query function.
#'
#' It also includes task-oriented metadata helpers for discovering datasets,
#' variables, geographies, and tables, along with flexible geography inputs and
#' optional geometry joins through `tinytiger`.
#'
#' @keywords internal
"_PACKAGE"
