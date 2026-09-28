# lens marks: ep34_opening

2026-09-28 17:41:42 - `tools/lens/run_lens.ps1 marks ep34_opening` - hash `bf4b02801d07faa4`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 22 PASS, 0 info, 0 skipped, 8 s

## Improve next

## Marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | marks file | PASS 100 | 10 shots -> docs/tools/lens/out/ep34_opening/marks.json | contract {shot: {from, to, look_from, look_to, fov_from, fov_to}} |  |

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 10 shots, 0 icon groups, 0 portraits | 0 errors |  |

## solve
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S_N02_cov | N02 ms coverage (1600x900) | PASS 100 | 0.51 (target 0.51) | +-10 % of the vocabulary target |  |
| S_N02_band | N02 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_N07_cov | N07 mcu coverage (1600x900) | PASS 100 | 0.61 (target 0.61) | +-10 % of the vocabulary target |  |
| S_N07_band | N07 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_N10_cov | N10 mcu coverage (1600x900) | PASS 100 | 0.61 (target 0.61) | +-10 % of the vocabulary target |  |
| S_N10_band | N10 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_N11_cov | N11 ms coverage (1600x900) | PASS 100 | 0.51 (target 0.51) | +-10 % of the vocabulary target |  |
| S_N11_band | N11 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_N13_cov | N13 mcu coverage (1600x900) | PASS 100 | 0.61 (target 0.61) | +-10 % of the vocabulary target |  |
| S_N13_band | N13 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_S02_cov | S02 ms coverage (1600x900) | PASS 100 | 0.60 (target 0.60) | +-10 % of the vocabulary target |  |
| S_S02_band | S02 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_S07_cov | S07 mcu coverage (1600x900) | PASS 100 | 0.69 (target 0.69) | +-10 % of the vocabulary target |  |
| S_S07_band | S07 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_S10_cov | S10 fs coverage (1600x900) | PASS 100 | 0.80 (target 0.80) | +-10 % of the vocabulary target |  |
| S_S10_band | S10 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_S11_cov | S11 ms coverage (1600x900) | PASS 100 | 0.60 (target 0.60) | +-10 % of the vocabulary target |  |
| S_S11_band | S11 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_S13_cov | S13 cu coverage (1600x900) | PASS 100 | 0.82 (target 0.82) | +-10 % of the vocabulary target |  |
| S_S13_band | S13 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |

## Notes
- Lens never edits a set: World Forge (tool 6) merges these entries into art/cinematics/stage_sets/forge_evenmead/marks.json (or calls LensSolver itself for `mark <shot> lens="..."`).
