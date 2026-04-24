# Write a backend state to JSON

Write a backend state to JSON

## Usage

``` r
write_xgeo_state(state, path, pretty = TRUE)
```

## Arguments

- state:

  An `xgeo_state` object.

- path:

  Output file path.

- pretty:

  Whether to pretty-print the JSON.

## Value

The normalized output path, invisibly.

## Examples

``` r
state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
path <- tempfile(fileext = ".json")

write_xgeo_state(state, path)
file.exists(path)
#> [1] TRUE
```
