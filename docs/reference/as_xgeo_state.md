# Coerce inputs to `xgeo_state`

Coerce inputs to `xgeo_state`

## Usage

``` r
as_xgeo_state(x, ...)
```

## Arguments

- x:

  An object to coerce.

- ...:

  Passed to method-specific implementations.

## Value

An `xgeo_state` object.

## Examples

``` r
as_xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
#> <xgeo_state>
#>   structure:    spatial
#>   method:       generic
#>   points:       4
#>   features:     1
#>   embeddings:   1 (active: spatial)
#>   diagnostics:  0
#>   lod bundles:  0

as_xgeo_state(
  data.frame(
    point_id = c("p1", "p1", "p2"),
    feature = c("f1", "f2", "f1"),
    x = c(0, 0, 1),
    y = c(0, 0, 1),
    value = c(1, -0.5, 0.75)
  )
)
#> <xgeo_state>
#>   structure:    spatial
#>   method:       generic
#>   points:       2
#>   features:     2
#>   embeddings:   1 (active: spatial)
#>   diagnostics:  0
#>   lod bundles:  0
```
