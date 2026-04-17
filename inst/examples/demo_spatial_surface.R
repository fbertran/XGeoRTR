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
    cat("htmlwidgets not installed; skipping HTML export.
")
    return(invisible(NULL))
  }

  out_file <- file.path(tempdir(), paste0(stem, ".html"))
  render_webgl(scene, file = out_file, selfcontained = FALSE, open = FALSE)
  cat("Saved HTML:", out_file, "
")
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

cat("== Generic spatial surface demo ==
")
print(summary(xd))

scene <- xgeo_scene(xd, camera = list(preset = "top")) +
  geom_xgeo_surface(alpha = 0.72, smooth = TRUE)

invisible(render_webgl(scene, open = FALSE))
cat("
Rendered generic surface scene headlessly.
")
save_optional_html(scene, "xgeort-demo-surface")
try(rgl::close3d(), silent = TRUE)
