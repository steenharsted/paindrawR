#' Replace information in a pain drawing list-column
#'
#' Updates elements within a pain drawing list-column. The function allows
#' either replacing an entire named element or replacing a named sub-element
#' within a non-atomic element.
#'
#' The function is intended for use with list-columns containing pain drawing
#' data, where each list element is a named list of components such as
#' `.id`, `.filename`, and `.strokes`.
#'
#' If the element specified by `id1` is atomic (e.g. a character vector,
#' numeric vector, or logical vector), it is replaced directly. If it is
#' non-atomic (e.g. a tibble or another list), the element specified by
#' `id2` is replaced instead.
#'
#' @param pdr_list A pain drawing list-column, typically a list-column in a
#'   tibble, suited for a `mutate()` function call. Each element is expected 
#'   to be a named list containing pain drawing data.
#' @param replacement The replacement data. Must have the same length as
#'   `pdr_list`, or have length one, in which case the same replacement is
#'   recycled across all elements.
#' @param id1 A character string specifying the name of the element to replace
#'   in each pain drawing. 
#' @param id2 An optional character string specifying the name of a nested
#'   element to replace within `id1`. Used when the element specified by
#'   `id1` is non-atomic.
#'
#' @return A modified pain drawing list-column with the same number of
#'   elements as `pdr_list`.
#'
#' @details
#' The function uses [purrr::map2()] to iterate over the original elements
#' and their corresponding replacement values.
#'
#' If `id1` is `NULL`, or the lengths of `pdr_list` and `replacement` are
#' incompatible, a warning is issued and `NA` is returned.
#'
#' @examples
#' # Replace the .id element in each pain drawing
#' pdr_list <- list(
#'   list(.id = "a", .filename = "drawing1.svg"),
#'   list(.id = "b", .filename = "drawing2.svg")
#' )
#'
#' pdr_put_info(pdr_list, replacement = c("x", "y"), id1 = ".id")
#'
#' # Replace the .filename element in each pain drawing
#' pdr_put_info(pdr_list, replacement = "new.svg", id1 = ".filename")
#'
#' @export

pdr_put_info <- function(pdr_list, replacement, id1 = NULL, id2 = NULL) {
  # pdr_list is expected the be a valid pain drawing
  # list-col
  # replacement_data is expected to a list of data to be put
  # inside pdr_list as a replacement for var1 element,
  # or as replacement for column var2 in element var1
  # The number of elements of replacement_data and the
  # pdr_list element is replaces should match.

  if (is.null(id1) || length(id1) != 1 || is.na(id1) || !nzchar(id1)) {
    stop("Parameter 'id1' must be specified as a non-empty character string",
       call. = FALSE)
  }

  if(length(pdr_list)==0) {
    stop("Parameter 'pdr_list' is empty (length == 0)", call. = FALSE)
  }
  
  if(!all(pdr_list |> purrr::map_lgl(\(x) {is.atomic(x[[id1]])})) && 
    (is.null(id2) || length(id2) != 1 || is.na(id2) || !nzchar(id2))) {
    stop(paste0("Parameter 'id2' must be specified when 'id1' is non-atomic"), call. = FALSE)
  }

  if (length(pdr_list) != length(replacement) && length(replacement) != 1) {
    stop("Mismatch in length of pdr_list and replacement. Length of replacement may 1", call. = FALSE)
  }

  if (length(replacement) == 1) {
    replacement <- rep(replacement, length(pdr_list))
  }

  purrr::map2(pdr_list, replacement, \(old_list, new_element) {
    if(is.atomic(old_list[[id1]])) {
      old_list[[id1]] <- new_element
    } else {
      old_list[[id1]][[id2]] <- new_element
    }
    old_list
  })  # Return this
  
}
