test_that("milestone 4 internal helper layout is backend-only", {
  helper_files <- file.path(
    testthat::test_path("..", "..", "R"),
    c(
      "utils-coerce.R",
      "utils-state.R",
      "utils-geometry.R",
      "utils-matrix.R"
    )
  )

  expect_true(all(file.exists(helper_files)))

  helper_text <- paste(unlist(lapply(helper_files, readLines, warn = FALSE)), collapse = "\n")
  forbidden_vocab <- "\\b(scene|render|camera|viewport|canvas|theme|shader|widget|snapshot|layer|view)\\b"
  expect_false(grepl(forbidden_vocab, helper_text, ignore.case = TRUE, perl = TRUE))
})

test_that("milestone 4 embedding point helper rename is applied internally", {
  ns <- asNamespace("XGeoRTR")

  expect_true(exists(".xgeo_embedding_point_table", envir = ns, inherits = FALSE))
  expect_false(exists(".xgeo_point_view", envir = ns, inherits = FALSE))
})
