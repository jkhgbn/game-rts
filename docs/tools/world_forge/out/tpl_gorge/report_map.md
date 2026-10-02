# world_forge map: tpl_gorge

2026-10-02 18:51:12 - `tools/world_forge/run_world_forge.ps1 map tpl_gorge` - hash `73952f937bdf/2d47f114974f`

## Result: **PASS** - quality **100 / 100** (previous run 71, +29)

0 FAIL, 0 WARN, 12 PASS, 1 info, 0 skipped, 342 s

## Improve next

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 1 keeps, 1 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (168 x 168 m) |  |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 1; crossings 5, roads 0, zones 0, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 121 polygons in 2.0 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | PASS, score 100 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 6 / 6 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 6 / 6 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 0 / 0 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 1 / 1 clean | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 0 / 0 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| LAB.R4 | Clearances (roads, crossings) | PASS 100 | 1 / 1 clean | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 1 half widths ok, 1 arms ok, 1 circles ok, 3 segments ok, 168 x 168 m ok, 1 spots ok, 2.0x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Files: `docs/tools/world_forge/out/tpl_gorge/tpl_gorge_layout.tres`, `docs/tools/world_forge/out/tpl_gorge/preview.tscn`, `docs/tools/world_forge/out/tpl_gorge/map_profile.json`, `docs/tools/world_forge/out/tpl_gorge/map_lab/scorecard.md`, `docs/tools/world_forge/out/tpl_gorge/map_lab/heatmap.png`, `docs/tools/world_forge/out/tpl_gorge/layout.png`
