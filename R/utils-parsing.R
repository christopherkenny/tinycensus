tc_null_if_empty <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NULL)
  }

  if (is.character(x) && !any(nzchar(x))) {
    return(NULL)
  }

  x
}

tc_recycle <- function(x, size, arg = "x") {
  if (is.null(x)) {
    return(NULL)
  }

  if (length(x) == size) {
    return(x)
  }

  if (length(x) == 1L) {
    return(rep(x, size))
  }

  cli::cli_abort("{.arg {arg}} must have length 1 or {size}.")
}

tc_compact <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

tc_unique <- function(x) {
  unique(x[!is.na(x)])
}

tc_clean_name <- function(x) {
  x <- tolower(trimws(x))
  x <- gsub("[.']", "", x)
  x <- gsub("&", "and", x)
  x <- gsub("\\s+", " ", x)
  x
}

tc_clean_county_name <- function(x) {
  x <- tc_clean_name(x)
  x <- sub(",.*$", "", x)
  x <- gsub(
    "\\s+(county|parish|borough|census area|municipality|city and borough|municipio)$",
    "",
    x
  )
  trimws(x)
}

tc_encode_query <- function(params) {
  params <- tc_compact(params)

  if (!length(params)) {
    return("")
  }

  pieces <- unlist(
    Map(
      f = function(name, value) {
        value <- as.character(value)
        paste0(
          curl::curl_escape(name),
          "=",
          vapply(value, curl::curl_escape, character(1))
        )
      },
      names(params),
      params
    ),
    use.names = FALSE
  )

  paste(pieces, collapse = "&")
}

tc_build_url <- function(base_url, params = NULL) {
  query <- tc_encode_query(params)
  if (!nzchar(query)) {
    return(base_url)
  }

  paste0(base_url, "?", query)
}

tc_json_matrix_to_tibble <- function(x) {
  if (is.null(dim(x)) || length(dim(x)) != 2L) {
    cli::cli_abort(
      "The Census API response was not in the expected tabular format."
    )
  }

  colnames <- x[1, , drop = TRUE]
  values <- x[-1, , drop = FALSE]
  keep <- !duplicated(colnames)
  colnames <- colnames[keep]
  values <- values[, keep, drop = FALSE]

  out <- as.data.frame(values, stringsAsFactors = FALSE)
  names(out) <- colnames
  tibble::as_tibble(out)
}

tc_as_tinycensus_tbl <- function(x, dataset, year, geography = NULL) {
  attr(x, "dataset") <- dataset
  attr(x, "year") <- year
  attr(x, "geography") <- geography
  x
}

tc_parse_list_column <- function(x) {
  if (is.null(x)) {
    return(character())
  }

  if (is.list(x)) {
    return(unlist(x, use.names = FALSE))
  }

  as.character(x)
}

tc_guess_numeric <- function(values, type) {
  if (type %in% c("int", "integer")) {
    suppressWarnings(as.numeric(values))
  } else if (type %in% c("float", "numeric")) {
    suppressWarnings(as.numeric(values))
  } else {
    values
  }
}

tc_to_long <- function(data, value_columns) {
  id_columns <- setdiff(names(data), value_columns)

  long_parts <- lapply(value_columns, function(column) {
    tibble::tibble(
      data[id_columns],
      variable = column,
      value = data[[column]]
    )
  })

  vctrs::vec_rbind(!!!long_parts)
}
