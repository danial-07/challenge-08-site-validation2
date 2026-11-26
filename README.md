# Data Challenge 08 – Site Classification: Validation of the Given Site Index

Forest Mensuration course. The data file `Clutter_data_original.xlsx` already contains a site index S (20, 22, 24 or 26 m) for each of the nine permanent plots. This challenge **checks whether that S can be reproduced** from dominant height (Hd) and age alone, and prepares the data base for Challenge 09 (Clutter model).

## Folder contents

| Path | What it is |
|---|---|
| `data/Clutter_data_original.xlsx` | Input: 43 measurements, 9 plots (stands 1, 2, 3, 6) |
| `scripts/00_functions_challenge08.R` | All functions (reading, guide-curve fit, S from a measurement, index-age test, graphs) |
| `scripts/01_site_validation.R` | Main script, CONFIG block at the top |
| `outputs/fitted_guide_curve.csv` | Coefficients, fit metrics (R², Syx) and the selected index age |
| `outputs/site_comparison.csv` | `stand, plot, s_given, s_calculated, difference` (+ extra columns) |
| `outputs/consolidated_site_base.csv` | `stand, plot, age, hd, b, v, s` – ready for Challenge 09 |
| `outputs/index_age_test.csv`, `index_age_test_fine.csv` | Index-age test (0.5-year grid of the assignment, and a 0.1-year check) |
| `outputs/site_curve_bundle.png` | Bundle of site curves with the observed points |
| `outputs/sse_vs_index_age.png`, `guide_curve_residuals.png` | SSE vs index age; guide-curve residuals |
| `report/report_challenge08.md` | Short report: graph, comparison table, discussion |

## How to run

```r
install.packages("readxl")        # once
setwd("path/to/challenge-08-site-validation")
source("scripts/01_site_validation.R")
```

## Method

1. **Guide curve.** One Chapman-Richards curve, `Hd = b0·(1 − e^(−b1·age))^b2`, is fitted to all 43 (age, Hd) points of the nine plots together. Column S is **not used** at this stage.
2. **S from a measurement.** In the guide-curve method all site curves have the same shape and S is the height at the index age Ii, so `Hd(t; S) = S·[(1 − e^(−b1·t)) / (1 − e^(−b1·Ii))]^b2`. Inverting: `S = Hd_obs·[(1 − e^(−b1·Ii)) / (1 − e^(−b1·t_obs))]^b2`.
3. **Which measurement.** For each plot, the measurement **nearest to Ii** is used (the earlier one if two are equally near).
4. **Index ages tested:** 4.0, 4.5, …, 7.0 (grid of the assignment). A finer 0.1-year grid is also run as a robustness check.

## Criterion used to select the index age

**Minimum SSE:** for each tested Ii, `SSE = Σ (S_calculated − S_given)²` over the nine plots. The Ii with the smallest SSE on the 0.5-year grid is selected. The tables also report the mean absolute difference, the mean difference (level bias), the number of plots whose nearest class equals the given S, and the correlation, as diagnostics only.

**Result:** Ii = **6.5 years** (SSE = 23.3 m²). The SSE is, however, almost flat between 5.5 and 7.0 years (26.6, 31.6, 23.3, 29.2), and the 0.1-year grid has its minimum at 5.9 years (SSE 14.5). Read the report before treating 6.5 as an exact answer.

## Notes

- All file, folder, function, variable and column names in this package are in English. The input workbook was renamed to `Clutter_data_original.xlsx`; its content is unchanged, so the column headers **inside** the workbook are still the original Portuguese ones. The script renames the columns by position, so this does not matter.

- `consolidated_site_base.csv` keeps the **original S** from the file. The recalculated S does not reproduce the given classes well (see report), so it was not used to overwrite them.
- All plots of one stand have the same given S. Because plots of the same stand differ in Hd, no index age can match every plot; part of the SSE is unavoidable (column `SSE_within_stand`).
- The PNG graphs in `outputs/` are provided with the package; running the R script overwrites them with the R versions (same file names).
