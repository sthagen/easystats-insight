if (require("testthat") && require("insight") && require("estimatr")) {
  context("insight, model_info")

  data(mtcars)
  m1 <- iv_robust(mpg ~ gear + cyl | carb + wt, data = mtcars)

  test_that("model_info", {
    expect_true(model_info(m1)$is_linear)
  })

  test_that("find_predictors", {
    expect_identical(find_predictors(m1), list(
      conditional = c("gear", "cyl"),
      instruments = c("carb", "wt")
    ))
    expect_identical(find_predictors(m1, component = "instruments"), list(instruments = c("carb", "wt")))
    expect_identical(find_predictors(m1, flatten = TRUE), c("gear", "cyl", "carb", "wt"))
    expect_null(find_predictors(m1, effects = "random"))
  })

  test_that("find_random", {
    expect_null(find_random(m1))
  })

  test_that("get_random", {
    expect_warning(get_random(m1))
  })

  test_that("find_response", {
    expect_identical(find_response(m1), "mpg")
  })

  test_that("get_response", {
    expect_equal(get_response(m1), mtcars$mpg)
  })

  test_that("get_predictors", {
    expect_equal(colnames(get_predictors(m1)), c("gear", "cyl", "carb", "wt"))
  })

  test_that("get_data", {
    expect_equal(nrow(get_data(m1)), 32)
    expect_equal(colnames(get_data(m1)), c("mpg", "carb + wt", "gear", "cyl", "carb", "wt"))
  })

  test_that("find_formula", {
    expect_length(find_formula(m1), 2)
    expect_equal(
      find_formula(m1),
      list(
        conditional = as.formula("mpg ~ gear + cyl"),
        instruments = as.formula("~carb + wt")
      )
    )
  })

  test_that("find_terms", {
    expect_equal(find_terms(m1), list(
      response = "mpg",
      conditional = c("gear", "cyl"),
      instruments = c("carb", "wt")
    ))
    expect_equal(find_terms(m1, flatten = TRUE), c("mpg", "gear", "cyl", "carb", "wt"))
  })

  test_that("n_obs", {
    expect_equal(n_obs(m1), 32)
  })

  test_that("link_function", {
    expect_equal(link_function(m1)(.2), .2, tolerance = 1e-5)
  })

  test_that("link_inverse", {
    expect_equal(link_inverse(m1)(.2), .2, tolerance = 1e-5)
  })

  test_that("find_parameters", {
    expect_equal(
      find_parameters(m1),
      list(
        conditional = c("(Intercept)", "gear", "cyl")
      )
    )
    expect_equal(nrow(get_parameters(m1)), 3)
    expect_equal(get_parameters(m1)$parameter, c("(Intercept)", "gear", "cyl"))
  })

  test_that("is_multivariate", {
    expect_false(is_multivariate(m1))
  })

  test_that("find_algorithm", {
    expect_warning(expect_null(find_algorithm(m1)))
  })
}