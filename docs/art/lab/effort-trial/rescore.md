# Effort trial: rescore with Art Lab v3.1 (2026-09-27)

One batch, one Godot process (laptop, windowed, `log=0`), the same args as the trial runs plus the brief's reach:
```powershell
.\tools\art_lab\run_art_lab.ps1 -Batch docs/art/lab/effort-trial/rescore_batch.txt -Extra 'out_root=docs/art/lab/effort-trial/rescore','log=0'
```
Each entry: `kind=unit kingdom=nature reach=3.0 ref=thornling,bramblehorn,burr_slinger compare=docs/art/lab/effort-trial/<level>`
(scorecards + `diff_sheet.png` vs the trial's final run in `rescore/<level>/`; 131 s for the 4, ~33 s each).

Blind key: A = high, B = low, C = xhigh, D = medium (`blind_key.txt`).

| Level | Before (v3.0, trial final) | After (v3.1) | Delta | C1 shapes | C2 vertex use | C3 palette | C4 inner detail | A3r reach (declared 3.0 m) | WARN |
|---|---|---|---|---|---|---|---|---|---|
| low (B) | 94.7 WARN | **87.1** WARN | -7.6 | 21 (3.4 shapes / part, 57 % plain prisms) | 25 (38 % of 2500) | 70 | 39 | PASS 3.23 m | R4k |
| medium (D) | 94.9 PASS | 92.9 PASS | -2.0 | 71 | 100 | 90 | 58 | PASS 4.14 m | - |
| high (A) | 95.3 PASS | 95.4 PASS | +0.1 | 97 | 100 | 100 | 86 | PASS 3.73 m | - |
| xhigh (C) | 96.1 PASS | 95.1 PASS | -1.0 | 76 | 100 | 100 | 83 | PASS 3.44 m | - |

Gap low vs the others: **0.2-1.4 points before, 5.8-8.3 after** (low vs medium 5.8, vs xhigh 8.0, vs high 8.3).
The order after (high 95.4 > xhigh 95.1 > medium 92.9 >> low 87.1) matches the blind sheet read. C1-C4 scores are x100
(INFO, scored, never WARN / FAIL). Medium loses 2 points on C4 (big plain torso panels at 25 m) and C1 (61 % of its
surface on low-sided prisms: the whip beads). A3r: every final model's strike shows the whip at >= 3 m, above the
ground (the high session's run-1 lash that hit the ground at 1.8 m was fixed before its final run; the planted
ground-lash case in `tests/test_art_lab.gd` WARNs at 1.8 m). The same low model is calibration case `vinelasher_low`
(quick runs 86.7 / 86.8 / 86.8, band 82-91).
