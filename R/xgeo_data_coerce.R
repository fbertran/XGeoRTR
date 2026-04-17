#' Coerce inputs to `xgeo_data`
#'
#' @param x An object to coerce.
#' @param ... Passed to method-specific implementations.
#'
#' @return A `xgeo_data` object.
#' @export
as_xgeo_data <- function(x, ...) {
  UseMethod("as_xgeo_data")
}

#' @export
as_xgeo_data.xgeo_data <- function(x, ...) {
  validate_xgeo_data(x)
  x
}

#' @export
as_xgeo_data.data.frame <- function(x,
                                    value_col = "value",
                                    x_col = "x",
                                    y_col = "y",
                                    z_col = NULL,
                                    feature_col = NULL,
                                    point_id_col = NULL,
                                    baseline = NULL,
                                    structure = "spatial",
                                    method = "generic",
                                    meta = list(),
                                    ...) {
  tables <- .coerce_spatial_long_table(
    x = x,
    value_col = value_col,
    x_col = x_col,
    y_col = y_col,
    z_col = z_col,
    feature_col = feature_col,
    point_id_col = point_id_col
  )

  new_xgeo_data(
    points = tables$points,
    explanations = tables$explanations,
    point_meta = tables$point_meta,
    baseline = baseline,
    structure = structure,
    method = method,
    meta = meta
  )
}

#' @export
as_xgeo_data.matrix <- function(x,
                                coordinates = NULL,
                                baseline = NULL,
                                structure = "spatial",
                                method = "generic",
                                meta = list(),
                                ...) {
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg x} must be a numeric matrix.")
  }

  if (is.null(coordinates)) {
    grid <- expand.grid(
      x = seq_len(nrow(x)),
      y = seq_len(ncol(x))
    )
    points <- .empty_df(
      point_id = paste0("point_", seq_len(nrow(grid))),
      x = grid$x,
      y = grid$y,
      z = 0
    )
    explanations <- .empty_df(
      point_id = points$point_id,
      feature = "value",
      value = as.vector(x)
    )

    return(new_xgeo_data(
      points = points,
      explanations = explanations,
      baseline = baseline,
      structure = structure,
      method = method,
      meta = meta
    ))
  }

  coordinates <- .normalize_table(coordinates, c("x", "y"), "coordinates")
  if (!("z" %in% names(coordinates))) {
    coordinates$z <- 0
  }

  if (!("point_id" %in% names(coordinates))) {
    coordinates$point_id <- paste0("point_", seq_len(nrow(coordinates)))
  }

  values_vec <- as.vector(x)
  if (nrow(coordinates) != length(values_vec)) {
    cli::cli_abort(
      "{.arg coordinates} must have the same number of rows as {.arg x} has elements."
    )
  }

  points <- coordinates[, c("point_id", "x", "y", "z"), drop = FALSE]
  point_meta <- coordinates[, setdiff(names(coordinates), c("x", "y", "z")), drop = FALSE]
  explanations <- .empty_df(
    point_id = as.character(points$point_id),
    feature = "value",
    value = values_vec
  )

  new_xgeo_data(
    points = points,
    explanations = explanations,
    point_meta = point_meta,
    baseline = baseline,
    structure = structure,
    method = method,
    meta = meta
  )
}
