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
