#' Create an `xgeo_scene`
#'
#' @param x A `xgeo_data` object or an object coercible to `xgeo_data`.
#' @param embeddings Optional embedding state.
#' @param diagnostics Optional diagnostic state.
#' @param lod Optional level-of-detail state.
#' @param views Optional named view registry.
#' @param selection Optional explicit selection state.
#' @param camera Named list of camera options. The MVP currently uses a `preset`
#'   entry such as `"isometric"`, `"top"`, or `"side"`.
#' @param theme Named list of theme options.
#' @param render_backend Rendering backend. The MVP supports only `"rgl"`.
#' @param meta Optional scene metadata.
#'
#' @return An `xgeo_scene` object.
#' @export
xgeo_scene <- function(x,
                       embeddings = NULL,
                       diagnostics = NULL,
                       lod = NULL,
                       views = NULL,
                       selection = NULL,
                       camera = list(preset = "isometric"),
                       theme = list(background = "white"),
                       render_backend = "rgl",
                       meta = list()) {
  if (!identical(render_backend, "rgl")) {
    cli::cli_abort(
      "Unsupported {.arg render_backend} {.val {render_backend}}. The current release supports only {.val rgl}."
    )
  }

  data <- as_xgeo_data(x)
  scene <- structure(
    list(
      data = data,
      layers = list(),
      embeddings = .normalize_embeddings(embeddings, data),
      diagnostics = .normalize_diagnostics(diagnostics),
      lod = .normalize_lod(lod),
      views = .normalize_views(views),
      selection = .normalize_selection(selection),
      camera = camera,
      theme = theme,
      render_backend = render_backend,
      meta = meta
    ),
    class = "xgeo_scene"
  )

  .validate_xgeo_scene(scene)
  scene
}

.validate_xgeo_scene <- function(x) {
  if (!inherits(x, "xgeo_scene")) {
    cli::cli_abort("{.arg x} must inherit from {.cls xgeo_scene}.")
  }

  required_fields <- c(
    "data",
    "layers",
    "embeddings",
    "diagnostics",
    "lod",
    "views",
    "selection",
    "camera",
    "theme",
    "render_backend",
    "meta"
  )
  missing_fields <- setdiff(required_fields, names(x))
  if (length(missing_fields) > 0L) {
    cli::cli_abort(
      "{.cls xgeo_scene} objects must contain fields {.val {missing_fields}}."
    )
  }

  validate_xgeo_data(x$data)

  if (!is.list(x$layers)) {
    cli::cli_abort("{.field layers} must be a list.")
  }

  if (!identical(x$render_backend, "rgl")) {
    cli::cli_abort("{.field render_backend} must currently be {.val rgl}.")
  }

  .normalize_embeddings(x$embeddings, x$data)
  .normalize_diagnostics(x$diagnostics)
  .normalize_lod(x$lod)
  .normalize_views(x$views)
  .normalize_selection(x$selection)

  invisible(x)
}

#' @export
print.xgeo_scene <- function(x, ...) {
  .validate_xgeo_scene(x)

  cat(
    "<xgeo_scene>\n",
    "  backend:      ", x$render_backend, "\n",
    "  layers:       ", length(x$layers), "\n",
    "  embeddings:   ", length(x$embeddings$items), " (active: ", x$embeddings$active, ")\n",
    "  diagnostics:  ", length(x$diagnostics$items), "\n",
    "  lod bundles:  ", length(x$lod$items), "\n",
    "  camera:       ", .or_default(x$camera$preset, "isometric"), "\n",
    sep = ""
  )

  invisible(x)
}

#' @export
`+.xgeo_scene` <- function(e1, e2) {
  .validate_xgeo_scene(e1)

  if (!inherits(e2, "xgeo_layer")) {
    cli::cli_abort("Right-hand side of {.code +} must be an xgeo layer.")
  }

  e1$layers <- c(e1$layers, list(e2))
  e1
}
