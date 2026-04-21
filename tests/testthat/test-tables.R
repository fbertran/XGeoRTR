test_that("xgeo_explanation_table applies selection and preserves metadata", {
  state <- as_xgeo_state(
    data.frame(
      point_id = c("p1", "p1", "p2"),
      feature = c("f1", "f2", "f1"),
      x = c(0, 0, 1),
      y = c(0, 0, 1),
      value = c(1, -0.5, 0.75),
      cluster = c("A", "A", "B"),
      confidence = c(0.9, 0.9, 0.4)
    ),
    point_id_col = "point_id",
    feature_col = "feature"
  )
  state <- set_xgeo_selection(state, point_ids = "p1", features = "f2")

  selected_tbl <- xgeo_explanation_table(state)
  all_tbl <- xgeo_explanation_table(state, selected = FALSE)

  expect_equal(nrow(selected_tbl), 1L)
  expect_equal(selected_tbl$point_id, "p1")
  expect_equal(selected_tbl$feature, "f2")
  expect_equal(selected_tbl$value, -0.5)
  expect_equal(selected_tbl$cluster, "A")
  expect_equal(selected_tbl$confidence, 0.9)
  expect_equal(nrow(all_tbl), 3L)
})

test_that("xgeo_point_values aggregates selected features and preserves point metadata", {
  state <- as_xgeo_state(
    data.frame(
      point_id = c("p1", "p1", "p2", "p2"),
      feature = c("f1", "f2", "f1", "f2"),
      x = c(0, 0, 1, 1),
      y = c(0, 0, 1, 1),
      value = c(1, -0.25, 0.75, 2),
      cluster = c("A", "A", "B", "B")
    ),
    point_id_col = "point_id",
    feature_col = "feature"
  )
  state <- set_xgeo_selection(state, features = "f1")

  point_tbl <- xgeo_point_values(state)

  expect_equal(point_tbl$value[match("p1", point_tbl$point_id)], 1)
  expect_equal(point_tbl$value[match("p2", point_tbl$point_id)], 0.75)
  expect_equal(point_tbl$cluster[match("p2", point_tbl$point_id)], "B")
})

test_that("xgeo_regular_grid validates complete two-dimensional grids", {
  grid <- xgeo_regular_grid(
    data.frame(
      x_coord = c(0, 1, 0, 1),
      y_coord = c(0, 0, 1, 1),
      score = c(1, 2, 3, 4)
    ),
    x = "x_coord",
    y = "y_coord",
    value = "score"
  )

  expect_equal(grid$x, c(0, 1))
  expect_equal(grid$y, c(0, 1))
  expect_equal(grid$z[1, 1], 1)
  expect_equal(grid$z[2, 2], 4)

  expect_error(
    xgeo_regular_grid(
      data.frame(x = c(0, 1, 0), y = c(0, 0, 1), value = c(1, 2, 3))
    ),
    "Regular-grid data"
  )
})
