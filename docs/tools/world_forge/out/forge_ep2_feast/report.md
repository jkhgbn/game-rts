# world_forge build: forge_ep2_feast

2026-09-27 21:16:08 - `tools/world_forge/run_world_forge.ps1 build forge_ep2_feast` - hash `374186da5887`

## Result: **PASS** - quality **100 / 100** (previous run 96, +4)

0 FAIL, 0 WARN, 9 PASS, 0 info, 0 skipped, 7 s

## Improve next

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 101 surfaces (13 particles / multimesh) | <= 200 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 2 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 53319 | <= 400000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 46 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 42 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 374186da5887 vs 374186da5887 | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: S01_a ndc (0.00, -0.02), S01_b ndc (0.02, 0.07), S01_c ndc (0.07, 0.26), S02_a ndc (0.00, 0.00), S02_b ndc (0.00, -0.00), S02_c ndc (0.00, 0.00), S03_a ndc (-0.05, 0.20), S03_b ndc (-0.08, 0.20), S03_c ndc (-0.11, 0.20), S04_a ndc (-0.34, -0.55), S04_b ndc (-0.35, -0.58), S04_c ndc (-0.37, -0.60), S05_a ndc (0.32, 0.02), S05_b ndc (0.32, 0.02), S05_c ndc (0.32, 0.02), S06_a ndc (-0.00, 0.00), S06_b ndc (-0.00, 0.00), S06_c ndc (-0.00, 0.00), S07_a ndc (0.00, -0.00), S07_b ndc (0.00, -0.00), S07_c ndc (0.00, -0.00), S08_a ndc (0.00, 0.00), S08_b ndc (0.00, 0.00), S08_c ndc (0.00, 0.00), S09_a ndc (0.00, -0.00), S09_b ndc (0.00, -0.00), S09_c ndc (-0.00, 0.00), S10_a ndc (0.00, 0.00), S10_b ndc (0.00, 0.00), S10_c ndc (0.00, 0.00), S11_a ndc (0.00, 0.00), S11_b ndc (-0.00, -0.00), S11_c ndc (0.00, 0.00), S12_a ndc (0.00, -0.00), S12_b ndc (0.00, -0.00), S12_c ndc (0.00, -0.00), S13_a ndc (-0.00, 0.00), S13_b ndc (-0.00, 0.00), S13_c ndc (-0.00, 0.00), S14_a ndc (-0.34, 0.52), S14_b ndc (-0.28, 0.48), S14_c ndc (-0.26, 0.39)
- Mesh file md5: ground.res f64f2cce, paths.res 328b251d, scatter.res 2e45699d, masonry.res 78f0bf7c
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_ep2_feast/forge_ep2_feast.tscn`, `art/cinematics/stage_sets/forge_ep2_feast/meshes/ground.res`, `art/cinematics/stage_sets/forge_ep2_feast/meshes/paths.res`, `art/cinematics/stage_sets/forge_ep2_feast/meshes/scatter.res`, `art/cinematics/stage_sets/forge_ep2_feast/meshes/masonry.res`, `art/cinematics/stage_sets/forge_ep2_feast/forge_ep2_feast_lighting.tres`, `art/cinematics/stage_sets/forge_ep2_feast/marks.json`, `docs/tools/world_forge/out/forge_ep2_feast/plan.png`
