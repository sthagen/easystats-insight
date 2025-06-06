skip_if_not_installed("lme4")

data(sleepstudy, package = "lme4")
set.seed(123)
sleepstudy$mygrp <- sample.int(5, size = 180, replace = TRUE)
sleepstudy$mysubgrp <- NA
for (i in 1:5) {
  filter_group <- sleepstudy$mygrp == i
  sleepstudy$mysubgrp[filter_group] <-
    sample.int(30, size = sum(filter_group), replace = TRUE)
}

m1 <- lme4::lmer(Reaction ~ Days + (1 + Days | Subject),
  data = sleepstudy
)

m2 <- suppressMessages(
  lme4::lmer(Reaction ~ Days + (1 | mygrp / mysubgrp) + (1 | Subject),
    data = sleepstudy
  )
)

test_that("model_info", {
  expect_true(model_info(m1)$is_linear)
  expect_true(model_info(m2)$is_linear)
})

test_that("loglik", {
  expect_equal(get_loglikelihood(m1, estimator = "REML"), logLik(m1), ignore_attr = TRUE)
  expect_equal(get_loglikelihood(m2, estimator = "REML"), logLik(m2), ignore_attr = TRUE)
  expect_equal(get_loglikelihood(m1), logLik(m1), ignore_attr = TRUE)
  expect_equal(get_loglikelihood(m2), logLik(m2), ignore_attr = TRUE)
  expect_equal(get_loglikelihood(m1, estimator = "ML"), logLik(m1, REML = FALSE), ignore_attr = TRUE)
  expect_equal(get_loglikelihood(m2, estimator = "ML"), logLik(m2, REML = FALSE), ignore_attr = TRUE)
})

test_that("get_df", {
  expect_equal(get_df(m1), df.residual(m1), ignore_attr = TRUE)
  expect_equal(get_df(m2), df.residual(m2), ignore_attr = TRUE)
  expect_equal(get_df(m1, type = "model"), attr(logLik(m1), "df"), ignore_attr = TRUE)
  expect_equal(get_df(m2, type = "model"), attr(logLik(m2), "df"), ignore_attr = TRUE)
})

test_that("get_df", {
  expect_equal(
    get_df(m1, type = "residual"),
    df.residual(m1),
    ignore_attr = TRUE
  )
  expect_equal(
    get_df(m1, type = "normal"),
    Inf,
    ignore_attr = TRUE
  )
  expect_equal(
    get_df(m1, type = "wald"),
    df.residual(m1),
    ignore_attr = TRUE
  )
  expect_equal(
    get_df(m1, type = "satterthwaite"),
    c(`(Intercept)` = 16.99973, Days = 16.99998),
    ignore_attr = TRUE,
    tolerance = 1e-4
  )
  expect_equal(
    as.vector(get_df(m1, type = "kenward")),
    c(17, 17),
    ignore_attr = TRUE,
    tolerance = 1e-4
  )
  skip_if_not_installed("pbkrtest")
  expect_equal(
    as.vector(get_df(m1, type = "kenward")),
    c(pbkrtest::get_Lb_ddf(m1, c(1, 0)), pbkrtest::get_Lb_ddf(m1, c(0, 1))),
    ignore_attr = TRUE,
    tolerance = 1e-4
  )
  expect_equal(
    unique(as.vector(get_df(m2, type = "kenward"))),
    c(pbkrtest::get_Lb_ddf(m2, c(1, 0)), pbkrtest::get_Lb_ddf(m2, c(0, 1))),
    ignore_attr = TRUE,
    tolerance = 1e-4
  )

  skip_if_not_installed("lmerTest")
  # per observation df
  data(mtcars)
  mod <- lme4::lmer(am ~ hp + (1 | cyl), data = mtcars)
  out1 <- get_df(mod, type = "satterthwaite", df_per_obs = TRUE, data = mtcars)
  out2 <- get_df(mod, type = "satterthwaite", df_per_obs = FALSE)
  expect_equal(
    out1,
    c(
      1.75657, 1.75657, 1.89121, 1.75657, 1.80609, 1.78946, 2.95048,
      2.31532, 1.87196, 1.69622, 1.69622, 1.84694, 1.84694, 1.84694,
      2.13913, 2.29991, 2.59236, 2.2466, 2.50664, 2.26337, 1.85365,
      1.68312, 1.68312, 2.95048, 1.80609, 2.2466, 1.91138, 1.73945,
      3.50471, 1.80609, 6.61056, 1.76271
    ),
    tolerance = 1e-3
  )
  expect_equal(
    out2,
    c(`(Intercept)` = 3.99802, hp = 29.3951),
    tolerance = 1e-3
  )
})

test_that("n_parameters", {
  expect_identical(n_parameters(m1), 2L)
  expect_identical(n_parameters(m2), 2L)
  expect_identical(n_parameters(m1, effects = "random"), 2L)
  expect_identical(n_parameters(m2, effects = "random"), 3L)
})

test_that("find_offset", {
  model_off <- lme4::lmer(log(mpg) ~ disp + (1 | cyl), offset = log(wt), data = mtcars)
  expect_identical(find_offset(model_off), "wt")
  model_off <- lme4::lmer(log(mpg) ~ disp + (1 | cyl) + offset(log(wt)), data = mtcars)
  expect_identical(find_offset(model_off), "wt")
})

test_that("find_predictors", {
  expect_identical(
    find_predictors(m1, effects = "all"),
    list(conditional = "Days", random = "Subject")
  )
  expect_identical(
    find_predictors(m1, effects = "all", flatten = TRUE),
    c("Days", "Subject")
  )
  expect_identical(
    find_predictors(m1, effects = "fixed"),
    list(conditional = "Days")
  )
  expect_identical(
    find_predictors(m1, effects = "fixed", flatten = TRUE),
    "Days"
  )
  expect_identical(
    find_predictors(m1, effects = "random"),
    list(random = "Subject")
  )
  expect_identical(
    find_predictors(m1, effects = "random", flatten = TRUE),
    "Subject"
  )
  expect_identical(
    find_predictors(m2, effects = "all"),
    list(
      conditional = "Days",
      random = c("mysubgrp", "mygrp", "Subject")
    )
  )
  expect_identical(
    find_predictors(m2, effects = "all", flatten = TRUE),
    c("Days", "mysubgrp", "mygrp", "Subject")
  )
  expect_identical(
    find_predictors(m2, effects = "fixed"),
    list(conditional = "Days")
  )
  expect_identical(find_predictors(m2, effects = "random"), list(random = c("mysubgrp", "mygrp", "Subject")))
  expect_null(find_predictors(m2, effects = "all", component = "zi"))
  expect_null(find_predictors(m2, effects = "fixed", component = "zi"))
  expect_null(find_predictors(m2, effects = "random", component = "zi"))
})

test_that("find_random", {
  expect_identical(find_random(m1), list(random = "Subject"))
  expect_identical(find_random(m1, flatten = TRUE), "Subject")
  expect_identical(find_random(m2), list(random = c("mysubgrp:mygrp", "mygrp", "Subject")))
  expect_identical(find_random(m2, split_nested = TRUE), list(random = c("mysubgrp", "mygrp", "Subject")))
  expect_identical(
    find_random(m2, flatten = TRUE),
    c("mysubgrp:mygrp", "mygrp", "Subject")
  )
  expect_identical(
    find_random(m2, split_nested = TRUE, flatten = TRUE),
    c("mysubgrp", "mygrp", "Subject")
  )
})

test_that("find_response", {
  expect_identical(find_response(m1), "Reaction")
  expect_identical(find_response(m2), "Reaction")
})

test_that("get_response", {
  expect_equal(get_response(m1), sleepstudy$Reaction, tolerance = 1e-5)
})

test_that("link_inverse", {
  expect_identical(link_inverse(m1)(0.2), 0.2)
  expect_identical(link_inverse(m2)(0.2), 0.2)
})

test_that("get_data", {
  expect_named(get_data(m1), c("Reaction", "Days", "Subject"))
  expect_named(get_data(m1, effects = "all"), c("Reaction", "Days", "Subject"))
  expect_named(get_data(m1, effects = "random"), "Subject")
  expect_named(
    get_data(m2),
    c("Reaction", "Days", "mysubgrp", "mygrp", "Subject")
  )
  expect_named(
    get_data(m2, effects = "all"),
    c("Reaction", "Days", "mysubgrp", "mygrp", "Subject")
  )
  expect_named(get_data(m2, effects = "random"), c("mysubgrp", "mygrp", "Subject"))
})

test_that("find_formula", {
  expect_length(find_formula(m1), 2)
  expect_length(find_formula(m2), 2)
  expect_equal(
    find_formula(m1, component = "conditional"),
    list(
      conditional = as.formula("Reaction ~ Days"),
      random = as.formula("~1 + Days | Subject")
    ),
    ignore_attr = TRUE
  )
  expect_equal(
    find_formula(m2, component = "conditional"),
    list(
      conditional = as.formula("Reaction ~ Days"),
      random = list(
        as.formula("~1 | mysubgrp:mygrp"),
        as.formula("~1 | mygrp"),
        as.formula("~1 | Subject")
      )
    ),
    ignore_attr = TRUE
  )
})

test_that("find_terms", {
  expect_identical(
    find_terms(m1),
    list(
      response = "Reaction",
      conditional = "Days",
      random = c("Days", "Subject")
    )
  )
  expect_identical(
    find_terms(m1, flatten = TRUE),
    c("Reaction", "Days", "Subject")
  )
  expect_identical(
    find_terms(m2),
    list(
      response = "Reaction",
      conditional = "Days",
      random = c("mysubgrp", "mygrp", "Subject")
    )
  )
  expect_identical(
    find_terms(m2, flatten = TRUE),
    c("Reaction", "Days", "mysubgrp", "mygrp", "Subject")
  )
})

test_that("find_variables", {
  expect_identical(
    find_variables(m1),
    list(
      response = "Reaction",
      conditional = "Days",
      random = "Subject"
    )
  )
  expect_identical(
    find_variables(m1, flatten = TRUE),
    c("Reaction", "Days", "Subject")
  )
  expect_identical(
    find_variables(m2),
    list(
      response = "Reaction",
      conditional = "Days",
      random = c("mysubgrp", "mygrp", "Subject")
    )
  )
  expect_identical(
    find_variables(m2, flatten = TRUE),
    c("Reaction", "Days", "mysubgrp", "mygrp", "Subject")
  )
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

test_that("clean_names", {
  expect_identical(clean_names(m1), c("Reaction", "Days", "Subject"))
  expect_identical(
    clean_names(m2),
    c("Reaction", "Days", "mysubgrp", "mygrp", "Subject")
  )
})

test_that("linkfun", {
  expect_false(is.null(link_function(m1)))
  expect_false(is.null(link_function(m2)))
})

test_that("find_parameters", {
  expect_identical(
    find_parameters(m1),
    list(
      conditional = c("(Intercept)", "Days"),
      random = list(Subject = c("(Intercept)", "Days"))
    )
  )
  expect_identical(nrow(get_parameters(m1)), 2L)
  expect_identical(get_parameters(m1)$Parameter, c("(Intercept)", "Days"))

  expect_identical(
    find_parameters(m2),
    list(
      conditional = c("(Intercept)", "Days"),
      random = list(
        `mysubgrp:mygrp` = "(Intercept)",
        Subject = "(Intercept)",
        mygrp = "(Intercept)"
      )
    )
  )

  expect_identical(nrow(get_parameters(m2)), 2L)
  expect_identical(get_parameters(m2)$Parameter, c("(Intercept)", "Days"))
  expect_named(
    get_parameters(m2, effects = "random"),
    c("mysubgrp:mygrp", "Subject", "mygrp")
  )
})

test_that("is_multivariate", {
  expect_false(is_multivariate(m1))
  expect_false(is_multivariate(m2))
})

test_that("get_variance", {
  expect_equal(
    get_variance(m1),
    list(
      var.fixed = 908.9534,
      var.random = 1698.084,
      var.residual = 654.94,
      var.distribution = 654.94,
      var.dispersion = 0,
      var.intercept = c(Subject = 612.1002),
      var.slope = c(Subject.Days = 35.07171),
      cor.slope_intercept = c(Subject = 0.06555124)
    ),
    tolerance = 1e-1
  )

  expect_equal(get_variance_fixed(m1),
    c(var.fixed = 908.9534),
    tolerance = 1e-1
  )
  expect_equal(get_variance_random(m1),
    c(var.random = 1698.084),
    tolerance = 1e-1
  )
  expect_equal(
    get_variance_residual(m1),
    c(var.residual = 654.94),
    tolerance = 1e-1
  )
  expect_equal(
    get_variance_distribution(m1),
    c(var.distribution = 654.94),
    tolerance = 1e-1
  )
  expect_equal(get_variance_dispersion(m1),
    c(var.dispersion = 0),
    tolerance = 1e-1
  )

  expect_equal(
    get_variance_intercept(m1),
    c(var.intercept.Subject = 612.1002),
    tolerance = 1e-1
  )
  expect_equal(
    get_variance_slope(m1),
    c(var.slope.Subject.Days = 35.07171),
    tolerance = 1e-1
  )
  expect_equal(
    get_correlation_slope_intercept(m1),
    c(cor.slope_intercept.Subject = 0.06555124),
    tolerance = 1e-1
  )

  expect_equal(
    suppressWarnings(get_variance(m2)),
    list(
      var.fixed = 889.3301,
      var.residual = 941.8135,
      var.distribution = 941.8135,
      var.dispersion = 0,
      var.intercept = c(
        `mysubgrp:mygrp` = 0,
        Subject = 1357.4257,
        mygrp = 24.4064
      )
    ),
    tolerance = 1e-1
  )
})

test_that("find_algorithm", {
  expect_identical(
    find_algorithm(m1),
    list(algorithm = "REML", optimizer = "nloptwrap")
  )
})

test_that("find_random_slopes", {
  expect_identical(find_random_slopes(m1), list(random = "Days"))
  expect_null(find_random_slopes(m2))
})


suppressMessages({
  m3 <- lme4::lmer(Reaction ~ (1 + Days | Subject),
    data = sleepstudy
  )

  m4 <- lme4::lmer(
    Reaction ~ (1 |
      mygrp / mysubgrp) + (1 | Subject),
    data = sleepstudy
  )

  m5 <- lme4::lmer(Reaction ~ 1 + (1 + Days | Subject),
    data = sleepstudy
  )

  m6 <- lme4::lmer(
    Reaction ~ 1 + (1 | mygrp / mysubgrp) + (1 | Subject),
    data = sleepstudy
  )
})

test_that("find_formula", {
  expect_equal(
    find_formula(m3),
    list(
      conditional = as.formula("Reaction ~ 1"),
      random = as.formula("~1 + Days | Subject")
    ),
    ignore_attr = TRUE
  )

  expect_equal(
    find_formula(m5),
    list(
      conditional = as.formula("Reaction ~ 1"),
      random = as.formula("~1 + Days | Subject")
    ),
    ignore_attr = TRUE
  )

  expect_equal(
    find_formula(m4),
    list(
      conditional = as.formula("Reaction ~ 1"),
      random = list(
        as.formula("~1 | mysubgrp:mygrp"),
        as.formula("~1 | mygrp"),
        as.formula("~1 | Subject")
      )
    ),
    ignore_attr = TRUE
  )

  expect_equal(
    find_formula(m6),
    list(
      conditional = as.formula("Reaction ~ 1"),
      random = list(
        as.formula("~1 | mysubgrp:mygrp"),
        as.formula("~1 | mygrp"),
        as.formula("~1 | Subject")
      )
    ),
    ignore_attr = TRUE
  )
})

test_that("satterthwaite dof vs. emmeans", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("pbkrtest")

  v1 <- get_varcov(m2, vcov = "kenward-roger")
  v2 <- as.matrix(pbkrtest::vcovAdj(m2))
  expect_equal(v1, v2, ignore_attr = TRUE, tolerance = 1e-5)

  p1 <- get_predicted(m2, ci_method = "satterthwaite", ci = 0.95, include_random = FALSE)
  p1 <- data.frame(p1)
  em1 <- emmeans::ref_grid(
    object = m2,
    specs = ~Days,
    at = list(Days = sleepstudy$Days),
    lmer.df = "satterthwaite"
  )
  em1 <- confint(em1)
  expect_equal(p1$CI_low, em1$lower.CL, ignore_attr = TRUE, tolerance = 1e-5)
  expect_equal(p1$CI_high, em1$upper.CL, ignore_attr = TRUE, tolerance = 1e-5)

  p2 <- get_predicted(m2, ci_method = "kenward-roger", ci = 0.95, include_random = FALSE)
  p2 <- data.frame(p2)
  em2 <- emmeans::ref_grid(
    object = m2,
    specs = ~Days,
    at = list(Days = sleepstudy$Days),
    lmer.df = "kenward-roger"
  )
  em2 <- confint(em2)
  expect_equal(p2$CI_low, em2$lower.CL, ignore_attr = TRUE, tolerance = 1e-5)
  expect_equal(p2$CI_high, em2$upper.CL, ignore_attr = TRUE, tolerance = 1e-5)
})

test_that("find_statistic", {
  expect_identical(find_statistic(m1), "t-statistic")
  expect_identical(find_statistic(m2), "t-statistic")
})

test_that("get_call", {
  expect_true(inherits(get_call(m1), "call")) # nolint
  expect_true(inherits(get_call(m2), "call")) # nolint
  expect_type(get_call(m1), "language")
  expect_type(get_call(m2), "language")
})

test_that("get_predicted_ci: warning when model matrix and varcovmat do not match", {
  skip_if(getRversion() < "4.1.0")
  data(ChickWeight)
  mod <- suppressMessages(lme4::lmer(
    weight ~ 1 + Time + I(Time^2) + Diet + Time:Diet + I(Time^2):Diet + (1 + Time + I(Time^2) | Chick),
    data = ChickWeight
  ))
  newdata <- ChickWeight[ChickWeight$Time %in% 0:10 & ChickWeight$Chick %in% c(1, 40), ]
  newdata$Chick[newdata$Chick == "1"] <- NA

  expect_warning(
    get_predicted(mod, data = newdata, include_random = FALSE, ci = 0.95),
    regexp = "levels"
  )

  # VAB: Not sure where these hard-coded values come from
  # Related to Issue #693. Not sure if these are valid since we arbitrarily
  # shrink the varcov and mm to be conformable. In some cases documented in
  # Issue #556 of {marginaleffects}, we know that this produces incorrect
  # results, so it's probably best to be conservative and not return results
  # here.
  known <- data.frame(
    Predicted = c(37.53433, 47.95719, 58.78866, 70.02873, 81.67742, 93.73472),
    SE = c(1.68687, 0.82574, 1.52747, 2.56109, 3.61936, 4.76178),
    CI_low = c(34.22096, 46.33525, 55.78837, 64.99819, 74.56822, 84.38154),
    CI_high = c(40.84771, 49.57913, 61.78894, 75.05927, 88.78662, 103.08789)
  )

  p <- suppressWarnings(get_predicted(mod, data = newdata, include_random = FALSE, ci = 0.95))
  expect_equal(
    head(data.frame(p)$Predicted),
    known$Predicted,
    tolerance = 1e-3
  )
})
