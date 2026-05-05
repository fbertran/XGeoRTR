# XGeoRTR: Backend-Neutral Explainable Geometry State and Operators ![](reference/figures/logo.png)

## Frédéric Bertrand

`XGeoRTR` is explainable geometry backend infrastructure for R workflows
that need reusable analytic state rather than package-specific
presentation code. It owns geometry-aware state, embeddings,
diagnostics, multiscale summaries, selection state, selected backend
tables, and JSON state exchange.

Downstream packages such as `shapViz3D`, `rTDA3D`, and renderer
frontends can consume `xgeo_state` or exported backend tables without
XGeoRTR taking ownership of their display, interaction, or use-case
presentation layers.

## Role in GeoXGL

`XGeoRTR` is the geometry/state backend of the
[`GeoXGL`](https://fbertran.github.io/GeoXGL/) ecosystem, a modular
R/WebGL stack for scalable statistical graphics, explanation geometry,
and scientific visualization.

Within GeoXGL:

- `XGeoRTR` owns backend-neutral explanation geometry, `xgeo_state`,
  embeddings, diagnostics, level-of-detail summaries, selection state,
  public backend tables, and JSON state exchange.
- `ggWebGL`, available as a CRAN renderer frontend, owns browser-native
  WebGL rendering, widgets, viewport interaction, shader execution, and
  static export surfaces.
- `shapViz3D` and other use-case packages own domain semantics and
  downstream layout mappings.

This package does not own rendering, viewport orchestration, camera
control, canvas management, shader execution, widget construction,
visual themes, or export surfaces. Those responsibilities remain in
renderer frontends such as `ggWebGL`.

## Current scope and future work

**Current scope:** backend state, coercion, embeddings, diagnostics,
level-of-detail summaries, selections, explanation tables, point-value
tables, regular-grid tables, and JSON serialization.

**Future/prototype scope:** topology-specific reasoning,
prediction-regime path semantics, and large-scale performance claims
should be presented only when supported by concrete downstream examples
or benchmark artifacts. Causal explanation is outside the current
package scope.

## Main features

- Canonical backend object:
  [`xgeo_state()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_state.md)
- Coercion:
  [`as_xgeo_state()`](https://fbertran.github.io/XGeoRTR/reference/as_xgeo_state.md)
- State operators:
  - [`compute_xgeo_embedding()`](https://fbertran.github.io/XGeoRTR/reference/compute_xgeo_embedding.md)
  - [`compute_xgeo_diagnostics()`](https://fbertran.github.io/XGeoRTR/reference/compute_xgeo_diagnostics.md)
  - [`build_xgeo_lod()`](https://fbertran.github.io/XGeoRTR/reference/build_xgeo_lod.md)
  - [`set_active_embedding()`](https://fbertran.github.io/XGeoRTR/reference/set_active_embedding.md)
  - [`set_xgeo_selection()`](https://fbertran.github.io/XGeoRTR/reference/set_xgeo_selection.md)
  - [`set_xgeo_lod()`](https://fbertran.github.io/XGeoRTR/reference/set_xgeo_lod.md)
- Backend-neutral accessors:
  - [`xgeo_geometry()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_geometry.md)
  - [`xgeo_attributes()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_attributes.md)
  - [`xgeo_indices()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_indices.md)
  - [`xgeo_selection()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_selection.md)
  - [`xgeo_metadata()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_metadata.md)
- Backend-neutral tables:
  - [`xgeo_explanation_table()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_explanation_table.md)
  - [`xgeo_point_values()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_point_values.md)
  - [`xgeo_regular_grid()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_regular_grid.md)
- Serialization:
  - [`write_xgeo_state()`](https://fbertran.github.io/XGeoRTR/reference/write_xgeo_state.md)
  - [`read_xgeo_state()`](https://fbertran.github.io/XGeoRTR/reference/read_xgeo_state.md)

## Installation

For local development from checked-out repositories:

``` r
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
  method = "spatial-field-demo",
  meta = list(source = "synthetic-demo", sample_id = "grid-01")
)

state <- compute_xgeo_embedding(state, method = "pca", source = "points", dims = 2)
state <- set_active_embedding(state, "pca_points")
state <- compute_xgeo_diagnostics(state, embedding = "pca_points", source = "points", k = 3)
state <- build_xgeo_lod(state, embedding = "pca_points", levels = c(8L, 16L), auto_threshold = 10L)
state <- set_xgeo_selection(state, point_ids = state$indices$point_ids[[1]])

summary(state)
```

## Popular R workflow examples

The file `inst/examples/popular_r_workflows.R` shows how outputs from
common R workflows can be standardized as backend explanation geometry:

- [`stats::lm()`](https://rdrr.io/r/stats/lm.html) on `mtcars`
- [`stats::glm()`](https://rdrr.io/r/stats/glm.html) on `mtcars`
- [`stats::kmeans()`](https://rdrr.io/r/stats/kmeans.html) on `iris`
- [`stats::prcomp()`](https://rdrr.io/r/stats/prcomp.html) on
  `USArrests`
- optional [`rpart::rpart()`](https://rdrr.io/pkg/rpart/man/rpart.html)
  on `iris`, when `rpart` is installed
- matrix-to-grid conversion using
  [`datasets::volcano`](https://rdrr.io/r/datasets/volcano.html)

The examples produce `xgeo_state` objects, compute PCA embeddings,
diagnostics, and LOD summaries, expose long and point-level backend
tables, and demonstrate JSON serialization through
[`tempfile()`](https://rdrr.io/r/base/tempfile.html).

``` r
source(system.file("examples", "popular_r_workflows.R", package = "XGeoRTR"))
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

Use-case packages should consume these public tables instead of
inspecting internal ingestion objects. For example, a Shapley-oriented
package can consume selected explanation tables, while a
topology-oriented package can consume point and regular-grid summaries
as backend inputs.

## Supported package claims

The package directly supports these backend capabilities:

- canonical backend state: `xgeo_state`
- tabular-to-state ingestion: `as_xgeo_state`
- embedding and diagnostic operators for geometry-aware workflows
- multiscale LOD summaries with `build_xgeo_lod`
- selected explanation, point-value, and regular-grid tables
- backend JSON exchange with `write_xgeo_state` and `read_xgeo_state`
- downstream-consumer readiness for packages such as `shapViz3D`,
  `rTDA3D`, and renderer frontends

## Downstream use-case consumers

`XGeoRTR` does not ship use-case-specific presentation assets.
Shapley-specific semantics belong in Shapley-oriented downstream
packages, topology-specific semantics belong in topology-oriented
downstream packages, and display orchestration belongs in renderer
frontends.

What `XGeoRTR` provides is the backend path that downstream consumers
can use:

- [`as_xgeo_state()`](https://fbertran.github.io/XGeoRTR/reference/as_xgeo_state.md)
  standardizes the long tables
- [`set_xgeo_selection()`](https://fbertran.github.io/XGeoRTR/reference/set_xgeo_selection.md)
  controls subset state upstream
- [`xgeo_explanation_table()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_explanation_table.md),
  [`xgeo_point_values()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_point_values.md),
  and
  [`xgeo_regular_grid()`](https://fbertran.github.io/XGeoRTR/reference/xgeo_regular_grid.md)
  expose renderer-neutral tables downstream
- [`compute_xgeo_embedding()`](https://fbertran.github.io/XGeoRTR/reference/compute_xgeo_embedding.md),
  [`compute_xgeo_diagnostics()`](https://fbertran.github.io/XGeoRTR/reference/compute_xgeo_diagnostics.md),
  and
  [`build_xgeo_lod()`](https://fbertran.github.io/XGeoRTR/reference/build_xgeo_lod.md)
  provide optional backend context without taking over presentation
- renderer frontends such as `ggWebGL` can convert `xgeo_state` objects
  or exported backend tables into display-specific WebGL specifications
  without moving rendering responsibilities into `XGeoRTR`

The backend-only example below shows the intended consumption pattern
for a downstream package. If the downstream data source is unavailable,
the same example falls back to the bundled `spatial_demo.csv` so the
backend workflow still runs without a SHAP or renderer dependency.

``` r
source("inst/examples/downstream_shapviz3d_state_tables.R")
```

## Scope

`XGeoRTR` produces backend state and computation products; downstream
packages decide how to present or interact with those products.

- XGeoRTR: backend geometry/state semantics, operators, selected tables,
  and serialization
- Downstream consumers: Shapley presentation, TDA workflows, renderer
  adapters, and front-end interaction

The frozen package boundary is documented in `INTERFACE_FREEZE.md`.
Public `XGeoRTR` objects and serialized payloads must remain free of
display-system fields such as scene, layer, viewport, camera, canvas,
theme, shader, widget, and export surface metadata.
