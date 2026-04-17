# Internal MVP constants for XGeoRTR.

.xgeo_supported_structures <- function() {
  "spatial"
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
