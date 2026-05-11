args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_dir <- if (length(file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1])))
} else {
  getwd()
}

folder_path <- file.path(script_dir, "tables_figures")

needed <- c(
  "hs_benchmark_forecasts.csv",
  "garch_n_benchmark_forecasts.csv",
  "garch_t_benchmark_forecasts.csv",
  "gas_t_benchmark_forecasts.csv",
  "brgast_rolling_forecasts_refit60.csv"
)

scripts <- c(
  "7_hs_benchmark.R",
  "8_garch_n_benchmark.R",
  "9_garch_t_benchmark.R",
  "10_gas_t_benchmark.R",
  "4_roll_brgast_forecasts.R"
)

for (i in seq_along(needed)) {
  if (!file.exists(file.path(folder_path, needed[i]))) {
    source(file.path(script_dir, scripts[i]))
  }
}

safe_loglik_binom <- function(x, n, p) {
  p <- min(max(p, 1e-8), 1 - 1e-8)
  x * log(p) + (n - x) * log(1 - p)
}

lruc_pvalue <- function(hits, tau) {
  n <- length(hits)
  x <- sum(hits)
  phat <- min(max(x / n, 1e-8), 1 - 1e-8)
  lr <- -2 * (safe_loglik_binom(x, n, tau) - safe_loglik_binom(x, n, phat))
  stats::pchisq(lr, df = 1, lower.tail = FALSE)
}

lrcc_pvalue <- function(hits, tau) {
  n00 <- sum(head(hits, -1) == 0 & tail(hits, -1) == 0)
  n01 <- sum(head(hits, -1) == 0 & tail(hits, -1) == 1)
  n10 <- sum(head(hits, -1) == 1 & tail(hits, -1) == 0)
  n11 <- sum(head(hits, -1) == 1 & tail(hits, -1) == 1)
  p01 <- min(max(n01 / max(n00 + n01, 1), 1e-8), 1 - 1e-8)
  p11 <- min(max(n11 / max(n10 + n11, 1), 1e-8), 1 - 1e-8)
  p <- min(max((n01 + n11) / max(n00 + n01 + n10 + n11, 1), 1e-8), 1 - 1e-8)
  ll_ind <- n00 * log(1 - p01) + n01 * log(p01) + n10 * log(1 - p11) + n11 * log(p11)
  ll_dep <- (n00 + n10) * log(1 - p) + (n01 + n11) * log(p)
  lr_ind <- -2 * (ll_dep - ll_ind)
  lr_cc <- stats::qchisq(lruc_pvalue(hits, tau), df = 1, lower.tail = FALSE) + lr_ind
  stats::pchisq(lr_cc, df = 2, lower.tail = FALSE)
}

dq_pvalue <- function(hits, tau, lags = 4) {
  y <- hits - tau
  if (length(y) <= lags + 5) {
    return(NA_real_)
  }
  yy <- y[(lags + 1L):length(y)]
  x <- matrix(1, nrow = length(yy), ncol = lags + 1L)
  for (j in seq_len(lags)) {
    x[, j + 1L] <- y[(lags + 1L - j):(length(y) - j)]
  }
  fit <- stats::lm.fit(x, yy)
  rss <- sum(fit$residuals^2)
  tss <- sum((yy - mean(yy))^2)
  r2 <- if (tss > 0) 1 - rss / tss else 0
  stat <- length(yy) * max(r2, 0)
  stats::pchisq(stat, df = ncol(x), lower.tail = FALSE)
}

one_table <- function(df) {
  sp <- split(df, list(df$model, df$tau), drop = TRUE)
  rows <- lapply(sp, function(x) {
    hits <- as.integer(x$realized <= x$var)
    tau_i <- unique(x$tau)
    data.frame(
      model = unique(x$model),
      tau = tau_i,
      lruc = lruc_pvalue(hits, tau_i),
      lrcc = lrcc_pvalue(hits, tau_i),
      dq = dq_pvalue(hits, tau_i),
      ae = mean(hits) / tau_i,
      ql = mean((tau_i - hits) * (x$realized - x$var)),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

forecast_files <- file.path(folder_path, needed)
all_forecasts <- do.call(rbind, lapply(forecast_files, read.csv, stringsAsFactors = FALSE))
all_forecasts$model[all_forecasts$model == "br-gas-t"] <- "BR-GAS-t"

var_table <- one_table(all_forecasts)
var_table <- var_table[order(var_table$tau, var_table$model), ]

write.csv(var_table, file.path(folder_path, "var_backtesting_table.csv"), row.names = FALSE)

print(var_table)
