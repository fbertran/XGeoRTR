# Render an `xgeo_scene` to `rgl` / WebGL

Render an `xgeo_scene` to `rgl` / WebGL

## Usage

``` r
render_webgl(
  scene,
  lod_level = NULL,
  file = NULL,
  selfcontained = FALSE,
  open = interactive()
)
```

## Arguments

- scene:

  An `xgeo_scene` object.

- lod_level:

  Optional LOD selector. Use `"auto"` to switch point layers to the
  active density bundle when the point threshold is exceeded.

- file:

  Optional HTML output path. When supplied, `htmlwidgets` is used to
  save an `rglwidget`.

- selfcontained:

  Passed to
  [`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html).

- open:

  Whether to open a visible device. When `FALSE`, `rgl` renders to a
  null device when possible.

## Value

An `rglwidget`, an output file path, or the rendered scene invisibly.
