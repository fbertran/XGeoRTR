#' Get geometry from an `xgeo_state`
#'
#' @param state An `xgeo_state` object.
#'
#' @return The `geometry` field.
#'
#' @examples
#' state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))
#'
#' xgeo_geometry(state)$points
#' @export
xgeo_geometry <- function(state) {
  validate_xgeo_state(state)
  state$geometry
}

#' Get attributes from an `xgeo_state`
#'
#' @param state An `xgeo_state` object.
#'
#' @return The `attributes` field.
#'
#' @examples
#' state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))
#'
#' names(xgeo_attributes(state))
#' @export
xgeo_attributes <- function(state) {
  validate_xgeo_state(state)
  state$attributes
}

#' Get indices from an `xgeo_state`
#'
#' @param state An `xgeo_state` object.
#'
#' @return The `indices` field.
#'
#' @examples
#' state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))
#'
#' xgeo_indices(state)
#' @export
xgeo_indices <- function(state) {
  validate_xgeo_state(state)
  state$indices
}

#' Get selection from an `xgeo_state`
#'
#' @param state An `xgeo_state` object.
#'
#' @return The `selection` field.
#'
#' @examples
#' state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))
#' state <- set_xgeo_selection(state, point_ids = state$indices$point_ids[[1]])
#'
#' xgeo_selection(state)
#' @export
xgeo_selection <- function(state) {
  validate_xgeo_state(state)
  state$selection
}

#' Get metadata from an `xgeo_state`
#'
#' @param state An `xgeo_state` object.
#'
#' @return The `metadata` field.
#'
#' @examples
#' state <- xgeo_state(
#'   matrix(c(1, 2, 3, 4), nrow = 2),
#'   metadata = list(source = "demo-state")
#' )
#'
#' xgeo_metadata(state)
#' @export
xgeo_metadata <- function(state) {
  validate_xgeo_state(state)
  state$metadata
}
