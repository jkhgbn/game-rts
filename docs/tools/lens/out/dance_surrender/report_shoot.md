# lens shoot: dance_surrender

2026-09-27 19:33:10 - `tools/lens/run_lens.ps1 shoot dance_surrender`

## Result: **PASS** - quality **100 / 100** (previous run 87, +13)

0 FAIL, 0 WARN, 10 PASS, 0 info, 0 skipped, 7 s

## Improve next

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 2 shots, 0 icon groups, 0 portraits | 0 errors |  |

## Measured framing (pixels)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F_S1_1600x900_cov | S1_1600x900 ws coverage | PASS 100 | 0.349 (target 0.35, -0 %) | +-10 % of the vocabulary target |  |
| F_S1_1600x900_band_vessa | S1_1600x900 face vessa in band | PASS 100 | 100 % of head rows inside | >= 90 % inside the 2.39 band |  |
| F_S2_1600x900_cov | S2_1600x900 fs coverage | PASS 100 | 0.801 (target 0.80, +0 %) | +-10 % of the vocabulary target |  |
| F_S2_1600x900_band_vessa | S2_1600x900 face vessa in band | PASS 100 | 100 % of head rows inside | >= 90 % inside the 2.39 band |  |
| F_S2_1600x900_band_torvald | S2_1600x900 face torvald in band | PASS 100 | 100 % of head rows inside | >= 90 % inside the 2.39 band |  |

## Readability
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R_S1_1600x900_occl | S1_1600x900 occlusion | PASS 100 | 5 % | <= 30 % (ots <= 60 %) |  |
| R_S1_1600x900_contrast | S1_1600x900 subject vs background | PASS 100 | L 1.06 : 1, dE 46 | luminance >= 1.5:1 or dE >= 15 |  |
| R_S2_1600x900_occl | S2_1600x900 occlusion | PASS 100 | 17 % | <= 30 % (ots <= 60 %) |  |
| R_S2_1600x900_contrast | S2_1600x900 subject vs background | PASS 100 | L 1.39 : 1, dE 51 | luminance >= 1.5:1 or dE >= 15 |  |

## Images
- S1 1600x900: [S1_1600x900.png](S1_1600x900.png)
- S2 1600x900: [S2_1600x900.png](S2_1600x900.png)
- sheet: [sheet.png](sheet.png)

## Notes
- Metrics from ID passes (unshaded white subject / black occluders): coverage s = head or body pixel height / band height; face in band = >= 90 % of the head mask rows inside the band; occlusion = 1 - visible / alone pixels; contrast = WCAG luminance ratio and CIE76 dE, subject vs a ring of background around it.
