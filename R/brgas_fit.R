map_brgas_params <- function(raw) {
  a_pre <- 0.25 * stats::plogis(raw[3])
  a_post <- 0.25 * stats::plogis(raw[4])
  b_pre <- 0.98 * stats::plogis(raw[5])
  b_post <- 0.98 * stats::plogis(raw[6])
  list(
    mu = raw[1],
    omega = 0.75 * tanh(raw[2]),
    a = a_pre,
    a1 = a_post - a_pre,
    b = b_pre,
    b1 = b_post - b_pre,
    d1 = 0.50 * tanh(raw[7]),
    nu = 3 + exp(raw[8]),
    a_post = a_post,
    b_post = b_post
  )
}

update_brgas_state <- function(y_t, state_t, params, indicator_t) {
  scale_t <- exp(state_t / 2)
  z_t <- (y_t - params$mu) / scale_t
  s_t <- gas_score_t(z_t, params$nu)
  a_t <- params$a + params$a1 * indicator_t
  b_t <- params$b + params$b1 * indicator_t
  d_t <- params$d1 * indicator_t
  stabilize_log_scale(params$omega + a_t * s_t + b_t * state_t + d_t)
}

filter_brgast <- function(y, indicator, params, return_path = TRUE) {
  validated <- validate_brgas_inputs(y, indicator)
  y <- validated$y
  indicator <- validated$indicator
  n <- length(y)
  h_t <- rep(log(max(stats::var(y), 1e-6)), n)
  ll_vec <- rep(NA_real_, n)
  score_vec <- rep(NA_real_, n)

  for (t in seq_len(n)) {
    scale_t <- exp(h_t[t] / 2)
    z_t <- (y[t] - params$mu) / scale_t
    ll_vec[t] <- dstd_t(z_t, params$nu, log = TRUE) - log(scale_t)
    score_vec[t] <- gas_score_t(z_t, params$nu)
    if (t < n) {
      a_t <- params$a + params$a1 * indicator[t]
      b_t <- params$b + params$b1 * indicator[t]
      d_t <- params$d1 * indicator[t]
      h_t[t + 1] <- stabilize_log_scale(params$omega + a_t * score_vec[t] + b_t * h_t[t] + d_t)
    }
  }

  a_last <- params$a + params$a1 * indicator[n]
  b_last <- params$b + params$b1 * indicator[n]
  d_last <- params$d1 * indicator[n]
  h_next <- stabilize_log_scale(params$omega + a_last * score_vec[n] + b_last * h_t[n] + d_last)

  out <- list(
    llk = sum(ll_vec),
    last_state = h_t[n],
    next_state = h_next
  )
  if (return_path) {
    out$h_path <- h_t
    out$scale_path <- exp(h_t / 2)
    out$score_path <- score_vec
    out$ll_path <- ll_vec
  }
  out
}

fit_brgast <- function(y, indicator, start = NULL, control = list(maxit = 1500)) {
  validated <- validate_brgas_inputs(y, indicator)
  y <- validated$y
  indicator <- validated$indicator
  var_y <- max(stats::var(y), 1e-6)
  if (is.null(start)) {
    start <- c(
      mean(y),
      0,
      stats::qlogis(0.08 / 0.25),
      stats::qlogis(0.12 / 0.25),
      stats::qlogis(0.88 / 0.98),
      stats::qlogis(0.82 / 0.98),
      0,
      log(8 - 3)
    )
  }

  objective <- function(raw) {
    params <- map_brgas_params(raw)
    filt <- filter_brgast(y, indicator, params, return_path = FALSE)
    -filt$llk
  }

  fit <- optim_with_fallback(start, objective, control = control)
  params <- map_brgas_params(fit$par)
  filtered <- filter_brgast(y, indicator, params, return_path = TRUE)
  out <- list(
    coefficients = params,
    raw = fit$par,
    loglik = filtered$llk,
    aic = -2 * filtered$llk + 2 * 8,
    bic = -2 * filtered$llk + log(length(y)) * 8,
    fitted = filtered,
    y = y,
    indicator = indicator,
    n = length(y),
    converged = isTRUE(fit$convergence == 0),
    call = match.call()
  )
  class(out) <- "brgas_fit"
  out
}

coef.brgas_fit <- function(object, ...) {
  object$coefficients
}

print.brgas_fit <- function(x, ...) {
  cat("brgast fit\n")
  cat(sprintf("  Observations: %s\n", x$n))
  cat(sprintf("  Log-likelihood: %.3f\n", x$loglik))
  cat(sprintf("  AIC: %.3f\n", x$aic))
  cat(sprintf("  BIC: %.3f\n", x$bic))
  cat(sprintf("  Converged: %s\n", if (isTRUE(x$converged)) "yes" else "no"))
  invisible(x)
}

summary.brgas_fit <- function(object, ...) {
  coefs <- unlist(object$coefficients[c("mu", "omega", "a", "a1", "b", "b1", "d1", "nu")])
  out <- list(
    coefficients = data.frame(
      term = names(coefs),
      estimate = unname(coefs),
      stringsAsFactors = FALSE
    ),
    fit = data.frame(
      metric = c("loglik", "aic", "bic", "n"),
      value = c(object$loglik, object$aic, object$bic, object$n),
      stringsAsFactors = FALSE
    ),
    converged = object$converged
  )
  class(out) <- "summary_brgas_fit"
  out
}

print.summary_brgas_fit <- function(x, ...) {
  cat("Summary of brgast fit\n")
  cat(sprintf("  Converged: %s\n\n", if (isTRUE(x$converged)) "yes" else "no"))
  print(x$coefficients, row.names = FALSE)
  cat("\n")
  print(x$fit, row.names = FALSE)
  invisible(x)
}
