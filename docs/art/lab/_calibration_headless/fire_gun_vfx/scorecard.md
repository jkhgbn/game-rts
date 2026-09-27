# Art Lab scorecard: fire_gun_vfx

Scene `res://art/vfx/unit_fire_gun_vfx.gd` · kind **vfx** / tier **family** · kingdom fire · ground meadow · 2026-09-27 13:51:51 · lab v3.1 · **headless: render checks skipped**

## Result: **PASS** · quality **100 / 100** (100.0)

0 FAIL · 0 WARN · 7 PASS · 0 info · 1 skipped · 14 s

## Improve next
1. **Read in 0.3 s** (IDEA): A bright core in the first 0.1 s, then a slower fade; the 40 m read comes from the core + a ground ring _(from effects sheet)_
2. **Team / kingdom colour** (IDEA): Tint with the owner's glow colour, never a third tint (art-keep 0.6) _(from effects sheet)_
3. **Cost** (IDEA): Pool and reuse; no particles beyond 45 m _(from V2 / V5)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | VFX family loads | PASS 100 | 2 effect ids | play(id, at, target) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B5 | Real lights during effects | PASS 100 | max 0 | 0 (emission + bloom) |  |

## VFX family
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| V2 | Nodes created per play (after warm-up) | PASS 100 | musket_shot 0, musket_breach 0 | 0: pooled (art-units 6.10: no runtime instancing) |  |
| V3 | Leak after all effects end | PASS 100 | +0 nodes 3 s after the last effect | back to the warm pool size |  |
| V4 | Materials created per play | PASS 100 | 0 | 0 (shared materials, instance uniforms) |  |
| V5 | Peak particles / draws | PASS 100 | 0 looping particles, 5 draw instances | particles <= 200 soft, draws <= 40 soft |  |
| V6 | Visible at 40 m | SKIP | headless | needs a windowed run |  |

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 6.10 / 8, cavalry-mounts.md 11 (pooled, no runtime instancing))
`{"lights":0,"soft":{"draw":40,"frame_ms":0.02,"leak":0,"mats_per_play":0,"nodes_per_play":0,"particles":200},"src":"art-units.md 6.10 / 8, cavalry-mounts.md 11 (pooled, no runtime instancing)"}`

