#' @title Find names of model parameters from Bayesian models
#' @name find_parameters.BGGM
#'
#' @description Returns the names of model parameters, like they typically
#' appear in the `summary()` output. For Bayesian models, the parameter
#' names equal the column names of the posterior samples after coercion
#' from `as.data.frame()`.
#'
#' @param parameters Regular expression pattern that describes the parameters that
#' should be returned.
#' @param ... Currently not used.
#' @inheritParams find_parameters
#' @inheritParams find_parameters.betamfx
#' @inheritParams find_predictors
#'
#' @return A list of parameter names. For simple models, only one list-element,
#' `conditional`, is returned. For more complex models, the returned list may
#' have following elements:
#'
#' - `conditional`, the "fixed effects" part from the model
#' - `random`, the "random effects" part from the model
#' - `zero_inflated`, the "fixed effects" part from the zero-inflation component
#'   of the model
#' - `zero_inflated_random`, the "random effects" part from the zero-inflation
#'   component of the model
#' - `smooth_terms`, the smooth parameters
#'
#' Furthermore, some models, especially from **brms**, can also return auxiliary
#' parameters. These may be one of the following:
#'
#' - `sigma`, the residual standard deviation (auxiliary parameter)
#' - `dispersion`, the dispersion parameters (auxiliary parameter)
#' - `beta`, the beta parameter (auxiliary parameter)
#' - `simplex`, simplex parameters of monotonic effects (**brms** only)
#' - `mix`, mixture parameters (**brms** only)
#' - `shiftprop`, shifted proportion parameters (**brms** only)
#'
#' Models of class **BGGM** additionally can return the elements `correlation`
#' and `intercept`.
#'
#' Models of class **BFBayesFactor** additionally can return the element
#' `extra`.
#'
#' @examples
#' data(mtcars)
#' m <- lm(mpg ~ wt + cyl + vs, data = mtcars)
#' find_parameters(m)
#' @export
find_parameters.BGGM <- function(x, component = "correlation", flatten = FALSE, ...) {
  component <- validate_argument(component, c("correlation", "conditional", "intercept", "all"))
  l <- switch(component,
    correlation = list(correlation = colnames(get_parameters(x, component = "correlation"))),
    conditional = list(conditional = colnames(get_parameters(x, component = "conditional"))),
    intercept = list(intercept = colnames(x$Y)),
    all = list(
      intercept = colnames(x$Y),
      correlation = colnames(get_parameters(x, component = "correlation")),
      conditional = colnames(get_parameters(x, component = "conditional"))
    )
  )

  l <- compact_list(l)

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.BFBayesFactor <- function(x,
                                          effects = "all",
                                          component = "all",
                                          flatten = FALSE,
                                          ...) {
  conditional <- NULL
  random <- NULL
  extra <- NULL

  effects <- validate_argument(effects, c("all", "fixed", "random"))
  component <- validate_argument(component, c("all", "extra"))

  if (.classify_BFBayesFactor(x) == "correlation") {
    conditional <- "rho"
  } else if (.classify_BFBayesFactor(x) %in% c("ttest1", "ttest2")) {
    conditional <- "Difference"
  } else if (.classify_BFBayesFactor(x) == "meta") {
    conditional <- "Effect"
  } else if (.classify_BFBayesFactor(x) == "proptest") {
    conditional <- "p"
  } else if (.classify_BFBayesFactor(x) == "linear") {
    posteriors <- as.data.frame(suppressMessages(
      BayesFactor::posterior(x, iterations = 20, progress = FALSE, index = 1, ...)
    ))

    params <- colnames(posteriors)
    vars <- find_variables(x, effects = "all", verbose = FALSE)
    interactions <- find_interactions(x)
    dat <- get_data(x, verbose = FALSE)

    if ("conditional" %in% names(vars)) {
      conditional <- unlist(lapply(vars$conditional, function(i) {
        if (is.factor(dat[[i]])) {
          sprintf("%s-%s", i, levels(dat[[i]]))
        } else {
          sprintf("%s-%s", i, i)
        }
      }), use.names = FALSE)
    }

    # add interaction terms to conditional
    if ("conditional" %in% names(interactions)) {
      for (i in interactions$conditional) {
        conditional <- c(conditional, grep(paste0("^\\Q", i, "\\E"), params, value = TRUE))
      }
    }

    if ("random" %in% names(vars)) {
      random <- unlist(lapply(vars$random, function(i) {
        if (is.factor(dat[[i]])) {
          sprintf("%s-%s", i, levels(dat[[i]]))
        } else {
          sprintf("%s-%s", i, i)
        }
      }), use.names = FALSE)
    }

    extra <- setdiff(params, c(conditional, random))
  }

  elements <- .get_elements(effects, component = component)
  l <- lapply(compact_list(list(conditional = conditional, random = random, extra = extra)), text_remove_backticks)
  l <- compact_list(l[elements])

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.MCMCglmm <- function(x, effects = "all", flatten = FALSE, ...) {
  sc <- summary(x)
  effects <- validate_argument(effects, c("all", "fixed", "random"))

  l <- compact_list(list(
    conditional = rownames(sc$solutions),
    random = rownames(sc$Gcovariances)
  ))

  .filter_parameters(l,
    effects = effects,
    flatten = flatten,
    recursive = FALSE
  )
}


#' @export
find_parameters.mcmc.list <- function(x, flatten = FALSE, ...) {
  l <- list(conditional = colnames(x[[1]]))
  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.bamlss <- function(x, flatten = FALSE, component = "all", parameters = NULL, ...) {
  component <- validate_argument(component, c("all", "conditional", "location", "distributional", "auxiliary"))
  cn <- colnames(as.data.frame(unclass(x$samples)))

  ignore <- grepl("(\\.alpha|logLik|\\.accepted|\\.edf)$", cn)
  cond <- cn[grepl("^(mu\\.p\\.|pi\\.p\\.)", cn) & !ignore]
  aux <- cn[startsWith(cn, "sigma.p.") & !ignore]
  smooth_terms <- cn[grepl("^mu\\.s\\.(.*)(\\.tau\\d+|\\.edf)$", cn)]
  alpha <- cn[endsWith(cn, ".alpha")]

  elements <- .get_elements(effects = "all", component = component)
  l <- compact_list(list(
    conditional = cond,
    smooth_terms = smooth_terms,
    sigma = aux,
    alpha = alpha
  )[elements])

  l <- .filter_pars(l, parameters)

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @rdname find_parameters.BGGM
#' @export
find_parameters.brmsfit <- function(x,
                                    effects = "all",
                                    component = "all",
                                    flatten = FALSE,
                                    parameters = NULL,
                                    ...) {
  effects <- validate_argument(effects, c("all", "fixed", "random"))
  component <- validate_argument(component, c("all", .all_elements(), "location", "distributional"))

  fe <- dimnames(x$fit)$parameters
  # fe <- colnames(as.data.frame(x))

  # remove redundant columns. These seem to be new since brms 2.16?
  pattern <- "^[A-z]_\\d\\.\\d\\.(.*)"
  fe <- fe[!grepl(pattern, fe)]

  is_mv <- NULL

  # remove "Intercept"
  fe <- fe[!startsWith(fe, "Intercept")]

  cond <- fe[grepl("^(b_|bs_|bsp_|bcs_)(?!zi_)(.*)", fe, perl = TRUE)]
  zi <- fe[grepl("^(b_zi_|bs_zi_|bsp_zi_|bcs_zi_)", fe)]
  rand <- fe[grepl("(?!.*__(zi|sigma|beta))(?=.*^r_)", fe, perl = TRUE) & !startsWith(fe, "prior_")]
  randzi <- fe[grepl("^r_(.*__zi)", fe)]
  rand_sd <- fe[grepl("(?!.*_zi)(?=.*^sd_)", fe, perl = TRUE)]
  randzi_sd <- fe[grepl("^sd_(.*_zi)", fe)]
  rand_cor <- fe[grepl("(?!.*_zi)(?=.*^cor_)", fe, perl = TRUE)]
  randzi_cor <- fe[grepl("^cor_(.*_zi)", fe)]
  simo <- fe[startsWith(fe, "simo_")]
  car_struc <- fe[fe %in% c("car", "sdcar")]
  smooth_terms <- fe[startsWith(fe, "sds_")]
  priors <- fe[startsWith(fe, "prior_")]
  sigma_param <- fe[startsWith(fe, "sigma_") | grepl("sigma", fe, fixed = TRUE)]
  randsigma <- fe[grepl("^r_(.*__sigma)", fe)]
  fixed_beta <- fe[grepl("beta", fe, fixed = TRUE)]
  rand_beta <- fe[grepl("^r_(.*__beta)", fe)]
  mix <- fe[grepl("mix", fe, fixed = TRUE)]
  shiftprop <- fe[grepl("shiftprop", fe, fixed = TRUE)]
  dispersion <- fe[grepl("dispersion", fe, fixed = TRUE)]
  auxiliary <- fe[grepl("(shape|phi|precision|_ndt_)", fe)]

  # if auxiliary is modelled directly, we need to remove duplicates here
  # e.g. "b_sigma..." is in "cond" and in "sigma" now, we just need it in "cond".

  sigma_param <- setdiff(sigma_param, c(cond, rand, rand_sd, rand_cor, randsigma, car_struc, "prior_sigma"))
  fixed_beta <- setdiff(fixed_beta, c(cond, rand, rand_sd, rand_beta, rand_cor, car_struc))
  auxiliary <- setdiff(auxiliary, c(cond, rand, rand_sd, rand_cor, car_struc))

  l <- compact_list(list(
    conditional = cond,
    random = c(rand, rand_sd, rand_cor, car_struc),
    zero_inflated = zi,
    zero_inflated_random = c(randzi, randzi_sd, randzi_cor),
    simplex = simo,
    smooth_terms = smooth_terms,
    sigma = sigma_param,
    sigma_random = randsigma,
    beta = fixed_beta,
    beta_random = rand_beta,
    dispersion = dispersion,
    mix = mix,
    shiftprop = shiftprop,
    auxiliary = auxiliary,
    priors = priors
  ))

  elements <- .get_elements(effects = effects, component = component)
  elements <- c(elements, "priors")

  if (is_multivariate(x)) {
    rn <- names(find_response(x))
    l <- lapply(rn, function(i) {
      if (object_has_names(l, "conditional")) {
        conditional <- l$conditional[grepl(sprintf("^(b_|bs_|bsp_|bcs_)\\Q%s\\E_", i), l$conditional)]
      } else {
        conditional <- NULL
      }

      if (object_has_names(l, "random")) {
        random <- l$random[grepl(sprintf("__\\Q%s\\E\\[", i), l$random) |
          grepl(sprintf("^sd_(.*)\\Q%s\\E\\_", i), l$random) |
          startsWith(l$random, "cor_") |
          l$random %in% c("car", "sdcar")]
      } else {
        random <- NULL
      }

      if (object_has_names(l, "zero_inflated")) {
        zero_inflated <- l$zero_inflated[grepl(sprintf("^(b_zi_|bs_zi_|bsp_zi_|bcs_zi_)\\Q%s\\E_", i), l$zero_inflated)]
      } else {
        zero_inflated <- NULL
      }

      if (object_has_names(l, "zero_inflated_random")) {
        zero_inflated_random <- l$zero_inflated_random[grepl(sprintf("__zi_\\Q%s\\E\\[", i), l$zero_inflated_random) |
          grepl(sprintf("^sd_(.*)\\Q%s\\E\\_", i), l$zero_inflated_random) |
          startsWith(l$zero_inflated_random, "cor_")]
      } else {
        zero_inflated_random <- NULL
      }

      if (object_has_names(l, "simplex")) {
        simplex <- l$simplex
      } else {
        simplex <- NULL
      }

      if (object_has_names(l, "sigma")) {
        sigma_param <- l$sigma[grepl(sprintf("^sigma_\\Q%s\\E$", i), l$sigma)]
      } else {
        sigma_param <- NULL
      }

      if (object_has_names(l, "beta")) {
        fixed_beta <- l$beta[grepl(sprintf("^beta_\\Q%s\\E$", i), l$beta)]
      } else {
        fixed_beta <- NULL
      }

      if (object_has_names(l, "dispersion")) {
        dispersion <- l$dispersion[grepl(sprintf("^dispersion_\\Q%s\\E$", i), l$dispersion)]
      } else {
        dispersion <- NULL
      }

      if (object_has_names(l, "mix")) {
        mix <- l$mix[grepl(sprintf("^mix_\\Q%s\\E$", i), l$mix)]
      } else {
        mix <- NULL
      }

      if (object_has_names(l, "shape") || object_has_names(l, "precision")) {
        aux <- l$aux[grepl(sprintf("^(shape|precision)_\\Q%s\\E$", i), l$aux)]
      } else {
        aux <- NULL
      }

      if (object_has_names(l, "smooth_terms")) {
        smooth_terms <- l$smooth_terms
      } else {
        smooth_terms <- NULL
      }

      if (object_has_names(l, "priors")) {
        priors <- l$priors
      } else {
        priors <- NULL
      }

      pars <- compact_list(list(
        conditional = conditional,
        random = random,
        zero_inflated = zero_inflated,
        zero_inflated_random = zero_inflated_random,
        simplex = simplex,
        smooth_terms = smooth_terms,
        sigma = sigma_param,
        beta = fixed_beta,
        dispersion = dispersion,
        mix = mix,
        priors = priors,
        auxiliary = aux
      ))

      compact_list(pars[elements])
    })

    names(l) <- rn
    is_mv <- "1"
  } else {
    l <- compact_list(l[elements])
  }

  l <- .filter_pars(l, parameters, !is.null(is_mv) && is_mv == "1")
  attr(l, "is_mv") <- is_mv

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.bayesx <- function(x, component = "all", flatten = FALSE, parameters = NULL, ...) {
  cond <- rownames(stats::coef(x))
  smooth_terms <- rownames(x$smooth.hyp)

  l <- compact_list(list(
    conditional = cond,
    smooth_terms = smooth_terms
  ))

  l <- .filter_pars(l, parameters)

  component <- validate_argument(component, c("all", "conditional", "smooth_terms"))
  elements <- .get_elements(effects = "all", component)
  l <- compact_list(l[elements])

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.stanreg <- function(x,
                                    effects = "all",
                                    component = "location",
                                    flatten = FALSE,
                                    parameters = NULL,
                                    ...) {
  fe <- colnames(as.data.frame(x))
  # This does not exclude all relevant names, see e.g. "stanreg_merMod_5".
  # fe <- setdiff(dimnames(x$stanfit)$parameters, c("mean_PPD", "log-posterior"))

  cond <- fe[grepl("^(?!(b\\[|sigma|Sigma))", fe, perl = TRUE) & .grep_non_smoothers(fe)]
  rand <- fe[startsWith(fe, "b[")]
  rand_sd <- fe[startsWith(fe, "Sigma[")]
  smooth_terms <- fe[startsWith(fe, "smooth_sd")]
  sigma_param <- fe[grepl("sigma", fe, fixed = TRUE)]
  auxiliary <- fe[grepl("(shape|phi|precision)", fe)]

  # remove auxiliary from conditional
  cond <- setdiff(cond, auxiliary)

  l <- compact_list(list(
    conditional = cond,
    random = c(rand, rand_sd),
    smooth_terms = smooth_terms,
    sigma = sigma_param,
    auxiliary = auxiliary
  ))

  l <- .filter_pars(l, parameters)

  effects <- validate_argument(effects, c("all", "fixed", "random"))
  component <- validate_argument(component, c("location", "all", "conditional", "smooth_terms", "sigma", "distributional", "auxiliary")) # nolint
  elements <- .get_elements(effects, component)
  l <- compact_list(l[elements])

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.bcplm <- function(x,
                                  flatten = FALSE,
                                  parameters = NULL,
                                  ...) {
  l <- .filter_pars(list(conditional = dimnames(x$sims.list[[1]])[[2]]), parameters)
  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.stanmvreg <- function(x,
                                      effects = "all",
                                      component = "location",
                                      flatten = FALSE,
                                      parameters = NULL,
                                      ...) {
  fe <- colnames(as.data.frame(x))
  rn <- names(find_response(x))

  cond <- fe[grepl("^(?!(b\\[|sigma|Sigma))", fe, perl = TRUE) & .grep_non_smoothers(fe) & !endsWith(fe, "|sigma")]
  rand <- fe[startsWith(fe, "b[")]
  rand_sd <- fe[startsWith(fe, "Sigma[")]
  smooth_terms <- fe[startsWith(fe, "smooth_sd")]
  sigma_param <- fe[endsWith(fe, "|sigma") & .grep_non_smoothers(fe)]
  auxiliary <- fe[grepl("(shape|phi|precision)", fe)]

  # remove auxiliary from conditional
  cond <- setdiff(cond, auxiliary)

  l <- compact_list(list(
    conditional = cond,
    random = c(rand, rand_sd),
    smooth_terms = smooth_terms,
    sigma = sigma_param,
    auxiliary = auxiliary
  ))

  if (object_has_names(l, "conditional")) {
    x1 <- sub("(.*)(\\|)(.*)", "\\1", l$conditional)
    x2 <- sub("(.*)(\\|)(.*)", "\\3", l$conditional)

    l.cond <- lapply(rn, function(i) {
      list(conditional = x2[which(x1 == i)])
    })
    names(l.cond) <- rn
  } else {
    l.cond <- NULL
  }


  if (object_has_names(l, "random")) {
    x1 <- sub("b\\[(.*)(\\|)(.*)", "\\1", l$random)
    x2 <- sub("(b\\[).*(.*)(\\|)(.*)", "\\1\\4", l$random)

    l.random <- lapply(rn, function(i) {
      list(random = x2[which(x1 == i)])
    })
    names(l.random) <- rn
  } else {
    l.random <- NULL
  }


  if (object_has_names(l, "sigma")) {
    l.sigma <- lapply(rn, function(i) {
      list(sigma = "sigma")
    })
    names(l.sigma) <- rn
  } else {
    l.sigma <- NULL
  }


  l <- Map(c, l.cond, l.random, l.sigma)
  l <- .filter_pars(l, parameters, is_mv = TRUE)

  effects <- validate_argument(effects, c("all", "fixed", "random"))
  component <- validate_argument(component, c("location", "all", "conditional", "smooth_terms", "sigma", "distributional", "auxiliary")) # nolint
  elements <- .get_elements(effects, component)
  l <- lapply(l, function(i) compact_list(i[elements]))

  attr(l, "is_mv") <- "1"

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


# Simulation models -----------------------------


#' @export
find_parameters.sim.merMod <- function(x,
                                       effects = "all",
                                       flatten = FALSE,
                                       parameters = NULL,
                                       ...) {
  fe <- colnames(.get_armsim_fixef_parms(x))
  re <- colnames(.get_armsim_ranef_parms(x))

  l <- compact_list(list(
    conditional = fe,
    random = re
  ))

  l <- .filter_pars(l, parameters)

  effects <- validate_argument(effects, c("all", "fixed", "random"))
  elements <- .get_elements(effects, component = "all")
  l <- compact_list(l[elements])

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.sim <- function(x, flatten = FALSE, parameters = NULL, ...) {
  l <- .filter_pars(
    list(conditional = colnames(.get_armsim_fixef_parms(x))),
    parameters
  )

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.mcmc <- function(x, flatten = FALSE, parameters = NULL, ...) {
  l <- .filter_pars(list(conditional = colnames(x)), parameters)

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.bayesQR <- function(x, flatten = FALSE, parameters = NULL, ...) {
  l <- .filter_pars(list(conditional = x[[1]]$names), parameters)

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}


#' @export
find_parameters.stanfit <- function(x, effects = "all", flatten = FALSE, parameters = NULL, ...) {
  fe <- colnames(as.data.frame(x))

  cond <- fe[grepl("^(?!(b\\[|sigma|Sigma|lp__))", fe, perl = TRUE) & .grep_non_smoothers(fe)]
  rand <- fe[startsWith(fe, "b[")]

  l <- compact_list(list(
    conditional = cond,
    random = rand
  ))

  l <- .filter_pars(l, parameters)

  effects <- validate_argument(effects, c("all", "fixed", "random"))
  elements <- .get_elements(effects, component = "all")
  l <- compact_list(l[elements])

  if (flatten) {
    unique(unlist(l, use.names = FALSE))
  } else {
    l
  }
}
