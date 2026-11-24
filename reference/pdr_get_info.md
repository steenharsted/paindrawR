# Extract information from pain drawing objects

Extracts variables from a pdr_list (see
[`pdr_match()`](https://steenharsted.github.io/paindrawR/reference/pdr_match.md)).
Simple elements (such as `".id"` or `".timestamp"`) are returned as a
vector, whereas non-atomic elements like `.points` or `.strokes`, or any
subelement like `.x` or `.tool` are returned as a list with one element
per pdr_drawing.

## Usage

``` r
pdr_get_info(pdr_list, e1 = ".id", e2 = NULL)
```

## Arguments

- pdr_list:

  A pdr_list (see
  [`pdr_match()`](https://steenharsted.github.io/paindrawR/reference/pdr_match.md)),
  e.g. the `pdr_data` column of a pdr_tibble.

- e1:

  A string specifying which element of each pdr_drawing to get. Default
  `".id"`.

- e2:

  Optional string naming a column within `e1` (when `e1` is a tibble
  such as `.points` or `.strokes`) to extract.

## Value

If `e2` is `NULL` and `e1` is atomic in all drawings, a simplified
vector of the extracted elements. If `e2` is `NULL` and `e1` is
non-atomic, a list with one element (`e1`) is returned for each pain
drawing. If `e2` (and `e1`) is supplied, a list with one element per
drawing, containing the extracted `e2` element from each `e1`.

## See also

[`pdr_match()`](https://steenharsted.github.io/paindrawR/reference/pdr_match.md)

## Examples

``` r
# Extract ids (a vector)
pdr_example_data |>
  dplyr::mutate(id = pdr_get_info(pdr_data, ".id"))
#> # A tibble: 50 × 6
#>    id                               pdr_data          sex     age duration  pain
#>    <chr>                            <list>            <fct> <dbl> <fct>    <dbl>
#>  1 6d63804892233bbb18bc21bcf0d81d0d <named list [10]> Fema…  46   Chronic      6
#>  2 c8b12cd45d08e94241d4de9990d60f71 <named list [10]> Fema…  35.4 Acute        6
#>  3 25062ac7dbeb08d8b532ac474a7849ca <named list [10]> Fema…  38.4 Acute        5
#>  4 0dc657fa6ed70150f9596fe692f2f9a0 <named list [10]> Male   98   Subacute     3
#>  5 fb61c33ffa09270a5c7931813e9d2d71 <named list [10]> Fema…  58.3 Acute        1
#>  6 328d31503202db3e5c1b8e78f287810e <named list [10]> Male   68.9 Subacute     7
#>  7 e07d8d7e7034ba3ae7f907de022af58d <named list [10]> Fema…  67.4 Subacute     6
#>  8 9996f1a95c8e939c6ab6258bfc76f722 <named list [10]> Fema…  53.4 Chronic      9
#>  9 41aa308e694ad270b7cfaea054c7c1a2 <named list [10]> Fema…  36.8 Chronic      9
#> 10 0bcfd36a71b799e857f13c29011d21ff <named list [10]> Fema…  34.9 Subacute     4
#> # ℹ 40 more rows

# Extract the .x coordinates from the .points tibbles (a list)
pdr_example_data |>
  dplyr::mutate(x_coord = pdr_get_info(pdr_data, ".points", ".x"))
#> # A tibble: 50 × 7
#>    id                            pdr_data     sex     age duration  pain x_coord
#>    <chr>                         <list>       <fct> <dbl> <fct>    <dbl> <list> 
#>  1 6d63804892233bbb18bc21bcf0d8… <named list> Fema…  46   Chronic      6 <int>  
#>  2 c8b12cd45d08e94241d4de9990d6… <named list> Fema…  35.4 Acute        6 <int>  
#>  3 25062ac7dbeb08d8b532ac474a78… <named list> Fema…  38.4 Acute        5 <int>  
#>  4 0dc657fa6ed70150f9596fe692f2… <named list> Male   98   Subacute     3 <int>  
#>  5 fb61c33ffa09270a5c7931813e9d… <named list> Fema…  58.3 Acute        1 <int>  
#>  6 328d31503202db3e5c1b8e78f287… <named list> Male   68.9 Subacute     7 <int>  
#>  7 e07d8d7e7034ba3ae7f907de022a… <named list> Fema…  67.4 Subacute     6 <int>  
#>  8 9996f1a95c8e939c6ab6258bfc76… <named list> Fema…  53.4 Chronic      9 <int>  
#>  9 41aa308e694ad270b7cfaea054c7… <named list> Fema…  36.8 Chronic      9 <int>  
#> 10 0bcfd36a71b799e857f13c29011d… <named list> Fema…  34.9 Subacute     4 <int>  
#> # ℹ 40 more rows
```
