#' Build density-grid LOD summaries for a scene
#'
#' @param scene An `xgeo_scene` object.
#' @param embedding Optional embedding name. Defaults to the active embedding.
#' @param levels Integer vector of grid resolutions.
#' @param color_by Statistic stored in each density grid.
#' @param name Optional LOD bundle name.
#' @param auto_threshold Point count threshold used by `lod_level = "auto"`.
#'
#' @return The updated `xgeo_scene`.
#' @export
build_xgeo_lod <- function(scene,
                           embedding = NULL,
                           levels = c(16L, 32L, 64L),
                           color_by = c("count", "mean_value"),
                           name = NULL,
                           auto_threshold = 200L) {
  .validate_xgeo_scene(scene)
  color_by <- match.arg(color_by)

  if (!all(vapply(levels, .is_count, logical(1)))) {
    cli::cli_abort("{.arg levels} must contain positive whole numbers.")
  }
  if (!.is_count(auto_threshold)) {
    cli::cli_abort("{.arg auto_threshold} must be a positive whole number.")
  }

  embedding_name <- .or_default(embedding, scene$embeddings$active)
  point_view <- .scene_point_view(scene, embedding = embedding_name)
  level_names <- as.character(sort(unique(as.integer(levels))))

  grids <- setNames(
    lapply(as.integer(level_names), function(level) {
      .density_grid(point_view, bins = level, color_by = color_by)
    }),
    level_names
  )

  name <- .or_default(name, paste("density_grid", embedding_name, sep = "_"))
  scene$lod$items[[name]] <- list(
    name = name,
    embedding = embedding_name,
    strategy = "density_grid",
    color_by = color_by,
    default_level = tail(level_names, 1),
    levels = grids,
    auto_threshold = auto_threshold
  )

  if (is.null(scene$lod$active$name)) {
    scene$lod$active <- list(
      name = name,
      level = tail(level_names, 1)
    )
  }

  scene
}
