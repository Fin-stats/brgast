library(brgast)

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1])))
} else {
  getwd()
}

hbea <- sample_data()

stopifnot(is.data.frame(hbea))
stopifnot(all(c("date", "ret", "post_break") %in% names(hbea)))
stopifnot(all(is.finite(hbea$ret)))
stopifnot(all(hbea$post_break %in% c(0L, 1L)))

fit <- fit_brgast(
  y = hbea$ret,
  indicator = hbea$post_break,
  control = list(maxit = 50)
)

stopifnot(inherits(fit, "brgas_fit"))

var_es <- forecast_var_es(fit, tau = c(0.05, 0.01))
stopifnot(all(c("tau", "var", "es") %in% names(var_es)))

print("All tests passed.")
