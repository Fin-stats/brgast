\name{filter_brgast}
\alias{filter_brgast}
\title{Filter Latent States in the BR-GAS-t Model}
\description{
Applies the BR-GAS-t recursion to a return series and returns the filtered
log-scale path and related quantities.
}
\usage{
filter_brgast(y, indicator, params, return_path = TRUE)
}
\arguments{
  \item{y}{A numeric return series.}
  \item{indicator}{A 0/1 break indicator with the same length as \code{y}.}
  \item{params}{A list of BR-GAS-t parameters.}
  \item{return_path}{Logical; if \code{TRUE}, return full filtered paths.}
}
\value{
A list with log-likelihood, states, and optionally the filtered scale, score,
and log-likelihood paths.
}

