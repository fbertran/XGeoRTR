#' Build a long explanation table from backend state
#'
#' `xgeo_explanation_table()` exposes the selected explanation records together
#' with point coordinates and metadata. It is renderer-agnostic and contains no
#' use-case-specific presentation semantics.
#'
#' @param state An `xgeo_state` object.
#' @param selected Whether to apply the state's point and feature selection.
#'
#' @return A data frame containing `point_id`, `feature`, `value`, `x`, `y`,
#'   `z`, and any point-, feature-, prediction-, or uncertainty-level metadata.
#'
#' @examples
#' state <- as_xgeo_state(
#'   data.frame(
#'     point_id = c("p1", "p1", "p2"),
#'     feature = c("f1", "f2", "f1"),
#'     x = c(0, 0, 1),
#'     y = c(0, 0, 1),
#'     value = c(1, -0.5, 0.75),
#'     cluster = c("A", "A", "B")
#'   ),
#'   point_id_col = "point_id",
#'   feature_col = "feature"
#' )
#'
#' xgeo_explanation_table(state)
#' @export
xgeo_explanation_table <- function(state, selected = TRUE) {
  validate_xgeo_state(state)
  .validate_selected_flag(selected)

  data <- .selected_xgeo_state_data(state, selected = selected)

  out <- merge(
    data$explanations,
    data$points[, c("point_id", "x", "y", "z"), drop = FALSE],
    by = "point_id",
    all.x = TRUE,
    sort = FALSE
  )
  out <- .merge_xgeo_metadata(out, data$feature_meta, by = "feature", suffix = ".feature")
  out <- .merge_xgeo_metadata(out, data$point_meta, by = "point_id", suffix = ".point_meta")
  out <- .merge_xgeo_metadata(out, data$predictions, by = "point_id", suffix = ".prediction")
  out <- .merge_xgeo_metadata(out, data$uncertainty, by = "point_id", suffix = ".uncertainty")

  rownames(out) <- NULL
  out
}

#' Aggregate explanation values per point
#'
#' `xgeo_point_values()` exposes a selected, renderer-neutral point table with
#' coordinates, aggregated explanation values, and point-level metadata.
#'
#' @param state An `xgeo_state` object.
#' @param aggregate Aggregation function applied across selected features per
#'   point. Defaults to `sum`.
#' @param selected Whether to apply the state's point and feature selection.
#'
#' @return A data frame containing `point_id`, `x`, `y`, `z`, `value`, and any
#'   point-, prediction-, or uncertainty-level metadata.
#'
#' @examples
#' state <- as_xgeo_state(
#'   data.frame(
#'     point_id = c("p1", "p1", "p2", "p2"),
#'     feature = c("f1", "f2", "f1", "f2"),
#'     x = c(0, 0, 1, 1),
#'     y = c(0, 0, 1, 1),
#'     value = c(1, -0.25, 0.75, 2),
#'     cluster = c("A", "A", "B", "B")
#'   ),
#'   point_id_col = "point_id",
#'   feature_col = "feature"
#' )
#' state <- set_xgeo_selection(state, features = "f1")
#'
#' xgeo_point_values(state)
#' @export
xgeo_point_values <- function(state, aggregate = sum, selected = TRUE) {
  validate_xgeo_state(state)
  if (!is.function(aggregate)) {
    cli::cli_abort("{.arg aggregate} must be a function.")
  }
  .validate_selected_flag(selected)

  data <- .selected_xgeo_state_data(state, selected = selected)
  out <- .point_value_table(data, fun = aggregate)
  out <- .merge_xgeo_metadata(out, data$point_meta, by = "point_id", suffix = ".point_meta")
  out <- .merge_xgeo_metadata(out, data$predictions, by = "point_id", suffix = ".prediction")
  out <- .merge_xgeo_metadata(out, data$uncertainty, by = "point_id", suffix = ".uncertainty")

  rownames(out) <- NULL
  out
}

#' Validate and normalize regular-grid data
#'
#' `xgeo_regular_grid()` validates a complete 2D regular grid and returns the
#' grid vectors and value matrix without creating a renderer-specific object.
#'
#' @param data A data frame containing x, y, and value columns.
#' @param x Name of the x-coordinate column.
#' @param y Name of the y-coordinate column.
#' @param value Name of the value column.
#'
#' @return A list with `x`, `y`, and `z`, where `z` is a value matrix indexed by
#'   the returned x and y coordinates.
#'
#' @examples
#' xgeo_regular_grid(
#'   data.frame(
#'     x_coord = c(0, 1, 0, 1),
#'     y_coord = c(0, 0, 1, 1),
#'     score = c(1, 2, 3, 4)
#'   ),
#'   x = "x_coord",
#'   y = "y_coord",
#'   value = "score"
#' )
#' @export
xgeo_regular_grid <- function(data, x = "x", y = "y", value = "value") {
  if (!.is_scalar_string(x) || !.is_scalar_string(y) || !.is_scalar_string(value)) {
    cli::cli_abort("{.arg x}, {.arg y}, and {.arg value} must be column names.")
  }
  data <- .normalize_table(data, c(x, y, value), "data")

  grid_data <- .empty_df(
    x = as.numeric(data[[x]]),
    y = as.numeric(data[[y]]),
    value = as.numeric(data[[value]])
  )
  if (anyNA(grid_data$x) || anyNA(grid_data$y) || anyNA(grid_data$value)) {
    cli::cli_abort("Grid coordinates and values must be numeric and non-missing.")
  }

  .regular_grid_from_long(grid_data)
}
