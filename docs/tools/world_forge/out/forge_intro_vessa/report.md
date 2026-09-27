# world_forge build: forge_intro_vessa

2026-09-27 14:37:24 - `tools/world_forge/run_world_forge.ps1 build forge_intro_vessa` - hash `b26ecdaf06b5`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 9 PASS, 0 info, 0 skipped, 9 s

## Improve next

## Set contract
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Set contract (prologue 2.3) | PASS 100 | all present | group, set_id, lighting, Shots markers = marks.json, begin_shot / end_shot / set_active / puppet(tag) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Draw calls | PASS 100 | 215 surfaces (37 particles / multimesh) | <= 250 (budget line) |  |
| B2 | Lights | PASS 100 | 0 visible Light3D; 4 switched off by lights=off | <= 0 (0 = the stage's LightingRig only) |  |
| B3 | Triangles | PASS 100 | 285991 | <= 600000 |  |

## Scatter
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S3 | Scatter counts | PASS 100 | 120 instances | every scatter line places its count |  |

## Camera marks
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| M1 | Subject inside the 2.39 band | PASS 100 | 18 mark phases inside /y/ <= 0.62 | subject point (actor head / place centre / look point) projects inside the central 2.39:1 band (/ndc y/ <= 0.744, PASS <= 0.62) at a / b / c |  |
| M2 | Cameras clear of geometry | PASS 100 | ok | every mark phase's camera is above the ground, outside walls / placed models (FAIL) and >= 0.9 m from them (WARN) |  |
| M3 | Line of sight to the subject | PASS 100 | ok | nothing placed between the camera and the subject (bounding boxes) |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Deterministic layout | PASS 100 | b26ecdaf06b5 vs b26ecdaf06b5 | same spec + seed = the same layout (every transform) |  |

## Images
- plan: [plan.png](plan.png)

## Notes
- Mark projections: S08_a ndc (0.00, -0.21), S08_b ndc (0.00, -0.33), S08_c ndc (-0.00, -0.52), S14_a ndc (0.00, -0.06), S14_b ndc (-0.00, -0.06), S14_c ndc (0.00, -0.07), S15_a ndc (-0.33, -0.08), S15_b ndc (-0.28, -0.08), S15_c ndc (-0.17, -0.08), S15U_a ndc (-0.40, 0.07), S15U_b ndc (-0.52, 0.05), S15U_c ndc (-0.69, 0.03), S16_a ndc (-0.02, -0.04), S16_b ndc (-0.03, -0.06), S16_c ndc (-0.04, -0.08), S17_a ndc (0.00, -0.15), S17_b ndc (0.00, -0.16), S17_c ndc (0.00, -0.17)
- Mesh file md5: ground.res f074b9c8, paths.res b22869b1, scatter.res 46bd242e, masonry.res c057c229, mountains.res f24208e5
- Art Lab decor_set: not wired yet (run `tools/art_lab/run_art_lab.ps1` on the set scene by hand); Lens stills: `sheet` verb (windowed).
- Files: `art/cinematics/stage_sets/forge_intro_vessa/forge_intro_vessa.tscn`, `art/cinematics/stage_sets/forge_intro_vessa/meshes/ground.res`, `art/cinematics/stage_sets/forge_intro_vessa/meshes/paths.res`, `art/cinematics/stage_sets/forge_intro_vessa/meshes/scatter.res`, `art/cinematics/stage_sets/forge_intro_vessa/meshes/masonry.res`, `art/cinematics/stage_sets/forge_intro_vessa/meshes/mountains.res`, `art/cinematics/stage_sets/forge_intro_vessa/marks.json`, `docs/tools/world_forge/out/forge_intro_vessa/plan.png`
