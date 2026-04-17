# Create a normalized `xgeo_data` object

Create a normalized `xgeo_data` object

## Usage

``` r
new_xgeo_data(
  points,
  explanations,
  point_meta = NULL,
  feature_meta = NULL,
  predictions = NULL,
  uncertainty = NULL,
  baseline = NULL,
  structure = "spatial",
  method = "generic",
  meta = list()
)
```

## Arguments

- points:

  Point table with `point_id`, `x`, `y`, and optional `z`.

- explanations:

  Explanation table with `point_id`, `feature`, and `value`.

- point_meta:

  Optional point-level metadata keyed by `point_id`.

- feature_meta:

  Optional feature-level metadata keyed by `feature`.

- predictions:

  Optional point-level predictions keyed by `point_id`.

- uncertainty:

  Optional point-level uncertainty keyed by `point_id`.

- baseline:

  Optional numeric scalar reference value.

- structure:

  Structure name for the object. The current release supports only
  `"spatial"`.

- method:

  Method label for the explanations represented in the object.

- meta:

  Optional metadata list.

## Value

An object of class `xgeo_data`.
