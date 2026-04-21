---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->

# XGeoRTR
## Frédéric Bertrand

`XGeoRTR` is a backend-neutral explainable geometry/state package for R.
It owns geometry-aware state, embeddings, diagnostics, multiscale summaries,
selection state, selected backend tables, and JSON state exchange. Rendering
is delegated to downstream packages such as `ggWebGL`.

## Main features

- Canonical backend object: `xgeo_state()`
- Coercion: `as_xgeo_state()`
- State operators:
  - `compute_xgeo_embedding()`
  - `compute_xgeo_diagnostics()`
  - `build_xgeo_lod()`
  - `set_active_embedding()`
  - `set_xgeo_selection()`
  - `set_xgeo_lod()`
- Backend-neutral accessors:
  - `xgeo_geometry()`
  - `xgeo_attributes()`
  - `xgeo_indices()`
  - `xgeo_selection()`
  - `xgeo_metadata()`
- Backend-neutral tables:
  - `xgeo_explanation_table()`
  - `xgeo_point_values()`
  - `xgeo_regular_grid()`
- Serialization:
  - `write_xgeo_state()`
  - `read_xgeo_state()`

## Installation

For local development from checked-out repositories:

```r
install.packages(c("cli", "jsonlite"))
devtools::load_all(".")
```

Optional packages:

- `uwot` for optional UMAP embeddings
- `knitr`, `rmarkdown`, and `pkgdown` for documentation work

## Build backend state


``` r
library(XGeoRTR)

demo_path <- system.file("extdata", "spatial_demo.csv", package = "XGeoRTR")
demo_tbl <- utils::read.csv(demo_path, stringsAsFactors = FALSE)

state <- as_xgeo_state(
  demo_tbl,
  x_col = "x",
  y_col = "y",
  z_col = "z",
  value_col = "value",
  feature_col = "feature",
  method = "surface-demo",
  meta = list(source = "synthetic-demo", sample_id = "grid-01")
)

state <- compute_xgeo_embedding(state, method = "pca", source = "points", dims = 2)
state <- set_active_embedding(state, "pca_points")
state <- compute_xgeo_diagnostics(state, embedding = "pca_points", source = "points", k = 3)
state <- build_xgeo_lod(state, embedding = "pca_points", levels = c(8L, 16L), auto_threshold = 10L)
state <- set_xgeo_selection(state, point_ids = state$indices$point_ids[[1]])

summary(state)
```

## Write and reload state


``` r
out_json <- tempfile(fileext = ".json")
write_xgeo_state(state, out_json)
restored_state <- read_xgeo_state(out_json)
```

## Build downstream tables


``` r
long_tbl <- xgeo_explanation_table(state)
point_tbl <- xgeo_point_values(state)
grid <- xgeo_regular_grid(point_tbl)
```

Use-case packages should consume these public tables instead of inspecting
internal ingestion objects.

## Scope

`XGeoRTR` is upstream of rendering layers. It provides state and computation;
frontends render that state.

- XGeoRTR: backend geometry/state semantics and generic selected tables
- ggWebGL (or another renderer): scene, camera, viewport, drawing

The frozen package boundary is documented in `INTERFACE_FREEZE.md`. Public
`XGeoRTR` objects and serialized payloads must remain free of renderer-owned
scene, layer, viewport, camera, canvas, theme, shader, widget, and export
surface fields.
