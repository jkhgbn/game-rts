# world_forge map: ashwind_reach

2026-10-13 21:22:27 - `tools/world_forge/run_world_forge.ps1 map ashwind_reach` - hash `52c29789ee8d/1b99de566291`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 13 PASS, 1 info, 0 skipped, 6 s

## Improve next

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 2 keeps, 2 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/ <= W/2 - 2, /z/ <= D/2 - 2 (192 x 96 m) |  |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots, >= 6 m between structures (keep, tavern, peddler, post, guild, point), one den + one lodge per image (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 2, start 2, slot 20; crossings 0, roads 2, zones 2, blocks 16 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 155 polygons in 0.1 s | the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 97 / 100 | Map Lab 0 FAIL and score >= 75 (map-production.md 9) |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 2 / 2 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 2 / 2 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 0 / 0 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.03 % (40 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 1 / 1 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| LAB.R4 | Clearances (roads, crossings, spacing) | PASS 100 | 2 / 2 clean | Map Lab v2 R4 |  |
| LAB.R5 | Engine limits | PASS 100 | 0 half widths ok, 0 arms ok, 0 circles ok, 0 segments ok, 192 x 96 m ok, 2 spots ok, 1.28x ok | Map Lab v2 R5 |  |
| LAB.R6 | Mission marks / triggers / paths reachable | PASS 100 | 5 / 5 clean | Map Lab v2 R6 |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Files: `data/maps/ashwind_reach_layout.tres`, `docs/tools/world_forge/out/ashwind_reach/preview.tscn`, `docs/tools/world_forge/out/ashwind_reach/map_profile.json`, `docs/tools/world_forge/out/ashwind_reach/map_lab/scorecard.md`, `docs/tools/world_forge/out/ashwind_reach/map_lab/heatmap.png`, `docs/tools/world_forge/out/ashwind_reach/layout.png`
