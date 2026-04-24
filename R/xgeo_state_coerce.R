#' Coerce inputs to `xgeo_state`
#'
#' @param x An object to coerce.
#' @param ... Passed to method-specific implementations.
#'
#' @return An `xgeo_state` object.
#'
#' @examples
#' as_xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
#'
#' as_xgeo_state(
#'   data.frame(
#'     point_id = c("p1", "p1", "p2"),
#'     feature = c("f1", "f2", "f1"),
#'     x = c(0, 0, 1),
#'     y = c(0, 0, 1),
#'     value = c(1, -0.5, 0.75)
#'   )
#' )
#' @export
as_xgeo_state <- function(x, ...) {
  UseMethod("as_xgeo_state")
}

#' @export
as_xgeo_state.default <- function(x, ...) {
  cli::cli_abort(
    "No {.fn as_xgeo_state} method is available for objects of class {.cls {class(x)}}."
  )
}

#' @export
as_xgeo_state.xgeo_state <- function(x, ...) {
  validate_xgeo_state(x)
  x
}

#' @export
as_xgeo_state.data.frame <- function(x, ...) {
  .xgeo_state_from_xgeo_data(as_xgeo_data(x, ...))
}

#' @export
as_xgeo_state.matrix <- function(x, ...) {
  .xgeo_state_from_xgeo_data(as_xgeo_data(x, ...))
}

#' @export
as_xgeo_state.xgeo_data <- function(x, ...) {
  .xgeo_state_from_xgeo_data(as_xgeo_data(x, ...))
}
