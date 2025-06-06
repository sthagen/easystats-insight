#' @title Get link-function from model object
#' @name link_function
#'
#' @description Returns the link-function from a model object.
#'
#' @inheritParams find_predictors
#' @inheritParams find_formula
#' @inheritParams link_inverse
#'
#' @return A function, describing the link-function from a model-object.
#'    For multivariate-response models, a list of functions is returned.
#'
#' @examples
#' # example from ?stats::glm
#' counts <- c(18, 17, 15, 20, 10, 20, 25, 13, 12)
#' outcome <- gl(3, 1, 9)
#' treatment <- gl(3, 3)
#' m <- glm(counts ~ outcome + treatment, family = poisson())
#'
#' link_function(m)(0.3)
#' # same as
#' log(0.3)
#' @export
link_function <- function(x, ...) {
  UseMethod("link_function")
}


# Default method ---------------------------


#' @export
link_function.default <- function(x, ...) {
  if (inherits(x, "list") && object_has_names(x, "gam")) {
    x <- x$gam
    class(x) <- c(class(x), c("glm", "lm"))
  }
  .extract_generic_linkfun(x)
}


.extract_generic_linkfun <- function(x, default_link = NULL) {
  # general approach
  out <- .safe(stats::family(x)$linkfun)
  # if it fails, try to retrieve from model information
  if (is.null(out)) {
    # get model family, consider special gam-case
    ff <- .gam_family(x)
    if ("linkfun" %in% names(ff)) {
      # return link function, if exists
      out <- ff$linkfun
    } else if ("link" %in% names(ff) && is.character(ff$link)) {
      # else, create link function from link-string
      out <- .safe(stats::make.link(link = ff$link)$linkfun)
      # or match the function - for "exp()", make.link() won't work
      if (is.null(out)) {
        out <- .safe(match.fun(ff$link))
      }
    }
  }
  # if all fails, force default link
  if (is.null(out) && !is.null(default_link)) {
    out <- switch(default_link,
      identity = .safe(stats::gaussian(link = "identity")$linkfun),
      .safe(stats::make.link(link = default_link)$linkfun)
    )
  }
  out
}


# Gaussian family ------------------------------------------

#' @export
link_function.lm <- function(x, ...) {
  .extract_generic_linkfun(x, "identity")
}

#' @export
link_function.asym <- link_function.lm

#' @export
link_function.phylolm <- link_function.lm

#' @export
link_function.lme <- link_function.lm

#' @export
link_function.mmrm <- link_function.lm

#' @export
link_function.mmrm_fit <- link_function.lm

#' @export
link_function.mmrm_tmb <- link_function.lm

#' @export
link_function.systemfit <- link_function.lm

#' @export
link_function.lqmm <- link_function.lm

#' @export
link_function.lqm <- link_function.lm

#' @export
link_function.bayesx <- link_function.lm

#' @export
link_function.mixed <- link_function.lm

#' @export
link_function.truncreg <- link_function.lm

#' @export
link_function.censReg <- link_function.lm

#' @export
link_function.gls <- link_function.lm

#' @export
link_function.rq <- link_function.lm

#' @export
link_function.rqs <- link_function.lm

#' @export
link_function.rqss <- link_function.lm

#' @export
link_function.crq <- link_function.lm

#' @export
link_function.crqs <- link_function.lm

#' @export
link_function.lmRob <- link_function.lm

#' @export
link_function.complmRob <- link_function.lm

#' @export
link_function.speedlm <- link_function.lm

#' @export
link_function.biglm <- link_function.lm

#' @export
link_function.lmrob <- link_function.lm

#' @export
link_function.lm_robust <- link_function.lm

#' @export
link_function.iv_robust <- link_function.lm

#' @export
link_function.aovlist <- link_function.lm

#' @export
link_function.felm <- link_function.lm

#' @export
link_function.feis <- link_function.lm

#' @export
link_function.ivreg <- link_function.lm

#' @export
link_function.ivFixed <- link_function.lm

#' @export
link_function.plm <- link_function.lm

#' @export
link_function.MANOVA <- link_function.lm

#' @export
link_function.RM <- link_function.lm

#' @export
link_function.afex_aov <- link_function.lm

#' @export
link_function.svy2lme <- link_function.lm


# General family ---------------------------------

#' @export
link_function.glm <- link_function.default

#' @export
link_function.speedglm <- link_function.default

#' @export
link_function.bigglm <- link_function.default

#' @export
link_function.brglm <- link_function.default

#' @export
link_function.cgam <- link_function.default

#' @export
link_function.nestedLogit <- function(x, ...) {
  stats::make.link(link = "logit")$linkfun
}


# Logit link ------------------------

#' @export
link_function.multinom <- function(x, ...) {
  .extract_generic_linkfun(x, "logit")
}

#' @export
link_function.logitr <- link_function.multinom

#' @export
link_function.BBreg <- link_function.multinom

#' @export
link_function.BBmm <- link_function.multinom

#' @export
link_function.gmnl <- link_function.multinom

#' @export
link_function.logistf <- link_function.multinom

#' @export
link_function.flac <- link_function.multinom

#' @export
link_function.flic <- link_function.multinom

#' @export
link_function.lrm <- link_function.multinom

#' @export
link_function.orm <- link_function.multinom

#' @export
link_function.cph <- link_function.multinom

#' @export
link_function.mlogit <- link_function.multinom

#' @export
link_function.mclogit <- link_function.multinom

#' @export
link_function.mblogit <- link_function.multinom

#' @export
link_function.mmclogit <- link_function.multinom

#' @export
link_function.coxph <- link_function.multinom

#' @export
link_function.coxr <- link_function.multinom

#' @export
link_function.survfit <- link_function.multinom

#' @export
link_function.coxme <- link_function.multinom

#' @export
link_function.riskRegression <- link_function.multinom

#' @export
link_function.comprisk <- link_function.multinom

#' @export
link_function.multinom_weightit <- function(x, ...) {
  stats::make.link(link = x$family$link)$linkfun
}

#' @export
link_function.ordinal_weightit <- link_function.multinom_weightit


# Phylo glm ------------------------

#' @export
link_inverse.phyloglm <- function(x, ...) {
  if (startsWith(x$method, "logistic")) {
    stats::make.link("logit")$linkfun
  } else {
    stats::poisson(link = "log")$linkfun
  }
}


# Probit link ------------------------

#' @export
link_function.ivprobit <- function(x, ...) {
  stats::make.link(link = "probit")$linkfun
}


# Log links ------------------------


#' @export
link_function.zeroinfl <- function(x, ...) {
  stats::make.link("log")$linkfun
}

#' @export
link_function.hurdle <- link_function.zeroinfl

#' @export
link_function.zerotrunc <- link_function.zeroinfl


# Tobit links ---------------------------------

#' @export
link_function.tobit <- function(x, ...) {
  .make_tobit_family(x)$linkfun
}

#' @export
link_function.crch <- link_function.tobit

#' @export
link_function.survreg <- link_function.tobit

#' @export
link_function.psm <- link_function.tobit

#' @export
link_function.flexsurvreg <- function(x, ...) {
  distribution <- parse(text = safe_deparse(x$call))[[1]]$dist
  .make_tobit_family(x, distribution)$linkfun
}


# Ordinal and cumulative links --------------------------


#' @export
link_function.mvord <- function(x, ...) {
  link_name <- x$rho$link$name
  l <- stats::make.link(link = ifelse(link_name == "mvprobit", "probit", "logit"))
  l$linkfun
}


#' @export
link_function.clm <- function(x, ...) {
  stats::make.link(link = .get_ordinal_link(x))$linkfun
}

#' @export
link_function.clm2 <- link_function.clm

#' @export
link_function.clmm <- link_function.clm

#' @export
link_function.serp <- link_function.clm

#' @export
link_function.mixor <- link_function.clm


# mfx models ------------------------------------------------------


#' @rdname link_function
#' @export
link_function.betamfx <- function(x, what = c("mean", "precision"), ...) {
  what <- match.arg(what)
  link_function.betareg(x$fit, what = what, ...)
}

#' @export
link_function.betaor <- link_function.betamfx

#' @export
link_function.logitmfx <- function(x, ...) {
  link_function(x$fit, ...)
}

#' @export
link_function.poissonmfx <- link_function.logitmfx

#' @export
link_function.negbinmfx <- link_function.logitmfx

#' @export
link_function.probitmfx <- link_function.logitmfx

#' @export
link_function.negbinirr <- link_function.logitmfx

#' @export
link_function.poissonirr <- link_function.logitmfx

#' @export
link_function.logitor <- link_function.logitmfx

#' @export
link_function.model_fit <- link_function.logitmfx


# Other models -----------------------------


#' @export
link_function.Rchoice <- function(x, ...) {
  stats::make.link(link = x$link)$linkfun
}


#' @export
link_function.sdmTMB <- function(x, ...) {
  f <- get_family(x)
  stats::make.link(link = f$link)$linkfun
}


#' @export
link_function.oohbchoice <- function(x, ...) {
  link <- switch(x$distribution,
    normal = "identity",
    weibull = ,
    "log-normal" = "log",
    logistic = ,
    ## TODO: not sure about log-logistic link-inverse
    "log-logistic" = "logit"
  )
  stats::make.link(link = link)$linkfun
}


#' @export
link_function.merModList <- function(x, ...) {
  link_function.default(x[[1]], ...)
}


#' @export
link_function.mipo <- function(x, ...) {
  models <- eval(x$call$object)
  link_function(models$analyses[[1]])
}


#' @export
link_function.mira <- function(x, ...) {
  check_if_installed("mice")
  link_function(mice::pool(x), ...)
}


#' @export
link_function.averaging <- function(x, ...) {
  ml <- attributes(x)$modelList
  if (is.null(ml)) {
    format_warning("Can't retrieve data. Please use `fit = TRUE` in `model.avg()`.")
    return(NULL)
  }
  link_function(ml[[1]])
}


#' @export
link_function.robmixglm <- function(x, ...) {
  switch(tolower(x$family),
    gaussian = stats::make.link(link = "identity")$linkfun,
    binomial = stats::make.link(link = "logit")$linkfun,
    gamma = stats::make.link(link = "inverse")$linkfun,
    poisson = ,
    truncpoisson = stats::make.link(link = "log")$linkfun,
    stats::make.link(link = "identity")$linkfun
  )
}


#' @export
link_function.MCMCglmm <- function(x, ...) {
  switch(x$Residual$original.family,
    cengaussian = ,
    gaussian = stats::gaussian(link = "identity")$linkfun,
    categorical = ,
    multinomial = ,
    zibinomial = ,
    ordinal = stats::make.link("logit")$linkfun,
    poisson = ,
    cenpoisson = ,
    zipoisson = ,
    zapoisson = ,
    ztpoisson = ,
    hupoisson = stats::make.link("log")$linkfun
  )
}


#' @export
link_function.cglm <- function(x, ...) {
  link <- parse(text = safe_deparse(x$call))[[1]]$link
  method <- parse(text = safe_deparse(x$call))[[1]]$method

  if (!is.null(method) && method == "clm") {
    link <- "identity"
  }
  stats::make.link(link = link)$linkfun
}


#' @export
link_function.fixest <- function(x, ...) {
  if (is.null(x$family)) {
    if (!is.null(x$method) && x$method == "feols") {
      stats::gaussian(link = "identity")$linkfun
    }
  } else if (inherits(x$family, "family")) {
    x$family$linkfun
  } else {
    link <- switch(x$family,
      poisson = ,
      negbin = "log",
      logit = "logit",
      gaussian = "identity"
    )
    stats::make.link(link)$linkfun
  }
}

#' @export
link_function.feglm <- link_function.fixest


#' @export
link_function.glmx <- function(x, ...) {
  x$family$glm$linkfun
}


#' @export
link_function.bife <- function(x, ...) {
  x$family$linkfun
}

#' @export
link_function.glmgee <- link_function.bife


#' @export
link_function.cpglmm <- function(x, ...) {
  f <- .get_cplm_family(x)
  f$linkfun
}

#' @export
link_function.cpglm <- link_function.cpglmm

#' @export
link_function.zcpglm <- link_function.cpglmm

#' @export
link_function.bcplm <- link_function.cpglmm


#' @export
link_function.gam <- function(x, ...) {
  lf <- .extract_generic_linkfun(x)
  if (is.null(lf)) {
    mi <- .gam_family(x)
    if (object_has_names(mi, "linfo")) {
      if (object_has_names(mi$linfo, "linkfun")) {
        lf <- mi$linfo$linkfun
      } else {
        lf <- mi$linfo[[1]]$linkfun
      }
    }
  }

  lf
}


#' @export
link_function.glimML <- function(x, ...) {
  stats::make.link(link = x@link)$linkfun
}


#' @export
link_function.glmmadmb <- function(x, ...) {
  x$linkfun
}


#' @export
link_function.glmm <- function(x, ...) {
  switch(tolower(x$family.glmm$family.glmm),
    bernoulli.glmm = ,
    binomial.glmm = stats::make.link("logit")$linkfun,
    poisson.glmm = stats::make.link("log")$linkfun,
    stats::gaussian(link = "identity")$linkfun
  )
}


#' @rdname link_function
#' @export
link_function.gamlss <- function(x, what = c("mu", "sigma", "nu", "tau"), ...) {
  what <- match.arg(what)
  faminfo <- get(x$family[1], asNamespace("gamlss"))()
  # exceptions
  if (faminfo$family[1] == "LOGNO") {
    function(mu) log(mu)
  } else {
    switch(what,
      mu = faminfo$mu.linkfun,
      sigma = faminfo$sigma.linkfun,
      nu = faminfo$nu.linkfun,
      tau = faminfo$tau.linkfun,
      faminfo$mu.linkfun
    )
  }
}


#' @export
link_function.gamm <- function(x, ...) {
  x <- x$gam
  class(x) <- c(class(x), c("glm", "lm"))
  NextMethod()
}


#' @export
link_function.bamlss <- function(x, ...) {
  flink <- stats::family(x)$links[1]
  .safe(
    stats::make.link(flink)$linkfun,
    print_colour("\nCould not find appropriate link-function.\n", "red")
  )
}


#' @export
link_function.LORgee <- function(x, ...) {
  if (grepl(pattern = "logit", x = x$link, fixed = TRUE)) {
    link <- "logit"
  } else if (grepl(pattern = "probit", x = x$link, fixed = TRUE)) {
    link <- "probit"
  } else if (grepl(pattern = "cauchit", x = x$link, fixed = TRUE)) {
    link <- "cauchit"
  } else if (grepl(pattern = "cloglog", x = x$link, fixed = TRUE)) {
    link <- "cloglog"
  } else {
    link <- "logit"
  }

  stats::make.link(link)$linkfun
}


#' @export
link_function.vgam <- function(x, ...) {
  x@family@linkfun
}


#' @export
link_function.vglm <- function(x, ...) {
  x@family@linkfun
}


#' @export
link_function.svy_vglm <- function(x, ...) {
  link_function(x$fit)
}


#' @export
link_function.polr <- function(x, ...) {
  link <- switch(x$method,
    logistic = "logit",
    probit = "probit",
    "log"
  )

  stats::make.link(link)$linkfun
}


#' @export
link_function.svyolr <- function(x, ...) {
  link <- switch(x$method,
    logistic = "logit",
    probit = "probit",
    "log"
  )

  stats::make.link(link)$linkfun
}


#' @rdname link_function
#' @export
link_function.betareg <- function(x, what = c("mean", "precision"), ...) {
  what <- match.arg(what)
  switch(what,
    mean = x$link$mean$linkfun,
    precision = x$link$precision$linkfun
  )
}


#' @rdname link_function
#' @export
link_function.DirichletRegModel <- function(x, what = c("mean", "precision"), ...) {
  what <- match.arg(what)
  if (x$parametrization == "common") {
    stats::make.link("logit")$linkfun
  } else {
    switch(what,
      mean = stats::make.link("logit")$linkfun,
      precision = stats::make.link("log")$linkfun
    )
  }
}


#' @export
link_function.gbm <- function(x, ...) {
  switch(x$distribution$name,
    laplace = ,
    tdist = ,
    gaussian = stats::gaussian(link = "identity")$linkfun,
    poisson = stats::poisson(link = "log")$linkfun,
    huberized = ,
    adaboost = ,
    coxph = ,
    bernoulli = stats::make.link("logit")$linkfun
  )
}


#' @export
link_function.stanmvreg <- function(x, ...) {
  fam <- stats::family(x)
  lapply(fam, function(.x) .x$linkfun)
}


#' @export
link_function.brmsfit <- function(x, ...) {
  fam <- stats::family(x)
  if (is_multivariate(x)) {
    lapply(fam, .brms_link_fun)
  } else {
    .brms_link_fun(fam)
  }
}


# helper -----------------------


.brms_link_fun <- function(fam) {
  # do we have custom families?
  if (!is.null(fam$family) && (is.character(fam$family) && fam$family == "custom")) {
    il <- stats::make.link(fam$link)$linkfun
  } else if ("linkfun" %in% names(fam)) {
    il <- fam$linkfun
  } else if ("link" %in% names(fam) && is.character(fam$link)) {
    il <- stats::make.link(fam$link)$linkfun
  } else {
    ff <- get(fam$family, asNamespace("stats"))
    il <- ff(fam$link)$linkfun
  }
  il
}
