# world_forge build: forge_hills_demo

2026-09-27 12:32:33 - `tools/world_forge/run_world_forge.ps1 build forge_hills_demo` - hash `e0da414299e5`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 10 PASS, 0 info, 0 skipped, 10 s

## Improve next

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 74 surfaces (16 particles / multimesh) | <= 150 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 3 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 111847 | <= 400000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 102 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 12 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | e0da414299e5 vs e0da414299e5 | same spec + seed = the same layout (every transform) |  |

## other
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | Placements on flat enough ground | PASS 100 | 4 placements; terrain 90x85 cells of 2.00 m, y -3.1..25.6 | slope under every place / actor <= 12 deg |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: H01_a ndc (-0.00, 0.19), H01_b ndc (0.00, 0.20), H01_c ndc (0.00, 0.21), H02_a ndc (-0.00, 0.28), H02_b ndc (-0.00, 0.28), H02_c ndc (-0.00, 0.28), H03_a ndc (0.00, 0.05), H03_b ndc (0.00, 0.05), H03_c ndc (0.00, 0.05), H04_a ndc (0.00, 0.00), H04_b ndc (0.00, -0.00), H04_c ndc (0.00, -0.00)
- Mesh file md5: terrain_shape.res b9aef2ca, ground.res 09b18891, paths.res be08256f, scatter.res acbf5664, masonry.res 555e063b, mountains.res 878bcee7, water_lake.res 1aa4e52c
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_hills_demo/forge_hills_demo.tscn`, `art/cinematics/stage_sets/forge_hills_demo/meshes/terrain_shape.res`, `art/cinematics/stage_sets/forge_hills_demo/meshes/ground.res`, `art/cinematics/stage_sets/forge_hills_demo/meshes/paths.res`, `art/cinematics/stage_sets/forge_hills_demo/meshes/scatter.res`, `art/cinematics/stage_sets/forge_hills_demo/meshes/masonry.res`, `art/cinematics/stage_sets/forge_hills_demo/meshes/mountains.res`, `art/cinematics/stage_sets/forge_hills_demo/meshes/water_lake.res`, `art/cinematics/stage_sets/forge_hills_demo/forge_hills_demo_lighting.tres`, `art/cinematics/stage_sets/forge_hills_demo/marks.json`, `docs/tools/world_forge/out/forge_hills_demo/plan.png`
