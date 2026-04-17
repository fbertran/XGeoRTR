.render_layer_surface <- function(data, layer) {
  grid <- .regular_grid_from_long(data)
  z <- if (isTRUE(layer$smooth)) .smooth_matrix(grid$z) else grid$z
  z <- z * layer$scaling

  palette <- grDevices::colorRampPalette(
    c(layer$low_fill, layer$high_fill)
  )(64)
  color_idx <- cut(
    as.vector(z),
    breaks = 64,
    include.lowest = TRUE,
    labels = FALSE
  )
  colors <- matrix(
    palette[color_idx],
    nrow = nrow(z),
    ncol = ncol(z)
  )

  rgl::surface3d(
    x = grid$x,
    y = grid$y,
    z = z,
    color = colors,
    alpha = layer$alpha,
    front = "fill",
    back = "lines"
  )
}

.apply_camera <- function(camera) {
  preset <- .or_default(camera$preset, "isometric")

  switch(
    preset,
    top = rgl::view3d(theta = 0, phi = 90, zoom = 0.8),
    side = rgl::view3d(theta = 90, phi = 15, zoom = 0.8),
    focus_on_region = rgl::view3d(theta = 25, phi = 25, zoom = 1.0),
    rgl::view3d(theta = 35, phi = 20, zoom = 0.85)
  )
}

#' Render one `xgeo_layer`
#'
#' @param data Long-table data from an `xgeo_data` object.
#' @param layer Layer object to render.
#' @param scene Parent scene.
#' @param ... Reserved for future extension methods.
#'
#' @return Invisibly returns `NULL`.
#' @export
render_xgeo_layer <- function(data, layer, scene, ...) {
  UseMethod("render_xgeo_layer", layer)
}

#' @export
render_xgeo_layer.default <- function(data, layer, scene, ...) {
  cli::cli_warn("Skipping unsupported layer class {.cls {class(layer)[[1]]}}.")
  invisible(NULL)
}

#' @export
render_xgeo_layer.xgeo_layer_surface <- function(data, layer, scene, ...) {
  .render_layer_surface(data, layer)
  invisible(NULL)
}

#' Render an `xgeo_scene` to `rgl` / WebGL
#'
#' @param scene An `xgeo_scene` object.
#' @param file Optional HTML output path. When supplied, `htmlwidgets` is used
#'   to save an `rglwidget`.
#' @param selfcontained Passed to `htmlwidgets::saveWidget()`.
#' @param open Whether to open a visible device. When `FALSE`, `rgl` renders to
#'   a null device when possible.
#'
#' @return An `rglwidget`, an output file path, or the rendered scene
#'   invisibly.
#' @export
render_webgl <- function(scene,
                         file = NULL,
                         selfcontained = FALSE,
                         open = interactive()) {
  if (!inherits(scene, "xgeo_scene")) {
    cli::cli_abort("{.arg scene} must be an {.cls xgeo_scene}.")
  }

  if (!requireNamespace("rgl", quietly = TRUE)) {
    cli::cli_abort(
      "Package {.pkg rgl} is required for {.fn render_webgl}."
    )
  }

  if (isTRUE(open)) {
    rgl::open3d()
  } else {
    rgl::open3d(useNULL = TRUE)
  }

  rgl::clear3d(type = "all")
  rgl::bg3d(color = .or_default(scene$theme$background, "white"))

  for (layer in scene$layers) {
    render_xgeo_layer(scene$data$data, layer, scene = scene)
  }

  .apply_camera(scene$camera)

  if (is.null(file)) {
    if (requireNamespace("htmlwidgets", quietly = TRUE)) {
      return(rgl::rglwidget())
    }

    return(invisible(scene))
  }

  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    cli::cli_warn(
      "Package {.pkg htmlwidgets} is required to save HTML output; returning the rendered scene instead."
    )
    return(invisible(scene))
  }

  widget <- rgl::rglwidget()
  htmlwidgets::saveWidget(widget, file = file, selfcontained = selfcontained)

  invisible(normalizePath(file, winslash = "/", mustWork = FALSE))
}
