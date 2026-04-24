# Aggregate explanation values per point

`xgeo_point_values()` exposes a selected, renderer-neutral point table
with coordinates, aggregated explanation values, and point-level
metadata.

## Usage

``` r
xgeo_point_values(state, aggregate = sum, selected = TRUE)
```

## Arguments

- state:

  An `xgeo_state` object.

- aggregate:

  Aggregation function applied across selected features per point.
  Defaults to `sum`.

- selected:

  Whether to apply the state's point and feature selection.

## Value

A data frame containing `point_id`, `x`, `y`, `z`, `value`, and any
point-, prediction-, or uncertainty-level metadata.

## Examples

``` r
state <- as_xgeo_state(
  data.frame(
    point_id = c("p1", "p1", "p2", "p2"),
    feature = c("f1", "f2", "f1", "f2"),
    x = c(0, 0, 1, 1),
    y = c(0, 0, 1, 1),
    value = c(1, -0.25, 0.75, 2),
    cluster = c("A", "A", "B", "B")
  ),
  point_id_col = "point_id",
  feature_col = "feature"
)
state <- set_xgeo_selection(state, features = "f1")

xgeo_point_values(state)
#>   point_id x y z value cluster
#> 1       p1 0 0 0  1.00       A
#> 2       p2 1 1 0  0.75       B
```
