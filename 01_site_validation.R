# =============================================================================
# 01_site_validation.R
# Data Challenge 08 - Site classification: validation and preparation of the
# data base for the Clutter model.
#
# HOW TO RUN
#   1. install.packages("readxl")      (once)
#   2. setwd() to the folder "challenge-08-site-validation"
#   3. source("scripts/01_site_validation.R")
#
# STEPS (numbers = steps of the assignment)
#   1. fit the guide curve to all plots together (column S NOT used)
#   2-3. for index ages 4 to 7 (step 0.5) compute the S of each plot
#   4. choose the index age that gives S closest to the given S (min SSE)
#   5. bundle of site curves + observed points
#   6. comparison table
#   7. consolidated data base for Challenge 09
# =============================================================================

# ----------------------------- CONFIG (edit here) ----------------------------
DATA_FILE      <- "data/Clutter_data_original.xlsx"
OUTPUT_DIR     <- "outputs"
FUNCTIONS_FILE <- "scripts/00_functions_challenge08.R"

INDEX_AGE_GRID <- seq(4, 7, by = 0.5)   # grid requested in the assignment
FINE_GRID      <- seq(4, 7, by = 0.1)   # extra: finer grid, robustness check
# -----------------------------------------------------------------------------

source(FUNCTIONS_FILE)
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)
out <- function(name) file.path(OUTPUT_DIR, name)

# ---- Step 0: data ------------------------------------------------------------
data    <- read_base(DATA_FILE)
classes <- sort(unique(data$S))
cat("Measurements:", nrow(data), "| plots:", length(unique(data$plot_id)),
    "| given S classes:", classes, "\n")

# ---- Step 1: guide curve (uses ONLY age and Hd) -----------------------------
guide <- fit_guide_curve(data$age, data$Hd)
co    <- guide$coef
cat("\nGuide curve (Chapman-Richards): b0 =", round(co[["b0"]], 4),
    " b1 =", round(co[["b1"]], 5), " b2 =", round(co[["b2"]], 5), "\n")
print(round(guide$metrics, 4))

# ---- Steps 2-4: test index ages and choose one ------------------------------
coarse_test <- test_index_ages(data, co, INDEX_AGE_GRID)
fine_test   <- test_index_ages(data, co, FINE_GRID)
Ii <- coarse_test$index_age[which.min(coarse_test$SSE)]     # CRITERION: min SSE
cat("\nIndex-age test (assignment grid):\n"); print(round(coarse_test, 3))
cat("\nSelected index age (min SSE on the 0.5 grid):", Ii, "years\n")
Ii_fine <- fine_test$index_age[which.min(fine_test$SSE)]
cat("Min SSE on the fine 0.1 grid:", Ii_fine, "years (SSE",
    round(min(fine_test$SSE), 2), "vs", round(min(coarse_test$SSE), 2), ")\n")
write.csv(coarse_test, out("index_age_test.csv"), row.names = FALSE)
write.csv(fine_test, out("index_age_test_fine.csv"), row.names = FALSE)

# ---- Step 6: comparison table at the selected index age ---------------------
comp <- calculate_plot_S(data, co, Ii)
comp_out <- comp[, c("stand", "plot", "s_given", "s_calculated", "difference",
                     "measurement_age_used", "measurement_hd_used",
                     "calculated_class", "class_match")]
write.csv(comp_out, out("site_comparison.csv"), row.names = FALSE)
cat("\nComparison (given S vs recalculated S):\n"); print(round(comp_out[, 1:7], 2))
cat("Plots whose nearest class equals the given S:", sum(comp$class_match), "of", nrow(comp), "\n")
cat("Mean difference:", round(mean(comp$difference), 2), "m | largest |difference|:",
    round(max(abs(comp$difference)), 2), "m\n")

# ---- Output 1: fitted_guide_curve.csv ----------------------------------------
guide_table <- rbind(
  data.frame(group = "coefficient", name = c("b0", "b1", "b2"), value = unname(co)),
  data.frame(group = "metric", name = names(guide$metrics), value = unname(guide$metrics)),
  data.frame(group = "selection", name = c("selected_index_age", "criterion_SSE"),
             value = c(Ii, min(coarse_test$SSE)))
)
write.csv(guide_table, out("fitted_guide_curve.csv"), row.names = FALSE)

# ---- Step 5: graphs ----------------------------------------------------------
plot_bundle(data, co, Ii, classes, out("site_curve_bundle.png"))
plot_sse(coarse_test, fine_test, Ii, out("sse_vs_index_age.png"))
plot_guide_residuals(data, co, out("guide_curve_residuals.png"))

# ---- Step 7: consolidated data base for Challenge 09 -------------------------
# Same original data, same S (the GIVEN one): the recalculated S is NOT used to
# overwrite it, because it does not reproduce the given classes (see report).
base <- data.frame(stand = data$stand, plot = data$plot, age = data$age,
                   hd = data$Hd, b = data$B, v = data$V, s = data$S)
write.csv(base, out("consolidated_site_base.csv"), row.names = FALSE)

cat("\nDone. Files written to:", normalizePath(OUTPUT_DIR), "\n")
