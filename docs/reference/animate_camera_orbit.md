# Attach orbit animation metadata to a scene

Attach orbit animation metadata to a scene

## Usage

``` r
animate_camera_orbit(scene, frames = 36L, axis = "z", step = 5)
```

## Arguments

- scene:

  An `xgeo_scene` object.

- frames:

  Number of animation frames.

- axis:

  Rotation axis. One of `"x"`, `"y"`, or `"z"`.

- step:

  Degrees per frame.

## Value

The updated `xgeo_scene`.
