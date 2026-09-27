# world_forge build: forge_intro_malrik

2026-09-27 14:35:13 - `tools/world_forge/run_world_forge.ps1 build forge_intro_malrik` - hash `18ee7125b4aa`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 9 PASS, 0 info, 0 skipped, 8 s

## Improve next

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 219 surfaces (47 particles / multimesh) | <= 250 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 4 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 238475 | <= 600000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 111 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 18 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 18ee7125b4aa vs 18ee7125b4aa | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: S09_a ndc (-0.06, 0.00), S09_b ndc (-0.07, 0.00), S09_c ndc (-0.08, 0.00), S18_a ndc (-0.00, -0.15), S18_b ndc (0.00, -0.16), S18_c ndc (0.00, -0.18), S19_a ndc (0.12, -0.01), S19_b ndc (0.10, -0.06), S19_c ndc (0.09, -0.09), S19U_a ndc (-0.40, 0.06), S19U_b ndc (-0.48, 0.03), S19U_c ndc (-0.59, 0.01), S20_a ndc (-0.16, 0.33), S20_b ndc (-0.15, 0.30), S20_c ndc (-0.15, 0.27), S21_a ndc (0.00, -0.25), S21_b ndc (0.00, -0.27), S21_c ndc (0.00, -0.28)
- Mesh file md5: ground.res 4074009c, paths.res cb3d81a7, scatter.res ddf7d44c, masonry.res 7e49fc4d, mountains.res 327d8bb5
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_intro_malrik/forge_intro_malrik.tscn`, `art/cinematics/stage_sets/forge_intro_malrik/meshes/ground.res`, `art/cinematics/stage_sets/forge_intro_malrik/meshes/paths.res`, `art/cinematics/stage_sets/forge_intro_malrik/meshes/scatter.res`, `art/cinematics/stage_sets/forge_intro_malrik/meshes/masonry.res`, `art/cinematics/stage_sets/forge_intro_malrik/meshes/mountains.res`, `art/cinematics/stage_sets/forge_intro_malrik/marks.json`, `docs/tools/world_forge/out/forge_intro_malrik/plan.png`
