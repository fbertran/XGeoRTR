locate_downstream_example <- function() {
  path <- file.path(
    normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = TRUE),
    "inst",
    "examples",
    "downstream_shapviz3d_state_tables.R"
  )
  if (!file.exists(path)) {
    return(NA_character_)
  }
  path
}

test_that("downstream shapViz3D backend example runs without renderer dependencies", {
  example_path <- locate_downstream_example()

  expect_false(is.na(example_path))
  if (is.na(example_path)) {
    return(invisible())
  }

  expect_false(grepl("ggWebGL", paste(readLines(example_path, warn = FALSE), collapse = "\n"), fixed = TRUE))

  env <- new.env(parent = globalenv())
  expect_no_error(sys.source(example_path, envir = env))
  expect_true(exists("run_downstream_shapviz3d_state_tables", envir = env))

  results <- env$run_downstream_shapviz3d_state_tables()
  expect_true(length(results) >= 1L)

  first <- results[[1L]]
  expect_s3_class(first$state, "xgeo_state")
  expect_true(all(c("point_id", "feature", "value", "x", "y", "z") %in% names(first$explanation_tbl)))
  expect_true(all(c("point_id", "x", "y", "z", "value") %in% names(first$point_tbl)))
  expect_true(all(c("x", "y", "z") %in% names(first$regular_grid)))
})

test_that("active docs keep XGeoRTR backend-only and point downstream for figures", {
  root <- normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = TRUE)
  files <- c(
    file.path(root, "README.Rmd"),
    file.path(root, "vignettes", "getting-started.Rmd"),
    file.path(root, "inst", "examples", "downstream_shapviz3d_state_tables.R")
  )
  text <- paste(unlist(lapply(files[file.exists(files)], readLines, warn = FALSE)), collapse = "\n")

  expect_true(grepl("shapViz3D", text, fixed = TRUE))
  forbidden <- c("ggWebGL", "geom_point_webgl", "render_webgl", "waterfall", "attribution cloud")
  expect_false(any(vapply(forbidden, grepl, logical(1), x = text, fixed = TRUE)))
})
