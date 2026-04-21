# XGeoRTR: Explainable Geometry Backend Infrastructure

Backend-level tools for standardizing explanation geometries into
backend-neutral `xgeo_state` objects with embeddings, diagnostics,
selection state, multiscale level-of-detail summaries, selected backend
tables, and JSON state exchange. XGeoRTR is intended to serve downstream
consumers such as `shapViz3D`, `rTDA3D`, and renderer frontends without
owning their presentation, interaction, or adapter layers. The frozen
package boundary is documented in `INTERFACE_FREEZE.md`.

## Author

**Maintainer**: Frederic Bertrand <frederic.bertrand@lecnam.net>
([ORCID](https://orcid.org/0000-0002-0837-8281))
