% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/TS_plots.R
\name{TS_summary_plot}
\alias{TS_summary_plot}
\title{Create the summary plot for a TS fit to an LDA model}
\usage{
TS_summary_plot(x, cols = set_TS_summary_plot_cols(), bin_width, xlab,
  selection = "median", LDATS = FALSE)
}
\arguments{
\item{x}{Object of class \code{TS_fit} produced by \code{\link{TS}}.}

\item{cols}{\code{list} of elements used to define the colors for the two
panels, as generated simply using \code{\link{set_TS_summary_plot_cols}}. 
Has two elements \code{rho} and \code{gamma}, each corresponding to the
related panel, and each containing default values for entries named
\code{cols}, \code{option}, and \code{alpha}. See
\code{\link{set_gamma_colors}} and \code{\link{set_rho_hist_colors}} for
details on usage.}

\item{bin_width}{Width of the bins used in the histograms, in units of the
x-axis (the time variable used to fit the model).}

\item{xlab}{Label for the x-axis (time).}

\item{selection}{Indicator of the change points to use. Currently only
defined for "median" and "mode".}

\item{LDATS}{\code{logical} indicating if the plot is part of a larger 
LDATS plot output.}
}
\description{
Produces a two-panel figure of [1] the change point 
  distributions as histograms over time and [2] the time series of the 
  fitted topic proportions over time, based on a selected set of 
  change point locations.
}
