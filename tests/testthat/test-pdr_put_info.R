
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
      y = c(4, 5, 6)
    )
  ),
  list(
    .id = "drawing_2",
    .filename = "drawing2.svg",
    .strokes = tibble(
      x = c(7, 8, 9),
      y = c(10, 11, 12)
    )
  )
)


test_that("atomic elements can be replaced", {

  result <- pdr_put_info(
    pdr_list,
    replacement = c("new_1", "new_2"),
    e1 = ".id"
  )

  expect_identical(result[[1]]$.id, "new_1")
  expect_identical(result[[2]]$.id, "new_2")

  # Other elements should remain unchanged
  expect_identical(result[[1]]$.filename, "drawing1.svg")
  expect_identical(result[[2]]$.filename, "drawing2.svg")
})


test_that("non-atomic elements can be modified through e2", {

  result <- pdr_put_info(
    pdr_list,
    replacement = c("new1.svg", "new2.svg"),
    e1 = ".filename"
  )

  # Direct replacement of another atomic element
  expect_identical(result[[1]]$.filename, "new1.svg")
  expect_identical(result[[2]]$.filename, "new2.svg")
})


test_that("nested tibble columns can be replaced", {

  result <- pdr_put_info(
    pdr_list,
    replacement = list(
      c(100, 200, 300),
      c(400, 500, 600)
    ),
    e1 = ".strokes",
    e2 = "x"
  )

  expect_identical(
    result[[1]]$.strokes$x,
    c(100, 200, 300)
  )

  expect_identical(
    result[[2]]$.strokes$x,
    c(400, 500, 600)
  )

  # The other column should remain unchanged
  expect_identical(
    result[[1]]$.strokes$y,
    pdr_list[[1]]$.strokes$y
  )
})


test_that("a single replacement is recycled", {

  result <- pdr_put_info(
    pdr_list,
    replacement = "same_value",
    e1 = ".id"
  )

  expect_identical(result[[1]]$.id, "same_value")
  expect_identical(result[[2]]$.id, "same_value")
})


test_that("missing e1 produces an error", {
  expect_error(
    pdr_put_info(pdr_list, replacement = "new_value"),
    "Parameter 'e1' must be specified"
  )
})

test_that("missing e2 for non-atomic elements produces an error", {
  expect_error(
    pdr_put_info(
      pdr_list,
      replacement = "new_value",
      e1 = ".strokes"
    ),
    "Parameter 'e2' must be specified"
  )
})

test_that("incompatible replacement length produces an error", {
  expect_error(
    pdr_put_info(
      pdr_list,
      replacement = c("a", "b", "c"),
      e1 = ".id"
    ),
    "Mismatch in length"
  )
})


test_that("the original list is not modified", {

  original <- pdr_list

  result <- pdr_put_info(
    pdr_list,
    replacement = c("new_1", "new_2"),
    e1 = ".id"
  )

  expect_identical(pdr_list, original)
  expect_false(identical(result, original))
})
