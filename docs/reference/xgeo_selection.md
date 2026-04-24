# Get selection from an `xgeo_state`

Get selection from an `xgeo_state`

## Usage

``` r
xgeo_selection(state)
```

## Arguments

- state:

  An `xgeo_state` object.

## Value

The `selection` field.

## Examples

``` r
state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))
state <- set_xgeo_selection(state, point_ids = state$indices$point_ids[[1]])

xgeo_selection(state)
#> $point_ids
#> [1] "point_1"
#> 
#> $features
#> character(0)
#> 
```
