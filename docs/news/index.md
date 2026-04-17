# Changelog

## XGeoRTR 0.2.0

- Redesigned `xgeo_data` as a normalized platform object with explicit
  `points`, `explanations`, `point_meta`, `feature_meta`, `predictions`,
  and `uncertainty`.
- Preserved unmapped point-level metadata during
  `as_xgeo_data.data.frame()` ingestion instead of dropping extra
  columns.
- Expanded [`xgeo_scene()`](../reference/xgeo_scene.md) to own
  embeddings, diagnostics, LOD state, views, selection state, and scene
  metadata.
- Added
  [`compute_xgeo_embedding()`](../reference/compute_xgeo_embedding.md),
  [`compute_xgeo_diagnostics()`](../reference/compute_xgeo_diagnostics.md),
  [`build_xgeo_lod()`](../reference/build_xgeo_lod.md),
  [`set_active_embedding()`](../reference/set_active_embedding.md),
  [`set_xgeo_selection()`](../reference/set_xgeo_selection.md), and
  [`set_xgeo_lod()`](../reference/set_xgeo_lod.md).
- Added [`geom_xgeo_points()`](../reference/geom_xgeo_points.md) and
  [`geom_xgeo_density()`](../reference/geom_xgeo_density.md) alongside
  the existing
  [`geom_xgeo_surface()`](../reference/geom_xgeo_surface.md).
- Added JSON scene IO through
  [`write_xgeo_scene()`](../reference/write_xgeo_scene.md) and
  [`read_xgeo_scene()`](../reference/read_xgeo_scene.md).
- Removed the misleading public `animate_camera_orbit()` helper because
  the renderer does not execute camera animation paths in this release.
