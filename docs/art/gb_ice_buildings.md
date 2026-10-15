# G-B Ice: the Ice kingdom's buildings

Task G-B Ice of the graphics week (docs/plan/graphics-week.md, 2026-10-15): every Ice building as beautiful as possible
from the RTS camera (zoom 10 / 30 / 50). One shared Ice paint layer lifts every Ice building at once, the keep gets a
real tier look, windows glow warm against the cold, and the Forge gets an Ice model. No node the game or the tests read
changed (names, hooks, collision, footprints, team colour, selection, B8 merges, mesh counts).

## What changed

| Piece | Before | After |
|---|---|---|
| Crystal ice (team crystals, glazed roof / dome tiles) | flat painted colour + spec | deep body, a fake interior (the paint noise sampled again 0.45 m and 0.9 m behind the surface along the view ray: cloudy depth + thin bright fracture planes, a cheap stand-in for refraction), sky reflection at grazing angles, crisp pale facet edges, a sharp twin specular, light that wraps through the ice and glows when the sun is behind it |
| Damage on ice | the rime veins widen | + white fracture lines (Voronoi edges) that spread with the damage, crazed ice around them |
| Ice-stone | flat painted colour | ashlar courses with staggered joints (Hall, Lodge, Spire, Keep, Forge; the Wall's blocks are modelled so it is off there), hoarfrost creeping up from the ground, a cold fill on the turned-away side |
| Snow | flat white | very soft wrapped light with a blue shadow side, wind-packed blue pockets, glints close up (High) |
| Tops of every block | stone | an even snow dusting on every upward face (dark plinths keep half their read) |
| Silver trims | spec only | fake sky / horizon reflection, tinted sharp highlight |
| Windows | cold team-glow slits | warm interior light (Keep windows, Hall arrow slits, Lodge windows + lantern, Spire slits, Forge slits); the crown, gate, keystones and orbs keep the team glow |
| Rime Keep tiers | placeholder gold rings (keep.gd) | Stronghold: four bastion crystals leaning out of the plinth corners + eight satellites, an outer ring of crystal shards turning the other way round the crown. Citadel: + six tall crystals ringing the crown on the top terrace, four sentinel crystals orbiting at mid height, full outer ring, crown light +30 % |
| Keep upgrade | nothing | `set_upgrading(true)`: the next tier's crystals grow with `Keep.upgrade_progress()`, the build ring swirls, the crown halo spins up; `play_tier_up()`: burst from the crown, light flash, the new crystals pop in |
| Frost Forge | placeholder boxes | new model `art/buildings/forge/ice/ice_forge.tscn` (FrostForgeModel): battered smithy under a hipped roof of glazed team ice, forge mouth glowing with frostfire (flares on each research), a banded chimney crowned with crystals around a floating frostfire shard, an ice anvil, a quench trough of frost-water, silver ingots, a crystal cluster, a banner, frost patch. **Not shown in game yet**: ForgeBuilding never reads `model_path` (handoff in docs/handoff/for-systems-coder.md) |
| Frost Stables, Frost Bazaar | painted | the same Ice layer (Stables through its own `ice_stables_painted.gdshader`; Bazaar awnings and goods keep a plain painted read) |
| High / Ultra ambience | | a few slow snowflakes drifting over the Lodge and the Forge (High+ only, `no_ghost` meta) |

## Files

- `art/buildings/ice/ice_paint.gdshaderinc` (the layer), `ice_painted_vc.gdshader` (B8 one-material bodies: Hall, Lodge,
  Wall, Bazaar, Forge), `ice_painted.gdshader` (per-part: the Keep, the Spire), `art/buildings/stables/ice/ice_stables_painted.gdshader`.
- `art/buildings/ice_hall_shapes.gd` (IceShapes): `ice_vc(body, masonry)`, `ice_part(mat, kind)`, `is_vc`, `gfx_tier`,
  `detail_tier`, `high_fx`, `window_color`, `WARM_WINDOW`, `snowfall_pm`, `legacy` (shots only: the pre-G-B look).
- Models: `ice_keep.gd` (Ice layer by material name, warm windows through the glow's per-instance `tint_color`, the tier
  look), `ice_keep_glow.gdshader` (instance `tint_color`), `ice_hall.gd`, `ice_lodge.gd`, `ice_spire.gd`, `ice_wall.gd`
  (relinks re-merge with painted_vc then switch back), `stables/ice/ice_stables.gd`, `market/ice/market_ice.gd`,
  `forge/ice/ice_forge.gd` + `.tscn` (new).
- `art/buildings/ice/tools/gb_ice_shots.gd` (windowed shots + fps of an Ice base), `tests/test_gb_ice.gd`.

How it plugs in: the Hall / Bazaar / Forge (FireHallModel) and the Lodge / Wall (SmallBuildingModel) swap their merged
body material to `ice_painted_vc` in `_post_build()`, right after `PaintedVC.convert()` (same vertex data and uniforms, so
team colour, rim, damage, crack energy still drive it). The Hall / Bazaar / Forge do not call `FireHallModel._post_build`
on purpose (a Fire look added there must never reach the Ice buildings) and override `_vc_wanted()` to accept the Ice
body. Surface kind comes from the vertex data: team + spec >= 0.3 = ice, matte team = plain (awnings), spec >= 0.33 =
silver, spec >= 0.25 = frosted ice, pale low-saturation = snow, warm colour = plain goods, else ice-stone.

## Cost tiers

`gb_detail` (material uniform, from `GameSettings.effective_graphics_quality()` in `_ready`): 0 Low, 1 Medium, 2 High /
Ultra.

| gb_detail | Runs |
|---|---|
| 0 Low | the light ramp per kind, sky fresnel and trapped light on ice, snow on tops, damage fractures (a few ALU, **no extra texture sample, no new particle or pass**) |
| 1 Medium | + ice interior (one parallax layer, 3 fetches), facet edges, masonry, hoarfrost, silver reflection, frost on frosted-ice tops |
| 2 High / Ultra | + the second interior layer (fracture planes), snow / frost glints (pixels < ~6 cm only); snowfall particles on the Lodge and Forge |

Headless / `-s` runs are Low (tests and labs unchanged in cost). Changing the setting mid-match applies to buildings
built after the change.

## Measurements

Art Lab (`--gfx=high`), before = `docs/art/lab/gb_ice/before/<asset>/`, after = `after/<asset>/` (batches
`batch_before.txt` / `batch_after.txt`):

| Asset | Before | After | Notes |
|---|---|---|---|
| ice_keep | PASS 89 | PASS 87 | P4 inner detail 2.2 -> 2.7 (25 m), 3.3 -> 3.9 (40 m); P5 (INFO) counts the warm windows as the glows now (lower half) |
| ice_hall | WARN 91 | WARN 91 | same R5 WARN (6 -> 7 glow points: sharper ice specular; the spec was lowered 1.8 -> 1.2 after this run); P4 2.5 -> 3.2 / 3.8 -> 4.7 |
| ice_lodge | PASS 91 | PASS 90 | |
| ice_spire | WARN 86 | WARN 88 | same pre-existing B8 / B9 WARN (13 per-part materials, not merged) |
| ice_wall | WARN 89 | PASS 92 | R5 WARN gone |
| ice_stables | PASS 93 | PASS 93 | |
| market_ice | PASS 94 | PASS 94 | |
| ice_forge | (placeholder) | PASS 91 | new model |

A first after-run of the keep FAILed B8 (a 9th material for the warm windows) and B6p (denser High snow motes): fixed
(the windows use the shared glow material's per-instance tint, the motes were reverted) and re-run: PASS 87.

GPU / fps, `gb_ice_shots.gd` over the Ice base at zoom 30 (1920 x 1055, RTX 3070 Laptop, Crown Hollow with 4 tier keeps,
2 halls, 4 lodges, 3 spires, 4 walls, stables, bazaar, forge). The PC was shared with other agents' Godot runs, so the
numbers swing a lot run to run; the quietest pair:

| Tier | Before (legacy look) | After |
|---|---|---|
| High | 124 fps, GPU 6.9 ms | 117 fps, GPU 7.3 ms |
| Ultra | 71 fps, GPU 12.1 ms | 79 fps, GPU 10.2 ms (noise: same scene) |

Draw calls +~30 (the tier crystal groups, the snowfall). High stays above the 90 fps target, Ultra above 60, on the quiet
runs.

Shots (`docs/art/lab/gb_ice/`, `.gdignore`): `contact_sheet_before_after.jpg` (before | after at High: base z30, base
z50, tier keeps z30 / z12, lodges z10, damaged hall z10, wall run z10, forge z10; "before" = `IceShapes.legacy`, the
same scene with the pre-G-B shaders, cold windows, no tier look, the Forge placeholder) and four key PNGs
`after_q2_base_z30.png`, `after_q2_tiers_z30.png`, `after_q2_small_z10.png`, `after_q2_forge_z10.png` (the Forge shot
puts the model in place of the placeholder: the game does not load it yet). Regenerate:
`tools\godot_run.ps1 --path . -s res://art/buildings/ice/tools/gb_ice_shots.gd --resolution 1920x1080 --quit-after 80000 '--' --gfx=high tag=after`
(`tag=before` for the legacy look, `shots=0` for fps only, `'only=base_z30,forge_z10'`).

Honest read: at zoom 30-50 the change is depth in the crystals (they read as ice, not blue plastic), stone with courses,
snow on every ledge, warm windows and the tier crystals (the biggest read change: a Citadel now looks like one); at zoom
10 the ice interiors, fracture lines on damaged buildings, masonry and the Forge show.

## Tests

`tests/test_gb_ice.gd` (headless): every Ice model draws its painted parts with an Ice shader (gb_detail 0 at Low), the
legacy switch keeps the old shaders, warm windows (keep tint on the shared glow material, hall slits), a joined wall keeps
the Ice shader after its re-merge, keep tier hooks (before _ready, Stronghold / Citadel groups, upgrade growth,
construction and collapse hide them, `Keep.set_tier_now` reaches the model, no placeholder emblem), the Forge model's
hooks and collapse, `ice_forge.tres` finds the model, no High snowfall at Low. Also run: test_a2_4, test_a_8, test_a_9,
test_10_v3, test_7_s1 PASS, smoke `victory=true`, perf_test PERF OK (norm 5.42-5.51 / limit 6.72).

## Open issues

- **Frost Forge not in game**: `ForgeBuilding` only reads `BuildingType.model_scene`; it needs the Market's
  `get_model_scene()` fallback (or `model_scene` in `ice_forge.tres`). Request in docs/handoff/for-systems-coder.md.
- The keep's existing hex snow motes / halo shards read as pale paper hexes at zoom 30-50 (pre-existing, unchanged).
- `IceHallModel`, `FrostBazaarModel`, `FrostStablesModel` and `FrostForgeModel` extend `FireHallModel`
  (art/buildings/fire_hall.gd, Fire buildings' file this wave): a Fire look added in `FireHallModel._ready` (not in
  `_post_build`) would reach them. They do not call `super()` in `_post_build`.
- The graphics tier is read in `_ready`: buildings standing when the setting changes keep their tier until rebuilt.
- Art Lab after-runs of the lodge / spire / wall / stables / bazaar / forge ran before the last two small tweaks (ice
  specular 1.8 -> 1.2, an even snow dusting on flat tops); keep and hall were re-run after.
