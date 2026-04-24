# Get geometry from an `xgeo_state`

Get geometry from an `xgeo_state`

## Usage

``` r
xgeo_geometry(state)
```

## Arguments

- state:

  An `xgeo_state` object.

## Value

The `geometry` field.

## Examples

``` r
state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))

xgeo_geometry(state)$points
#>   point_id x y z
#> 1  point_1 1 1 0
#> 2  point_2 2 1 0
#> 3  point_3 1 2 0
#> 4  point_4 2 2 0
```
