#' Write a backend state to JSON
#'
#' @param state An `xgeo_state` object.
#' @param path Output file path.
#' @param pretty Whether to pretty-print the JSON.
#'
#' @return The normalized output path, invisibly.
#'
#' @examples
#' state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
#' path <- tempfile(fileext = ".json")
#'
#' write_xgeo_state(state, path)
#' file.exists(path)
#' @export
write_xgeo_state <- function(state, path, pretty = TRUE) {
  validate_xgeo_state(state)

  attributes <- state$attributes
  attributes$embeddings <- list(
    active = attributes$embeddings$active,
    items = lapply(attributes$embeddings$items, unclass)
  )

  payload <- list(
    schema_version = .xgeo_schema_version(),
    package_version = as.character(utils::packageVersion("XGeoRTR")),
    state = list(
      geometry = state$geometry,
      attributes = attributes,
      indices = state$indices,
      selection = state$selection,
      lod = state$lod,
      metadata = state$metadata
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

.coerce_embeddings <- function(embeddings) {
  if (is.null(embeddings)) {
    return(NULL)
  }

  items <- .or_default(embeddings$items, list())
  if (length(items) > 0L) {
    items <- lapply(items, function(item) {
      item$coords <- .coerce_json_frame(item$coords, c("point_id", "dim1", "dim2"))
      item
    })
  }

  list(active = embeddings$active, items = items)
}

#' Read a backend state from JSON
#'
#' @param path Path to a JSON state file.
#'
#' @return An `xgeo_state` object.
#'
#' @examples
#' state <- xgeo_state(matrix(c(1, -1, 2, 0), nrow = 2))
#' path <- tempfile(fileext = ".json")
#' write_xgeo_state(state, path)
#'
#' restored <- read_xgeo_state(path)
#' class(restored)
#' @export
read_xgeo_state <- function(path) {
  payload <- jsonlite::fromJSON(path, simplifyDataFrame = TRUE)

  if (!identical(payload$schema_version, .xgeo_schema_version())) {
    cli::cli_warn(
      "Reading state schema {.val {payload$schema_version}} with XGeoRTR schema {.val {.xgeo_schema_version()}}."
    )
  }

  state_payload <- payload$state

  new_xgeo_state(
    geometry = list(
      points = .coerce_json_frame(state_payload$geometry$points, c("point_id", "x", "y", "z"))
    ),
    attributes = list(
      explanations = .coerce_json_frame(state_payload$attributes$explanations, c("point_id", "feature", "value")),
      point_meta = .coerce_json_frame(state_payload$attributes$point_meta, "point_id"),
      feature_meta = .coerce_json_frame(state_payload$attributes$feature_meta, "feature"),
      predictions = .coerce_json_frame(state_payload$attributes$predictions, "point_id"),
      uncertainty = .coerce_json_frame(state_payload$attributes$uncertainty, "point_id"),
      embeddings = .coerce_embeddings(state_payload$attributes$embeddings),
      diagnostics = state_payload$attributes$diagnostics,
      baseline = state_payload$attributes$baseline,
      method = state_payload$attributes$method,
      structure = state_payload$attributes$structure
    ),
    indices = state_payload$indices,
    selection = state_payload$selection,
    lod = state_payload$lod,
    metadata = state_payload$metadata
  )
}
