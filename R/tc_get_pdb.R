tc_pdb_dataset <- function(dataset = NULL, geography = NULL) {
  dataset <- tc_null_if_empty(dataset)
  geography <- tc_normalize_geography_name(tc_null_if_empty(geography))

  if (!is.null(dataset)) {
    if (grepl("^pdb/", dataset)) {
      return(dataset)
    }

    cli::cli_abort(
      "{.arg dataset} for the Planning Database must be a `pdb/...` dataset path."
    )
  }

  if (is.null(geography)) {
    cli::cli_abort(
      "Supply either {.arg dataset} or a supported {.arg geography} for the Planning Database."
    )
  }

  if (identical(geography, "tract")) {
    return("pdb/tract")
  }

  if (identical(geography, "block group")) {
    return("pdb/blockgroup")
  }

  if (geography %in% c("state", "county")) {
    return("pdb/statecounty")
  }

  cli::cli_abort(
    "Planning Database geography must be one of {.val state}, {.val county}, {.val tract}, or {.val block group}."
  )
}

#' Retrieve Census Planning Database data
#'
#' @param geography Census geography name.
#' @param variables Optional character vector of variable names.
#' @param table Optional table or group identifier. Mutually exclusive with
#'   `variables`.
#' @param year Dataset year.
#' @param dataset Optional `pdb/...` dataset path. When omitted, the dataset is
#'   inferred from `geography`.
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
#' tc_get_pdb(
#'   year = 2024,
#'   variables = "Tot_Population_CEN_2020",
#'   geography = "tract",
#'   state = "NY",
#'   county = "061"
#' )
tc_get_pdb <- function(
  geography = NULL,
  variables = NULL,
  table = NULL,
  year,
  dataset = NULL,
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
  dataset <- tc_pdb_dataset(dataset = dataset, geography = geography)

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
