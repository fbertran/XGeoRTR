# Set the active level-of-detail state on a scene

Set the active level-of-detail state on a scene

## Usage

``` r
set_xgeo_lod(scene, name = NULL, level = NULL)
```

## Arguments

- scene:

  An `xgeo_scene` object.

- name:

  Optional LOD bundle name stored in `scene$lod$items`.

- level:

  Optional level inside the selected LOD bundle.

## Value

The updated `xgeo_scene`.
