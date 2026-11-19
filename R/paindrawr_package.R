#' @keywords internal
#' @section Terminology:
#' | Term | Meaning |
#' |---|---|
#' | pdr_drawing | Named list for one drawing: `.id`, `.file`, `.version`, `.width`, `.height`, `.units`, `.timestamp`, `.app`, `.template_file`, `.strokes`, `.points`, optional `.rgba`, `.stencil`, `.stencil_inverted` |
#' | pdr_list | A list of pdr_drawings (typically the list-column `pdr_data`) |
#' | pdr_tibble | A tibble with columns `id` and a pdr_list column (default name `pdr_data`) |
#'
#' See [pdr_match()] for validating and coercing between these types.
"_PACKAGE"

#' @importFrom stats quantile sd median IQR runif
#' @importFrom grDevices as.raster
#' @importFrom rlang :=
NULL

# Column names used via tidy evaluation (dplyr, ggplot2, tidyr, purrr
# formulas) and therefore not visible as variables to R CMD check.
utils::globalVariables(c(
  ".VAR1_grp",
  ".VAR2_grp",
  ".alpha",
  ".color",
  ".height",
  ".id",
  ".index",
  ".list_col",
  ".point_density",
  ".points",
  ".rgba",
  ".spray_radius",
  ".strokes",
  ".tool",
  ".tool_width",
  ".width",
  ".x",
  ".y",
  "alpha",
  "alpha_matrix",
  "alpha_sum",
  "angle",
  "cells",
  "color",
  "count",
  "device_pixel_ratio",
  "distance",
  "draw_input_type",
  "drawInputType",
  "i",
  "label",
  "line_width",
  "lineWidth",
  "lw",
  "n_group",
  "n_id_at_location",
  "offsetX",
  "offsetY",
  "p",
  "pct",
  "pdr",
  "pdr_data",
  "pdr_indx",
  "points",
  "radius",
  "scale_factor",
  "spray_density",
  "spray_radius",
  "sprayDensity",
  "sprayRadius",
  "spray_id",
  "stroke_id",
  "strokeId",
  "tool",
  "x",
  "x_bin",
  "y",
  "y_bin"
))
