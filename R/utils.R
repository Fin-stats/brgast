optim_with_fallback <- function(par, fn, control = list()) {
  methods <- c("BFGS", "Nelder-Mead")
  best <- NULL
  for (method in methods) {
    fit <- try(stats::optim(par = par, fn = fn, method = method, control = control), silent = TRUE)
    if (inherits(fit, "try-error")) {
      next
    }
    if (!is.finite(fit$value)) {
      next
    }
    if (is.null(best) || fit$value < best$value) {
      best <- fit
    }
  }
  if (is.null(best)) {
    stop("Optimization failed for all candidate methods.", call. = FALSE)
  }
  best
}

stabilize_log_scale <- function(x, lower = -8, upper = 8) {
  pmin(pmax(x, lower), upper)
}

validate_brgas_inputs <- function(y, indicator = NULL) {
  y <- as.numeric(y)
  if (length(y) < 50) {
    stop("`y` must contain at least 50 observations.", call. = FALSE)
  }
  if (any(!is.finite(y))) {
    stop("`y` contains missing or non-finite values.", call. = FALSE)
  }
  if (is.null(indicator)) {
    indicator <- rep(0, length(y))
  }
  indicator <- as.integer(indicator)
  if (length(indicator) != length(y)) {
    stop("`indicator` must have the same length as `y`.", call. = FALSE)
  }
  if (any(!indicator %in% c(0L, 1L))) {
    stop("`indicator` must only contain 0/1 values.", call. = FALSE)
  }
  list(y = y, indicator = indicator)
}

extract_series <- function(data, ret_col = "ret", indicator_col = "post_break", date_col = "date") {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }
  required <- c(ret_col, indicator_col)
  missing_cols <- setdiff(required, names(data))
  if (length(missing_cols) > 0) {
    stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")), call. = FALSE)
  }
  dates <- if (date_col %in% names(data)) as.Date(data[[date_col]]) else seq_along(data[[ret_col]])
  validated <- validate_brgas_inputs(data[[ret_col]], data[[indicator_col]])
  list(y = validated$y, indicator = validated$indicator, dates = dates)
}
