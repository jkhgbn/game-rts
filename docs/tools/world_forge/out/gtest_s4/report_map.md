# world_forge map: gtest_s4

2026-10-02 17:20:20 - `tools/world_forge/run_world_forge.ps1 map gtest_s4` - hash `423a096b8880/312a29a5bb73`

## Result: **FAIL** - quality **87 / 100**

1 FAIL, 3 WARN, 11 PASS, 1 info, 0 skipped, 96 s

## Improve next
1. **Spots inside the map** (FAIL): move the spot inward (map line gtest_s4.map) _(from L2 Spots inside the map)_

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 2 keeps, 2 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | **FAIL** 0 | rich_hollow (-59.59, -48.97), rich_hollow_twin (59.59, 48.97), lairs_w_two (-59.35, -3.08), lairs_w_two_twin (59.35, 3.08) | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (120 x 120 m) | move the spot inward (map line gtest_s4.map) |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 2, node 10, point 8, camp 8, tavern 2, post 4, guild 8, peddler 2, cache 4, lair 8, crown 1, start 2, slot 30; crossings 6, roads 2, zones 2, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 592 polygons in 0.2 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 89 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 63 / 63 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 63 / 63 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.01 % (11 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | **WARN** 50 | 979 / 992 pairs within 2 % (0 FAIL, 13 WARN, 0 info) | Map Lab F1 |  |
| LAB.R1 | Targets met (rules bands, per seat) | **WARN** 50 | 6 / 8 clean (0 FAIL, 2 WARN) | Map Lab v2 R1 |  |
| LAB.R2 | Content per seat (Crown Hollow per side) | PASS 100 | 30 / 30 clean | Map Lab v2 R2 |  |
| LAB.R3 | Contested + raidable objectives per seat | PASS 100 | 2 / 2 clean | Map Lab v2 R3 |  |
| LAB.R4 | Clearances (roads, crossings) | **WARN** 50 | 51 / 57 clean (0 FAIL, 6 WARN) | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 2 circles ok, 10 segments ok, 120 x 120 m ok, 89 spots ok, 1.0x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Forest (MapForest): 22 trees, 8 rocks, 8 pillars, hash e3b1134b763d.
- Files: `data/maps/gen/gtest_s4_layout.tres`, `docs/tools/world_forge/out/gtest_s4/preview.tscn`, `docs/tools/world_forge/out/gtest_s4/map_profile.json`, `docs/tools/world_forge/out/gtest_s4/map_lab/scorecard.md`, `docs/tools/world_forge/out/gtest_s4/map_lab/heatmap.png`, `docs/tools/world_forge/out/gtest_s4/layout.png`
