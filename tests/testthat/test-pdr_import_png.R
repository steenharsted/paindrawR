png_fixture <- function(n) {
  test_path("fixtures", "png", paste0(n, "_palmar_png.png"))
}

tiny_png <- function(name) test_path("fixtures", "png", name)

test_that("a real RGBA PNG is imported as a pdr_tibble", {
  res <- pdr_import_png(png_fixture(1))

  expect_s3_class(res, "tbl_df")
  expect_named(res, c("pdr_data", "id"))
  expect_equal(nrow(res), 1)
  expect_equal(res$id, "1_palmar_png")

  drawing <- res$pdr_data[[1]]
  expect_setequal(
    names(drawing),
    c(
      ".id",
      ".file",
      ".version",
      ".width",
      ".height",
      ".units",
      ".timestamp",
      ".app",
      ".template_file",
      ".points",
      ".strokes",
      ".rgba"
    )
  )
  expect_equal(drawing$.file, png_fixture(1))
  expect_equal(drawing$.units, "px")
  expect_equal(drawing$.width, 624)
  expect_equal(drawing$.height, 720)
  expect_equal(dim(drawing$.rgba), c(720, 624, 4))
})

test_that("multiple files give one row each, in input order", {
  res <- pdr_import_png(c(png_fixture(2), png_fixture(1)))

  expect_equal(nrow(res), 2)
  expect_equal(res$id, c("2_palmar_png", "1_palmar_png"))
})

test_that("`.points` and `.strokes` are empty tibbles", {
  drawing <- pdr_import_png(png_fixture(1))$pdr_data[[1]]

  expect_s3_class(drawing$.points, "tbl_df")
  expect_equal(nrow(drawing$.points), 0)
  expect_named(drawing$.points, c(".index", ".x", ".y"))
  expect_s3_class(drawing$.strokes, "tbl_df")
  expect_equal(nrow(drawing$.strokes), 0)
  expect_named(drawing$.strokes, ".index")
})

test_that("`id_from_filename` controls `.id`", {
  path <- tiny_png("rgba_opaque_white_4ch.png")

  expect_equal(
    pdr_import_png(path)$id,
    tools::file_path_sans_ext(basename(path))
  )
  res <- pdr_import_png(path, id_from_filename = FALSE)
  expect_identical(res$id, NA_character_)
  expect_identical(res$pdr_data[[1]]$.id, NA_character_)
})

test_that("RGBA is kept, with transparent pixels set to black", {
  path <- tiny_png("rgba_transparent_4ch.png")
  expected <- png::readPNG(path)

  rgba <- pdr_import_png(path)$pdr_data[[1]]$.rgba
  expect_equal(rgba[1, 1, ], c(0, 0, 0, 0))
  expect_equal(rgba[2, 2, ], expected[2, 2, ])
  expect_equal(rgba[1, 2, ], expected[1, 2, ])
})

test_that("greyscale PNGs are rejected", {
  expect_snapshot(error = TRUE, pdr_import_png(tiny_png("gray_1ch.png")))
})

test_that("greyscale PNGs with alpha are rejected", {
  expect_snapshot(error = TRUE, pdr_import_png(tiny_png("gray_alpha_2ch.png")))
})

test_that("RGB PNGs are rejected", {
  expect_snapshot(error = TRUE, pdr_import_png(tiny_png("rgb_3ch.png")))
})

test_that("`files` must be a non-empty character vector", {
  expect_error(pdr_import_png(character()), "`files` must be")
  expect_error(pdr_import_png(NULL), "`files` must be")
  expect_error(pdr_import_png(1), "`files` must be")
  expect_error(pdr_import_png(list(png_fixture(1))), "`files` must be")
})

test_that("missing files give a warning naming the files", {
  expect_warning(
    pdr_import_png(c(png_fixture(1), "nope_a.png", "nope_b.png")),
    "nope_a.png, nope_b.png",
    fixed = TRUE
  )
})

test_that("NA entries give NA out, without error", {
  res <- pdr_import_png(c(png_fixture(1), NA))
  expect_equal(nrow(res), 2)
  expect_identical(res$pdr_data[[2]], NA)
  expect_identical(res$id[[2]], NA_character_)
  expect_equal(dim(res$pdr_data[[1]]$.rgba)[3], 4)
})

test_that("non-existing files warn and give NA with a file-derived id", {
  expect_warning(
    res <- pdr_import_png(c(png_fixture(1), "does_not_exist.png", NA)),
    "Non-existing PNG files"
  )
  expect_equal(nrow(res), 3)
  expect_identical(res$pdr_data[[2]], NA)
  expect_identical(res$pdr_data[[3]], NA)
  expect_identical(res$id, c("1_palmar_png", "does_not_exist", NA_character_))

  res <- suppressWarnings(
    pdr_import_png("does_not_exist.png", id_from_filename = FALSE)
  )
  expect_identical(res$id, NA_character_)
})
