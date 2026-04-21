#' Coerce inputs to `xgeo_data`
#'
#' Methods auto-detect canonical spatial columns when possible and pass
#' backend state through to the resulting `xgeo_data`.
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
                                    embeddings = NULL,
                                    diagnostics = NULL,
                                    lod = NULL,
                                    selection = NULL,
                                    baseline = NULL,
                                    structure = "spatial",
                                    method = "generic",
                                    meta = list(),
                                    ...) {
  x_col_missing <- missing(x_col)
  y_col_missing <- missing(y_col)
  z_col_missing <- missing(z_col)
  feature_col_missing <- missing(feature_col)
  point_id_col_missing <- missing(point_id_col)

  if (x_col_missing && !("x" %in% names(x)) && "dim1" %in% names(x)) {
    x_col <- "dim1"
  }
  if (y_col_missing && !("y" %in% names(x)) && "dim2" %in% names(x)) {
    y_col <- "dim2"
  }
  if (z_col_missing) {
    if ("z" %in% names(x)) {
      z_col <- "z"
    } else if ("dim3" %in% names(x)) {
      z_col <- "dim3"
    }
  }
  if (feature_col_missing && "feature" %in% names(x)) {
    feature_col <- "feature"
  }
  if (point_id_col_missing && "point_id" %in% names(x)) {
    point_id_col <- "point_id"
  }

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
    embeddings = embeddings,
    diagnostics = diagnostics,
    lod = lod,
    selection = selection,
    baseline = baseline,
    structure = structure,
    method = method,
    meta = meta
  )
}

#' @export
as_xgeo_data.matrix <- function(x,
                                coordinates = NULL,
                                embeddings = NULL,
                                diagnostics = NULL,
                                lod = NULL,
                                selection = NULL,
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
      embeddings = embeddings,
      diagnostics = diagnostics,
      lod = lod,
      selection = selection,
      baseline = baseline,
      structure = structure,
      method = method,
      meta = meta
    ))
  }

  coordinates <- .normalize_matrix_coordinates(coordinates)

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
    embeddings = embeddings,
    diagnostics = diagnostics,
    lod = lod,
    selection = selection,
    baseline = baseline,
    structure = structure,
    method = method,
    meta = meta
  )
}

.normalize_matrix_coordinates <- function(coordinates) {
  coordinates <- .normalize_table(coordinates, name = "coordinates")

  if (all(c("x", "y") %in% names(coordinates))) {
    x_src <- "x"
    y_src <- "y"
  } else if (all(c("dim1", "dim2") %in% names(coordinates))) {
    x_src <- "dim1"
    y_src <- "dim2"
  } else {
    cli::cli_abort(
      "{.arg coordinates} must contain columns {.val {c('x', 'y')}} or {.val {c('dim1', 'dim2')}}."
    )
  }

  z_src <- if ("z" %in% names(coordinates)) {
    "z"
  } else if ("dim3" %in% names(coordinates)) {
    "dim3"
  } else {
    NULL
  }

  point_id <- if ("point_id" %in% names(coordinates)) {
    as.character(coordinates$point_id)
  } else {
    paste0("point_", seq_len(nrow(coordinates)))
  }

  mapped <- c("point_id", x_src, y_src, z_src)
  extra_cols <- setdiff(names(coordinates), mapped)

  out <- .empty_df(
    point_id = point_id,
    x = as.numeric(coordinates[[x_src]]),
    y = as.numeric(coordinates[[y_src]]),
    z = if (is.null(z_src)) rep(0, nrow(coordinates)) else as.numeric(coordinates[[z_src]])
  )

  if (length(extra_cols) > 0L) {
    out <- cbind(out, coordinates[, extra_cols, drop = FALSE])
  }

  out
}
