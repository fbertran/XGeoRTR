# Getting Started with XGeoRTR

`XGeoRTR` is a backend-neutral explainable geometry/state package. It
standardizes analytic outputs into `xgeo_state` objects with:

- geometry
- attributes
- indices
- selection
- level-of-detail summaries
- metadata

Rendering is delegated to downstream frontends such as `ggWebGL`.

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
  method = "surface-demo",
  meta = list(source = "synthetic-demo", sample_id = "grid-01")
)

state
#> <xgeo_state>
#>   structure:    spatial
#>   method:       surface-demo
#>   points:       16
#>   features:     16
#>   embeddings:   1 (active: spatial)
#>   diagnostics:  0
#>   lod bundles:  0
summary(state)
#> <summary.xgeo_state>
#>   structure:      spatial
#>   method:         surface-demo
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
#>   method:         surface-demo
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

## Write and reload state

``` r
json_file <- tempfile(fileext = ".json")
write_xgeo_state(state, json_file)
restored <- read_xgeo_state(json_file)

restored$attributes$embeddings$active
#> [1] "pca_points"
```

## Boundary with rendering

`XGeoRTR` does not expose scene/camera/viewport APIs. Renderer-specific
orchestration belongs in downstream rendering packages.
