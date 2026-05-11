library(brgast)

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1])))
} else {
  getwd()
}

folder_path <- file.path(script_dir, "tables_figures")

if (!dir.exists(folder_path)) {
  dir.create(folder_path, recursive = TRUE)
}

hbea <- sample_data()

roll_refit60 <- roll_brgast(
  data = hbea,
  win = 250,
  refit_every = 60,
  tau = c(0.10, 0.05, 0.025, 0.01)
)

write.csv(roll_refit60$forecasts, file.path(folder_path, "brgast_rolling_forecasts_refit60.csv"), row.names = FALSE)
write.csv(roll_refit60$evaluation, file.path(folder_path, "brgast_rolling_evaluation_refit60.csv"), row.names = FALSE)

print(head(roll_refit60$forecasts))
print(roll_refit60$evaluation)
