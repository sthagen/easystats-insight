#' @title Get link-inverse function from model object
#' @name link_inverse
#'
#' @description Returns the link-inverse function from a model object.
#'
#' @param what For `gamlss` models, indicates for which distribution
#'   parameter the link (inverse) function should be returned; for
#'   `betareg` or `DirichletRegModel`, can be `"mean"` or
#'   `"precision"`.
#' @inheritParams find_predictors
#' @inheritParams find_formula
#'
#' @return A function, describing the inverse-link function from a model-object.
#'    For multivariate-response models, a list of functions is returned.
#'
#' @examples
#' # example from ?stats::glm
#' counts <- c(18, 17, 15, 20, 10, 20, 25, 13, 12)
#' outcome <- gl(3, 1, 9)
#' treatment <- gl(3, 3)
#' m <- glm(counts ~ outcome + treatment, family = poisson())
#'
#' link_inverse(m)(0.3)
#' # same as
#' exp(0.3)
#' @export
link_inverse <- function(x, ...) {
  UseMethod("link_inverse")
}


# Default method ---------------------------------------


#' @export
link_inverse.default <- function(x, ...) {
  if (inherits(x, "list") && object_has_names(x, "gam")) {
    x <- x$gam
    class(x) <- c(class(x), c("glm", "lm"))
  }

  if (inherits(x, "Zelig-relogit")) {
    stats::make.link(link = "logit")$linkinv
  } else {
    .extract_generic_linkinv(x)
  }
}

.extract_generic_linkinv <- function(x, default_link = NULL) {
  # general approach
  out <- .safe(stats::family(x)$linkinv)
  # if it fails, try to retrieve from model information
  if (is.null(out)) {
    # get model family, consider special gam-case
    ff <- .gam_family(x)
    if ("linkfun" %in% names(ff)) {
      # return link function, if exists
      out <- ff$linkinv
    } else if ("link" %in% names(ff) && is.character(ff$link)) {
      # else, create link function from link-string
      out <- .safe(stats::make.link(link = ff$link)$linkinv)
      # or match the function - for "exp()", make.link() won't work
      if (is.null(out)) {
        out <- .safe(match.fun(ff$link))
      }
    }
  }
  # if all fails, force default link
  if (is.null(out) && !is.null(default_link)) {
    out <- switch(default_link,
      identity = .safe(stats::gaussian(link = "identity")$linkinv),
      .safe(stats::make.link(link = default_link)$linkinv)
    )
  }
  out
}


# GLM families ---------------------------------------------------

#' @export
link_inverse.glm <- function(x, ...) {
  .extract_generic_linkinv(x, "logit")
}

#' @export
link_inverse.speedglm <- link_inverse.glm

#' @export
link_inverse.bigglm <- link_inverse.glm

#' @export
link_inverse.nestedLogit <- function(x, ...) {
  stats::make.link(link = "logit")$linkinv
}


# Tobit Family ---------------------------------


#' @export
link_inverse.tobit <- function(x, ...) {
  .make_tobit_family(x)$linkinv
}

#' @export
link_inverse.crch <- link_inverse.tobit

#' @export
link_inverse.survreg <- link_inverse.tobit

#' @export
link_inverse.psm <- link_inverse.tobit

#' @export
link_inverse.flexsurvreg <- function(x, ...) {
  distribution <- parse(text = safe_deparse(x$call))[[1]]$dist
  .make_tobit_family(x, distribution)$linkinv
}


# Gaussian identity links ---------------------------------

#' @export
link_inverse.lm <- function(x, ...) {
  .extract_generic_linkinv(x, "identity")
}

#' @export
link_inverse.asym <- link_inverse.lm

#' @export
link_inverse.phylolm <- link_inverse.lm

#' @export
link_inverse.bayesx <- link_inverse.lm

#' @export
link_inverse.mmrm <- link_inverse.lm

#' @export
link_inverse.mmrm_fit <- link_inverse.lm

#' @export
link_inverse.mmrm_tmb <- link_inverse.lm

#' @export
link_inverse.systemfit <- link_inverse.lm

#' @export
link_inverse.lqmm <- link_inverse.lm

#' @export
link_inverse.lqm <- link_inverse.lm

#' @export
link_inverse.biglm <- link_inverse.lm

#' @export
link_inverse.aovlist <- link_inverse.lm

#' @export
link_inverse.ivreg <- link_inverse.lm

#' @export
link_inverse.ivFixed <- link_inverse.lm

#' @export
link_inverse.iv_robust <- link_inverse.lm

#' @export
link_inverse.mixed <- link_inverse.lm

#' @export
link_inverse.lme <- link_inverse.lm

#' @export
link_inverse.rq <- link_inverse.lm

#' @export
link_inverse.rqs <- link_inverse.lm

#' @export
link_inverse.rqss <- link_inverse.lm

#' @export
link_inverse.crq <- link_inverse.lm

#' @export
link_inverse.crqs <- link_inverse.lm

#' @export
link_inverse.censReg <- link_inverse.lm

#' @export
link_inverse.plm <- link_inverse.lm

#' @export
link_inverse.lm_robust <- link_inverse.lm

#' @export
link_inverse.truncreg <- link_inverse.lm

#' @export
link_inverse.felm <- link_inverse.lm

#' @export
link_inverse.feis <- link_inverse.lm

#' @export
link_inverse.gls <- link_inverse.lm

#' @export
link_inverse.lmRob <- link_inverse.lm

#' @export
link_inverse.MANOVA <- link_inverse.lm

#' @export
link_inverse.RM <- link_inverse.lm

#' @export
link_inverse.lmrob <- link_inverse.lm

#' @export
link_inverse.complmrob <- link_inverse.lm

#' @export
link_inverse.speedlm <- link_inverse.lm

#' @export
link_inverse.afex_aov <- link_inverse.lm

#' @export
link_inverse.svy2lme <- link_inverse.lm


#' @rdname link_inverse
#' @export
link_inverse.betareg <- function(x, what = c("mean", "precision"), ...) {
  what <- match.arg(what)
  switch(what,
    mean = x$link$mean$linkinv,
    precision = x$link$precision$linkinv
  )
}


#' @rdname link_inverse
#' @export
link_inverse.DirichletRegModel <- function(x, what = c("mean", "precision"), ...) {
  what <- match.arg(what)
  if (x$parametrization == "common") {
    stats::make.link("logit")$linkinv
  } else {
    switch(what,
      mean = stats::make.link("logit")$linkinv,
      precision = stats::make.link("log")$linkinv
    )
  }
}


# Logit links -----------------------------------

#' @export
link_inverse.gmnl <- function(x, ...) {
  .extract_generic_linkinv(x, "logit")
}

#' @export
link_inverse.mlogit <- link_inverse.gmnl

#' @export
link_inverse.mclogit <- link_inverse.gmnl

#' @export
link_inverse.mmclogit <- link_inverse.gmnl

#' @export
link_inverse.mblogit <- link_inverse.gmnl

#' @export
link_inverse.logitr <- link_inverse.gmnl

#' @export
link_inverse.BBreg <- link_inverse.gmnl

#' @export
link_inverse.BBmm <- link_inverse.gmnl

#' @export
link_inverse.coxph <- link_inverse.gmnl

#' @export
link_inverse.riskRegression <- link_inverse.gmnl

#' @export
link_inverse.comprisk <- link_inverse.gmnl

#' @export
link_inverse.coxr <- link_inverse.gmnl

#' @export
link_inverse.survfit <- link_inverse.gmnl

#' @export
link_inverse.coxme <- link_inverse.gmnl

#' @export
link_inverse.lrm <- link_inverse.gmnl

#' @export
link_inverse.orm <- link_inverse.gmnl

#' @export
link_inverse.cph <- link_inverse.gmnl

#' @export
link_inverse.logistf <- link_inverse.gmnl

#' @export
link_inverse.flac <- link_inverse.gmnl

#' @export
link_inverse.flic <- link_inverse.gmnl

#' @export
link_inverse.multinom <- link_inverse.gmnl

#' @export
link_inverse.multinom_weightit <- function(x, ...) {
  stats::make.link(link = x$family$link)$linkinv
}

#' @export
link_inverse.ordinal_weightit <- link_inverse.multinom_weightit


# Probit link ------------------------

#' @export
link_inverse.ivprobit <- function(x, ...) {
  stats::make.link(link = "probit")$linkinv
}


#' @export
link_inverse.mvord <- function(x, ...) {
  link_name <- x$rho$link$name
  l <- stats::make.link(link = ifelse(link_name == "mvprobit", "probit", "logit"))
  l$linkinv
}


# Log-links ---------------------------------------

#' @export
link_inverse.zeroinfl <- function(x, ...) {
  stats::make.link("log")$linkinv
}

#' @export
link_inverse.hurdle <- link_inverse.zeroinfl

#' @export
link_inverse.zerotrunc <- link_inverse.zeroinfl


# Ordinal models -----------------------------------

#' @export
link_inverse.clm <- function(x, ...) {
  stats::make.link(.get_ordinal_link(x))$linkinv
}

#' @export
link_inverse.clmm <- link_inverse.clm

#' @export
link_inverse.clm2 <- link_inverse.clm

#' @export
link_inverse.serp <- link_inverse.clm

#' @export
link_inverse.mixor <- link_inverse.clm


# mfx models ------------------------------------------------------


#' @rdname link_inverse
#' @export
link_inverse.betamfx <- function(x, what = c("mean", "precision"), ...) {
  what <- match.arg(what)
  link_inverse.betareg(x$fit, what = what, ...)
}

#' @export
link_inverse.betaor <- link_inverse.betamfx

#' @export
link_inverse.logitmfx <- function(x, ...) {
  link_inverse(x$fit, ...)
}

#' @export
link_inverse.poissonmfx <- link_inverse.logitmfx

#' @export
link_inverse.probitmfx <- link_inverse.logitmfx

#' @export
link_inverse.negbinmfx <- link_inverse.logitmfx

#' @export
link_inverse.logitor <- link_inverse.logitmfx

#' @export
link_inverse.probitirr <- link_inverse.logitmfx

#' @export
link_inverse.negbinirr <- link_inverse.logitmfx


# Other models ----------------------------

#' @export
link_inverse.Rchoice <- function(x, ...) {
  stats::make.link(link = x$link)$linkinv
}


#' @export
link_inverse.oohbchoice <- function(x, ...) {
  link <- switch(x$distribution,
    normal = "identity",
    weibull = ,
    "log-normal" = "log",
    logistic = ,
    ## TODO: not sure about log-logistic link-inverse
    "log-logistic" = "logit"
  )
  stats::make.link(link = link)$linkinv
}


#' @export
link_inverse.merModList <- function(x, ...) {
  link_inverse.default(x[[1]], ...)
}


#' @export
link_inverse.robmixglm <- function(x, ...) {
  switch(tolower(x$family),
    gaussian = stats::make.link(link = "identity")$linkinv,
    binomial = stats::make.link(link = "logit")$linkinv,
    gamma = stats::make.link(link = "inverse")$linkinv,
    poisson = ,
    truncpoisson = stats::make.link(link = "log")$linkinv,
    stats::make.link(link = "identity")$linkinv
  )
}


#' @export
link_inverse.cglm <- function(x, ...) {
  link <- parse(text = safe_deparse(x$call))[[1]]$link
  method <- parse(text = safe_deparse(x$call))[[1]]$method

  if (!is.null(method) && method == "clm") {
    link <- "identity"
  }
  stats::make.link(link = link)$linkinv
}


#' @export
link_inverse.cpglmm <- function(x, ...) {
  f <- .get_cplm_family(x)
  f$linkinv
}

#' @export
link_inverse.cpglm <- link_inverse.cpglmm

#' @export
link_inverse.zcpglm <- link_inverse.cpglmm

#' @export
link_inverse.bcplm <- link_inverse.cpglmm


#' @export
link_inverse.fixest <- function(x, ...) {
  if (is.null(x$family)) {
    if (!is.null(x$method) && x$method == "feols") {
      stats::gaussian(link = "identity")$linkinv
    }
  } else if (inherits(x$family, "family")) {
    x$family$linkinv
  } else {
    link <- switch(x$family,
      poisson = ,
      negbin = "log",
      logit = "logit",
      gaussian = "identity"
    )
    stats::make.link(link)$linkinv
  }
}

#' @export
link_inverse.feglm <- link_inverse.fixest


#' @export
link_inverse.glmx <- function(x, ...) {
  x$family$glm$linkinv
}


#' @export
link_inverse.bife <- function(x, ...) {
  x$family$linkinv
}

#' @export
link_inverse.glmgee <- link_inverse.bife


#' @export
link_inverse.glmmadmb <- function(x, ...) {
  x$ilinkfun
}


#' @export
link_inverse.polr <- function(x, ...) {
  link <- x$method
  if (link == "logistic") link <- "logit"
  stats::make.link(link)$linkinv
}


#' @export
link_inverse.svyolr <- function(x, ...) {
  link <- x$method
  if (link == "logistic") link <- "logit"
  stats::make.link(link)$linkinv
}


#' @export
link_inverse.averaging <- function(x, ...) {
  ml <- attributes(x)$modelList
  if (is.null(ml)) {
    format_warning("Can't retrieve data. Please use `fit = TRUE` in `model.avg()`.")
    return(NULL)
  }
  link_inverse(ml[[1]])
}


#' @export
link_inverse.sdmTMB <- function(x, ...) {
  f <- get_family(x)
  stats::make.link(link = f$link)$linkinv
}


#' @export
link_inverse.LORgee <- function(x, ...) {
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

  stats::make.link(link)$linkinv
}


#' @export
link_inverse.glimML <- function(x, ...) {
  stats::make.link(x@link)$linkinv
}


#' @export
link_inverse.glmmTMB <- function(x, ...) {
  ff <- stats::family(x)

  if ("linkinv" %in% names(ff)) {
    ff$linkinv
  } else if ("link" %in% names(ff) && is.character(ff$link)) {
    stats::make.link(ff$link)$linkinv
  } else {
    match.fun("exp")
  }
}


#' @export
link_inverse.MCMCglmm <- function(x, ...) {
  switch(x$Residual$original.family,
    cengaussian = ,
    gaussian = stats::gaussian(link = "identity")$linkinv,
    categorical = ,
    multinomial = ,
    zibinomial = ,
    ordinal = stats::make.link("logit")$linkinv,
    poisson = ,
    cenpoisson = ,
    zipoisson = ,
    zapoisson = ,
    ztpoisson = ,
    hupoisson = stats::make.link("log")$linkinv
  )
}


#' @export
link_inverse.glmm <- function(x, ...) {
  switch(tolower(x$family.glmm$family.glmm),
    bernoulli.glmm = ,
    binomial.glmm = stats::make.link("logit")$linkinv,
    poisson.glmm = stats::make.link("log")$linkinv,
    stats::gaussian(link = "identity")$linkinv
  )
}


#' @export
link_inverse.gamm <- function(x, ...) {
  x <- x$gam
  class(x) <- c(class(x), c("glm", "lm"))
  NextMethod()
}


#' @export
link_inverse.stanmvreg <- function(x, ...) {
  fam <- stats::family(x)
  lapply(fam, function(.x) .x$linkinv)
}


#' @export
link_inverse.gbm <- function(x, ...) {
  switch(x$distribution$name,
    laplace = ,
    tdist = ,
    gaussian = stats::gaussian(link = "identity")$linkinv,
    poisson = stats::poisson(link = "log")$linkinv,
    huberized = ,
    adaboost = ,
    coxph = ,
    bernoulli = stats::make.link("logit")$linkinv
  )
}


#' @export
link_inverse.phyloglm <- function(x, ...) {
  if (startsWith(x$method, "logistic")) {
    stats::make.link("logit")$linkinv
  } else {
    stats::poisson(link = "log")$linkinv
  }
}


#' @export
link_inverse.brmsfit <- function(x, ...) {
  fam <- stats::family(x)
  if (is_multivariate(x)) {
    lapply(fam, .brms_link_inverse)
  } else {
    .brms_link_inverse(fam)
  }
}


#' @rdname link_inverse
#' @export
link_inverse.gamlss <- function(x, what = c("mu", "sigma", "nu", "tau"), ...) {
  what <- match.arg(what)
  faminfo <- get(x$family[1], asNamespace("gamlss"))()
  # exceptions
  if (faminfo$family[1] == "LOGNO") {
    function(eta) pmax(exp(eta), .Machine$double.eps)
  } else {
    switch(what,
      mu = faminfo$mu.linkinv,
      sigma = faminfo$sigma.linkinv,
      nu = faminfo$nu.linkinv,
      tau = faminfo$tau.linkinv,
      faminfo$mu.linkinv
    )
  }
}


#' @export
link_inverse.bamlss <- function(x, ...) {
  flink <- stats::family(x)$links[1]
  tryCatch(
    stats::make.link(flink)$linkinv,
    error = function(e) {
      print_colour("\nCould not find appropriate link-inverse-function.\n", "red")
    }
  )
}


#' @export
link_inverse.glmmPQL <- function(x, ...) {
  x$family$linkinv
}

#' @export
link_inverse.MixMod <- link_inverse.glmmPQL

#' @export
link_inverse.cgam <- link_inverse.glmmPQL


#' @export
link_inverse.vgam <- function(x, ...) {
  x@family@linkinv
}

#' @export
link_inverse.vglm <- link_inverse.vgam

#' @export
link_inverse.svy_vglm <- function(x, ...) {
  link_inverse(x$fit)
}

#' @export
link_inverse.model_fit <- link_inverse.svy_vglm


#' @export
link_inverse.gam <- function(x, ...) {
  li <- .safe(.gam_family(x)$linkinv)

  if (is.null(li)) {
    mi <- .gam_family(x)
    if (object_has_names(mi, "linfo")) {
      if (object_has_names(mi$linfo, "linkinv")) {
        li <- mi$linfo$linkinv
      } else {
        li <- mi$linfo[[1]]$linkinv
      }
    }
  }

  li
}


#' @export
link_inverse.mipo <- function(x, ...) {
  models <- eval(x$call$object)
  link_inverse(models$analyses[[1]])
}


#' @export
link_inverse.mira <- function(x, ...) {
  check_if_installed("mice")
  link_inverse(mice::pool(x), ...)
}


# helper --------------

.brms_link_inverse <- function(fam) {
  # do we have custom families?
  if (!is.null(fam$family) && (is.character(fam$family) && fam$family == "custom")) {
    il <- stats::make.link(fam$link)$linkinv
  } else if ("linkinv" %in% names(fam)) {
    il <- fam$linkinv
  } else if ("link" %in% names(fam) && is.character(fam$link)) {
    il <- stats::make.link(fam$link)$linkinv
  } else {
    ff <- get(fam$family, asNamespace("stats"))
    il <- ff(fam$link)$linkinv
  }
  il
}


.get_cplm_family <- function(x) {
  link <- parse(text = safe_deparse(x@call))[[1]]$link

  if (is.null(link)) link <- "log"

  if (is.numeric(link)) {
    check_if_installed("statmod")
    statmod::tweedie(link.power = link)
  } else {
    stats::poisson(link = link)
  }
}
