# G-B neutral: the neutral and shared buildings

Task G-B neutral of the graphics week (docs/plan/graphics-week.md, 2026-10-15). Scope: the two Taverns, the trading posts,
the capture points (watchtower, essence well, wayshrine), the Magpie Den, the Greywater Lodge and the Stables' shared
shader (`art/buildings/stables/stables_painted.gdshader` + `stables_model.gd`). The Bazaar has no shared file outside
its kingdom subfolders, so nothing changed there. No scene, node name, hook, state, footprint, collider, LOD or test
contract changed.

## What changed

### 1. One painted-PBR layer for every neutral material (`art/buildings/tavern/neutral_paint.gdshaderinc`)

The same idea as the units' G3b layer, tuned for an old roadside world (stone, timber, thatch, plaster, iron, canvas,
shingles, hides). Every neutral painted shader includes it and lights through it:
`tavern_painted`, `trade_post_painted`, `watchtower_painted`, `essence_well_painted`, `wayshrine_stone`,
`greywater_lodge_painted`, `magpie_den_painted`, `stables_painted`.

| Layer | Tier | What |
|---|---|---|
| Light | all | 60 % smooth wrapped ramp + 40 % the old 2-band paint, a cool fill on the turned-away side, a warm terminator (canvas / straw / hide scatter most), a light-side rim catch on the sunlit silhouette, per-surface speculars (iron sharp + broad tinted Blinn, wood / tiles soft sheen, stone a faint broad sheen, canvas / straw / fur velvet grazing sheen) |
| Albedo | Medium+ | tops catch the sky (+6 %), undersides take a tinted crease AO, earth splashed up the foot of the walls, rain streaks down stone / plaster / wood walls (1 extra noise sample), lichen-warm / cool weathering on stone, sun-grey tops on timber, bleached / damp straw, dye pooling in canvas folds, iron gets a small fake sky / horizon reflection |
| Fine detail | High / Ultra | stone chisel pits, wood fibres, straw strands, plaster trowel marks, canvas weave, fur strands, shingle grain, iron brushing; each also bends the normal (derivative bump) and fades out once a pixel is wider than half its period (an RTS-zoom pixel never pays for it) |

Surface kinds come from each shader's own pattern / part ids (stone courses, thatch, clay tiles, planks, canvas,
whitewash, fur, shingles, iron, rope...), else from the part colour (`np_kind_of`: iron by spec, browns = wood, light warm
yellows = straw, pale low-saturation = plaster, the rest stone). Self-lit parts (glows, embers, rune inlays, openings,
hot iron) keep their own look. The wayshrine's rune light also spills a little onto the stone round the grooves (Medium+),
so an owned / awake shrine glows in its colour from the RTS camera.

### 2. `NeutralBuildingLook` (`art/buildings/tavern/neutral_look.gd`) and `NeutralFlickerLight`

- `detail()` = `GameSettings.effective_graphics_quality()` (0..3; Low in every headless / `-s` run).
- `set_detail(m)` / `set_detail_all(ms)` write `gb_detail` into the materials (per-instance palettes, the shared
  `watchtower_mat.tres`, `essence_well_painted_mat.tres`, `wayshrine_stone_mat.tres`, the Stables' body material).
- `add_light(...)`: a shadowless, distance-faded, flickering `NeutralFlickerLight` (`set_level`, `set_tint`, `flash`),
  **Ultra only** (see Open issues): tavern lantern (sways with it) + doorway (flashes on a hire), trading post brazier +
  lantern, watchtower cresset (owner glow colour, follows ignition / capture flare), essence well (rune colour: owner
  glow or violet, flares on the income pulse), wayshrine rune stone (pale blue asleep, owner, gold awake, blessing burst),
  Den lantern (blue-green), Lodge lantern + roof fire. All follow the open / closed state.
- `add_sparks(...)`: 6-8 ember sparks (one shared process material + quad), **High / Ultra**: the tavern chimney.
- Every light / spark node carries `meta no_ghost = true` (lead rule: Building.make_ghost skips it).

### 3. Shapes

Tavern: four window boxes (planks + earth, leaves, red / gold blooms) under the shuttered upper windows and two
ground-floor windows (ground-floor boxes stick out 0.26 m: inside the 0.3 m footprint rule; baked into the shared
merged Structure mesh, 3 new palette entries).

### Low

Low keeps the pre-G-B effect cost: no new light, particle or pass (test_gb_neutral checks it); only the light ramp
(a few ALU) and the tavern's window boxes change at Low, as the lead's ruling allows for materials and shapes.

## Measurements

Shots: `art/buildings/tavern/tools/gb_neutral_shots.gd` (windowed, one tier per run, `tag=`, `only=`, `perf=0`,
`pause=1`) on Crown Hollow: nearest tavern / trading post / Den / Lodge / watchtower (owned by the player) / well (owned
by the enemy) / shrine (woken) / a Fire Stables by the player keep, zoom 10 and 30 + a zoom-50 centre view.
Contact sheet `docs/art/lab/gb_neutral/gb_neutral_contact_sheet.jpg` (per building: before High | after High, same
framing | after Ultra, live zoom 10). Key PNGs: `key_tavern_before_after.png`, `key_trade_post_before_after.png`,
`key_tavern_ultra_z10.png`, `key_shrine_ultra_z10.png`. The other shots stay local in `docs/art/lab/gb_neutral/shots/`
(~195 MB; the lead adds them to `.git/info/exclude`).

Note on framing: the skirmish opens paused (the STR / INT pick), and the first "before" run did not unpause, so the
camera never left its default zoom and the capture-point owner blends did not run. The paired before / after set is
therefore taken with `pause=1` (same framing, owner states not shown); the `live_*` set is unpaused (true zoom 10 / 30 /
50, owner colours and lights animating).

Art Lab (`--gfx=high`, batch files `docs/art/lab/gb_neutral/batch_before.txt` / `batch_after.txt`, scorecards in
`docs/art/lab/gb_neutral/before|after/<asset>/`):

| Asset | Before | After | Notes |
|---|---|---|---|
| tavern | WARN 84 | WARN 87 | R5 glow-point WARN gone; only A1 (no construction hooks: neutral, by design) |
| trade_post | WARN 85 | WARN 85 | same B8 / B9 / A1 WARNs (pre-existing) |
| watchtower | WARN 86 | WARN 87 | same B4 / A1 / R5 |
| essence_well | WARN 88 | WARN 88 | A1 only |
| wayshrine | WARN 86 | WARN 85 | same A1 / R5 (C3 colour score moved: the stone is a touch lighter) |
| magpie_den | WARN 87 | WARN 87 | A1 only |
| greywater_lodge | WARN 89 | WARN 89 | A1 only |
| fire_stables (shared shader) | FAIL 89 (B8) | PASS 93 | the Fire agent changed its Stables in the same hours: not all of it is this task |

GPU / fps (1920 x 1080, RTX 3070 Laptop, camera over the tavern at zoom 30, other agents' Godot runs on the machine,
numbers noisy): before High (paused) 93.3 fps avg / GPU median 9.99 ms; after High (paused) 114.2 fps / 8.08 ms (an
earlier after run under heavier load: 55.5 fps / 8.49 ms GPU; the GPU time is the stable figure); after Ultra
(unpaused, live match, all lights) 69.9 fps avg, 57.0 fps 1 % low, GPU median 12.59 ms (target Ultra >= 60).

Shadow / Nature Stables (shared shader, lead review): `art/buildings/stables/tools/gb_stables_shots.gd` spawns both by
the player keep and shoots them after, then swaps their materials to `stables_painted_legacy.gdshader` (tool-only
pre-G-B copy) for the before shot in the same frame -> `docs/art/lab/gb_neutral/key_stables_shadow_nature_before_after.jpg`
(left before, right after): wood grain and sun-grey tops on timber, team-colour roofs read as dyed cloth (darker folds),
stone weathering.

## Review fixes (lead, 2026-10-15)

- Derivatives out of per-fragment branches: the pixel size (`fwidth`) is computed before the kind branches in
  watchtower / essence well / stables, and the Stables' bump runs after its if / else (`bump_h` 0 on holes).
- `NeutralFlickerLight` stops processing once it is off (level 0, hidden, no flash) and wakes on `set_level` / `flash`.
- test_gb_neutral also builds the Fire, Shadow and Nature Stables (shared shader) and checks the light sleeps when off.
- Lights stay Ultra-only (lead decision); the lead handles the Art Lab B5 exception.

## Tests

`tests/test_gb_neutral.gd` (headless): every neutral painted shader includes the layer and lights through `np_light`,
Low tier = 0, `add_light` / `add_sparks` make nothing at Low, every model scene builds with no light / spark node at Low,
the shared .tres materials and palettes get `gb_detail = 0` at Low, hooks still answer, `NeutralFlickerLight` levels.
Also PASS: test_9_v6, test_10_v8, test_10_v9, test_10_v10, test_10_c9, test_12_v17, test_12_v18, test_12_v19; smoke
victory=true; perf_test PERF OK (norm 5.28 / limit 6.72).

## Open issues

- **Real lights vs the building budget.** Art Lab B5 / art-keep 0.4 say buildings use 0 Light3D. Lights are Ultra only
  (`NeutralBuildingLook.MIN_LIGHT_TIER = 3`, lead decision 2026-10-15); the lead adds the Ultra B5 exception to the lab.
- The Stables' shared shader changes every kingdom's Stables that still uses `stables_painted.gdshader` (Fire, Shadow,
  Nature; Ice swaps its own shader in `ice_stables.gd`). Kingdom agents who swap in their own shader later keep theirs.
- The trading post, Den and Lodge got no new shapes (they were already dressed); the gain there is material + light.
