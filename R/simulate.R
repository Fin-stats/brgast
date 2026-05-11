gas_score_t <- function(z_t, nu) {
  ((nu + 1) * z_t^2) / ((nu - 2) + z_t^2) - 1
}

simulate_brgast <- function(n = 600,
                            break_at = floor(n * 0.6),
                            seed = NULL,
                            params = list(
                              mu = 0.00,
                              omega = -0.12,
                              a = 0.08,
                              a1 = 0.04,
                              b = 0.88,
                              b1 = -0.08,
                              d1 = 0.15,
                              nu = 8.00
                            ),
                            start_date = as.Date("2021-01-01")) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  stopifnot(n >= 50, break_at >= 2, break_at <= n)
  required <- c("mu", "omega", "a", "a1", "b", "b1", "d1", "nu")
  if (!all(required %in% names(params))) {
    stop("`params` is missing required fields.", call. = FALSE)
  }

  h <- rep(log(1.0), n)
  ret <- rep(NA_real_, n)
  indicator <- as.integer(seq_len(n) >= break_at)

  for (t in seq_len(n)) {
    scale_t <- exp(h[t] / 2)
    z_t <- stats::rt(1, df = params$nu) / std_t_scale(params$nu)
    ret[t] <- params$mu + scale_t * z_t
    s_t <- gas_score_t(z_t, params$nu)
    if (t < n) {
      a_t <- params$a + params$a1 * indicator[t]
      b_t <- params$b + params$b1 * indicator[t]
      d_t <- params$d1 * indicator[t]
      h[t + 1] <- stabilize_log_scale(params$omega + a_t * s_t + b_t * h[t] + d_t)
    }
  }

  data.frame(
    date = seq.Date(as.Date(start_date), by = "day", length.out = n),
    ret = ret,
    post_break = indicator,
    stringsAsFactors = FALSE
  )
}
