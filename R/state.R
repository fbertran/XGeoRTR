#' Set explicit point and feature selection on a scene
#'
#' @param scene An `xgeo_scene` object.
#' @param point_ids Optional character vector of selected point ids.
#' @param features Optional character vector of selected feature ids.
#'
#' @return The updated `xgeo_scene`.
#' @export
set_xgeo_selection <- function(scene, point_ids = NULL, features = NULL) {
  .validate_xgeo_scene(scene)

  point_ids <- unique(as.character(.or_default(point_ids, character())))
  features <- unique(as.character(.or_default(features, character())))

  if (length(point_ids) > 0L) {
    missing_points <- setdiff(point_ids, scene$data$points$point_id)
    if (length(missing_points) > 0L) {
      cli::cli_abort(
        "Unknown {.arg point_ids}: {.val {missing_points}}."
      )
    }
  }

  if (length(features) > 0L) {
    missing_features <- setdiff(features, scene$data$feature_meta$feature)
    if (length(missing_features) > 0L) {
      cli::cli_abort(
        "Unknown {.arg features}: {.val {missing_features}}."
      )
    }
  }

  scene$selection <- list(
    point_ids = point_ids,
    features = features
  )
  scene
}

#' Set the active embedding on a scene
#'
#' @param scene An `xgeo_scene` object.
#' @param name Name of an embedding stored in `scene$embeddings$items`.
#'
#' @return The updated `xgeo_scene`.
#' @export
set_active_embedding <- function(scene, name) {
  .validate_xgeo_scene(scene)

  if (!.is_scalar_string(name)) {
    cli::cli_abort("{.arg name} must be a single string.")
  }

  if (!(name %in% names(scene$embeddings$items))) {
    cli::cli_abort(
      "Unknown embedding {.val {name}}."
    )
  }

  scene$embeddings$active <- name
  scene
}

#' Set the active level-of-detail state on a scene
#'
#' @param scene An `xgeo_scene` object.
#' @param name Optional LOD bundle name stored in `scene$lod$items`.
#' @param level Optional level inside the selected LOD bundle.
#'
#' @return The updated `xgeo_scene`.
#' @export
set_xgeo_lod <- function(scene, name = NULL, level = NULL) {
  .validate_xgeo_scene(scene)

  if (is.null(name)) {
    scene$lod$active <- list(name = NULL, level = NULL)
    return(scene)
  }

  if (!(name %in% names(scene$lod$items))) {
    cli::cli_abort("Unknown LOD bundle {.val {name}}.")
  }

  bundle <- scene$lod$items[[name]]
  if (is.null(level)) {
    level <- bundle$default_level
  }
  level <- as.character(level)

  if (!(level %in% names(bundle$levels))) {
    cli::cli_abort(
      "Unknown LOD level {.val {level}} for bundle {.val {name}}."
    )
  }

  scene$lod$active <- list(name = name, level = level)
  scene
}
