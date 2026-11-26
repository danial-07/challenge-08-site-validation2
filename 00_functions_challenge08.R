# =============================================================================
# 00_functions_challenge08.R
# Data Challenge 08 - Site classification: validating the S given in the data
#
# Functions only (no data, no plots run here). Loaded by 01_site_validation.R
# with source().
#
# IDEA IN ONE PARAGRAPH
#   The data file already comes with a site index S per plot (20, 22, 24, 26 m).
#   We IGNORE it, fit ONE guide curve to the dominant heights (Hd) of all plots
#   together, and for a chosen index age Ii we compute the S of each plot
#   (= the height that plot's curve would have at age Ii). We repeat for many
#   index ages and keep the Ii whose computed S is closest to the given S.
# =============================================================================

# Base growth model: Chapman-Richards   Hd = b0 * (1 - exp(-b1 * t))^b2
cr <- function(t, b0, b1, b2) b0 * (1 - exp(-b1 * t))^b2


# -----------------------------------------------------------------------------
# 1. READING THE DATA
# -----------------------------------------------------------------------------
# Reads Clutter_data_original.xlsx; renames the 8 columns BY POSITION (the
# original header is in Portuguese and has accents). plot_id = "stand-plot"
# because plot numbers repeat between stands.
# NOTE: column S is kept in the table but is NEVER used by the fit; it is only
# used afterwards to compare.
read_base <- function(path) {
  d <- as.data.frame(readxl::read_excel(path))
  names(d)[1:8] <- c("project", "stand", "plot", "age", "B", "Hd", "V", "S")
  d$plot_id <- paste(d$stand, d$plot, sep = "-")
  d <- d[order(d$plot_id, d$age), ]
  rownames(d) <- NULL
  d
}


# -----------------------------------------------------------------------------
# 2. GUIDE CURVE (all plots pooled, S not used)
# -----------------------------------------------------------------------------
# nls() with several starting points and bounds ("port"); keeps the fit with
# the smallest residual sum of squares. Output: list(coef, model, metrics).
fit_guide_curve <- function(age, hd) {
  dd <- data.frame(age = age, hd = hd)
  starts <- expand.grid(b0 = c(25, 30, 40, 60), b1 = c(0.1, 0.2, 0.4), b2 = c(0.8, 1, 1.5))
  best <- NULL
  for (i in seq_len(nrow(starts))) {
    fit <- tryCatch(
      nls(hd ~ b0 * (1 - exp(-b1 * age))^b2, data = dd,
          start = as.list(starts[i, ]), algorithm = "port",
          lower = c(b0 = 5, b1 = 0.01, b2 = 0.1), upper = c(b0 = 200, b1 = 3, b2 = 10),
          control = nls.control(maxiter = 500, warnOnly = TRUE)),
      error = function(e) NULL)
    if (!is.null(fit) && (is.null(best) || deviance(fit) < deviance(best))) best <- fit
  }
  if (is.null(best)) stop("nls failed from every starting point.")
  co  <- unname(coef(best))
  n   <- nrow(dd); k <- 3
  sse <- sum((dd$hd - fitted(best))^2)
  metrics <- c(n = n,
               R2 = 1 - sse / sum((dd$hd - mean(dd$hd))^2),
               Syx_m = sqrt(sse / (n - k)),
               Syx_percent = 100 * sqrt(sse / (n - k)) / mean(dd$hd))
  list(coef = c(b0 = co[1], b1 = co[2], b2 = co[3]), model = best, metrics = metrics)
}


# -----------------------------------------------------------------------------
# 3. SITE INDEX FROM THE GUIDE CURVE
# -----------------------------------------------------------------------------
# Anamorphic guide-curve rule. All site curves have the same shape and differ
# only by a multiplier, and S is the height at the index age Ii:
#     Hd(t ; S) = S * [ (1 - exp(-b1 t)) / (1 - exp(-b1 Ii)) ]^b2
# Inverting for S, given an observation (t_obs, Hd_obs):
#     S = Hd_obs * [ (1 - exp(-b1 Ii)) / (1 - exp(-b1 t_obs)) ]^b2
site_index_from_observation <- function(hd_obs, age_obs, Ii, co) {
  hd_obs * ((1 - exp(-co[["b1"]] * Ii)) / (1 - exp(-co[["b1"]] * age_obs)))^co[["b2"]]
}

# Hd of the site curve S at age t, for index age Ii (used for the curve bundle).
site_curve_height <- function(t, S, Ii, co) {
  S * ((1 - exp(-co[["b1"]] * t)) / (1 - exp(-co[["b1"]] * Ii)))^co[["b2"]]
}

# For each plot, take the measurement NEAREST to the index age Ii (the earlier
# one if two are equally near) and convert it to S. Output: one row per plot.
calculate_plot_S <- function(data, co, Ii) {
  rows <- lapply(split(data, data$plot_id), function(g) {
    j <- which.min(abs(g$age - Ii))
    data.frame(stand = g$stand[j], plot = g$plot[j], plot_id = g$plot_id[j],
               s_given = g$S[j],
               measurement_age_used = g$age[j], measurement_hd_used = g$Hd[j],
               s_calculated = site_index_from_observation(g$Hd[j], g$age[j], Ii, co),
               stringsAsFactors = FALSE)
  })
  t <- do.call(rbind, rows)
  rownames(t) <- NULL
  t$difference <- t$s_calculated - t$s_given
  classes <- sort(unique(data$S))
  t$calculated_class <- vapply(t$s_calculated, function(s) classes[which.min(abs(classes - s))], numeric(1))
  t$class_match <- t$calculated_class == t$s_given
  t
}


# -----------------------------------------------------------------------------
# 4. TESTING MANY INDEX AGES
# -----------------------------------------------------------------------------
# For each Ii in `grid`, computes the S of the 9 plots and the comparison
# criteria. CRITERION USED TO CHOOSE Ii: SSE = sum over plots of
# (calculated S - given S)^2  (smaller is better). Other columns are only
# diagnostics:
#   mean_abs_deviation  mean |difference| (m)
#   bias                mean difference (calculated - given); 0 = no level error
#   matching_classes    plots whose nearest class equals the given S (out of 9)
#   correlation         correlation calculated S vs given S
#   SSE_within_stand    part of the variation of the calculated S that exists
#                       INSIDE each stand (plots of one stand have the same given
#                       S, so no index age can remove this part of the SSE)
test_index_ages <- function(data, co, grid) {
  rows <- lapply(grid, function(Ii) {
    t <- calculate_plot_S(data, co, Ii)
    within <- t$s_calculated - ave(t$s_calculated, t$stand)    # deviation from stand mean
    data.frame(index_age = round(Ii, 2),
               SSE = sum(t$difference^2),
               mean_abs_deviation = mean(abs(t$difference)),
               bias = mean(t$difference),
               matching_classes = sum(t$class_match),
               correlation = cor(t$s_calculated, t$s_given),
               SSE_within_stand = sum(within^2))
  })
  do.call(rbind, rows)
}


# -----------------------------------------------------------------------------
# 5. GRAPHS
# -----------------------------------------------------------------------------
# Bundle of site curves (S = 20, 22, 24, 26) for the chosen Ii, with the
# observed points of the 9 plots coloured by the GIVEN S.
plot_bundle <- function(data, co, Ii, classes, file) {
  colors <- c("#86b6ef", "#3987e5", "#1c5cab", "#0d366b")[seq_along(classes)]
  names(colors) <- as.character(classes)
  png(file, width = 1275, height = 825, res = 150)
  par(mar = c(4.5, 4.5, 3, 2))
  plot(NA, xlim = c(2.4, 7.5), ylim = c(10.5, 28), xlab = "Age (years)",
       ylab = "Dominant height Hd (m)",
       main = "Site-curve bundle vs observed points (colour = given S)")
  grid(nx = NA, ny = NULL, col = "#e1e0d9", lty = 1)
  ages <- seq(2.4, 7, length.out = 100)
  for (S in classes) {
    lines(ages, site_curve_height(ages, S, Ii, co), col = colors[as.character(S)], lwd = 2)
    text(7.05, site_curve_height(7, S, Ii, co), paste0("S=", S), pos = 4, cex = 0.8, xpd = TRUE)
  }
  for (p in unique(data$plot_id)) {
    g <- data[data$plot_id == p, ]
    cc <- colors[as.character(g$S[1])]
    lines(g$age, g$Hd, col = cc, lty = 3)
    points(g$age, g$Hd, pch = 19, col = cc, cex = 0.9)
  }
  abline(v = Ii, lty = 2, col = "#898781")
  text(Ii - 0.05, 11.2, paste0("index age\n", Ii, " years"), pos = 2, cex = 0.8)
  legend("topleft", legend = paste0("Given S = ", classes, " m"), col = colors,
         pch = 19, bty = "n", cex = 0.85)
  dev.off()
}

# SSE versus tested index age (coarse grid of the assignment + fine grid).
plot_sse <- function(coarse_test, fine_test, Ii, file) {
  png(file, width = 1125, height = 600, res = 150)
  par(mar = c(4.5, 4.5, 3, 1))
  plot(fine_test$index_age, fine_test$SSE, type = "l", col = "#2a78d6", lwd = 2,
       xlab = "Tested index age (years)", ylab = "Sum of squared deviations (m2)",
       main = "SSE between calculated S and given S", ylim = c(0, max(fine_test$SSE)))
  grid(nx = NA, ny = NULL, col = "#e1e0d9", lty = 1)
  points(coarse_test$index_age, coarse_test$SSE, pch = 19, col = "#eb6834", cex = 1.2)
  points(Ii, min(coarse_test$SSE), pch = 1, cex = 2.2)
  legend("topright", legend = c("0.1-year step", "0.5-year step (assignment)"),
         col = c("#2a78d6", "#eb6834"), lwd = c(2, NA), pch = c(NA, 19), bty = "n")
  dev.off()
}

# Residuals of the guide curve.
plot_guide_residuals <- function(data, co, file) {
  fitted_hd <- cr(data$age, co[["b0"]], co[["b1"]], co[["b2"]])
  png(file, width = 900, height = 600, res = 150)
  par(mar = c(4.5, 4.5, 3, 1))
  plot(fitted_hd, data$Hd - fitted_hd, pch = 19, col = "#2a78d6", xlab = "Fitted Hd (m)",
       ylab = "Residual (m)", main = "Guide curve: residuals")
  abline(h = 0, col = "#898781")
  dev.off()
}
