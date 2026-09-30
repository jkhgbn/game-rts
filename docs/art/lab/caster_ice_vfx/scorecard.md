# Art Lab scorecard: caster_ice_vfx

Scene `res://art/vfx/caster_ice_vfx.gd` · kind **vfx** / tier **family** · kingdom ice · ground meadow · 2026-09-30 16:04:56 · lab v3.1

## Result: **PASS** · quality **100 / 100** (100.0) (previous run 100, +0)

0 FAIL · 0 WARN · 8 PASS · 1 info · 0 skipped · 88 s

## Before / after (vs the run of 2026-09-30 15:34:53 in `docs/art/lab/caster_ice_vfx`: quality 100 -> 100, +0)
### What got worse (0)
Nothing got worse.

Changed pixels per shot: effects 0.9 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Read in 0.3 s** (IDEA): A bright core in the first 0.1 s, then a slower fade; the 40 m read comes from the core + a ground ring _(from effects sheet)_
2. **Team / kingdom colour** (IDEA): Tint with the owner's glow colour, never a third tint (art-keep 0.6) _(from effects sheet)_
3. **Cost** (IDEA): Pool and reuse; no particles beyond 45 m _(from V2 / V5)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | VFX family loads | PASS 100 | 5 effect ids | play(id, at, target) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B5 | Real lights during effects | PASS 100 | max 0 | 0 (emission + bloom) |  |
| B13 | Frame cost (all ids x 3 in 1 s) | INFO | process +-1.418 ms, render CPU +0.1 ms, GPU +0.02 ms | for information |  |

## VFX family
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| V2 | Nodes created per play (after warm-up) | PASS 100 | rime_bulwark 0, rime_bulwark_shatter 0, rime_bulwark_melt 0, scrying_rune 0, scrying_rune_end 0 | 0: pooled (art-units 6.10: no runtime instancing) |  |
| V3 | Leak after all effects end | PASS 100 | +0 nodes 3 s after the last effect | back to the warm pool size |  |
| V4 | Materials created per play | PASS 100 | 0 | 0 (shared materials, instance uniforms) |  |
| V5 | Peak particles / draws | PASS 100 | 0 looping particles, 7 draw instances | particles <= 200 soft, draws <= 40 soft |  |
| V6 | Visible at 40 m | PASS 100 | every id changes >= 200 px | each effect changes >= 200 px of the 40 m frame (ids that need a unit target may show nothing here) |  |

## Shots
- effects: [effects.jpg](effects.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 6.10 / 8, cavalry-mounts.md 11 (pooled, no runtime instancing))
`{"lights":0,"soft":{"draw":40,"frame_ms":0.02,"leak":0,"mats_per_play":0,"nodes_per_play":0,"particles":200},"src":"art-units.md 6.10 / 8, cavalry-mounts.md 11 (pooled, no runtime instancing)"}`

