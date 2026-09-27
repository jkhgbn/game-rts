# world_forge map: crown_hollow

2026-09-27 08:09:01 - `tools/world_forge/run_world_forge.ps1 map crown_hollow` - hash `ddbe2dda6264/6976d88e4e12`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 12 PASS, 1 info, 0 skipped, 38 s

## Improve next

## Layout
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS 100 | 2 keeps, 2 seats | each seat's frame maps the canonical keep onto that seat |  |
| L2 | Spots inside the map | PASS 100 | ok | /x/, /z/ <= size/2 - 2 |  |
| L3 | Spot spacing | PASS 100 | ok | >= 3 m between spots (slots / starts excepted) |  |
| L4 | Spot counts | INFO | keep 2, node 8, point 8, camp 8, tavern 2, post 4, guild 4, peddler 2, cache 4, lair 8, crown 1; crossings 8, roads 0, zones 0, blocks 0 | compare with the design doc's count table |  |

## Navmesh
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| N0 | Navmesh bakes | PASS 100 | 1356 polygons in 0.0 s | the preview's navmesh bakes (flat ground, river / moat / keeps / blocks as obstacles) |  |

## Map Lab
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| LAB | Map Lab | PASS 100 | WARN, score 98 / 100 | Map Lab PASS / WARN and score >= 90 |  |
| LAB.M1 | Every live spot has its mirror twins | PASS 100 | 59 / 59 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS 100 | 59 / 59 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS 100 | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS 100 | 0.03 % (64 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS 100 | 812 / 812 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |

## Round trip
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Round trip: every live spot rebuilt within 0.1 m | PASS 100 | 51 live spots, 51 rebuilt; worst 0.000 m () | export-map -> map: same count, each spot within 0.1 m (same kind) |  |
| R2 | Round trip: path table identical | PASS 100 | 1275 pairs, 0 missing, worst diff 0.000 m (camp_hollow_nw/node_shadow_rich) | every spot pair's NavigationServer path length on the rebuilt preview = the live map's (<= 0.01 m); the preview uses the exported live navmesh (`navmesh` lines) |  |

## Images
- heatmap: [map_lab/heatmap.png](map_lab/heatmap.png)
- layout: [layout.png](layout.png)

## Notes
- Files: `data/maps/crown_hollow_layout.tres`, `docs/tools/world_forge/out/crown_hollow/preview.tscn`, `docs/tools/world_forge/out/crown_hollow/map_profile.json`, `docs/tools/world_forge/out/crown_hollow/map_lab/scorecard.md`, `docs/tools/world_forge/out/crown_hollow/map_lab/heatmap.png`, `docs/tools/world_forge/out/crown_hollow/layout.png`
