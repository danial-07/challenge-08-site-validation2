# Data Challenge 08 – Validation of the Site Index

## 1. What was done
Without using column S, one Chapman-Richards guide curve was fitted to the dominant heights of the nine plots together (43 points). For index ages from 4 to 7 years (step 0.5), the S of each plot was computed from its measurement nearest to that age, and compared with the S given in the data. The index age with the smallest sum of squared deviations (SSE) was selected.

## 2. Guide curve

Hd = 34.048 · (1 − e^(−0.15557·age))^0.84615

R² = 0.787; Syx = 1.81 m (9.7 % of mean Hd). The fit is moderate because the curve has to represent plots of different productivity at once.

![Residuals of the guide curve](../outputs/guide_curve_residuals.png)

## 3. Choice of the index age

| Index age (years) | SSE (m²) | Mean difference (calc − given), m | Plots with same class |
|---|---|---|---|
| 4.0 | 198.7 | −4.59 | 2 of 9 |
| 4.5 | 156.3 | −3.92 | 2 of 9 |
| 5.0 | 87.2 | −2.76 | 3 of 9 |
| 5.5 | 26.6 | −1.26 | 4 of 9 |
| 6.0 | 31.6 | −1.04 | 4 of 9 |
| **6.5** | **23.3** | **−0.08** | **5 of 9** |
| 7.0 | 29.2 | +0.73 | 4 of 9 |

The selected index age is **6.5 years**. At ages of 4–5 years the calculated S is far below the given one (the given S values are heights of about 20–26 m, which the trees only reach at 5.5–6.5 years). At 6.5 years the average level matches (mean difference −0.08 m).

![SSE versus index age](../outputs/sse_vs_index_age.png)

**How firm is 6.5?** Not very. Between 5.5 and 7.0 years the SSE only varies from 23 to 32, and with a 0.1-year grid the minimum moves to 5.9 years (SSE 14.5). The curve is jagged because, when the index age changes, a plot may switch to a different "nearest" measurement. The data support an index age of roughly **6 years (5.5–6.5)**, not a precise value.

## 4. Bundle of site curves

![Site curves S = 20, 22, 24, 26 and observed points](../outputs/site_curve_bundle.png)

Curves are drawn for index age 6.5 years; points are coloured by the **given** S. The points of the S = 20 stand lie close to the S = 20 curve, and the single S = 26 plot follows the S = 26 curve. The S = 22 and S = 24 plots overlap: several S = 24 plots lie on or below the S = 22 curve.

## 5. Comparison of given and recalculated S (index age 6.5 years)

| Stand | Plot | Given S | Recalculated S | Difference (m) | Class from recalculated S |
|---|---|---|---|---|---|
| 1 | 1 | 20 | 19.91 | −0.09 | 20 (same) |
| 1 | 5 | 20 | 21.21 | +1.21 | 22 |
| 2 | 2 | 22 | 24.57 | +2.57 | 24 |
| 2 | 3 | 22 | 22.13 | +0.13 | 22 (same) |
| 2 | 5 | 22 | 21.53 | −0.47 | 22 (same) |
| 3 | 1 | 24 | 21.34 | −2.66 | 22 |
| 3 | 2 | 24 | 24.69 | +0.69 | 24 (same) |
| 3 | 3 | 24 | 21.34 | −2.66 | 22 |
| 6 | 1 | 26 | 26.56 | +0.56 | 26 (same) |

Five of nine plots fall in the same class. The mean difference is about zero, but the individual differences reach ±2.7 m.

## 6. Discussion: rounding, or a different formulation?

- **The differences are not just rounding.** Classes are 2 m wide, so rounding alone would give differences of at most ±1 m. Four of the nine plots differ by more than 1 m (up to 2.7 m).
- **S in the data looks like a stand-level label.** All plots of a stand have the same given S (stand 1 → 20, 2 → 22, 3 → 24, 6 → 26), while their Hd differ within the stand (for example plots 2-2 and 2-3 differ by 2.4 m in S). Averaged by stand, the recalculated S is 20.6, 22.7, 22.5 and 26.6. So, at plot level, no index age can reproduce the given values: about 13.5 of the 23.3 m² of SSE comes from variation **inside** stands. This is our interpretation of the pattern; the data file does not say how S was assigned.
- **The ordering of stands 2 and 3 is not reproduced.** The given S puts stand 3 above stand 2 (24 vs 22), but the guide curve gives stand 2 a slightly higher S (22.7 vs 22.5). Stand 3 plots 3-1 and 3-3 have Hd of 21.0 m at 6.3 years, similar to the S = 22 plots (21.2 and 21.8 m).
- **The original method or index age was probably different.** A level match at about 6 years suggests an index age near 6, but the pattern above (stand-level labels, different curve family, or a different fitting rule) cannot be resolved with this data alone.

## 7. Consequence for Challenge 09
The consolidated data base (`consolidated_site_base.csv`) keeps the **given S**, because it is the S the assignment tells us to use and the recalculated S does not replace it reliably. However, the Challenge 09 fit has a consistent symptom: the Clutter volume projection underestimated the S = 22 plots by about 5 % and overestimated the S = 24 plots by about 6 %, which fits with the S = 24 plots being less productive than their label implies. This is consistent with, but does not prove, a classification issue.

## 8. Limitations
- Nine plots; the S = 26 class is one plot only.
- The guide curve is anamorphic by construction (all curves have the same shape), and fitted to the same points it is later compared against.
- Index ages above 6.4 years lie beyond the oldest measurement (6.37 years), so S at 6.5 years is partly extrapolated along the curve.
