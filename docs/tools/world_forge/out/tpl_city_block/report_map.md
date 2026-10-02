# world_forge map: tpl_city_block

2026-10-02 18:50:00 - `tools/world_forge/run_world_forge.ps1 map tpl_city_block` - hash `b085848b7afc/706c3a61b5ba`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 12 PASS, 1 info, 0 skipped, 182 s

## Improve next

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 1 keeps, 1 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (72 x 72 m) |  |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 1; crossings 0, roads 0, zones 0, blocks 4 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 99 polygons in 0.2 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 96 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 1 / 1 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 1 / 1 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 0 / 0 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 1 / 1 clean | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 0 / 0 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| LAB.R4 | Clearances (roads, crossings) | PASS 100 | 1 / 1 clean | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 0 half widths ok, 0 arms ok, 0 circles ok, 0 segments ok, 72 x 72 m ok, 1 spots ok, 0.4x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Files: `docs/tools/world_forge/out/tpl_city_block/tpl_city_block_layout.tres`, `docs/tools/world_forge/out/tpl_city_block/preview.tscn`, `docs/tools/world_forge/out/tpl_city_block/map_profile.json`, `docs/tools/world_forge/out/tpl_city_block/map_lab/scorecard.md`, `docs/tools/world_forge/out/tpl_city_block/map_lab/heatmap.png`, `docs/tools/world_forge/out/tpl_city_block/layout.png`
