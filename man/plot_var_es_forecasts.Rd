\name{plot_var_es_forecasts}
\alias{plot_var_es_forecasts}
\title{Plot VaR Forecast Paths}
\description{
Plots realized returns together with one or more VaR forecast paths.
}
\usage{
plot_var_es_forecasts(
  forecasts,
  tau,
  model_order = NULL,
  palette = NULL,
  realized_col = "#3A3A3A",
  breach_col = "#C1121F",
  ...
)
}
\arguments{
  \item{forecasts}{A forecast table containing dates, model names, realized returns, and VaR forecasts.}
  \item{tau}{The tail probability to plot.}
  \item{model_order}{Optional plotting order for model names.}
  \item{palette}{Optional vector of line colors.}
  \item{realized_col}{Color used for realized returns.}
  \item{breach_col}{Color used for VaR breach markers.}
  \item{...}{Additional graphical arguments.}
}
\value{
The plotted subset of the forecast table, invisibly.
}
\examples{
sample_df <- sample_data()
roll_out <- roll_brgast(sample_df, win = 250, refit_every = 60, tau = c(0.05, 0.01))
plot_var_es_forecasts(roll_out$forecasts, tau = 0.05)
}
