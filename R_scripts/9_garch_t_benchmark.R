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

std_t_scale <- function(nu) sqrt(nu / (nu - 2))
qstd_t <- function(p, nu) stats::qt(p, df = nu) / std_t_scale(nu)
es_std_t <- function(p, nu) {
  q_raw <- stats::qt(p, df = nu)
  dens_raw <- stats::dt(q_raw, df = nu)
  -((nu + q_raw^2) / ((nu - 1) * p)) * dens_raw / std_t_scale(nu)
}
dstd_t <- function(x, nu, log = FALSE) {
  adj <- std_t_scale(nu)
  val <- stats::dt(x * adj, df = nu, log = log)
  if (log) val + log(adj) else val * adj
}

map_garch_t <- function(raw) {
  w <- exp(raw[3:4])
  alpha <- 0.995 * w[1] / (1 + sum(w))
  beta <- 0.995 * w[2] / (1 + sum(w))
  list(mu = raw[1], omega = exp(raw[2]), alpha = alpha, beta = beta, nu = 3 + exp(raw[5]))
}

filter_garch_t <- function(y, params) {
  e <- y - params$mu
  n <- length(y)
  sig2 <- rep(max(stats::var(y), 1e-6), n)
  ll <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    z <- e[i] / sqrt(sig2[i])
    ll[i] <- dstd_t(z, params$nu, log = TRUE) - log(sqrt(sig2[i]))
    if (i < n) {
      sig2[i + 1L] <- params$omega + params$alpha * e[i]^2 + params$beta * sig2[i]
      sig2[i + 1L] <- min(max(sig2[i + 1L], 1e-8), 1e4)
    }
  }
  next_sig2 <- params$omega + params$alpha * e[n]^2 + params$beta * sig2[n]
  list(llk = sum(ll), next_sig2 = min(max(next_sig2, 1e-8), 1e4))
}

fit_garch_t <- function(y, start = NULL) {
  if (is.null(start)) {
    start <- c(mean(y), log(0.05 * stats::var(y)), stats::qlogis(0.05), stats::qlogis(0.90), log(8 - 3))
  }
  obj <- function(raw) -filter_garch_t(y, map_garch_t(raw))$llk
  fit <- try(stats::optim(start, obj, method = "BFGS", control = list(maxit = 300)), silent = TRUE)
  if (inherits(fit, "try-error") || !is.finite(fit$value)) {
    fit <- stats::optim(start, obj, method = "Nelder-Mead", control = list(maxit = 500))
  }
  params <- map_garch_t(fit$par)
  filt <- filter_garch_t(y, params)
  list(params = params, raw = fit$par, next_sig2 = filt$next_sig2)
}

forecast_garch_t <- function(fit, tau) {
  sig <- sqrt(fit$next_sig2)
  data.frame(
    tau = tau,
    var = fit$params$mu + sig * qstd_t(tau, fit$params$nu),
    es = fit$params$mu + sig * es_std_t(tau, fit$params$nu),
    stringsAsFactors = FALSE
  )
}

hbea <- brgast::sample_data()

win <- 250
refit_every <- 60
tau <- c(0.10, 0.05, 0.025, 0.01)
oos_idx <- seq.int(win + 1L, nrow(hbea))
rows <- vector("list", length(oos_idx) * length(tau))
row_id <- 1L
current_fit <- NULL
current_start <- NULL

for (j in seq_along(oos_idx)) {
  idx <- oos_idx[j]
  if (j == 1L || ((j - 1L) %% refit_every) == 0L || is.null(current_fit)) {
    train <- hbea$ret[(idx - win):(idx - 1L)]
    current_fit <- fit_garch_t(train, current_start)
    current_start <- current_fit$raw
  }
  fc <- forecast_garch_t(current_fit, tau)
  for (k in seq_len(nrow(fc))) {
    rows[[row_id]] <- data.frame(
      date = hbea$date[idx],
      model = "GARCH-t",
      tau = fc$tau[k],
      realized = hbea$ret[idx],
      var = fc$var[k],
      es = fc$es[k],
      stringsAsFactors = FALSE
    )
    row_id <- row_id + 1L
  }
  e_idx <- hbea$ret[idx] - current_fit$params$mu
  current_fit$next_sig2 <- current_fit$params$omega +
    current_fit$params$alpha * e_idx^2 +
    current_fit$params$beta * current_fit$next_sig2
  current_fit$next_sig2 <- min(max(current_fit$next_sig2, 1e-8), 1e4)
}

garch_t_forecasts <- do.call(rbind, rows)

write.csv(garch_t_forecasts, file.path(folder_path, "garch_t_benchmark_forecasts.csv"), row.names = FALSE)

print(head(garch_t_forecasts))
