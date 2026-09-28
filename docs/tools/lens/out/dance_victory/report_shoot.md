# lens shoot: dance_victory

2026-09-27 19:32:14 - `tools/lens/run_lens.ps1 shoot dance_victory`

## Result: **PASS** - quality **98 / 100**

0 FAIL, 0 WARN, 10 PASS, 0 info, 0 skipped, 7 s

## Improve next

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 2 shots, 0 icon groups, 0 portraits | 0 errors |  |

## Measured framing (pixels)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F_D1_1600x900_cov | D1_1600x900 ws coverage | PASS 99 | 0.363 (target 0.35, +4 %) | +-10 % of the vocabulary target |  |
| F_D1_1600x900_band_vessa | D1_1600x900 face vessa in band | PASS 100 | 100 % of head rows inside | >= 90 % inside the 2.39 band |  |
| F_D2_1600x900_cov | D2_1600x900 fs coverage | PASS 88 | 0.879 (target 0.80, +10 %) | +-10 % of the vocabulary target |  |
| F_D2_1600x900_band_ysolde | D2_1600x900 face ysolde in band | PASS 100 | 100 % of head rows inside | >= 90 % inside the 2.39 band |  |
| F_D2_1600x900_band_torvald | D2_1600x900 face torvald in band | PASS 100 | 100 % of head rows inside | >= 90 % inside the 2.39 band |  |

## Readability
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R_D1_1600x900_occl | D1_1600x900 occlusion | PASS 100 | 1 % | <= 30 % (ots <= 60 %) |  |
| R_D1_1600x900_contrast | D1_1600x900 subject vs background | PASS 100 | L 1.04 : 1, dE 45 | luminance >= 1.5:1 or dE >= 15 |  |
| R_D2_1600x900_occl | D2_1600x900 occlusion | PASS 100 | 7 % | <= 30 % (ots <= 60 %) |  |
| R_D2_1600x900_contrast | D2_1600x900 subject vs background | PASS 100 | L 1.02 : 1, dE 19 | luminance >= 1.5:1 or dE >= 15 |  |

## Images
- D1 1600x900: [D1_1600x900.png](D1_1600x900.png)
- D2 1600x900: [D2_1600x900.png](D2_1600x900.png)
- sheet: [sheet.png](sheet.png)

## Notes
- Metrics from ID passes (unshaded white subject / black occluders): coverage s = head or body pixel height / band height; face in band = >= 90 % of the head mask rows inside the band; occlusion = 1 - visible / alone pixels; contrast = WCAG luminance ratio and CIE76 dE, subject vs a ring of background around it.
