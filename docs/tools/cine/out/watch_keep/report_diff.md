# cine diff: watch_keep

2026-09-27 08:10:47 - `tools/cine/run_cine.ps1 diff watch_keep` - hash `102fec8ae7f336f7`

## Result: **WARN** - quality **88 / 100** (previous run 100, -13)

0 FAIL, 1 WARN, 3 PASS, 5 info, 0 skipped, 65 s

## Improve next

## Stills
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| ST1 | frames | PASS 100 | 24 frames in stills/ | 3 per shot per size |  |

## Changes vs the goldens
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| DF1 | shot S1 | INFO | minor change, frames a,b,c (max 0.48 % px: flame / particle flicker level; look at diff.png if unexpected) | <= 0.05 % of stable pixels differ by > 12 (WARN above 1.0 %) |  |
| DF2 | shot S2 | INFO | minor change, frames a,b,c (max 0.24 % px: flame / particle flicker level; look at diff.png if unexpected) | <= 0.05 % of stable pixels differ by > 12 (WARN above 1.0 %) |  |
| DF3 | shot S3 | PASS 100 | unchanged (max 0.000 % px) | <= 0.05 % of stable pixels differ by > 12 (WARN above 1.0 %) |  |
| DF4 | shot S4 | **WARN** 50 | CHANGED frames a,b,c (max 55.75 % px) | <= 0.05 % of stable pixels differ by > 12 (WARN above 1.0 %) | expected after an edit? then this run is the new reference; else look at diff.png |
| DF5 | shot S5 | INFO | minor change, frames a (max 0.06 % px: flame / particle flicker level; look at diff.png if unexpected) | <= 0.05 % of stable pixels differ by > 12 (WARN above 1.0 %) |  |
| DF6 | shot S6 | PASS 100 | unchanged (max 0.000 % px) | <= 0.05 % of stable pixels differ by > 12 (WARN above 1.0 %) |  |
| DF7 | shot S7 | INFO | minor change, frames a,b (max 0.25 % px: flame / particle flicker level; look at diff.png if unexpected) | <= 0.05 % of stable pixels differ by > 12 (WARN above 1.0 %) |  |
| DF8 | shot S8 | INFO | minor change, frames a,b,c (max 0.11 % px: flame / particle flicker level; look at diff.png if unexpected) | <= 0.05 % of stable pixels differ by > 12 (WARN above 1.0 %) |  |

## Images
- contact sheet: [stills.png](stills.png)
- diff: [diff.png](diff.png)

## Notes
- changed shots: S4; compared with docs/tools/cine/goldens/watch_keep (Visual Diff Lab vdl_diff.gd maths)
