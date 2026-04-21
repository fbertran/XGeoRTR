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

test_that("milestone 3 rendering API is removed from XGeoRTR", {
  removed_api <- c(
    "geom_xgeo_points",
    "geom_xgeo_density",
    "geom_xgeo_surface",
    "render_xgeo_layer",
    "render_webgl",
    "snapshot_webgl"
  )

  exports <- getNamespaceExports("XGeoRTR")
  expect_false(any(removed_api %in% exports))

  ns <- asNamespace("XGeoRTR")
  for (fn in removed_api) {
    expect_false(exists(fn, envir = ns, inherits = FALSE))
  }
})
