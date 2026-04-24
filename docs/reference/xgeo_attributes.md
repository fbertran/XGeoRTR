# Get attributes from an `xgeo_state`

Get attributes from an `xgeo_state`

## Usage

``` r
xgeo_attributes(state)
```

## Arguments

- state:

  An `xgeo_state` object.

## Value

The `attributes` field.

## Examples

``` r
state <- xgeo_state(matrix(c(1, 2, 3, 4), nrow = 2))

names(xgeo_attributes(state))
#>  [1] "explanations" "point_meta"   "feature_meta" "predictions"  "uncertainty" 
#>  [6] "embeddings"   "diagnostics"  "baseline"     "method"       "structure"   
```
