% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/multinom_TS.R
\name{prep_chunks}
\alias{prep_chunks}
\title{Prepare the time chunk table for a multinomial change point 
  Time Series model}
\usage{
prep_chunks(data, changepoints = NULL,
  timename = TS_controls_list()$timename)
}
\arguments{
\item{data}{Class \code{data.frame} object including the predictor and 
response variables, but specifically here containing the column indicated
by the \code{timename} input.}

\item{changepoints}{Numeric vector indicating locations of the change 
points. Must be conformable to \code{integer} values.}

\item{timename}{The name of the column containing the time variable used 
to chunk out the time series. Generally contained in the \code{control}
(class \code{TS_controls}) list.}
}
\value{
Data frame of \code{start} and \code{end} times for each chunk 
  (row).
}
\description{
Creates the table containing the start and end times for each
  chunk within a time series, based on the change points (used to break up
  the time series) and the range of the time series. If there are no 
  change points (i.e. \code{changepoints} is \code{NULL}, there is still a
  single chunk defined by the start and end of the time series.
}
