# Create an `xgeo_scene`

Create an `xgeo_scene`

## Usage

``` r
xgeo_scene(
  x,
  embeddings = NULL,
  diagnostics = NULL,
  lod = NULL,
  views = NULL,
  selection = NULL,
  camera = list(preset = "isometric"),
  theme = list(background = "white"),
  render_backend = "rgl",
  meta = list()
)
```

## Arguments

- x:

  A `xgeo_data` object or an object coercible to `xgeo_data`.

- embeddings:

  Optional embedding state.

- diagnostics:

  Optional diagnostic state.

- lod:

  Optional level-of-detail state.

- views:

  Optional named view registry.

- selection:

  Optional explicit selection state.

- camera:

  Named list of camera options. The MVP currently uses a `preset` entry
  such as `"isometric"`, `"top"`, or `"side"`.

- theme:

  Named list of theme options.

- render_backend:

  Rendering backend. The MVP supports only `"rgl"`.

- meta:

  Optional scene metadata.

## Value

An `xgeo_scene` object.
