#' Set explicit point and feature selection on a state
#'
#' @param state An `xgeo_state` object.
#' @param point_ids Optional character vector of selected point ids.
#' @param features Optional character vector of selected feature ids.
#'
#' @return The updated `xgeo_state`.
#'
#' @examples
#' state <- as_xgeo_state(
#'   data.frame(
#'     point_id = c("p1", "p1", "p2", "p2"),
#'     feature = c("f1", "f2", "f1", "f2"),
#'     x = c(0, 0, 1, 1),
#'     y = c(0, 0, 1, 1),
#'     value = c(1, -0.25, 0.75, 2)
#'   ),
#'   point_id_col = "point_id",
#'   feature_col = "feature"
#' )
#' state <- set_xgeo_selection(state, point_ids = "p1", features = "f2")
#'
#' xgeo_selection(state)
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
#'
#' @examples
#' state <- as_xgeo_state(
#'   data.frame(
#'     point_id = rep(paste0("p", 1:4), each = 2),
#'     feature = rep(c("f1", "f2"), times = 4),
#'     x = c(0, 0, 1, 1, 0, 0, 1, 1),
#'     y = c(0, 0, 0, 0, 1, 1, 1, 1),
#'     value = c(0.2, 0.7, 0.4, 0.1, 0.8, 0.6, 0.5, 0.3)
#'   ),
#'   point_id_col = "point_id",
#'   feature_col = "feature"
#' )
#' state <- compute_xgeo_embedding(state, method = "pca", source = "explanations", dims = 2)
#' state <- set_active_embedding(state, "pca_explanations")
#'
#' state$attributes$embeddings$active
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
#'
#' @examples
#' state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
#' state <- build_xgeo_lod(state, levels = c(4L, 8L), auto_threshold = 2L)
#' state <- set_xgeo_lod(state, name = "density_grid_spatial", level = "4")
#'
#' state$lod$active
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
