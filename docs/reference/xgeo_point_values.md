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
