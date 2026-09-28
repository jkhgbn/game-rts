# world_forge build: forge_ep3_memories_sonnet

2026-09-28 16:32:52 - `tools/world_forge/run_world_forge.ps1 build forge_ep3_memories_sonnet` - hash `d51134c8db4e`

## Result: **FAIL** - quality **83 / 100** (previous run 83, +0)

1 FAIL, 0 WARN, 8 PASS, 0 info, 0 skipped, 3 s

## Improve next
1. **Cameras clear of geometry** (FAIL): move from= / to= out of the model (see plan.png) _(from M2 Cameras clear of geometry)_

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 82 surfaces (8 particles / multimesh) | <= 90 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 2 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 126974 | <= 300000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 0 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 12 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | **FAIL** 0 | G03@0.00 inside corner_g03; G03@0.13 inside corner_g03; G03@0.25 inside corner_g03; G03@0.38 inside corner_g03; G03@0.50 inside corner_g03; G03@0.63 inside corner_g03; G03@0.75 inside corner_g03; G03@0.88 inside corner_g03; G03@1.00 inside corner_g03; G04@0.00 inside corner_g04; G04@0.13 inside corner_g04; G04@0.25 inside corner_g04; G04@0.38 inside corner_g04; G04@0.50 inside corner_g04; G04@0.63 inside corner_g04; G04@0.75 inside corner_g04; G04@0.88 inside corner_g04; G04@1.00 inside corner_g04; G06@0.00 inside corner_g04; G06@0.13 inside corner_g04; G06@0.25 inside corner_g04; G06@0.38 inside corner_g04; G06@0.50 inside corner_g04; G06@0.63 inside corner_g04; G06@0.75 inside corner_g04; G06@0.88 inside corner_g04; G06@1.00 inside corner_g04; G09@0.00 inside corner_g09; G09@0.13 inside corner_g09; G09@0.25 inside corner_g09; G09@0.38 inside corner_g09; G09@0.50 inside corner_g09; G09@0.63 inside corner_g09; G09@0.75 inside corner_g09; G09@0.88 inside corner_g09; G09@1.00 inside corner_g09; G03@0.00 within 0.9 m of candle (fills the frame); G03@0.13 within 0.9 m of candle (fills the frame); G03@0.25 within 0.9 m of candle (fills the frame); G03@0.38 within 0.9 m of candle (fills the frame); G03@0.50 within 0.9 m of candle (fills the frame); G03@0.63 within 0.9 m of candle (fills the frame); G03@0.75 within 0.9 m of candle (fills the frame); G03@0.88 within 0.9 m of candle (fills the frame); G03@1.00 within 0.9 m of candle (fills the frame); G04@0.00 within 0.9 m of corner_g03 (fills the frame); G04@0.13 within 0.9 m of corner_g03 (fills the frame); G04@0.25 within 0.9 m of corner_g03 (fills the frame); G04@0.38 within 0.9 m of corner_g03 (fills the frame); G04@0.50 within 0.9 m of corner_g03 (fills the frame); G04@0.63 within 0.9 m of corner_g03 (fills the frame); G04@0.75 within 0.9 m of corner_g03 (fills the frame); G04@0.88 within 0.9 m of corner_g03 (fills the frame); G04@1.00 within 0.9 m of corner_g03 (fills the frame); G06@0.00 within 0.9 m of corner_g03 (fills the frame); G06@0.13 within 0.9 m of corner_g03 (fills the frame); G06@0.25 within 0.9 m of corner_g03 (fills the frame); G06@0.38 within 0.9 m of corner_g03 (fills the frame); G06@0.50 within 0.9 m of corner_g03 (fills the frame); G06@0.63 within 0.9 m of corner_g03 (fills the frame); G06@0.75 within 0.9 m of corner_g03 (fills the frame); G06@0.88 within 0.9 m of corner_g03 (fills the frame); G06@1.00 within 0.9 m of corner_g03 (fills the frame) | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) | move from= / to= out of the model (see plan.png) |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | d51134c8db4e vs d51134c8db4e | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: G03_a ndc (-0.19, 0.07), G03_b ndc (-0.19, 0.07), G03_c ndc (-0.19, 0.07), G04_a ndc (-0.36, -0.20), G04_b ndc (-0.36, -0.20), G04_c ndc (-0.36, -0.20), G06_a ndc (-0.36, -0.20), G06_b ndc (-0.36, -0.20), G06_c ndc (-0.36, -0.20), G09_a ndc (-0.02, 0.28), G09_b ndc (-0.02, 0.28), G09_c ndc (-0.02, 0.28)
- Mesh file md5: ground.res 98fae612, scatter.res b86f2aa3, mountains.res 249de48a
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_ep3_memories_sonnet/forge_ep3_memories_sonnet.tscn`, `art/cinematics/stage_sets/forge_ep3_memories_sonnet/meshes/ground.res`, `art/cinematics/stage_sets/forge_ep3_memories_sonnet/meshes/scatter.res`, `art/cinematics/stage_sets/forge_ep3_memories_sonnet/meshes/mountains.res`, `art/cinematics/stage_sets/forge_ep3_memories_sonnet/marks.json`, `docs/tools/world_forge/out/forge_ep3_memories_sonnet/plan.png`
