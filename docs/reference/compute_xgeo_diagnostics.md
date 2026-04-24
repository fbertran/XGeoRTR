# Compute embedding diagnostics for a state

Compute embedding diagnostics for a state

## Usage

``` r
compute_xgeo_diagnostics(
  state,
  embedding = NULL,
  source = c("explanations", "point_meta", "points"),
  k = 10L,
  name = NULL
)
```

## Arguments

- state:

  An `xgeo_state` object.

- embedding:

  Optional embedding name. Defaults to the active embedding.

- source:

  Reference source space used for neighbour comparisons.

- k:

  Number of neighbours.

- name:

  Optional diagnostic bundle name.

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
state <- compute_xgeo_diagnostics(
  state,
  embedding = "pca_explanations",
  source = "explanations",
  k = 1
)

names(state$attributes$diagnostics$items)
#> [1] "diagnostics_pca_explanations_explanations"
```
