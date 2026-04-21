.regular_grid_from_long <- function(data) {
  grid_x <- sort(unique(data$x))
  grid_y <- sort(unique(data$y))

  if (nrow(data) != length(grid_x) * length(grid_y)) {
    cli::cli_abort(
      "Regular-grid data must contain every {.field x}/{.field y} coordinate combination."
    )
  }

  z <- matrix(NA_real_, nrow = length(grid_x), ncol = length(grid_y))

  for (i in seq_len(nrow(data))) {
    ix <- match(data$x[[i]], grid_x)
    iy <- match(data$y[[i]], grid_y)

    if (!is.na(z[ix, iy])) {
      cli::cli_abort(
        "Regular-grid data must contain unique {.field x}/{.field y} coordinate pairs."
      )
    }

    z[ix, iy] <- data$value[[i]]
  }

  if (anyNA(z)) {
    cli::cli_abort(
      "Regular-grid data must contain a value for every {.field x}/{.field y} coordinate pair."
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

.density_grid <- function(data, bins = 32L, color_by = c("count", "mean_value")) {
  color_by <- match.arg(color_by)

  if (!.is_count(bins)) {
    cli::cli_abort("{.arg bins} must be a positive whole number.")
  }

  x_range <- range(data$x)
  y_range <- range(data$y)
  if (diff(x_range) == 0) {
    x_range <- x_range + c(-0.5, 0.5)
  }
  if (diff(y_range) == 0) {
    y_range <- y_range + c(-0.5, 0.5)
  }

  x_breaks <- seq(x_range[[1]], x_range[[2]], length.out = bins + 1L)
  y_breaks <- seq(y_range[[1]], y_range[[2]], length.out = bins + 1L)

  x_bin <- cut(data$x, breaks = x_breaks, include.lowest = TRUE, labels = FALSE)
  y_bin <- cut(data$y, breaks = y_breaks, include.lowest = TRUE, labels = FALSE)

  stats <- matrix(NA_real_, nrow = bins, ncol = bins)
  counts <- matrix(0, nrow = bins, ncol = bins)

  for (i in seq_len(nrow(data))) {
    xi <- x_bin[[i]]
    yi <- y_bin[[i]]
    if (is.na(xi) || is.na(yi)) {
      next
    }

    counts[xi, yi] <- counts[xi, yi] + 1L
    if (identical(color_by, "count")) {
      stats[xi, yi] <- counts[xi, yi]
    } else {
      cell_values <- data$value[x_bin == xi & y_bin == yi]
      stats[xi, yi] <- mean(cell_values)
    }
  }

  stats[is.na(stats)] <- 0

  list(
    x = utils::head(x_breaks, -1),
    y = utils::head(y_breaks, -1),
    z = stats,
    counts = counts,
    color_by = color_by
  )
}
