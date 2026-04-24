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

## Examples

``` r
state <- as_xgeo_state(
  data.frame(
    point_id = rep(paste0("p", 1:4), each = 2),
    feature = rep(c("f1", "f2"), times = 4),
    x = c(0, 0, 1, 1, 0, 0, 1, 1),
    y = c(0, 0, 0, 0, 1, 1, 1, 1),
    value = c(0.2, 0.7, 0.4, 0.1, 0.8, 0.6, 0.5, 0.3)
  ),
  point_id_col = "point_id",
  feature_col = "feature"
)
state <- compute_xgeo_embedding(state, method = "pca", source = "explanations", dims = 2)

names(state$attributes$embeddings$items)
#> [1] "spatial"          "pca_explanations"
```
