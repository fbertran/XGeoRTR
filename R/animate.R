#' Attach orbit animation metadata to a scene
#'
#' @param scene An `xgeo_scene` object.
#' @param frames Number of animation frames.
#' @param axis Rotation axis. One of `"x"`, `"y"`, or `"z"`.
#' @param step Degrees per frame.
#'
#' @return The updated `xgeo_scene`.
#' @export
animate_camera_orbit <- function(scene,
                                 frames = 36L,
                                 axis = "z",
                                 step = 5) {
  if (!inherits(scene, "xgeo_scene")) {
    cli::cli_abort("{.arg scene} must be an {.cls xgeo_scene}.")
  }
  if (!.is_count(frames)) {
    cli::cli_abort("{.arg frames} must be a positive whole number.")
  }
  if (!(axis %in% c("x", "y", "z"))) {
    cli::cli_abort("{.arg axis} must be one of {.val {c('x', 'y', 'z')}}.")
  }
  if (!.is_scalar_numeric(step) || step <= 0) {
    cli::cli_abort("{.arg step} must be a positive numeric scalar.")
  }

  scene$animation <- list(
    frames = as.integer(frames),
    axis = axis,
    step = step
  )

  scene
}
