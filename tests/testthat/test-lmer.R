if (require("testthat") && require("insight") && require("lme4")) {
  context("insight, find_predictors")

  data(sleepstudy)

  sleepstudy$mygrp <- sample(1:5, size = 180, replace = TRUE)
  sleepstudy$mysubgrp <- NA
  for (i in 1:5) {
    filter_group <- sleepstudy$mygrp == i
    sleepstudy$mysubgrp[filter_group] <- sample(1:30, size = sum(filter_group), replace = TRUE)
  }

  m1 <- lme4::lmer(
    Reaction ~ Days + (1 + Days | Subject),
    data = sleepstudy
  )

  m2 <- lme4::lmer(
    Reaction ~ Days + (1 | mygrp / mysubgrp) + (1 | Subject),
    data = sleepstudy
  )

  test_that("model_info", {
    expect_true(model_info(m1)$is_linear)
    expect_true(model_info(m2)$is_linear)
  })

  test_that("find_predictors", {
    expect_equal(find_predictors(m1, effects = "all"), c("Days", "Subject"))
    expect_equal(find_predictors(m1, effects = "fixed"), "Days")
    expect_equal(find_predictors(m1, effects = "random"), "Subject")
    expect_equal(find_predictors(m2, effects = "all"), c("Days", "mygrp", "mysubgrp", "Subject"))
    expect_equal(find_predictors(m2, effects = "fixed"), "Days")
    expect_equal(find_predictors(m2, effects = "random"), c("mysubgrp:mygrp", "mygrp", "Subject"))
    expect_null(find_predictors(m2, effects = "all", component = "zi"))
    expect_null(find_predictors(m2, effects = "fixed", component = "zi"))
    expect_null(find_predictors(m2, effects = "random", component = "zi"))
  })

  test_that("find_random", {
    expect_equal(find_random(m1), "Subject")
    expect_equal(find_random(m2), c("mysubgrp:mygrp", "mygrp", "Subject"))
    expect_equal(find_random(m2, split_nested = TRUE), c("mysubgrp", "mygrp", "Subject"))
    expect_equal(find_random(m1, component = "cond"), "Subject")
    expect_equal(find_random(m1, component = "all"), "Subject")
    expect_null(find_random(m1, component = "zi"))
    expect_null(find_random(m1, component = "disp"))
    expect_equal(find_random(m2, component = "cond"), c("mysubgrp:mygrp", "mygrp", "Subject"))
    expect_equal(find_random(m2, component = "cond", split_nested = TRUE), c("mysubgrp", "mygrp", "Subject"))
    expect_equal(find_random(m2, component = "all"), c("mysubgrp:mygrp", "mygrp", "Subject"))
    expect_equal(find_random(m2, component = "all", split_nested = TRUE), c("mysubgrp", "mygrp", "Subject"))
    expect_null(find_random(m2, component = "zi"))
    expect_null(find_random(m2, component = "zi", split_nested = TRUE))
    expect_null(find_random(m2, component = "disp"))
    expect_null(find_random(m2, component = "disp", split_nested = TRUE))
  })

  test_that("find_response", {
    expect_identical(find_response(m1), "Reaction")
    expect_identical(find_response(m2), "Reaction")
  })

  test_that("link_inverse", {
    expect_identical(link_inverse(m1)(.2), .2)
    expect_identical(link_inverse(m2)(.2), .2)
  })

  test_that("get_data", {
    expect_equal(colnames(get_data(m1)), c("Reaction", "Days", "Subject"))
    expect_equal(colnames(get_data(m1, effects = "all")), c("Reaction", "Days", "Subject"))
    expect_equal(colnames(get_data(m1, effects = "random")), "Subject")
    expect_equal(colnames(get_data(m2)), c("Reaction", "Days", "mygrp", "mysubgrp", "Subject"))
    expect_equal(colnames(get_data(m2, effects = "all")), c("Reaction", "Days", "mygrp", "mysubgrp", "Subject"))
    expect_equal(colnames(get_data(m2, effects = "random")), c("mygrp", "mysubgrp", "Subject"))
  })

  test_that("find_formula", {
    expect_length(find_formula(m1), 1)
    expect_identical(find_formula(m1, component = "conditional"), stats::formula(m1))
    expect_identical(find_formula(m2, component = "cond"), stats::formula(m2))
    expect_null(find_formula(m2, component = "zero_inflated"))
  })

  test_that("find_terms", {
    expect_identical(find_terms(m1), list(
      response = "Reaction",
      conditional = "Days",
      random = "Subject"
    ))
    expect_identical(find_terms(m1, flatten = TRUE), c("Reaction", "Days", "Subject"))
    expect_identical(find_terms(m2), list(
      response = "Reaction",
      conditional = "Days",
      random = c("mysubgrp", "mygrp", "Subject")
    ))
    expect_identical(find_terms(m2, flatten = TRUE), c("Reaction", "Days", "mysubgrp", "mygrp", "Subject"))
  })

  test_that("get_response", {
    expect_identical(get_response(m1), sleepstudy$Reaction)
  })

  test_that("get_predictors", {
    expect_identical(colnames(get_predictors(m1)), "Days")
    expect_identical(colnames(get_predictors(m2)), "Days")
  })

  test_that("get_random", {
    expect_identical(colnames(get_random(m1)), "Subject")
    expect_identical(colnames(get_random(m2)), c("mysubgrp", "mygrp", "Subject"))
  })

}
