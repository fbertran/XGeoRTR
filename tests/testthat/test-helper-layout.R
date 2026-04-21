test_that("milestone 4 internal helpers are present in the namespace", {
  ns <- asNamespace("XGeoRTR")
  expected_helpers <- c(
    ".coerce_spatial_long_table",
    ".xgeo_embedding_point_table",
    ".regular_grid_from_long",
    ".source_matrix_from_data"
  )

  expect_true(all(vapply(
    expected_helpers,
    exists,
    logical(1),
    envir = ns,
    inherits = FALSE
  )))
})

test_that("milestone 4 source helper modules are backend-only", {
  helper_files <- file.path(
    testthat::test_path("..", "..", "R"),
    c(
      "utils-coerce.R",
      "utils-state.R",
      "utils-geometry.R",
      "utils-matrix.R"
    )
  )

  skip_if_not(
    all(file.exists(helper_files)),
    "Source helper files are only available in source-tree tests."
  )

  helper_text <- paste(unlist(lapply(helper_files, readLines, warn = FALSE)), collapse = "\n")
  forbidden_vocab <- "\\b(scene|render|camera|viewport|canvas|theme|shader|widget|snapshot|layer|view)\\b"
  expect_false(grepl(forbidden_vocab, helper_text, ignore.case = TRUE, perl = TRUE))
})

test_that("milestone 4 embedding point helper rename is applied internally", {
  ns <- asNamespace("XGeoRTR")

  expect_true(exists(".xgeo_embedding_point_table", envir = ns, inherits = FALSE))
  expect_false(exists(".xgeo_point_view", envir = ns, inherits = FALSE))
})
