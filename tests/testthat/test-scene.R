options(rgl.useNULL = TRUE)

test_that("xgeo_scene stores data and layers", {
  xd <- as_xgeo_data(matrix(c(1, -1, 0.5, 0), nrow = 2), method = "surface-demo")
  scene <- xgeo_scene(xd)
  scene <- scene + geom_xgeo_surface(alpha = 0.6)

  expect_s3_class(scene, "xgeo_scene")
  expect_length(scene$layers, 1L)
  expect_s3_class(scene$layers[[1]], "xgeo_layer")
})

test_that("animate_camera_orbit stores animation metadata", {
  scene <- xgeo_scene(as_xgeo_data(matrix(c(1, 2, 3, 4), nrow = 2), method = "orbit-demo"))
  animated <- animate_camera_orbit(scene, frames = 12, axis = "y", step = 15)

  expect_equal(animated$animation$frames, 12L)
  expect_equal(animated$animation$axis, "y")
  expect_equal(animated$animation$step, 15)
})

test_that("render_webgl dispatches the surface layer headlessly", {
  scene <- xgeo_scene(
    as_xgeo_data(matrix(c(1, -1, 2, 0), nrow = 2), method = "render-demo"),
    camera = list(preset = "top")
  ) + geom_xgeo_surface(alpha = 0.7, smooth = TRUE)

  expect_silent(render_webgl(scene, open = FALSE))
  try(rgl::close3d(), silent = TRUE)
})

test_that("render_webgl can export HTML when htmlwidgets is available", {
  skip_if_not_installed("htmlwidgets")

  scene <- xgeo_scene(
    as_xgeo_data(matrix(c(1, 0, -1, 0.5), nrow = 2), method = "html-demo"),
    camera = list(preset = "top")
  ) + geom_xgeo_surface(alpha = 0.7)

  out_file <- tempfile(fileext = ".html")
  result <- render_webgl(scene, file = out_file, selfcontained = FALSE, open = FALSE)

  expect_true(file.exists(out_file))
  expect_match(result, "\\.html$")
  try(rgl::close3d(), silent = TRUE)
})
