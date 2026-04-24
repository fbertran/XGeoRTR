# Build density-grid LOD summaries for a state

Build density-grid LOD summaries for a state

## Usage

``` r
build_xgeo_lod(
  state,
  embedding = NULL,
  levels = c(16L, 32L, 64L),
  color_by = c("count", "mean_value"),
  name = NULL,
  auto_threshold = 200L
)
```

## Arguments

- state:

  An `xgeo_state` object.

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

The updated `xgeo_state`.

## Examples

``` r
state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
state <- build_xgeo_lod(state, levels = c(4L, 8L), auto_threshold = 2L)

names(state$lod$items)
#> [1] "density_grid_spatial"
```
