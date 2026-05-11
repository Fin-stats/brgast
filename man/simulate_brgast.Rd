\name{simulate_brgast}
\alias{simulate_brgast}
\title{Simulate Data from a Break-Regime GAS-t Process}
\description{
Generates a synthetic return series from a break-regime GAS-t process.
}
\usage{
simulate_brgast(
  n = 600,
  break_at = floor(n * 0.6),
  seed = NULL,
  params = list(mu = 0, omega = -0.12, a = 0.08, a1 = 0.04, b = 0.88,
    b1 = -0.08, d1 = 0.15, nu = 8),
  start_date = as.Date("2021-01-01")
)
}
\arguments{
  \item{n}{Number of observations to simulate.}
  \item{break_at}{Observation index at which the break indicator switches to 1.}
  \item{seed}{Optional random seed.}
  \item{params}{A named list of BR-GAS-t parameters.}
  \item{start_date}{Starting date for the generated series.}
}
\value{
A data frame with \code{date}, \code{ret}, and \code{post_break}.
}
