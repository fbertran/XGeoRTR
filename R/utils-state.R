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

.safe_merge <- function(x, y, by) {
  if (is.null(y) || nrow(y) == 0L) {
    return(x)
  }

  merge(x, y, by = by, all.x = TRUE, sort = FALSE)
}

.rename_metadata_conflicts <- function(base_names, metadata, by, suffix) {
  if (is.null(metadata) || nrow(metadata) == 0L) {
    return(metadata)
  }

  rename <- intersect(setdiff(names(metadata), by), base_names)
  if (length(rename) > 0L) {
    names(metadata)[match(rename, names(metadata))] <- paste0(rename, suffix)
  }

  metadata
}

.merge_xgeo_metadata <- function(x, metadata, by, suffix) {
  if (is.null(metadata) || nrow(metadata) == 0L) {
    return(x)
  }

  metadata <- .rename_metadata_conflicts(names(x), metadata, by = by, suffix = suffix)
  merge(x, metadata, by = by, all.x = TRUE, sort = FALSE)
}

.xgeo_state_data <- function(state) {
  list(
    points = state$geometry$points,
    explanations = state$attributes$explanations,
    point_meta = state$attributes$point_meta,
    feature_meta = state$attributes$feature_meta,
    predictions = state$attributes$predictions,
    uncertainty = state$attributes$uncertainty
  )
}

.filter_point_level_table <- function(x, point_ids) {
  if (nrow(x) == 0L || length(point_ids) == 0L) {
    return(x[0L, , drop = FALSE])
  }

  x[x$point_id %in% point_ids, , drop = FALSE]
}

.selected_xgeo_state_data <- function(state, selected = TRUE) {
  data <- .xgeo_state_data(state)
  if (!selected) {
    return(data)
  }

  selection <- state$selection
  point_ids <- if (length(selection$point_ids) > 0L) {
    selection$point_ids
  } else {
    data$points$point_id
  }
  features <- if (length(selection$features) > 0L) {
    selection$features
  } else {
    data$feature_meta$feature
  }

  data$points <- data$points[data$points$point_id %in% point_ids, , drop = FALSE]
  data$explanations <- data$explanations[
    data$explanations$point_id %in% point_ids &
      data$explanations$feature %in% features,
    ,
    drop = FALSE
  ]
  data$point_meta <- .filter_point_level_table(data$point_meta, point_ids)
  data$predictions <- .filter_point_level_table(data$predictions, point_ids)
  data$uncertainty <- .filter_point_level_table(data$uncertainty, point_ids)
  data$feature_meta <- data$feature_meta[data$feature_meta$feature %in% features, , drop = FALSE]

  data
}

.xgeo_embedding_point_table <- function(state, embedding = NULL) {
  embedding_name <- .or_default(embedding, state$attributes$embeddings$active)
  if (!(embedding_name %in% names(state$attributes$embeddings$items))) {
    cli::cli_abort("Unknown embedding {.val {embedding_name}}.")
  }

  coords <- state$attributes$embeddings$items[[embedding_name]]$coords
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

  data <- .xgeo_state_data(state)
  values <- .point_value_table(data)[, c("point_id", "value"), drop = FALSE]
  out <- .safe_merge(out, values, by = "point_id")
  out <- .safe_merge(out, data$point_meta, by = "point_id")
  out <- .safe_merge(out, data$predictions, by = "point_id")
  out <- .safe_merge(out, data$uncertainty, by = "point_id")

  active_diag <- state$attributes$diagnostics$active
  if (!is.null(active_diag) && active_diag %in% names(state$attributes$diagnostics$items)) {
    diag_tbl <- state$attributes$diagnostics$items[[active_diag]]$per_point
    out <- .safe_merge(out, diag_tbl, by = "point_id")
  }

  out
}
