required_example_topics <- c(
  "as_xgeo_state.Rd",
  "build_xgeo_lod.Rd",
  "compute_xgeo_diagnostics.Rd",
  "compute_xgeo_embedding.Rd",
  "read_xgeo_state.Rd",
  "set_active_embedding.Rd",
  "set_xgeo_lod.Rd",
  "set_xgeo_selection.Rd",
  "validate_xgeo_state.Rd",
  "write_xgeo_state.Rd",
  "xgeo_attributes.Rd",
  "xgeo_explanation_table.Rd",
  "xgeo_geometry.Rd",
  "xgeo_indices.Rd",
  "xgeo_metadata.Rd",
  "xgeo_point_values.Rd",
  "xgeo_regular_grid.Rd",
  "xgeo_selection.Rd",
  "xgeo_state.Rd"
)

locate_man_dir <- function() {
  candidates <- c(
    file.path(getwd(), "man"),
    file.path(
      normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = FALSE),
      "man"
    )
  )
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    return(NA_character_)
  }

  found[[1L]]
}

rd_has_examples <- function(path) {
  text <- readLines(path, warn = FALSE)
  any(grepl("^\\\\examples", text))
}

test_that("exported help topics include example sections", {
  man_dir <- locate_man_dir()

  if (is.na(man_dir)) {
    skip("man directory is unavailable in this installed-package test context.")
  }

  paths <- file.path(man_dir, required_example_topics)

  expect_true(all(file.exists(paths)))
  for (path in paths) {
    expect_true(rd_has_examples(path), info = basename(path))
  }
})
