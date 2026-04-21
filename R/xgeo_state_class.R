#' Create an `xgeo_state`
#'
#' @param x A matrix, data frame, or object coercible to backend geometry state.
#' @param embeddings Optional embedding state.
#' @param diagnostics Optional diagnostic state.
#' @param lod Optional level-of-detail state.
#' @param selection Optional explicit selection state.
#' @param metadata Optional state metadata.
#'
#' @return An `xgeo_state` object.
#' @export
xgeo_state <- function(x,
                       embeddings = NULL,
                       diagnostics = NULL,
                       lod = NULL,
                       selection = NULL,
                       metadata = list()) {
  if (inherits(x, "xgeo_state")) {
    if (!is.null(embeddings) || !is.null(diagnostics) || !is.null(lod) ||
        !is.null(selection) || length(metadata) > 0L) {
      cli::cli_abort(
        paste(
          "When {.arg x} is already an {.cls xgeo_state},",
          "do not pass state override arguments."
        )
      )
    }

    validate_xgeo_state(x)
    return(x)
  }

  data <- as_xgeo_data(
    x,
    embeddings = embeddings,
    diagnostics = diagnostics,
    lod = lod,
    selection = selection,
    meta = metadata
  )

  .xgeo_state_from_xgeo_data(data)
}

new_xgeo_state <- function(geometry,
                           attributes,
                           indices,
                           selection = NULL,
                           lod = NULL,
                           metadata = list()) {
  state <- structure(
    list(
      geometry = geometry,
      attributes = attributes,
      indices = indices,
      selection = .normalize_selection(selection),
      lod = .normalize_lod(lod),
      metadata = metadata
    ),
    class = "xgeo_state"
  )

  validate_xgeo_state(state)
  state
}

.xgeo_state_from_xgeo_data <- function(data) {
  validate_xgeo_data(data)

  new_xgeo_state(
    geometry = list(points = data$points),
    attributes = list(
      explanations = data$explanations,
      point_meta = data$point_meta,
      feature_meta = data$feature_meta,
      predictions = data$predictions,
      uncertainty = data$uncertainty,
      embeddings = data$embeddings,
      diagnostics = data$diagnostics,
      baseline = data$baseline,
      method = data$method,
      structure = data$structure
    ),
    indices = list(
      point_ids = data$points$point_id,
      feature_ids = data$feature_meta$feature
    ),
    selection = data$selection,
    lod = data$lod,
    metadata = data$meta
  )
}

#' Validate an `xgeo_state` object
#'
#' @param x An object to validate.
#'
#' @return `x`, invisibly, when validation succeeds.
#' @export
validate_xgeo_state <- function(x) {
  if (!inherits(x, "xgeo_state")) {
    cli::cli_abort("{.arg x} must inherit from {.cls xgeo_state}.")
  }

  forbidden <- intersect(
    c("scene", "layers", "views", "camera", "viewport", "canvas", "theme", "render_backend"),
    names(x)
  )
  if (length(forbidden) > 0L) {
    cli::cli_abort(
      "{.cls xgeo_state} objects must not contain renderer-only fields {.val {forbidden}}."
    )
  }

  required_fields <- c(
    "geometry",
    "attributes",
    "indices",
    "selection",
    "lod",
    "metadata"
  )
  missing_fields <- setdiff(required_fields, names(x))
  if (length(missing_fields) > 0L) {
    cli::cli_abort(
      "{.cls xgeo_state} objects must contain fields {.val {missing_fields}}."
    )
  }

  if (!is.list(x$geometry) || !"points" %in% names(x$geometry)) {
    cli::cli_abort("{.field geometry} must be a list containing {.field points}.")
  }
  points_tbl <- .normalize_points(x$geometry$points)

  required_attributes <- c(
    "explanations",
    "point_meta",
    "feature_meta",
    "predictions",
    "uncertainty",
    "embeddings",
    "diagnostics",
    "baseline",
    "method",
    "structure"
  )
  if (!is.list(x$attributes)) {
    cli::cli_abort("{.field attributes} must be a list.")
  }
  missing_attributes <- setdiff(required_attributes, names(x$attributes))
  if (length(missing_attributes) > 0L) {
    cli::cli_abort(
      "{.field attributes} must contain fields {.val {missing_attributes}}."
    )
  }

  explanations_tbl <- .normalize_explanations(x$attributes$explanations, points_tbl$point_id)
  point_meta_tbl <- .normalize_point_level_table(x$attributes$point_meta, points_tbl$point_id, "attributes$point_meta")
  predictions_tbl <- .normalize_point_level_table(x$attributes$predictions, points_tbl$point_id, "attributes$predictions")
  uncertainty_tbl <- .normalize_point_level_table(x$attributes$uncertainty, points_tbl$point_id, "attributes$uncertainty")
  feature_meta_tbl <- .normalize_feature_meta(x$attributes$feature_meta, explanations_tbl)

  .normalize_embeddings(
    x$attributes$embeddings,
    list(points = points_tbl)
  )
  .normalize_diagnostics(x$attributes$diagnostics)
  .normalize_lod(x$lod)
  .normalize_xgeo_data_selection(
    x$selection,
    points_tbl$point_id,
    feature_meta_tbl$feature
  )

  if (!is.null(x$attributes$baseline) && !.is_scalar_numeric(x$attributes$baseline)) {
    cli::cli_abort("{.field attributes$baseline} must be NULL or a single numeric value.")
  }
  if (!.is_scalar_string(x$attributes$method)) {
    cli::cli_abort("{.field attributes$method} must be a single string.")
  }
  if (!(x$attributes$structure %in% .xgeo_supported_structures())) {
    cli::cli_abort(
      "{.field attributes$structure} {.val {x$attributes$structure}} is not supported."
    )
  }

  if (!is.list(x$indices)) {
    cli::cli_abort("{.field indices} must be a list.")
  }
  if (!all(c("point_ids", "feature_ids") %in% names(x$indices))) {
    cli::cli_abort(
      "{.field indices} must contain {.field point_ids} and {.field feature_ids}."
    )
  }

  point_ids <- unique(as.character(x$indices$point_ids))
  feature_ids <- unique(as.character(x$indices$feature_ids))

  if (!setequal(point_ids, points_tbl$point_id)) {
    cli::cli_abort("{.field indices$point_ids} must match {.field geometry$points$point_id}.")
  }
  if (!setequal(feature_ids, feature_meta_tbl$feature)) {
    cli::cli_abort("{.field indices$feature_ids} must match {.field attributes$feature_meta$feature}.")
  }

  if (!is.list(x$metadata)) {
    cli::cli_abort("{.field metadata} must be a list.")
  }

  invisible(x)
}

#' @export
print.xgeo_state <- function(x, ...) {
  validate_xgeo_state(x)

  cat(
    "<xgeo_state>\n",
    "  structure:    ", x$attributes$structure, "\n",
    "  method:       ", x$attributes$method, "\n",
    "  points:       ", nrow(x$geometry$points), "\n",
    "  features:     ", length(x$indices$feature_ids), "\n",
    "  embeddings:   ", length(x$attributes$embeddings$items),
    " (active: ", x$attributes$embeddings$active, ")\n",
    "  diagnostics:  ", length(x$attributes$diagnostics$items), "\n",
    "  lod bundles:  ", length(x$lod$items), "\n",
    sep = ""
  )

  invisible(x)
}

#' @export
summary.xgeo_state <- function(object, ...) {
  validate_xgeo_state(object)

  out <- list(
    structure = object$attributes$structure,
    method = object$attributes$method,
    n_points = nrow(object$geometry$points),
    n_features = length(object$indices$feature_ids),
    n_explanations = nrow(object$attributes$explanations),
    active_embedding = object$attributes$embeddings$active,
    n_embeddings = length(object$attributes$embeddings$items),
    active_diagnostic = object$attributes$diagnostics$active,
    n_diagnostics = length(object$attributes$diagnostics$items),
    active_lod = object$lod$active$name,
    n_lod_bundles = length(object$lod$items),
    n_selected_points = length(object$selection$point_ids),
    n_selected_features = length(object$selection$features),
    metadata_names = names(object$metadata)
  )

  class(out) <- "summary.xgeo_state"
  out
}

#' @export
print.summary.xgeo_state <- function(x, ...) {
  cat(
    "<summary.xgeo_state>\n",
    "  structure:      ", x$structure, "\n",
    "  method:         ", x$method, "\n",
    "  points:         ", x$n_points, "\n",
    "  features:       ", x$n_features, "\n",
    "  explanations:   ", x$n_explanations, "\n",
    "  embeddings:     ", x$n_embeddings, " (active: ", x$active_embedding, ")\n",
    "  diagnostics:    ", x$n_diagnostics, " (active: ", .or_default(x$active_diagnostic, "none"), ")\n",
    "  lod bundles:    ", x$n_lod_bundles, " (active: ", .or_default(x$active_lod, "none"), ")\n",
    "  selected points:", x$n_selected_points, "\n",
    "  selected feats: ", x$n_selected_features, "\n",
    sep = ""
  )

  invisible(x)
}
