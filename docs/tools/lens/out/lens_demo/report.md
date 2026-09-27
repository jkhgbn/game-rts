# lens check: lens_demo

2026-09-27 08:48:30 - `tools/lens/run_lens.ps1 check lens_demo` - hash `08536558bef3ae04` (2 stagings within 38.9 mm (idle animation phase))

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 7 PASS, 1 info, 0 skipped, 1 s

## Improve next
1. **Measure it** (IDEA): run `run_lens.ps1 shoot lens_demo` to confirm the predicted framing from pixels _(from lens)_

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 2 shots, 0 icon groups, 0 portraits | 0 errors |  |

## Solved framing (predicted from bounds)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S_L1_cov | L1 mcu coverage (1600x900) | PASS 100 | 0.71 (target 0.71) | +-10 % of the vocabulary target |  |
| S_L1_band | L1 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_L2_cov | L2 ms coverage (1600x900) | PASS 100 | 0.44 (target 0.44) | +-10 % of the vocabulary target |  |
| S_L2_band | L2 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |

## Icon / portrait subjects
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| I0 | icon / portrait lines | INFO | none | - |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | solver (same bounds, 2 solves) | PASS 100 | identical bytes | a pure function |  |
| D2 | two stagings | PASS 100 | 08536558bef3ae04 / 1f1b21852e48d7ce, worst 38.9 mm (L1) | cameras within 60 mm (models idle-sway +- 4 cm; bounds on a 1 cm grid) |  |

## Notes
- CameraSpec files: docs/tools/lens/out/lens_demo/camera_<shot>.json (first res of each shot; camera.json = the first shot). cine: `cam=lens "<words>" lens_spec=res://docs/tools/lens/out/lens_demo/camera_<shot>.json`
- Coverage s = reference height / band height (head for ecu cu mcu, body for ms cowboy fs ws ews); targets in LensSolver.SIZES; pixels are measured by `shoot` (windowed).
