options(rgl.useNULL = TRUE)

test_that("xgeo_scene stores expanded platform state", {
  xd <- as_xgeo_data(matrix(c(1, -1, 0.5, 0), nrow = 2), method = "scene-demo")
  scene <- xgeo_scene(xd) + geom_xgeo_surface(alpha = 0.6)

  expect_s3_class(scene, "xgeo_scene")
  expect_length(scene$layers, 1L)
  expect_s3_class(scene$layers[[1]], "xgeo_layer")
  expect_true("spatial" %in% names(scene$embeddings$items))
  expect_equal(scene$embeddings$active, "spatial")
  expect_named(scene$selection, c("point_ids", "features"))
})

test_that("compute_xgeo_embedding adds PCA and optional UMAP embeddings", {
  scene <- xgeo_scene(as_xgeo_data(matrix(c(1, 2, 3, 4), nrow = 2), method = "embed-demo"))
  scene <- compute_xgeo_embedding(scene, method = "pca", source = "explanations", dims = 2)

  expect_true("pca_explanations" %in% names(scene$embeddings$items))
  expect_equal(ncol(scene$embeddings$items$pca_explanations$coords), 3L)

  if (requireNamespace("uwot", quietly = TRUE)) {
    scene <- compute_xgeo_embedding(scene, method = "umap", dims = 2)
    expect_true("umap_explanations" %in% names(scene$embeddings$items))
  }
})

test_that("compute_xgeo_diagnostics stores trustworthiness and local agreement", {
  scene <- xgeo_scene(as_xgeo_data(matrix(c(1, -1, 2, 0), nrow = 2), method = "diag-demo"))
  scene <- compute_xgeo_embedding(scene, method = "pca", source = "explanations", dims = 2)
  scene <- set_active_embedding(scene, "pca_explanations")
  scene <- compute_xgeo_diagnostics(scene, source = "explanations", k = 1)

  active_name <- scene$diagnostics$active
  diag_obj <- scene$diagnostics$items[[active_name]]
  expect_true(diag_obj$global$trustworthiness >= 0)
  expect_true(diag_obj$global$trustworthiness <= 1)
  expect_equal(nrow(diag_obj$per_point), nrow(scene$data$points))
  expect_true("local_agreement" %in% names(diag_obj$per_point))
})

test_that("scene JSON round-trips embeddings, diagnostics, lod, and selection", {
  scene <- xgeo_scene(as_xgeo_data(matrix(c(1, -1, 2, 0), nrow = 2), method = "io-demo"))
  scene <- compute_xgeo_embedding(scene, method = "pca", source = "explanations", dims = 2)
  scene <- set_active_embedding(scene, "pca_explanations")
  scene <- compute_xgeo_diagnostics(scene, source = "explanations", k = 1)
  scene <- build_xgeo_lod(scene, levels = c(8L, 16L), auto_threshold = 2L)
  scene <- set_xgeo_selection(scene, point_ids = "point_1")

  out_file <- tempfile(fileext = ".json")
  write_xgeo_scene(scene, out_file)
  restored <- read_xgeo_scene(out_file)

  expect_equal(restored$embeddings$active, "pca_explanations")
  expect_equal(restored$selection$point_ids, "point_1")
  expect_equal(names(restored$lod$items), names(scene$lod$items))
  expect_equal(names(restored$diagnostics$items), names(scene$diagnostics$items))
})

test_that("render_webgl dispatches surface, point, and density layers headlessly", {
  scene <- xgeo_scene(
    as_xgeo_data(matrix(c(1, -1, 2, 0), nrow = 2), method = "render-demo"),
    camera = list(preset = "top")
  ) +
    geom_xgeo_surface(alpha = 0.7, smooth = TRUE) +
    geom_xgeo_points(size = 6)

  expect_silent(render_webgl(scene, open = FALSE))
  try(rgl::close3d(), silent = TRUE)
})

test_that("LOD auto switches point rendering to density grids", {
  values <- matrix(seq_len(25), nrow = 5)
  scene <- xgeo_scene(as_xgeo_data(values, method = "lod-demo")) +
    geom_xgeo_points(size = 5)
  scene <- build_xgeo_lod(scene, levels = c(8L, 16L), auto_threshold = 5L)

  expect_silent(render_webgl(scene, lod_level = "auto", open = FALSE))
  try(rgl::close3d(), silent = TRUE)
})

test_that("render_webgl can export HTML when htmlwidgets is available", {
  skip_if_not_installed("htmlwidgets")

  scene <- xgeo_scene(
    as_xgeo_data(matrix(c(1, 0, -1, 0.5), nrow = 2), method = "html-demo"),
    camera = list(preset = "top")
  ) + geom_xgeo_points(size = 6)

  out_file <- tempfile(fileext = ".html")
  result <- render_webgl(scene, file = out_file, selfcontained = FALSE, open = FALSE)

  expect_true(file.exists(out_file))
  expect_match(result, "\\.html$")
  try(rgl::close3d(), silent = TRUE)
})
