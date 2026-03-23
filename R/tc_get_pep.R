tc_pep_dataset <- function(
  dataset = NULL,
  product = NULL,
  year = NULL,
  breakdown = NULL
) {
  dataset <- tc_null_if_empty(dataset)
  product <- tc_null_if_empty(product)

  if (!is.null(dataset) && !is.null(product)) {
    cli::cli_abort(
      "{.arg dataset} and {.arg product} are mutually exclusive."
    )
  }

  target <- product %||% dataset %||% "population"

  if (grepl("^pep/", target)) {
    return(target)
  }

  if (identical(target, "characteristics")) {
    breakdown <- unique(as.character(tc_null_if_empty(breakdown) %||% character()))

    if ("AGE" %in% breakdown && "AGEGROUP" %in% breakdown) {
      cli::cli_abort(
        "{.arg breakdown} cannot include both {.val AGE} and {.val AGEGROUP}."
      )
    }

    if (!is.null(year) && year >= 2023L) {
      return("pep/charv")
    }

    if (!is.null(year) && year >= 2000L) {
      if ("AGEGROUP" %in% breakdown) {
        return("pep/charagegroups")
      }

      return("pep/charage")
    }
  }

  paste0("pep/", target)
}

tc_pep_breakdown_variables <- function(breakdown = NULL) {
  breakdown <- tc_null_if_empty(breakdown)
  if (is.null(breakdown)) {
    return(character())
  }

  breakdown <- unique(as.character(breakdown))
  allowed <- c("AGE", "AGEGROUP", "SEX", "HISP", "RACE")
  bad <- setdiff(breakdown, allowed)
  if (length(bad)) {
    cli::cli_abort(
      "{.arg breakdown} must only include {.val {allowed}}. Problem values: {.val {bad}}."
    )
  }

  mapped <- c(
    AGE = "AGE",
    AGEGROUP = "AGE",
    SEX = "SEX",
    HISP = "HISP",
    RACE = "POPGROUP"
  )

  unique(unname(mapped[breakdown]))
}

tc_pep_default_variables <- function(dataset, year, breakdown = NULL, refresh = FALSE) {
  if (dataset %in% c("pep/charv", "pep/charage", "pep/charagegroups")) {
    return(unique(c("POP", tc_pep_breakdown_variables(breakdown))))
  }

  meta <- tc_variables(dataset, year, refresh = refresh)

  if (dataset == "pep/population") {
    keep <- grepl("^(POP|DENSITY|NPOPCHG|PPOPCHG|RANK_)", meta$name)
    return(meta$name[keep])
  }

  if (dataset == "pep/components") {
    keep <- grepl(
      "^(BIRTHS|DEATHS|DOMESTICMIG|INTERNATIONALMIG|NATURALINC|NETMIG|PERIOD_CODE|PERIOD_DESC|RBIRTH|RDEATH|RDOMESTICMIG|RESIDUAL|RINTERNATIONALMIG|RNATURALINC|RNETMIG)$",
      meta$name
    )
    return(meta$name[keep])
  }

  if (dataset == "pep/housing") {
    return(intersect(c("DATE_CODE", "DATE_DESC", "HUEST"), meta$name))
  }

  keep <- !meta$predicate_type %in% c("fips-for", "fips-in", "ucgid")
  vars <- meta$name[keep]
  setdiff(vars, c("NAME", "GEOID", "ucgid"))
}

tc_pep_label_variables <- function(dataset, breakdown = NULL) {
  breakdown <- unique(as.character(tc_null_if_empty(breakdown) %||% character()))

  if (!length(breakdown)) {
    return(character())
  }

  if (dataset == "pep/charv") {
    out <- character()
    if ("RACE" %in% breakdown) {
      out <- c(out, "POPGROUP_LABEL")
    }
    return(out)
  }

  if (dataset == "pep/charage") {
    mapped <- c(SEX = "SEX_LABEL", HISP = "HISP_LABEL", RACE = "RACE_LABEL")
    return(unname(mapped[breakdown[breakdown %in% names(mapped)]]))
  }

  character()
}

#' Retrieve Population Estimates Program data
#'
#' @param year Dataset year.
#' @param variables Optional character vector of variable names.
#' @param table Optional table or group identifier. Mutually exclusive with
#'   `variables`.
#' @param geography Census geography name.
#' @param within Optional named list of parent geographies.
#' @param predicates Optional named list of additional predicates.
#' @param dataset PEP dataset path, such as `"population"` or
#'   `"components"`. A leading `"pep/"` is optional.
#' @param product Optional PEP product alias. Supported values are
#'   `"population"`, `"components"`, `"housing"`, and `"characteristics"`.
#' @param breakdown Optional characteristics breakdown variables. Supported
#'   values are `"AGE"`, `"AGEGROUP"`, `"SEX"`, `"HISP"`, and `"RACE"`.
#' @param breakdown_labels Should label variables for supported breakdowns be
#'   added automatically?
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
#' tc_get_pep(
#'   year = 2021,
#'   product = "population",
#'   variables = "POP_2021",
#'   geography = "state",
#'   state = c("NY", "Delaware")
#' )
tc_get_pep <- function(
  year,
  variables = NULL,
  table = NULL,
  geography = NULL,
  within = NULL,
  predicates = NULL,
  dataset = NULL,
  product = NULL,
  breakdown = NULL,
  breakdown_labels = FALSE,
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
  dataset <- tc_pep_dataset(
    dataset = dataset,
    product = product,
    year = year,
    breakdown = breakdown
  )
  pep_breakdown <- tc_pep_breakdown_variables(breakdown)
  variables <- tc_null_if_empty(variables)

  if (is.null(variables) && is.null(table) && !is.null(product)) {
    variables <- tc_pep_default_variables(
      dataset = dataset,
      year = year,
      breakdown = breakdown,
      refresh = refresh
    )
  }

  if (length(pep_breakdown)) {
    variables <- unique(c(variables %||% "POP", pep_breakdown))
  }

  if (isTRUE(breakdown_labels)) {
    variables <- unique(c(
      variables %||% character(),
      tc_pep_label_variables(dataset, breakdown = breakdown)
    ))
  }

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
