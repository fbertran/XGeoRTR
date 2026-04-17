# XGeoRTR 0.2.0

- Redesigned `xgeo_data` as a normalized platform object with explicit
  `points`, `explanations`, `point_meta`, `feature_meta`, `predictions`, and
  `uncertainty`.
- Preserved unmapped point-level metadata during `as_xgeo_data.data.frame()`
  ingestion instead of dropping extra columns.
- Expanded `xgeo_scene()` to own embeddings, diagnostics, LOD state, views,
  selection state, and scene metadata.
- Added `compute_xgeo_embedding()`, `compute_xgeo_diagnostics()`,
  `build_xgeo_lod()`, `set_active_embedding()`, `set_xgeo_selection()`, and
  `set_xgeo_lod()`.
- Added `geom_xgeo_points()` and `geom_xgeo_density()` alongside the existing
  `geom_xgeo_surface()`.
- Added JSON scene IO through `write_xgeo_scene()` and `read_xgeo_scene()`.
- Removed the misleading public `animate_camera_orbit()` helper because the
  renderer does not execute camera animation paths in this release.
