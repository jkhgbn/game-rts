# world_forge build: forge_ep4_memories

2026-09-28 16:47:18 - `tools/world_forge/run_world_forge.ps1 build forge_ep4_memories` - hash `3c2fec429205`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 9 PASS, 0 info, 0 skipped, 2 s

## Improve next

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 116 surfaces (22 particles / multimesh) | <= 150 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 2 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 157891 | <= 700000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 85 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 15 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 3c2fec429205 vs 3c2fec429205 | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: H03_a ndc (0.00, -0.01), H03_b ndc (0.00, -0.00), H03_c ndc (0.00, 0.01), H04_a ndc (0.00, -0.01), H04_b ndc (0.00, -0.00), H04_c ndc (0.00, 0.01), H05_a ndc (-0.05, -0.21), H05_b ndc (-0.05, -0.22), H05_c ndc (-0.05, -0.23), H08_a ndc (-0.05, 0.10), H08_b ndc (-0.04, 0.13), H08_c ndc (-0.02, 0.16), H09_a ndc (0.01, -0.02), H09_b ndc (0.00, 0.00), H09_c ndc (-0.02, 0.03)
- Mesh file md5: ground.res 5357ee8a, scatter.res 284cc726, mountains.res ba384661
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_ep4_memories/forge_ep4_memories.tscn`, `art/cinematics/stage_sets/forge_ep4_memories/meshes/ground.res`, `art/cinematics/stage_sets/forge_ep4_memories/meshes/scatter.res`, `art/cinematics/stage_sets/forge_ep4_memories/meshes/mountains.res`, `art/cinematics/stage_sets/forge_ep4_memories/marks.json`, `docs/tools/world_forge/out/forge_ep4_memories/plan.png`
