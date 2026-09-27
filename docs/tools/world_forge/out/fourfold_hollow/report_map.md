# world_forge map: fourfold_hollow

2026-09-27 08:10:14 - `tools/world_forge/run_world_forge.ps1 map fourfold_hollow` - hash `12c62c06b891/17c01a78162c`

## Result: **PASS** - quality **100 / 100**

0 FAIL, 0 WARN, 10 PASS, 1 info, 0 skipped, 141 s

## Improve next

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 4 keeps, 4 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/, /z/ <= size/2 - 2 |  |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 4, node 24, point 10, camp 12, tavern 4, post 8, guild 4, peddler 4, cache 6, lair 8, crown 1, start 4, slot 8; crossings 10, roads 8, zones 8, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 235 polygons in 0.3 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 98 / 100 | Map Lab PASS / WARN and score >= 90 |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 95 / 95 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 95 / 95 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (4 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 6693 / 6693 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Files: `data/maps/fourfold_hollow_layout.tres`, `docs/tools/world_forge/out/fourfold_hollow/preview.tscn`, `docs/tools/world_forge/out/fourfold_hollow/map_profile.json`, `docs/tools/world_forge/out/fourfold_hollow/map_lab/scorecard.md`, `docs/tools/world_forge/out/fourfold_hollow/map_lab/heatmap.png`, `docs/tools/world_forge/out/fourfold_hollow/layout.png`
