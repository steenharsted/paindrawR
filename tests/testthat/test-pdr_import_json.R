json_fixture <- function(n) {
  test_path("fixtures", "json", paste0(n, "_palmar.json"))
}
all_fixtures <- vapply(1:2, json_fixture, character(1))

test_that("a single file gives a one-row pdr_tibble", {
  res <- pdr_import_json(json_fixture(1))

  expect_s3_class(res, "tbl_df")
  expect_named(res, c("pdr_data", "id"))
  expect_equal(nrow(res), 1)
  expect_type(res$pdr_data, "list")
  expect_equal(res$id, "PID4193-R1F-palmar-E13885-I1")
})

test_that("each drawing has the expected elements", {
  drawing <- pdr_import_json(json_fixture(1))$pdr_data[[1]]

  expect_setequal(
    names(drawing),
    c(
      ".file",
      ".points",
      ".strokes",
      ".id",
      ".version",
      ".width",
      ".height",
      ".units",
      ".timestamp",
      ".app",
      ".template_file"
    )
  )
  expect_equal(drawing$.file, json_fixture(1))
  expect_equal(drawing$.width, 624)
  expect_equal(drawing$.height, 720)
  expect_equal(drawing$.units, "px")
})

test_that("multiple files are combined row-wise in input order", {
  res <- pdr_import_json(all_fixtures)

  expect_equal(nrow(res), 2)
  expect_equal(
    res$id,
    sprintf("PID4193-R%dF-palmar-E13885-I1", 1:2)
  )
  expect_equal(
    vapply(res$pdr_data, \(x) x$.file, character(1)),
    unname(all_fixtures)
  )
})

test_that("a list of paths gives the same result as a character vector", {
  expect_equal(
    pdr_import_json(as.list(all_fixtures)),
    pdr_import_json(all_fixtures)
  )
})

test_that(".points has renamed columns and a flipped y-axis", {
  drawing <- pdr_import_json(json_fixture(1))$pdr_data[[1]]
  raw <- jsonlite::fromJSON(json_fixture(1))

  expect_named(drawing$.points, c(".index", ".x", ".y"))

  first_stroke <- drawing$.points[drawing$.points$.index == 1, ]
  raw_first <- raw$s$p[[1]]
  expect_equal(first_stroke$.x, raw_first[, 1])
  expect_equal(first_stroke$.y, raw$h - raw_first[, 2])
})

test_that(".points has one row per raw coordinate", {
  drawing <- pdr_import_json(json_fixture(2))$pdr_data[[1]]
  raw <- jsonlite::fromJSON(json_fixture(2))

  expect_equal(nrow(drawing$.points), sum(vapply(raw$s$p, nrow, integer(1))))
  expect_setequal(drawing$.points$.index, seq_len(nrow(raw$s)))
})

test_that(".strokes has renamed columns and drops `p`", {
  drawing <- pdr_import_json(json_fixture(1))$pdr_data[[1]]
  raw <- jsonlite::fromJSON(json_fixture(1))

  expect_s3_class(drawing$.strokes, "tbl_df")
  expect_equal(nrow(drawing$.strokes), nrow(raw$s))
  expect_true(all(
    c(
      ".index",
      ".draw_input_type",
      ".tool",
      ".tool_width",
      ".color",
      ".alpha",
      ".spray_radius",
      ".point_density"
    ) %in%
      names(drawing$.strokes)
  ))
  expect_false("p" %in% names(drawing$.strokes))
  expect_equal(drawing$.strokes$.index, raw$s$strokeId)
})

test_that("invalid `files` input warns and returns an empty list", {
  expect_warning(res <- pdr_import_json(character()), "No JSON files")
  expect_identical(res, list())

  expect_warning(res <- pdr_import_json(NULL), "No JSON files")
  expect_identical(res, list())

  expect_warning(res <- pdr_import_json(123), "No JSON files")
  expect_identical(res, list())
})

test_that("a non-existing file gives a warning", {
  expect_warning(
    pdr_import_json(c("does_not_exist.json", json_fixture(1))),
    "Non-existing JSON files"
  )
})

test_that("a file with invalid JSON gives a warning", {
  bad <- withr::local_tempfile(fileext = ".json")
  writeLines("{ this is not json", bad)

  expect_warning(
    pdr_import_json(c(bad, json_fixture(1))),
    "could not be validated as JSON"
  )
})

test_that("failing files are kept as placeholder rows", {
  bad <- withr::local_tempfile(fileext = ".json")
  writeLines("{ this is not json", bad)

  res <- suppressWarnings(
    pdr_import_json(c("does_not_exist.json", bad, json_fixture(1)))
  )
  expect_equal(nrow(res), 3)
  expect_identical(res$pdr_data[[1]], NA)
  expect_identical(res$pdr_data[[2]], list())
  expect_identical(
    res$id,
    c("does_not_exist", NA_character_, "PID4193-R1F-palmar-E13885-I1")
  )
})

test_that("a failing file does not overwrite good drawings", {
  res <- suppressWarnings(
    pdr_import_json(c(json_fixture(1), "does_not_exist.json", json_fixture(2)))
  )
  expect_equal(nrow(res), 3)
  expect_identical(
    res$id,
    c(
      "PID4193-R1F-palmar-E13885-I1",
      "does_not_exist",
      "PID4193-R2F-palmar-E13885-I1"
    )
  )
  expect_identical(res$pdr_data[[2]], NA)
})

test_that("NA entries give NA out, without warning", {
  res <- pdr_import_json(c(json_fixture(1), NA, json_fixture(2)))
  expect_equal(nrow(res), 3)
  expect_identical(res$pdr_data[[2]], NA)
  expect_identical(
    res$id,
    c(
      "PID4193-R1F-palmar-E13885-I1",
      NA_character_,
      "PID4193-R2F-palmar-E13885-I1"
    )
  )
})

test_that("a valid drawing without strokes gives zero-row tibbles", {
  empty <- test_path("fixtures", "json", "empty_palmar.json")

  expect_no_warning(res <- pdr_import_json(empty))
  expect_equal(nrow(res), 1)
  expect_equal(res$id, "PID-empty")

  drawing <- res$pdr_data[[1]]
  expect_equal(drawing$.height, 720)
  expect_s3_class(drawing$.points, "tbl_df")
  expect_equal(nrow(drawing$.points), 0)
  expect_named(drawing$.points, c(".index", ".x", ".y"))
  expect_s3_class(drawing$.strokes, "tbl_df")
  expect_equal(nrow(drawing$.strokes), 0)
  expect_named(
    drawing$.strokes,
    c(
      ".index",
      ".draw_input_type",
      ".tool",
      ".tool_width",
      ".color",
      ".alpha",
      ".spray_radius",
      ".point_density"
    ),
    ignore.order = TRUE
  )
})

# Schema detection and schema 1.0 -------------------------------------------

new_fixture <- function(name) test_path("fixtures", "json", name)

test_that("the schema is detected from the parsed content", {
  expect_equal(detect_json_schema(list(schema_version = "1.0")), "1.0")
  expect_equal(detect_json_schema(list(schema_version = "1.3")), "1.0")
  expect_true(is.na(detect_json_schema(list(schema_version = "2.0"))))
  expect_equal(
    detect_json_schema(jsonlite::fromJSON(json_fixture(1))),
    "0.3"
  )
  expect_true(is.na(detect_json_schema(list(a = 1))))
  expect_true(is.na(detect_json_schema(1:3)))
})

test_that("schema 1.0 and v0.3 files with the same content give equal drawings", {
  old <- pdr_import_json(json_fixture(1))$pdr_data[[1]]
  new <- pdr_import_json(new_fixture("1.0_palmar.json"))$pdr_data[[1]]

  # Only the file path and the version (module vs. old format) differ
  expect_equal(new$.file, new_fixture("1.0_palmar.json"))
  expect_equal(new$.version, "1.0.0")
  old$.file <- new$.file <- NULL
  old$.version <- new$.version <- NULL
  expect_equal(new, old)
  expect_identical(names(new), names(old))
})

test_that("old and new files can be mixed in one call", {
  res <- pdr_import_json(c(json_fixture(1), new_fixture("1.0_palmar.json")))
  expect_equal(nrow(res), 2)
  expect_equal(res$id, rep("PID4193-R1F-palmar-E13885-I1", 2))
})

test_that(".template_file is read from both formats", {
  old <- pdr_import_json(json_fixture(1))$pdr_data[[1]]
  new <- pdr_import_json(new_fixture("1.0_example.json"))$pdr_data[[1]]
  expect_equal(old$.template_file, "lower_arm_palmar.png")
  expect_equal(new$.template_file, "bg_full_body.png")
})

test_that("the schema 1.0 example file imports with the right types", {
  res <- pdr_import_json(new_fixture("1.0_example.json"))
  drawing <- res$pdr_data[[1]]

  expect_equal(res$id, "1")
  expect_equal(drawing$.version, "0.1.0")
  expect_equal(drawing$.app, "paindraw_shiny")
  expect_equal(drawing$.timestamp, "2026-11-19T14:37:35Z")
  expect_type(drawing$.width, "integer")
  expect_type(drawing$.points$.x, "integer")
  expect_type(drawing$.points$.y, "integer")
  expect_type(drawing$.points$.index, "integer")
  expect_type(drawing$.strokes$.index, "integer")
  expect_setequal(drawing$.points$.index, drawing$.strokes$.index)
  expect_true(pdr_match(res, action = "eval", as = "pdr_tibble", mode = "validate"))
})

test_that("pen strokes and single-point strokes are handled in schema 1.0", {
  drawing <- pdr_import_json(new_fixture("1.0_pen.json"))$pdr_data[[1]]

  expect_equal(drawing$.strokes$.tool, c("spray", "pen", "spray"))
  expect_equal(is.na(drawing$.strokes$.point_density), c(FALSE, TRUE, FALSE))
  expect_equal(is.na(drawing$.strokes$.spray_radius), c(FALSE, TRUE, FALSE))
  expect_type(drawing$.strokes$.point_density, "integer")
  expect_equal(sum(drawing$.points$.index == 3), 1)
  expect_equal(drawing$.points$.y[drawing$.points$.index == 3], drawing$.height - 20L)
})

test_that("a schema 1.0 drawing without strokes gives zero-row tibbles", {
  expect_no_warning(res <- pdr_import_json(new_fixture("1.0_empty.json")))
  drawing <- res$pdr_data[[1]]
  empty_old <- pdr_import_json(test_path("fixtures", "json", "empty_palmar.json"))$pdr_data[[1]]

  expect_equal(res$id, "PID-empty")
  expect_equal(drawing$.points, empty_old$.points)
  expect_equal(drawing$.strokes, empty_old$.strokes)
})

test_that("an unrecognised format or schema version gives a placeholder row", {
  other <- withr::local_tempfile(fileext = ".json")
  writeLines('{"a": 1}', other)

  expect_warning(
    pdr_import_json(other),
    "not a recognised paindraw JSON format"
  )
  expect_warning(
    pdr_import_json(new_fixture("2.0_unsupported.json")),
    "not a recognised paindraw JSON format"
  )
  res <- suppressWarnings(
    pdr_import_json(c(other, new_fixture("2.0_unsupported.json"), json_fixture(1)))
  )
  expect_equal(nrow(res), 3)
  expect_identical(res$pdr_data[[1]], list())
  expect_identical(res$pdr_data[[2]], list())
  expect_identical(res$id, c(NA_character_, NA_character_, "PID4193-R1F-palmar-E13885-I1"))
})

test_that("a schema 1.0 file missing required fields warns and gives a placeholder", {
  broken <- withr::local_tempfile(fileext = ".json")
  writeLines('{"schema_version": "1.0", "strokes": []}', broken)
  expect_warning(res <- pdr_import_json(broken), "missing field")
  expect_identical(res$pdr_data[[1]], list())
})
