library(brgast)

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1])))
} else {
  getwd()
}

folder_path <- file.path(script_dir, "tables_figures")
fit_path <- file.path(folder_path, "brgast_fit.rds")
rolling_path <- file.path(folder_path, "brgast_rolling_forecasts_refit60.csv")

if (!file.exists(fit_path)) {
  source(file.path(script_dir, "2_fit_brgast_model.R"))
}

if (!file.exists(rolling_path)) {
  source(file.path(script_dir, "4_roll_brgast_forecasts.R"))
}

hbea <- sample_data()

fit <- readRDS(fit_path)
rolling_forecasts <- read.csv(rolling_path, stringsAsFactors = FALSE)
rolling_forecasts$date <- as.Date(rolling_forecasts$date)

png(file.path(folder_path, "brgast_fitted_scale.png"), width = 1200, height = 600, res = 150)
plot(fit, dates = hbea$date)
dev.off()

png(file.path(folder_path, "brgast_var_forecasts_tau005.png"), width = 1200, height = 600, res = 150)
plot_var_es_forecasts(rolling_forecasts, tau = 0.05)
dev.off()
