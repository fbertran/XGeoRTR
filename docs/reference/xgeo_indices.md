# Get indices from an `xgeo_state`

Get indices from an `xgeo_state`

## Usage

``` r
xgeo_indices(state)
```

## Arguments

- state:

  An `xgeo_state` object.

## Value

The `indices` field.

## Examples

``` r
state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))

xgeo_indices(state)
#> $point_ids
#> [1] "point_1" "point_2" "point_3" "point_4"
#> 
#> $feature_ids
#> [1] "value"
#> 
```
