\name{forecast_var_es}
\alias{forecast_var_es}
\title{Compute One-Step-Ahead VaR and ES Forecasts}
\description{
Computes one-step-ahead VaR and Expected Shortfall forecasts from a fitted
BR-GAS-t model.
}
\usage{
forecast_var_es(object, tau = c(0.1, 0.05, 0.01), state = NULL)
}
\arguments{
  \item{object}{A fitted \code{brgas_fit} object.}
  \item{tau}{A numeric vector of tail probabilities in \code{(0, 0.5)}.}
  \item{state}{Optional log-scale state. If omitted, the fitted next state is used.}
}
\value{
A data frame with columns \code{tau}, \code{var}, and \code{es}.
}
\examples{
sample_df <- sample_data()
fit <- fit_brgast(sample_df$ret, sample_df$post_break)
forecast_var_es(fit, tau = c(0.10, 0.05, 0.01))
}
