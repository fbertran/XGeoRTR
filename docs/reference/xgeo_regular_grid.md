# Validate and normalize regular-grid data

`xgeo_regular_grid()` validates a complete 2D regular grid and returns
the grid vectors and value matrix without creating a renderer-specific
object.

## Usage

``` r
xgeo_regular_grid(data, x = "x", y = "y", value = "value")
```

## Arguments

- data:

  A data frame containing x, y, and value columns.

- x:

  Name of the x-coordinate column.

- y:

  Name of the y-coordinate column.

- value:

  Name of the value column.

## Value

A list with `x`, `y`, and `z`, where `z` is a value matrix indexed by
the returned x and y coordinates.
