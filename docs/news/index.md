# Changelog

## XGeoRTR 0.5.0

- Added `INTERFACE_FREEZE.md` and recursive contract tests to lock the
  XGeoRTR/ggWebGL ownership boundary.
- Added renderer-agnostic table helpers:
  [`xgeo_explanation_table()`](../reference/xgeo_explanation_table.md),
  [`xgeo_point_values()`](../reference/xgeo_point_values.md), and
  [`xgeo_regular_grid()`](../reference/xgeo_regular_grid.md).
- Centralized selection-aware point/feature filtering for downstream
  packages.
- Clarified the public interface freeze around `xgeo_state`; use-case
  packages should consume backend state and generic tables rather than
  internal data structures.

## XGeoRTR 0.4.0

- Hard architectural break: `xgeo_scene` has been replaced by
  backend-neutral `xgeo_state`.
- Added [`as_xgeo_state()`](../reference/as_xgeo_state.md),
  [`write_xgeo_state()`](../reference/write_xgeo_state.md), and
  [`read_xgeo_state()`](../reference/read_xgeo_state.md).
- Added backend accessors:
  [`xgeo_geometry()`](../reference/xgeo_geometry.md),
  [`xgeo_attributes()`](../reference/xgeo_attributes.md),
  [`xgeo_indices()`](../reference/xgeo_indices.md),
  [`xgeo_selection()`](../reference/xgeo_selection.md), and
  [`xgeo_metadata()`](../reference/xgeo_metadata.md).
- Removed renderer-facing API from XGeoRTR: `render_webgl()`,
  `snapshot_webgl()`, `render_xgeo_layer()`, and all `geom_xgeo_*()`
  constructors.
- Retargeted embedding/diagnostics/LOD/selection operators to
  `xgeo_state`.
- `xgeo_data` is now internal-only and no longer part of the public API.

## XGeoRTR 0.2.0

- Redesigned `xgeo_data` as a normalized platform object with explicit
  `points`, `explanations`, `point_meta`, `feature_meta`, `predictions`,
  and `uncertainty`.
- Preserved unmapped point-level metadata during
  `as_xgeo_data.data.frame()` ingestion instead of dropping extra
  columns.
- Expanded `xgeo_scene()` to own embeddings, diagnostics, LOD state,
  views, selection state, and scene metadata.
- Added
  [`compute_xgeo_embedding()`](../reference/compute_xgeo_embedding.md),
  [`compute_xgeo_diagnostics()`](../reference/compute_xgeo_diagnostics.md),
  [`build_xgeo_lod()`](../reference/build_xgeo_lod.md),
  [`set_active_embedding()`](../reference/set_active_embedding.md),
  [`set_xgeo_selection()`](../reference/set_xgeo_selection.md), and
  [`set_xgeo_lod()`](../reference/set_xgeo_lod.md).
- Added `geom_xgeo_points()` and `geom_xgeo_density()` alongside the
  existing `geom_xgeo_surface()`.
- Added JSON scene IO through `write_xgeo_scene()` and
  `read_xgeo_scene()`.
- Removed the misleading public `animate_camera_orbit()` helper because
  the renderer does not execute camera animation paths in this release.
