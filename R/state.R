#' Set explicit point and feature selection on a state
#'
#' @param state An `xgeo_state` object.
#' @param point_ids Optional character vector of selected point ids.
#' @param features Optional character vector of selected feature ids.
#'
#' @return The updated `xgeo_state`.
#' @export
set_xgeo_selection <- function(state, point_ids = NULL, features = NULL) {
  validate_xgeo_state(state)

  point_ids <- unique(as.character(.or_default(point_ids, character())))
  features <- unique(as.character(.or_default(features, character())))

  if (length(point_ids) > 0L) {
    missing_points <- setdiff(point_ids, state$indices$point_ids)
    if (length(missing_points) > 0L) {
      cli::cli_abort(
        "Unknown {.arg point_ids}: {.val {missing_points}}."
      )
    }
  }

  if (length(features) > 0L) {
    missing_features <- setdiff(features, state$indices$feature_ids)
    if (length(missing_features) > 0L) {
      cli::cli_abort(
        "Unknown {.arg features}: {.val {missing_features}}."
      )
    }
  }

  state$selection <- list(
    point_ids = point_ids,
    features = features
  )
  state
}

#' Set the active embedding on a state
#'
#' @param state An `xgeo_state` object.
#' @param name Name of an embedding stored in `state$attributes$embeddings$items`.
#'
#' @return The updated `xgeo_state`.
#' @export
set_active_embedding <- function(state, name) {
  validate_xgeo_state(state)

  if (!.is_scalar_string(name)) {
    cli::cli_abort("{.arg name} must be a single string.")
  }

  if (!(name %in% names(state$attributes$embeddings$items))) {
    cli::cli_abort(
      "Unknown embedding {.val {name}}."
    )
  }

  state$attributes$embeddings$active <- name
  state
}

#' Set the active level-of-detail state on a state
#'
#' @param state An `xgeo_state` object.
#' @param name Optional LOD bundle name stored in `state$lod$items`.
#' @param level Optional level inside the selected LOD bundle.
#'
#' @return The updated `xgeo_state`.
#' @export
set_xgeo_lod <- function(state, name = NULL, level = NULL) {
  validate_xgeo_state(state)

  if (is.null(name)) {
    state$lod$active <- list(name = NULL, level = NULL)
    return(state)
  }

  if (!(name %in% names(state$lod$items))) {
    cli::cli_abort("Unknown LOD bundle {.val {name}}.")
  }

  bundle <- state$lod$items[[name]]
  if (is.null(level)) {
    level <- bundle$default_level
  }
  level <- as.character(level)

  if (!(level %in% names(bundle$levels))) {
    cli::cli_abort(
      "Unknown LOD level {.val {level}} for bundle {.val {name}}."
    )
  }

  state$lod$active <- list(name = name, level = level)
  state
}
