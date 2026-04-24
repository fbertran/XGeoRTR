# Getting Started with XGeoRTR

`XGeoRTR` is explainable geometry backend infrastructure for workflows
that need portable analytic state. It standardizes analytic outputs into
`xgeo_state` objects with:

- geometry
- attributes
- indices
- selection
- level-of-detail summaries
- selected backend tables
- metadata

Packages such as `shapViz3D`, `rTDA3D`, and renderer frontends consume
this backend state downstream. XGeoRTR does not include use-case
presentation code or front-end adapters.

## Create an `xgeo_state`

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

state
#> <xgeo_state>
#>   structure:    spatial
#>   method:       spatial-field-demo
#>   points:       16
#>   features:     16
#>   embeddings:   1 (active: spatial)
#>   diagnostics:  0
#>   lod bundles:  0
summary(state)
#> <summary.xgeo_state>
#>   structure:      spatial
#>   method:         spatial-field-demo
#>   points:         16
#>   features:       16
#>   explanations:   16
#>   embeddings:     1 (active: spatial)
#>   diagnostics:    0 (active: none)
#>   lod bundles:    0 (active: none)
#>   selected points:0
#>   selected feats: 0
```

## Compute backend state operators

``` r
state <- compute_xgeo_embedding(state, method = "pca", source = "points", dims = 2)
state <- set_active_embedding(state, "pca_points")
state <- compute_xgeo_diagnostics(state, embedding = "pca_points", source = "points", k = 3)
state <- build_xgeo_lod(state, embedding = "pca_points", levels = c(8L, 16L), auto_threshold = 10L)
state <- set_xgeo_selection(state, point_ids = state$indices$point_ids[[1]])

summary(state)
#> <summary.xgeo_state>
#>   structure:      spatial
#>   method:         spatial-field-demo
#>   points:         16
#>   features:       16
#>   explanations:   16
#>   embeddings:     2 (active: pca_points)
#>   diagnostics:    1 (active: diagnostics_pca_points_points)
#>   lod bundles:    1 (active: density_grid_pca_points)
#>   selected points:1
#>   selected feats: 0
```

## Access backend-neutral fields

``` r
names(xgeo_geometry(state))
#> [1] "points"
names(xgeo_attributes(state))
#>  [1] "explanations" "point_meta"   "feature_meta" "predictions"  "uncertainty" 
#>  [6] "embeddings"   "diagnostics"  "baseline"     "method"       "structure"
names(xgeo_indices(state))
#> [1] "point_ids"   "feature_ids"
xgeo_selection(state)
#> $point_ids
#> [1] "point_1"
#> 
#> $features
#> character(0)
names(xgeo_metadata(state))
#> [1] "source"    "sample_id"
```

## Build selected backend tables

``` r
long_tbl <- xgeo_explanation_table(state)
point_tbl <- xgeo_point_values(state)
grid <- xgeo_regular_grid(point_tbl)

utils::head(long_tbl)
#>   point_id  feature value x y z    label
#> 1  point_1 cell_1_1  0.65 1 1 0 cell_1_1
utils::head(point_tbl)
#>   point_id x y z value
#> 1  point_1 1 1 0  0.65
names(grid)
#> [1] "x" "y" "z"
```

Downstream use-case packages should consume these public tables rather
than internal ingestion objects.

## Downstream consumers

`shapViz3D` can consume explanation and point-value tables for
Shapley-oriented workflows. `rTDA3D` can consume point and grid
summaries for topology-oriented workflows. Renderer frontends can
consume `xgeo_state` through their own adapter contracts. Those packages
own presentation, interaction, and front-end behavior.

## Downstream figure consumers

`XGeoRTR` stops at backend state and backend tables. The canonical
selected figure assets for the SHAP workflow live downstream in
`shapViz3D`, where the SHAP semantics and figure selection logic are
owned.

The backend-only example below shows the intended consumption pattern:

``` r
source("inst/examples/downstream_shapviz3d_state_tables.R")
```

When the sibling `shapViz3D` repository is available, that example reads
the three deterministic evidence CSVs from `shapViz3D`, builds
`xgeo_state` objects, applies selection, computes optional
embedding/diagnostic/LOD state, and emits only backend tables. When the
downstream repo is unavailable, it falls back to the bundled
`spatial_demo.csv` so the example still runs without renderer or
SHAP-package dependencies.

## Write and reload state

``` r
json_file <- tempfile(fileext = ".json")
write_xgeo_state(state, json_file)
restored <- read_xgeo_state(json_file)

restored$attributes$embeddings$active
#> [1] "pca_points"
```

## Package boundary

`XGeoRTR` exposes backend state, derived tables, and serialized state
exchange. It does not expose scene/camera/viewport APIs or
renderer-specific orchestration.
