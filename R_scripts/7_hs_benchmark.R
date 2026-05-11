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

hbea <- brgast::sample_data()

win <- 250
tau <- c(0.10, 0.05, 0.025, 0.01)
oos_idx <- seq.int(win + 1L, nrow(hbea))
rows <- vector("list", length(oos_idx) * length(tau))
row_id <- 1L

for (idx in oos_idx) {
  train <- hbea$ret[(idx - win):(idx - 1L)]
  for (p in tau) {
    var_p <- as.numeric(stats::quantile(train, probs = p, type = 7, names = FALSE))
    es_p <- mean(train[train <= var_p])
    rows[[row_id]] <- data.frame(
      date = hbea$date[idx],
      model = "HS",
      tau = p,
      realized = hbea$ret[idx],
      var = var_p,
      es = es_p,
      stringsAsFactors = FALSE
    )
    row_id <- row_id + 1L
  }
}

hs_forecasts <- do.call(rbind, rows)

write.csv(hs_forecasts, file.path(folder_path, "hs_benchmark_forecasts.csv"), row.names = FALSE)

print(head(hs_forecasts))
