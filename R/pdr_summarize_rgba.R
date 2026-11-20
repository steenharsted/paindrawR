#' Summarise the alpha values of drawn pixels in a pain drawing
#'
#' Computes summary statistics of the alpha channel of the `.rgba` array of
#' each drawing, using only pixels whose alpha falls within `alpha_range`
#' (lower bound exclusive, upper bound inclusive). The number of drawn pixels
#' (`px`) and the proportion of the canvas covered (`area_prop`) describe how
#' much was drawn, while e.g. `mean` or `median` describe how dark or opaque
#' the strokes are. Optionally, each drawing is first multiplied by one or more
#' stencils (e.g. body regions) so that statistics are computed per region.
#'
#' The drawings must already contain `.rgba`; see [pdr_add_rgba()]. For the
#' terms pdr_drawing, pdr_list and pdr_tibble, see [pdr_match()].
#'
#' @inheritParams pdr_plot_rgba
#' @param pdr_col <[`tidy-select`][tidyselect::language]> One or more
#'   list-columns of `.data` (pdr_lists) with `.rgba` in each drawing. Defaults
#'   to `pdr_data`. Unquoted names, strings and selections such as
#'   `c(a, b)` are accepted; each selected column is summarised separately.
#' @param summary_stat Character vector of statistics to compute from the alpha
#'   values of the included pixels. Any of `"px"` (number of pixels),
#'   `"area_prop"` (`px` divided by the canvas area `.width * .height`, or by
#'   the number of pixels inside the stencil when `stencils` is given),
#'   `"mean"`, `"sd"`,
#'   `"median"`, `"iqr"`, `"min"`, `"max"`, `"q1"`, `"q5"`, `"q10"`, `"q25"`,
#'   `"q75"`, `"q90"`, `"q95"` and `"q99"` (the `q` statistics are quantiles
#'   at probabilities 0.01, 0.05, ..., 0.99). Two shortcuts are available when
#'   given as a single string: `"seven"` (default) is `px`, `mean`, `max`,
#'   `min`, `median`, `sd` and `iqr`; `"all"` is `seven` plus `area_prop`,
#'   `q1`, `q5`, `q25`, `q75`, `q90`, `q95` and `q99` (note: `q10` is *not*
#'   included in `"all"`, but can be requested explicitly). Columns are
#'   returned in a fixed order, not in the order requested: `px`, `area_prop`,
#'   `mean`, `sd`, `median`, `iqr`, `min`, `max`, `q1`, `q5`, `q10`, `q25`,
#'   `q75`, `q90`, `q95`, `q99` (restricted to those requested). Note this
#'   differs from the order in which `"seven"` is listed above.
#' @param alpha_range Numeric vector of length 2 giving the lower (exclusive)
#'   and upper (inclusive) alpha bounds of pixels to include, with
#'   `0 <= alpha_range[1] < alpha_range[2] <= 1`. Defaults to `c(0, 1)`, i.e.
#'   all drawn pixels. Use e.g. `c(0.5, 1)` to restrict to heavily drawn pixels.
#' @param stencils Optional pdr_list in which each element has a `.stencil`
#'   (a height x width matrix of 0/1) and an `.id`, e.g. the list-column
#'   `pdr_stencil_full_body$pdr_data` or a list built with [pdr_add_stencil()]. Each stencil is applied
#'   (multiplied) to the alpha channel of every drawing before summarising, so
#'   the stencil dimensions must match the drawings. Defaults to `NULL`
#'   (no stencil). Note that this is deliberately plural and differs from
#'   `stencil` in [pdr_modify_rgba()].
#'
#' @returns `.data` (a pdr_tibble) with added numeric columns, one per selected
#'   `pdr_col` and statistic (and per stencil, if `stencils` is given). Columns
#'   are named `<pdr_col>_<stat>` without stencils, and
#'   `<pdr_col>_<stencil id>_<stat>` with stencils, e.g. `pdr_data_mean` or
#'   `pdr_data_Back_head_mean`. If no pixels fall in `alpha_range`, `px` is 0,
#'   `mean`, `sd`, `median`, `iqr` and quantiles are `NA`, and `min`/`max` are
#'   `Inf`/`-Inf` (with a warning). If a drawing is missing (`NA`), its `.rgba`
#'   is `NA`, or its alpha channel is entirely `NA`, all statistics for that
#'   drawing, including `px`, are `NA`. Individual `NA` pixels are ignored.
#'
#' @param inverted_stencil Logical. If `TRUE`, use each stencil's
#'   `.stencil_inverted` instead of `.stencil`. Default `FALSE`. Ignored when
#'   `stencils` is `NULL`.
#'
#' @seealso [pdr_add_rgba()] to add `.rgba`, [pdr_add_stencil()] and
#'   [pdr_modify_rgba()] for stencils, [pdr_plot_rgba()] to plot the arrays.
#'
#' @importFrom stats quantile sd median IQR
#' @export
#' @examples
#' pd <- pdr_example_data |>
#'   dplyr::mutate(pdr_data = pdr_add_rgba(pdr_data))
#'
#' # Default: the "seven" statistics across all drawn pixels
#' pdr_summarize_rgba(pd)
#'
#' # Selected statistics, only heavily drawn pixels
#' pdr_summarize_rgba(
#'   pd,
#'   summary_stat = c("px", "area_prop", "mean"),
#'   alpha_range = c(0.5, 1)
#' )
#'
#' # Per stencil (here, two body regions)
#' pdr_summarize_rgba(
#'   pd,
#'   summary_stat = "px",
#'   stencils = pdr_stencil_full_body$pdr_data[1:2]
#' )
pdr_summarize_rgba <- function(.data, pdr_col = pdr_data, summary_stat = "seven", alpha_range = c(0, 1), stencils = NULL, inverted_stencil = FALSE) {
  ############################
  ##### Helper functions #####
  ############################

  # We must handle both string input, unquoted col names, and 1 or more at the same time
  pdr_col <- names(
    tidyselect::eval_select(
      rlang::enquo(pdr_col),
      .data
    )
  )

  summarize_drawing_as_tibble <- function(
    one_pdr_list,
    summary_stat,
    alpha_range,
    one_stencil,
    col_name
  ) {
    # This function is intended to take a single pdr_list as input and iterate over each drawing
    # Apply a single stencil (a matrix) and apply an alpha range, before calculating a number
    # of summary statistics and returning the result as a tibble of same number of rows as pdr_list
    # with columns of col_name as prefix to the statistical summary function.

    # It is worth noting: The calculations are performed on the alpha channel only. Initially, we
    # apply the stencil to the full (width x height) alpha channel (.rgba[,,4]) which will retain
    # the alpha value of all pixels inside the stencil and set every the alpha value to 0 for all
    # pixels outside the stencil. We then simply filter out all pixels with alpha values not within
    # the specificed alpha_range and in the process, convert the alpha_channel from a width x height
    # matrix to a variable length vector.

    # No stencil (NULL) means the whole canvas is used
    one_pdr_list |>
      purrr::map_dfr(\(pdr_drawing) {
        # A missing drawing (NA), missing .rgba, or an alpha channel that is
        # entirely NA cannot be summarised: all statistics are NA (not px = 0)
        is_missing <- !is.list(pdr_drawing) ||
          !is.array(pdr_drawing$.rgba) ||
          all(is.na(pdr_drawing$.rgba[,, 4]))

        if (is_missing) {
          alpha_channel <- NA_integer_
          # case_when() evaluates every branch, so parent_area must exist
          parent_area <- NA_real_
        } else {
          alpha_channel <- pdr_drawing$.rgba[,, 4]
          # get the area of the 'parent area' -- either the canvas or stencil
          parent_area <- if (is.null(one_stencil)) {
            length(alpha_channel)
          } else {
            sum(one_stencil != 0, na.rm = TRUE)
          }
          # apply stencil to alpha_channel (dimensions are unchanged)
          if (!is.null(one_stencil)) {
            alpha_channel <- alpha_channel * one_stencil
          }
          # apply alpha range to alpha_channel (NOTE! after this alpha_channel is no longer an array
          # and its length has changed)
          alpha_channel <- alpha_channel[!is.na(alpha_channel)]
          alpha_channel <- alpha_channel[
            alpha_channel > alpha_range[1] & alpha_channel <= alpha_range[2]
          ]
        }

        is_empty <- length(alpha_channel) == 0 # Nothing within alpha_range inside stencil/canvas

        result_tib <- tibble::tibble(.rows = 1)

        if ("px" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            px = dplyr::case_when(
              is_missing ~ NA_integer_,
              is_empty ~ 0,
              .default = length(alpha_channel)
            )
          )
        }

        if ("area_prop" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            area_prop = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = length(alpha_channel) / parent_area
            )
          )
        }

        if ("mean" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            mean = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = mean(alpha_channel, na.rm = TRUE)
            )
          )
        }

        if ("sd" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            sd = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = sd(alpha_channel, na.rm = TRUE)
            )
          )
        }

        if ("median" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            median = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = median(alpha_channel, na.rm = TRUE)
            )
          )
        }

        if ("iqr" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            iqr = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = IQR(alpha_channel, na.rm = TRUE)
            )
          )
        }

        if ("min" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            min = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = min(alpha_channel, na.rm = TRUE)
            )
          )
        }

        if ("max" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            max = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = max(alpha_channel, na.rm = TRUE)
            )
          )
        }

        if ("q1" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            q1 = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = quantile(alpha_channel, probs = 0.01, na.rm = TRUE)
            )
          )
        }

        if ("q5" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            q5 = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = quantile(alpha_channel, probs = 0.05, na.rm = TRUE)
            )
          )
        }

        if ("q10" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            q10 = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = quantile(alpha_channel, probs = 0.10, na.rm = TRUE)
            )
          )
        }

        if ("q25" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            q25 = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = quantile(alpha_channel, probs = 0.25, na.rm = TRUE)
            )
          )
        }

        if ("q75" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            q75 = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = quantile(alpha_channel, probs = 0.75, na.rm = TRUE)
            )
          )
        }

        if ("q90" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            q90 = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = quantile(alpha_channel, probs = 0.90, na.rm = TRUE)
            )
          )
        }

        if ("q95" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            q95 = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = quantile(alpha_channel, probs = 0.95, na.rm = TRUE)
            )
          )
        }

        if ("q99" %in% summary_stat) {
          result_tib <- dplyr::bind_cols(
            result_tib,
            q99 = dplyr::case_when(
              is_missing ~ NA_real_,
              is_empty ~ 0,
              .default = quantile(alpha_channel, probs = 0.99, na.rm = TRUE)
            )
          )
        }

        names(result_tib) <- paste0(col_name, "_", names(result_tib))
        return(result_tib)
      })
  }

  #########################
  ##### Sanity checks #####
  #########################
  if (identical(summary_stat, "seven")) {
    summary_stat <- c("px", "mean", "max", "min", "median", "sd", "iqr")
  } else if (identical(summary_stat, "all")) {
    summary_stat <- c(
      "px",
      "area_prop",
      "mean",
      "max",
      "min",
      "median",
      "sd",
      "iqr",
      "q1",
      "q5",
      "q25",
      "q75",
      "q90",
      "q95",
      "q99"
    )
  }

  # alpha_range is valid
  if (
    !is.numeric(alpha_range) ||
      length(alpha_range) != 2 ||
      any(is.na(alpha_range)) ||
      alpha_range[1] < 0 ||
      alpha_range[2] > 1 ||
      alpha_range[1] >= alpha_range[2]
  ) {
    stop(
      "`alpha_range` must be a numeric vector of length 2 with 0 <= alpha_range[1] < alpha_range[2] <= 1."
    )
  }
  # Stencils must be a pdr_list
  if (!pdr_match(stencils, as = "pdr_list")) {
    if (!is.null(stencils)) {
      stop(
        "Parameter 'stencils' is not a valid pdr_list with .stencil elements"
      )
    }
  }
  #########################
  ### End sanity cheks ####
  #########################

  ##########################
  ####### Main loops #######
  ##########################

  # If no stencils are supplied:
  if (is.null(stencils)) {
    for (i in pdr_col) {
      .data <- dplyr::bind_cols(
        .data,
        summarize_drawing_as_tibble(
          one_pdr_list = .data[[i]],
          summary_stat = summary_stat,
          alpha_range = alpha_range,
          one_stencil = NULL,
          col_name = i
        )
      )
    }
  } else {
    for (i in pdr_col) {
      for (j in seq_along(stencils)) {
        .data <- dplyr::bind_cols(
          .data,
          summarize_drawing_as_tibble(
            one_pdr_list = .data[[i]],
            summary_stat = summary_stat,
            alpha_range = alpha_range,
            one_stencil = if (inverted_stencil) {
              stencils[[j]]$.stencil_inverted
            } else {
              stencils[[j]]$.stencil
            },
            col_name = paste0(i, "_", stencils[[j]]$.id)
          )
        )
      }
    }
  }

  .data
}
