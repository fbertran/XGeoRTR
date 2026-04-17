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
                                    baseline = NULL,
                                    structure = "spatial",
                                    method = "generic",
                                    meta = list(),
                                    ...) {
  required_cols <- c(value_col, x_col, y_col)
  if (!is.null(z_col)) {
    required_cols <- c(required_cols, z_col)
  }
  if (!is.null(feature_col)) {
    required_cols <- c(required_cols, feature_col)
  }
  .assert_required_columns(x, required_cols)

  data <- data.frame(
    feature = if (is.null(feature_col)) {
      paste0("feature_", seq_len(nrow(x)))
    } else {
      as.character(x[[feature_col]])
    },
    x = as.numeric(x[[x_col]]),
    y = as.numeric(x[[y_col]]),
    z = if (is.null(z_col)) {
      rep(0, nrow(x))
    } else {
      as.numeric(x[[z_col]])
    },
    value = as.numeric(x[[value_col]]),
    stringsAsFactors = FALSE
  )

  new_xgeo_data(
    values = data,
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
    data <- data.frame(
      feature = paste0("cell_", seq_len(nrow(grid))),
      x = grid$x,
      y = grid$y,
      z = 0,
      value = as.vector(x),
      stringsAsFactors = FALSE
    )

    return(
      new_xgeo_data(
        values = data,
        baseline = baseline,
        structure = structure,
        method = method,
        meta = meta
      )
    )
  }

  new_xgeo_data(
    values = as.vector(x),
    coordinates = coordinates,
    baseline = baseline,
    structure = structure,
    method = method,
    meta = meta
  )
}
