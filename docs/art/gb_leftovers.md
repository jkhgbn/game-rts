# G-B leftovers: Forges, Ember Stables paint, completion settle, no grass on dead ground

Task G-B leftovers of the graphics week (docs/plan/graphics-week.md, wave G-B; JS 2026-10-15 "make the graphics as
beautiful as possible"). Four items, in order. Nothing in `scripts/` or `data/` changed; no contract changed (the Forge
models plug in through `BuildingType.get_model_scene()`: `model_path` was already set in all four forge `.tres`).

## 1. Forge models (Fire, Nature, Shadow)

`data/buildings/{fire,nature,shadow}_forge.tres` already point `model_path` at
`res://art/buildings/forge/<kingdom>/<kingdom>_forge.tscn` (no handoff needed); the files did not exist, so ForgeBuilding
drew its placeholder boxes. Each model is a hall-size model (3 x 3 cells, 6 x 6 m, gate local -Z) on its kingdom's
G-B paint layer and hall base class, so construction (rise in height order + scaffold + glowing outline), damage (roof
holes, smoke / blaze, the tall element's crown lost under 50 %, banner under 25 %), selection rim, team colour, training
pulse (the forge mouth flares when a research completes) and the 3 s collapse (-> `destroyed_finished`, tall element
falls, wreck) are the FireHallModel contract (art-keep.md 8.8), like the Frost Forge.

| Forge | Class / base | Look |
|---|---|---|
| Ember Forge `forge/fire/fire_forge.gd` | `EmberForgeModel extends FireHallModel`, `_gb_fire()` true | Fire paint layer (fire_painted_vc: ashlar, clay tiles on team slopes, timber, bronze + patina, soot, ember bounce). Dominant vertical: a round banded basalt smelting kiln with a tapering stack, bronze hoops, flared crown with a glowing rim, fire hole at its foot, bellows of timber + leather. Squat ashlar smithy under a team clay-tile gable with crossed bronze bargeboards and a wide glowing forge arch; paved yard: bronze anvil on a stump under a timber lean-to roofed in team tiles, hammer rack, lava quench trough (glow under the bloom), bronze ingots, slag heap, banner post. Heat haze over the kiln crown and the trough at High / Ultra (FireBuildingLook). |
| Grove Forge `forge/nature/nature_forge.gd` | `GroveForgeModel extends NatureHallModel` (own NatureKit mesh keys `nature_forge/*`) | Nature paint layer (NatureKit materials + NatureVC merge: wind, translucency, moss velvet, relief at High). Dominant vertical: a hollow chimney-tree (flared bark trunk, roots gripping the plinth, open wood-rimmed top glowing with sap-fire, a sap seam, one living branch with a leaf clump and a blossom). Mossy fieldstone kiln dome (lathe) with a glowing mouth and a moss cap, bark flue into the tree; lean-to of bark posts under a living hedge roof sheltering a stone anvil on a stump; hollow-log quench trough, cut stone, logs, leaning rune stone, leaf banner on a gnarled standard. Hall ground (moss patch, fairy ring, dressing). Sap embers rise from the tree; leaves + fireflies (High+) near the camera only. |
| Gloom Forge `forge/shadow/shadow_forge.gd` | `GloomForgeModel extends ShadowHallModel` | The Gloom Hall's language + its G-B ShadowDress (dead ground Medium+, mist / wisps / embers High+, light Ultra; nothing at Low) and team / dark-team slate courses. Dominant vertical: the soul furnace, a tapering obsidian stack banded in iron-silver, gripped by three obsidian claws, crowned by a cage of iron spikes holding a bobbing soul flame. Crypt smithy with corner pinnacles, pointed forge arch glowing violet, lancet slit, spike crest; obsidian anvil on a skull-rune block, dark ichor quench basin, blade rack, chain gallows with a hook, banner on a spiked post. |

Tier rule: every forge reads `GameSettings.effective_graphics_quality()` in `_ready` through its layer (FireBuildingLook
`detail()`, NatureKit `make_materials` / `gfx_rich()`, ShadowDress `quality()`); Low = no haze, no fireflies, no
ShadowDress (the cost before G1: shapes and materials only).

Note: the Grove Forge meshes are built in GDScript the first time one appears (the Grove Hall's are baked to
`art/buildings/nature/baked/` by `nature_bake.gd`). Baking `nature_forge/*` is a cheap follow-up (run the bake script
windowed after adding the keys) if the first-build hitch shows in a profile.

## 2. Ember Stables on the Fire paint layer

`art/buildings/stables/fire/fire_stables_painted.gdshader` (new): the shared Stables vertex contract and uniforms
(`stables_painted.gdshader`, untouched: COLOR = part colour / team flag, UV2.x = plain / stone / metal / hot / hole) with
`fire_paint.gdshaderinc` instead of the neutral layer: surface kind from the part colour (stone, basalt, timber planks,
clay tiles on the team roofs), class 2 = bronze / iron, Fire light / soot / ember bounce / patina, fine detail + bump at
High+; hot parts and holes keep the shared look; damage = the Fire soot blotches. `EmberStablesModel._post_build()` swaps
the body shader and writes `gb_detail = FireBuildingLook.detail()` once (`FireBuildingLook.legacy` keeps the old shader
for comparison shots). One material as before (B8 8, PASS); no haze (B8 budget, see gb_fire_buildings.md).

## 3. White puffs on freshly built buildings

What makes them (measured windowed, High, a Gloom Hall / Frost Hall / Grove Hall finishing in front of the camera,
`gb_leftovers_shots.gd` settle sequence, and a per-emitter hide-and-count probe):
- the completion burst of FireHallModel / SmallBuildingModel (`BuildFlash` / `Flash`, the base of every hall, house,
  tower, Stables, Bazaar and Forge model): 24-32 additive sparks in the glow colour, 0.35 m, raining from the roof.
  The Ice / Nature / Shadow glow colours are near white, so under the G1 bloom they read as white puffs;
- then the idle emitters that switch on at completion, when their additive motes sum past the bloom threshold:
  ShadowDress soul wisps (the biggest share on Shadow buildings), the Shadow halls' void motes, the Frost Hall's snow
  motes and the Snow Lodge's crystal sparkles.

Fix:
- `art/buildings/build_settle.gd` (new, `BuildSettle`): the completion effect is now a short **settle**: a low ring of
  soft MIX dust rolling out from the foot of the walls in the kingdom's earth tone (colour value capped at 0.5, so a
  pale palette never makes white puffs; process material shared per radius / style / colour), and a few small glints
  in the glow colour x 0.8 (under the bloom), flavoured by the glow hue: Fire embers jump and fall, Ice frost glints
  drift down, Nature pollen and Shadow soul motes rise. 1.2-1.5 s, one-shot, pre-built at `_ready` (no allocation when
  it fires). Fog-safe: `BuildSettle.play` draws nothing for another team's building the local player does not see now
  (`VfxFog.ok`, same rule as the spell / combat hubs), and both emitters carry `no_ghost`. Low: 10 + 10 particles
  (the old burst was 32), High+: 16 + 18 (halls) / two thirds of that (small buildings).
  Wired in `fire_hall.gd` (BuildFlash = the glints, new BuildDust) and `hearth_small_building.gd` (new SettleDust /
  SettleGlint; `Flash` stays the collapse burst). The keeps keep their own construction flash (they are rarely built).
- Idle motes kept under the bloom (colour only, same counts): ShadowDress wisps (team glow x 0.9 at alpha 0.5, smaller)
  and damage embers, the Gloom Hall's void motes (`shadow_hall.gd`, also the Bazaar / Paddock / Gloom Forge), the Frost
  Hall's snow motes (`ice_hall.gd`), the Snow Lodge's crystal sparkles (`ice_lodge.gd`); the Gloom Forge's ichor fume is
  dark.

## 4. No grass under Shadow dead ground

Buildings already cleared the G2a grass (`GroundDetail.refresh_clears`: a circle of `target_radius() + 0.3` m round
every building the player has seen, fog-safe), but the Shadow dead ground reaches 2.7-8.6 m. Now `ShadowDress.attach`
sets the runtime meta `_grass_clear_radius` (dead-ground half size x 0.72: its solid part, the ragged fbm fringe still
lets grass in) on its model, and `GroundDetail.model_clear_radius(building)` (public, static) reads it through
`building.model()`; the clear circle is the larger of the two. Same fog rule (seen buildings only), same 32-circle
budget, no shader change. Medium+ only (no dead ground and no grass at Low).

## Measurements

**Art Lab** (`--gfx=high`; batch `docs/art/lab/gb_leftovers/batch_after.txt`, scorecards
`docs/art/lab/gb_leftovers/after/<asset>/`). Before = the ForgeBuilding placeholder (no model scene to measure) and,
for the Ember Stables, the G-B Fire after-run (`docs/art/lab/gb_fire/after/fire_stables`).

| Asset | Before | After | Notes |
|---|---|---|---|
| fire_forge | placeholder | PASS 92 | 4 569 verts, 7 materials, 19 draws, 48 looping particles |
| nature_forge | placeholder | WARN 91 | 5 973 verts, 8 materials; R5 glow points WARN (12 above the bloom: leaf-card translucency of the branch / hedge clumps, the kiln mouth; the Grove Hall has the same WARN) |
| shadow_forge | placeholder | FAIL 89 (High) / PASS 90 (Low, `after_low/`) | 3 841 verts; the High FAIL is B8 9 materials = the 6 of the model + ShadowDress's dead ground and its two particle quads (every Shadow building has them at High; the G-B Shadow scorecards were taken at Low) |
| fire_stables | PASS 92 | PASS 92 | same budgets (B8 8, 11 164 verts); the Fire layer replaces the neutral one |
| ice_forge (reference) | PASS 91 | PASS 91 | unchanged model; the settle swap only |

**Shots** (windowed 1920 x 1080, `--gfx=high`, `art/buildings/forge/tools/gb_leftovers_shots.gd`: the skirmish map, the
four Forges + a Fire Forge site, damaged Nature / Shadow Forges, the Ember Stables, a Gloom Hall + Hovels on dead
ground, then three halls finishing construction): `docs/art/lab/gb_leftovers/contact_sheet.jpg` (before | after:
forges z30, each forge z10, damaged / site z14, Ember Stables z10, grass on dead ground z12, settle at +4 / +12 / +30
frames; both columns run the new settle code, the "before" column differs only by the placeholders / old Stables /
grass: the old burst was seen in a probe run before the change, not kept); key PNGs `before_q2_forges_z30`, `after_q2_forges_z30`, `after_q2_fire_forge_z10`, `after_q2_settle_f12`.
Everything else regenerates with the tool (`tag=before|after`, `only=...`, `perf=0`).

**fps** (`gb_leftovers_shots.gd`, the forges at zoom 30, High, 600 frames; RTX 3070 Laptop shared with other agents'
Godot runs, so single numbers are noisy):

| Run | avg fps | 1 % low | GPU ms (median) | draws |
|---|---|---|---|---|
| before (placeholders, old Stables, no grass clear) | 100.6 | 75.4 | 8.92 | 1 171 |
| after | 80.5 | 61.6 | 10.20 | 1 386 |

The +1.3 ms GPU / +215 draws are mostly the scene itself: seven placeholder boxes became full Forge models (merged tiers,
idle particles, two heat-haze quads per Ember Forge, ShadowDress on each Gloom Forge); the machine load also moved
between the two runs (one process each, other agents' runs in parallel).

Headless: smoke `victory=true`; perf_test `PERF OK` (norm 6.56 vs limit 6.72, the PC shared with 3-4 other runs).

## Tests

`tests/test_gb_leftovers.gd` (new, headless): the three forge `.tres` find their model and it is the right class with
the six hooks, under the hall vertex budget, Fire = fire_painted_vc at gb_detail 0, Nature = NatureVC, Shadow = no
ShadowDress at Low + dark slate courses; site shows the scaffold, built hides it, < 50 % loses a part, collapse emits
`destroyed_finished`; Ember Stables = fire_stables_painted (gb_detail 0), the other Stables keep theirs, legacy keeps
the old one; settle emitters on every hall and the Hovel (one-shot, `no_ghost`, dust value <= 0.5, flavour per kingdom,
`play` fires them); ShadowDress marks the clear radius and `GroundDetail.model_clear_radius` reads it.

Results 2026-10-15 (after the `--import` that put `IceShapes` back on `art/buildings/ice_hall_shapes.gd`, see the
report): test_gb_leftovers PASS, test_forge_model PASS (6 checks, the Fire Forge model now found), test_gb_fire PASS,
test_gb_ice PASS, test_gb_nature PASS, test_gb_shadow PASS, test_stables PASS, test_g2a_ground PASS, test_fog_leak PASS
(Low, and `-- --gfx=ultra`), test_shader_lint PASS, smoke `victory=true`, perf_test PERF OK (norm 6.56 / 6.72),
test_ws_perf PASS (clash p95 32.3 ms vs 33.0 at load x1.97; a first run at load x1.83 failed on clash p95 44 ms, machine
load; nothing here runs in Wave Strike lanes).

## Files

New: `art/buildings/forge/fire/fire_forge.gd|.tscn`, `art/buildings/forge/nature/nature_forge.gd|.tscn`,
`art/buildings/forge/shadow/shadow_forge.gd|.tscn`, `art/buildings/forge/tools/gb_leftovers_shots.gd`,
`art/buildings/build_settle.gd`, `art/buildings/stables/fire/fire_stables_painted.gdshader`,
`tests/test_gb_leftovers.gd`, `docs/art/gb_leftovers.md`, `docs/art/lab/gb_leftovers/` (`.gdignore`, batch files,
scorecards, contact sheet, 4 key PNGs).

Edited: `art/buildings/fire_hall.gd` (settle), `art/buildings/hearth_small_building.gd` (settle),
`art/buildings/stables/fire/fire_stables.gd` (`_post_build`: Fire layer), `art/buildings/shadow_dress.gd` (grass clear
meta, wisps / embers under the bloom), `art/buildings/shadow_hall.gd` (void motes), `art/buildings/ice_hall.gd` (snow
motes), `art/buildings/ice_lodge.gd` (crystal sparkles), `art/environment/grass/ground_detail.gd`
(`model_clear_radius`, item 4 only).

## Open points

- The keeps' own completion flashes (fire_keep_build / ice_keep_build / dusk_keep_build / nature_keep_build) are
  unchanged: keeps are only built in rare cases.
- Other bright additive idle emitters (Nature hall lanterns' emissive bulbs, the Gloom Hall's soul orb) still bloom at
  High; they are glow points, not puffs, and their R5 Art Lab counts are the G-B owners' calls.
