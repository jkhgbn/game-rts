# world_forge build: forge_ep3_memories

2026-09-28 17:38:55 - `tools/world_forge/run_world_forge.ps1 build forge_ep3_memories` - hash `5215fc25ad8d`

## Result: **PASS** - quality **100 / 100** (previous run 83, +17)

0 FAIL, 0 WARN, 9 PASS, 0 info, 0 skipped, 2 s

## Improve next

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 116 surfaces (15 particles / multimesh) | <= 150 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 1 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 81894 | <= 700000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 11 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 12 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 5215fc25ad8d vs 5215fc25ad8d | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: G03_a ndc (0.24, 0.23), G03_b ndc (0.26, 0.28), G03_c ndc (0.28, 0.35), G04_a ndc (0.00, 0.03), G04_b ndc (-0.03, 0.04), G04_c ndc (-0.06, 0.06), G06_a ndc (0.35, -0.05), G06_b ndc (0.00, 0.00), G06_c ndc (-0.52, 0.08), G09_a ndc (-0.01, 0.22), G09_b ndc (-0.01, 0.25), G09_c ndc (-0.01, 0.29)
- Mesh file md5: ground.res b869d3c6, scatter.res f21951a5, mountains.res dd5de66a
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_ep3_memories/forge_ep3_memories.tscn`, `art/cinematics/stage_sets/forge_ep3_memories/meshes/ground.res`, `art/cinematics/stage_sets/forge_ep3_memories/meshes/scatter.res`, `art/cinematics/stage_sets/forge_ep3_memories/meshes/mountains.res`, `art/cinematics/stage_sets/forge_ep3_memories/marks.json`, `docs/tools/world_forge/out/forge_ep3_memories/plan.png`
