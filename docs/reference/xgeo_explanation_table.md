# Build a long explanation table from backend state

`xgeo_explanation_table()` exposes the selected explanation records
together with point coordinates and metadata. It is renderer-agnostic
and contains no use-case-specific presentation semantics.

## Usage

``` r
xgeo_explanation_table(state, selected = TRUE)
```

## Arguments

- state:

  An `xgeo_state` object.

- selected:

  Whether to apply the state's point and feature selection.

## Value

A data frame containing `point_id`, `feature`, `value`, `x`, `y`, `z`,
and any point-, feature-, prediction-, or uncertainty-level metadata.

## Examples

``` r
state <- as_xgeo_state(
  data.frame(
    point_id = c("p1", "p1", "p2"),
    feature = c("f1", "f2", "f1"),
    x = c(0, 0, 1),
    y = c(0, 0, 1),
    value = c(1, -0.5, 0.75),
    cluster = c("A", "A", "B")
  ),
  point_id_col = "point_id",
  feature_col = "feature"
)

xgeo_explanation_table(state)
#>   point_id feature value x y z label cluster
#> 1       p1      f1  1.00 0 0 0    f1       A
#> 2       p1      f2 -0.50 0 0 0    f2       A
#> 3       p2      f1  0.75 1 1 0    f1       B
```
