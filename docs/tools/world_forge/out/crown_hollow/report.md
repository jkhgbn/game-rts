# World Forge map: Crown Hollow (1v1)

**Result: PASS**, score **100 / 100** (0 FAIL, 0 WARN, 11 PASS). Hash `0d75f2d0f8e1/6976d88e4e12`. 39.9 s.

| ID | Check | Status | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS | 2 keeps, 2 seats | each seat's frame maps the canonical keep onto that seat | add `seat <team> frame=<mirror>` for every image of the symmetry |
| L2 | Spots inside the map | PASS | ok | /x/, /z/ <= size/2 - 2 | move the spot inward (map line crown_hollow.map) |
| L3 | Spot spacing | PASS | ok | >= 3 m between spots (slots / starts excepted) | a canonical spot too close to its own mirror axis doubles up: move it off the axis or onto it |
| L4 | Spot counts | INFO | keep 2, node 8, point 8, camp 8, tavern 2, post 4, guild 4, peddler 2, cache 4, lair 8, crown 1; crossings 8, roads 0, zones 0, blocks 0 | compare with the design doc's count table |  |
| N0 | Navmesh bakes | PASS | 226 polygons in 0.2 s | the preview's navmesh bakes (flat ground, river / moat / keeps / blocks as obstacles) | check the river / block lines |
| LAB | Map Lab | PASS | WARN, score 98 / 100 | Map Lab PASS / WARN and score >= 90 | open map_lab/scorecard.md: its Improve next names the spot |
| LAB.M1 | Every live spot has its mirror twins | PASS | 59 / 59 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS | 59 / 59 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS | 0.00 % (0 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS | 870 / 870 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |
| R1 | Round trip: every live spot rebuilt within 0.1 m | PASS | 51 live spots, 51 rebuilt; worst 0.000 m () | export-map -> map: same count, each spot within 0.1 m (same kind) | a live spot without an exact twin must be written `solo` |
| R2 | Round trip: Map Lab path table | INFO | not comparable yet | identical path table needs the live terrain (cliffs, forest, river banks) in the preview; the preview is flat ground + water + keeps | next: export blocks (forest clusters / cliffs) from the live navmesh so paths match |

## Improve next
- R2 Round trip: Map Lab path table: next: export blocks (forest clusters / cliffs) from the live navmesh so paths match
- Open layout.png (spots by kind, river, roads) and map_lab/heatmap.png (where paths crowd).
- Read map_lab/scorecard.md: its WARN rows (engine path noise F2 is not the map's fault) and Improve next.

## Files
- `res://data/maps/crown_hollow_layout.tres`
- `res://docs/tools/world_forge/out/crown_hollow/preview.tscn`
- `res://docs/tools/world_forge/out/crown_hollow/map_profile.json`
- `res://docs/tools/world_forge/out/crown_hollow/map_lab/scorecard.md`
- `res://docs/tools/world_forge/out/crown_hollow/map_lab/heatmap.png`
- `res://docs/tools/world_forge/out/crown_hollow/layout.png`
