#' @title Fit a multinomial change point Time Series model
#'
#' @description Fit a set of multinomial regression models (via
#'   \code{\link[nnet]{multinom}}, Venables and Ripley 2002) to a time series
#'   of data divided into multiple segments (a.k.a. chunks) based on given 
#'   locations for a set of change points. 
#'
#' @param data \code{data.frame} including [1] the time variable (indicated 
#'   in \code{control$timename}), [2] the predictor variables (required by
#'   \code{formula}) and [3], the multinomial response variable (indicated in
#'   \code{formula}) as verified by \code{\link{check_timename}} and 
#'   \code{\link{check_formula}}. Note that the response variables should be
#'   formatted as a \code{data.frame} object named as indicated by the 
#'   \code{response} entry in the \code{control} list, such as \code{gamma} 
#'   for a standard TS analysis on LDA output. See \code{Examples}.
#'
#' @param formula \code{\link[stats]{formula}} defining the regression between
#'   relationship the change points. Any 
#'   predictor variable included must also be a column in 
#'   \code{data} and any (multinomial) response variable must be a set of
#'   columns in \code{data}, as verified by \code{\link{check_formula}}.
#'
#' @param changepoints Numeric vector indicating locations of the change 
#'   points. Must be conformable to \code{integer} values. Validity 
#'   checked by \code{\link{check_changepoints}} and
#'   \code{\link{verify_changepoint_locations}}.
#'
#' @param weights Optional class \code{numeric} vector of weights for each 
#'   document. Defaults to \code{NULL}, translating to an equal weight for
#'   each document. When using \code{multinom_TS} in a standard LDATS 
#'   analysis, it is advisable to weight the documents by their total size,
#'   as the result of \code{\link[topicmodels]{LDA}} is a matrix of 
#'   proportions, which does not account for size differences among documents.
#'   For most models, a scaling of the weights (so that the average is 1) is
#'   most appropriate, and this is accomplished using 
#'   \code{\link{document_weights}}.
#'
#' @param control Class \code{TS_controls} list, holding control parameters
#'   for the Time Series model including the parallel tempering Markov Chain 
#'   Monte Carlo (ptMCMC) controls, generated by 
#'   \code{\link{TS_controls_list}}.
#'
#' @return Object of class \code{multinom_TS_fit}, which is a list of [1]
#'   chunk-level model fits (\code{"chunk models"}), [2] the total log 
#'   likelihood combined across all chunks (\code{"logLik"}), and [3] a 
#'   \code{data.frame} of chunk beginning and ending times (\code{"logLik"}
#'   with columns \code{"start"} and \code{"end"}).
#'
#' @references
#'   Venables, W. N. and B. D. Ripley. 2002. \emph{Modern and Applied
#'   Statistics with S}. Fourth Edition. Springer, New York, NY, USA.
#'
#' @examples 
#' \dontrun{
#'   data(rodents)
#'   dtt <- rodents$document_term_table
#'   lda <- LDA_set(dtt, 4, 1, LDA_controls_list(quiet = TRUE))
#'   dct <- rodents$document_covariate_table
#'   dct$gamma <- lda[[1]]@gamma
#'   weights <- document_weights(dtt)
#'   mts <- multinom_TS(dct, formula = gamma ~ 1, changepoints = c(20,50),
#'                      weights = weights) 
#' }
#'
#' @export 
#'
multinom_TS <- function(data, formula, changepoints = NULL, 
                        weights = NULL, control = TS_controls_list()){

  check_multinom_TS_inputs(data, formula, changepoints, weights, control)
  if (!verify_changepoint_locations(data, changepoints, control$timename)){
    out <- list("chunk models" = NA, "logLik" = -Inf, "chunks" = NA)
    class(out) <- c("multinom_TS_fit", "list")
    return(out)
  }

  TS_chunk_memo <- memoise_fun(multinom_TS_chunk, control$memoise)

  chunks <- prep_chunks(data, changepoints, control$timename)
  nchunks <- nrow(chunks)
  fits <- vector("list", length = nchunks)
  for (i in 1:nchunks){
    fits[[i]] <- TS_chunk_memo(data, formula, chunks[i, ], weights, control)
  }
  package_chunk_fits(chunks, fits)
}

#' @rdname multinom_TS
#'
#' @description \code{check_multinom_TS_inputs} checks that the inputs to 
#'   \code{multinom_TS} are of proper classes for an analysis.
#' 
#' @export
#'
check_multinom_TS_inputs <- function(data, formula, changepoints = NULL, 
                                     weights = NULL, 
                                     control = TS_controls_list()){
  check_changepoints(changepoints)
  check_weights(weights)
  check_formula(data, formula)
  check_timename(data, control$timename)
  check_control(control, "TS_controls")
}

#' @title Check that a set of change point locations is proper
#' 
#' @description Check that the change point locations are \code{numeric}
#'   and conformable to \code{interger} values. 
#'   
#' @param changepoints Change point locations to evaluate.
#' 
#' @export
#'
check_changepoints <- function(changepoints = NULL){
  if (is.null(changepoints)){
    return()
  }
  if (!is.numeric(changepoints) || any(changepoints %% 1 != 0)){
    stop("changepoints must be integer-valued")
  }
}

#' @title Log likelihood of a multinomial TS model
#' 
#' @description Convenience function to simply extract the \code{logLik}
#'   element (and \code{df} and \code{nobs}) from a \code{multinom_TS_fit}
#'   object fit by \code{\link{multinom_TS}}. Extends 
#'   \code{\link[stats]{logLik}} from \code{\link[nnet]{multinom}} to 
#'   \code{multinom_TS_fit} objects.
#'
#' @param object A \code{multinom_TS_fit}-class object.
#'
#' @param ... Not used, simply included to maintain method compatability.
#'
#' @return Log likelihood of the model, as class \code{logLik}, with 
#'   attributes \code{df} (degrees of freedom) and \code{nobs} (the number of
#'   weighted observations, accounting for size differences among documents). 
#'
#' @export
#'
logLik.multinom_TS_fit <- function(object, ...){
  ll <- object$logLik
  df <- NA
  nobs <- NA
  if (object$logLik != -Inf){
    nchunks <- nrow(object$chunks)
    dfperchunk <- length(coef(object$"chunk models"[[1]]))
    df <- nchunks - 1 + dfperchunk * nchunks
    nobs <- 0
    for(i in 1:nchunks){
      nobs <- nobs + sum(object$"chunk models"[[i]]$weights)
    }
  }
  structure(ll, df = df, nobs = nobs, class = "logLik")  
}

#' @title Package the output of the chunk-level multinomial models into a
#'   multinom_TS_fit list
#'    
#' @description Takes the list of fitted chunk-level models returned from
#'   \code{TS_chunk_memo} (the memoised version of 
#'   \code{\link{multinom_TS_chunk}} and packages it as a 
#'   \code{multinom_TS_fit} object. This involves naming the model fits based 
#'   on the chunk time windows, combining the log likelihood values across the 
#'   chunks, and setting the class of the output object. 
#'
#' @param chunks Data frame of \code{start} and \code{end} times for each 
#'   chunk (row).
#'
#' @param fits List of chunk-level fits returned by \code{TS_chunk_memo},
#'   the memoised version of \code{\link{multinom_TS_chunk}}.
#'
#' @return Object of class \code{multinom_TS_fit}, which is a list of [1]
#'   chunk-level model fits, [2] the total log likelihood combined across 
#'   all chunks, and [3] the chunk time data table.
#'
#' @export 
#'
package_chunk_fits <- function(chunks, fits){
  nchunks <- nrow(chunks)
  chunk_times <- paste0("(", chunks[ , "start"], " - ", chunks[ , "end"], ")")
  names(fits) <- paste("chunk", 1:nchunks, chunk_times, "model")
  ll <- sum(sapply(fits, logLik))
  out <- list("chunk models" = fits, "logLik" = ll, "chunks" = chunks)
  class(out) <- c("multinom_TS_fit", "list")
  out
}

#' @title Prepare the time chunk table for a multinomial change point 
#'   Time Series model
#'
#' @description Creates the table containing the start and end times for each
#'   chunk within a time series, based on the change points (used to break up
#'   the time series) and the range of the time series. If there are no 
#'   change points (i.e. \code{changepoints} is \code{NULL}, there is still a
#'   single chunk defined by the start and end of the time series.
#'
#' @param data Class \code{data.frame} object including the predictor and 
#'   response variables, but specifically here containing the column indicated
#'   by the \code{timename} input. 
#'
#' @param changepoints Numeric vector indicating locations of the change 
#'   points. Must be conformable to \code{integer} values. 
#'
#' @param timename The name of the column containing the time variable used 
#'   to chunk out the time series. Generally contained in the \code{control}
#'   (class \code{TS_controls}) list.
#'
#' @return Data frame of \code{start} and \code{end} times for each chunk 
#'   (row).
#'
#' @export 
#'
prep_chunks <- function(data, changepoints = NULL, 
                        timename = TS_controls_list()$timename){
  start <- c(min(data[ , timename]), changepoints + 1)   
  end <- c(changepoints, max(data[ , timename])) 
  data.frame(start, end)
}

#' @title Verify the change points of a multinomial time series model
#'
#' @description Verify that a time series can be broken into a set 
#'   of chunks based on input change points. 
#'
#' @param data Class \code{data.frame} object including the predictor and 
#'   response variables.
#'
#' @param changepoints Numeric vector indicating locations of the change 
#'   points. Must be conformable to \code{integer} values. 
#'
#' @param timename \code{character} name of the column in the 
#'   \code{document_covariate_table} that contains the time index to use
#'   for assignment of the change points. 
#'
#' @return Logical indicator of the check passing \code{TRUE} or failing
#'   \code{FALSE}.
#'
#' @export 
#'
verify_changepoint_locations <- function(data, changepoints = NULL, 
                                     timename = TS_controls_list()$timename){

  if (is.null(changepoints)){
    return(TRUE)
  }

  first_time <- min(data[ , timename])
  last_time <- max(data[ , timename])
  time_check <- any(changepoints <= first_time | changepoints >= last_time)
  sort_check <- is.unsorted(changepoints, strictly = TRUE)

  !(time_check | sort_check)
}

#' @title Fit a multinomial Time Series model chunk
#'
#' @description Fit a multinomial regression model (via
#'   \code{\link[nnet]{multinom}}, Ripley 1996, Venables and Ripley 2002)
#'   to a defined chunk of time (a.k.a. segment)
#'   \code{[chunk$start, chunk$end]} within a time series.
#'
#' @param data Class \code{data.frame} object including the predictor and 
#'   response variables.
#'
#' @param formula Formula as a \code{\link[stats]{formula}} or 
#'   \code{\link[base]{character}} object describing the chunk.
#'
#' @param chunk Length-2 vector of times: [1] \code{start}, the start time 
#'   for the chunk and [2] \code{end}, the end time for the chunk.
#'
#' @param weights Optional class \code{numeric} vector of weights for each 
#'   document. Defaults to \code{NULL}, translating to an equal weight for
#'   each document. When using \code{multinom_TS} in a standard LDATS 
#'   analysis, it is advisable to weight the documents by their total size,
#'   as the result of \code{\link[topicmodels]{LDA}} is a matrix of 
#'   proportions, which does not account for size differences among documents.
#'   For most models, a scaling of the weights (so that the average is 1) is
#'   most appropriate, and this is accomplished using \code{document_weights}.
#'
#' @param control Class \code{TS_controls} list, holding control parameters
#'   for the Time Series model, generated by \code{\link{TS_controls_list}}.
#' 
#' @return Fitted model object for the chunk, of classes \code{multinom} and
#'   \code{nnet}.
#' 
#' @references 
#'   Ripley, B. D. 1996. Pattern Recognition and Neural Networks. Cambridge.
#'
#'   Venables, W. N. and B. D. Ripley. 2002. Modern Applied Statistics with S.
#'   Fourth edition. Springer. 
#'
#' @examples 
#' \dontrun{
#'   data(rodents)
#'   dtt <- rodents$document_term_table
#'   lda <- LDA_set(dtt, 4, 1, LDA_controls_list(quiet = TRUE))
#'   dct <- rodents$document_covariate_table
#'   dct$gamma <- lda[[1]]@gamma
#'   weights <- document_weights(dtt)
#'   chunk <- c(start = 0, end = 100)
#'   mtsc <- multinom_TS_chunk(dct, formula = gamma ~ 1, chunk = chunk,
#'                      weights = weights) 
#' }
#'
#' @export 
#'
multinom_TS_chunk <- function(data, formula, chunk, weights = NULL,
                              control = TS_controls_list()){

  formula <- as.formula(format(formula))
  time_obs <- data[ , control$timename] 
  chunk_start <- as.numeric(chunk["start"])
  chunk_end <- as.numeric(chunk["end"])
  in_chunk <- time_obs >= chunk_start & time_obs <= chunk_end
  fit <- multinom(formula, data, weights, subset = in_chunk, trace = FALSE,
                  decay = control$lambda)
  fit$timevals <- time_obs[which(in_chunk)]
  fit 
}
