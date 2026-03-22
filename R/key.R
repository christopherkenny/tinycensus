#' Check for a Census API key
#'
#' @return A logical scalar.
#' @export
#' @examples
#' tc_has_key()
tc_has_key <- function() {
  Sys.getenv("CENSUS_API_KEY") != ""
}

#' Get the Census API key
#'
#' @return A character scalar, or `""` if no key is set.
#' @export
#' @examples
#' invisible(tc_get_key())
tc_get_key <- function() {
  Sys.getenv("CENSUS_API_KEY")
}

#' Set the Census API key
#'
#' Adds a Census API key to the current session and, optionally, to a
#' `.Renviron` file.
#'
#' @param key Character scalar API key.
#' @param overwrite Should an existing `CENSUS_API_KEY` entry in `.Renviron` be
#'   overwritten?
#' @param install Should the key be added to a `.Renviron` file?
#' @param r_env Path to the `.Renviron` file when `install = TRUE`.
#'
#' @return Invisibly returns the key.
#' @export
#' @examples
#' \dontrun{
#' tc_set_key("YOUR-API-KEY")
#' tc_set_key(
#'   "YOUR-API-KEY",
#'   install = TRUE,
#'   overwrite = TRUE,
#'   r_env = "~/.Renviron"
#' )
#' }
tc_set_key <- function(
  key,
  overwrite = FALSE,
  install = FALSE,
  r_env = NULL
) {
  if (missing(key)) {
    cli::cli_abort("Input {.arg key} cannot be missing.")
  }

  if (!is.character(key) || length(key) != 1L || !nzchar(key)) {
    cli::cli_abort("{.arg key} must be a single non-empty string.")
  }

  env_name <- "CENSUS_API_KEY"
  key_list <- list(key)
  names(key_list) <- env_name

  if (!isTRUE(install)) {
    do.call(Sys.setenv, key_list)
    return(invisible(key))
  }

  if (is.null(r_env)) {
    cli::cli_abort(c(
      "No path set.",
      i = "Re-run with {.arg r_env} set, possibly to {.file {file.path(Sys.getenv('HOME'), '.Renviron')}}."
    ))
  }

  if (!file.exists(r_env)) {
    file.create(r_env)
  }

  lines <- readLines(r_env, warn = FALSE)
  newline <- paste0(env_name, "='", key, "'")
  exists <- grepl(paste0("^", env_name, "="), lines)

  if (any(exists)) {
    if (sum(exists) > 1L) {
      cli::cli_abort(
        "Multiple {.val {env_name}} entries found in {.file {r_env}}. Edit manually."
      )
    }

    if (!isTRUE(overwrite)) {
      cli::cli_inform(
        "{.arg CENSUS_API_KEY} already exists in {.file {r_env}}. Re-run with {.code overwrite = TRUE} to replace it."
      )
      do.call(Sys.setenv, key_list)
      return(invisible(key))
    }

    lines[exists] <- newline
  } else {
    lines <- c(lines, newline)
  }

  writeLines(lines, r_env)
  do.call(Sys.setenv, key_list)
  invisible(key)
}
