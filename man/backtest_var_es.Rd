\name{backtest_var_es}
\alias{backtest_var_es}
\title{Evaluate VaR and ES Forecasts}
\description{
Computes simple exceedance, quantile-loss, and FZ-loss summaries for forecast
tables containing realized returns, VaR forecasts, and ES forecasts.
}
\usage{
backtest_var_es(forecasts)
}
\arguments{
  \item{forecasts}{A data frame with \code{tau}, \code{realized}, \code{var}, and \code{es}.}
}
\value{
A data frame summarizing exceedance rate, actual-to-expected ratio, quantile
loss, and FZ loss by tail probability.
}

