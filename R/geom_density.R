#' Add a density-grid layer
#'
#' @param embedding Optional embedding name. Defaults to the active embedding.
#' @param bins Grid resolution used when no precomputed LOD level is selected.
#' @param color_by Statistic used for cell coloring. One of `"count"` or
#'   `"mean_value"`.
#' @param lod_name Optional precomputed LOD bundle name.
#' @param level Optional precomputed level inside `lod_name`.
#' @param alpha Layer alpha.
#' @param low_fill Low-end color.
#' @param high_fill High-end color.
#'
#' @return An `xgeo_layer` object.
#' @export
geom_xgeo_density <- function(embedding = NULL,
                              bins = 32L,
                              color_by = c("count", "mean_value"),
                              lod_name = NULL,
                              level = NULL,
                              alpha = 0.85,
                              low_fill = "#F4D35E",
                              high_fill = "#EE964B") {
  color_by <- match.arg(color_by)

  if (!.is_count(bins)) {
    cli::cli_abort("{.arg bins} must be a positive whole number.")
  }
  if (!.is_scalar_numeric(alpha) || alpha <= 0 || alpha > 1) {
    cli::cli_abort("{.arg alpha} must be in the interval (0, 1].")
  }

  structure(
    list(
      geom = "density",
      embedding = embedding,
      bins = as.integer(bins),
      color_by = color_by,
      lod_name = lod_name,
      level = if (is.null(level)) NULL else as.character(level),
      alpha = alpha,
      low_fill = low_fill,
      high_fill = high_fill
    ),
    class = c("xgeo_layer_density", "xgeo_layer")
  )
}
