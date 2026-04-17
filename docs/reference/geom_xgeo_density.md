# Add a density-grid layer

Add a density-grid layer

## Usage

``` r
geom_xgeo_density(
  embedding = NULL,
  bins = 32L,
  color_by = c("count", "mean_value"),
  lod_name = NULL,
  level = NULL,
  alpha = 0.85,
  low_fill = "#F4D35E",
  high_fill = "#EE964B"
)
```

## Arguments

- embedding:

  Optional embedding name. Defaults to the active embedding.

- bins:

  Grid resolution used when no precomputed LOD level is selected.

- color_by:

  Statistic used for cell coloring. One of `"count"` or `"mean_value"`.

- lod_name:

  Optional precomputed LOD bundle name.

- level:

  Optional precomputed level inside `lod_name`.

- alpha:

  Layer alpha.

- low_fill:

  Low-end color.

- high_fill:

  High-end color.

## Value

An `xgeo_layer` object.
