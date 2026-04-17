# Internal constants and helpers for XGeoRTR.

.xgeo_supported_structures <- function() {
  "spatial"
}

.xgeo_schema_version <- function() {
  "0.2.0"
}

.or_default <- function(x, default) {
  if (is.null(x)) {
    default
  } else {
    x
  }
}

.is_scalar_numeric <- function(x) {
  is.numeric(x) && length(x) == 1L && !is.na(x)
}

.is_scalar_flag <- function(x) {
  is.logical(x) && length(x) == 1L && !is.na(x)
}

.is_scalar_string <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x)
}

.is_count <- function(x) {
  .is_scalar_numeric(x) && x >= 1 && abs(x - round(x)) < sqrt(.Machine$double.eps)
}

.is_named_list <- function(x) {
  is.list(x) && !is.null(names(x))
}

.empty_df <- function(...) {
  data.frame(..., stringsAsFactors = FALSE)
}

.normalize_table <- function(x, required = NULL, name = "table") {
  if (is.null(x)) {
    return(NULL)
  }

  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg {name}} must be a data frame.")
  }

  if (!is.null(required)) {
    .assert_required_columns(x, required, arg = name)
  }

  x <- as.data.frame(x, stringsAsFactors = FALSE)
  rownames(x) <- NULL
  x
}
