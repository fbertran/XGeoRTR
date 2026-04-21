#' Compute and attach a platform embedding
#'
#' @param state An `xgeo_state` object.
#' @param source Source matrix used to build the embedding. One of
#'   `"explanations"`, `"point_meta"`, or `"points"`.
#' @param method Embedding backend. `"pca"` is always available; `"umap"`
#'   requires `uwot`.
#' @param dims Number of output dimensions.
#' @param name Optional embedding name. Defaults to `<method>_<source>`.
#' @param ... Passed to backend-specific implementations.
#'
#' @return The updated `xgeo_state`.
#' @export
compute_xgeo_embedding <- function(state,
                                   source = c("explanations", "point_meta", "points"),
                                   method = c("pca", "umap"),
                                   dims = 2L,
                                   name = NULL,
                                   ...) {
  validate_xgeo_state(state)
  source <- match.arg(source)
  method <- match.arg(method)

  if (!.is_count(dims)) {
    cli::cli_abort("{.arg dims} must be a positive whole number.")
  }

  source_matrix <- .source_matrix_from_data(.xgeo_state_data(state), source)
  point_ids <- rownames(source_matrix)

  coords <- if (identical(method, "pca")) {
    keep <- apply(source_matrix, 2, stats::sd) > 0
    if (!any(keep)) {
      cli::cli_abort(
        "The selected {.arg source} does not contain non-constant columns for PCA."
      )
    }
    fit <- stats::prcomp(source_matrix[, keep, drop = FALSE], center = TRUE, scale. = TRUE)
    .pad_embedding_dims(fit$x, dims)
  } else {
    if (!requireNamespace("uwot", quietly = TRUE)) {
      cli::cli_abort(
        "Package {.pkg uwot} is required for {.val umap} embeddings."
      )
    }
    uwot::umap(source_matrix, n_components = dims, ...)
  }

  coords <- as.data.frame(coords, stringsAsFactors = FALSE)
  names(coords) <- paste0("dim", seq_len(ncol(coords)))
  coords$point_id <- point_ids
  coords <- coords[, c("point_id", setdiff(names(coords), "point_id")), drop = FALSE]

  name <- .or_default(name, paste(method, source, sep = "_"))
  if (!.is_scalar_string(name)) {
    cli::cli_abort("{.arg name} must be a single string.")
  }

  state$attributes$embeddings$items[[name]] <- .embedding_record(
    name = name,
    method = method,
    source = source,
    coords = coords,
    meta = list(
      dims = dims
    )
  )

  state
}
