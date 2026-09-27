# world_forge build: forge_intro_malrik

2026-09-27 12:32:48 - `tools/world_forge/run_world_forge.ps1 build forge_intro_malrik` - hash `74bb6280de89`

## Result: **FAIL** - quality **71 / 100**

1 FAIL, 2 WARN, 6 PASS, 0 info, 0 skipped, 12 s

## Improve next
1. **Subject inside the 2.39 band** (FAIL): aim look= closer to the subject, or raise from= y _(from M1 Subject inside the 2.39 band)_
2. **Cameras clear of geometry** (WARN): move from= / to= out of the model (see plan.png) _(from M2 Cameras clear of geometry)_
3. **Line of sight to the subject** (WARN): raise the camera or move it round the blocker _(from M3 Line of sight to the subject)_

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 187 surfaces (39 particles / multimesh) | <= 200 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 4 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 134139 | <= 400000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 111 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | **FAIL** 0 | S20_c (0.18, -0.87); S20_b (0.13, -0.65) | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c | aim look= closer to the subject, or raise from= y |
| M2 | Cameras clear of geometry | **WARN** 50 | S21@0.00 within 0.9 m of brazier (fills the frame); S21@0.13 within 0.9 m of brazier (fills the frame); S21@0.25 within 0.9 m of brazier (fills the frame); S21@0.38 within 0.9 m of brazier (fills the frame); S21@0.50 within 0.9 m of brazier (fills the frame); S21@0.63 within 0.9 m of brazier (fills the frame); S21@0.75 within 0.9 m of brazier (fills the frame); S21@0.88 within 0.9 m of brazier (fills the frame); S21@1.00 within 0.9 m of brazier (fills the frame) | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) | move from= / to= out of the model (see plan.png) |
| M3 | Line of sight to the subject | **WARN** 50 | S18_a: brazier blocks the view of malrik_young; S18_b: brazier blocks the view of malrik_young; S18_c: brazier blocks the view of malrik_young | nothing placed between the camera and the subject (bounding boxes) | raise the camera or move it round the blocker |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | 74bb6280de89 vs 74bb6280de89 | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: S09_a ndc (-0.06, 0.00), S09_b ndc (-0.07, 0.00), S09_c ndc (-0.08, 0.00), S18_a ndc (-0.00, 0.03), S18_b ndc (0.00, 0.04), S18_c ndc (-0.00, 0.04), S19_a ndc (0.12, -0.01), S19_b ndc (0.10, -0.06), S19_c ndc (0.09, -0.09), S19U_a ndc (-0.21, 0.02), S19U_b ndc (-0.27, -0.01), S19U_c ndc (-0.35, -0.04), S20_a ndc (0.10, -0.48), S20_b ndc (0.13, -0.65), S20_c ndc (0.18, -0.87), S21_a ndc (0.00, -0.28), S21_b ndc (0.00, -0.30), S21_c ndc (0.00, -0.31)
- Mesh file md5: ground.res 4074009c, paths.res cb3d81a7, scatter.res 8764608f, masonry.res 71a18a5a
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_intro_malrik/forge_intro_malrik.tscn`, `art/cinematics/stage_sets/forge_intro_malrik/meshes/ground.res`, `art/cinematics/stage_sets/forge_intro_malrik/meshes/paths.res`, `art/cinematics/stage_sets/forge_intro_malrik/meshes/scatter.res`, `art/cinematics/stage_sets/forge_intro_malrik/meshes/masonry.res`, `art/cinematics/stage_sets/forge_intro_malrik/forge_intro_malrik_lighting.tres`, `art/cinematics/stage_sets/forge_intro_malrik/marks.json`, `docs/tools/world_forge/out/forge_intro_malrik/plan.png`
