# world_forge map: thornwater

2026-10-02 19:11:36 - `tools/world_forge/run_world_forge.ps1 map thornwater` - hash `71462d2eabe5/7bc72982d5a0`

## Result: **WARN** - quality **95 / 100** (previous run 97, -2)

0 FAIL, 2 WARN, 13 PASS, 1 info, 0 skipped, 89 s

## Improve next
1. **Spot spacing** (WARN): a canonical spot too close to its own mirror axis doubles up: move it off the axis or onto it _(from L3 Spot spacing)_

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 2 keeps, 2 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (120 x 120 m) |  |
| L3 | Spot spacing | **WARN** 50 | rich_den-guilds_den 1.9 m, rich_den_twin-guilds_den_twin 1.9 m, rich_lodge-guilds_lodge 1.0 m, rich_lodge_twin-guilds_lodge_twin 1.0 m, shrine-inn_peddler 2.3 m, shrine_twin-inn_peddler_twin 2.3 m | >= 3 m between spots (slots / starts excepted) | a canonical spot too close to its own mirror axis doubles up: move it off the axis or onto it |
| L4 | Spot counts | INFO | keep 2, node 10, point 8, camp 8, tavern 2, post 4, guild 8, peddler 2, cache 4, lair 8, crown 1, start 2, slot 30; crossings 8, roads 2, zones 2, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 945 polygons | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 93 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 65 / 65 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 65 / 65 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | layout thornwater | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | **WARN** 50 | 1047 / 1056 pairs within 2 % (0 FAIL, 9 WARN, 0 info) | Map Lab F1 |  |
| LAB.R1 | Targets met (rules bands, per seat) | PASS 100 | 8 / 8 clean | Map Lab v2 R1 |  |
| LAB.R2 | Content per seat (Crown Hollow per side) | PASS 100 | 30 / 30 clean | Map Lab v2 R2 |  |
| LAB.R3 | Contested + raidable objectives per seat | PASS 100 | 2 / 2 clean | Map Lab v2 R3 |  |
| LAB.R4 | Clearances (roads, crossings) | PASS 100 | 57 / 57 clean | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 57 spots ok, 1.0x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- live=1: the Map Lab ran on res://scenes/layout_level.tscn with this layout (sim mode, bots off).
- Forest (MapForest): 26 trees, 8 rocks, 8 pillars, hash db5973a70cf2.
- Files: `data/maps/thornwater_layout.tres`, `docs/tools/world_forge/out/thornwater/preview.tscn`, `docs/tools/world_forge/out/thornwater/map_profile.json`, `docs/tools/world_forge/out/thornwater/map_lab/scorecard.md`, `docs/tools/world_forge/out/thornwater/map_lab/heatmap.png`, `docs/tools/world_forge/out/thornwater/layout.png`
