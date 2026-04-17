#' Write a scene to JSON
#'
#' @param scene An `xgeo_scene` object.
#' @param path Output file path.
#' @param pretty Whether to pretty-print the JSON.
#'
#' @return The normalized output path, invisibly.
#' @export
write_xgeo_scene <- function(scene, path, pretty = TRUE) {
  .validate_xgeo_scene(scene)

  payload <- list(
    schema_version = .xgeo_schema_version(),
    package_version = as.character(utils::packageVersion("XGeoRTR")),
    scene = list(
      data = unclass(scene$data),
      layers = lapply(scene$layers, .serialize_layer),
      embeddings = list(
        active = scene$embeddings$active,
        items = lapply(scene$embeddings$items, unclass)
      ),
      diagnostics = scene$diagnostics,
      lod = scene$lod,
      views = scene$views,
      selection = scene$selection,
      camera = scene$camera,
      theme = scene$theme,
      render_backend = scene$render_backend,
      meta = scene$meta
    )
  )

  json <- jsonlite::toJSON(
    payload,
    pretty = pretty,
    auto_unbox = TRUE,
    dataframe = "rows",
    null = "null"
  )

  writeLines(json, con = path, useBytes = TRUE)
  invisible(normalizePath(path, winslash = "/", mustWork = FALSE))
}

.coerce_json_frame <- function(x, required = NULL) {
  if (is.null(x)) {
    return(NULL)
  }

  if (is.data.frame(x)) {
    return(x)
  }

  if (is.list(x) && length(x) == 0L) {
    out <- data.frame(stringsAsFactors = FALSE)
    if (!is.null(required)) {
      for (col in required) {
        out[[col]] <- character()
      }
    }
    return(out)
  }

  if (is.list(x) && !is.null(names(x)) && !all(names(x) == "")) {
    return(as.data.frame(x, stringsAsFactors = FALSE))
  }

  cli::cli_abort("Unable to coerce JSON payload into a data frame.")
}

#' Read a scene from JSON
#'
#' @param path Path to a JSON scene file.
#'
#' @return An `xgeo_scene` object.
#' @export
read_xgeo_scene <- function(path) {
  payload <- jsonlite::fromJSON(path, simplifyDataFrame = TRUE)

  if (!identical(payload$schema_version, .xgeo_schema_version())) {
    cli::cli_warn(
      "Reading scene schema {.val {payload$schema_version}} with XGeoRTR schema {.val {.xgeo_schema_version()}}."
    )
  }

  data <- new_xgeo_data(
    points = .coerce_json_frame(payload$scene$data$points, c("point_id", "x", "y", "z")),
    explanations = .coerce_json_frame(payload$scene$data$explanations, c("point_id", "feature", "value")),
    point_meta = .coerce_json_frame(payload$scene$data$point_meta, "point_id"),
    feature_meta = .coerce_json_frame(payload$scene$data$feature_meta, "feature"),
    predictions = .coerce_json_frame(payload$scene$data$predictions, "point_id"),
    uncertainty = .coerce_json_frame(payload$scene$data$uncertainty, "point_id"),
    baseline = payload$scene$data$baseline,
    structure = payload$scene$data$structure,
    method = payload$scene$data$method,
    meta = payload$scene$data$meta
  )

  scene <- xgeo_scene(
    x = data,
    embeddings = payload$scene$embeddings,
    diagnostics = payload$scene$diagnostics,
    lod = payload$scene$lod,
    views = payload$scene$views,
    selection = payload$scene$selection,
    camera = payload$scene$camera,
    theme = payload$scene$theme,
    render_backend = payload$scene$render_backend,
    meta = payload$scene$meta
  )

  scene$layers <- lapply(payload$scene$layers, .deserialize_layer)
  .validate_xgeo_scene(scene)
  scene
}
