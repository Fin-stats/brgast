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

fit <- fit_brgast(
  y = hbea$ret,
  indicator = hbea$post_break
)

coefs <- unlist(fit$coefficients[c("mu", "omega", "a", "a1", "b", "b1", "d1", "nu")])
parameter_table <- data.frame(term = names(coefs), estimate = unname(coefs))

saveRDS(fit, file.path(folder_path, "brgast_fit.rds"))
write.csv(parameter_table, file.path(folder_path, "brgast_parameter_table.csv"), row.names = FALSE)

print(fit)
print(parameter_table)
