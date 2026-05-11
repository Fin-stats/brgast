sample_data <- function() {
  path <- system.file("extdata", "hbea_sample.csv", package = "brgast")
  if (path == "") {
    stop("Bundled sample data not found.", call. = FALSE)
  }
  out <- utils::read.csv(path, stringsAsFactors = FALSE)
  out$date <- as.Date(out$date)
  out$post_break <- as.integer(out$post_break)
  out
}
