# world_forge build: forge_intro_ysolde

2026-09-27 14:30:33 - `tools/world_forge/run_world_forge.ps1 build forge_intro_ysolde` - hash `33d60137d404`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 9 PASS, 0 info, 0 skipped, 15 s

## Improve next

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 206 surfaces (38 particles / multimesh) | <= 250 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 4 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 305066 | <= 600000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 190 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 18 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 33d60137d404 vs 33d60137d404 | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: S11_a ndc (0.00, 0.02), S11_b ndc (0.00, 0.02), S11_c ndc (0.00, 0.00), S26_a ndc (-0.06, 0.14), S26_b ndc (-0.08, 0.16), S26_c ndc (-0.09, 0.17), S27_a ndc (-0.26, -0.18), S27_b ndc (-0.22, -0.20), S27_c ndc (0.00, -0.19), S27U_a ndc (-0.30, 0.02), S27U_b ndc (-0.36, -0.01), S27U_c ndc (-0.43, -0.05), S28_a ndc (0.07, 0.06), S28_b ndc (0.08, 0.06), S28_c ndc (0.08, 0.06), S29_a ndc (0.00, 0.19), S29_b ndc (0.00, 0.21), S29_c ndc (0.00, 0.23)
- Mesh file md5: ground.res 7c78877b, paths.res 382a64a9, scatter.res c7d16696, mountains.res b6217702
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_intro_ysolde/forge_intro_ysolde.tscn`, `art/cinematics/stage_sets/forge_intro_ysolde/meshes/ground.res`, `art/cinematics/stage_sets/forge_intro_ysolde/meshes/paths.res`, `art/cinematics/stage_sets/forge_intro_ysolde/meshes/scatter.res`, `art/cinematics/stage_sets/forge_intro_ysolde/meshes/mountains.res`, `art/cinematics/stage_sets/forge_intro_ysolde/marks.json`, `docs/tools/world_forge/out/forge_intro_ysolde/plan.png`
