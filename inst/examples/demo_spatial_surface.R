load_xgeort <- function() {
  if (exists("as_xgeo_state", mode = "function")) {
    return(invisible(NULL))
  }

  if (requireNamespace("pkgload", quietly = TRUE) && file.exists("DESCRIPTION")) {
    pkgload::load_all(".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
    return(invisible(NULL))
  }

  if (requireNamespace("XGeoRTR", quietly = TRUE)) {
    library(XGeoRTR)
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

load_xgeort()

demo_tbl <- utils::read.csv(
  demo_path(),
  stringsAsFactors = FALSE
)

state <- as_xgeo_state(
  demo_tbl,
  x_col = "x",
  y_col = "y",
  z_col = "z",
  value_col = "value",
  feature_col = "feature",
  method = "surface-demo",
  meta = list(source = "synthetic-demo", sample_id = "grid-01")
)

cat("== XGeoRTR backend-state demo ==\n")
print(summary(state))

state <- compute_xgeo_embedding(state, method = "pca", source = "points", dims = 2)
state <- set_active_embedding(state, "pca_points")
state <- compute_xgeo_diagnostics(
  state,
  embedding = "pca_points",
  source = "points",
  k = 3
)
state <- build_xgeo_lod(
  state,
  embedding = "pca_points",
  levels = c(8L, 16L),
  auto_threshold = 10L
)
state <- set_xgeo_selection(state, point_ids = state$indices$point_ids[[1]])

cat("\nComputed embeddings, diagnostics, LOD, and selection.\n")

json_file <- file.path(tempdir(), "xgeort-demo-state.json")
write_xgeo_state(state, json_file)
cat("Saved state JSON:", json_file, "\n")

restored_state <- read_xgeo_state(json_file)
cat("Restored active embedding:", restored_state$attributes$embeddings$active, "\n")
