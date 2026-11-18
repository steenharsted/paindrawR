# Local absolute path to example files

This function facilitates users' access to example files such as e.g.
background images, stored in the inst/extdata folder of the package.

## Usage

``` r
pdr_example_file(path = NULL)
```

## Arguments

- path:

  File name or path to example file in inst/extdata

## Value

An absolute file path to the specified file. In case no file is
specified, a vector of file names from the folder, is returned.

## Details

This function does not take a pdr_list or pdr_tibble as input, nor
return one as output (see
[`pdr_match()`](https://steenharsted.github.io/paindrawR/reference/pdr_match.md)).

## Examples

``` r
# Get a vector of files in the _example files_ folder
pdr_example_file()
#>  [1] "1_palmar.json"               "LibreCAD_test_1.dxf"        
#>  [3] "bg_feet.png"                 "bg_full_body.png"           
#>  [5] "bg_full_body_woman.png"      "bg_full_body_woman_hair.png"
#>  [7] "bg_head.png"                 "bg_legs.png"                
#>  [9] "bg_lower_arm_dorsal.png"     "bg_lower_arm_palmar.png"    
#> [11] "bg_lower_leg.png"            "bg_mird.png"                
#> [13] "bg_spiral.png"               "bg_spiral_grey.png"         
#> [15] "bg_square_paper.png"         "bg_zealand.png"             

# Get the absolute path to a file in the _example files_
# folder
pdr_example_data[1, ] |>
  pdr_plot_xy(background_image = pdr_example_file("bg_full_body.png"))
```
