#' Create a normalized `xgeo_data` object
#'
#' @param points Point table with `point_id`, `x`, `y`, and optional `z`.
#' @param explanations Explanation table with `point_id`, `feature`, and
#'   `value`.
#' @param point_meta Optional point-level metadata keyed by `point_id`.
#' @param feature_meta Optional feature-level metadata keyed by `feature`.
#' @param predictions Optional point-level predictions keyed by `point_id`.
#' @param uncertainty Optional point-level uncertainty keyed by `point_id`.
#' @param baseline Optional numeric scalar reference value.
#' @param structure Structure name for the object. The current release supports
#'   only `"spatial"`.
#' @param method Method label for the explanations represented in the object.
#' @param meta Optional metadata list.
#'
#' @return An object of class `xgeo_data`.
#' @export
new_xgeo_data <- function(points,
                          explanations,
                          point_meta = NULL,
                          feature_meta = NULL,
                          predictions = NULL,
                          uncertainty = NULL,
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

  out <- structure(
    list(
      points = points_tbl,
      explanations = explanations_tbl,
      point_meta = point_meta_tbl,
      feature_meta = feature_meta_tbl,
      predictions = predictions_tbl,
      uncertainty = uncertainty_tbl,
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
#' @export
validate_xgeo_data <- function(x) {
  if (!inherits(x, "xgeo_data")) {
    cli::cli_abort("{.arg x} must inherit from {.cls xgeo_data}.")
  }

  required_fields <- c(
    "points",
    "explanations",
    "point_meta",
    "feature_meta",
    "predictions",
    "uncertainty",
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

  if (!.is_scalar_string(x$method)) {
    cli::cli_abort("{.field method} must be a single string.")
  }

  .normalize_points(x$points)
  .normalize_explanations(x$explanations, x$points$point_id)
  .normalize_point_level_table(x$point_meta, x$points$point_id, "point_meta")
  .normalize_point_level_table(x$predictions, x$points$point_id, "predictions")
  .normalize_point_level_table(x$uncertainty, x$points$point_id, "uncertainty")
  .normalize_feature_meta(x$feature_meta, x$explanations)

  if (!is.list(x$meta)) {
    cli::cli_abort("{.field meta} must be a list.")
  }

  invisible(x)
}

#' @export
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

#' @export
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

#' @export
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
