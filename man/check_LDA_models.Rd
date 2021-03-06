% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TS_on_LDA.R
\name{check_LDA_models}
\alias{check_LDA_models}
\title{Check that LDA model input is proper}
\usage{
check_LDA_models(LDA_models)
}
\arguments{
\item{LDA_models}{List of LDA models or singular LDA model to evaluate.}
}
\description{
Check that the \code{LDA_models} input is either a set of 
  LDA models (class \code{LDA_set}, produced by
  \code{\link{LDA_set}}) or a singular LDA model (class \code{LDA},
  produced by \code{\link[topicmodels]{LDA}}).
}
