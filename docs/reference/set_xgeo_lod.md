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

## Examples

``` r
state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
state <- build_xgeo_lod(state, levels = c(4L, 8L), auto_threshold = 2L)
state <- set_xgeo_lod(state, name = "density_grid_spatial", level = "4")

state$lod$active
#> $name
#> [1] "density_grid_spatial"
#> 
#> $level
#> [1] "4"
#> 
```
