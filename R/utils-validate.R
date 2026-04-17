.assert_required_columns <- function(data, required, arg = "data") {
  missing_cols <- setdiff(required, names(data))

  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "{.arg {arg}} must contain columns {.val {missing_cols}}."
    )
  }

  invisible(data)
}

.coerce_feature_table <- function(features, data) {
  if (is.null(features)) {
    feature_levels <- unique(as.character(data$feature))
    return(
      data.frame(
        feature = feature_levels,
        label = feature_levels,
        stringsAsFactors = FALSE
      )
    )
  }

  if (!is.data.frame(features)) {
    cli::cli_abort("{.arg features} must be NULL or a data frame.")
  }

  if (!("feature" %in% names(features))) {
    cli::cli_abort("{.arg features} must contain a {.field feature} column.")
  }

  features
}

.coerce_spatial_table <- function(values, coordinates = NULL) {
  if (is.data.frame(values)) {
    .assert_required_columns(values, c("x", "y", "value"))

    data <- values
    if (!("feature" %in% names(data))) {
      data$feature <- paste0("feature_", seq_len(nrow(data)))
    }
    if (!("z" %in% names(data))) {
      data$z <- 0
    }

    return(
      data[, c("feature", "x", "y", "z", "value"), drop = FALSE]
    )
  }

  if (!is.numeric(values)) {
    cli::cli_abort(
      "{.arg values} must be a numeric vector/matrix or a data frame."
    )
  }

  if (is.null(coordinates)) {
    cli::cli_abort(
      "{.arg coordinates} is required when {.arg values} is numeric."
    )
  }

  if (!is.data.frame(coordinates)) {
    cli::cli_abort("{.arg coordinates} must be a data frame.")
  }

  .assert_required_columns(coordinates, c("x", "y"), arg = "coordinates")

  values_vec <- as.vector(values)

  if (nrow(coordinates) != length(values_vec)) {
    cli::cli_abort(
      "{.arg coordinates} must have the same number of rows as {.arg values} has elements."
    )
  }

  data <- coordinates
  if (!("z" %in% names(data))) {
    data$z <- 0
  }

  if (!("feature" %in% names(data))) {
    data$feature <- paste0("feature_", seq_len(nrow(data)))
  }

  data$value <- values_vec
  data[, c("feature", "x", "y", "z", "value"), drop = FALSE]
}

.regular_grid_from_long <- function(data) {
  grid_x <- sort(unique(data$x))
  grid_y <- sort(unique(data$y))

  if (nrow(data) != length(grid_x) * length(grid_y)) {
    cli::cli_abort(
      "A surface view requires a complete regular grid over {.field x} and {.field y}."
    )
  }

  z <- matrix(NA_real_, nrow = length(grid_x), ncol = length(grid_y))

  for (i in seq_len(nrow(data))) {
    ix <- match(data$x[[i]], grid_x)
    iy <- match(data$y[[i]], grid_y)

    if (!is.na(z[ix, iy])) {
      cli::cli_abort(
        "A surface view requires unique {.field x}/{.field y} pairs."
      )
    }

    z[ix, iy] <- data$value[[i]]
  }

  if (anyNA(z)) {
    cli::cli_abort(
      "A surface view requires a value for every {.field x}/{.field y} pair."
    )
  }

  list(x = grid_x, y = grid_y, z = z)
}

.smooth_matrix <- function(z) {
  out <- z
  nr <- nrow(z)
  nc <- ncol(z)

  for (i in seq_len(nr)) {
    for (j in seq_len(nc)) {
      rows <- max(1L, i - 1L):min(nr, i + 1L)
      cols <- max(1L, j - 1L):min(nc, j + 1L)
      out[i, j] <- mean(z[rows, cols])
    }
  }

  out
}
