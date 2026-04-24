load_backend_demo_package <- function() {
  if (exists("as_xgeo_state", mode = "function")) {
    return(invisible(TRUE))
  }

  if (requireNamespace("XGeoRTR", quietly = TRUE)) {
    library(XGeoRTR)
    return(invisible(TRUE))
  }

  if (requireNamespace("pkgload", quietly = TRUE) && file.exists("DESCRIPTION")) {
    pkgload::load_all(".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
    library(XGeoRTR)
    return(invisible(TRUE))
  }

  stop("XGeoRTR is not available. Install the package or run from the repo with pkgload.")
}

locate_shapviz3d_case_files <- function() {
  manifest <- data.frame(
    case_id = c("diffusion", "neural_rendering", "digital_twin"),
    file_name = c(
      "package_user_diffusion_slice.csv",
      "package_user_neural_rendering_view.csv",
      "package_user_digital_twin_floor_map.csv"
    ),
    stringsAsFactors = FALSE
  )

  env_root <- Sys.getenv("SHAPVIZ3D_ROOT", unset = NA_character_)
  candidate_roots <- c(
    if (!is.na(env_root)) env_root else character(),
    normalizePath("../shapViz3D", winslash = "/", mustWork = FALSE),
    normalizePath(file.path(getwd(), "..", "shapViz3D"), winslash = "/", mustWork = FALSE)
  )
  candidate_roots <- unique(candidate_roots[file.exists(candidate_roots)])

  for (root in candidate_roots) {
    extdata_dir <- file.path(root, "inst", "extdata")
    files <- file.path(extdata_dir, manifest$file_name)
    if (all(file.exists(files))) {
      manifest$path <- files
      manifest$source <- "sibling_shapViz3D_repo"
      return(manifest)
    }
  }

  fallback <- system.file("extdata", "spatial_demo.csv", package = "XGeoRTR")
  if (fallback == "") {
    fallback <- file.path("inst", "extdata", "spatial_demo.csv")
  }

  manifest <- data.frame(
    case_id = "fallback_spatial_demo",
    file_name = basename(fallback),
    path = fallback,
    source = "bundled_xgeort_demo",
    stringsAsFactors = FALSE
  )
  manifest
}

build_downstream_state <- function(path, case_id, source_label) {
  data <- utils::read.csv(path, stringsAsFactors = FALSE)
  state <- as_xgeo_state(
    data,
    x_col = "x",
    y_col = "y",
    z_col = "z",
    value_col = "value",
    feature_col = "feature",
    method = "downstream-consumer-demo",
    meta = list(
      downstream_case = case_id,
      downstream_source = source_label
    )
  )

  state <- compute_xgeo_embedding(state, method = "pca", source = "points", dims = 2)
  state <- set_active_embedding(state, "pca_points")
  state <- compute_xgeo_diagnostics(state, embedding = "pca_points", source = "points", k = 3)
  state <- build_xgeo_lod(state, embedding = "pca_points", levels = c(8L, 16L), auto_threshold = 10L)

  full_point_tbl <- xgeo_point_values(state)
  regular_grid <- xgeo_regular_grid(full_point_tbl)
  keep <- utils::head(full_point_tbl$point_id[order(abs(full_point_tbl$value), decreasing = TRUE)], 16L)
  state <- set_xgeo_selection(state, point_ids = keep)

  explanation_tbl <- xgeo_explanation_table(state)
  selected_point_tbl <- xgeo_point_values(state)

  list(
    state = state,
    explanation_tbl = explanation_tbl,
    point_tbl = selected_point_tbl,
    regular_grid = regular_grid
  )
}

run_downstream_shapviz3d_state_tables <- function() {
  load_backend_demo_package()
  manifest <- locate_shapviz3d_case_files()

  out <- lapply(seq_len(nrow(manifest)), function(idx) {
    build_downstream_state(
      path = manifest$path[[idx]],
      case_id = manifest$case_id[[idx]],
      source_label = manifest$source[[idx]]
    )
  })
  names(out) <- manifest$case_id

  for (case_id in names(out)) {
    cat("\ncase_id=", case_id, "\n", sep = "")
    print(summary(out[[case_id]]$state))
    print(utils::head(out[[case_id]]$explanation_tbl, 6))
    print(utils::head(out[[case_id]]$point_tbl, 6))
    cat(
      "grid_size=",
      length(out[[case_id]]$regular_grid$x),
      "x",
      length(out[[case_id]]$regular_grid$y),
      "\n",
      sep = ""
    )
  }

  invisible(out)
}

run_downstream_shapviz3d_state_tables()
