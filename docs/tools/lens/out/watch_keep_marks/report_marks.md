# lens marks: watch_keep_marks

2026-09-27 08:30:56 - `tools/lens/run_lens.ps1 marks watch_keep_marks` - hash `8b46f905410592e5`

## Result: **PASS** - quality **100 / 100** (previous run 88, +13)

0 FAIL, 0 WARN, 8 PASS, 0 info, 0 skipped, 2 s

## Improve next

## Marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | marks file | PASS 100 | 3 shots -> docs/tools/lens/out/watch_keep_marks/marks.json | contract {shot: {from, to, look_from, look_to, fov_from, fov_to}} |  |

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 3 shots, 0 icon groups, 0 portraits | 0 errors |  |

## solve
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S_L1_cov | L1 mcu coverage (1600x900) | PASS 100 | 0.71 (target 0.71) | +-10 % of the vocabulary target |  |
| S_L1_band | L1 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_L2_cov | L2 fs coverage (1600x900) | PASS 100 | 0.78 (target 0.80) | +-10 % of the vocabulary target |  |
| S_L2_band | L2 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_L3_cov | L3 ms coverage (1600x900) | PASS 100 | 0.50 (target 0.50) | +-10 % of the vocabulary target |  |
| S_L3_band | L3 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |

## Notes
- Lens never edits a set: World Forge (tool 6) merges these entries into art/cinematics/stage_sets/forge_watch_keep/marks.json (or calls LensSolver itself for `mark <shot> lens="..."`).
