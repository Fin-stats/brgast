\name{roll_brgast}
\alias{roll_brgast}
\title{Run Rolling BR-GAS-t Forecasts}
\description{
Fits the BR-GAS-t model on a moving window and generates one-step-ahead VaR and
ES forecasts through time.
}
\usage{
roll_brgast(
  data,
  win = 250,
  refit_every = 20,
  tau = c(0.1, 0.05, 0.01),
  warm_start = TRUE,
  fit_control = list(maxit = 600),
  ret_col = "ret",
  indicator_col = "post_break",
  date_col = "date"
)
}
\arguments{
  \item{data}{A data frame containing returns and a break indicator.}
  \item{win}{Rolling window length.}
  \item{refit_every}{Number of observations between parameter re-estimation steps.}
  \item{tau}{A numeric vector of tail probabilities.}
  \item{warm_start}{Logical; if \code{TRUE}, reuse the previous fit as the next optimizer starting point.}
  \item{fit_control}{A list of optimizer control settings used in each re-estimation step.}
  \item{ret_col}{Name of the return column.}
  \item{indicator_col}{Name of the 0/1 break indicator column.}
  \item{date_col}{Optional date column name.}
}
\value{
A list with \code{forecasts} and \code{evaluation}.
}
\examples{
sample_df <- sample_data()
roll_out <- roll_brgast(sample_df, win = 250, refit_every = 60, tau = c(0.05, 0.01))
head(roll_out$forecasts)
}
