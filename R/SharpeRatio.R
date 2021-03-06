#' calculate a traditional or modified Sharpe Ratio of Return over StdDev or
#' VaR or ES
#' 
#' The Sharpe ratio is simply the return per unit of risk (represented by
#' variability).  In the classic case, the unit of risk is the standard
#' deviation of the returns.
#' 
#' \deqn{\frac{\overline{(R_{a}-R_{f})}}{\sqrt{\sigma_{(R_{a}-R_{f})}}}}
#' 
#' William Sharpe now recommends \code{\link{InformationRatio}} preferentially
#' to the original Sharpe Ratio.
#' 
#' The higher the Sharpe ratio, the better the combined performance of "risk"
#' and return.
#' 
#' As noted, the traditional Sharpe Ratio is a risk-adjusted measure of return
#' that uses standard deviation to represent risk.
#' 
#' A number of papers now recommend using a "modified Sharpe" ratio using a
#' Modified Cornish-Fisher VaR or CVaR/Expected Shortfall as the measure of
#' Risk.
#' 
#' We have recently extended this concept to create multivariate modified
#' Sharpe-like Ratios for standard deviation, Gaussian VaR, modified VaR,
#' Gaussian Expected Shortfall, and modified Expected Shortfall. See
#' \code{\link{VaR}} and \code{\link{ES}}.  You can pass additional arguments
#' to \code{\link{VaR}} and \code{\link{ES}} via \dots{} The most important is
#' probably the 'method' argument/
#' 
#' This function returns a traditional or modified Sharpe ratio for the same
#' periodicity of the data being input (e.g., monthly data -> monthly SR)
#' 
#' 
#' @aliases SharpeRatio.modified SharpeRatio
#' @param R an xts, vector, matrix, data frame, timeSeries or zoo object of
#' asset returns
#' @param Rf risk free rate, in same period as your returns
#' @param p confidence level for calculation, default p=.95
#' @param FUN one of "StdDev" or "VaR" or "ES" to use as the denominator
#' @param weights portfolio weighting vector, default NULL, see Details in
#' \code{\link{VaR}}
#' @param annualize if TRUE, annualize the measure, default FALSE
#' @param \dots any other passthru parameters to the VaR or ES functions
#' @author Brian G. Peterson
#' @seealso \code{\link{SharpeRatio.annualized}} \cr
#' \code{\link{InformationRatio}} \cr \code{\link{TrackingError}} \cr
#' \code{\link{ActivePremium}} \cr \code{\link{SortinoRatio}} \cr
#' \code{\link{VaR}} \cr \code{\link{ES}} \cr
#' @references Sharpe, W.F. The Sharpe Ratio,\emph{Journal of Portfolio
#' Management},Fall 1994, 49-58.
#' 
#' Laurent Favre and Jose-Antonio Galeano. Mean-Modified Value-at-Risk
#' Optimization with Hedge Funds. Journal of Alternative Investment, Fall 2002,
#' v 5.
###keywords ts multivariate distribution models
#' @examples
#' 
#' data(managers)
#' SharpeRatio(managers[,1,drop=FALSE], Rf=.035/12, FUN="StdDev") 
#' SharpeRatio(managers[,1,drop=FALSE], Rf = managers[,10,drop=FALSE], FUN="StdDev")
#' SharpeRatio(managers[,1:6], Rf=.035/12, FUN="StdDev") 
#' SharpeRatio(managers[,1:6], Rf = managers[,10,drop=FALSE], FUN="StdDev")
#' 
#' 
#' 
#' data(edhec)
#' SharpeRatio(edhec[, 6, drop = FALSE], FUN="VaR")
#' SharpeRatio(edhec[, 6, drop = FALSE], Rf = .04/12, FUN="VaR")
#' SharpeRatio(edhec[, 6, drop = FALSE], Rf = .04/12, FUN="VaR" , method="gaussian")
#' SharpeRatio(edhec[, 6, drop = FALSE], FUN="ES")
#' 
#' # and all the methods
#' SharpeRatio(managers[,1:9], Rf = managers[,10,drop=FALSE])
#' SharpeRatio(edhec,Rf = .04/12)
#' 
#' @export
#' @rdname SharpeRatio
SharpeRatio <-
function (R, Rf = 0, p = 0.95, FUN=c("StdDev", "VaR","ES"), weights=NULL, annualize = FALSE , ...)
{ # @author Brian G. Peterson

    # DESCRIPTION:
    # The Sharpe ratio is simply the return per unit of risk (represented by
    # variability).  The higher the Sharpe ratio, the better the combined
    # performance of "risk" and return.

    # The Sharpe Ratio is a risk-adjusted measure of return that uses
    # standard deviation to represent risk.

    # A number of papers now recommend using a "modified Sharpe" ratio
    # using a Modified Cornish-Fisher VaR as the measure of Risk.

    # Inputs:
    # R: in this case, the function anticipates having a return stream as input,
    #    rather than prices.
    #
    # Rf: the risk free rate MUST be in the same periodicity as the data going in.
    #
    # p: probability at which to calculate the modified risk measure (defaults to 95%)

    # Outputs:
    # This function returns a (modified) Sharpe ratio for the same periodicity of the
    # data being input (e.g., monthly data -> monthly SR)

    # @TODO: annualize using multiperiod VaR and ES calcs

    # FUNCTION:

    R = checkData(R)
    
    if(!is.null(dim(Rf)))
        Rf = checkData(Rf)
        
    if(annualize){ # scale the Rf to the periodicity of the calculation
        freq = periodicity(R)
        switch(freq$scale,
            minute = {stop("Data periodicity too high")},
            hourly = {stop("Data periodicity too high")},
            daily = {scale = 252},
            weekly = {scale = 52},
            monthly = {scale = 12},
            quarterly = {scale = 4},
            yearly = {scale = 1}
        )
    } else {
        scale = 1 # won't scale the Rf, will leave it at the same periodicity
    }
    # TODO: Consolidate annualized and regular SR calcs
    srm <-function (R, ..., Rf, p, FUNC)
    {
        FUNCT <- match.fun(FUNC)
        xR = Return.excess(R, Rf)
        SRM = mean(xR, na.rm=TRUE)/FUNCT(R=R, p=p, ...=..., invert=FALSE)
        SRM
    }
    sra <-function (R, ..., Rf, p, FUNC)
    {
        if(FUNC == "StdDev") {
            risk <- StdDev.annualized(x=R, ...)
        } else {
            FUNCT <- match.fun(FUNC)
            risk <- FUNCT(R=R, p=p, ...=..., invert=FALSE)
        }
        xR = Return.excess(R, Rf)
        SRA = Return.annualized(xR)/risk
        SRA
    }
    
    i=1
    if(is.null(weights)){
        result = matrix(nrow=length(FUN), ncol=ncol(R)) 
        colnames(result) = colnames(R) 
    } 
    else {
        result = matrix(nrow=length(FUN))
    }
    
    tmprownames=vector()
    
    for (FUNCT in FUN){
        if (is.null(weights)){
            if(annualize)
                result[i,] = sapply(R, FUN=sra, Rf=Rf, p=p, FUNC=FUNCT, ...)
            else
                result[i,] = sapply(R, FUN=srm, Rf=Rf, p=p, FUNC=FUNCT, ...)
        }
        else { # TODO FIX this calculation, currently broken
            result[i,] = mean(R%*%weights,na.rm=TRUE)/match.fun(FUNCT)(R, Rf=Rf, p=p, weights=weights, portfolio_method="single", ...=...)
        }
        tmprownames = c(tmprownames, paste(if(annualize) "Annualized ", FUNCT, " Sharpe", " (Rf=", round(scale*mean(Rf)*100,1), "%, p=", round(p*100,1),"%):", sep=""))
        i=i+1 #increment counter
    }
    rownames(result)=tmprownames
    return (result)
}

#' @export
#' @rdname SharpeRatio
SharpeRatio.modified <-
function (R, Rf = 0, p = 0.95, FUN=c("StdDev", "VaR","ES"), weights=NULL, ...) {
    .Deprecated("SharpeRatio", package="PerformanceAnalytics", "The SharpeRatio.modified function has been deprecated in favor of a newer SharpeRatio wrapper that will cover both the classic case and a larger suite of modified Sharpe Ratios.  This deprecated function may be removed from future versions")

    return(SharpeRatio(R = R, Rf = Rf, p = p, FUN = FUN, weights=weights, ...))
}

###############################################################################
# R (http://r-project.org/) Econometrics for Performance and Risk Analysis
#
# Copyright (c) 2004-2015 Peter Carl and Brian G. Peterson
#
# This R package is distributed under the terms of the GNU Public License (GPL)
# for full details see the file COPYING
#
# $Id$
#
###############################################################################
