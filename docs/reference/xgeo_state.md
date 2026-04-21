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
