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
gas_score_t <- function(z, nu) ((nu + 1) * z^2) / ((nu - 2) + z^2) - 1
clip <- function(x, lo = -8, hi = 8) pmin(pmax(x, lo), hi)

map_gas_t <- function(raw) {
  list(
    mu = raw[1],
    omega = 0.75 * tanh(raw[2]),
    a = 0.25 * stats::plogis(raw[3]),
    b = 0.98 * stats::plogis(raw[4]),
    nu = 3 + exp(raw[5])
  )
}

filter_gas_t <- function(y, params) {
  n <- length(y)
  h <- rep(log(max(stats::var(y), 1e-6)), n)
  ll <- rep(NA_real_, n)
  score <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    scale_i <- exp(h[i] / 2)
    z <- (y[i] - params$mu) / scale_i
    ll[i] <- dstd_t(z, params$nu, log = TRUE) - log(scale_i)
    score[i] <- gas_score_t(z, params$nu)
    if (i < n) {
      h[i + 1L] <- clip(params$omega + params$a * score[i] + params$b * h[i])
    }
  }
  next_h <- clip(params$omega + params$a * score[n] + params$b * h[n])
  list(llk = sum(ll), next_h = next_h)
}

fit_gas_t <- function(y, start = NULL) {
  if (is.null(start)) {
    start <- c(mean(y), 0, stats::qlogis(0.08 / 0.25), stats::qlogis(0.88 / 0.98), log(8 - 3))
  }
  obj <- function(raw) -filter_gas_t(y, map_gas_t(raw))$llk
  fit <- try(stats::optim(start, obj, method = "BFGS", control = list(maxit = 500)), silent = TRUE)
  if (inherits(fit, "try-error") || !is.finite(fit$value)) {
    fit <- stats::optim(start, obj, method = "Nelder-Mead", control = list(maxit = 700))
  }
  params <- map_gas_t(fit$par)
  filt <- filter_gas_t(y, params)
  list(params = params, raw = fit$par, next_h = filt$next_h)
}

forecast_gas_t <- function(fit, tau) {
  scale_i <- exp(fit$next_h / 2)
  data.frame(
    tau = tau,
    var = fit$params$mu + scale_i * qstd_t(tau, fit$params$nu),
    es = fit$params$mu + scale_i * es_std_t(tau, fit$params$nu),
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
    current_fit <- fit_gas_t(train, current_start)
    current_start <- current_fit$raw
  }
  fc <- forecast_gas_t(current_fit, tau)
  for (k in seq_len(nrow(fc))) {
    rows[[row_id]] <- data.frame(
      date = hbea$date[idx],
      model = "GAS-t",
      tau = fc$tau[k],
      realized = hbea$ret[idx],
      var = fc$var[k],
      es = fc$es[k],
      stringsAsFactors = FALSE
    )
    row_id <- row_id + 1L
  }
  scale_idx <- exp(current_fit$next_h / 2)
  z_idx <- (hbea$ret[idx] - current_fit$params$mu) / scale_idx
  score_idx <- gas_score_t(z_idx, current_fit$params$nu)
  current_fit$next_h <- clip(
    current_fit$params$omega +
      current_fit$params$a * score_idx +
      current_fit$params$b * current_fit$next_h
  )
}

gas_t_forecasts <- do.call(rbind, rows)

write.csv(gas_t_forecasts, file.path(folder_path, "gas_t_benchmark_forecasts.csv"), row.names = FALSE)

print(head(gas_t_forecasts))
