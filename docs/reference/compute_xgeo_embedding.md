# Compute and attach a platform embedding

Compute and attach a platform embedding

## Usage

``` r
compute_xgeo_embedding(
  state,
  source = c("explanations", "point_meta", "points"),
  method = c("pca", "umap"),
  dims = 2L,
  name = NULL,
  ...
)
```

## Arguments

- state:

  An `xgeo_state` object.

- source:

  Source matrix used to build the embedding. One of `"explanations"`,
  `"point_meta"`, or `"points"`.

- method:

  Embedding backend. `"pca"` is always available; `"umap"` requires
  `uwot`.

- dims:

  Number of output dimensions.

- name:

  Optional embedding name. Defaults to `<method>_<source>`.

- ...:

  Passed to backend-specific implementations.

## Value

The updated `xgeo_state`.
