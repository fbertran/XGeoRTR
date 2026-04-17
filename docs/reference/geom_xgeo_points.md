# Add a point-cloud layer

Add a point-cloud layer

## Usage

``` r
geom_xgeo_points(
  embedding = NULL,
  size = 8,
  alpha = 0.85,
  color_by = "value",
  low_fill = "#2166AC",
  mid_fill = "#F7F7F7",
  high_fill = "#B2182B"
)
```

## Arguments

- embedding:

  Optional embedding name. Defaults to the active embedding.

- size:

  Point size passed to
  [`rgl::points3d()`](https://dmurdoch.github.io/rgl/dev/reference/primitives.html).

- alpha:

  Point alpha.

- color_by:

  Point-level numeric field used for coloring.

- low_fill:

  Low-end color.

- mid_fill:

  Midpoint color.

- high_fill:

  High-end color.

## Value

An `xgeo_layer` object.
