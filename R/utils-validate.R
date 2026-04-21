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

.validate_selected_flag <- function(selected) {
  if (!.is_scalar_flag(selected)) {
    cli::cli_abort("{.arg selected} must be `TRUE` or `FALSE`.")
  }

  invisible(selected)
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
