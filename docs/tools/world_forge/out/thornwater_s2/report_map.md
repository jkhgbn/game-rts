# world_forge map: thornwater_s2

2026-10-02 17:46:29 - `tools/world_forge/run_world_forge.ps1 map thornwater_s2` - hash `d94632e960db/7bab50363ae1`

## Result: **FAIL** - quality **88 / 100**

1 FAIL, 2 WARN, 12 PASS, 1 info, 0 skipped, 516 s

## Improve next
1. **Spots inside the map** (FAIL): move the spot inward (map line thornwater_s2.map) _(from L2 Spots inside the map)_
2. **Spot spacing** (WARN): a canonical spot too close to its own mirror axis doubles up: move it off the axis or onto it _(from L3 Spot spacing)_

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 2 keeps, 2 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | **FAIL** 0 | lairs_w_two (-60.60, -10.81), lairs_w_two_twin (60.60, 10.81) | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (120 x 120 m) | move the spot inward (map line thornwater_s2.map) |
| L3 | Spot spacing | **WARN** 50 | rich_den-guilds_den 0.6 m, rich_den_twin-guilds_den_twin 0.6 m, rich_lodge-guilds_lodge 0.9 m, rich_lodge_twin-guilds_lodge_twin 0.9 m, shrine-inn_peddler 3.0 m, shrine_twin-inn_peddler_twin 3.0 m | >= 3 m between spots (slots / starts excepted) | a canonical spot too close to its own mirror axis doubles up: move it off the axis or onto it |
| L4 | Spot counts | INFO | keep 2, node 10, point 8, camp 8, tavern 2, post 4, guild 8, peddler 2, cache 4, lair 8, crown 1, start 2, slot 30; crossings 8, roads 2, zones 2, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 727 polygons in 1.3 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 95 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 65 / 65 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 65 / 65 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (1 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 1056 / 1056 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| LAB.R1 | Targets met (rules bands, per seat) | PASS 100 | 8 / 8 clean | Map Lab v2 R1 |  |
| LAB.R2 | Content per seat (Crown Hollow per side) | PASS 100 | 30 / 30 clean | Map Lab v2 R2 |  |
| LAB.R3 | Contested + raidable objectives per seat | PASS 100 | 2 / 2 clean | Map Lab v2 R3 |  |
| LAB.R4 | Clearances (roads, crossings) | **WARN** 50 | 53 / 57 clean (0 FAIL, 4 WARN) | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 89 spots ok, 1.0x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Forest (MapForest): 44 trees, 8 rocks, 8 pillars, hash 74d996ad90f4.
- Files: `data/maps/gen/thornwater_s2_layout.tres`, `docs/tools/world_forge/out/thornwater_s2/preview.tscn`, `docs/tools/world_forge/out/thornwater_s2/map_profile.json`, `docs/tools/world_forge/out/thornwater_s2/map_lab/scorecard.md`, `docs/tools/world_forge/out/thornwater_s2/map_lab/heatmap.png`, `docs/tools/world_forge/out/thornwater_s2/layout.png`
