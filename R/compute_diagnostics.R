#' Compute embedding diagnostics for a scene
#'
#' @param scene An `xgeo_scene` object.
#' @param embedding Optional embedding name. Defaults to the active embedding.
#' @param source Reference source space used for neighbour comparisons.
#' @param k Number of neighbours.
#' @param name Optional diagnostic bundle name.
#'
#' @return The updated `xgeo_scene`.
#' @export
compute_xgeo_diagnostics <- function(scene,
                                     embedding = NULL,
                                     source = c("explanations", "point_meta", "points"),
                                     k = 10L,
                                     name = NULL) {
  .validate_xgeo_scene(scene)
  source <- match.arg(source)

  if (!.is_count(k)) {
    cli::cli_abort("{.arg k} must be a positive whole number.")
  }

  embedding_name <- .or_default(embedding, scene$embeddings$active)
  if (!(embedding_name %in% names(scene$embeddings$items))) {
    cli::cli_abort("Unknown embedding {.val {embedding_name}}.")
  }

  reference <- .source_matrix_from_data(scene$data, source)
  embedded_tbl <- scene$embeddings$items[[embedding_name]]$coords
  embedded <- as.matrix(embedded_tbl[, setdiff(names(embedded_tbl), "point_id"), drop = FALSE])
  rownames(embedded) <- embedded_tbl$point_id

  common_ids <- intersect(rownames(reference), rownames(embedded))
  if (length(common_ids) < 2L) {
    cli::cli_abort("Diagnostics require at least two shared points.")
  }

  reference <- reference[common_ids, , drop = FALSE]
  embedded <- embedded[common_ids, , drop = FALSE]
  k <- min(k, nrow(reference) - 1L)

  local_agreement <- .local_agreement_score(reference, embedded, k)
  trustworthiness <- .trustworthiness_score(reference, embedded, k)

  name <- .or_default(name, paste("diagnostics", embedding_name, source, sep = "_"))
  scene$diagnostics$items[[name]] <- list(
    name = name,
    embedding = embedding_name,
    source = source,
    k = k,
    global = list(trustworthiness = trustworthiness),
    per_point = .empty_df(
      point_id = common_ids,
      local_agreement = as.numeric(local_agreement)
    )
  )

  if (is.null(scene$diagnostics$active)) {
    scene$diagnostics$active <- name
  }

  scene
}
