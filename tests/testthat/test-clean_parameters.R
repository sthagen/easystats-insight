test_that("clean_parameters blavaan", {
  skip_on_cran()
  skip_if_not_installed("blavaan")
  skip_if_not_installed("lavaan")
  skip_if_not_installed("Rcpp")
  suppressPackageStartupMessages(require("blavaan", quietly = TRUE, warn.conflicts = FALSE)) # nolint

  data("PoliticalDemocracy", package = "lavaan")

  model <- "
    # latent variable definitions
    dem60 =~ y1 + a*y2
    dem65 =~ y5 + a*y6

    # regressions
    dem65 ~ dem60

    # residual correlations
    y1 ~~ y5
  "

  suppressWarnings(capture.output({
    bfit <- blavaan::bsem(model,
      data = PoliticalDemocracy,
      n.chains = 1, burnin = 50, sample = 100
    )
  }))

  out <- clean_parameters(bfit)
  expect_true(inherits(out, "clean_parameters")) # nolint
})


test_that("clean_parameters stanrag", {
  skip_on_cran()
  skip_if_not_installed("rstanarm")
  skip_if_not_installed("lme4")

  data(sleepstudy, package = "lme4")
  m <- insight::download_model("stanreg_merMod_6")
  out <- clean_parameters(m)

  expect_identical(
    out$Group,
    c(
      "", "", "Intercept: Subject", "Days: Subject", "Intercept: Subject",
      "Days: Subject", "Intercept: Subject", "Days: Subject", "Intercept: Subject",
      "Days: Subject", "Intercept: Subject", "Days: Subject", "Intercept: Subject",
      "Days: Subject", "Intercept: Subject", "Days: Subject", "Intercept: Subject",
      "Days: Subject", "Intercept: Subject", "Days: Subject", "Intercept: Subject",
      "Days: Subject", "Intercept: Subject", "Days: Subject", "Intercept: Subject",
      "Days: Subject", "Intercept: Subject", "Days: Subject", "Intercept: Subject",
      "Days: Subject", "Intercept: Subject", "Days: Subject", "Intercept: Subject",
      "Days: Subject", "Intercept: Subject", "Days: Subject", "Intercept: Subject",
      "Days: Subject", "Var/Cov: Subject", "Var/Cov: Subject", "Var/Cov: Subject", ""
    )
  )
})
