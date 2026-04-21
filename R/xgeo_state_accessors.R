#' Get geometry from an `xgeo_state`
#'
#' @param state An `xgeo_state` object.
#'
#' @return The `geometry` field.
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
#' @export
xgeo_metadata <- function(state) {
  validate_xgeo_state(state)
  state$metadata
}
