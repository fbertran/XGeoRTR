# Read a backend state from JSON

Read a backend state from JSON

## Usage

``` r
read_xgeo_state(path)
```

## Arguments

- path:

  Path to a JSON state file.

## Value

An `xgeo_state` object.

## Examples

``` r
state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
path <- tempfile(fileext = ".json")
write_xgeo_state(state, path)

restored <- read_xgeo_state(path)
class(restored)
#> [1] "xgeo_state"
```
