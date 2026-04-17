#' Create a `xgeo_data` object
#'
#' @param values A numeric vector, numeric matrix, or data frame containing
#'   precomputed explanation values.
#' @param coordinates Optional coordinate table with `x`, `y`, and optional `z`
#'   columns when `values` is numeric.
#' @param features Optional feature metadata table with at least a `feature`
#'   column.
#' @param baseline Optional numeric scalar reference value.
#' @param structure Structure name for the object. The MVP currently supports
#'   only `"spatial"`.
#' @param method Method label for the explanations represented in the object.
#' @param meta Optional metadata list.
#'
#' @return An object of class `xgeo_data`.
#' @export
new_xgeo_data <- function(values,
                          coordinates = NULL,
                          features = NULL,
                          baseline = NULL,
                          structure = "spatial",
                          method = "generic",
                          meta = list()) {
  if (!(structure %in% .xgeo_supported_structures())) {
    cli::cli_abort(
      "Unsupported {.arg structure} {.val {structure}}. The MVP currently supports only {.val spatial}."
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

  data <- .coerce_spatial_table(values = values, coordinates = coordinates)
  features_tbl <- .coerce_feature_table(features, data)

  out <- structure(
    list(
      values = data$value,
      coordinates = data[, c("x", "y", "z"), drop = FALSE],
      features = features_tbl,
      baseline = baseline,
      structure = structure,
      method = method,
      meta = meta,
      data = data
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
    "values",
    "coordinates",
    "features",
    "baseline",
    "structure",
    "method",
    "meta",
    "data"
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

  if (!is.data.frame(x$data)) {
    cli::cli_abort("{.field data} must be a data frame.")
  }

  .assert_required_columns(x$data, c("feature", "x", "y", "z", "value"))

  numeric_cols <- c("x", "y", "z", "value")
  for (col in numeric_cols) {
    if (!is.numeric(x$data[[col]])) {
      cli::cli_abort("{.field data${col}} must be numeric.")
    }
  }

  if (nrow(x$coordinates) != nrow(x$data)) {
    cli::cli_abort(
      "{.field coordinates} must have the same number of rows as {.field data}."
    )
  }

  if (length(x$values) != nrow(x$data)) {
    cli::cli_abort(
      "{.field values} must have the same number of elements as rows in {.field data}."
    )
  }

  if (!is.data.frame(x$features)) {
    cli::cli_abort("{.field features} must be a data frame.")
  }

  if (!("feature" %in% names(x$features))) {
    cli::cli_abort("{.field features} must contain a {.field feature} column.")
  }

  if (!is.list(x$meta)) {
    cli::cli_abort("{.field meta} must be a list.")
  }

  invisible(x)
}

#' @export
print.xgeo_data <- function(x, ...) {
  validate_xgeo_data(x)

  value_range <- range(x$data$value)
  cat(
    "<xgeo_data>
",
    "  structure: ", x$structure, "
",
    "  method:    ", x$method, "
",
    "  locations: ", nrow(x$data), "
",
    "  features:  ", nrow(x$features), "
",
    "  value range:", sprintf("[%.3f, %.3f]", value_range[[1]], value_range[[2]]), "
",
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
    n_points = nrow(object$data),
    n_features = nrow(object$features),
    range = range(object$data$value),
    centroid = c(
      x = mean(object$data$x),
      y = mean(object$data$y),
      z = mean(object$data$z)
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
    "<summary.xgeo_data>
",
    "  structure: ", x$structure, "
",
    "  method:    ", x$method, "
",
    "  points:    ", x$n_points, "
",
    "  features:  ", x$n_features, "
",
    "  range:     ", sprintf("[%.3f, %.3f]", x$range[[1]], x$range[[2]]), "
",
    sep = ""
  )

  invisible(x)
}
