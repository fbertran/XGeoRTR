test_that("xgeo_state stores backend-only canonical fields", {
  state <- xgeo_state(matrix(c(1, -1, 0.5, 0), nrow = 2))

  expect_s3_class(state, "xgeo_state")
  expect_named(
    state,
    c("geometry", "attributes", "indices", "selection", "lod", "metadata")
  )
  expect_true(all(c("points") %in% names(state$geometry)))
  expect_true(all(c("point_ids", "feature_ids") %in% names(state$indices)))
  expect_false(any(c(
    "layers", "views", "camera", "viewport", "theme", "render_backend",
    "shader", "widget", "snapshot", "export", "render"
  ) %in% names(state)))
})

test_that("compute_xgeo_embedding adds PCA and optional UMAP embeddings", {
  state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))
  state <- compute_xgeo_embedding(state, method = "pca", source = "explanations", dims = 2)

  expect_true("pca_explanations" %in% names(state$attributes$embeddings$items))
  expect_equal(ncol(state$attributes$embeddings$items$pca_explanations$coords), 3L)

  if (requireNamespace("uwot", quietly = TRUE)) {
    state <- compute_xgeo_embedding(state, method = "umap", dims = 2)
    expect_true("umap_explanations" %in% names(state$attributes$embeddings$items))
  }
})

test_that("compute_xgeo_diagnostics stores trustworthiness and local agreement", {
  state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
  state <- compute_xgeo_embedding(state, method = "pca", source = "explanations", dims = 2)
  state <- set_active_embedding(state, "pca_explanations")
  state <- compute_xgeo_diagnostics(state, source = "explanations", k = 1)

  active_name <- state$attributes$diagnostics$active
  diag_obj <- state$attributes$diagnostics$items[[active_name]]
  expect_true(diag_obj$global$trustworthiness >= 0)
  expect_true(diag_obj$global$trustworthiness <= 1)
  expect_equal(nrow(diag_obj$per_point), nrow(state$geometry$points))
  expect_true("local_agreement" %in% names(diag_obj$per_point))
})

test_that("state JSON round-trips embeddings, diagnostics, lod, and selection", {
  state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
  state <- compute_xgeo_embedding(state, method = "pca", source = "explanations", dims = 2)
  state <- set_active_embedding(state, "pca_explanations")
  state <- compute_xgeo_diagnostics(state, source = "explanations", k = 1)
  state <- build_xgeo_lod(state, levels = c(8L, 16L), auto_threshold = 2L)
  state <- set_xgeo_selection(state, point_ids = state$indices$point_ids[[1]])

  out_file <- tempfile(fileext = ".json")
  write_xgeo_state(state, out_file)
  restored <- read_xgeo_state(out_file)

  expect_equal(restored$attributes$embeddings$active, "pca_explanations")
  expect_equal(restored$selection$point_ids, state$indices$point_ids[[1]])
  expect_equal(names(restored$lod$items), names(state$lod$items))
  expect_equal(names(restored$attributes$diagnostics$items), names(state$attributes$diagnostics$items))
})

test_that("state JSON payload is backend-only and rooted at `state`", {
  state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
  out_file <- tempfile(fileext = ".json")
  write_xgeo_state(state, out_file)

  payload <- jsonlite::fromJSON(out_file, simplifyDataFrame = FALSE)
  expect_true("state" %in% names(payload))
  expect_false("scene" %in% names(payload))

  state_names <- names(payload$state)
  expect_true(all(c("geometry", "attributes", "indices", "selection", "lod", "metadata") %in% state_names))
  expect_false(any(c(
    "scene", "camera", "viewport", "layers", "theme", "render_backend",
    "shader", "widget", "snapshot", "export", "render"
  ) %in% state_names))
})

test_that("validate_xgeo_state rejects renderer-only fields", {
  state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
  state$camera <- list(preset = "top")

  expect_error(
    validate_xgeo_state(state),
    "renderer-only fields"
  )
})

test_that("print and summary methods work for xgeo_state", {
  state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))

  expect_output(print(state), "<xgeo_state>", fixed = TRUE)
  smry <- summary(state)
  expect_s3_class(smry, "summary.xgeo_state")
  expect_equal(smry$n_points, nrow(state$geometry$points))
  expect_output(print(smry), "<summary.xgeo_state>", fixed = TRUE)
})
