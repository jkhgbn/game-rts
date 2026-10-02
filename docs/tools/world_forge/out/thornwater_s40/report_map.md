# world_forge map: thornwater_s40

2026-10-02 18:12:53 - `tools/world_forge/run_world_forge.ps1 map thornwater_s40` - hash `d1ec0d419fde/97fc7e45f9a9`

## Result: **FAIL** - quality **64 / 100** (previous run 62, +2)

3 FAIL, 0 WARN, 12 PASS, 1 info, 0 skipped, 371 s

## Improve next
1. **Map Lab** (FAIL): open map_lab/scorecard.md: its Improve next names the spot; `run_world_forge.ps1 fix thornwater_s40` moves fixable spots _(from LAB Map Lab)_
2. **Spots inside the map** (FAIL): move the spot inward (map line thornwater_s40.map) _(from L2 Spots inside the map)_

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 2 keeps, 2 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | **FAIL** 0 | rich_den (-59.11, -40.91), rich_den_twin (59.11, 40.91), rich_hollow (-60.61, -49.84), rich_hollow_twin (60.61, 49.84) | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (120 x 120 m) | move the spot inward (map line thornwater_s40.map) |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 2, node 10, point 8, camp 8, tavern 2, post 4, guild 8, peddler 2, cache 4, lair 8, crown 1, start 2, slot 30; crossings 8, roads 2, zones 2, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 856 polygons in 1.5 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | **FAIL** 0 | FAIL, score 88 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) | open map_lab/scorecard.md: its Improve next names the spot; `run_world_forge.ps1 fix thornwater_s40` moves fixable spots |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 65 / 65 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 65 / 65 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.00 % (4 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | **FAIL** 0 | 1055 / 1056 pairs within 2 % (1 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| LAB.R1 | Targets met (rules bands, per seat) | PASS 100 | 8 / 8 clean | Map Lab v2 R1 |  |
| LAB.R2 | Content per seat (Crown Hollow per side) | PASS 100 | 30 / 30 clean | Map Lab v2 R2 |  |
| LAB.R3 | Contested + raidable objectives per seat | PASS 100 | 2 / 2 clean | Map Lab v2 R3 |  |
| LAB.R4 | Clearances (roads, crossings) | PASS 100 | 57 / 57 clean | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 89 spots ok, 1.0x ok | Map Lab v2 R5 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Forest (MapForest): 70 trees, 6 rocks, 8 pillars, hash f70ec922fed6.
- Files: `data/maps/gen/thornwater_s40_layout.tres`, `docs/tools/world_forge/out/thornwater_s40/preview.tscn`, `docs/tools/world_forge/out/thornwater_s40/map_profile.json`, `docs/tools/world_forge/out/thornwater_s40/map_lab/scorecard.md`, `docs/tools/world_forge/out/thornwater_s40/map_lab/heatmap.png`, `docs/tools/world_forge/out/thornwater_s40/layout.png`
