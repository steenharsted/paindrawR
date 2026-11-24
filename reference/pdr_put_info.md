# Replace information in a pain drawing list-column

Updates elements within a pain drawing list-column. The function allows
either replacing an entire named element or replacing a named
sub-element within a non-atomic element.

## Usage

``` r
pdr_put_info(pdr_list, replacement, e1 = NULL, e2 = NULL)
```

## Arguments

- pdr_list:

  A pain drawing list-column, typically a list-column in a tibble,
  suited for a
  [`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  function call. Each element is expected to be a named list containing
  pain drawing data.

- replacement:

  The replacement data. Must have the same length as `pdr_list`, or have
  length one, in which case the same replacement is recycled across all
  elements.

- e1:

  A character string specifying the name of the element to replace in
  each pain drawing.

- e2:

  An optional character string specifying the name of a nested element
  to replace within `e1`. Used when the element specified by `e1` is
  non-atomic.

## Value

A modified pain drawing list-column with the same number of elements as
`pdr_list`.

## Details

The function is intended for use with list-columns containing pain
drawing data, where each list element is a named list of components such
as `.id`, `.filename`, and `.strokes`.

If the element specified by `e1` is atomic (e.g. a character vector,
numeric vector, or logical vector), it is replaced directly. If it is
non-atomic (e.g. a tibble or another list), the element specified by
`e2` is replaced instead.

The function uses
[`purrr::map2()`](https://purrr.tidyverse.org/reference/map2.html) to
iterate over the original elements and their corresponding replacement
values.

If `e1` is `NULL`, or the lengths of `pdr_list` and `replacement` are
incompatible, a warning is issued and `NA` is returned.

## Examples

``` r
# Replace the .id element in each pain drawing
pdr_list <- list(
  list(.id = "a", .filename = "drawing1.svg"),
  list(.id = "b", .filename = "drawing2.svg")
)

pdr_put_info(pdr_list, replacement = c("x", "y"), e1 = ".id")
#> [[1]]
#> [[1]]$.id
#> [1] "x"
#> 
#> [[1]]$.filename
#> [1] "drawing1.svg"
#> 
#> 
#> [[2]]
#> [[2]]$.id
#> [1] "y"
#> 
#> [[2]]$.filename
#> [1] "drawing2.svg"
#> 
#> 

# Replace the .filename element in each pain drawing
pdr_put_info(pdr_list, replacement = "new.svg", e1 = ".filename")
#> [[1]]
#> [[1]]$.id
#> [1] "a"
#> 
#> [[1]]$.filename
#> [1] "new.svg"
#> 
#> 
#> [[2]]
#> [[2]]$.id
#> [1] "b"
#> 
#> [[2]]$.filename
#> [1] "new.svg"
#> 
#> 
```
