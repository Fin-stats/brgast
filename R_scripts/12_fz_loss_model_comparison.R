args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1])))
} else {
  getwd()
}

folder_path <- file.path(script_dir, "tables_figures")
var_table_path <- file.path(folder_path, "var_backtesting_table.csv")

if (!file.exists(var_table_path)) {
  source(file.path(script_dir, "11_var_backtesting_table.R"))
}

needed <- c(
  "hs_benchmark_forecasts.csv",
  "garch_n_benchmark_forecasts.csv",
  "garch_t_benchmark_forecasts.csv",
  "gas_t_benchmark_forecasts.csv",
  "brgast_rolling_forecasts_refit60.csv"
)

fz_one <- function(df) {
  sp <- split(df, list(df$model, df$tau), drop = TRUE)
  rows <- lapply(sp, function(x) {
    hits <- as.integer(x$realized <= x$var)
    tau_i <- unique(x$tau)
    data.frame(
      model = unique(x$model),
      tau = tau_i,
      fz_loss = mean((1 / (x$es^2)) * (x$es - x$var + ((x$var - x$realized) * hits) / tau_i)),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

all_forecasts <- do.call(rbind, lapply(file.path(folder_path, needed), read.csv, stringsAsFactors = FALSE))
all_forecasts$model[all_forecasts$model == "br-gas-t"] <- "BR-GAS-t"

fz_by_tau <- fz_one(all_forecasts)
fz_by_tau <- fz_by_tau[order(fz_by_tau$tau, fz_by_tau$model), ]

fz_average <- aggregate(fz_loss ~ model, data = fz_by_tau, FUN = mean)
fz_average$rank <- rank(fz_average$fz_loss, ties.method = "first")
fz_average <- fz_average[order(fz_average$rank), ]

write.csv(fz_by_tau, file.path(folder_path, "fz_loss_by_tau.csv"), row.names = FALSE)
write.csv(fz_average, file.path(folder_path, "fz_loss_model_ranking.csv"), row.names = FALSE)

print(fz_by_tau)
print(fz_average)
