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
