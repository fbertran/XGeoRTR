test_that("new_xgeo_data rejects unsupported structures", {
  expect_error(
    new_xgeo_data(
      points = data.frame(point_id = paste0("p", 1:3), x = 1:3, y = 1:3),
      explanations = data.frame(point_id = paste0("p", 1:3), feature = "value", value = 1:3),
      structure = "temporal"
    ),
    "spatial"
  )
})

test_that("new_xgeo_data rejects inconsistent dimensions", {
  expect_error(
    new_xgeo_data(
      points = data.frame(point_id = c("p1", "p2"), x = 1:2, y = 1:2),
      explanations = data.frame(point_id = c("p1", "p3"), feature = "value", value = c(1, 2))
    ),
    "unknown points"
  )
})

test_that("as_xgeo_data.matrix creates a spatial grid", {
  xd <- as_xgeo_data(matrix(c(1, -1, 2, 0), nrow = 2), method = "grid-demo")

  expect_s3_class(xd, "xgeo_data")
  expect_equal(xd$method, "grid-demo")
  expect_equal(nrow(xd$points), 4L)
  expect_equal(nrow(xd$explanations), 4L)
  expect_equal(sort(unique(xd$points$x)), c(1, 2))
  expect_equal(sort(unique(xd$points$y)), c(1, 2))
})

test_that("as_xgeo_data.data.frame preserves unmapped point metadata", {
  xd <- as_xgeo_data(
    data.frame(
      point_id = c("p1", "p1", "p2"),
      feature = c("f1", "f2", "f1"),
      x = c(0, 0, 1),
      y = c(0, 0, 1),
      value = c(1, -0.5, 0.75),
      cluster = c("A", "A", "B"),
      uncertainty = c(0.2, 0.2, 0.1)
    ),
    point_id_col = "point_id",
    feature_col = "feature"
  )

  expect_true(all(c("cluster", "uncertainty") %in% names(xd$point_meta)))
  expect_equal(nrow(xd$point_meta), 2L)
  expect_equal(xd$point_meta$cluster[match("p1", xd$point_meta$point_id)], "A")
})

test_that("as_xgeo_data.data.frame rejects conflicting point metadata", {
  expect_error(
    as_xgeo_data(
      data.frame(
        point_id = c("p1", "p1"),
        feature = c("f1", "f2"),
        x = c(0, 0),
        y = c(0, 0),
        value = c(1, -0.5),
        cluster = c("A", "B")
      ),
      point_id_col = "point_id",
      feature_col = "feature"
    ),
    "conflicting point-level metadata"
  )
})

test_that("summary.xgeo_data reports key dimensions", {
  xd <- as_xgeo_data(
    data.frame(
      feature = c("a", "b", "c"),
      x = c(1, 2, 3),
      y = c(1, 2, 3),
      z = 0,
      value = c(1, -2, 3)
    ),
    method = "summary-demo"
  )
  smry <- summary(xd)

  expect_s3_class(smry, "summary.xgeo_data")
  expect_equal(smry$method, "summary-demo")
  expect_equal(smry$n_points, 3L)
  expect_equal(smry$n_explanations, 3L)
  expect_equal(smry$n_features, 1L)
  expect_equal(unname(smry$range), c(-2, 3))
})
