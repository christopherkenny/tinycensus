first_row_as_names <- function(x) {
  colnames(x) <- x[1, ]
  x <- x[-1, ]
  x
}

as_tib <- function(x) {
  x <- x |>
    first_row_as_names() |>
    as.data.frame()
  class(x) <- c('tbl_df', 'tbl', 'data.frame')
  x
}
