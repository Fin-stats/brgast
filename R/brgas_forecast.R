forecast_var_es <- function(object, tau = c(0.10, 0.05, 0.01), state = NULL) {
  if (!inherits(object, "brgas_fit")) {
    stop("`object` must inherit from 'brgas_fit'.", call. = FALSE)
  }
  tau <- as.numeric(tau)
  tau <- tau[tau > 0 & tau < 0.5]
  if (length(tau) == 0) {
    stop("`tau` must contain values in (0, 0.5).", call. = FALSE)
  }
  if (is.null(state)) {
    state <- object$fitted$next_state
  }
  scale_t <- exp(state / 2)
  params <- object$coefficients
  data.frame(
    tau = tau,
    var = params$mu + scale_t * qstd_t(tau, params$nu),
    es = params$mu + scale_t * es_std_t(tau, params$nu),
    stringsAsFactors = FALSE
  )
}

backtest_var_es <- function(forecasts) {
  required <- c("tau", "realized", "var", "es")
  missing_cols <- setdiff(required, names(forecasts))
  if (length(missing_cols) > 0) {
    stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")), call. = FALSE)
  }
  split_df <- split(forecasts, forecasts$tau)
  out <- lapply(split_df, function(df) {
    hits <- as.integer(df$realized <= df$var)
    ae <- mean(hits) / unique(df$tau)
    ql <- mean((unique(df$tau) - hits) * (df$realized - df$var))
    fz <- mean((1 / (df$es^2)) * (df$es - df$var + ((df$var - df$realized) * hits) / unique(df$tau)))
    data.frame(
      tau = unique(df$tau),
      exceedance_rate = mean(hits),
      ae = ae,
      ql = ql,
      fz_loss = fz,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

mean_fz_loss <- function(forecasts) {
  bt <- backtest_var_es(forecasts)
  mean(bt$fz_loss)
}

roll_brgast <- function(data,
                        win = 250,
                        refit_every = 20,
                        tau = c(0.10, 0.05, 0.01),
                        warm_start = TRUE,
                        fit_control = list(maxit = 600),
                        ret_col = "ret",
                        indicator_col = "post_break",
                        date_col = "date") {
  extracted <- extract_series(data, ret_col = ret_col, indicator_col = indicator_col, date_col = date_col)
  y <- extracted$y
  indicator <- extracted$indicator
  dates <- extracted$dates

  if (win >= length(y)) {
    stop("`win` must be shorter than the available sample.", call. = FALSE)
  }
  if (refit_every < 1) {
    stop("`refit_every` must be at least 1.", call. = FALSE)
  }

  oos_idx <- seq.int(win + 1, length(y))
  recs <- vector("list", length(oos_idx) * length(tau))
  rec_id <- 1L
  current_fit <- NULL
  current_state <- NULL
  current_start <- NULL

  for (j in seq_along(oos_idx)) {
    idx <- oos_idx[j]
    if (j == 1L || ((j - 1L) %% refit_every) == 0L || is.null(current_fit)) {
      train_idx <- seq.int(idx - win, idx - 1L)
      current_fit <- fit_brgast(
        y[train_idx],
        indicator[train_idx],
        start = current_start,
        control = fit_control
      )
      current_state <- current_fit$fitted$next_state
      if (isTRUE(warm_start)) {
        current_start <- current_fit$raw
      } else {
        current_start <- NULL
      }
    }

    fc <- forecast_var_es(current_fit, tau = tau, state = current_state)
    for (k in seq_len(nrow(fc))) {
      recs[[rec_id]] <- data.frame(
        date = dates[idx],
        model = "br-gas-t",
        tau = fc$tau[k],
        realized = y[idx],
        var = fc$var[k],
        es = fc$es[k],
        stringsAsFactors = FALSE
      )
      rec_id <- rec_id + 1L
    }

    current_state <- update_brgas_state(
      y_t = y[idx],
      state_t = current_state,
      params = current_fit$coefficients,
      indicator_t = indicator[idx]
    )
  }

  forecasts <- do.call(rbind, recs)
  evaluation <- backtest_var_es(forecasts)
  list(forecasts = forecasts, evaluation = evaluation)
}
