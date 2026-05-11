args <- commandArgs(trailingOnly = FALSE)
file_arg <- "--file="
script_path <- sub(file_arg, "", args[grep(file_arg, args)])
pkg_root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/")
setwd(pkg_root)

.libPaths(c(normalizePath(file.path(pkg_root, "..", ".Rlib"), winslash = "/"), .libPaths()))

library(brgast)

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)

sample_df <- sample_data()
fit <- fit_brgast(sample_df$ret, sample_df$post_break)
roll_out <- roll_brgast(
  data = sample_df,
  win = 250,
  refit_every = 60,
  tau = c(0.05, 0.01)
)

grDevices::png(
  filename = "man/figures/fit_scale.png",
  width = 1400,
  height = 720,
  res = 150
)
plot(fit, dates = sample_df$date)
grDevices::dev.off()

grDevices::png(
  filename = "man/figures/var_forecast.png",
  width = 1400,
  height = 720,
  res = 150
)
plot_var_es_forecasts(roll_out$forecasts, tau = 0.05)
grDevices::dev.off()
