# Create an `xgeo_state`

Create an `xgeo_state`

## Usage

``` r
xgeo_state(
  x,
  embeddings = NULL,
  diagnostics = NULL,
  lod = NULL,
  selection = NULL,
  metadata = list()
)
```

## Arguments

- x:

  A matrix, data frame, or object coercible to backend geometry state.

- embeddings:

  Optional embedding state.

- diagnostics:

  Optional diagnostic state.

- lod:

  Optional level-of-detail state.

- selection:

  Optional explicit selection state.

- metadata:

  Optional state metadata.

## Value

An `xgeo_state` object.

## Examples

``` r
# Matrix input is converted into a backend regular grid state.
xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
#> <xgeo_state>
#>   structure:    spatial
#>   method:       generic
#>   points:       4
#>   features:     1
#>   embeddings:   1 (active: spatial)
#>   diagnostics:  0
#>   lod bundles:  0

# Long-tabular input preserves point ids and feature ids.
xgeo_state(
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
