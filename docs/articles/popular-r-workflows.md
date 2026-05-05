# Popular R Workflows as XGeoRTR Backend States

`XGeoRTR` provides a platform layer for explanation geometry in R. It
standardizes generic explanation tables into a normalized `xgeo_state`,
computes embeddings, diagnostics, and multiscale level-of-detail
summaries, and exposes backend-neutral tables for downstream packages.

This vignette uses common R workflows and built-in datasets. It does not
render graphics. Rendering and viewport orchestration are delegated to
downstream frontends.

``` r
library(XGeoRTR)

scale01 <- function(x) {
x <- as.numeric(x)
rng <- range(x, finite = TRUE)
if (!all(is.finite(rng)) || diff(rng) == 0) {
  return(rep(0.5, length(x)))
}
(x - rng[[1]]) / diff(rng)
}

finish_state <- function(state, embedding_source = "explanations", k = 3L) {
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
build_xgeo_lod(
  state,
  embedding = embedding_name,
  levels = c(8L, 16L),
  auto_threshold = 10L
)
}
```

## Linear model: `stats::lm()` on `mtcars`

The first example turns coefficient-scaled centered predictors into
explanation values. Each car becomes a point, each predictor becomes a
feature contribution, and fitted/residual information becomes point
metadata.

``` r
mt <- datasets::mtcars
mt$car <- rownames(mt)

fit_lm <- stats::lm(mpg ~ wt + hp + qsec, data = mt)
terms_lm <- c("wt", "hp", "qsec")
centered_lm <- scale(mt[, terms_lm, drop = FALSE], center = TRUE, scale = FALSE)
contrib_lm <- sweep(centered_lm, 2, stats::coef(fit_lm)[terms_lm], `*`)
fitted_lm <- stats::predict(fit_lm)
resid_lm <- stats::residuals(fit_lm)

lm_tbl <- data.frame(
point_id = rep(mt$car, each = length(terms_lm)),
feature = rep(terms_lm, times = nrow(mt)),
value = as.vector(t(contrib_lm)),
x = rep(scale01(mt$wt), each = length(terms_lm)),
y = rep(scale01(fitted_lm), each = length(terms_lm)),
z = rep(scale01(abs(resid_lm)), each = length(terms_lm)),
response = rep(mt$mpg, each = length(terms_lm)),
fitted = rep(fitted_lm, each = length(terms_lm)),
residual = rep(resid_lm, each = length(terms_lm))
)

state_lm <- as_xgeo_state(
lm_tbl,
point_id_col = "point_id",
feature_col = "feature",
method = "linear-model-coefficient-contributions",
meta = list(dataset = "datasets::mtcars", model = "stats::lm")
)

state_lm <- finish_state(state_lm)
summary(state_lm)
#> <summary.xgeo_state>
#>   structure:      spatial
#>   method:         linear-model-coefficient-contributions
#>   points:         32
#>   features:       3
#>   explanations:   96
#>   embeddings:     2 (active: pca_explanations)
#>   diagnostics:    1 (active: diagnostics_pca_explanations_explanations)
#>   lod bundles:    1 (active: density_grid_pca_explanations)
#>   selected points:0
#>   selected feats: 0
```

## Logistic model: `stats::glm()` on `mtcars`

The second example uses a logistic model and stores the predicted
probability as state metadata. This gives the same backend state
contract for a classification workflow.

``` r
mt$efficient <- as.integer(mt$mpg > stats::median(mt$mpg))
fit_glm <- stats::glm(efficient ~ wt + hp + qsec, data = mt, family = stats::binomial())
#> Warning: glm.fit: algorithm did not converge
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
prob_glm <- stats::predict(fit_glm, type = "response")
terms_glm <- c("wt", "hp", "qsec")
centered_glm <- scale(mt[, terms_glm, drop = FALSE], center = TRUE, scale = FALSE)
contrib_glm <- sweep(centered_glm, 2, stats::coef(fit_glm)[terms_glm], `*`)

glm_tbl <- data.frame(
point_id = rep(mt$car, each = length(terms_glm)),
feature = rep(terms_glm, times = nrow(mt)),
value = as.vector(t(contrib_glm)),
x = rep(scale01(mt$wt), each = length(terms_glm)),
y = rep(prob_glm, each = length(terms_glm)),
z = rep(scale01(abs(stats::predict(fit_glm, type = "link"))), each = length(terms_glm)),
class = rep(ifelse(mt$efficient == 1L, "high_mpg", "low_mpg"), each = length(terms_glm)),
probability = rep(prob_glm, each = length(terms_glm))
)

state_glm <- as_xgeo_state(
glm_tbl,
point_id_col = "point_id",
feature_col = "feature",
method = "logistic-model-coefficient-contributions",
meta = list(dataset = "datasets::mtcars", model = "stats::glm")
)

state_glm <- finish_state(state_glm)
summary(state_glm)
#> <summary.xgeo_state>
#>   structure:      spatial
#>   method:         logistic-model-coefficient-contributions
#>   points:         32
#>   features:       3
#>   explanations:   96
#>   embeddings:     2 (active: pca_explanations)
#>   diagnostics:    1 (active: diagnostics_pca_explanations_explanations)
#>   lod bundles:    1 (active: density_grid_pca_explanations)
#>   selected points:0
#>   selected feats: 0
```

## Clustering: `stats::kmeans()` on `iris`

For clustering, explanation values can be residuals to the assigned
cluster center. The geometry can be defined by a PCA layout, while the
explanation table stores feature-level deviations.

``` r
iris_x <- scale(datasets::iris[, 1:4])
km <- stats::kmeans(iris_x, centers = 3L, nstart = 5L)
pca_iris <- stats::prcomp(iris_x, center = FALSE, scale. = FALSE)
cluster_residual <- iris_x - km$centers[km$cluster, , drop = FALSE]

iris_tbl <- data.frame(
point_id = rep(paste0("iris_", seq_len(nrow(iris_x))), each = ncol(iris_x)),
feature = rep(colnames(iris_x), times = nrow(iris_x)),
value = as.vector(t(cluster_residual)),
x = rep(pca_iris$x[, 1], each = ncol(iris_x)),
y = rep(pca_iris$x[, 2], each = ncol(iris_x)),
z = rep(scale01(km$cluster), each = ncol(iris_x)),
species = rep(as.character(datasets::iris$Species), each = ncol(iris_x)),
cluster = rep(paste0("cluster_", km$cluster), each = ncol(iris_x))
)

state_km <- as_xgeo_state(
iris_tbl,
point_id_col = "point_id",
feature_col = "feature",
method = "kmeans-residual-geometry",
meta = list(dataset = "datasets::iris", model = "stats::kmeans")
)

state_km <- finish_state(state_km, k = 5L)
summary(state_km)
#> <summary.xgeo_state>
#>   structure:      spatial
#>   method:         kmeans-residual-geometry
#>   points:         150
#>   features:       4
#>   explanations:   600
#>   embeddings:     2 (active: pca_explanations)
#>   diagnostics:    1 (active: diagnostics_pca_explanations_explanations)
#>   lod bundles:    1 (active: density_grid_pca_explanations)
#>   selected points:0
#>   selected feats: 0
```

## Principal components: `stats::prcomp()` on `USArrests`

PCA loadings can also be exposed as feature-level contributions.

``` r
arrests <- datasets::USArrests
pca_arrests <- stats::prcomp(arrests, center = TRUE, scale. = TRUE)
scaled_arrests <- scale(arrests, center = pca_arrests$center, scale = pca_arrests$scale)
pc1_contrib <- sweep(scaled_arrests, 2, pca_arrests$rotation[, 1], `*`)

pca_tbl <- data.frame(
point_id = rep(rownames(arrests), each = ncol(arrests)),
feature = rep(colnames(arrests), times = nrow(arrests)),
value = as.vector(t(pc1_contrib)),
x = rep(pca_arrests$x[, 1], each = ncol(arrests)),
y = rep(pca_arrests$x[, 2], each = ncol(arrests)),
z = rep(scale01(rowSums(abs(pc1_contrib))), each = ncol(arrests))
)

state_pca <- as_xgeo_state(
pca_tbl,
point_id_col = "point_id",
feature_col = "feature",
method = "pca-loading-contribution-geometry",
meta = list(dataset = "datasets::USArrests", model = "stats::prcomp")
)

state_pca <- finish_state(state_pca, k = 4L)
summary(state_pca)
#> <summary.xgeo_state>
#>   structure:      spatial
#>   method:         pca-loading-contribution-geometry
#>   points:         50
#>   features:       4
#>   explanations:   200
#>   embeddings:     2 (active: pca_explanations)
#>   diagnostics:    1 (active: diagnostics_pca_explanations_explanations)
#>   lod bundles:    1 (active: density_grid_pca_explanations)
#>   selected points:0
#>   selected feats: 0
```

## Regular-grid state: `datasets::volcano`

Matrix data can be converted into state and exposed as a regular grid
for downstream scientific-visualization packages.

``` r
state_volcano <- as_xgeo_state(
  datasets::volcano,
  method = "matrix-regular-grid",
  meta = list(dataset = "datasets::volcano")
)
state_volcano <- finish_state(state_volcano, embedding_source = "points", k = 4L)

point_tbl <- xgeo_point_values(state_volcano)
grid <- xgeo_regular_grid(point_tbl)
names(grid)
#> [1] "x" "y" "z"
```

## Backend-neutral exchange

Serialization writes to an explicit temporary file.

``` r
json_file <- tempfile(fileext = ".json")
write_xgeo_state(state_lm, json_file)
restored <- read_xgeo_state(json_file)

class(restored)
#> [1] "xgeo_state"
restored$attributes$embeddings$active
#> [1] "pca_explanations"
```

## Downstream handoff

Downstream packages consume public tables rather than internal state
details.

``` r
long_tbl <- xgeo_explanation_table(state_lm)
point_tbl <- xgeo_point_values(state_lm)

utils::head(long_tbl)
#>    point_id feature      value         x         y          z label response
#> 1 Mazda RX4      wt  2.6032916 0.2830478 0.6765502 0.27370651    wt     21.0
#> 2 Mazda RX4    qsec -0.7094203 0.2830478 0.6765502 0.27370651  qsec     21.0
#> 3 Mazda RX4      hp  0.6538546 0.2830478 0.6765502 0.27370651    hp     21.0
#> 4  Merc 280      wt -0.9709221 0.4927129 0.5331987 0.07873225    wt     19.2
#> 5  Merc 280    qsec  0.2305137 0.4927129 0.5331987 0.07873225  qsec     19.2
#> 6  Merc 280      hp  0.4221651 0.4927129 0.5331987 0.07873225    hp     19.2
#>     fitted   residual
#> 1 22.63835 -1.6383509
#> 2 22.63835 -1.6383509
#> 3 22.63835 -1.6383509
#> 4 19.77238 -0.5723817
#> 5 19.77238 -0.5723817
#> 6 19.77238 -0.5723817
utils::head(point_tbl)
#>            point_id         x         y           z      value response
#> 1         Mazda RX4 0.2830478 0.6765502 0.273706514  2.5477259     21.0
#> 2     Mazda RX4 Wag 0.3482485 0.6352636 0.122729451  1.7222995     21.0
#> 3        Datsun 710 0.2063411 0.8120459 0.439953430  5.2566361     22.8
#> 4    Hornet 4 Drive 0.4351828 0.6229704 0.004612335  1.4765260     21.4
#> 5 Hornet Sportabout 0.4927129 0.4541382 0.067000881 -1.8988686     18.7
#> 6           Valiant 0.4978266 0.5939425 0.502059129  0.8961823     18.1
#>     fitted   residual
#> 1 22.63835 -1.6383509
#> 2 21.81292 -0.8129245
#> 3 25.34726 -2.5472611
#> 4 21.56715 -0.1671510
#> 5 18.19176  0.5082436
#> 6 20.98681 -2.8868073
```
