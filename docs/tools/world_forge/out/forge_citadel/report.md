# world_forge build: forge_citadel

2026-09-27 14:37:11 - `tools/world_forge/run_world_forge.ps1 build forge_citadel` - hash `91cd04a9dca1`

## Result: **WARN** - quality **96 / 100** (previous run 96, +0)

0 FAIL, 1 WARN, 8 PASS, 0 info, 0 skipped, 37 s

## Improve next
1. **Line of sight to the subject** (WARN): raise the camera or move it round the blocker _(from M3 Line of sight to the subject)_

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 198 surfaces (0 particles / multimesh) | <= 400 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 0 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 436456 | <= 1600000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 0 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 30 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | **WARN** 50 | S01_a: s01_veil blocks the view of summit; S01_b: s01_veil blocks the view of summit; S02_a: statue blocks the view of statue; S02_b: statue blocks the view of statue; S02_c: statue blocks the view of statue; S03_b: great_tower blocks the view of citadel; S03_c: great_tower blocks the view of citadel; S05_c: feast_table blocks the view of market; S05_c: crowd_b blocks the view of market; S05_c: crowd_a blocks the view of market; S07_a: orrery blocks the view of orrery; S07_b: orrery blocks the view of orrery; S07_c: orrery blocks the view of orrery; S12_a: throne blocks the view of throne; S12_a: shaft_red blocks the view of throne; S12_a: shaft_violet blocks the view of throne; S12_a: shaft_blue blocks the view of throne; S12_a: shaft_green blocks the view of throne; S12_b: throne blocks the view of throne; S12_b: shaft_red blocks the view of throne; S12_b: shaft_violet blocks the view of throne; S12_b: shaft_blue blocks the view of throne; S12_b: shaft_green blocks the view of throne; S12_c: throne blocks the view of throne; S12_c: shaft_red blocks the view of throne; S12_c: shaft_violet blocks the view of throne; S12_c: shaft_blue blocks the view of throne; S12_c: shaft_green blocks the view of throne; S13_a: orrery_ruin blocks the view of candle; S13_a: moss blocks the view of candle; S13_a: ruin_dress blocks the view of candle; S13_b: orrery_ruin blocks the view of candle; S13_b: moss blocks the view of candle; S13_b: ruin_dress blocks the view of candle; S13_c: orrery_ruin blocks the view of candle; S13_c: moss blocks the view of candle; S13_c: ruin_dress blocks the view of candle; S30_a: throne blocks the view of throne; S30_a: shaft_red blocks the view of throne; S30_a: shaft_violet blocks the view of throne; S30_a: shaft_blue blocks the view of throne; S30_a: shaft_green blocks the view of throne; S30_b: shaft_red blocks the view of throne; S30_b: shaft_violet blocks the view of throne; S30_b: shaft_blue blocks the view of throne; S30_b: shaft_green blocks the view of throne | nothing placed between the camera and the subject (bounding boxes) | raise the camera or move it round the blocker |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 91cd04a9dca1 vs 91cd04a9dca1 | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: S01_a ndc (-0.00, -0.39), S01_b ndc (-0.01, -0.21), S01_c ndc (-0.01, 0.07), S02_a ndc (0.00, -0.00), S02_b ndc (0.00, -0.07), S02_c ndc (0.00, -0.19), S03_a ndc (-0.00, -0.05), S03_b ndc (-0.00, -0.06), S03_c ndc (-0.00, -0.06), S04_a ndc (0.02, -0.38), S04_b ndc (0.09, -0.43), S04_c ndc (0.21, -0.58), S05_a ndc (0.00, -0.02), S05_b ndc (0.00, -0.03), S05_c ndc (-0.00, -0.10), S06_a ndc (0.00, -0.29), S06_b ndc (0.00, -0.34), S06_c ndc (0.00, -0.39), S07_a ndc (0.00, -0.39), S07_b ndc (0.00, -0.39), S07_c ndc (0.00, -0.39), S12_a ndc (0.00, 0.06), S12_b ndc (0.00, -0.27), S12_c ndc (0.00, -0.48), S13_a ndc (0.00, 0.00), S13_b ndc (0.00, 0.00), S13_c ndc (0.00, 0.00), S30_a ndc (0.00, -0.05), S30_b ndc (0.00, -0.23), S30_c ndc (0.00, -0.22)
- Mesh file md5: ground.res 48a37125, scatter.res 0e031b23, masonry.res 7bbf0db5
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_citadel/forge_citadel.tscn`, `art/cinematics/stage_sets/forge_citadel/meshes/ground.res`, `art/cinematics/stage_sets/forge_citadel/meshes/scatter.res`, `art/cinematics/stage_sets/forge_citadel/meshes/masonry.res`, `art/cinematics/stage_sets/forge_citadel/marks.json`, `docs/tools/world_forge/out/forge_citadel/plan.png`
