demo_points <- function() {
  data.frame(
    point_id = c("p1", "p2"),
    x = c(0, 1),
    y = c(0, 1),
    z = c(0, 0),
    stringsAsFactors = FALSE
  )
}

demo_explanations <- function() {
  data.frame(
    point_id = c("p1", "p2"),
    feature = c("f1", "f1"),
    value = c(1, -1),
    stringsAsFactors = FALSE
  )
}

new_demo_xgeo_data <- function(...) {
  new_xgeo_data(
    points = demo_points(),
    explanations = demo_explanations(),
    ...
  )
}

demo_backend_state <- function(point_ids, features) {
  list(
    embeddings = list(
      active = "demo",
      items = list(
        demo = list(
          coords = data.frame(
            point_id = point_ids,
            dim1 = seq_along(point_ids),
            dim2 = rev(seq_along(point_ids)),
            stringsAsFactors = FALSE
          )
        )
      )
    ),
    diagnostics = list(
      active = "diag_demo",
      items = list(diag_demo = list(name = "diag_demo"))
    ),
    lod = list(
      active = list(name = "lod_demo", level = "8"),
      items = list(
        lod_demo = list(
          levels = setNames(list(list(count = length(point_ids))), "8"),
          default_level = "8"
        )
      ),
      auto = list(point_threshold = 5L)
    ),
    selection = list(
      point_ids = point_ids[[1]],
      features = features[[1]]
    )
  )
}

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

test_that("new_xgeo_data creates default backend state", {
  xd <- new_demo_xgeo_data()

  expect_equal(xd$embeddings$active, "spatial")
  expect_true("spatial" %in% names(xd$embeddings$items))
  expect_equal(xd$embeddings$items$spatial$coords$point_id, xd$points$point_id)
  expect_null(xd$diagnostics$active)
  expect_length(xd$diagnostics$items, 0L)
  expect_null(xd$lod$active$name)
  expect_null(xd$lod$active$level)
  expect_length(xd$lod$items, 0L)
  expect_equal(xd$selection$point_ids, character())
  expect_equal(xd$selection$features, character())
})

test_that("validate_xgeo_data rejects renderer-specific fields", {
  xd <- new_demo_xgeo_data()
  xd$camera <- list(preset = "top")

  expect_error(
    validate_xgeo_data(xd),
    "renderer-specific fields"
  )
})

test_that("new_xgeo_data rejects unknown selection point ids and features", {
  expect_error(
    new_demo_xgeo_data(selection = list(point_ids = "missing")),
    "unknown points"
  )

  expect_error(
    new_demo_xgeo_data(selection = list(features = "missing_feature")),
    "unknown features"
  )
})

test_that("new_xgeo_data rejects malformed or unknown backend state references", {
  expect_error(
    new_demo_xgeo_data(
      embeddings = list(
        active = "missing",
        items = list(
          demo = list(
            coords = data.frame(
              point_id = c("p1", "p2"),
              dim1 = c(0, 1),
              dim2 = c(1, 0),
              stringsAsFactors = FALSE
            )
          )
        )
      )
    ),
    "Unknown active embedding"
  )

  expect_error(
    new_demo_xgeo_data(
      embeddings = list(
        active = "demo",
        items = list(
          demo = list(
            coords = data.frame(
              point_id = c("p1", "p1"),
              dim1 = c(0, 1),
              dim2 = c(1, 0),
              stringsAsFactors = FALSE
            )
          )
        )
      )
    ),
    "unique .*point_id"
  )

  expect_error(
    new_demo_xgeo_data(
      lod = list(
        active = list(name = "missing", level = "8"),
        items = list()
      )
    ),
    "Unknown active LOD bundle"
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

test_that("as_xgeo_data.data.frame auto-detects canonical point_id, feature, and z columns", {
  xd <- as_xgeo_data(
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

  expect_equal(sort(xd$points$point_id), c("p1", "p2"))
  expect_equal(xd$points$z[match("p1", xd$points$point_id)], 2)
  expect_equal(sort(unique(xd$feature_meta$feature)), c("f1", "f2"))
  expect_true("cluster" %in% names(xd$point_meta))
})

test_that("as_xgeo_data.data.frame falls back to dim1, dim2, and dim3 coordinates", {
  xd <- as_xgeo_data(
    data.frame(
      point_id = c("p1", "p2"),
      feature = c("f1", "f2"),
      dim1 = c(10, 20),
      dim2 = c(1, 2),
      dim3 = c(-1, -2),
      value = c(0.5, -0.75)
    )
  )

  expect_equal(xd$points$point_id, c("p1", "p2"))
  expect_equal(xd$points$x, c(10, 20))
  expect_equal(xd$points$y, c(1, 2))
  expect_equal(xd$points$z, c(-1, -2))
})

test_that("as_xgeo_data.matrix accepts dim1, dim2, and dim3 coordinates", {
  xd <- as_xgeo_data(
    matrix(seq_len(4), ncol = 1),
    coordinates = data.frame(
      point_id = paste0("p", 1:4),
      dim1 = c(0, 1, 0, 1),
      dim2 = c(0, 0, 1, 1),
      dim3 = c(5, 5, 6, 6),
      cluster = c("A", "A", "B", "B")
    )
  )

  expect_equal(xd$points$x, c(0, 1, 0, 1))
  expect_equal(xd$points$y, c(0, 0, 1, 1))
  expect_equal(xd$points$z, c(5, 5, 6, 6))
  expect_true("cluster" %in% names(xd$point_meta))
})

test_that("as_xgeo_data.data.frame preserves backend state arguments", {
  state <- demo_backend_state(point_ids = c("p1", "p2"), features = c("f1", "f2"))

  xd <- as_xgeo_data(
    data.frame(
      point_id = c("p1", "p2"),
      feature = c("f1", "f2"),
      x = c(0, 1),
      y = c(0, 1),
      value = c(1, -1)
    ),
    embeddings = state$embeddings,
    diagnostics = state$diagnostics,
    lod = state$lod,
    selection = state$selection
  )

  expect_equal(xd$embeddings$active, "demo")
  expect_equal(xd$diagnostics$active, "diag_demo")
  expect_equal(xd$lod$active$name, "lod_demo")
  expect_equal(xd$lod$active$level, "8")
  expect_equal(xd$selection$point_ids, "p1")
  expect_equal(xd$selection$features, "f1")
})

test_that("as_xgeo_data.matrix preserves backend state arguments", {
  state <- demo_backend_state(point_ids = paste0("p", 1:4), features = "value")

  xd <- as_xgeo_data(
    matrix(seq_len(4), ncol = 1),
    coordinates = data.frame(
      point_id = paste0("p", 1:4),
      x = c(0, 1, 0, 1),
      y = c(0, 0, 1, 1)
    ),
    embeddings = state$embeddings,
    diagnostics = state$diagnostics,
    lod = state$lod,
    selection = state$selection
  )

  expect_equal(xd$embeddings$active, "demo")
  expect_equal(xd$diagnostics$active, "diag_demo")
  expect_equal(xd$lod$active$name, "lod_demo")
  expect_equal(xd$selection$point_ids, "p1")
  expect_equal(xd$selection$features, "value")
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
  expect_equal(smry$n_features, 3L)
  expect_equal(unname(smry$range), c(-2, 3))
})
