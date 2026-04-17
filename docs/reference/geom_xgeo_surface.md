# Add a generic surface layer

Add a generic surface layer

## Usage

``` r
geom_xgeo_surface(
  feature = NULL,
  scaling = 1,
  alpha = 0.7,
  smooth = FALSE,
  low_fill = "#20639B",
  high_fill = "#D1495B"
)
```

## Arguments

- feature:

  Optional feature subset to aggregate before rendering.

- scaling:

  Vertical scale multiplier for explanation values.

- alpha:

  Surface alpha.

- smooth:

  Whether to apply a simple neighborhood average before rendering.

- low_fill:

  Color used near the lower value range.

- high_fill:

  Color used near the upper value range.

## Value

An `xgeo_layer` object.
