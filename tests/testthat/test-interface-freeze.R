test_that("exported XGeoRTR API matches backend-only freeze", {
  exports <- getNamespaceExports("XGeoRTR")

  expected_exports <- c(
    "xgeo_state",
    "as_xgeo_state",
    "validate_xgeo_state",
    "compute_xgeo_embedding",
    "compute_xgeo_diagnostics",
    "build_xgeo_lod",
    "set_active_embedding",
    "set_xgeo_selection",
    "set_xgeo_lod",
    "read_xgeo_state",
    "write_xgeo_state",
    "xgeo_geometry",
    "xgeo_attributes",
    "xgeo_indices",
    "xgeo_selection",
    "xgeo_metadata",
    "xgeo_explanation_table",
    "xgeo_point_values",
    "xgeo_regular_grid"
  )

  expect_true(all(expected_exports %in% exports))
  expect_false(any(grepl("scene|render_|camera|viewport", exports)))
})
