# world_forge build: forge_intro_torvald

2026-09-27 14:35:56 - `tools/world_forge/run_world_forge.ps1 build forge_intro_torvald` - hash `900e65b7bfde`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 9 PASS, 0 info, 0 skipped, 51 s

## Improve next

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 209 surfaces (46 particles / multimesh) | <= 250 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 3 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 240714 | <= 600000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 74 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 21 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 900e65b7bfde vs 900e65b7bfde | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: S10_a ndc (0.00, 0.24), S10_b ndc (0.00, 0.14), S10_c ndc (0.00, 0.01), S22_a ndc (0.04, 0.19), S22_b ndc (0.04, 0.09), S22_c ndc (0.05, -0.01), S23_a ndc (-0.00, -0.10), S23_b ndc (0.00, -0.16), S23_c ndc (0.00, -0.15), S23U_a ndc (-0.35, -0.14), S23U_b ndc (-0.47, -0.20), S23U_c ndc (-0.60, -0.28), S24_a ndc (0.06, 0.11), S24_b ndc (0.06, 0.11), S24_c ndc (0.06, 0.11), S25_a ndc (0.00, -0.34), S25_b ndc (0.00, -0.35), S25_c ndc (0.00, -0.36), S25D_a ndc (-0.24, 0.22), S25D_b ndc (0.00, 0.00), S25D_c ndc (0.02, -0.24)
- Mesh file md5: ground.res 487c2b01, paths.res 5a64303a, scatter.res 1a50b392, masonry.res 99c3e771, mountains.res fddfcf80
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_intro_torvald/forge_intro_torvald.tscn`, `art/cinematics/stage_sets/forge_intro_torvald/meshes/ground.res`, `art/cinematics/stage_sets/forge_intro_torvald/meshes/paths.res`, `art/cinematics/stage_sets/forge_intro_torvald/meshes/scatter.res`, `art/cinematics/stage_sets/forge_intro_torvald/meshes/masonry.res`, `art/cinematics/stage_sets/forge_intro_torvald/meshes/mountains.res`, `art/cinematics/stage_sets/forge_intro_torvald/marks.json`, `docs/tools/world_forge/out/forge_intro_torvald/plan.png`
