# Contributing to brgast

Thanks for your interest in improving `brgast`.

## Scope

This repository is focused on the **R package implementation** of the BR-GAS-t
model. Contributions should improve one or more of the following:

- model fitting and forecasting
- package usability and documentation
- plotting and diagnostics
- testing and package infrastructure

Please avoid opening pull requests that try to recreate the full empirical
workflow of the paper or ship the full research dataset.

## Getting started

1. Fork the repository.
2. Create a feature branch from `main`.
3. Make focused changes.
4. Run a local install check:

```r
install.packages(".", repos = NULL, type = "source")
```

5. Run the example script:

```r
source("inst/examples/basic_usage.R")
```

## Pull request guidance

- Keep pull requests narrow and easy to review.
- Update documentation when you change exported functions.
- Add or update examples when user-facing behavior changes.
- Explain any numerical or modeling trade-offs in the PR description.

## Reporting bugs

When opening an issue, please include:

- your R version
- your operating system
- the code used to reproduce the problem
- the full error message
