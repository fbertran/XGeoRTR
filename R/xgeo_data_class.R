#' Create a normalized `xgeo_data` object
#'
#' @param points Point table with `point_id`, `x`, `y`, and optional `z`.
#' @param explanations Explanation table with `point_id`, `feature`, and
#'   `value`.
#' @param point_meta Optional point-level metadata keyed by `point_id`.
#' @param feature_meta Optional feature-level metadata keyed by `feature`.
#' @param predictions Optional point-level predictions keyed by `point_id`.
#' @param uncertainty Optional point-level uncertainty keyed by `point_id`.
#' @param embeddings Optional embedding registry. Defaults to a backend spatial
#'   embedding derived from `points`.
#' @param diagnostics Optional diagnostics registry.
#' @param lod Optional level-of-detail registry.
#' @param selection Optional selection state.
#' @param baseline Optional numeric scalar reference value.
#' @param structure Structure name for the object. The current release supports
#'   only `"spatial"`.
#' @param method Method label for the explanations represented in the object.
#' @param meta Optional metadata list.
#'
#' @return An object of class `xgeo_data`.
#' @noRd
new_xgeo_data <- function(points,
                          explanations,
                          point_meta = NULL,
                          feature_meta = NULL,
                          predictions = NULL,
                          uncertainty = NULL,
                          embeddings = NULL,
                          diagnostics = NULL,
                          lod = NULL,
                          selection = NULL,
                          baseline = NULL,
                          structure = "spatial",
                          method = "generic",
                          meta = list()) {
  if (!(structure %in% .xgeo_supported_structures())) {
    cli::cli_abort(
      "Unsupported {.arg structure} {.val {structure}}. The current release supports only {.val spatial}."
    )
  }

  if (!is.null(baseline) && !.is_scalar_numeric(baseline)) {
    cli::cli_abort("{.arg baseline} must be NULL or a single numeric value.")
  }

  if (!.is_scalar_string(method)) {
    cli::cli_abort("{.arg method} must be a single string.")
  }

  if (!is.list(meta)) {
    cli::cli_abort("{.arg meta} must be a list.")
  }

  points_tbl <- .normalize_points(points)
  explanations_tbl <- .normalize_explanations(explanations, points_tbl$point_id)
  feature_meta_tbl <- .normalize_feature_meta(feature_meta, explanations_tbl)
  point_meta_tbl <- .normalize_point_level_table(point_meta, points_tbl$point_id, "point_meta")
  predictions_tbl <- .normalize_point_level_table(predictions, points_tbl$point_id, "predictions")
  uncertainty_tbl <- .normalize_point_level_table(uncertainty, points_tbl$point_id, "uncertainty")
  embeddings_state <- .normalize_xgeo_data_embeddings(
    embeddings,
    list(points = points_tbl)
  )
  diagnostics_state <- .normalize_xgeo_data_diagnostics(diagnostics)
  lod_state <- .normalize_xgeo_data_lod(lod)
  selection_state <- .normalize_xgeo_data_selection(
    selection,
    points_tbl$point_id,
    feature_meta_tbl$feature
  )

  out <- structure(
    list(
      points = points_tbl,
      explanations = explanations_tbl,
      point_meta = point_meta_tbl,
      feature_meta = feature_meta_tbl,
      predictions = predictions_tbl,
      uncertainty = uncertainty_tbl,
      embeddings = embeddings_state,
      diagnostics = diagnostics_state,
      lod = lod_state,
      selection = selection_state,
      baseline = baseline,
      structure = structure,
      method = method,
      meta = meta
    ),
    class = "xgeo_data"
  )

  validate_xgeo_data(out)
  out
}

#' Validate a `xgeo_data` object
#'
#' @param x An object to validate.
#'
#' @return `x`, invisibly, when validation succeeds.
#' @noRd
validate_xgeo_data <- function(x) {
  if (!inherits(x, "xgeo_data")) {
    cli::cli_abort("{.arg x} must inherit from {.cls xgeo_data}.")
  }

  renderer_fields <- intersect(
    c("layers", "views", "camera", "theme", "render_backend"),
    names(x)
  )
  if (length(renderer_fields) > 0L) {
    cli::cli_abort(
      "{.cls xgeo_data} objects must not contain renderer-specific fields {.val {renderer_fields}}."
    )
  }

  required_fields <- c(
    "points",
    "explanations",
    "point_meta",
    "feature_meta",
    "predictions",
    "uncertainty",
    "embeddings",
    "diagnostics",
    "lod",
    "selection",
    "baseline",
    "structure",
    "method",
    "meta"
  )

  missing_fields <- setdiff(required_fields, names(x))
  if (length(missing_fields) > 0L) {
    cli::cli_abort(
      "{.cls xgeo_data} objects must contain fields {.val {missing_fields}}."
    )
  }

  if (!(x$structure %in% .xgeo_supported_structures())) {
    cli::cli_abort(
      "{.cls xgeo_data} structure {.val {x$structure}} is not supported."
    )
  }

  if (!is.null(x$baseline) && !.is_scalar_numeric(x$baseline)) {
    cli::cli_abort("{.field baseline} must be NULL or a single numeric value.")
  }

  if (!.is_scalar_string(x$method)) {
    cli::cli_abort("{.field method} must be a single string.")
  }

  points_tbl <- .normalize_points(x$points)
  explanations_tbl <- .normalize_explanations(x$explanations, points_tbl$point_id)
  .normalize_point_level_table(x$point_meta, points_tbl$point_id, "point_meta")
  .normalize_point_level_table(x$predictions, points_tbl$point_id, "predictions")
  .normalize_point_level_table(x$uncertainty, points_tbl$point_id, "uncertainty")
  feature_meta_tbl <- .normalize_feature_meta(x$feature_meta, explanations_tbl)
  .normalize_xgeo_data_embeddings(x$embeddings, list(points = points_tbl))
  .normalize_xgeo_data_diagnostics(x$diagnostics)
  .normalize_xgeo_data_lod(x$lod)
  .normalize_xgeo_data_selection(
    x$selection,
    points_tbl$point_id,
    feature_meta_tbl$feature
  )

  if (!is.list(x$meta)) {
    cli::cli_abort("{.field meta} must be a list.")
  }

  invisible(x)
}

.normalize_xgeo_data_embeddings <- function(embeddings, data) {
  embeddings <- .normalize_embeddings(embeddings, data)
  known_point_ids <- data$points$point_id

  for (name in names(embeddings$items)) {
    item <- embeddings$items[[name]]
    coords <- .or_default(item$coords, NULL)

    if (is.null(coords)) {
      cli::cli_abort(
        "Embedding {.val {name}} must contain a {.field coords} data frame."
      )
    }

    coords <- .normalize_table(
      coords,
      "point_id",
      paste0("embeddings$items$", name, "$coords")
    )
    coords$point_id <- as.character(coords$point_id)

    if (anyNA(coords$point_id) || any(coords$point_id == "")) {
      cli::cli_abort(
        "Embedding {.val {name}} coordinates must not contain missing {.field point_id} values."
      )
    }

    if (anyDuplicated(coords$point_id)) {
      cli::cli_abort(
        "Embedding {.val {name}} coordinates must have unique {.field point_id} values."
      )
    }

    unknown_points <- setdiff(coords$point_id, known_point_ids)
    if (length(unknown_points) > 0L) {
      cli::cli_abort(
        "Embedding {.val {name}} coordinates contain unknown points {.val {unknown_points}}."
      )
    }
  }

  embeddings
}

.normalize_xgeo_data_diagnostics <- function(diagnostics) {
  .normalize_diagnostics(diagnostics)
}

.normalize_xgeo_data_lod <- function(lod) {
  .normalize_lod(lod)
}

.normalize_xgeo_data_selection <- function(selection, point_ids, features) {
  selection <- .normalize_selection(selection)

  unknown_points <- setdiff(selection$point_ids, point_ids)
  if (length(unknown_points) > 0L) {
    cli::cli_abort(
      "{.field selection$point_ids} contains unknown points {.val {unknown_points}}."
    )
  }

  unknown_features <- setdiff(selection$features, features)
  if (length(unknown_features) > 0L) {
    cli::cli_abort(
      "{.field selection$features} contains unknown features {.val {unknown_features}}."
    )
  }

  selection
}

#' @noRd
print.xgeo_data <- function(x, ...) {
  validate_xgeo_data(x)

  value_range <- range(x$explanations$value)
  cat(
    "<xgeo_data>\n",
    "  structure:    ", x$structure, "\n",
    "  method:       ", x$method, "\n",
    "  points:       ", nrow(x$points), "\n",
    "  explanations: ", nrow(x$explanations), "\n",
    "  features:     ", nrow(x$feature_meta), "\n",
    "  value range:  ", sprintf("[%.3f, %.3f]", value_range[[1]], value_range[[2]]), "\n",
    sep = ""
  )

  invisible(x)
}

#' @noRd
summary.xgeo_data <- function(object, ...) {
  validate_xgeo_data(object)

  out <- list(
    structure = object$structure,
    method = object$method,
    n_points = nrow(object$points),
    n_explanations = nrow(object$explanations),
    n_features = nrow(object$feature_meta),
    range = range(object$explanations$value),
    centroid = c(
      x = mean(object$points$x),
      y = mean(object$points$y),
      z = mean(object$points$z)
    ),
    baseline = object$baseline,
    meta_names = names(object$meta)
  )

  class(out) <- "summary.xgeo_data"
  out
}

#' @noRd
print.summary.xgeo_data <- function(x, ...) {
  cat(
    "<summary.xgeo_data>\n",
    "  structure:    ", x$structure, "\n",
    "  method:       ", x$method, "\n",
    "  points:       ", x$n_points, "\n",
    "  explanations: ", x$n_explanations, "\n",
    "  features:     ", x$n_features, "\n",
    "  range:        ", sprintf("[%.3f, %.3f]", x$range[[1]], x$range[[2]]), "\n",
    sep = ""
  )

  invisible(x)
}
