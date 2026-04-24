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

## Examples

``` r
xgeo_regular_grid(
  data.frame(
    x_coord = c(0, 1, 0, 1),
    y_coord = c(0, 0, 1, 1),
    score = c(1, 2, 3, 4)
  ),
  x = "x_coord",
  y = "y_coord",
  value = "score"
)
#> $x
#> [1] 0 1
#> 
#> $y
#> [1] 0 1
#> 
#> $z
#>      [,1] [,2]
#> [1,]    1    3
#> [2,]    2    4
#> 
```
