clamp_prob <- function(x) {
  pmin(pmax(x, 1e-8), 1 - 1e-8)
}

std_t_scale <- function(nu) {
  sqrt(nu / (nu - 2))
}

dstd_t <- function(x, nu, log = FALSE) {
  scale_adj <- std_t_scale(nu)
  out <- stats::dt(x * scale_adj, df = nu, log = log)
  if (log) {
    out + log(scale_adj)
  } else {
    out * scale_adj
  }
}

qstd_t <- function(p, nu) {
  stats::qt(clamp_prob(p), df = nu) / std_t_scale(nu)
}

es_std_t <- function(tau, nu) {
  tau <- clamp_prob(tau)
  q_raw <- stats::qt(tau, df = nu)
  dens_raw <- stats::dt(q_raw, df = nu)
  es_raw <- -((nu + q_raw^2) / ((nu - 1) * tau)) * dens_raw
  es_raw / std_t_scale(nu)
}

