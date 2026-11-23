#' Extract information from pain drawing objects
#'
#' Extracts variables from a pdr_list (see [pdr_match()]). Simple 
#' elements (such as `".id"` or `".timestamp"`) are returned as 
#' a vector, whereas non-atomic elements like `.points` or `.strokes`, 
#' or any subelement like `.x` or `.tool` are returned as a list with 
#' one element per pdr_drawing. 
#'
#' @param pdr_list A pdr_list (see [pdr_match()]), e.g. the `pdr_data`
#'   column of a pdr_tibble.
#' @param e1 A string specifying which element of each pdr_drawing to get.
#'   Default `".id"`.
#' @param e2 Optional string naming a column within `e1` (when `e1` is a
#'   tibble such as `.points` or `.strokes`) to extract.
#'
#' @returns
#' If `e2` is `NULL` and `e1` is atomic in all drawings, a simplified
#' vector of the extracted elements.
#' If `e2` is `NULL` and `e1` is non-atomic, a list with one element 
#' (`e1`) is returned for each pain drawing.
#' If `e2` (and `e1`) is supplied, a list with one element per drawing, 
#' containing the extracted `e2` element from each `e1`.
#'
#' @examples
#' # Extract ids (a vector)
#' pdr_example_data |>
#'   dplyr::mutate(id = pdr_get_info(pdr_data, ".id"))
#'
#' # Extract the .x coordinates from the .points tibbles (a list)
#' pdr_example_data |>
#'   dplyr::mutate(x_coord = pdr_get_info(pdr_data, ".points", ".x"))
#'
#' @seealso [pdr_match()]
#'
#' @export

pdr_get_info <- function(pdr_list, e1 = ".id", e2 = NULL) {
  # pdr_list is expected to be a valid data_col list-col
  # elements[1] should be an element name in data_col (list)
  # elements[2] should be an element in var1, if var1 is tibble/list

  if (is.null(e1) || length(e1) != 1 || is.na(e1) || !nzchar(e1)) {
    stop("Parameter 'e1' must be specified as a non-empty character string",
      call. = FALSE)
  }

  if(length(pdr_list)==0) {
    stop("Parameter 'pdr_list' is empty (length == 0)", call. = FALSE)
  }

  e1_is_atomic <- all(pdr_list |> purrr::map_lgl(\(pdr_drawing) {is.atomic(pdr_drawing[[e1]])}))

  result <- 
    purrr::map(pdr_list, \(pdr_drawing) {
      if(e1_is_atomic) {
        pdr_drawing[[e1]]
      } else {
        if(is.null(e2) || length(e2) != 1 || is.na(e2) || !nzchar(e2)) {
          pdr_drawing[[e1]]
        } else {
          pdr_drawing[[e1]][[e2]] 
        }
      }      
    }) 
  
  if(e1_is_atomic) {
    purrr::simplify(result) # Return this 
  } else {
    result
  }
}
