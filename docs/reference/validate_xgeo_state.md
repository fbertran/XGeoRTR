# Validate an `xgeo_state` object

Validate an `xgeo_state` object

## Usage

``` r
validate_xgeo_state(x)
```

## Arguments

- x:

  An object to validate.

## Value

`x`, invisibly, when validation succeeds.

## Examples

``` r
state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))

validate_xgeo_state(state)
```
