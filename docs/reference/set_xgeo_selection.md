# Set explicit point and feature selection on a state

Set explicit point and feature selection on a state

## Usage

``` r
set_xgeo_selection(state, point_ids = NULL, features = NULL)
```

## Arguments

- state:

  An `xgeo_state` object.

- point_ids:

  Optional character vector of selected point ids.

- features:

  Optional character vector of selected feature ids.

## Value

The updated `xgeo_state`.

## Examples

``` r
state <- as_xgeo_state(
  data.frame(
    point_id = c("p1", "p1", "p2", "p2"),
    feature = c("f1", "f2", "f1", "f2"),
    x = c(0, 0, 1, 1),
    y = c(0, 0, 1, 1),
    value = c(1, -0.25, 0.75, 2)
  ),
  point_id_col = "point_id",
  feature_col = "feature"
)
state <- set_xgeo_selection(state, point_ids = "p1", features = "f2")

xgeo_selection(state)
#> $point_ids
#> [1] "p1"
#> 
#> $features
#> [1] "f2"
#> 
```
