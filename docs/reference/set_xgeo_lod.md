# Set the active level-of-detail state on a state

Set the active level-of-detail state on a state

## Usage

``` r
set_xgeo_lod(state, name = NULL, level = NULL)
```

## Arguments

- state:

  An `xgeo_state` object.

- name:

  Optional LOD bundle name stored in `state$lod$items`.

- level:

  Optional level inside the selected LOD bundle.

## Value

The updated `xgeo_state`.
