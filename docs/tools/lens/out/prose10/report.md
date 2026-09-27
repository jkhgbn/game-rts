# lens check: prose10

2026-09-27 08:42:13 - `tools/lens/run_lens.ps1 check prose10` - hash `93920152b091b5d9` (2 stagings within 62.0 mm (idle animation phase))

## Result: **WARN** - quality **99 / 100** (previous run 100, -1)

0 FAIL, 1 WARN, 22 PASS, 1 info, 0 skipped, 7 s

## Improve next
1. **Measure it** (IDEA): run `run_lens.ps1 shoot prose10` to confirm the predicted framing from pixels _(from lens)_

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 10 shots, 0 icon groups, 0 portraits | 0 errors |  |

## Solved framing (predicted from bounds)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S_P01_cov | P01 cu coverage (1600x900) | PASS 100 | 0.84 (target 0.84) | +-10 % of the vocabulary target |  |
| S_P01_band | P01 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_P02_cov | P02 mcu coverage (1600x900) | PASS 100 | 0.71 (target 0.71) | +-10 % of the vocabulary target |  |
| S_P02_band | P02 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_P03_cov | P03 ms coverage (1600x900) | PASS 100 | 0.44 (target 0.44) | +-10 % of the vocabulary target |  |
| S_P03_band | P03 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_P04_cov | P04 cowboy coverage (1600x900) | PASS 100 | 0.67 (target 0.67) | +-10 % of the vocabulary target |  |
| S_P04_band | P04 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_P05_cov | P05 fs coverage (1600x900) | PASS 100 | 0.80 (target 0.80) | +-10 % of the vocabulary target |  |
| S_P05_band | P05 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_P06_cov | P06 ws coverage (1600x900) | PASS 100 | 0.35 (target 0.35) | +-10 % of the vocabulary target |  |
| S_P06_band | P06 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_P07_cov | P07 cowboy coverage (1600x900) | PASS 100 | 0.58 (target 0.58) | +-10 % of the vocabulary target |  |
| S_P07_band | P07 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_P08_cov | P08 mcu coverage (1600x900) | PASS 100 | 0.54 (target 0.54) | +-10 % of the vocabulary target |  |
| S_P08_band | P08 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_P09_cov | P09 cu coverage (1600x900) | PASS 100 | 0.86 (target 0.86) | +-10 % of the vocabulary target |  |
| S_P09_band | P09 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_P10_cov | P10 ms coverage (1600x900) | PASS 100 | 0.63 (target 0.63) | +-10 % of the vocabulary target |  |
| S_P10_band | P10 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |

## Icon / portrait subjects
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| I0 | icon / portrait lines | INFO | none | - |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | solver (same bounds, 2 solves) | PASS 100 | identical bytes | a pure function |  |
| D2 | two stagings | **WARN** 50 | 93920152b091b5d9 / e6b104132ee987ce, worst 62.0 mm (P09) | cameras within 60 mm (models idle-sway +- 4 cm; bounds on a 1 cm grid) | a pose=...@t or a moving model changes the bounds: pose it, or give the subject a still model |

## Notes
- CameraSpec files: docs/tools/lens/out/prose10/camera_<shot>.json (first res of each shot; camera.json = the first shot). cine: `cam=lens "<words>" lens_spec=res://docs/tools/lens/out/prose10/camera_<shot>.json`
- Coverage s = reference height / band height (head for ecu cu mcu, body for ms cowboy fs ws ews); targets in LensSolver.SIZES; pixels are measured by `shoot` (windowed).
