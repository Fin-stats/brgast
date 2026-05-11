library(brgast)

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

hbea <- sample_data()

fz_mean <- function(forecasts) {
  sp <- split(forecasts, forecasts$tau)
  vals <- lapply(sp, function(x) {
    hits <- as.integer(x$realized <= x$var)
    tau_i <- unique(x$tau)
    mean((1 / (x$es^2)) * (x$es - x$var + ((x$var - x$realized) * hits) / tau_i))
  })
  mean(unlist(vals))
}

run_case <- function(label, data, win, refit_every) {
  ans <- roll_brgast(
    data = data,
    win = win,
    refit_every = refit_every,
    tau = c(0.05, 0.01),
    fit_control = list(maxit = 250)
  )
  data.frame(
    case = label,
    win = win,
    refit_every = refit_every,
    mean_fz_loss = fz_mean(ans$forecasts),
    ae_005 = ans$evaluation$ae[ans$evaluation$tau == 0.05],
    ae_001 = ans$evaluation$ae[ans$evaluation$tau == 0.01],
    stringsAsFactors = FALSE
  )
}

break_idx <- which(hbea$post_break == 1L)[1]

minus10 <- hbea
minus10$post_break <- as.integer(seq_len(nrow(minus10)) >= max(1L, break_idx - 10L))

plus10 <- hbea
plus10$post_break <- as.integer(seq_len(nrow(plus10)) >= min(nrow(plus10), break_idx + 10L))

cases <- list(
  run_case("baseline", hbea, 250, 60),
  run_case("break_minus_10", minus10, 250, 60),
  run_case("break_plus_10", plus10, 250, 60),
  run_case("window_200", hbea, 200, 60),
  run_case("window_300", hbea, 300, 60),
  run_case("refit_30", hbea, 250, 30),
  run_case("refit_90", hbea, 250, 90)
)

robustness_table <- do.call(rbind, cases)

write.csv(robustness_table, file.path(folder_path, "robustness_checks_table.csv"), row.names = FALSE)

print(robustness_table)
