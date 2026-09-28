# world_forge build: forge_ep4_memories_sonnet

2026-09-28 16:32:10 - `tools/world_forge/run_world_forge.ps1 build forge_ep4_memories_sonnet` - hash `97c180f8e064`

## Result: **WARN** - quality **98 / 100** (previous run 98, +0)

0 FAIL, 1 WARN, 9 PASS, 0 info, 0 skipped, 2 s

## Improve next
1. **Scatter counts** (WARN): widen the area, lower gap= or count= (the area is full) _(from S3 Scatter counts)_

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 124 surfaces (13 particles / multimesh) | <= 125 (budget line) |  |
| B2 | Lights | PASS 100 | 1 visible Light3D Placed/hemlight/Fire; 1 switched off by lights=off | <= 1 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 78100 | <= 400000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | **WARN** 50 | 58 instances; short: line 47 meadow_tufts: 29 / 30, line 48 flower_patch: 2 / 10, line 49 broadleaf: 4 / 5, line 76 dead_trunk_b: 0 / 4 | every scatter line places its count | widen the area, lower gap= or count= (the area is full) |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 15 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 97c180f8e064 vs 97c180f8e064 | same spec + seed = the same layout (every transform) |  |

## other
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | Placements on flat enough ground | PASS 100 | 17 placements; terrain 90x62 cells of 2.00 m, y -0.0..18.7 | slope under every place / actor <= 12 deg |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: H03_a ndc (0.05, 0.04), H03_b ndc (0.05, 0.05), H03_c ndc (0.04, 0.06), H04_a ndc (0.03, 0.21), H04_b ndc (0.03, 0.25), H04_c ndc (0.02, 0.29), H05_a ndc (0.10, 0.06), H05_b ndc (0.12, 0.06), H05_c ndc (0.14, 0.07), H08_a ndc (0.00, -0.01), H08_b ndc (0.00, 0.00), H08_c ndc (0.00, 0.01), H09_a ndc (-0.05, 0.00), H09_b ndc (-0.03, 0.02), H09_c ndc (0.00, 0.05)
- Mesh file md5: terrain_shape.res 43da1889, ground.res 2db1cc3e, scatter.res f72fe35c, mountains.res 0e8c7828
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_ep4_memories_sonnet/forge_ep4_memories_sonnet.tscn`, `art/cinematics/stage_sets/forge_ep4_memories_sonnet/meshes/terrain_shape.res`, `art/cinematics/stage_sets/forge_ep4_memories_sonnet/meshes/ground.res`, `art/cinematics/stage_sets/forge_ep4_memories_sonnet/meshes/scatter.res`, `art/cinematics/stage_sets/forge_ep4_memories_sonnet/meshes/mountains.res`, `art/cinematics/stage_sets/forge_ep4_memories_sonnet/forge_ep4_memories_sonnet_lighting.tres`, `art/cinematics/stage_sets/forge_ep4_memories_sonnet/marks.json`, `docs/tools/world_forge/out/forge_ep4_memories_sonnet/plan.png`
