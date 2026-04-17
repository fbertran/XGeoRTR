#' Add a generic surface layer
#'
#' @param feature Optional feature subset to aggregate before rendering.
#' @param scaling Vertical scale multiplier for explanation values.
#' @param alpha Surface alpha.
#' @param smooth Whether to apply a simple neighborhood average before
#'   rendering.
#' @param low_fill Color used near the lower value range.
#' @param high_fill Color used near the upper value range.
#'
#' @return An `xgeo_layer` object.
#' @export
geom_xgeo_surface <- function(feature = NULL,
                              scaling = 1,
                              alpha = 0.7,
                              smooth = FALSE,
                              low_fill = "#20639B",
                              high_fill = "#D1495B") {
  if (!.is_scalar_numeric(scaling) || scaling <= 0) {
    cli::cli_abort("{.arg scaling} must be a positive numeric scalar.")
  }
  if (!.is_scalar_numeric(alpha) || alpha <= 0 || alpha > 1) {
    cli::cli_abort("{.arg alpha} must be in the interval (0, 1].")
  }
  if (!.is_scalar_flag(smooth)) {
    cli::cli_abort("{.arg smooth} must be `TRUE` or `FALSE`.")
  }

  structure(
    list(
      geom = "surface",
      feature = feature,
      scaling = scaling,
      alpha = alpha,
      smooth = smooth,
      low_fill = low_fill,
      high_fill = high_fill
    ),
    class = c("xgeo_layer_surface", "xgeo_layer")
  )
}
