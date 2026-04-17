.assert_required_columns <- function(data, required, arg = "data") {
  missing_cols <- setdiff(required, names(data))

  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "{.arg {arg}} must contain columns {.val {missing_cols}}."
    )
  }

  invisible(data)
}

.ensure_data_frame <- function(x, columns, name) {
  if (is.null(x)) {
    return(.empty_df())
  }

  x <- .normalize_table(x, name = name)
  missing_cols <- setdiff(columns, names(x))
  for (col in missing_cols) {
    x[[col]] <- NA
  }
  x[, unique(c(columns, names(x))), drop = FALSE]
}

.normalize_points <- function(points) {
  points <- .normalize_table(points, c("point_id", "x", "y"), "points")

  if (!("z" %in% names(points))) {
    points$z <- 0
  }

  points$point_id <- as.character(points$point_id)
  points$x <- as.numeric(points$x)
  points$y <- as.numeric(points$y)
  points$z <- as.numeric(points$z)

  if (anyNA(points$point_id) || any(points$point_id == "")) {
    cli::cli_abort("{.field points$point_id} must not contain missing values.")
  }

  if (anyDuplicated(points$point_id)) {
    cli::cli_abort("{.field points$point_id} must be unique.")
  }

  if (anyNA(points$x) || anyNA(points$y) || anyNA(points$z)) {
    cli::cli_abort("Point coordinates must be numeric and non-missing.")
  }

  points <- points[, unique(c("point_id", "x", "y", "z", names(points))), drop = FALSE]
  rownames(points) <- NULL
  points
}

.normalize_explanations <- function(explanations, point_ids) {
  explanations <- .normalize_table(
    explanations,
    c("point_id", "feature", "value"),
    "explanations"
  )

  explanations$point_id <- as.character(explanations$point_id)
  explanations$feature <- as.character(explanations$feature)
  explanations$value <- as.numeric(explanations$value)

  if (anyNA(explanations$point_id) || any(explanations$point_id == "")) {
    cli::cli_abort("{.field explanations$point_id} must not contain missing values.")
  }

  if (anyNA(explanations$feature) || any(explanations$feature == "")) {
    cli::cli_abort("{.field explanations$feature} must not contain missing values.")
  }

  if (anyNA(explanations$value)) {
    cli::cli_abort("{.field explanations$value} must be numeric and non-missing.")
  }

  missing_points <- setdiff(unique(explanations$point_id), point_ids)
  if (length(missing_points) > 0L) {
    cli::cli_abort(
      "{.field explanations$point_id} contains unknown points {.val {missing_points}}."
    )
  }

  key <- paste(explanations$point_id, explanations$feature, sep = "::")
  if (anyDuplicated(key)) {
    cli::cli_abort(
      "Each {.field point_id}/{.field feature} pair must be unique in {.arg explanations}."
    )
  }

  rownames(explanations) <- NULL
  explanations
}

.normalize_feature_meta <- function(feature_meta, explanations) {
  feature_levels <- unique(as.character(explanations$feature))

  if (is.null(feature_meta)) {
    return(
      .empty_df(
        feature = feature_levels,
        label = feature_levels
      )
    )
  }

  feature_meta <- .normalize_table(feature_meta, "feature", "feature_meta")
  feature_meta$feature <- as.character(feature_meta$feature)

  missing_features <- setdiff(feature_levels, feature_meta$feature)
  if (length(missing_features) > 0L) {
    feature_meta <- rbind(
      feature_meta,
      .empty_df(feature = missing_features, label = missing_features)
    )
  }

  feature_meta <- feature_meta[!duplicated(feature_meta$feature), , drop = FALSE]
  rownames(feature_meta) <- NULL
  feature_meta
}

.normalize_point_level_table <- function(x, point_ids, name) {
  if (is.null(x)) {
    return(.empty_df(point_id = character()))
  }

  x <- .normalize_table(x, "point_id", name)
  x$point_id <- as.character(x$point_id)

  missing_points <- setdiff(unique(x$point_id), point_ids)
  if (length(missing_points) > 0L) {
    cli::cli_abort(
      "{.arg {name}} contains unknown points {.val {missing_points}}."
    )
  }

  if (anyDuplicated(x$point_id)) {
    cli::cli_abort("{.arg {name}} must have unique {.field point_id} rows.")
  }

  rownames(x) <- NULL
  x
}

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

.point_value_table <- function(x, feature = NULL, fun = sum) {
  explanations <- x$explanations
  if (!is.null(feature)) {
    explanations <- explanations[explanations$feature %in% feature, , drop = FALSE]
  }

  if (nrow(explanations) == 0L) {
    out <- x$points[, c("point_id", "x", "y", "z"), drop = FALSE]
    out$value <- 0
    return(out)
  }

  agg <- stats::aggregate(
    value ~ point_id,
    data = explanations,
    FUN = fun
  )

  out <- merge(
    x$points,
    agg,
    by = "point_id",
    all.x = TRUE,
    sort = FALSE
  )
  out$value[is.na(out$value)] <- 0
  out
}

.wide_explanation_matrix <- function(x) {
  features <- x$feature_meta$feature
  point_ids <- x$points$point_id
  matrix_out <- matrix(
    0,
    nrow = length(point_ids),
    ncol = length(features),
    dimnames = list(point_ids, features)
  )

  if (nrow(x$explanations) > 0L) {
    row_idx <- match(x$explanations$point_id, point_ids)
    col_idx <- match(x$explanations$feature, features)
    matrix_out[cbind(row_idx, col_idx)] <- x$explanations$value
  }

  matrix_out
}

.numeric_point_meta_matrix <- function(x) {
  meta <- x$point_meta
  if (nrow(meta) == 0L) {
    cli::cli_abort("{.field point_meta} does not contain numeric columns.")
  }

  keep <- vapply(meta, is.numeric, logical(1))
  keep["point_id"] <- FALSE
  if (!any(keep)) {
    cli::cli_abort("{.field point_meta} does not contain numeric columns.")
  }

  matrix_out <- as.matrix(meta[, keep, drop = FALSE])
  rownames(matrix_out) <- meta$point_id
  matrix_out
}

.source_matrix_from_data <- function(x, source = c("explanations", "point_meta", "points")) {
  source <- match.arg(source)

  if (identical(source, "explanations")) {
    return(.wide_explanation_matrix(x))
  }

  if (identical(source, "point_meta")) {
    return(.numeric_point_meta_matrix(x))
  }

  matrix_out <- as.matrix(x$points[, c("x", "y", "z"), drop = FALSE])
  rownames(matrix_out) <- x$points$point_id
  matrix_out
}

.safe_merge <- function(x, y, by) {
  if (is.null(y) || nrow(y) == 0L) {
    return(x)
  }

  merge(x, y, by = by, all.x = TRUE, sort = FALSE)
}

.scene_point_view <- function(scene, embedding = NULL) {
  embedding_name <- .or_default(embedding, scene$embeddings$active)
  if (!(embedding_name %in% names(scene$embeddings$items))) {
    cli::cli_abort("Unknown embedding {.val {embedding_name}}.")
  }

  coords <- scene$embeddings$items[[embedding_name]]$coords
  coord_cols <- setdiff(names(coords), "point_id")

  if (length(coord_cols) < 2L) {
    cli::cli_abort(
      "Embedding {.val {embedding_name}} must contain at least two dimensions."
    )
  }

  out <- .empty_df(
    point_id = coords$point_id,
    x = as.numeric(coords[[coord_cols[[1]]]]),
    y = as.numeric(coords[[coord_cols[[2]]]]),
    z = if (length(coord_cols) >= 3L) {
      as.numeric(coords[[coord_cols[[3]]]])
    } else {
      rep(0, nrow(coords))
    }
  )

  values <- .point_value_table(scene$data)[, c("point_id", "value"), drop = FALSE]
  out <- .safe_merge(out, values, by = "point_id")
  out <- .safe_merge(out, scene$data$point_meta, by = "point_id")
  out <- .safe_merge(out, scene$data$predictions, by = "point_id")
  out <- .safe_merge(out, scene$data$uncertainty, by = "point_id")

  active_diag <- scene$diagnostics$active
  if (!is.null(active_diag) && active_diag %in% names(scene$diagnostics$items)) {
    diag_tbl <- scene$diagnostics$items[[active_diag]]$per_point
    out <- .safe_merge(out, diag_tbl, by = "point_id")
  }

  out
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

.knn_indices <- function(mat, k) {
  n <- nrow(mat)
  if (n < 2L) {
    cli::cli_abort("Nearest-neighbour diagnostics require at least two points.")
  }

  dmat <- as.matrix(stats::dist(mat))
  diag(dmat) <- Inf
  out <- lapply(seq_len(n), function(i) order(dmat[i, ])[seq_len(k)])
  matrix(unlist(out, use.names = FALSE), nrow = n, byrow = TRUE)
}

.trustworthiness_score <- function(reference, embedded, k) {
  n <- nrow(reference)
  ref_dist <- as.matrix(stats::dist(reference))
  emb_dist <- as.matrix(stats::dist(embedded))
  diag(ref_dist) <- Inf
  diag(emb_dist) <- Inf

  ref_knn <- .knn_indices(reference, k)
  emb_knn <- .knn_indices(embedded, k)
  ref_ranks <- t(vapply(
    seq_len(n),
    function(i) rank(ref_dist[i, ], ties.method = "average"),
    numeric(n)
  ))

  penalty <- 0
  for (i in seq_len(n)) {
    intruders <- setdiff(emb_knn[i, ], ref_knn[i, ])
    if (length(intruders) == 0L) {
      next
    }
    penalty <- penalty + sum(ref_ranks[i, intruders] - k)
  }

  denom <- n * k * (2 * n - 3 * k - 1)
  if (denom <= 0) {
    return(1)
  }

  1 - (2 / denom) * penalty
}

.local_agreement_score <- function(reference, embedded, k) {
  ref_knn <- .knn_indices(reference, k)
  emb_knn <- .knn_indices(embedded, k)

  vapply(seq_len(nrow(ref_knn)), function(i) {
    length(intersect(ref_knn[i, ], emb_knn[i, ])) / k
  }, numeric(1))
}

.pad_embedding_dims <- function(mat, dims) {
  if (ncol(mat) >= dims) {
    return(mat[, seq_len(dims), drop = FALSE])
  }

  extra <- matrix(0, nrow = nrow(mat), ncol = dims - ncol(mat))
  cbind(mat, extra)
}

.embedding_record <- function(name, coords, method, source, meta = list()) {
  coords <- as.data.frame(coords, stringsAsFactors = FALSE)
  if (!("point_id" %in% names(coords))) {
    cli::cli_abort("Embedding coordinates must include a {.field point_id} column.")
  }

  structure(
    list(
      name = name,
      method = method,
      source = source,
      coords = coords,
      meta = meta
    ),
    class = "xgeo_embedding"
  )
}

.normalize_embeddings <- function(embeddings, data) {
  spatial <- .embedding_record(
    name = "spatial",
    method = "identity",
    source = "points",
    coords = .empty_df(
      point_id = data$points$point_id,
      dim1 = data$points$x,
      dim2 = data$points$y,
      dim3 = data$points$z
    )
  )

  items <- list(spatial = spatial)
  active <- "spatial"

  if (is.null(embeddings)) {
    return(list(active = active, items = items))
  }

  if (!.is_named_list(embeddings$items)) {
    cli::cli_abort("{.arg embeddings} must be a named list with an {.field items} entry.")
  }

  user_items <- embeddings$items
  user_items$spatial <- NULL
  items <- c(items, user_items)
  active <- .or_default(embeddings$active, active)

  if (!(active %in% names(items))) {
    cli::cli_abort("Unknown active embedding {.val {active}}.")
  }

  list(active = active, items = items)
}

.normalize_diagnostics <- function(diagnostics) {
  if (is.null(diagnostics)) {
    return(list(active = NULL, items = list()))
  }

  active <- diagnostics$active
  items <- .or_default(diagnostics$items, list())
  if (!is.list(items)) {
    cli::cli_abort("{.arg diagnostics$items} must be a list.")
  }

  if (!is.null(active) && !(active %in% names(items))) {
    cli::cli_abort("Unknown active diagnostic {.val {active}}.")
  }

  list(active = active, items = items)
}

.normalize_lod <- function(lod) {
  base <- list(
    active = list(name = NULL, level = NULL),
    items = list(),
    auto = list(point_threshold = 200L)
  )

  if (is.null(lod)) {
    return(base)
  }

  items <- .or_default(lod$items, list())
  active <- .or_default(lod$active, base$active)
  auto <- .or_default(lod$auto, base$auto)

  if (!is.list(items)) {
    cli::cli_abort("{.arg lod$items} must be a list.")
  }

  if (!is.list(auto) || !.is_count(.or_default(auto$point_threshold, 200L))) {
    cli::cli_abort("{.arg lod$auto$point_threshold} must be a positive whole number.")
  }

  if (!is.null(active$name)) {
    if (!(active$name %in% names(items))) {
      cli::cli_abort("Unknown active LOD bundle {.val {active$name}}.")
    }
    if (!is.null(active$level) &&
        !(as.character(active$level) %in% names(items[[active$name]]$levels))) {
      cli::cli_abort("Unknown active LOD level {.val {active$level}}.")
    }
  }

  list(active = active, items = items, auto = auto)
}

.normalize_views <- function(views) {
  base <- list(
    active = "main",
    items = list(main = list(title = "main"))
  )

  if (is.null(views)) {
    return(base)
  }

  items <- .or_default(views$items, base$items)
  active <- .or_default(views$active, base$active)

  if (!is.list(items)) {
    cli::cli_abort("{.arg views$items} must be a list.")
  }

  if (!(active %in% names(items))) {
    cli::cli_abort("Unknown active view {.val {active}}.")
  }

  list(active = active, items = items)
}

.normalize_selection <- function(selection) {
  base <- list(point_ids = character(), features = character())
  if (is.null(selection)) {
    return(base)
  }

  list(
    point_ids = unique(as.character(.or_default(selection$point_ids, character()))),
    features = unique(as.character(.or_default(selection$features, character())))
  )
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
    x = head(x_breaks, -1),
    y = head(y_breaks, -1),
    z = stats,
    counts = counts,
    color_by = color_by
  )
}

.serialize_layer <- function(layer) {
  list(
    class = class(layer),
    fields = unclass(layer)
  )
}

.deserialize_layer <- function(layer) {
  structure(layer$fields, class = unlist(layer$class, use.names = FALSE))
}
