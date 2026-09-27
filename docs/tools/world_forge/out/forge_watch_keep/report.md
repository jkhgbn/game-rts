# world_forge build: forge_watch_keep

2026-09-27 08:06:34 - `tools/world_forge/run_world_forge.ps1 build forge_watch_keep` - hash `e081912a67ec`

## Result: **PASS** - quality **100 / 100**

0 FAIL, 0 WARN, 9 PASS, 0 info, 0 skipped, 8 s

## Improve next

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 118 surfaces (20 particles / multimesh) | <= 150 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 3 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 70849 | <= 400000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 68 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 12 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | e081912a67ec vs e081912a67ec | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: W01_a ndc (-0.03, 0.13), W01_b ndc (-0.02, 0.11), W01_c ndc (-0.01, 0.08), W02_a ndc (0.00, 0.03), W02_b ndc (0.00, 0.03), W02_c ndc (0.00, 0.04), W03_a ndc (0.00, 0.08), W03_b ndc (0.00, 0.08), W03_c ndc (0.00, 0.08), W04_a ndc (0.11, 0.45), W04_b ndc (0.08, 0.41), W04_c ndc (0.05, 0.36)
- Mesh file md5: ground.res 42f483e2, paths.res 67bda8d0, scatter.res f11f50c7, masonry.res 0d481713
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_watch_keep/forge_watch_keep.tscn`, `art/cinematics/stage_sets/forge_watch_keep/meshes/ground.res`, `art/cinematics/stage_sets/forge_watch_keep/meshes/paths.res`, `art/cinematics/stage_sets/forge_watch_keep/meshes/scatter.res`, `art/cinematics/stage_sets/forge_watch_keep/meshes/masonry.res`, `art/cinematics/stage_sets/forge_watch_keep/forge_watch_keep_lighting.tres`, `art/cinematics/stage_sets/forge_watch_keep/marks.json`, `docs/tools/world_forge/out/forge_watch_keep/plan.png`
