# lens check: two_wizards

2026-09-27 08:32:39 - `tools/lens/run_lens.ps1 check two_wizards` - hash `4a1ee37403cef145` (2 stagings within 37.9 mm (idle animation phase))

## Result: **PASS** - quality **100 / 100**

0 FAIL, 0 WARN, 12 PASS, 1 info, 0 skipped, 2 s

## Improve next
1. **Measure it** (IDEA): run `run_lens.ps1 shoot two_wizards` to confirm the predicted framing from pixels _(from lens)_

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 4 shots, 1 icon groups, 1 portraits | 0 errors |  |

## Solved framing (predicted from bounds)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S_V1_cov | V1 mcu coverage (1600x900) | PASS 100 | 0.71 (target 0.71) | +-10 % of the vocabulary target |  |
| S_V1_band | V1 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_V2_cov | V2 cowboy coverage (1600x900) | PASS 100 | 0.58 (target 0.58) | +-10 % of the vocabulary target |  |
| S_V2_band | V2 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_V3_cov | V3 mcu coverage (1600x900) | PASS 100 | 0.54 (target 0.54) | +-10 % of the vocabulary target |  |
| S_V3_band | V3 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |
| S_V4_cov | V4 ms coverage (1600x900) | PASS 100 | 0.63 (target 0.63) | +-10 % of the vocabulary target |  |
| S_V4_band | V4 faces in band (predicted) | PASS 100 | all in | every framed face inside the 2.39 band |  |

## Icon / portrait subjects
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| I1 | icon / portrait scenes resolve | PASS 100 | 2 scenes | every res:// path exists |  |
| I2 | data ids without an icon (Data Lab view) | INFO | 13: units/bristleback, units/duskwing_roc, units/elder_grizzlemaw, units/gloomcap_elder, units/gloomcap_sprout, units/greymane_direwolf, units/grizzlemaw, units/hollow_stag, units/ironhide_tusker, units/mirefang, units/moonpelt_direwolf, units/old_scarback, units/stormcrest_roc | every UnitType / BuildingType has an icon |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | solver (same bounds, 2 solves) | PASS 100 | identical bytes | a pure function |  |
| D2 | two stagings | PASS 100 | 4a1ee37403cef145 / 29a1902fe4754c25, worst 37.9 mm (V2) | cameras within 60 mm (models idle-sway +- 4 cm; bounds on a 1 cm grid) |  |

## Notes
- CameraSpec files: docs/tools/lens/out/two_wizards/camera_<shot>.json (first res of each shot; camera.json = the first shot). cine: `cam=lens "<words>" lens_spec=res://docs/tools/lens/out/two_wizards/camera_<shot>.json`
- Coverage s = reference height / band height (head for ecu cu mcu, body for ms cowboy fs ws ews); targets in LensSolver.SIZES; pixels are measured by `shoot` (windowed).
