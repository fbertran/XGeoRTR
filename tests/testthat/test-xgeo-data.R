test_that("new_xgeo_data rejects unsupported structures", {
  expect_error(
    new_xgeo_data(
      values = c(1, 2, 3),
      coordinates = data.frame(x = 1:3, y = 1:3),
      structure = "temporal"
    ),
    "spatial"
  )
})

test_that("new_xgeo_data rejects inconsistent dimensions", {
  expect_error(
    new_xgeo_data(
      values = c(1, 2, 3),
      coordinates = data.frame(x = 1:2, y = 1:2)
    ),
    "same number of rows"
  )
})

test_that("as_xgeo_data.matrix creates a spatial grid", {
  xd <- as_xgeo_data(matrix(c(1, -1, 2, 0), nrow = 2), method = "grid-demo")

  expect_s3_class(xd, "xgeo_data")
  expect_equal(xd$method, "grid-demo")
  expect_equal(nrow(xd$data), 4L)
  expect_equal(sort(unique(xd$data$x)), c(1, 2))
  expect_equal(sort(unique(xd$data$y)), c(1, 2))
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
  expect_equal(smry$n_features, 3L)
  expect_equal(unname(smry$range), c(-2, 3))
})
