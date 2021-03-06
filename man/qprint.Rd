% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities.R
\name{qprint}
\alias{qprint}
\title{Print with quieting}
\usage{
qprint(msg, wrapper, quiet)
}
\arguments{
\item{msg}{Message to be printed. \code{character}-class element.}

\item{wrapper}{Wrapper \code{character} to use.}

\item{quiet}{\code{logical} indicator of whether the message should be 
printed.}
}
\description{
Print a message (via \code{\link{cat}}) wrapped as in 
  \code{<wrapper><msg><wrapper>}, if desired.
}
