% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_model.R
\name{get_model}
\alias{get_model}
\title{Get a model objects that is saved as attribute}
\usage{
get_model(x, name = "model", element = NULL, ...)
}
\arguments{
\item{x}{An object that contains a model object as an attribute. This could be
a data frame or any other object that has an attribute containing the model.}

\item{name}{The name of the attribute that contains the model object. Defaults
to \code{"model"}.}

\item{element}{String or character vector. If provided, this argument allows
you to specify which element(s) of the model object to return. This can be
useful if the model object is a list or has multiple components, and you only
want to extract a specific part.}

\item{...}{Not used.}
}
\value{
The object that is stored as an attribute of \code{x} with the name \code{name},
or the specific element of that object if \code{element} is provided. If the
attribute or element does not exist, an error is raised.
}
\description{
This functions tries to get a model object from the object \code{x},
where the model object is saved as an (arbitrarily named) attribute. This is
useful for example, when a model is fitted and saved as an attribute of a
data frame.
}
\examples{
# Example of using get_model
d <- data.frame(x = rnorm(100), y = rnorm(100))
# fit a model and save it as an attribute
model <- lm(y ~ x, data = d)
attr(d, "model") <- model
# get the model back
get_model(d)
# get the coefficients of the model
get_model(d, element = "coefficients")

}
