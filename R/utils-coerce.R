.point_signature <- function(df) {
  if (nrow(df) == 0L) {
    return(character())
  }

  apply(df, 1, function(row) paste(ifelse(is.na(row), "<NA>", row), collapse = "\r"))
}

.dedupe_point_rows <- function(point_rows) {
  if (!("point_id" %in% names(point_rows))) {
    cli::cli_abort("Internal error: point rows must include {.field point_id}.")
  }

  signatures <- .point_signature(point_rows[, setdiff(names(point_rows), "point_id"), drop = FALSE])
  point_rows$.signature <- signatures

  unique_ids <- unique(point_rows$point_id)
  for (point_id in unique_ids) {
    subset_rows <- point_rows[point_rows$point_id == point_id, , drop = FALSE]
    if (length(unique(subset_rows$.signature)) > 1L) {
      cli::cli_abort(
        "Repeated {.field point_id} {.val {point_id}} carries conflicting point-level metadata."
      )
    }
  }

  out <- point_rows[!duplicated(point_rows$point_id), setdiff(names(point_rows), ".signature"), drop = FALSE]
  rownames(out) <- NULL
  out
}

.make_point_ids_from_coordinates <- function(x, x_col, y_col, z_col) {
  z_values <- if (is.null(z_col)) rep(0, nrow(x)) else x[[z_col]]
  keys <- paste(x[[x_col]], x[[y_col]], z_values, sep = "::")
  match(keys, unique(keys))
}

.coerce_spatial_long_table <- function(x,
                                       value_col,
                                       x_col,
                                       y_col,
                                       z_col = NULL,
                                       feature_col = NULL,
                                       point_id_col = NULL) {
  required_cols <- c(value_col, x_col, y_col)
  if (!is.null(z_col)) {
    required_cols <- c(required_cols, z_col)
  }
  if (!is.null(feature_col)) {
    required_cols <- c(required_cols, feature_col)
  }
  if (!is.null(point_id_col)) {
    required_cols <- c(required_cols, point_id_col)
  }
  .assert_required_columns(x, required_cols)

  point_id <- if (is.null(point_id_col)) {
    paste0("point_", .make_point_ids_from_coordinates(x, x_col, y_col, z_col))
  } else {
    as.character(x[[point_id_col]])
  }

  feature <- if (is.null(feature_col)) {
    rep("value", nrow(x))
  } else {
    as.character(x[[feature_col]])
  }

  z_value <- if (is.null(z_col)) {
    rep(0, nrow(x))
  } else {
    as.numeric(x[[z_col]])
  }

  mapped <- unique(c(value_col, x_col, y_col, z_col, feature_col, point_id_col))
  extra_cols <- setdiff(names(x), mapped)

  point_rows <- .empty_df(
    point_id = point_id,
    x = as.numeric(x[[x_col]]),
    y = as.numeric(x[[y_col]]),
    z = z_value
  )

  if (length(extra_cols) > 0L) {
    point_rows <- cbind(point_rows, x[, extra_cols, drop = FALSE])
  }

  points_wide <- .dedupe_point_rows(point_rows)

  points <- points_wide[, c("point_id", "x", "y", "z"), drop = FALSE]
  point_meta <- points_wide[, setdiff(names(points_wide), c("x", "y", "z")), drop = FALSE]

  explanations <- .empty_df(
    point_id = point_id,
    feature = feature,
    value = as.numeric(x[[value_col]])
  )

  list(
    points = points,
    explanations = explanations,
    point_meta = point_meta
  )
}
