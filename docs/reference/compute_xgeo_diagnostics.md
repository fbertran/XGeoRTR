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
