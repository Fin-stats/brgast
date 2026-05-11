\name{sample_data}
\alias{sample_data}
\title{Load the Bundled Sample Dataset}
\description{
Loads a bundled synthetic 10-year return series designed to illustrate package
usage.
}
\usage{
sample_data()
}
\value{
A data frame with columns \code{date}, \code{ret}, and \code{post_break}.
}
\examples{
sample_df <- sample_data()
head(sample_df)
}
