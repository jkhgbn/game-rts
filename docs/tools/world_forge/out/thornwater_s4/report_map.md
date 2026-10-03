# world_forge map: thornwater_s4

2026-10-03 01:23:07 - `tools/world_forge/run_world_forge.ps1 map thornwater_s4` - hash `7eb04dc8e134/e86429840f28`

## Result: **WARN** - quality **98 / 100**

0 FAIL, 1 WARN, 14 PASS, 1 info, 0 skipped, 4107 s

## Improve next

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 2 keeps, 2 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (120 x 120 m) |  |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots, >= 6 m between structures (keep, tavern, peddler, post, guild, point), one den + one lodge per image (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 2, node 8, point 8, camp 6, tavern 2, post 4, guild 4, peddler 2, cache 4, lair 8, crown 1, start 2, slot 28; crossings 8, roads 2, zones 2, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 691 polygons in 3.5 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 96 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 57 / 57 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 57 / 57 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 812 / 812 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| LAB.R1 | Targets met (rules bands, per seat) | PASS 100 | 8 / 8 clean | Map Lab v2 R1 |  |
| LAB.R2 | Content per seat (Crown Hollow per side) | PASS 100 | 30 / 30 clean | Map Lab v2 R2 |  |
| LAB.R3 | Contested + raidable objectives per seat | PASS 100 | 2 / 2 clean | Map Lab v2 R3 |  |
| LAB.R4 | Clearances (roads, crossings, spacing) | **WARN** 50 | 45 / 49 clean (0 FAIL, 4 WARN) | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 49 spots ok, 1.00x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Forest (MapForest): 40 trees, 8 rocks, 8 pillars, hash fbe8d2051809.
- Files: `data/maps/gen/thornwater_s4_layout.tres`, `docs/tools/world_forge/out/thornwater_s4/preview.tscn`, `docs/tools/world_forge/out/thornwater_s4/map_profile.json`, `docs/tools/world_forge/out/thornwater_s4/map_lab/scorecard.md`, `docs/tools/world_forge/out/thornwater_s4/map_lab/heatmap.png`, `docs/tools/world_forge/out/thornwater_s4/layout.png`
