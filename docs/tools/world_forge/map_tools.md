# Map tools MT1-MT7: acceptance report (2026-10-02)

Spec: `docs/design/map-production.md` 2 / 4.2 / 9 (Map Lab bar 75, auto-fix 3 rounds). Manual: `tools/world_forge/README.md`
(verbs, grammar v2, templates, Map Lab v2, runtime). Per-run reports stay in `docs/tools/world_forge/out/<id>/`.

## What exists
| Task | Built | Where |
|---|---|---|
| MT1 MapInfo | running map W x D (static); fog grid W/2 x D/2 (non-square), BuildGrid cells, river mask + unit grid, minimap (letterboxed), camera bounds, bounty / champion / bot scout checks; main.gd `_map_size()` / `_player_start()` hooks | `scripts/core/map_info.gd`, `scripts/world/fog_of_war.gd`, `main.gd` |
| MT2 LayoutLevel | any MapLayout plays: seats, keeps, starts, nodes with roles, crown + wardens, river, roads + TradeNetwork, posts, guild houses, points, camps, lairs, herds, props, blocks, the forest (MapForest = main.gd / skirmish.gd generator as data, same seeds); `bot_point` maps Commander's Crown Hollow slots; Bot Lab `--layout=` | `scripts/world/layout_level.gd`, `scripts/world/map_forest.gd`, `scenes/layout_level.tscn`, `data/maps/crown_hollow_level.map` |
| MT3 grammar v2 | `size=WxD`, `use` templates, `forest` / `grove` / `willows`, `prop`, `block kind=`, `rules`, `closed_seat`, `seat ... scripted`, overlays (`base=`, `move` / `remove` / `set`, `mark` / `trigger` / `path` / `bounds` / `light`), terrain statements (stored) | `tools/world_forge/forge_map_grammar.gd`, `forge_map.gd`, `data/maps/map_layout.gd` |
| MT4 templates | 46 `.mapt` (bases, resources, rivers, crossings, chokes, centre, points, camps, services, 9 biomes); `template all`: 46 / 46 PASS alone | `data/maps/templates/` |
| MT5 gen | `gen <id> archetype= players= tempo= biome= count= full=`: candidates -> grid pre-filter (1 m Dijkstra, water / blocks / forest walls) -> best `full` through map + Map Lab + fix -> `gen.md` + contact sheet | `tools/world_forge/forge_gen.gd`, `world_forge.gd` |
| MT6 Map Lab v2 + fix | R1 targets, R2 content, R3 contest, R4 clearances, R5 engine limits, R6 mission marks; fix moves (R1 / R4 / L2) written as `move ... # autofix` lines, 3 rounds, stop at 0 FAIL + 75 | `tools/map_lab/map_checks_v2.gd`, `forge_map.gd apply_fixes` |
| MT7 mapsheet | windowed top-down render of the dressed LayoutLevel + plan + heat map + Map Lab / travel text (2048 x 1024) + lobby preview 512 x 512 | `world_forge.gd mapsheet`, `tools/world_forge/forge_sheet.gd` |

## Acceptance
**Crown Hollow through LayoutLevel** (`crown_hollow_level.map`, tests/test_mt2_layout_level.gd PASS): 51 / 51 Map Lab spots at
0.000 m, 133 / 133 layer-1 colliders identical (hash e8fc65302bd8: same trees, rocks, pillars, landmarks, buildings), 1275-pair
NavigationServer path table identical (0.000 m), bot slots identical. Map Lab live on the LayoutLevel: WARN 97 (live
skirmish.tscn: 98; the point is R4's 4 clearance WARNs, a v2 check). Bot game (Bot Lab, normal vs normal, sim, 15:00 limit): ended
on score at 15:00 (fire 17 977 vs shadow 15 187), 0 script errors, 7 attacks, 133 kills. Perf (tests/test_mt2_perf.gd, 100
units crossing): LayoutLevel 14.25 ms vs skirmish.tscn 14.84 ms on the same busy machine: PASS.

**Generated 1v1: Thornwater** (`gen thornwater archetype=river_split players=2 tempo=standard biome=meadow count=40`, seed 26,
1 auto-fix round + 1 L2 fix, adopted as `data/maps/thornwater.map`): Map Lab preview WARN 98, **live (LayoutLevel) WARN 93,
0 FAIL**; R1 keep->enemy 115.6, natural 44.7, rich 82, crown 57.8 m; R2 30 / 30; R3 9-10 per seat. Bot game: **ended by
concede at 12:35** (fire won), 0 script errors. Perf vs skirmish.tscn: 15.11 vs 14.66 ms: PASS.
Contact sheet: `out/gen_thornwater/contact_sheet.png`; sheet: `out/thornwater/mapsheet.png`; preview `data/maps/previews/thornwater.png`.

**Generated 2v2: Quartermeet** (`gen quartermeet archetype=river_split players=4 tempo=standard biome=autumn count=40 full=2`,
seed 16, adopted as `data/maps/quartermeet.map`, 176 m fourfold): Map Lab WARN 95, 0 FAIL; R1 all 24 in band (ally 64.3 m,
enemy / ally 2.16, keep->enemy 138.7); R2 60 / 60; M3 / F1 PASS; World Forge `map quartermeet` WARN 98. Bot game (played 1v1
on seats A1 / B1: LayoutLevel plays 2 seats until step 20's 2v2 rules): **ended by concede at 21:33** (fire won, 116 / 80
kills), 0 script errors.
Note: in both generated games the losing (enemy-seat) bot ended with 0 workers and few attacks: one game each, not a balance
verdict; MT10 (bots read the layout) + the MT8 fairness matrix are the follow-up.

## Not built (next)
MT8 map gate script, MT9 MapCatalog + menu picker, MT10 bots reading the layout (today: Crown Hollow's slots moved rigidly by
`bot_point`), Skirmish2v2 on a layout (4 seats), terrain heights at runtime, archetypes gorge / mere / chasm / corridor / arena in
`gen` (river_split, open, spine exist), the 1 m Map Lab grid for big maps (2v2 Map Lab runs take ~15 min).
