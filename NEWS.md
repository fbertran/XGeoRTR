# XGeoRTR 0.6.0

- Added runnable, CRAN-safe examples to all exported help topics so package
  checks no longer report `checking examples ... NONE`.
- Added documentation coverage tests to ensure exported `.Rd` topics retain
  `\examples{}` sections and to prevent regressions in future releases.
- No backend contract or public API changes in this release; the update is
  limited to documentation quality and release-check stability.

# XGeoRTR 0.5.0

- Added `INTERFACE_FREEZE.md` and recursive contract tests to lock the
  XGeoRTR/ggWebGL ownership boundary.
- Added renderer-agnostic table helpers: `xgeo_explanation_table()`,
  `xgeo_point_values()`, and `xgeo_regular_grid()`.
- Centralized selection-aware point/feature filtering for downstream packages.
- Clarified the public interface freeze around `xgeo_state`; use-case packages
  should consume backend state and generic tables rather than internal data
  structures.

# XGeoRTR 0.4.0

- Hard architectural break: `xgeo_scene` has been replaced by backend-neutral
  `xgeo_state`.
- Added `as_xgeo_state()`, `write_xgeo_state()`, and `read_xgeo_state()`.
- Added backend accessors: `xgeo_geometry()`, `xgeo_attributes()`,
  `xgeo_indices()`, `xgeo_selection()`, and `xgeo_metadata()`.
- Removed renderer-facing API from XGeoRTR:
  `render_webgl()`, `snapshot_webgl()`, `render_xgeo_layer()`, and all
  `geom_xgeo_*()` constructors.
- Retargeted embedding/diagnostics/LOD/selection operators to `xgeo_state`.
- `xgeo_data` is now internal-only and no longer part of the public API.

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
