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

if (!file.exists(fit_path)) {
  source(file.path(script_dir, "2_fit_brgast_model.R"))
}

fit <- readRDS(fit_path)

var_es <- forecast_var_es(fit, tau = c(0.10, 0.05, 0.025, 0.01))

write.csv(var_es, file.path(folder_path, "brgast_var_es_forecasts.csv"), row.names = FALSE)

print(var_es)
