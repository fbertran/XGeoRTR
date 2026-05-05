# Popular R workflows as XGeoRTR backend-state examples
#
# These examples show how common R outputs can be standardized into xgeo_state
# objects without taking ownership of rendering, viewport orchestration, or
# frontend display.
#
# CRAN-safety:
# - no writes to getwd(), package directories, or the user's home directory;
# - serialization writes only to tempfile();
# - no modification of .GlobalEnv;
# - no fixed random seed inside functions;
# - no renderer dependencies.

load_xgeortr_example_package <- function() {
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
  
      stop("XGeoRTR is not available. Install the package or run from the repository.")
  }

scale01 <- function(x) {
    x <- as.numeric(x)
    rng <- range(x, finite = TRUE)
    if (!all(is.finite(rng)) || diff(rng) == 0) {
        return(rep(0.5, length(x)))
      }
    (x - rng[[1]]) / diff(rng)
  }

safe_regular_grid <- function(point_tbl) {
    out <- try(xgeo_regular_grid(point_tbl), silent = TRUE)
    if (inherits(out, "try-error")) {
        return(NULL)
      }
    out
  }

finish_state <- function(state, embedding_source = "points", k = 3L, lod_levels = c(8L, 16L)) {
    state <- compute_xgeo_embedding(
        state,
        method = "pca",
        source = embedding_source,
        dims = 2
      )
  
      embedding_name <- paste("pca", embedding_source, sep = "_")
      state <- set_active_embedding(state, embedding_name)
    
        state <- compute_xgeo_diagnostics(
            state,
            embedding = embedding_name,
            source = embedding_source,
            k = k
          )
      
          state <- build_xgeo_lod(
              state,
              embedding = embedding_name,
              levels = lod_levels,
              auto_threshold = 10L
            )
        
            state
        }

example_lm_mtcars <- function() {
    data <- datasets::mtcars
    data$car <- rownames(data)
  
      fit <- stats::lm(mpg ~ wt + hp + qsec, data = data)
      terms <- c("wt", "hp", "qsec")
      centered <- scale(data[, terms, drop = FALSE], center = TRUE, scale = FALSE)
      beta <- stats::coef(fit)[terms]
      contributions <- sweep(centered, 2, beta, `*`)
    
        scores <- stats::predict(fit)
        residuals <- stats::residuals(fit)
      
          long <- data.frame(
              point_id = rep(data$car, each = length(terms)),
              feature = rep(terms, times = nrow(data)),
              value = as.vector(t(contributions)),
              x = rep(scale01(data$wt), each = length(terms)),
              y = rep(scale01(scores), each = length(terms)),
              z = rep(scale01(abs(residuals)), each = length(terms)),
              model = "stats::lm",
              response = rep(data$mpg, each = length(terms)),
              fitted = rep(scores, each = length(terms)),
              residual = rep(residuals, each = length(terms)),
              stringsAsFactors = FALSE
            )
        
            state <- as_xgeo_state(
                long,
                point_id_col = "point_id",
                feature_col = "feature",
                x_col = "x",
                y_col = "y",
                z_col = "z",
                value_col = "value",
                method = "linear-model-coefficient-contributions",
                meta = list(
                    dataset = "datasets::mtcars",
                    package = "stats",
                    model = "lm(mpg ~ wt + hp + qsec)"
                  )
              )
          
              finish_state(state, embedding_source = "explanations", k = 3L)
          }

example_glm_mtcars <- function() {
    data <- datasets::mtcars
    data$car <- rownames(data)
    data$efficient <- as.integer(data$mpg > stats::median(data$mpg))
  
      fit <- stats::glm(efficient ~ wt + hp + qsec, data = data, family = stats::binomial())
      terms <- c("wt", "hp", "qsec")
      centered <- scale(data[, terms, drop = FALSE], center = TRUE, scale = FALSE)
      beta <- stats::coef(fit)[terms]
      contributions <- sweep(centered, 2, beta, `*`)
    
        prob <- stats::predict(fit, type = "response")
        linear_predictor <- stats::predict(fit, type = "link")
      
          long <- data.frame(
              point_id = rep(data$car, each = length(terms)),
              feature = rep(terms, times = nrow(data)),
              value = as.vector(t(contributions)),
              x = rep(scale01(data$wt), each = length(terms)),
              y = rep(prob, each = length(terms)),
              z = rep(scale01(abs(linear_predictor)), each = length(terms)),
              model = "stats::glm",
              class = rep(ifelse(data$efficient == 1L, "high_mpg", "low_mpg"), each = length(terms)),
              probability = rep(prob, each = length(terms)),
              stringsAsFactors = FALSE
            )
        
            state <- as_xgeo_state(
                long,
                point_id_col = "point_id",
                feature_col = "feature",
                x_col = "x",
                y_col = "y",
                z_col = "z",
                value_col = "value",
                method = "logistic-model-coefficient-contributions",
                meta = list(
                    dataset = "datasets::mtcars",
                    package = "stats",
                    model = "glm(efficient ~ wt + hp + qsec, family = binomial())"
                  )
              )
          
              finish_state(state, embedding_source = "explanations", k = 3L)
          }

example_kmeans_iris <- function() {
    data <- datasets::iris
    numeric_cols <- c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")
  
      scaled <- scale(data[, numeric_cols, drop = FALSE])
      km <- stats::kmeans(scaled, centers = 3L, nstart = 5L)
      pca <- stats::prcomp(scaled, center = FALSE, scale. = FALSE)
    
        centers <- km$centers[km$cluster, , drop = FALSE]
        contributions <- scaled - centers
        rownames(contributions) <- paste0("iris_", seq_len(nrow(data)))
      
          long <- data.frame(
              point_id = rep(rownames(contributions), each = length(numeric_cols)),
              feature = rep(numeric_cols, times = nrow(data)),
              value = as.vector(t(contributions)),
              x = rep(pca$x[, 1], each = length(numeric_cols)),
              y = rep(pca$x[, 2], each = length(numeric_cols)),
              z = rep(scale01(km$cluster), each = length(numeric_cols)),
              species = rep(as.character(data$Species), each = length(numeric_cols)),
              cluster = rep(paste0("cluster_", km$cluster), each = length(numeric_cols)),
              stringsAsFactors = FALSE
            )
        
            state <- as_xgeo_state(
                long,
                point_id_col = "point_id",
                feature_col = "feature",
                x_col = "x",
                y_col = "y",
                z_col = "z",
                value_col = "value",
                method = "kmeans-residual-geometry",
                meta = list(
                    dataset = "datasets::iris",
                    package = "stats",
                    model = "kmeans(scale(iris[1:4]), centers = 3)"
                  )
              )
          
              finish_state(state, embedding_source = "explanations", k = 5L)
          }

example_prcomp_usarrests <- function() {
    data <- datasets::USArrests
    vars <- names(data)
    pca <- stats::prcomp(data, center = TRUE, scale. = TRUE)
  
      scaled <- scale(data, center = pca$center, scale = pca$scale)
      loadings <- pca$rotation[, 1:2, drop = FALSE]
      contributions <- scaled %*% loadings
      colnames(contributions) <- c("PC1_score_component", "PC2_score_component")
    
        feature_contrib <- sweep(scaled, 2, pca$rotation[, 1], `*`)
      
          long <- data.frame(
              point_id = rep(rownames(data), each = length(vars)),
              feature = rep(vars, times = nrow(data)),
              value = as.vector(t(feature_contrib)),
              x = rep(pca$x[, 1], each = length(vars)),
              y = rep(pca$x[, 2], each = length(vars)),
              z = rep(scale01(rowSums(abs(feature_contrib))), each = length(vars)),
              state_name = rep(rownames(data), each = length(vars)),
              method_label = "stats::prcomp",
              stringsAsFactors = FALSE
            )
        
            state <- as_xgeo_state(
                long,
                point_id_col = "point_id",
                feature_col = "feature",
                x_col = "x",
                y_col = "y",
                z_col = "z",
                value_col = "value",
                method = "pca-loading-contribution-geometry",
                meta = list(
                    dataset = "datasets::USArrests",
                    package = "stats",
                    model = "prcomp(USArrests, center = TRUE, scale. = TRUE)"
                  )
              )
          
              finish_state(state, embedding_source = "explanations", k = 4L)
          }

example_rpart_iris <- function() {
    if (!requireNamespace("rpart", quietly = TRUE)) {
        return(NULL)
      }
  
      data <- datasets::iris
      data$point_id <- paste0("iris_", seq_len(nrow(data)))
      fit <- rpart::rpart(Species ~ ., data = data[, c(names(data)[1:4], "Species")])
      prob <- stats::predict(fit, type = "prob")
      pred <- colnames(prob)[max.col(prob)]
      xmat <- stats::model.matrix(~ Sepal.Length + Sepal.Width + Petal.Length + Petal.Width, data = data)
      xmat <- xmat[, -1, drop = FALSE]
    
        global_center <- colMeans(xmat)
        contributions <- sweep(xmat, 2, global_center, "-")
        importance <- fit$variable.importance
        importance <- importance[colnames(contributions)]
        importance[is.na(importance)] <- 0
        if (sum(abs(importance)) > 0) {
            importance <- importance / sum(abs(importance))
          }
        contributions <- sweep(contributions, 2, importance, `*`)
      
          pca <- stats::prcomp(scale(data[, 1:4]), center = FALSE, scale. = FALSE)
        
            long <- data.frame(
                point_id = rep(data$point_id, each = ncol(contributions)),
                feature = rep(colnames(contributions), times = nrow(data)),
                value = as.vector(t(contributions)),
                x = rep(pca$x[, 1], each = ncol(contributions)),
                y = rep(pca$x[, 2], each = ncol(contributions)),
                z = rep(apply(prob, 1L, max), each = ncol(contributions)),
                species = rep(as.character(data$Species), each = ncol(contributions)),
                predicted_species = rep(pred, each = ncol(contributions)),
                model = "rpart::rpart",
                stringsAsFactors = FALSE
              )
          
              state <- as_xgeo_state(
                  long,
                  point_id_col = "point_id",
                  feature_col = "feature",
                  x_col = "x",
                  y_col = "y",
                  z_col = "z",
                  value_col = "value",
                  method = "decision-tree-variable-importance-geometry",
                  meta = list(
                      dataset = "datasets::iris",
                      package = "rpart",
                      model = "rpart(Species ~ .)"
                    )
                )
            
                finish_state(state, embedding_source = "explanations", k = 5L)
            }

example_volcano_regular_grid <- function() {
    state <- as_xgeo_state(
        datasets::volcano,
        method = "matrix-regular-grid",
        meta = list(
            dataset = "datasets::volcano",
            package = "datasets",
            source_shape = paste(dim(datasets::volcano), collapse = "x")
          )
      )
  
      state <- finish_state(state, embedding_source = "points", k = 4L)
      point_tbl <- xgeo_point_values(state)
      grid <- xgeo_regular_grid(point_tbl)
    
        list(state = state, point_tbl = point_tbl, regular_grid = grid)
    }

run_popular_r_workflow_examples <- function() {
    load_xgeortr_example_package()
  
      states <- list(
          lm_mtcars = example_lm_mtcars(),
          glm_mtcars = example_glm_mtcars(),
          kmeans_iris = example_kmeans_iris(),
          prcomp_usarrests = example_prcomp_usarrests(),
          rpart_iris = example_rpart_iris()
        )
      states <- states[!vapply(states, is.null, logical(1))]
    
        grid_case <- example_volcano_regular_grid()
        states$volcano_regular_grid <- grid_case$state
      
          # JSON serialization example. This is deliberately written to tempfile().
          json_file <- tempfile(fileext = ".json")
          write_xgeo_state(states$lm_mtcars, json_file)
          restored <- read_xgeo_state(json_file)
        
            tables <- lapply(states, function(state) {
                list(
                    explanation_tbl = xgeo_explanation_table(state),
                    point_tbl = xgeo_point_values(state),
                    active_embedding = state$attributes$embeddings$active,
                    active_lod = state$lod$active
                  )
              })
          
              for (nm in names(states)) {
                  cat("\ncase_id=", nm, "\n", sep = "")
                  print(summary(states[[nm]]))
                  print(utils::head(tables[[nm]]$point_tbl, 4L))
                }
          
              invisible(list(
                  states = states,
                  tables = tables,
                  grid_case = grid_case,
                  json_file = json_file,
                  restored = restored
                ))
          }

run_popular_r_workflow_examples()