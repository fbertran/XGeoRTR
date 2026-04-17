#' Create an `xgeo_scene`
#'
#' @param x A `xgeo_data` object or an object coercible to `xgeo_data`.
#' @param camera Named list of camera options. The MVP currently uses a `preset`
#'   entry such as `"isometric"`, `"top"`, or `"side"`.
#' @param theme Named list of theme options.
#' @param render_backend Rendering backend. The MVP supports only `"rgl"`.
#'
#' @return An `xgeo_scene` object.
#' @export
xgeo_scene <- function(x,
                       camera = list(preset = "isometric"),
                       theme = list(background = "white"),
                       render_backend = "rgl") {
  if (!identical(render_backend, "rgl")) {
    cli::cli_abort(
      "Unsupported {.arg render_backend} {.val {render_backend}}. The MVP currently supports only {.val rgl}."
    )
  }

  structure(
    list(
      data = as_xgeo_data(x),
      layers = list(),
      camera = camera,
      theme = theme,
      render_backend = render_backend,
      animation = NULL
    ),
    class = "xgeo_scene"
  )
}

#' @export
print.xgeo_scene <- function(x, ...) {
  cat(
    "<xgeo_scene>
",
    "  backend: ", x$render_backend, "
",
    "  layers:  ", length(x$layers), "
",
    "  camera:  ", .or_default(x$camera$preset, "isometric"), "
",
    sep = ""
  )

  if (!is.null(x$animation)) {
    cat(
      "  animation: ",
      x$animation$frames,
      " frames around ",
      x$animation$axis,
      "
",
      sep = ""
    )
  }

  invisible(x)
}

#' @export
`+.xgeo_scene` <- function(e1, e2) {
  if (!inherits(e1, "xgeo_scene")) {
    cli::cli_abort("Left-hand side of {.code +} must be a {.cls xgeo_scene}.")
  }

  if (!inherits(e2, "xgeo_layer")) {
    cli::cli_abort("Right-hand side of {.code +} must be an xgeo layer.")
  }

  e1$layers <- c(e1$layers, list(e2))
  e1
}
