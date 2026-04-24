# Get metadata from an `xgeo_state`

Get metadata from an `xgeo_state`

## Usage

``` r
xgeo_metadata(state)
```

## Arguments

- state:

  An `xgeo_state` object.

## Value

The `metadata` field.

## Examples

``` r
state <- xgeo_state(
  matrix(c(1, 2, 3, 4), nrow = 2),
  metadata = list(source = "demo-state")
)

xgeo_metadata(state)
#> $source
#> [1] "demo-state"
#> 
```
