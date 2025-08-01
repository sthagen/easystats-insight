% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_predicted.R, R/get_predicted_bayesian.R,
%   R/get_predicted_gam.R, R/get_predicted_mixed.R, R/get_predicted_other.R
\name{get_predicted}
\alias{get_predicted}
\alias{get_predicted.default}
\alias{get_predicted.lm}
\alias{get_predicted.stanreg}
\alias{get_predicted.gam}
\alias{get_predicted.lmerMod}
\alias{get_predicted.principal}
\title{Model predictions (robust) and their confidence intervals}
\usage{
get_predicted(x, ...)

\method{get_predicted}{default}(
  x,
  data = NULL,
  predict = "expectation",
  ci = NULL,
  ci_type = "confidence",
  ci_method = NULL,
  dispersion_method = "sd",
  vcov = NULL,
  vcov_args = NULL,
  verbose = TRUE,
  ...
)

\method{get_predicted}{lm}(
  x,
  data = NULL,
  predict = "expectation",
  ci = NULL,
  iterations = NULL,
  verbose = TRUE,
  ...
)

\method{get_predicted}{stanreg}(
  x,
  data = NULL,
  predict = "expectation",
  iterations = NULL,
  ci = NULL,
  ci_method = NULL,
  include_random = "default",
  include_smooth = TRUE,
  verbose = TRUE,
  ...
)

\method{get_predicted}{gam}(
  x,
  data = NULL,
  predict = "expectation",
  ci = NULL,
  include_random = TRUE,
  include_smooth = TRUE,
  iterations = NULL,
  verbose = TRUE,
  ...
)

\method{get_predicted}{lmerMod}(
  x,
  data = NULL,
  predict = "expectation",
  ci = NULL,
  ci_method = NULL,
  include_random = "default",
  iterations = NULL,
  verbose = TRUE,
  ...
)

\method{get_predicted}{principal}(x, data = NULL, ...)
}
\arguments{
\item{x}{A statistical model (can also be a data.frame, in which case the
second argument has to be a model).}

\item{...}{Other argument to be passed, for instance to the model's \code{predict()}
method, or \code{get_predicted_ci()}.}

\item{data}{An optional data frame in which to look for variables with which
to predict. If omitted, the data used to fit the model is used. Visualization
matrices can be generated using \code{\link[=get_datagrid]{get_datagrid()}}.}

\item{predict}{string or \code{NULL}
\itemize{
\item \code{"link"} returns predictions on the model's link-scale (for logistic models,
that means the log-odds scale) with a confidence interval (CI). This option
should also be used for finite mixture models (currently only family
\code{\link[brms:mixture]{brms::mixture()}} from package \emph{brms}), when predicted values of the
response for each class is required.
\item \code{"expectation"} (default) also returns confidence intervals, but this time
the output is on the response scale (for logistic models, that means
probabilities).
\item \code{"prediction"} also gives an output on the response scale, but this time
associated with a prediction interval (PI), which is larger than a confidence
interval (though it mostly make sense for linear models).
\item \code{"classification"} is relevant only for binomial, ordinal or mixture models.
\itemize{
\item For binomial models, \code{predict = "classification"} will additionally
transform the predictions into the original response's type (for
instance, to a factor).
\item For ordinal models (e.g., classes \code{clm} or \code{multinom}), gives the
predicted response class membership, defined as highest probability
prediction.
\item For finite mixture models (currently only family \code{\link[brms:mixture]{brms::mixture()}} from
package \emph{brms}) also returns the predicted response class membership
(similar as for ordinal models).
}
\item Other strings are passed directly to the \code{type} argument of the \code{predict()}
method supplied by the modelling package.
\item Specifically for models of class \code{brmsfit} (package \emph{brms}), the \code{predict}
argument can be any valid option for the \code{dpar} argument, to predict
distributional parameters (such as \code{"sigma"}, \code{"beta"}, \code{"kappa"}, \code{"phi"}
and so on, see \code{?brms::brmsfamily}).
\item When \code{predict = NULL}, alternative arguments such as \code{type} will be captured
by the \code{...} ellipsis and passed directly to the \code{predict()} method supplied
by the modelling package. Note that this might result in conflicts with
multiple matching \code{type} arguments - thus, the recommendation is to use the
\code{predict} argument for those values.
\item Notes: You can see the four options for predictions as on a gradient from
"close to the model" to "close to the response data": "link", "expectation",
"prediction", "classification". The \code{predict} argument modulates two things:
the scale of the output and the type of certainty interval. Read more about
in the \strong{Details} section below.
}}

\item{ci}{The interval level. Default is \code{NULL}, to be fast even for larger
models. Set the interval level to an explicit value, e.g. \code{0.95}, for \verb{95\%}
CI).}

\item{ci_type}{Can be \code{"prediction"} or \code{"confidence"}. Prediction intervals
show the range that likely contains the value of a new observation (in what
range it would fall), whereas confidence intervals reflect the uncertainty
around the estimated parameters (and gives the range of the link; for
instance of the regression line in a linear regressions). Prediction
intervals account for both the uncertainty in the model's parameters, plus
the random variation of the individual values. Thus, prediction intervals
are always wider than confidence intervals. Moreover, prediction intervals
will not necessarily become narrower as the sample size increases (as they
do not reflect only the quality of the fit). This applies mostly for
"simple" linear models (like \code{lm}), as for other models (e.g., \code{glm}),
prediction intervals are somewhat useless (for instance, for a binomial
model for which the dependent variable is a vector of 1s and 0s, the
prediction interval is... \verb{[0, 1]}).}

\item{ci_method}{The method for computing p values and confidence intervals.
Possible values depend on model type.
\itemize{
\item \code{NULL} uses the default method, which varies based on the model type.
\item Most frequentist models: \code{"wald"} (default), \code{"residual"} or \code{"normal"}.
\item Bayesian models:  \code{"quantile"}  (default), \code{"hdi"}, \code{"eti"}, and \code{"spi"}.
\item Mixed effects \strong{lme4} models: \code{"wald"} (default), \code{"residual"},
\code{"normal"}, \code{"satterthwaite"}, and \code{"kenward-roger"}.
}

See \code{\link[=get_df]{get_df()}} for details.}

\item{dispersion_method}{Bootstrap dispersion and Bayesian posterior summary:
\code{"sd"} or \code{"mad"}.}

\item{vcov}{Variance-covariance matrix used to compute uncertainty estimates
(e.g., for robust standard errors). This argument accepts a covariance
matrix, a function which returns a covariance matrix, or a string which
identifies the function to be used to compute the covariance matrix.
\itemize{
\item A covariance matrix
\item A function which returns a covariance matrix (e.g., \code{stats::vcov()})
\item A string which indicates the kind of uncertainty estimates to return.
\itemize{
\item Heteroskedasticity-consistent: \code{"HC"}, \code{"HC0"}, \code{"HC1"}, \code{"HC2"},
\code{"HC3"}, \code{"HC4"}, \code{"HC4m"}, \code{"HC5"}. See \code{?sandwich::vcovHC}
\item Cluster-robust: \code{"CR"}, \code{"CR0"}, \code{"CR1"}, \code{"CR1p"}, \code{"CR1S"}, \code{"CR2"},
\code{"CR3"}. See \code{?clubSandwich::vcovCR}
\item Bootstrap: \code{"BS"}, \code{"xy"}, \code{"residual"}, \code{"wild"}, \code{"mammen"},
\code{"fractional"}, \code{"jackknife"}, \code{"norm"}, \code{"webb"}. See
\code{?sandwich::vcovBS}
\item Other \code{sandwich} package functions: \code{"HAC"}, \code{"PC"}, \code{"CL"}, \code{"OPG"},
\code{"PL"}.
\item Kenward-Roger approximation: \code{kenward-roger}. See \code{?pbkrtest::vcovAdj}.
}
}

One exception are models of class \code{glmgee}, which have pre-defined options
for the variance-covariance matrix calculation. These are \code{"robust"},
\code{"df-adjusted"}, \code{"model"}, \code{"bias-corrected"}, and \code{"jackknife"}. See
\code{?glmtoolbox::vcov.glmgee} for details.}

\item{vcov_args}{List of arguments to be passed to the function identified by
the \code{vcov} argument. This function is typically supplied by the
\strong{sandwich} or \strong{clubSandwich} packages. Please refer to their
documentation (e.g., \code{?sandwich::vcovHAC}) to see the list of available
arguments. If no estimation type (argument \code{type}) is given, the default
type for \code{"HC"} equals the default from the \strong{sandwich} package; for type
\code{"CR"}, the default is set to \code{"CR3"}.}

\item{verbose}{Toggle warnings.}

\item{iterations}{For Bayesian models, this corresponds to the number of
posterior draws. If \code{NULL}, will return all the draws (one for each
iteration of the model). For frequentist models, if not \code{NULL}, will
generate bootstrapped draws, from which bootstrapped CIs will be computed.
Iterations can be accessed by running \code{as.data.frame(..., keep_iterations = TRUE)}
on the output.}

\item{include_random}{If \code{"default"}, include all random effects in the
prediction, unless random effect variables are not in the data.  If \code{TRUE},
include all random effects in the prediction (in this case, it will be
checked if actually all random effect variables are in \code{data}). If \code{FALSE},
don't take them into account. Can also be a formula to specify which random
effects to condition on when predicting (passed to the \code{re.form} argument).
If \code{include_random = TRUE} and \code{data} is provided, make sure to include
the random effect variables in \code{data} as well.}

\item{include_smooth}{For General Additive Models (GAMs). If \code{FALSE}, will
fix the value of the smooth to its average, so that the predictions are not
depending on it. (default), \code{mean()}, or \code{bayestestR::map_estimate()}.}
}
\value{
The fitted values (i.e. predictions for the response). For Bayesian
or bootstrapped models (when \code{iterations != NULL}), iterations (as columns
and observations are rows) can be accessed via \code{as.data.frame()}.
}
\description{
The \code{get_predicted()} function is a robust, flexible and user-friendly
alternative to base R \code{\link[=predict]{predict()}} function. Additional features and
advantages include availability of uncertainty intervals (CI), bootstrapping,
a more intuitive API and the support of more models than base R's \code{predict()}
function. However, although the interface are simplified, it is still very
important to read the documentation of the arguments. This is because making
"predictions" (a lose term for a variety of things) is a non-trivial process,
with lots of caveats and complications. Read the 'Details' section for more
information.

\code{\link[=get_predicted_ci]{get_predicted_ci()}} returns the confidence (or prediction) interval (CI)
associated with predictions made by a model. This function can be called
separately on a vector of predicted values. \code{get_predicted()} usually
returns confidence intervals (included as attribute, and accessible via the
\code{as.data.frame()} method) by default. It is preferred to rely on the
\code{get_predicted()} function for standard errors and confidence intervals -
use \code{get_predicted_ci()} only if standard errors and confidence intervals
are not available otherwise.
}
\details{
In \code{insight::get_predicted()}, the \code{predict} argument jointly modulates two
separate concepts, the \strong{scale} and the \strong{uncertainty interval}.
}
\section{Confidence Interval (CI) vs. Prediction Interval (PI))}{

\itemize{
\item \strong{Linear models} - \code{lm()}: For linear models, prediction intervals
(\code{predict="prediction"}) show the range that likely contains the value of a
new observation (in what range it is likely to fall), whereas confidence
intervals (\code{predict="expectation"} or \code{predict="link"}) reflect the
uncertainty around the estimated parameters (and gives the range of
uncertainty of the regression line). In general, Prediction Intervals (PIs)
account for both the uncertainty in the model's parameters, plus the random
variation of the individual values. Thus, prediction intervals are always
wider than confidence intervals. Moreover, prediction intervals will not
necessarily become narrower as the sample size increases (as they do not
reflect only the quality of the fit, but also the variability within the
data).
\item \strong{Generalized Linear models} - \code{glm()}: For binomial models, prediction
intervals are somewhat useless (for instance, for a binomial (Bernoulli)
model for which the dependent variable is a vector of 1s and 0s, the
prediction interval is... \verb{[0, 1]}).
}
}

\section{Link scale vs. Response scale}{

When users set the \code{predict} argument to \code{"expectation"}, the predictions are
returned on the response scale, which is arguably the most convenient way to
understand and visualize relationships of interest. When users set the
\code{predict} argument to \code{"link"}, predictions are returned on the link scale,
and no transformation is applied. For instance, for a logistic regression
model, the response scale corresponds to the predicted probabilities, whereas
the link-scale makes predictions of log-odds (probabilities on the logit
scale). Note that when users select \code{predict = "classification"} in binomial
models, the \code{get_predicted()} function will first calculate predictions as if
the user had selected \code{predict = "expectation"}. Then, it will round the
responses in order to return the most likely outcome. For ordinal or mixture
models, it returns the predicted class membership, based on the highest
probability of classification.
}

\section{Heteroscedasticity consistent standard errors}{

The arguments \code{vcov} and \code{vcov_args} can be used to calculate robust standard
errors for confidence intervals of predictions. These arguments, when
provided in \code{get_predicted()}, are passed down to \code{get_predicted_ci()}, thus,
see the related documentation there for more details.
}

\section{Finite mixture models}{

For finite mixture models (currently, only the \code{mixture()} family from package
\emph{brms} is supported), use \code{predict = "classification"} to predict the class
membership. To predict outcome values by class, use \code{predict = "link"}. Other
\code{predict} options will return predicted values of the outcome for the full
data, not stratified by class membership.
}

\section{Bayesian and Bootstrapped models and iterations}{

For predictions based on multiple iterations, for instance in the case of
Bayesian models and bootstrapped predictions, the function used to compute
the centrality (point-estimate predictions) can be modified via the
\code{centrality_function} argument. For instance,
\code{get_predicted(model, centrality_function = stats::median)}. The default is
\code{mean}. Individual draws can be accessed by running
\code{iter <- as.data.frame(get_predicted(model))}, and their iterations can be
reshaped into a long format by \code{bayestestR::reshape_iterations(iter)}.
}

\section{Hypothesis tests}{

There is limited support for hypothesis tests, i.e. objects of class \code{htest}:
\itemize{
\item \code{chisq.test()}: returns the expected values of the contingency table.
}
}

\examples{
\dontshow{if (require("boot")) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
data(mtcars)
x <- lm(mpg ~ cyl + hp, data = mtcars)

predictions <- get_predicted(x, ci = 0.95)
predictions

# Options and methods ---------------------
get_predicted(x, predict = "prediction")

# Get CI
as.data.frame(predictions)

# Bootstrapped
as.data.frame(get_predicted(x, iterations = 4))
# Same as as.data.frame(..., keep_iterations = FALSE)
summary(get_predicted(x, iterations = 4))

# Different prediction types ------------------------
data(iris)
data <- droplevels(iris[1:100, ])

# Fit a logistic model
x <- glm(Species ~ Sepal.Length, data = data, family = "binomial")

# Expectation (default): response scale + CI
pred <- get_predicted(x, predict = "expectation", ci = 0.95)
head(as.data.frame(pred))

# Prediction: response scale + PI
pred <- get_predicted(x, predict = "prediction", ci = 0.95)
head(as.data.frame(pred))

# Link: link scale + CI
pred <- get_predicted(x, predict = "link", ci = 0.95)
head(as.data.frame(pred))

# Classification: classification "type" + PI
pred <- get_predicted(x, predict = "classification", ci = 0.95)
head(as.data.frame(pred))
\dontshow{\}) # examplesIf}
}
\seealso{
\code{\link[=get_datagrid]{get_datagrid()}}
}
