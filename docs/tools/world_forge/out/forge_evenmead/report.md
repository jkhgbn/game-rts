# world_forge build: forge_evenmead

2026-09-28 17:02:27 - `tools/world_forge/run_world_forge.ps1 build forge_evenmead` - hash `58787cbde480`

## Result: **WARN** - quality **92 / 100** (previous run 92, +0)

0 FAIL, 1 WARN, 9 PASS, 0 info, 0 skipped, 6 s

## Improve next
1. **Subject inside the 2.39 band** (WARN): aim look= closer to the subject, or raise from= y _(from M1 Subject inside the 2.39 band)_

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 286 surfaces (35 particles / multimesh) | <= 300 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 4 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 960291 | <= 2600000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 0 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | **WARN** 50 | N13_c (-0.01, -0.72) | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c | aim look= closer to the subject, or raise from= y |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 58787cbde480 vs 58787cbde480 | same spec + seed = the same layout (every transform) |  |

## other
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | Placements on flat enough ground | PASS 100 | 11 placements; terrain 234x214 cells of 1.50 m, y -2.8..32.2 | slope under every place / actor <= 12 deg |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: B01_a ndc (-0.14, -0.40), B01_b ndc (-0.27, -0.46), B01_c ndc (-0.58, -0.52), N05_a ndc (0.34, 0.10), N05_b ndc (0.35, 0.10), N05_c ndc (0.05, 0.22), N12_a ndc (0.14, 0.24), N12_b ndc (0.14, 0.24), N12_c ndc (0.14, 0.24), B14_a ndc (-0.16, -0.18), B14_b ndc (-0.18, -0.20), B14_c ndc (-0.20, -0.20), S06_a ndc (0.35, 0.07), S06_b ndc (0.35, -0.09), S06_c ndc (-0.07, -0.39), S12_a ndc (0.00, 0.00), S12_b ndc (0.00, 0.00), S12_c ndc (0.00, 0.00), B14R_a ndc (0.12, 0.12), B14R_b ndc (0.14, 0.13), B14R_c ndc (0.16, 0.14), N02_a ndc (0.33, -0.16), N02_b ndc (0.36, -0.18), N02_c ndc (0.41, -0.20), N07_a ndc (0.34, -0.33), N07_b ndc (0.34, -0.33), N07_c ndc (0.34, -0.33), N10_a ndc (0.00, 0.01), N10_b ndc (0.00, 0.01), N10_c ndc (0.00, 0.01), N11_a ndc (0.46, -0.16), N11_b ndc (0.46, -0.16), N11_c ndc (0.46, -0.16), N13_a ndc (-0.00, -0.51), N13_b ndc (-0.00, -0.59), N13_c ndc (-0.01, -0.72), S02_a ndc (0.28, -0.03), S02_b ndc (0.31, -0.03), S02_c ndc (0.34, -0.04), S07_a ndc (0.26, -0.15), S07_b ndc (0.26, -0.15), S07_c ndc (0.26, -0.15), S10_a ndc (0.31, 0.03), S10_b ndc (0.31, 0.03), S10_c ndc (0.31, 0.03), S11_a ndc (0.48, -0.07), S11_b ndc (0.48, -0.07), S11_c ndc (0.48, -0.07), S13_a ndc (0.02, -0.36), S13_b ndc (0.02, -0.42), S13_c ndc (0.02, -0.52)
- Mesh file md5: terrain_shape.res 824b3262, ground.res 4dca4ad5, mountains.res d3b11524
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_evenmead/forge_evenmead.tscn`, `art/cinematics/stage_sets/forge_evenmead/meshes/terrain_shape.res`, `art/cinematics/stage_sets/forge_evenmead/meshes/ground.res`, `art/cinematics/stage_sets/forge_evenmead/meshes/mountains.res`, `art/cinematics/stage_sets/forge_evenmead/marks.json`, `docs/tools/world_forge/out/forge_evenmead/plan.png`
