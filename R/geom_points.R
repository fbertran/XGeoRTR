#' Add a point-cloud layer
#'
#' @param embedding Optional embedding name. Defaults to the active embedding.
#' @param size Point size passed to `rgl::points3d()`.
#' @param alpha Point alpha.
#' @param color_by Point-level numeric field used for coloring.
#' @param low_fill Low-end color.
#' @param mid_fill Midpoint color.
#' @param high_fill High-end color.
#'
#' @return An `xgeo_layer` object.
#' @export
geom_xgeo_points <- function(embedding = NULL,
                             size = 8,
                             alpha = 0.85,
                             color_by = "value",
                             low_fill = "#2166AC",
                             mid_fill = "#F7F7F7",
                             high_fill = "#B2182B") {
  if (!.is_scalar_numeric(size) || size <= 0) {
    cli::cli_abort("{.arg size} must be a positive numeric scalar.")
  }
  if (!.is_scalar_numeric(alpha) || alpha <= 0 || alpha > 1) {
    cli::cli_abort("{.arg alpha} must be in the interval (0, 1].")
  }
  if (!.is_scalar_string(color_by)) {
    cli::cli_abort("{.arg color_by} must be a single string.")
  }

  structure(
    list(
      geom = "points",
      embedding = embedding,
      size = size,
      alpha = alpha,
      color_by = color_by,
      low_fill = low_fill,
      mid_fill = mid_fill,
      high_fill = high_fill
    ),
    class = c("xgeo_layer_points", "xgeo_layer")
  )
}
