#' Statusbar that estimates the remaining time based on the user-registered work progress.
#'
#' This is an R port of a Fortran module that was used in the astrophysical codes SPEV and MRGENESIS.
#'
#' @section Initialization:
#' An R6 object is initalized sing \code{estatusbar$new()} with a no arguments. It should be called by the user when the task starts.
#'
#' @section Adding new entries:
#' As the task progresses, the user can call the function \code{add} to register the fraction of the task that has been completed. The routine \code{add} has only one argument, the fraction (between 0 and 1) that is complete at current time.
#'
#' @section Displaying the status bar:
#' At any point the user can call the \code{display} function to draw the status bar in terminal. This function accepts the following arguments:
#' width = 40, text = NULL, perc = TRUE, eta = TRUE, digits=0
#' \describe{
#' \item{width}{The width of the progress bar. The default values is 40 characters}
#' \item{text}{A custom text string that can be shown next to the progress bar. By default no text is displayed.}
#' \item{perc}{Percentage display flag, by default set to TRUE. This controls whether the percentage of progress should be printed.}
#' \item{eta}{Estimated completion time display flag, by default set to TRUE. This controls whether the ETA should be printed.}
#' \item{digits}{Total number of digits to be used when printing seconds, by default set to 0. This allows the user to show fractions of a second.}
#' }
#'
#' @export
#'
#' @examples
#'
#' What follows is the typical usage case. The status bar is registered, and then 20 entries are added. Before each add the system sleeps for a random time interval (between 0 and 2 seconds). Afterward an entry is registered and the display is updated.
#'
#' est <- estatusbar$new()
#' for (i in 1:20) {
#'    Sys.sleep(2 * runif(1))
#'    est$add(i / 20)
#'    est$display()
#' }
#'
#' @name estatusbar

estatusbar <-
    R6::R6Class("estatusbar",

            public = list (

                initialize = function() {
                    estatusbar.zero(self, private)
                },
                add = function(fraction) {
                    # hard coded number of algorithms
                    num.algs <- 4

                    # get current time
                    cur <- as.numeric(lubridate::now())

                    # get current number of entries
                    num.entries <- length(private$fracs)

                    # if there have been enough entries, compute predictions
                    if (num.entries > 1) {
                        # add predictions to the array
                        new.pred <- array(data = 0, c(num.algs, 1))
                        new.pred[1, 1] <- estatusbar.linear.window(private, fraction, 5)
                        new.pred[2, 1] <- estatusbar.first.last(private, fraction, 1e0)
                        new.pred[3, 1] <- estatusbar.first.last(private, fraction, 2e0)
                        new.pred[4, 1] <- estatusbar.linear(private, fraction)

                        private$predicted <- cbind(private$predicted, new.pred)

                        # compute the sum of square difference for each algorithm
                        private$sqdiff <- sapply(1:num.algs, function(i) {
                            1e0 / max(c(sum((private$measured[1:num.entries] - private$predicted[i, 1:num.entries])^2), 1e-10))
                        })

                        # compute the final predictions
                        final.pred <- array(data = 0, c(num.algs))
                        final.pred[1] <- estatusbar.linear.window(private, 1e0, 5)
                        final.pred[2] <- estatusbar.first.last(private, 1e0, 1e0)
                        final.pred[3] <- estatusbar.first.last(private, 1e0, 2e0)
                        final.pred[4] <- estatusbar.linear(private, 1e0)

                        # compute the average prediction, using sqdiff as weights
                        private$prediction <- sum(private$sqdiff * final.pred) / sum(private$sqdiff)

                    }

                    # add new entry
                    private$measured <- c(private$measured, cur - private$start)
                    private$fracs <- c(private$fracs, fraction)
                    private$expired <- cur - private$start

                    # initialize predicted array with the first measurement
                    if (num.entries < 2) {
                        private$predicted <- cbind(private$predicted, array(data=private$measured[num.entries + 1], c(num.algs, 1)))
                    }
                },
                predict = function() {
                    Sys.setenv(TZ="Europe/Madrid")
                    return(as.POSIXct(private$prediction + private$start, origin=lubridate::origin))
                },
                display = function(width = 40, text = NULL, perc = TRUE, eta = TRUE, digits=0) {
                    # Set the digits for fractions of a second
                    options(digits.secs=digits)

                    # Compute the fraction of work done so far.
                    done.frac <- tail(private$fracs, n=1)

                    # First, we go to the beginning of the current line
                    cat("\r")

                    # Compute the width of the staus bar and erase the current line
                    tot.width <- width + 2 # bar width including borders
                    if (!is.null(text)) {
                        tot.width <- tot.width + nchar(text) + 1 # one space at the beginning
                    }

                    # If the estimated time of completion is to be shown, compute it and add its width.
                    if (eta) {
                        pred <- paste0(" ETA: ", self$predict(), collapse="")
                        tot.width <- tot.width + nchar(pred)
                    }

                    # If the percentage is to be shown, compute its string and add width.
                    if (perc) {
                        perc.string <- paste0(" (", formatC(width=2, flag="0", floor(done.frac * 100)), "%)")
                        tot.width <- tot.width + nchar(perc.string)
                    }

                    # Multiply tot.width by 10 percent for safety
                    tot.width <- floor(tot.width * 1.1)

                    spaces <- paste0(rep(" ", tot.width), collapse="")
                    cat(spaces)
                    cat("\r")

                    # Compute the status bar

                    # Define symbols
                    bar.border <- "|"
                    bar.right <- ">"
                    bar.complete <- "="
                    bar.remaining <- " "

                    # Compute the length of each part
                    len.complete <- floor(width * done.frac)
                    len.remaining <- width - len.complete


                    # Generate the bar
                    if (len.complete > 1) {
                        complete.string <- paste0(rep(bar.complete, len.complete - 1), collapse="")
                    } else {
                        complete.string <- ""
                    }
                    if (len.remaining > 0) {
                        remaining.string <- paste0(rep(bar.remaining, len.remaining), collapse="")
                    } else {
                        remaining.string <- ""
                    }
                    bar.string <- paste0(bar.border, complete.string, bar.right, remaining.string, bar.border, collapse="")


                    # Print the final result
                    cat(bar.string)

                    if (!is.null(text)) {
                        cat(paste0(" ", text))
                    }

                    if (perc) {
                        cat(perc.string)
                    }

                    if (eta) {
                        cat(pred)
                    }
                }

            ),

            private = list (
                fracs = 0e0, # fraction of work done vector
                sqdiff = array(data = 0, c(4, 1)), # square of prediction differences
                measured = 0e0, # measured time
                predicted = array(data = 0, c(4, 1)), # predicted time of completion
                start = 0e0, # timer
                expired = 0e0, # expired time
                prediction = 0e0 # final prediction
            )

    )

# This function initializes an estimator to the current time
estatusbar.zero <- function(self, private) {
    private$start = as.numeric(lubridate::now()) # timer start
    self
}


# This estimator uses last "win" entries to predict the next one. It performs a linear fit.
estatusbar.linear.window <- function(private, frac, win) {

    num.entries <- length(private$fracs)
    realwin <- min(c(win, num.entries)) # the real window may be smaller than win

    # create a data frame to perform linear regression
    df <- data.frame(fracs = private$fracs[(num.entries - realwin):(num.entries)], times = private$measured[(num.entries - realwin):(num.entries)])

    # linear regression
    fit <- lm(times ~ fracs, data = df)

    # create a data frame for predicting
    pdf <- data.frame(fracs = c(frac))

    # predict the time at frac
    pdf$times <- predict(fit, pdf)

    return(pdf$times[1])
}

# This estimator performs a full linear fit
estatusbar.linear<- function(private, frac) {

    # create a data frame to perform a linear regression (logarithmic)
    df <- data.frame(fracs = private$fracs, times = private$measured)

    # linear regression
    fit <- lm(times ~ fracs, data = df)

    # create a data frame for predicting
    pdf <- data.frame(fracs = c(frac))

    # predict the time at frac
    pdf$times <- predict(fit, pdf)

    return(pdf$times[1])
}

# This simple estimator takes the last known entry and assumes that the time increases as a power of fraction:
# time(frac) = tot * frac^expo
#
# where tot is the total time estimated by substituting the data for the last entry into the previous equation:
# tot = time(last) / frac(last)^expo
estatusbar.first.last <- function(private, frac, expo, smallf = 1e-10) {
    num.entries <- length(private$fracs)

    # Estimate the total time (use a small value to avoid division by zero)
    tot <- private$expired / max(c(smallf, private$fracs[num.entries]))^expo

    # Return the prediction for frac
    return(tot * frac^expo)
}