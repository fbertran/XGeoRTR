.map_colors <- function(values,
                        low_fill,
                        high_fill,
                        mid_fill = NULL,
                        n = 64L) {
  if (!is.numeric(values)) {
    cli::cli_abort("Color mapping requires numeric values.")
  }

  if (all(values == values[[1]])) {
    return(rep(.or_default(mid_fill, high_fill), length(values)))
  }

  palette <- if (!is.null(mid_fill) && min(values) < 0 && max(values) > 0) {
    grDevices::colorRampPalette(c(low_fill, mid_fill, high_fill))(n)
  } else {
    grDevices::colorRampPalette(c(low_fill, high_fill))(n)
  }

  idx <- cut(values, breaks = n, include.lowest = TRUE, labels = FALSE)
  palette[idx]
}

.render_layer_surface <- function(scene, layer) {
  data <- .point_value_table(scene$data, feature = layer$feature)
  grid <- .regular_grid_from_long(data[, c("x", "y", "value"), drop = FALSE])
  z <- if (isTRUE(layer$smooth)) .smooth_matrix(grid$z) else grid$z
  z <- z * layer$scaling

  colors <- matrix(
    .map_colors(as.vector(z), layer$low_fill, layer$high_fill),
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

.resolve_density_grid <- function(scene, layer) {
  if (!is.null(layer$lod_name)) {
    if (!(layer$lod_name %in% names(scene$lod$items))) {
      cli::cli_abort("Unknown LOD bundle {.val {layer$lod_name}}.")
    }

    bundle <- scene$lod$items[[layer$lod_name]]
    level <- .or_default(layer$level, bundle$default_level)
    if (!(level %in% names(bundle$levels))) {
      cli::cli_abort("Unknown LOD level {.val {level}} for bundle {.val {layer$lod_name}}.")
    }
    return(bundle$levels[[level]])
  }

  point_view <- .scene_point_view(scene, embedding = layer$embedding)
  .density_grid(point_view, bins = layer$bins, color_by = layer$color_by)
}

.render_layer_points <- function(scene, layer) {
  point_view <- .scene_point_view(scene, embedding = layer$embedding)

  if (!(layer$color_by %in% names(point_view))) {
    cli::cli_abort(
      "Point layer requested unknown {.arg color_by} field {.val {layer$color_by}}."
    )
  }

  colors <- .map_colors(
    values = as.numeric(point_view[[layer$color_by]]),
    low_fill = layer$low_fill,
    mid_fill = layer$mid_fill,
    high_fill = layer$high_fill
  )

  rgl::points3d(
    x = point_view$x,
    y = point_view$y,
    z = point_view$z,
    color = colors,
    alpha = layer$alpha,
    size = layer$size
  )
}

.render_layer_density <- function(scene, layer) {
  grid <- .resolve_density_grid(scene, layer)
  colors <- matrix(
    .map_colors(as.vector(grid$z), layer$low_fill, layer$high_fill),
    nrow = nrow(grid$z),
    ncol = ncol(grid$z)
  )

  rgl::surface3d(
    x = grid$x,
    y = grid$y,
    z = matrix(0, nrow = length(grid$x), ncol = length(grid$y)),
    color = colors,
    alpha = layer$alpha,
    front = "fill",
    back = "fill"
  )
}

.open_rgl_device <- function(open) {
  if (isTRUE(open)) {
    rgl::open3d()
  } else {
    rgl::open3d(useNULL = TRUE)
  }
}

.draw_scene <- function(scene, lod_level = NULL, open = interactive()) {
  .validate_xgeo_scene(scene)

  if (!requireNamespace("rgl", quietly = TRUE)) {
    cli::cli_abort(
      "Package {.pkg rgl} is required for WebGL rendering."
    )
  }

  .open_rgl_device(open)
  rgl::clear3d(type = "all")
  rgl::bg3d(color = .or_default(scene$theme$background, "white"))

  for (layer in scene$layers) {
    render_layer <- .resolve_render_layer(scene, layer, lod_level = lod_level)
    render_xgeo_layer(render_layer, scene = scene)
  }

  .apply_camera(scene$camera)

  invisible(scene)
}

.build_rgl_widget <- function() {
  rgl::rglwidget()
}

.save_widget_html <- function(file, selfcontained = FALSE) {
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    return(NULL)
  }

  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  widget <- .build_rgl_widget()
  htmlwidgets::saveWidget(widget, file = file, selfcontained = selfcontained)
  normalizePath(file, winslash = "/", mustWork = FALSE)
}

.save_legacy_webgl <- function(file) {
  if (!exists("writeWebGL", where = asNamespace("rgl"), inherits = FALSE)) {
    return(NULL)
  }

  result <- tryCatch(
    rgl::writeWebGL(
      dir = { dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE); dirname(file) },
      filename = file,
      snapshot = FALSE
    ),
    error = function(e) e
  )

  if (inherits(result, "error")) {
    if (grepl("defunct", conditionMessage(result), ignore.case = TRUE)) {
      return(NULL)
    }

    cli::cli_warn(
      "Legacy {.fn rgl::writeWebGL} export failed: {conditionMessage(result)}"
    )
    return(NULL)
  }

  if (file.exists(file)) {
    return(normalizePath(file, winslash = "/", mustWork = FALSE))
  }

  NULL
}

.save_webgl_html <- function(file, selfcontained = FALSE) {
  html_path <- .save_widget_html(file, selfcontained = selfcontained)
  if (!is.null(html_path)) {
    return(html_path)
  }

  html_path <- .save_legacy_webgl(file)
  if (!is.null(html_path)) {
    return(html_path)
  }

  NULL
}

.try_snapshot3d <- function(file,
                            webshot = FALSE,
                            width = NULL,
                            height = NULL) {
  warning_message <- NULL
  error_message <- NULL

  withCallingHandlers(
    tryCatch(
      rgl::snapshot3d(
        filename = file,
        webshot = webshot,
        width = width,
        height = height
      ),
      error = function(e) {
        error_message <<- conditionMessage(e)
        NULL
      }
    ),
    warning = function(w) {
      warning_message <<- conditionMessage(w)
      invokeRestart("muffleWarning")
    }
  )

  if (file.exists(file)) {
    return(list(
      path = normalizePath(file, winslash = "/", mustWork = TRUE),
      message = warning_message
    ))
  }

  if (!is.null(error_message)) {
    return(list(path = NULL, message = error_message))
  }

  list(path = NULL, message = warning_message)
}

.write_placeholder_snapshot <- function(file, html_file = NULL) {
  grDevices::png(filename = file, width = 1200, height = 800)
  on.exit(grDevices::dev.off(), add = TRUE)

  graphics::par(mar = c(1, 1, 1, 1))
  graphics::plot.new()
  graphics::rect(0, 0, 1, 1, col = "white", border = NA)
  graphics::text(
    0.5, 0.62,
    labels = "Static snapshot unavailable in this rgl build.",
    cex = 1.5,
    font = 2
  )
  subtitle <- if (is.null(html_file)) {
    "Interactive WebGL export was not created."
  } else {
    paste("Interactive WebGL export written to", basename(html_file))
  }
  graphics::text(
    0.5, 0.46,
    labels = subtitle,
    cex = 1.1
  )
  graphics::text(
    0.5, 0.34,
    labels = "Use the HTML artifact for interactive review.",
    cex = 1
  )

  normalizePath(file, winslash = "/", mustWork = FALSE)
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
#' @param layer Layer object to render.
#' @param scene Parent scene.
#' @param ... Reserved for future extension methods.
#'
#' @return Invisibly returns `NULL`.
#' @export
render_xgeo_layer <- function(layer, scene, ...) {
  UseMethod("render_xgeo_layer", layer)
}

#' @export
render_xgeo_layer.default <- function(layer, scene, ...) {
  cli::cli_warn("Skipping unsupported layer class {.cls {class(layer)[[1]]}}.")
  invisible(NULL)
}

#' @export
render_xgeo_layer.xgeo_layer_surface <- function(layer, scene, ...) {
  .render_layer_surface(scene, layer)
  invisible(NULL)
}

#' @export
render_xgeo_layer.xgeo_layer_points <- function(layer, scene, ...) {
  .render_layer_points(scene, layer)
  invisible(NULL)
}

#' @export
render_xgeo_layer.xgeo_layer_density <- function(layer, scene, ...) {
  .render_layer_density(scene, layer)
  invisible(NULL)
}

.resolve_render_layer <- function(scene, layer, lod_level = NULL) {
  if (!inherits(layer, "xgeo_layer_points")) {
    return(layer)
  }

  if (is.null(lod_level)) {
    return(layer)
  }

  if (identical(lod_level, "auto")) {
    active <- scene$lod$active
    if (is.null(active$name) ||
        nrow(scene$data$points) <= scene$lod$auto$point_threshold) {
      return(layer)
    }

    bundle <- scene$lod$items[[active$name]]
    return(geom_xgeo_density(
      embedding = bundle$embedding,
      color_by = bundle$color_by,
      lod_name = active$name,
      level = active$level
    ))
  }

  active_name <- scene$lod$active$name
  if (is.null(active_name)) {
    cli::cli_abort("No active LOD bundle is configured on the scene.")
  }

  bundle <- scene$lod$items[[active_name]]
  geom_xgeo_density(
    embedding = bundle$embedding,
    color_by = bundle$color_by,
    lod_name = active_name,
    level = as.character(lod_level)
  )
}

#' Render an `xgeo_scene` to `rgl` / WebGL
#'
#' @param scene An `xgeo_scene` object.
#' @param lod_level Optional LOD selector. Use `"auto"` to switch point layers
#'   to the active density bundle when the point threshold is exceeded.
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
                         lod_level = NULL,
                         file = NULL,
                         selfcontained = FALSE,
                         open = interactive()) {
  .draw_scene(scene, lod_level = lod_level, open = open)

  if (is.null(file)) {
    if (requireNamespace("htmlwidgets", quietly = TRUE)) {
      return(.build_rgl_widget())
    }

    return(invisible(scene))
  }

  html_path <- .save_webgl_html(file, selfcontained = selfcontained)
  if (!is.null(html_path)) {
    return(invisible(html_path))
  }

  cli::cli_warn(
    paste(
      "No supported HTML export path is available.",
      "Install {.pkg htmlwidgets} for {.fn rgl::rglwidget} export;",
      "legacy {.fn rgl::writeWebGL} is unavailable in this {.pkg rgl} build."
    )
  )

  invisible(scene)
}

#' Save a static snapshot of an `xgeo_scene` when available
#'
#' @param scene An `xgeo_scene` object.
#' @param file Output PNG path.
#' @param lod_level Optional LOD selector passed to `render_webgl()`.
#' @param open Whether to open a visible device.
#' @param webshot Whether to allow `snapshot3d()` to use a webshot-based path.
#' @param selfcontained Passed to the HTML fallback export when used.
#' @param html_fallback Whether to also export an interactive HTML scene next to
#'   the PNG when static snapshots are unavailable.
#' @param placeholder Whether to create a placeholder PNG when no static
#'   snapshot backend is available.
#' @param width Optional snapshot width.
#' @param height Optional snapshot height.
#'
#' @return The normalized PNG path, invisibly.
#' @export
snapshot_webgl <- function(scene,
                           file,
                           lod_level = NULL,
                           open = FALSE,
                           webshot = FALSE,
                           selfcontained = FALSE,
                           html_fallback = TRUE,
                           placeholder = TRUE,
                           width = NULL,
                           height = NULL) {
  if (!.is_scalar_string(file)) {
    cli::cli_abort("{.arg file} must be a single file path.")
  }

  .draw_scene(scene, lod_level = lod_level, open = open)

  html_path <- NULL
  if (isTRUE(html_fallback)) {
    html_file <- paste0(tools::file_path_sans_ext(file), ".html")
    html_path <- .save_webgl_html(html_file, selfcontained = selfcontained)
  }

  snapshot_result <- .try_snapshot3d(
    file = file,
    webshot = webshot,
    width = width,
    height = height
  )

  if (!is.null(snapshot_result$path)) {
    return(invisible(snapshot_result$path))
  }

  message_text <- snapshot_result$message
  if (isTRUE(placeholder)) {
    cli::cli_warn(
      paste(
        "Static snapshot capture is unavailable",
        if (!is.null(message_text) && nzchar(message_text)) {
          paste0("(", message_text, ").")
        } else {
          "in this rgl build."
        },
        "Writing a placeholder PNG instead."
      )
    )
    return(invisible(.write_placeholder_snapshot(file, html_file = html_path)))
  }

  if (!is.null(html_path)) {
    cli::cli_warn(
      "Static snapshot capture is unavailable; interactive HTML export written to {.file {html_path}}."
    )
  }

  invisible(NULL)
}
