# world_forge map: quartermeet_s11

2026-10-02 18:24:41 - `tools/world_forge/run_world_forge.ps1 map quartermeet_s11` - hash `52e0f621b0ec/5835ae1c65c7`

## Result: **FAIL** - quality **64 / 100**

3 FAIL, 0 WARN, 12 PASS, 1 info, 0 skipped, 1053 s

## Improve next
1. **Map Lab** (FAIL): open map_lab/scorecard.md: its Improve next names the spot; `run_world_forge.ps1 fix quartermeet_s11` moves fixable spots _(from LAB Map Lab)_
2. **Spots inside the map** (FAIL): move the spot inward (map line quartermeet_s11.map) _(from L2 Spots inside the map)_

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 4 keeps, 4 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | **FAIL** 0 | lairs_one_a1 (-60.40, 90.80), lairs_one_a2 (-60.40, -90.80), lairs_one_b1 (60.40, -90.80), lairs_one_b2 (60.40, 90.80) | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (176 x 176 m) | move the spot inward (map line quartermeet_s11.map) |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 4, node 20, point 16, camp 10, tavern 4, post 8, guild 8, peddler 4, cache 8, lair 8, crown 1, start 4, slot 52; crossings 6, roads 4, zones 4, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 1195 polygons in 3.3 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | **FAIL** 0 | FAIL, score 89 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) | open map_lab/scorecard.md: its Improve next names the spot; `run_world_forge.ps1 fix quartermeet_s11` moves fixable spots |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 97 / 97 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 97 / 97 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (6 cells), 0.00 % (6 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 6982 / 6982 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| LAB.R1 | Targets met (rules bands, per seat) | **FAIL** 0 | 20 / 24 clean (4 FAIL, 0 WARN) | Map Lab v2 R1 |  |
| LAB.R2 | Content per seat (Crown Hollow per side) | PASS 100 | 60 / 60 clean | Map Lab v2 R2 |  |
| LAB.R3 | Contested + raidable objectives per seat | PASS 100 | 4 / 4 clean | Map Lab v2 R3 |  |
| LAB.R4 | Clearances (roads, crossings) | PASS 100 | 91 / 91 clean | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 2 circles ok, 2 segments ok, 176 x 176 m ok, 91 spots ok, 2.2x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Forest (MapForest): 48 trees, 48 rocks, 8 pillars, hash d616477e6510.
- Files: `data/maps/gen/quartermeet_s11_layout.tres`, `docs/tools/world_forge/out/quartermeet_s11/preview.tscn`, `docs/tools/world_forge/out/quartermeet_s11/map_profile.json`, `docs/tools/world_forge/out/quartermeet_s11/map_lab/scorecard.md`, `docs/tools/world_forge/out/quartermeet_s11/map_lab/heatmap.png`, `docs/tools/world_forge/out/quartermeet_s11/layout.png`
