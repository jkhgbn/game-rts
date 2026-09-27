# Art Lab scorecard: heath

Scene `res://art/environment/biomes/heath/heath_set.gd` · kind **decor_set** / tier **set** · kingdom neutral · ground heath · 2026-09-26 22:57:01 · lab v1.0

## Result: **WARN** · quality **89 / 100** (previous run 86, +3)

0 FAIL · 1 WARN · 9 PASS · 3 info · 0 skipped · 4 s

## Improve next
1. **Units still read on this decor** (WARN): Units drop to dE 8.0 on this decor: desaturate / darken the busiest piece _(from D8 Units still read on this decor, shot z40)_
2. **Units hidden by decor at 40 m** (PASS): Tall pieces hide up to 16% of a unit: cap them ~0.6 m or thin the clusters _(from D7 Units hidden by decor at 40 m, shot z40)_
3. **Decor coverage at 40 m** (PASS): Leave more bare ground between clumps (coverage 41%) _(from D9 Decor coverage at 40 m, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Set script loads | PASS 100 | 4 entries, biome heath | ENTRIES / BIOME_ID / GROUND_TINT (map-fill.md 10) |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B8 | Unique materials | INFO | 2 | shared nature material + contact disc expected |  |
| B13 | Patch frame cost (900 m2) | INFO | process +-0.02 ms, render CPU +0.01 ms, GPU +0.53 ms | script cost ~0 (MultiMesh, vertex-shader wind); GPU for info (soft 0.1 ms) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R5 | Glow points in the patch (12 x 12 m) | PASS 100 | 0 | <= 12 per 144 m2 (emissive decor only in its biome) |  |

## Decor set
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | Mesh kinds in the set | PASS 100 | 4 | <= 6 soft (map total <= 24 kinds, map-fill.md 9) |  |
| D2 | Triangles per decor mesh | PASS 70 | max 1186 (heath_tall_grass 315, heath_heather 880, heath_gorse 1186, heath_lichen_stones 693) | <= 1200 soft (lab default) |  |
| D3 | Shadow casters | PASS 100 | only trees / logs / big rocks cast | map-fill.md 9: only trees, logs, big rocks, landmarks, bridges cast shadows |  |
| D4 | Visibility ranges | PASS 100 | all within 65 / 90 m | tufts / flowers / pebbles <= 65 m, bushes / reeds / ferns / mushrooms <= 90 m (map-fill.md 9) |  |
| D5 | Instance budget coverage | INFO | 59.6 per 100 m2 -> the 1600-instance budget covers 2684 m2 at full weight | map-fill.md 10 instance budget per set |  |
| D7 | Units hidden by decor at 40 m | PASS 89 | worst 16% (flame_guard 0% hidden, dE 52.0; shade 16% hidden, dE 60.6; rimeshield 0% hidden, dE 45.2; thornling 0% hidden, dE 8.0) | <= 20% of a unit's silhouette (FAIL > 40%) |  |
| D8 | Units still read on this decor | **WARN** 38 | worst unit mean-colour dE 8.0 (per unit in D7) | dE >= 20 (WARN only; < 10 = that unit melts into this decor) | Keep the decor a value step away from unit colours (darker / desaturated under units) |
| D9 | Decor coverage at 40 m | PASS 93 | 41% of the ground covered | <= 55% (busy ground hides units and orders) |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 / 10 (biome sets))
`{"lights":0,"soft":{"frame_ms_patch":0.1,"kinds":6,"range":90.0,"tris_per_mesh":1200},"src":"map-fill.md 9 / 10 (biome sets)"}`

