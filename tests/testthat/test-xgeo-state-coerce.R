test_that("as_xgeo_state.matrix creates a spatial grid", {
  state <- as_xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2), method = "grid-demo")

  expect_s3_class(state, "xgeo_state")
  expect_equal(state$attributes$method, "grid-demo")
  expect_equal(nrow(state$geometry$points), 4L)
  expect_equal(nrow(state$attributes$explanations), 4L)
  expect_equal(sort(unique(state$geometry$points$x)), c(1, 2))
  expect_equal(sort(unique(state$geometry$points$y)), c(1, 2))
})

test_that("as_xgeo_state.data.frame preserves unmapped point metadata", {
  state <- as_xgeo_state(
    data.frame(
      point_id = c("p1", "p1", "p2"),
      feature = c("f1", "f2", "f1"),
      x = c(0, 0, 1),
      y = c(0, 0, 1),
      value = c(1, -0.5, 0.75),
      cluster = c("A", "A", "B"),
      confidence = c(0.2, 0.2, 0.1)
    ),
    point_id_col = "point_id",
    feature_col = "feature"
  )

  expect_true(all(c("cluster", "confidence") %in% names(state$attributes$point_meta)))
  expect_equal(nrow(state$attributes$point_meta), 2L)
  expect_equal(
    state$attributes$point_meta$cluster[match("p1", state$attributes$point_meta$point_id)],
    "A"
  )
})

test_that("as_xgeo_state.data.frame rejects conflicting point metadata", {
  expect_error(
    as_xgeo_state(
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

test_that("as_xgeo_state.data.frame auto-detects canonical columns", {
  state <- as_xgeo_state(
    data.frame(
      point_id = c("p1", "p1", "p2"),
      feature = c("f1", "f2", "f1"),
      x = c(0, 0, 1),
      y = c(0, 0, 1),
      z = c(2, 2, 3),
      value = c(1, -0.5, 0.75),
      cluster = c("A", "A", "B")
    )
  )

  expect_equal(sort(state$indices$point_ids), c("p1", "p2"))
  expect_equal(state$geometry$points$z[match("p1", state$geometry$points$point_id)], 2)
  expect_equal(sort(unique(state$indices$feature_ids)), c("f1", "f2"))
  expect_true("cluster" %in% names(state$attributes$point_meta))
})

test_that("as_xgeo_state.data.frame falls back to dim1/dim2/dim3 coordinates", {
  state <- as_xgeo_state(
    data.frame(
      point_id = c("p1", "p2"),
      feature = c("f1", "f2"),
      dim1 = c(10, 20),
      dim2 = c(1, 2),
      dim3 = c(-1, -2),
      value = c(0.5, -0.75)
    )
  )

  expect_equal(state$geometry$points$point_id, c("p1", "p2"))
  expect_equal(state$geometry$points$x, c(10, 20))
  expect_equal(state$geometry$points$y, c(1, 2))
  expect_equal(state$geometry$points$z, c(-1, -2))
})
