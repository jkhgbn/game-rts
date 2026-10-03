# Review: map tools MT1-MT7 (d1599f24)

Reviewer: code review agent, 2026-10-02. This was a read-only review: no game code, data or test was changed, and
Godot was not run. I only ran read-only git commands (`git show`, `git diff d1599f24 HEAD`). None of the files in
scope changed after d1599f24, so every line number below is valid at HEAD.

Scope:
- `scripts/core/map_info.gd`
- `scripts/world/{layout_level,map_forest,fog_of_war,main,river_system,bounty_board}.gd`
- `scripts/ui/{hud,minimap,bounty_mode}.gd`
- `scripts/buildings/build_grid.gd`
- the Commander `bot_point` hook
- `tools/world_forge/*` (grammar v2, gen, fix loop, sheet) and `tools/map_lab/map_checks_v2.gd` (+ the v1 hooks)
- `data/maps/map_layout.gd` and `data/maps/templates/*.mapt`
- `thornwater` / `quartermeet` (`.map` + `_layout.tres`)
- `tools/bot_lab/lab_match.gd`
- `tests/test_map_tools.gd`, `test_mt2_layout_level.gd`, `test_mt2_perf.gd`

## Verdict

**The engine side is solid on Crown Hollow, and the regression risk for `skirmish.tscn` and the Replay Lab is low.**
The generated maps are a different story. They are fair to both seats, but four problems need fixing before more maps
are produced:

1. The ground shader still believes every map is 120 m. Any map that is not 120 m gets its border scree and canopy
   painted in the wrong place: over playable ground on maps above 120 m (Quartermeet, 176 m), and a bare cut edge on
   rush maps (112 m).
2. Thornwater, as adopted, has two Magpie Dens 1.9 m apart and two Greywater Lodges 1.0 m apart on each side, plus a
   shrine 2.3 m from the peddler. Nothing in the pipeline stopped this.
3. `bot_point` is an affine map, but Commander also feeds it relative offsets (slot shifts, wall offsets). On any map
   whose keep is not about 61 m from the centre, the bot's fallback building spots and Ice walls jump by up to about
   18 m (Quartermeet).
4. The bot's second barracks (X2) ignores the layout's `rich_hall` slot. On Quartermeet it lands about 90 m from the
   rich node.

**About the "second-seat bot lost both generated games" observation:** I checked every place where a seat or team is
mapped to a position.
- I found no slot-mapping or start-position bias.
- On a 120 m rot180 map, `bot_point` for seat 1 is the exact half-turn of seat 0's.
- The worker spawns, node roles, hubs, fog reveals and river banks are all mirrored.

What the evidence does show: n = 1 game per map, and kingdom confounded with seat (lab default `fire:shadow`, fire
always seat 0). The Crown Hollow baseline game also had fire ahead (17 977 vs 15 187). See M1.

The MT1 size plumbing checks out:
- fog grid
- BuildGrid
- river mask and unit grid
- minimap
- camera
- bounty / champion / scout checks

Crown Hollow through LayoutLevel is proven well by `test_mt2_layout_level.gd`. I found no navmesh or region timing race
(details at the end).

## Findings

### High

**H1. The ground shader's `map_half` is never set: maps that are not 120 m get the wrong border, or no skirt at all**
Where:
- `art/environment/ground.gdshader:91-93`: `uniform float map_half = 60.0`, `expand_edge = true`, `expand_to = 260`
- `ground.gdshader:165-171`: only vertices with `|v| > map_half - 0.05` are pushed out
- `ground.gdshader:771` / `:903`: the outer-ring tint and the "Border outside the map square" paint
- `art/environment/ground_material.tres:38`: `map_half = null`, so the shader default (60) applies
- Nothing in `scripts/` or `tools/` sets it (`grep map_half`: only the fog and an old test).
- `main.gd:385` now sizes the PlaneMesh to `MapInfo.size_x x size_z`, and `layout_level.gd:374` turns the Crown Hollow
  edge dressing off for every other map.

What is wrong: MT1 made the fog shader size-generic (`fog_of_war.gd:472`) but not the ground shader.

Failure scenario:
- **Quartermeet (176 m):** everything with `|x|` or `|z|` > 60 m is painted as the off-map border: scree, rock rim,
  then forest canopy from 65.5 m. That covers about 53 % of the playable area, including all four keeps (`|x| = 71.6`).
  Units walk on "forest canopy".
- **Rush maps (112 m, `SIZE_1V1["rush"]`):** the plane edge at 56 m is below 59.95, so `expand_edge` never moves it.
  The ground ends in a hard cut at 56 m with no rim, and the map dressing is off.
- Only 120 m maps (Crown Hollow, Thornwater) look right. That is why the Thornwater mapsheet looked fine. No mapsheet
  was made for Quartermeet (`out/quartermeet/` has none).

Fix:
- In `main.gd _build_ground()`, set `map_half` on the painted material (and `outer` / border math). It needs either a
  vec2 for non-square maps, or `MapInfo.half_max()` plus a separate edge clamp. Extend the vertex test to `|v| >= half_x - 0.05` / `half_z`.
- Add a test that a 168 x 150 LayoutLevel's ground material has `map_half` equal to its halves.
- Run `mapsheet quartermeet` before the next playtest.

**H2. Thornwater ships with overlapping guild houses and a shrine on the peddler; the pipeline lets L3 through**
Where:
- `data/maps/thornwater.map:11` (`use rich_pocket`: den at local (-14,-6), lodge at (-6,-14)) and `:46`
  (`use guild_pair`).
- In `thornwater_layout.tres`: `rich_den` (-52.1, -48.8) vs `guilds_den` (-52.5, -46.9) = 1.9 m, and `rich_lodge` vs
  `guilds_lodge` = 1.0 m, each with twins.
- `shrine` (-22.3, -5.4) vs `inn_peddler` (-20.6, -6.9) = 2.3 m.
- `docs/tools/world_forge/out/thornwater/report_map.md:17` lists exactly these pairs as **L3 WARN**.

What is wrong:
- (a) The candidate came from an older generator that used `rich_pocket` (`out/gen_thornwater/cand/thornwater_s26.map:10`).
  Today's `forge_gen.gd:125` writes `rich_node`, but the adopted map was never regenerated.
- (b) L3 (`forge_map.gd:662-672`) is only a WARN, and its fix hint ("too close to its own mirror axis") is wrong for
  two different spots stacked on each other.
- (c) The gen pre-filter comment says L3 is scored (`forge_gen.gd:459`), but only L2 `outside` is added to the score
  (`:460-466`).
- (d) The Map Lab v2 header promises "spots >= 3 m apart" in R4 (`map_checks_v2.gd:10-11`), but `_r4_clearances` never
  checks it.

Failure scenario: each Thornwater side gets 2 Magpie Dens and 2 Lodges. The `GuildHouse` colliders interpenetrate, the
`MagpieDenNorthWest` / `GreywaterLodgeNorthWest` names collide (`layout_level.gd:693-694`; Godot auto-renames), and the
Thieves' and Hunters' guild services see twice the houses. The shrine capture ring overlaps the peddler counter. The
map passed with WARN 93, 0 FAIL.

Fix:
- Remove `use guild_pair` from `thornwater.map` (`rich_pocket` already brings both houses), or switch it to
  `rich_node`, then recompile.
- Make L3 a FAIL for building kinds (guild, post, tavern, peddler, keep, node, point, camp) under 3 m, and correct the
  hint text.
- Score `close` pairs in `score_layout`.
- Implement the R4 spacing check, or drop the claim from the header.

**H3. `bot_point` is affine, but Commander feeds it relative offsets too**
Where:
- `layout_level.gd:292-295`: `bot_point(p) = frame * (R * (-p - CH_KEEP) + canon_keep)`
- `commander.gd:3228-3231`: `_side()` delegates to it
- Offset uses:
  - `commander.gd:1524-1525`: `var p := base + _side(shift)` with `SLOT_SHIFTS` (4 m, `:185`)
  - `commander.gd:1552`: wall spot = `S1.global_position + _side(row["pos"])` with `WALL_OFFSETS` (±2 m, `:212`)

What is wrong: on Crown Hollow, `canon_keep == CH_KEEP` and `R = I`, so the translation cancels (hence the test
passes). On any other map, `_side(offset)` = `R * (-offset) + T` with `T = canon_keep - R * CH_KEEP`.

Failure scenario:
- **Quartermeet** (keep (-71.6, 32.4), turn ≈ -20.7°, |T| ≈ 17.8 m):
  - The "shift the slot by 4 m" retry becomes base + (-14.8, 0, 3.6), a 15 m jump toward the west edge.
  - Ice walls `W1` / `W2` land about 16 m from the S1 tower instead of ±2 m, or are skipped by the path-ratio test.
- **Generated rush (112 m, keep r ≈ 51 m) and macro (144 m, r ≈ 77 m) 1v1 maps:** |T| ≈ 10-16 m.
- **Thornwater:** |T| ≈ 0.26 m, so harmless there by luck.

Fix: add `bot_vector(team, v)` (basis only: `frame.basis * (R * -v)`) on LayoutLevel. Use it in `_row_spot` and
`_wall_spot`. Keep `_side()` for points. Add a test on a non-Crown-Hollow layout:
`bot_point(t, p + v) - bot_point(t, p) == bot_vector(t, v)`.

**H4. The bot's second barracks (X2) ignores the layout's `rich_hall` slot**
Where:
- `commander.gd:209`: X2 row `pos: X2_SPOT`, no `slot` key
- `commander.gd:1437-1451`: `_row_base` only routes INF (X1), M1, S3 and S4 to the level, so X2 goes through `_side()`
- By contrast, `layout_level.gd:255-259` (`rich_hall_spot`) reads the slot, and `ai_champions.gd:607` scouts the
  enemy's `rich_hall_spot`.

What is wrong: X2 is Crown Hollow's rich hall moved rigidly. The `rich_hall` slot that `rich_node` / `rich_pocket`
define (local (0, 9.9)) is never used by the builder.

Failure scenario: on Quartermeet the PLAYER bot's X2 resolves to about (-35.4, -35.2). That is next to the closed A2
seat's natural; the rich node is at (-14.6, 52.2), about 90 m away. The bot builds a drop-off nowhere near the node it
mines, and enemy champions scout the slot where nothing is built. On 1v1 maps from the current generator the rich node
sits roughly where Crown Hollow's does, so it is masked there.

Fix: in `_row_base`, route `&"X2"` to `_level.rich_hall_spot(team)` when the level has it. That is identity on Crown
Hollow (`skirmish.gd:470` = the same `_mirror(RICH_HALL_SPOT)`), so the MT2 gate stays green. The rigid move of
`SCOUT_PATH` / `AIMapFill.SCOUT_PATH_RIVER` (Crown Hollow's bridge route, wrong on a straight x = 0 river) belongs to
MT10. List it there.

### Medium

**M1. The "enemy seat loses" evidence cannot separate seat from kingdom; the lab has no seat swap**
Where: `docs/tools/world_forge/history.md` (one game per map); `lab_match.gd:53` (`kingdoms = ["fire", "shadow"]`) and
`:198`; `--pair` exists, but nothing runs the swapped pair.

What is wrong: as the verdict says, I found no positional seat bias (`bot_point` / worker / hub / role / bank mapping
all mirror exactly). The two losses are what you would expect from n = 1 with fire always seat 0.

Fix: before MT8, run each generated map at least 4 times: `--pair=fire:shadow` and `--pair=shadow:fire`, 2 seeds each.
Report wins by seat and by kingdom. Make the MT8 fairness matrix do this by default.

**M2. A bad or missing layout plays a bogus match instead of failing**
Where:
- `layout_level.gd:65-71`: no layout gives `push_error`, then an empty `MapLayout.new()`. That means fallback keeps at
  (±30, ∓30), no nodes, no river.
- `_layout_error` is written but never read anywhere.
- `lab_match.gd:129-135` sets `layout_path` and never checks it.

Failure scenario: a typo in `--layout=res://data/maps/thornwatr.map` produces a 30-minute bot game on an empty map that
"ends on score". The JSON says `"map": "thornwatr.map"` and may report 0 script errors if the lab only counts
`SCRIPT ERROR` lines.

Fix: in lab_match, `load_layout()` up front and `_finish("bad layout", -1, ...)` on null. Expose `layout_error()` on
LayoutLevel and have the HUD and menu refuse to start when it is set.

**M3. Auto-fix moves only the named spot, not the template parts that depend on it, and never rolls back**
Where: `forge_map.gd:487-538` (`apply_fixes`); `world_forge.gd:381-405` (`_fix_step`).

What is wrong:
- A `move nat_node` leaves `nat_hall` (natural_hall slot), `nat_tower` and any `door=` of the same template where they
  were.
- Each round's moves are written straight into the `.map`. Nothing keeps the best round: a round that lowers the score
  is still kept.
- `apply_fixes` also deletes hand-written `move <id>` lines for the same id. The doc says it only replaces autofix lines.

Failure scenario: Thornwater's `third_node` moved 4.5 m (`thornwater.map` autofix line). Its `third_hall` slot stayed
7.5 m away in the old frame. With a 5 m move on the natural, the bot's X1 slot can end up 3 m or 12 m from the node,
or inside its forest clearing ring. R1 / R4 can also push the same spot back and forth across rounds.

Fix:
- Record the template anchor of each spot at expand time (`use` prefix → member ids). When the fixed spot is a
  template's anchor member, write `move` for every member, or move the `use` line's `at=`.
- Keep a copy of the best-scoring round and restore it when the last round is worse.
- Only drop lines that carry `# autofix`.

**M4. Contract and documentation drift**
- `CLAUDE.md` has no contract entry for `MapInfo`, `LayoutLevel` / `layout_path` / `bot_point` / `map_layout()`, or the
  `MapLayout` v2 accessors (`mark`, `trigger`, `path`, `play_bounds`, `open_seats`, `target`). `map-production.md:393`
  says the lead adds them. They are shared interfaces that systems, ai and ui code now call.
- `map-production.md:375` says R3 for team maps is ≥ 2.5 per seat; the code uses `CONTEST_MIN_TEAM := 3`
  (`map_checks_v2.gd:28`) and gen writes `contest=3`.
- `map-production.md:256` still says "after 5 loops"; the code and section 9 say 3.
- MT2's done-when (`:358`: Skirmish2v2 on a layout, 4 seats spawn, 2 / 4 bots play) and MT5's (`:361`: 3 archetypes x
  2 player counts) are not met. `history.md` lists them as next. The status tables should not read as done.
- MT1's done-when, "a 168 m and a 150 x 120 level load with correct fog / minimap", passes, but see H1 for the ground.

Fix: the lead adds a "Map layouts" contract paragraph to CLAUDE.md, and the game-designer aligns the numbers in
map-production.md.

**M5. The forest's auto lane connects the wrong pair of seats on fourfold maps**
Where: `map_forest.gd:148-149`: the lane runs from `starts[0]` to `starts[starts.size() - 1]`, and keep spots come in
image order [identity, mirror_z, rot180, mirror_x].

What is wrong: on a fourfold map the kept-open lane runs A1 → B2 (mirror_x, across the river, same z). It never runs
A1 → B1, who are the 1v1 opponents LayoutLevel actually plays (`_assign_seats`), nor A1 → A2 (the allies).

Fix: build the lane from the identity start to the start of the first seat whose side differs and whose frame is
`rot180` (fall back to the first enemy seat). Optionally add a second lane to the ally.

**M6. A mission that extends LayoutLevel silently loses the river and every landmark**
Where: `layout_level.gd:51-62` (all map systems off unless the script is `layout_level.gd` itself); `:381-382` and
`:394-395` (`_add_river` / `_add_landmarks` gated on `river_enabled`).

What is wrong: the header invites missions to extend LayoutLevel (`:21`). A mission subclass then builds a map with:
- no water: the forest is planned with `river = null`, so willows and corridor checks change
- no prop colliders

Failure scenario: a campaign map designed and Map-Labbed with a river and landmarks plays as dry open ground. The paths
the Map Lab approved no longer exist.

Fix: decouple the layout's terrain (river, moat, crossings, props) from the gameplay switches. Always build the river
geometry and props from the layout, and let `river_enabled` only gate fords, ford-slow and map-fill services. Or
document that a mission must set `river_enabled = true`.

### Low

- **L1. MapInfo is process-global static state** (`map_info.gd:11-13`). Every main.gd level resets it in `_ready`,
  which covers the game. But any tool or test that builds a `FogOfWar`, `RiverSystem` or `BuildGrid` without a level
  inherits the last map's size. Examples: `forge_gen.score_layout` (`:333`), `forge_map_level` (`:44`), and a later
  test in the same process. Tests remember to `reset()` today; a helper `MapInfo.scoped(w, d, fn)` or a test-template
  reset would make that automatic.
- **L2. Fourfold maps make duplicate node names**: `_add_taverns` names by `p.x + p.z < 0` (`skirmish.gd:1231`), so 4
  taverns become 2 x "TavernFire" + 2 x "TavernShadow". The Map Lab falls back to `get_class()` ids for the
  auto-renamed ones (`map_checks.gd:180-186`). Name by `_image_name`, as peddlers already do (`layout_level.gd:409`).
- **L3. Cosmetic critters use Crown Hollow coordinates** on every map (`critter_system.gd:59-85`, `MAP_LIMIT := 56.0`):
  birds, butterflies and fireflies spawn at Crown Hollow's spots, so in water or forest on Quartermeet, and never
  beyond 56 m.
- **L4. Dead constants after MT1**: `river_system.gd:34` `MAP_HALF`, `bounty_mode.gd:40` `MAP_HALF_FALLBACK`. Remove
  them so nobody uses them again.
- **L5. Minimap letterbox**: on a non-square map the ground fill covers the whole square, and `map_to_world`
  (`minimap.gd:343-346`) lets a right-click in the letterbox order moves to points off the map. Clamp with
  `MapInfo.clamp_point`.
- **L6. The preview ground is 2 m larger than the live one** (`forge_map_level.gd:45`: `size * 0.5 + 2.0`). Preview Map
  Lab paths can hug a 2 m strip outside the map that the live LayoutLevel does not have, and preview and live scores
  drift. Use the exact size.
- **L7. R5 "navmesh raster <= 4x Crown Hollow" can never fail** after "size <= 192 m": the condition reduces to
  `W x D <= 240 x 240`. `CH_CELLS` also assumes 0.5 m cells, while the navmesh uses 0.25 m (`main.gd:297`). Drop it or
  compute the real cell count.
- **L8. Gen seeding**: `rng.seed = hash([id, seed, archetype, players, tempo])` (`forge_gen.gd:65`). The same `seed=`
  gives a different map under another id (the adopted maps were renamed), and it relies on `Array.hash()` staying
  stable across Godot versions. Seed from `seed` plus the knobs, without the id, and write the knob string into the
  header (it is already there).
- **L9. The gen pre-filter ignores building footprints and prop colliders** (`forge_gen.gd:369-387`: only trees,
  rocks, blocks and water). The grid then underestimates paths around posts, guild houses, taverns and landmarks. That
  is fine as a pre-filter, but say so in the doc next to `GRID_ALLY_OVERHEAD`.

## Test quality

- `test_mt2_layout_level.gd` is a strong regression gate: spots, the collider hash, the 1275-pair path table, bot
  points, node roles and slots against the live `skirmish.tscn`.
- Its gap is that it only proves the identity case. Every LayoutLevel bug above (H3, H4) is invisible on Crown Hollow
  by construction. Add a non-Crown-Hollow layout case that checks:
  - `bot_point` linearity
  - `rich_hall_spot` == the `rich_hall` slot
  - Commander's X2 / shift / wall targets lie within N m of their slots
- `test_map_tools.gd` covers MT1 / MT3 / MT4 / MT6 well, including teaching errors and the overlay.
  - MT5 checks one seed per player count and does not check determinism (`map_text(s)` twice, then compare).
  - MT6 checks only a hand-made canonical id. It does not check a template member (M3) or a twin id.
- No test runs a ≥ 150 m LayoutLevel end to end (fog + ground material + minimap + BuildGrid edge). H1 would have
  shown up there.
- `test_mt2_perf.gd` takes `map=` but defaults to Crown Hollow. Add a 176 m run to the slow list (bake time and
  per-frame cost grow about 2.15x with the navmesh area).

## Things checked and found fine

- **Navmesh / region timing**: blocks, landmarks, river obstacles, keeps, nodes, posts and guild houses are all added
  under `nav_region` in `_build_map` before the one bake. Map-fill services, wardens and caches come after
  `bake_finished`, exactly as in skirmish.gd. `MapInfo.setup` runs first in `main._ready`. `LayoutLevel._assign_seats`
  runs before `super()` but reads no MapInfo-dependent state. Fog allocates in `_init` from MapInfo, which is already
  set because the fog is created inside `main._ready`.
- **Mirror and coordinate math**:
  - `_canon_rot` (atan2(x, z) convention with `Basis(UP, turn)` adds the angle)
  - template `face=center` (`atan2(-x, -z)`)
  - prop / block yaw under rot180 / mirror_x / mirror_z
  - willow yaw per image
  - fourfold suffixes / frames
  - BuildGrid bounds (`ceil(half / 2) - 2` = -29..28 at 120 m)
  - fog grid rounding (even cell counts)
  - river mask and near-grid sizing
  - minimap fog rect via `cell_origin`
- **Determinism**: MapForest uses its own seeded RNGs, draws in skirmish.gd's order, and the hash test proves the plan
  is stable. Road graph and herd dictionaries iterate in insertion order.
- **Map Lab v2 logic**: R1 fixes are emitted only for the identity seat with canonical ids. `_spot_idx` -1 is guarded
  everywhere it feeds `path_len`, which would otherwise index the wrong row. The R4 nest-exception precedence is
  correct.

## What is good

- `MapInfo` is small, static, and read everywhere the 120 m used to be hard-coded. The MT1 diff is surgical, and
  Crown Hollow's numbers (BuildGrid -29..28, camera 116 m, fog 60 x 60, mask 240 x 240) are preserved exactly.
- Crown Hollow rebuilt tree for tree by a data generator (MapForest), with a collider hash and path-table gate, is an
  excellent regression strategy.
- Grammar v2 is well designed:
  - errors name both the file and the `use` line
  - did-you-mean suggestions
  - templates as transformed `.map` fragments
  - overlays (`base=`, `move`, `remove`, `set`) that keep ids canonical
  - `templates_used` and the source hash for provenance
- The grid pre-filter (1 m octile Dijkstra with corner-cut prevention, symmetry used to get the other seats'
  distances) is a cheap, sensible gate before the 15-minute Map Lab, and the code is clear.
- Fixable findings carry a canonical-frame move vector and are written as readable, revertible `move ... # autofix`
  lines. That is a good human-in-the-loop design.
- LayoutLevel keeps the Skirmish public API (`node_of`, `*_hall_spot`, `market_slot`, `tower_slot`, `base_center`,
  `cache_spots`), so existing AI and UI code works unchanged.
