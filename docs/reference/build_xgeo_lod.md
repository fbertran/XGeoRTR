# Build density-grid LOD summaries for a scene

Build density-grid LOD summaries for a scene

## Usage

``` r
build_xgeo_lod(
  scene,
  embedding = NULL,
  levels = c(16L, 32L, 64L),
  color_by = c("count", "mean_value"),
  name = NULL,
  auto_threshold = 200L
)
```

## Arguments

- scene:

  An `xgeo_scene` object.

- embedding:

  Optional embedding name. Defaults to the active embedding.

- levels:

  Integer vector of grid resolutions.

- color_by:

  Statistic stored in each density grid.

- name:

  Optional LOD bundle name.

- auto_threshold:

  Point count threshold used by `lod_level = "auto"`.

## Value

The updated `xgeo_scene`.
