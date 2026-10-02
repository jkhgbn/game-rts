# world_forge map: quartermeet_s25

2026-10-02 19:00:23 - `tools/world_forge/run_world_forge.ps1 map quartermeet_s25` - hash `d8f9a7fa4bd4/4b00610fcf46`

## Result: **FAIL** - quality **70 / 100** (previous run 68, +2)

2 FAIL, 0 WARN, 13 PASS, 1 info, 0 skipped, 752 s

## Improve next
1. **Map Lab** (FAIL): open map_lab/scorecard.md: its Improve next names the spot; `run_world_forge.ps1 fix quartermeet_s25` moves fixable spots _(from LAB Map Lab)_

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 4 keeps, 4 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (176 x 176 m) |  |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 4, node 20, point 16, camp 10, tavern 4, post 8, guild 8, peddler 4, cache 8, lair 8, crown 1, start 4, slot 52; crossings 6, roads 4, zones 4, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 1017 polygons in 0.4 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | **FAIL** 0 | FAIL, score 87 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) | open map_lab/scorecard.md: its Improve next names the spot; `run_world_forge.ps1 fix quartermeet_s25` moves fixable spots |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 97 / 97 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 97 / 97 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (0 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 6982 / 6982 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| LAB.R1 | Targets met (rules bands, per seat) | **FAIL** 0 | 16 / 24 clean (4 FAIL, 4 WARN) | Map Lab v2 R1 |  |
| LAB.R2 | Content per seat (Crown Hollow per side) | PASS 100 | 60 / 60 clean | Map Lab v2 R2 |  |
| LAB.R3 | Contested + raidable objectives per seat | PASS 100 | 4 / 4 clean | Map Lab v2 R3 |  |
| LAB.R4 | Clearances (roads, crossings) | PASS 100 | 91 / 91 clean | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 2 circles ok, 2 segments ok, 176 x 176 m ok, 91 spots ok, 2.2x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Forest (MapForest): 16 trees, 44 rocks, 8 pillars, hash f74cd1de8535.
- Files: `data/maps/gen/quartermeet_s25_layout.tres`, `docs/tools/world_forge/out/quartermeet_s25/preview.tscn`, `docs/tools/world_forge/out/quartermeet_s25/map_profile.json`, `docs/tools/world_forge/out/quartermeet_s25/map_lab/scorecard.md`, `docs/tools/world_forge/out/quartermeet_s25/map_lab/heatmap.png`, `docs/tools/world_forge/out/quartermeet_s25/layout.png`
