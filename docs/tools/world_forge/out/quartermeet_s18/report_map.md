# world_forge map: quartermeet_s18

2026-10-02 17:55:42 - `tools/world_forge/run_world_forge.ps1 map quartermeet_s18` - hash `1f660e4c38fc/ae183dcaec37`

## Result: **FAIL** - quality **55 / 100**

4 FAIL, 2 WARN, 9 PASS, 1 info, 0 skipped, 617 s

## Improve next
1. **Map Lab** (FAIL): open map_lab/scorecard.md: its Improve next names the spot; `run_world_forge.ps1 fix quartermeet_s18` moves fixable spots _(from LAB Map Lab)_
2. **Spots inside the map** (FAIL): move the spot inward (map line quartermeet_s18.map) _(from L2 Spots inside the map)_

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 4 keeps, 4 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | **FAIL** 0 | lairs_one_a1 (-58.70, 85.90), lairs_one_a2 (-58.70, -85.90), lairs_one_b1 (58.70, -85.90), lairs_one_b2 (58.70, 85.90) | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (168 x 168 m) | move the spot inward (map line quartermeet_s18.map) |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 4, node 20, point 16, camp 14, tavern 4, post 8, guild 16, peddler 4, cache 8, lair 8, crown 1, start 4, slot 52; crossings 6, roads 4, zones 4, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 1302 polygons in 0.4 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | **FAIL** 0 | FAIL, score 76 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) | open map_lab/scorecard.md: its Improve next names the spot; `run_world_forge.ps1 fix quartermeet_s18` moves fixable spots |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 109 / 109 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 109 / 109 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (0 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | **WARN** 50 | 8826 / 8827 pairs within 2 % (0 FAIL, 1 WARN, 0 info) | Map Lab F1 |  |
| LAB.R1 | Targets met (rules bands, per seat) | **FAIL** 0 | 18 / 24 clean (2 FAIL, 4 WARN) | Map Lab v2 R1 |  |
| LAB.R2 | Content per seat (Crown Hollow per side) | PASS 100 | 60 / 60 clean | Map Lab v2 R2 |  |
| LAB.R3 | Contested + raidable objectives per seat | PASS 100 | 4 / 4 clean | Map Lab v2 R3 |  |
| LAB.R4 | Clearances (roads, crossings) | **WARN** 50 | 91 / 103 clean (0 FAIL, 12 WARN) | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | **FAIL** 0 | 1 half widths ok, 2 arms ok, 2 circles ok, 2 segments ok, 168 x 168 m ok, 159 spots OVER, 2.0x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Forest (MapForest): 56 trees, 44 rocks, 8 pillars, hash c20fb025c731.
- Files: `data/maps/gen/quartermeet_s18_layout.tres`, `docs/tools/world_forge/out/quartermeet_s18/preview.tscn`, `docs/tools/world_forge/out/quartermeet_s18/map_profile.json`, `docs/tools/world_forge/out/quartermeet_s18/map_lab/scorecard.md`, `docs/tools/world_forge/out/quartermeet_s18/map_lab/heatmap.png`, `docs/tools/world_forge/out/quartermeet_s18/layout.png`
