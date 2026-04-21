# Save a static snapshot of an `xgeo_scene` when available

Save a static snapshot of an `xgeo_scene` when available

## Usage

``` r
snapshot_webgl(
  scene,
  file,
  lod_level = NULL,
  open = FALSE,
  webshot = FALSE,
  selfcontained = FALSE,
  html_fallback = TRUE,
  placeholder = TRUE,
  width = NULL,
  height = NULL
)
```

## Arguments

- scene:

  An `xgeo_scene` object.

- file:

  Output PNG path.

- lod_level:

  Optional LOD selector passed to [`render_webgl()`](render_webgl.md).

- open:

  Whether to open a visible device.

- webshot:

  Whether to allow `snapshot3d()` to use a webshot-based path.

- selfcontained:

  Passed to the HTML fallback export when used.

- html_fallback:

  Whether to also export an interactive HTML scene next to the PNG when
  static snapshots are unavailable.

- placeholder:

  Whether to create a placeholder PNG when no static snapshot backend is
  available.

- width:

  Optional snapshot width.

- height:

  Optional snapshot height.

## Value

The normalized PNG path, invisibly.
