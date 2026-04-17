# Compute embedding diagnostics for a scene

Compute embedding diagnostics for a scene

## Usage

``` r
compute_xgeo_diagnostics(
  scene,
  embedding = NULL,
  source = c("explanations", "point_meta", "points"),
  k = 10L,
  name = NULL
)
```

## Arguments

- scene:

  An `xgeo_scene` object.

- embedding:

  Optional embedding name. Defaults to the active embedding.

- source:

  Reference source space used for neighbour comparisons.

- k:

  Number of neighbours.

- name:

  Optional diagnostic bundle name.

## Value

The updated `xgeo_scene`.
