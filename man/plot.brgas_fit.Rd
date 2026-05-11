\name{plot.brgas_fit}
\alias{plot.brgas_fit}
\title{Plot a Fitted BR-GAS-t Model}
\description{
Plots returns and the fitted conditional scale from a \code{brgas_fit} object.
}
\usage{
\method{plot}{brgas_fit}(
  x,
  dates = NULL,
  returns = NULL,
  break_date = NULL,
  return_col = "#5C677D",
  scale_col = "#0B6E4F",
  break_col = "firebrick",
  ...
)
}
\arguments{
  \item{x}{A fitted \code{brgas_fit} object.}
  \item{dates}{Optional date or index vector.}
  \item{returns}{Optional return vector.}
  \item{break_date}{Optional vertical reference line location.}
  \item{return_col}{Color for the return panel.}
  \item{scale_col}{Color for the scale panel.}
  \item{break_col}{Color for the break reference line.}
  \item{...}{Additional graphical arguments.}
}
\value{
The fitted object, invisibly.
}
\examples{
sample_df <- sample_data()
fit <- fit_brgast(sample_df$ret, sample_df$post_break)
plot(fit, dates = sample_df$date)
}
