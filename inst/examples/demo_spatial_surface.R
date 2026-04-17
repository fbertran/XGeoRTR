options(rgl.useNULL = TRUE)

load_xgeort <- function() {
  if (exists("as_xgeo_data", mode = "function")) {
    return(invisible(NULL))
  }

  if (requireNamespace("XGeoRTR", quietly = TRUE)) {
    library(XGeoRTR)
    return(invisible(NULL))
  }

  if (requireNamespace("pkgload", quietly = TRUE) && file.exists("DESCRIPTION")) {
    pkgload::load_all(".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
    return(invisible(NULL))
  }

  stop("XGeoRTR is not available. Install the package or run from the repo with pkgload.")
}

demo_path <- function() {
  installed <- system.file("extdata", "spatial_demo.csv", package = "XGeoRTR")
  if (nzchar(installed)) {
    return(installed)
  }

  local <- file.path("inst", "extdata", "spatial_demo.csv")
  if (file.exists(local)) {
    return(local)
  }

  stop("Could not locate spatial_demo.csv.")
}

save_optional_html <- function(scene, stem) {
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    cat("htmlwidgets not installed; skipping HTML export.\n")
    return(invisible(NULL))
  }

  out_file <- file.path(tempdir(), paste0(stem, ".html"))
  render_webgl(scene, file = out_file, selfcontained = FALSE, open = FALSE)
  cat("Saved HTML:", out_file, "\n")
  invisible(out_file)
}

load_xgeort()

demo_tbl <- utils::read.csv(
  demo_path(),
  stringsAsFactors = FALSE
)

xd <- as_xgeo_data(
  demo_tbl,
  x_col = "x",
  y_col = "y",
  z_col = "z",
  value_col = "value",
  feature_col = "feature",
  method = "surface-demo",
  meta = list(source = "synthetic-demo", sample_id = "grid-01")
)

cat("== XGeoRTR platform demo ==\n")
print(summary(xd))

surface_scene <- xgeo_scene(xd, camera = list(preset = "top")) +
  geom_xgeo_surface(alpha = 0.72, smooth = TRUE)

platform_scene <- xgeo_scene(xd, camera = list(preset = "top"))
platform_scene <- compute_xgeo_embedding(platform_scene, method = "pca", source = "points", dims = 2)
platform_scene <- set_active_embedding(platform_scene, "pca_points")
platform_scene <- compute_xgeo_diagnostics(
  platform_scene,
  embedding = "pca_points",
  source = "points",
  k = 3
)
platform_scene <- build_xgeo_lod(
  platform_scene,
  embedding = "pca_points",
  levels = c(8L, 16L),
  auto_threshold = 10L
)
point_scene <- platform_scene + geom_xgeo_points(color_by = "local_agreement", size = 8)

invisible(render_webgl(surface_scene, open = FALSE))
cat("\nRendered surface scene headlessly.\n")
invisible(render_webgl(point_scene, lod_level = "auto", open = FALSE))
cat("Rendered point-cloud scene with automatic density LOD headlessly.\n")

json_file <- file.path(tempdir(), "xgeort-demo-scene.json")
write_xgeo_scene(point_scene, json_file)
cat("Saved scene JSON:", json_file, "\n")

save_optional_html(surface_scene, "xgeort-demo-surface")
save_optional_html(point_scene, "xgeort-demo-points")
try(rgl::close3d(), silent = TRUE)
