library(brgast)

sample_df <- sample_data()

fit <- fit_brgast(
  y = sample_df$ret,
  indicator = sample_df$post_break
)

print(fit)
print(summary(fit))

one_step <- forecast_var_es(fit, tau = c(0.10, 0.05, 0.01))
print(one_step)

plot(fit, dates = sample_df$date)

roll_out <- roll_brgast(
  data = sample_df,
  win = 250,
  refit_every = 60,
  tau = c(0.05, 0.01)
)

print(head(roll_out$forecasts))
print(roll_out$evaluation)

plot_var_es_forecasts(roll_out$forecasts, tau = 0.05)
