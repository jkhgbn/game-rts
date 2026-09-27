# World Forge map: Fourfold Hollow (2v2)

**Result: PASS**, score **100 / 100** (0 FAIL, 0 WARN, 10 PASS). Hash `12c62c06b891/17c01a78162c`. 132.7 s.

| ID | Check | Status | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | One keep per seat | PASS | 4 keeps, 4 seats | each seat's frame maps the canonical keep onto that seat | add `seat <team> frame=<mirror>` for every image of the symmetry |
| L2 | Spots inside the map | PASS | ok | /x/, /z/ <= size/2 - 2 | move the spot inward (map line fourfold_hollow.map) |
| L3 | Spot spacing | PASS | ok | >= 3 m between spots (slots / starts excepted) | a canonical spot too close to its own mirror axis doubles up: move it off the axis or onto it |
| L4 | Spot counts | INFO | keep 4, node 24, point 10, camp 12, tavern 4, post 8, guild 4, peddler 4, cache 6, lair 8, crown 1, start 4, slot 8; crossings 10, roads 8, zones 8, blocks 0 | compare with the design doc's count table |  |
| N0 | Navmesh bakes | PASS | 235 polygons in 0.3 s | the preview's navmesh bakes (flat ground, river / moat / keeps / blocks as obstacles) | check the river / block lines |
| LAB | Map Lab | PASS | WARN, score 98 / 100 | Map Lab PASS / WARN and score >= 90 | open map_lab/scorecard.md: its Improve next names the spot |
| LAB.M1 | Every live spot has its mirror twins | PASS | 95 / 95 clean | Map Lab M1 |  |
| LAB.M4 | Spots meet the navmesh at mirrored points | PASS | 95 / 95 clean | Map Lab M4 |  |
| LAB.M2 | Spot constants mirror | PASS | 1 / 1 clean | Map Lab M2 |  |
| LAB.M3 | Navmesh mirrors itself | PASS | 0.00 % (0 cells), 0.00 % (0 cells), 0.00 % (4 cells) | Map Lab M3 |  |
| LAB.F1 | Map geometry: path pairs match their mirror twins | PASS | 6693 / 6693 pairs within 2 % (0 FAIL, 0 WARN, 0 info) | Map Lab F1 |  |

## Improve next
- Open layout.png (spots by kind, river, roads) and map_lab/heatmap.png (where paths crowd).
- Read map_lab/scorecard.md: its WARN rows (engine path noise F2 is not the map's fault) and Improve next.

## Files
- `res://data/maps/fourfold_hollow_layout.tres`
- `res://docs/tools/world_forge/out/fourfold_hollow/preview.tscn`
- `res://docs/tools/world_forge/out/fourfold_hollow/map_profile.json`
- `res://docs/tools/world_forge/out/fourfold_hollow/map_lab/scorecard.md`
- `res://docs/tools/world_forge/out/fourfold_hollow/map_lab/heatmap.png`
- `res://docs/tools/world_forge/out/fourfold_hollow/layout.png`
