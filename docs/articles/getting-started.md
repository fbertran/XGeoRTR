# Getting Started with XGeoRTR

`XGeoRTR` is the general platform package for the current spatial-only
release. It owns the neutral explanation object, scene abstraction,
embeddings, diagnostics, multiscale summaries, selection state, and
`rgl` / WebGL export path.

The current release includes:

- one neutral data object: `xgeo_data`
- one composable scene container:
  [`xgeo_scene()`](../reference/xgeo_scene.md)
- one embedding path:
  [`compute_xgeo_embedding()`](../reference/compute_xgeo_embedding.md)
- one diagnostic path:
  [`compute_xgeo_diagnostics()`](../reference/compute_xgeo_diagnostics.md)
- one density-grid LOD path:
  [`build_xgeo_lod()`](../reference/build_xgeo_lod.md)
- three generic views:
  [`geom_xgeo_surface()`](../reference/geom_xgeo_surface.md),
  [`geom_xgeo_points()`](../reference/geom_xgeo_points.md), and
  [`geom_xgeo_density()`](../reference/geom_xgeo_density.md)
- one export path: [`render_webgl()`](../reference/render_webgl.md) plus
  JSON scene IO

## Create an `xgeo_data` object

``` r
library(XGeoRTR)

demo_path <- system.file("extdata", "spatial_demo.csv", package = "XGeoRTR")
demo_tbl <- utils::read.csv(demo_path, stringsAsFactors = FALSE)

xd <- as_xgeo_data(
  demo_tbl,
  x_col = "x",
  y_col = "y",
  z_col = "z",
  value_col = "value",
  feature_col = "feature",
  method = "surface-demo",
  meta = list(source = "synthetic-demo", sample_id = "grid-01")
)

xd
#> <xgeo_data>
#>   structure:    spatial
#>   method:       surface-demo
#>   points:       16
#>   explanations: 16
#>   features:     16
#>   value range:  [-0.910, 1.150]
summary(xd)
#> <summary.xgeo_data>
#>   structure:    spatial
#>   method:       surface-demo
#>   points:       16
#>   explanations: 16
#>   features:     16
#>   range:        [-0.910, 1.150]
```

## Build a scene and attach platform state

``` r
scene <- xgeo_scene(xd, camera = list(preset = "top"))
scene <- compute_xgeo_embedding(scene, method = "pca", source = "points", dims = 2)
scene <- set_active_embedding(scene, "pca_points")
scene <- compute_xgeo_diagnostics(scene, embedding = "pca_points", source = "points", k = 3)
scene <- build_xgeo_lod(scene, embedding = "pca_points", levels = c(8L, 16L), auto_threshold = 10L)

scene
#> <xgeo_scene>
#>   backend:      rgl
#>   layers:       0
#>   embeddings:   2 (active: pca_points)
#>   diagnostics:  1
#>   lod bundles:  1
#>   camera:       top
```

## Render point, density, and surface views

Rendering requires `rgl`. Saving to an HTML file also requires
`htmlwidgets`.

``` r
point_scene <- scene + geom_xgeo_points(color_by = "local_agreement", size = 8)
density_scene <- scene + geom_xgeo_density(lod_name = "density_grid_pca_points", level = "16")
surface_scene <- xgeo_scene(xd, camera = list(preset = "top")) +
  geom_xgeo_surface(alpha = 0.7, smooth = TRUE)

render_webgl(point_scene, lod_level = "auto")
render_webgl(density_scene)
render_webgl(surface_scene)

outfile <- tempfile(fileext = ".html")
render_webgl(point_scene, file = outfile, selfcontained = FALSE)
```

## Write and reload scene state

``` r
json_file <- tempfile(fileext = ".json")
write_xgeo_scene(point_scene, json_file)
restored <- read_xgeo_scene(json_file)
```

## Platform position

`XGeoRTR` is the substrate for explanation packages: it owns the parts
that still make sense outside SHAP semantics:

- generic ingestion with metadata preservation
- scene composition and explicit selection state
- embeddings and diagnostics
- multiscale density summaries
- generic point, density, and surface rendering
- HTML and JSON export/import

SHAP-specific semantics and layouts continue to belong in `shapViz3D`.
