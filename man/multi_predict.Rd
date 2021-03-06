% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/C5_rules.R, R/cubist.R, R/rule_fit.R
\name{multi_predict._c5_rules}
\alias{multi_predict._c5_rules}
\alias{multi_predict._cubist}
\alias{multi_predict._xrf}
\title{\code{multi_predict()} methods for rule-based models}
\usage{
\method{multi_predict}{`_c5_rules`}(object, new_data, type = NULL, trees = NULL, ...)

\method{multi_predict}{`_cubist`}(object, new_data, type = NULL, neighbors = NULL, ...)

\method{multi_predict}{`_xrf`}(object, new_data, type = NULL, penalty = NULL, ...)
}
\arguments{
\item{object}{An object of class \code{model_fit}}

\item{new_data}{A rectangular data object, such as a data frame.}

\item{type}{A single character value or \code{NULL}. Possible values
are class" and "prob".}

\item{trees}{An numeric vector of \code{trees} between one and 100.}

\item{...}{Not currently used.}

\item{neighbors}{An numeric vector of neighbors values between zero and nine.}

\item{penalty}{Non-negative penalty values.}
}
\value{
A tibble with one row for each row of \code{new_data}. Multiple
predictions are contained in a list column called \code{.pred}. That column has
the standard \code{parsnip} prediction column names as well as the column with
the tuning parameter values.
}
\description{
\code{multi_predict()} methods for rule-based models
}
\details{
For C5.0 rule-based models, the model fit may contain less boosting
iterations than the number requested. Printing the object will show how many
were used due to early stopping. This can be change using an option in
\code{\link[C50:C5.0Control]{C50::C5.0Control()}}. Beware that the number of iterations requested
}
