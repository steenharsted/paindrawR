# greyscale PNGs are rejected

    Code
      pdr_import_png(tiny_png("gray_1ch.png"))
    Condition
      Error in `purrr::map()`:
      i In index: 1.
      Caused by error in `.f()`:
      ! `fixtures/png/gray_1ch.png` must be a four-channel RGBA PNG; found 1 channel(s).

# greyscale PNGs with alpha are rejected

    Code
      pdr_import_png(tiny_png("gray_alpha_2ch.png"))
    Condition
      Error in `purrr::map()`:
      i In index: 1.
      Caused by error in `.f()`:
      ! `fixtures/png/gray_alpha_2ch.png` must be a four-channel RGBA PNG; found 2 channel(s).

# RGB PNGs are rejected

    Code
      pdr_import_png(tiny_png("rgb_3ch.png"))
    Condition
      Error in `purrr::map()`:
      i In index: 1.
      Caused by error in `.f()`:
      ! `fixtures/png/rgb_3ch.png` must be a four-channel RGBA PNG; found 3 channel(s).

