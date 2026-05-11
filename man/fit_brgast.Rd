\name{fit_brgast}
\alias{fit_brgast}
\alias{coef.brgas_fit}
\alias{print.brgas_fit}
\alias{summary.brgas_fit}
\alias{print.summary_brgas_fit}
\title{Fit a Break-Regime GAS-t Model}
\description{
Fits the BR-GAS-t model by maximum likelihood and provides basic S3 methods
for printing, summarizing, and extracting coefficients.
}
\usage{
fit_brgast(y, indicator, start = NULL, control = list(maxit = 1500))

\method{coef}{brgas_fit}(object, ...)

\method{print}{brgas_fit}(x, ...)

\method{summary}{brgas_fit}(object, ...)

\method{print}{summary_brgas_fit}(x, ...)
}
\arguments{
  \item{y}{A numeric return series.}
  \item{indicator}{A 0/1 break-regime indicator with the same length as \code{y}.}
  \item{start}{Optional starting values on the unconstrained optimization scale.}
  \item{control}{A list of control parameters passed to the optimizer.}
  \item{object}{A fitted \code{"brgas_fit"} object.}
  \item{x}{An object to print.}
  \item{...}{Additional arguments passed to S3 methods.}
}
\value{
An object of class \code{"brgas_fit"} containing coefficients, fit statistics,
filtered states, and the original inputs.
}
\examples{
sample_df <- sample_data()
fit <- fit_brgast(sample_df$ret, sample_df$post_break)
print(fit)
}
