# world_forge map: kinhearth_vale

2026-09-27 14:53:41 - `tools/world_forge/run_world_forge.ps1 map kinhearth_vale` - hash `3b53f6f713f9/878905a4450e`

## Result: **WARN** - quality **97 / 100** (previous run 97, +0)

0 FAIL, 1 WARN, 9 PASS, 1 info, 0 skipped, 134 s

## Improve next

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 4 keeps, 4 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/, /z/ <= size/2 - 2 |  |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 4, node 16, point 14, camp 14, tavern 4, post 8, guild 4, peddler 4, cache 6, lair 8, crown 1, start 4, slot 8; crossings 6, roads 16, zones 16, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 208 polygons in 0.4 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 90 / 100 | Map Lab PASS / WARN and score >= 90 |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 89 / 89 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 89 / 89 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (0 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | **WARN** 50 | 5869 / 5870 pairs within 2 % (0 FAIL, 1 WARN, 0 info) | Map Lab F1 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Files: `data/maps/kinhearth_vale_layout.tres`, `docs/tools/world_forge/out/kinhearth_vale/preview.tscn`, `docs/tools/world_forge/out/kinhearth_vale/map_profile.json`, `docs/tools/world_forge/out/kinhearth_vale/map_lab/scorecard.md`, `docs/tools/world_forge/out/kinhearth_vale/map_lab/heatmap.png`, `docs/tools/world_forge/out/kinhearth_vale/layout.png`
