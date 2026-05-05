#!/usr/bin/env Rscript

# Generate static SIGGRAPH-style XGeoRTR backend-state figures.
# Usage:
#   Rscript siggraph_figures/scripts/generate_xgeort_siggraph_figures.R [output_dir]
#
# This directory is ignored by Rbuild, so this script is not part of CRAN checks.
# Still, default to tempdir() rather than getwd() to avoid accidental writes to
# a user's working directory when the script is run without arguments.

out_dir <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(out_dir) || !nzchar(out_dir)) {
  out_dir <- file.path(tempdir(), "xgeortr_siggraph_figures")
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_file <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else NA_character_
repo <- if (!is.na(script_file)) {
  normalizePath(file.path(dirname(script_file), "..", ".."), mustWork = FALSE)
} else {
  getwd()
}
if (!file.exists(file.path(repo, "DESCRIPTION"))) {
  repo <- getwd()
}

load_xgeortr <- function(repo) {
  if (requireNamespace("pkgload", quietly = TRUE) && file.exists(file.path(repo, "DESCRIPTION"))) {
    pkgload::load_all(repo, quiet = TRUE, export_all = FALSE)
  } else {
    library(XGeoRTR)
  }
}

load_xgeortr(repo)

safe_file <- function(name) file.path(out_dir, name)

class_palette <- c(
  "Low response" = "#255C99",
  "Transition" = "#2E9F6E",
  "High response" = "#D17A22"
)

group_palette <- c(
  "Position" = "#255C99",
  "Wave response" = "#2E9F6E",
  "Stability" = "#D17A22",
  "Interaction" = "#A23E48"
)

muted <- "#5F6872"
grid_col <- "#E9ECEF"
arrow_col <- "#202225"

make_demo_state <- function(seed, n = 840L, balanced_groups = FALSE) {
  set.seed(seed)
  class_seed <- sample.int(3L, n, replace = TRUE, prob = c(0.33, 0.34, 0.33))
  centers <- matrix(
    c(-2.35, -0.80,
       2.15, -0.55,
       0.00,  2.15),
    ncol = 2,
    byrow = TRUE
  )
  latent <- centers[class_seed, , drop = FALSE] +
    matrix(stats::rnorm(n * 2L, sd = 0.72), ncol = 2)

  features <- cbind(
    f_position_x = latent[, 1],
    f_position_y = latent[, 2],
    f_wave = sin(1.35 * latent[, 1]) + 0.16 * stats::rnorm(n),
    f_stability = cos(0.85 * latent[, 2]) + 0.18 * stats::rnorm(n),
    f_interaction = 0.42 * latent[, 1] * latent[, 2] + 0.20 * stats::rnorm(n)
  )

  weights <- matrix(
    c(
      0.95, -0.50,  0.70, -0.24,  0.24,
     -0.28,  1.02, -0.24,  0.72, -0.16,
     -0.62, -0.50,  0.34, -0.40,  0.92
    ),
    nrow = 3L,
    byrow = TRUE
  )
  colnames(weights) <- colnames(features)

  logits <- features %*% t(weights) + matrix(stats::rnorm(n * 3L, sd = 0.17), ncol = 3L)
  prob <- exp(logits - apply(logits, 1L, max))
  prob <- prob / rowSums(prob)
  pred_id <- max.col(prob)
  classes <- names(class_palette)
  prediction <- factor(classes[pred_id], levels = classes)
  confidence <- apply(prob, 1L, max)

  shap_values <- features * weights[pred_id, , drop = FALSE]
  colnames(shap_values) <- colnames(features)

  feature_group <- c(
    f_position_x = "Position",
    f_position_y = "Position",
    f_wave = "Wave response",
    f_stability = "Stability",
    f_interaction = "Interaction"
  )

  if (balanced_groups) {
    assigned_group <- ifelse(
      latent[, 1] < -1.15,
      "Position",
      ifelse(
        latent[, 2] > 1.0,
        "Stability",
        ifelse(abs(latent[, 1] * latent[, 2]) > 1.05, "Interaction", "Wave response")
      )
    )
    for (i in seq_len(n)) {
      dominant_features <- names(feature_group)[feature_group == assigned_group[i]]
      other_features <- setdiff(colnames(shap_values), dominant_features)
      shap_values[i, dominant_features] <- shap_values[i, dominant_features] * 6.0
      shap_values[i, other_features] <- shap_values[i, other_features] * 0.06
    }
    shap_values <- shap_values + matrix(stats::rnorm(length(shap_values), sd = 0.01), nrow = n)
  }

  point_id <- sprintf("pt_%04d", seq_len(n))
  long <- data.frame(
    point_id = rep(point_id, each = ncol(shap_values)),
    feature = rep(colnames(shap_values), times = n),
    value = as.vector(t(shap_values)),
    x = rep(features[, "f_position_x"], each = ncol(shap_values)),
    y = rep(features[, "f_position_y"], each = ncol(shap_values)),
    z = rep(0, n * ncol(shap_values)),
    prediction = rep(as.character(prediction), each = ncol(shap_values)),
    confidence = rep(confidence, each = ncol(shap_values)),
    stringsAsFactors = FALSE
  )

  state <- as_xgeo_state(
    long,
    x_col = "x",
    y_col = "y",
    z_col = "z",
    value_col = "value",
    feature_col = "feature",
    point_id_col = "point_id",
    method = "classification SHAP-like attribution state",
    meta = list(
      poster_asset = TRUE,
      purpose = "SIGGRAPH static backend-state figure"
    )
  )

  list(
    state = state,
    long = long,
    shap_values = shap_values,
    prob = prob,
    feature_group = feature_group
  )
}

embed_state <- function(state, seed, n_neighbors = 18L, n_epochs = 180L) {
  if (requireNamespace("uwot", quietly = TRUE)) {
    set.seed(seed)
    state <- compute_xgeo_embedding(
      state,
      method = "umap",
      source = "explanations",
      dims = 2,
      n_neighbors = n_neighbors,
      n_epochs = n_epochs,
      init = "random",
      n_threads = 1,
      verbose = FALSE
    )
    coords <- state$attributes$embeddings$items$umap_explanations$coords
    method <- "umap"
  } else {
    state <- compute_xgeo_embedding(state, method = "pca", source = "explanations", dims = 2)
    coords <- state$attributes$embeddings$items$pca_explanations$coords
    method <- "pca fallback"
  }

  coords <- as.data.frame(coords, stringsAsFactors = FALSE)
  if (!"point_id" %in% names(coords)) {
    coords$point_id <- rownames(coords)
  }
  coord_names <- setdiff(names(coords), "point_id")[seq_len(2)]
  coords <- coords[c("point_id", coord_names)]
  names(coords) <- c("point_id", "dim1", "dim2")

  list(state = state, coords = coords, method = method)
}

make_plot_data <- function(coords, long, shap_values) {
  point_meta <- unique(long[c("point_id", "prediction", "confidence")])
  dat <- merge(coords, point_meta, by = "point_id", sort = FALSE)
  dat$prediction <- factor(dat$prediction, levels = names(class_palette))

  contrib_wide <- reshape(
    long[c("point_id", "feature", "value")],
    idvar = "point_id",
    timevar = "feature",
    direction = "wide"
  )
  names(contrib_wide) <- sub("^value\\.", "", names(contrib_wide))
  dat <- merge(dat, contrib_wide, by = "point_id", sort = FALSE)

  dat$vx_raw <- 0.72 * dat$f_position_x - 0.30 * dat$f_position_y + 0.55 * dat$f_interaction
  dat$vy_raw <- 0.62 * dat$f_position_y + 0.42 * dat$f_wave - 0.25 * dat$f_stability
  mag <- sqrt(dat$vx_raw^2 + dat$vy_raw^2)
  mag[mag == 0] <- 1
  dat$vx <- dat$vx_raw / mag
  dat$vy <- dat$vy_raw / mag
  dat
}

make_arrows <- function(dat, k, scale = 0.07) {
  dat <- dat[is.finite(dat$dim1) & is.finite(dat$dim2), , drop = FALSE]
  if (nrow(dat) == 0L) {
    stop("no finite embedding points available for arrows", call. = FALSE)
  }
  k <- min(k, max(1L, nrow(dat)))
  set.seed(20260422 + k)
  km <- stats::kmeans(dat[c("dim1", "dim2")], centers = k, iter.max = 50)
  split_idx <- split(seq_len(nrow(dat)), km$cluster)
  out <- do.call(rbind, lapply(split_idx, function(idx) {
    data.frame(
      x = mean(dat$dim1[idx]),
      y = mean(dat$dim2[idx]),
      vx = mean(dat$vx[idx]),
      vy = mean(dat$vy[idx]),
      n = length(idx)
    )
  }))
  vmag <- sqrt(out$vx^2 + out$vy^2)
  vmag[vmag == 0] <- 1
  span <- max(diff(range(dat$dim1)), diff(range(dat$dim2)))
  out$xend <- out$x + (out$vx / vmag) * span * scale
  out$yend <- out$y + (out$vy / vmag) * span * scale
  out
}

full_limits <- function(dat) {
  xlim <- range(dat$dim1)
  ylim <- range(dat$dim2)
  list(
    x = xlim + c(-1, 1) * diff(xlim) * 0.08,
    y = ylim + c(-1, 1) * diff(ylim) * 0.08
  )
}

plot_embedding_panel <- function(dat, arrows, xlim, ylim, title, subtitle, cols, cex = 0.74,
                                 show_zoom_box = FALSE, zoom_center = NULL, zoom_radius = NULL) {
  plot(NA, xlim = xlim, ylim = ylim, type = "n", axes = FALSE, xlab = "", ylab = "", asp = 1)
  box(col = "#CED4DA", lwd = 1.2)
  abline(h = pretty(ylim, 6), v = pretty(xlim, 6), col = grid_col, lwd = 0.75)
  points(dat$dim1, dat$dim2, pch = 16, col = cols, cex = cex)
  arrows(
    arrows$x, arrows$y, arrows$xend, arrows$yend,
    length = 0.085,
    angle = 22,
    lwd = 2.2,
    col = grDevices::adjustcolor(arrow_col, alpha.f = 0.86)
  )
  points(arrows$x, arrows$y, pch = 21, cex = 0.86, bg = "white", col = arrow_col, lwd = 0.9)
  if (show_zoom_box) {
    rect(
      zoom_center$dim1 - zoom_radius,
      zoom_center$dim2 - zoom_radius,
      zoom_center$dim1 + zoom_radius,
      zoom_center$dim2 + zoom_radius,
      border = "#111827",
      lwd = 2.1
    )
  }
  mtext(title, side = 3, adj = 0, line = 1.0, font = 2, cex = 1.25, col = "#111827")
  mtext(subtitle, side = 3, adj = 0, line = -0.15, cex = 0.78, col = muted)
}

generate_representative_and_multiscale <- function() {
  demo <- make_demo_state(seed = 20260421, n = 840L, balanced_groups = FALSE)
  embedded <- embed_state(demo$state, seed = 20260421, n_neighbors = 18L, n_epochs = 180L)
  dat <- make_plot_data(embedded$coords, demo$long, demo$shap_values)
  limits <- full_limits(dat)
  global_arrows <- make_arrows(dat, k = 15L, scale = 0.065)
  point_cols <- grDevices::adjustcolor(class_palette[dat$prediction], alpha.f = 0.72)

  center_candidates <- order(abs(dat$confidence - stats::quantile(dat$confidence, 0.33)))
  center <- dat[center_candidates[1L], c("dim1", "dim2")]
  full_span <- max(diff(range(dat$dim1)), diff(range(dat$dim2)))
  radius <- full_span * 0.17
  repeat {
    local_idx <- abs(dat$dim1 - center$dim1) <= radius & abs(dat$dim2 - center$dim2) <= radius
    if (sum(local_idx) >= 120L || radius > full_span * 0.34) {
      break
    }
    radius <- radius * 1.18
  }
  local_data <- dat[local_idx, , drop = FALSE]
  local_arrows <- make_arrows(local_data, k = 22L, scale = 0.055)
  local_cols <- grDevices::adjustcolor(class_palette[local_data$prediction], alpha.f = 0.82)

  grDevices::jpeg(safe_file("xgeort_representative.jpg"), width = 2400, height = 1600, res = 220, quality = 96, bg = "white")
  op <- par(no.readonly = TRUE)
  on.exit(par(op), add = TRUE)
  par(mar = c(1.0, 1.0, 4.2, 1.0), oma = c(1.8, 1.0, 2.4, 1.0), family = "sans")
  plot_embedding_panel(
    dat,
    global_arrows,
    limits$x,
    limits$y,
    title = "Geometric explanation state",
    subtitle = sprintf(
      "%s embedding; points colored by predicted class; arrows summarize contribution direction",
      toupper(embedded$method)
    ),
    cols = point_cols,
    cex = 0.72
  )
  legend("topright", legend = names(class_palette), pch = 16, col = class_palette, bty = "n", cex = 0.88, title = "Prediction")
  mtext(
    "XGeoRTR backend state: global structure with sparse local explanation vectors",
    outer = TRUE,
    side = 3,
    line = 0.4,
    font = 2,
    cex = 1.18,
    col = "#111827"
  )
  mtext(
    "Contribution scores are aggregated into readable local directions; no display-system state is used.",
    outer = TRUE,
    side = 1,
    line = 0.3,
    cex = 0.72,
    col = muted
  )
  grDevices::dev.off()
  par(op)

  local_xlim <- range(local_data$dim1) + c(-1, 1) * diff(range(local_data$dim1)) * 0.16
  local_ylim <- range(local_data$dim2) + c(-1, 1) * diff(range(local_data$dim2)) * 0.16

  grDevices::jpeg(safe_file("xgeort_multiscale.jpg"), width = 3200, height = 1600, res = 220, quality = 96, bg = "white")
  op <- par(no.readonly = TRUE)
  on.exit(par(op), add = TRUE)
  layout(matrix(c(1, 2), nrow = 1), widths = c(1, 1))
  par(mar = c(1.0, 1.0, 4.0, 1.0), oma = c(1.8, 1.0, 2.5, 1.0), family = "sans")
  plot_embedding_panel(
    dat,
    global_arrows,
    limits$x,
    limits$y,
    title = "Global embedding",
    subtitle = "Full backend state with sparse explanation directions",
    cols = grDevices::adjustcolor(class_palette[dat$prediction], alpha.f = 0.58),
    cex = 0.58,
    show_zoom_box = TRUE,
    zoom_center = center,
    zoom_radius = radius
  )
  legend("topright", legend = names(class_palette), pch = 16, col = class_palette, bty = "n", cex = 0.76, title = "Prediction")
  plot_embedding_panel(
    local_data,
    local_arrows,
    local_xlim,
    local_ylim,
    title = "Local explanation region",
    subtitle = "Zoomed neighborhood with denser contribution vectors",
    cols = local_cols,
    cex = 0.86
  )
  mtext("Global vs local explanation structure", outer = TRUE, side = 3, line = 0.5, font = 2, cex = 1.16, col = "#111827")
  mtext("Same embedding and color mapping across panels; arrows remain sparse to avoid clutter.", outer = TRUE, side = 1, line = 0.3, cex = 0.72, col = muted)
  grDevices::dev.off()
  par(op)
}

generate_attribution <- function() {
  demo <- make_demo_state(seed = 20260424, n = 900L, balanced_groups = TRUE)
  embedded <- embed_state(demo$state, seed = 20260424, n_neighbors = 20L, n_epochs = 190L)

  meta <- unique(demo$long[c("point_id", "prediction", "confidence")])
  dat <- merge(embedded$coords, meta, by = "point_id", sort = FALSE)

  group_names <- names(group_palette)
  raw_group_scores <- sapply(group_names, function(g) {
    rowMeans(abs(demo$shap_values[, demo$feature_group == g, drop = FALSE]))
  })
  scale_ref <- apply(raw_group_scores, 2, function(x) stats::quantile(x, 0.72) + 1e-8)
  group_scores <- sweep(raw_group_scores, 2, scale_ref, "/")
  dat$dominant_group <- factor(group_names[max.col(group_scores)], levels = group_names)
  dat$importance <- apply(raw_group_scores, 1L, max)
  importance_scaled <- (dat$importance - min(dat$importance)) / (max(dat$importance) - min(dat$importance))
  dat$point_cex <- 0.38 + 1.18 * sqrt(importance_scaled)
  dat$alpha <- 0.46 + 0.40 * sqrt(importance_scaled)

  limits <- full_limits(dat)

  grDevices::jpeg(safe_file("xgeort_attribution.jpg"), width = 2400, height = 1600, res = 220, quality = 96, bg = "white")
  op <- par(no.readonly = TRUE)
  on.exit(par(op), add = TRUE)
  par(mar = c(1.0, 1.0, 4.2, 1.0), oma = c(1.8, 1.0, 2.4, 1.0), family = "sans")
  plot(NA, xlim = limits$x, ylim = limits$y, type = "n", axes = FALSE, xlab = "", ylab = "", asp = 1)
  box(col = "#CED4DA", lwd = 1.2)
  abline(h = pretty(limits$y, 6), v = pretty(limits$x, 6), col = grid_col, lwd = 0.75)
  if (requireNamespace("MASS", quietly = TRUE)) {
    dens <- MASS::kde2d(dat$dim1, dat$dim2, n = 70, lims = c(limits$x, limits$y))
    contour(dens, add = TRUE, drawlabels = FALSE, col = "#D7DCE0", lwd = 0.9, levels = pretty(range(dens$z), 7)[-1])
  }
  cols <- mapply(grDevices::adjustcolor, group_palette[dat$dominant_group], alpha.f = dat$alpha, USE.NAMES = FALSE)
  points(dat$dim1, dat$dim2, pch = 16, col = cols, cex = dat$point_cex)
  legend("topright", legend = names(group_palette), pch = 16, col = group_palette, bty = "n", cex = 0.84, title = "Dominant attribution")
  legend(
    "bottomright",
    legend = c("low", "medium", "high"),
    pt.cex = c(0.55, 0.95, 1.45),
    pch = 16,
    col = grDevices::adjustcolor("#111827", alpha.f = 0.55),
    bty = "n",
    cex = 0.74,
    title = "Importance"
  )
  mtext("Feature attribution mapped into explanation space", side = 3, adj = 0, line = 1.0, font = 2, cex = 1.25, col = "#111827")
  mtext(
    sprintf("%s embedding; color = dominant normalized SHAP-like feature group; glyph size/intensity = attribution magnitude", toupper(embedded$method)),
    side = 3,
    adj = 0,
    line = -0.15,
    cex = 0.78,
    col = muted
  )
  mtext("XGeoRTR backend state: feature contributions become spatial attribution structure.", outer = TRUE, side = 3, line = 0.4, font = 2, cex = 1.14, col = "#111827")
  mtext("Density contours are optional context; four feature groups avoid color clutter.", outer = TRUE, side = 1, line = 0.3, cex = 0.72, col = muted)
  grDevices::dev.off()
  par(op)
}

generate_structure <- function() {
  demo <- make_demo_state(seed = 20260422, n = 900L, balanced_groups = FALSE)
  embedded <- embed_state(demo$state, seed = 20260422, n_neighbors = 20L, n_epochs = 190L)
  dat <- make_plot_data(embedded$coords, demo$long, demo$shap_values)
  dat$decision_score <- demo$prob[, 3L] - demo$prob[, 1L]
  limits <- full_limits(dat)
  dat$path_band <- cut(
    dat$dim2,
    breaks = stats::quantile(dat$dim2, probs = c(0.08, 0.38, 0.62, 0.92)),
    include.lowest = TRUE,
    labels = c("lower", "middle", "upper")
  )

  make_path <- function(d) {
    d <- d[!is.na(d$path_band), , drop = FALSE]
    if (nrow(d) < 60L) {
      return(NULL)
    }
    br <- unique(stats::quantile(d$decision_score, probs = seq(0.08, 0.92, length.out = 7), na.rm = TRUE))
    if (length(br) < 4L) {
      return(NULL)
    }
    d$score_bin <- cut(d$decision_score, breaks = br, include.lowest = TRUE)
    centers <- stats::aggregate(cbind(dim1, dim2, decision_score) ~ score_bin, data = d, FUN = stats::median)
    centers[order(centers$decision_score), , drop = FALSE]
  }

  paths <- lapply(levels(dat$path_band), function(b) make_path(dat[dat$path_band == b, , drop = FALSE]))
  names(paths) <- levels(dat$path_band)
  path_cols <- c(lower = "#1F4E79", middle = "#263238", upper = "#8A4B12")

  grDevices::jpeg(safe_file("xgeort_structure.jpg"), width = 2400, height = 1600, res = 220, quality = 96, bg = "white")
  op <- par(no.readonly = TRUE)
  on.exit(par(op), add = TRUE)
  par(mar = c(1.0, 1.0, 4.2, 1.0), oma = c(1.8, 1.0, 2.4, 1.0), family = "sans")
  plot(NA, xlim = limits$x, ylim = limits$y, type = "n", axes = FALSE, xlab = "", ylab = "", asp = 1)
  box(col = "#CED4DA", lwd = 1.2)
  abline(h = pretty(limits$y, 6), v = pretty(limits$x, 6), col = grid_col, lwd = 0.75)
  points(dat$dim1, dat$dim2, pch = 16, col = grDevices::adjustcolor(class_palette[dat$prediction], alpha.f = 0.34), cex = 0.62)
  for (nm in names(paths)) {
    centers <- paths[[nm]]
    if (is.null(centers) || nrow(centers) < 3L) {
      next
    }
    xs <- stats::spline(seq_len(nrow(centers)), centers$dim1, n = 100)$y
    ys <- stats::spline(seq_len(nrow(centers)), centers$dim2, n = 100)$y
    lines(xs, ys, col = grDevices::adjustcolor(path_cols[[nm]], alpha.f = 0.92), lwd = 4.0, lend = "round")
    arrow_idx <- round(seq(18, length(xs) - 12, length.out = 3))
    for (i in arrow_idx) {
      arrows(xs[i], ys[i], xs[i + 5], ys[i + 5], length = 0.075, angle = 22, lwd = 3.2, col = grDevices::adjustcolor(path_cols[[nm]], alpha.f = 0.92))
    }
    points(centers$dim1, centers$dim2, pch = 21, bg = "white", col = path_cols[[nm]], lwd = 1.2, cex = 1.05)
  }
  legend("topright", legend = names(class_palette), pch = 16, col = class_palette, bty = "n", cex = 0.84, title = "Prediction")
  legend("bottomright", legend = c("lower path", "middle path", "upper path"), lwd = 4, col = path_cols, bty = "n", cex = 0.78, title = "Transition summaries")
  mtext("Geometric structure of explanation transitions", side = 3, adj = 0, line = 1.0, font = 2, cex = 1.25, col = "#111827")
  mtext("Static transition paths through embedding neighborhoods ordered by prediction contrast", side = 3, adj = 0, line = -0.15, cex = 0.78, col = muted)
  mtext("XGeoRTR backend state: decision movement summarized as clean paths, not animation.", outer = TRUE, side = 3, line = 0.4, font = 2, cex = 1.14, col = "#111827")
  mtext("Lines connect median neighborhood states from low-response to high-response regions.", outer = TRUE, side = 1, line = 0.3, cex = 0.72, col = muted)
  grDevices::dev.off()
  par(op)
}

generate_representative_and_multiscale()
generate_attribution()
generate_structure()

cat("Generated figures in ", normalizePath(out_dir), "\n", sep = "")
cat("- xgeort_representative.jpg\n")
cat("- xgeort_multiscale.jpg\n")
cat("- xgeort_attribution.jpg\n")
cat("- xgeort_structure.jpg\n")
