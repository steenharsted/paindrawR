library(testthat)
library(tibble)

# Test data: two pain drawings, each containing atomic and
# non-atomic elements.
pdr_list <- list(
  list(
    .id = "drawing_1",
    .filename = "drawing1.svg",
    .strokes = tibble(
      x = c(1, 2, 3),
      y = c(4, 5, 6),
      label="drawing_1"
    )
  ),
  list(
    .id = "drawing_2",
    .filename = "drawing2.svg",
    .strokes = tibble(
      x = c(7, 8, 9),
      y = c(10, 11, 12),
      label="drawing_2"
    )
  )
)


test_that("pdr_get_info extracts atomic elements as a vector", {
  result <- pdr_get_info(pdr_list, ".id")

  expect_equal(result, c("drawing_1", "drawing_2"))
  expect_type(result, "character")
})

test_that("pdr_get_info extracts other atomic elements", {
  result <- pdr_get_info(pdr_list, ".filename")

  expect_equal(result, c("drawing1.svg", "drawing2.svg"))
})

test_that("pdr_get_info uses .id as the default e1", {
  result <- pdr_get_info(pdr_list)

  expect_equal(result, c("drawing_1", "drawing_2"))
})

test_that("pdr_get_info extracts nested elements as a list", {
  result <- pdr_get_info(pdr_list, ".strokes")

  expect_type(result, "list")
  expect_length(result, 2)
  expect_equal(result[[1]], pdr_list[[1]]$.strokes)
  expect_equal(result[[2]], pdr_list[[2]]$.strokes)
})

test_that("pdr_get_info extracts a column from nested elements", {
  result <- pdr_get_info(pdr_list, ".strokes", "x")

  expect_type(result, "list")
  expect_length(result, 2)
  expect_equal(result[[1]], c(1, 2, 3))
  expect_equal(result[[2]], c(7, 8, 9))
})

test_that("pdr_get_info returns a list when extracting nested columns", {
  result <- pdr_get_info(pdr_list, ".strokes", "x")

  expect_true(is.list(result))
  expect_length(result, length(pdr_list))
})

test_that("pdr_get_info errors when e1 is missing", {
  expect_error(
    pdr_get_info(pdr_list, e1 = NULL),
    "Parameter 'e1' must be specified"
  )
})

test_that("pdr_get_info errors when e1 is an empty string", {
  expect_error(
    pdr_get_info(pdr_list, e1 = ""),
    "Parameter 'e1' must be specified"
  )
})

test_that("pdr_get_info errors when pdr_list is empty", {
  expect_error(
    pdr_get_info(list()),
    "Parameter 'pdr_list' is empty"
  )
})

