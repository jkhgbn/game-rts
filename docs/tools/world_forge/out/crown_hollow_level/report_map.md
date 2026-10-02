# world_forge map: crown_hollow_level

2026-10-02 18:55:40 - `tools/world_forge/run_world_forge.ps1 map crown_hollow_level` - hash `3fce17dee01d/9efcf7c5e5d2`

## Result: **WARN** - quality **98 / 100**

0 FAIL, 1 WARN, 14 PASS, 1 info, 0 skipped, 76 s

## Improve next

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 2 keeps, 2 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (120 x 120 m) |  |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 2, node 8, point 8, camp 8, tavern 2, post 4, guild 4, peddler 2, cache 4, lair 8, crown 1, slot 48; crossings 8, roads 2, zones 0, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 1356 polygons | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 97 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 59 / 59 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 59 / 59 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | layout crown_hollow_level | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.03 % (64 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 812 / 812 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| LAB.R1 | Targets met (rules bands, per seat) | PASS 100 | 8 / 8 clean | Map Lab v2 R1 |  |
| LAB.R2 | Content per seat (Crown Hollow per side) | PASS 100 | 30 / 30 clean | Map Lab v2 R2 |  |
| LAB.R3 | Contested + raidable objectives per seat | PASS 100 | 2 / 2 clean | Map Lab v2 R3 |  |
| LAB.R4 | Clearances (roads, crossings) | **WARN** 50 | 47 / 51 clean (0 FAIL, 4 WARN) | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 51 spots ok, 1.0x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- live=1: the Map Lab ran on res://scenes/layout_level.tscn with this layout (sim mode, bots off).
- Forest (MapForest): 66 trees, 8 rocks, 8 pillars, hash c721c118e90d.
- Files: `data/maps/crown_hollow_level_layout.tres`, `docs/tools/world_forge/out/crown_hollow_level/preview.tscn`, `docs/tools/world_forge/out/crown_hollow_level/map_profile.json`, `docs/tools/world_forge/out/crown_hollow_level/map_lab/scorecard.md`, `docs/tools/world_forge/out/crown_hollow_level/map_lab/heatmap.png`, `docs/tools/world_forge/out/crown_hollow_level/layout.png`
