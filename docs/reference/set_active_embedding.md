# Set the active embedding on a state

Set the active embedding on a state

## Usage

``` r
set_active_embedding(state, name)
```

## Arguments

- state:

  An `xgeo_state` object.

- name:

  Name of an embedding stored in `state$attributes$embeddings$items`.

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
state <- set_active_embedding(state, "pca_explanations")

state$attributes$embeddings$active
#> [1] "pca_explanations"
```
