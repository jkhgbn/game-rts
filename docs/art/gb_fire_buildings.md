# G-B Fire: the Fire kingdom's buildings

Task G-B Fire of the graphics week (docs/plan/graphics-week.md, wave G-B; JS 2026-10-15 "make the graphics as beautiful
as possible"). Every Fire building gets one shared paint layer (stone, bronze, timber, clay tiles), the Fire Keep gets
real tier looks and an upgrade state, and the hot parts get heat haze at High / Ultra. Nothing in `scripts/buildings`
changed; scenes, node names, hooks, footprints, collision, team colour, selection and the construction / damage /
collapse states are as before.

## What changed

| Piece | Before | After |
|---|---|---|
| Painted parts of the Hall, Hearth, Ember Spire, Bazaar, Dragon Roost, Ember Crucible | `painted_vc.gdshader`: flat colour blocks + noise, 2-band toon light | `art/buildings/fire/fire_painted_vc.gdshader` (same vertex contract, same uniforms, swapped in right after `PaintedVC.convert`): surface kind read from the part colour, ashlar courses / flagstones on stone, clay tile rows on team slopes, plank seams + grain on timber, bronze with patina + fake sky reflection, soot, ember bounce, softer wrapped light, light-side rim |
| Fire Keep painted parts | A.7 masonry / tiles / bronze / obsidian patterns, 2-band light; lava joints and obsidian veins bloomed (Art Lab R5: 31 glow points) | same patterns + the Fire paint layer; chiselled block bevels, rounded tile shoulders, kiln-dark tiles; joint lava / veins kept under the bloom level (`lava_glow` 0.55, back to full as damage rises); banner glyph under the bloom |
| Fire Keep tiers | no `set_tier`: Keep.gd drew placeholder gold torus rings over the roof | `set_tier(t)`: **Stronghold** = flying buttresses from the corner towers to the donjon, bronze war-spikes round the donjon crown, tall obsidian finials on the two front roofs, two 10.6 m obsidian standards with team war-banners at the plinth's front corners; **Citadel** adds a crown of eight obsidian blades on the donjon, the forge chimney raised 3.1 m (bronze band, flared crown, glowing mouth; its smoke and haze move up), lava veins down the four corner towers, four obsidian obelisks with ember tips at the plinth corners, a bronze crown hoop over the Ember Heart (on the Spire: it topples with it) |
| Keep upgrade | nothing | `set_upgrading(on)`: a timber-and-bronze scaffold cage round the donjon, a glowing forging band climbing it, the construction sparks on the plinth; `play_tier_up()`: flash from the heart, crystal burst, heart and crystals flare 1.4 s |
| Hearth | 11 unique materials (Art Lab B8 FAIL) | `vc_merge` on: one painted material (6 total), Fire paint layer, timber woodpile / stump / scaffold |
| Timber | bronze stand-ins (firewood, rack, scaffold) | a timber shade (`Color(0.36, 0.22, 0.12)`) on the Hall firewood, weapon rack, Hall / Hearth / Spire scaffolds |
| Heat haze | none | `fire_heat_haze.gdshader`: a small upright billboard that refracts the screen over chimneys, forge mouths, the Bazaar beacon and brazier, the Roost nest and lava pool, the Keep chimney (none on the Spire / Stables: Art Lab B8 budget; one shared material, per-quad `strength` instance uniform). **High / Ultra only** (no node at Low / Medium); every haze carries `set_meta(&"no_ghost", true)` so the fog ghost skips it |
| Damage | flat darkening x0.65 | soot blotches (0.22-0.55 by noise), ember seep glowing in the dark basalt joints near the foot, growing with damage |

## Files

New (all owned): `art/buildings/fire/fire_paint.gdshaderinc` (the layer), `fire_painted_vc.gdshader`,
`fire_heat_haze.gdshader`, `fire_building_look.gd` (`FireBuildingLook`: `apply(body)`, `set_detail(m)`, `detail()`,
`add_heat_haze(...)`, tools-only `legacy`), `fire_keep_tiers.gd` (`FireKeepTiers.build(...)`, uses the keep builder's
`MB` mesh kit, loaded at run time to avoid a preload cycle), tools `art/buildings/fire/tools/gb_fire_shots.gd` (Fire
base on the skirmish map, adapted from the Shadow tool), `gb_fire_keep_tiers_shot.gd` (keep row tier 1 / 2 / 3 /
upgrading + Hall, Hearth, Spire, damaged Hall), test `tests/test_gb_fire.gd`.

Edited: `art/buildings/fire_keep_painted.gdshader`, `fire_keep.gd` (hooks `set_tier`, `set_upgrading`, `play_tier_up`),
`fire_hall.gd`, `hearth_small_building.gd`, `hearth.gd`, `fire_tower.gd`, `market/fire/market_fire.gd`,
`lair/fire/dragon_roost.gd`, `fire/ember_crucible/ember_crucible.gd` (`stables/fire/fire_stables.gd` back to its original).

**Shared base scripts.** `fire_hall.gd` (FireHallModel) and `hearth_small_building.gd` (SmallBuildingModel) are also the
bases of the Ice / Nature / Shadow halls, Bazaars, Stables, Hovel, Night Spire, Ice / Nature small buildings. Every
addition there is opt-in through `_gb_fire()` (false by default; true for `fire_hall.gd` itself by script path, Hearth,
Ember Spire by script path so the Night Spire that extends it stays out, Fire Bazaar, Dragon Roost), `mat_wood` /
`_m_wood` (null = the old trim stand-in) and `_hazes` (empty unless a Fire model adds one). `tests/test_gb_fire.gd`
checks that the Ice / Shadow halls, Hovel and Night Spire keep `painted_vc`.

## Surface kinds (fire_painted_vc)

Read per vertex from the PaintedVC data (part colour = sRGB vertex colour, team flag = alpha, spec = UV2.y):
painted spec 0.03-0.08 on a team or light part = **cloth** (awnings, canvas: no pattern, soft sheen); team = **clay
tiles** on slopes (n.y 0.22-0.96), painted plaster elsewhere; spec >= 0.3 = **bronze** (or **glassy** when darker than
0.26: water, polished obsidian); spec 0.15-0.3 = **dark basalt**; red-dominant, saturated, hue < 13 deg = **lacquer**;
hue < 48 deg and value < 0.7 = **timber**; value < 0.17 = dark basalt; else **stone**. Patterns use the per-facet
model-space normal (derivatives), so smoothed CylinderMesh pyramids and shafts do not swirl. New Fire parts pick their
kind by colour and spec alone (no new data).

## Cost tiers (graphics quality)

`gb_detail` (material uniform) = `GameSettings.effective_graphics_quality()` written once at `_ready` by
`FireBuildingLook.apply` / `set_detail` (Low in every headless / `-s` run).

| Tier | Runs |
|---|---|
| Low (0) | the big patterns (blocks, tiles, planks: ALU only, no extra texture sample), the wrapped light; no haze, no new particles, no extra pass (the tier parts are geometry with the keep's existing two materials) |
| Medium (1) | + sky catch, crease tint, soot streaks (1 sample), bronze reflection + patina, ember bounce, basalt joint seep, light-side rim |
| High (2) / Ultra (3) | + fine detail and bump (2 mipmapped samples, faded out by pixel size), heat-haze quads (one screen read each, ~10 per Fire base) |

## Measurements

Art Lab (`--gfx=high`), before `docs/art/lab/gb_fire/before/<asset>/`, after `docs/art/lab/gb_fire/after/<asset>/`
(batch files `docs/art/lab/gb_fire/batch_before.txt` / `batch_after.txt`):

| Asset | Before | After | Note |
|---|---|---|---|
| fire_keep | WARN 90 (R5: 31 glow points) | PASS 90 | joint lava / veins under the bloom |
| fire_hall | PASS 91 | PASS 90 | |
| hearth | FAIL 81 (B8: 11 materials) | PASS 86 | merged painted material |
| fire_tower | PASS 90 | PASS 90 | |
| ember_crucible | WARN 92 | WARN 92 | R1 silhouette, pre-existing |
| market_fire | PASS 92 | PASS 92 | |
| dragon_roost | WARN 88 (R4k ash dE 9.2) | WARN 89 (dE 11.5) | basalt now reads as ashlar (open issue) |
| fire_stables | PASS 91 | PASS 92 | own shader, untouched |

Kept on disk: each asset's `scorecard.md/json`, `fixes.json`, `z40.jpg` (the other lab images were trimmed, disk rule).

Base shots on the skirmish map (`gb_fire_shots.gd`, 1920 x 1080, before = `legacy=1`: the Fire layer, tiers and haze
switched off at run time; the Hearth's timber colour and merged material stay, the keep keeps its bevel / tile tweaks):
contact sheet `docs/art/lab/gb_fire/gb_fire_contact.jpg` (before | after: base zoom 30 / 50 / 10, damaged Hall zoom 10, keep
row tier 1 / 2 / 3 / upgrading + Hall, Hearth, Spire, damaged Hall); key PNGs in `shots/`: `before_q2_base_z30`,
`after_q2_base_z30`, `after_q2_keep_row`, `after_q2_citadel_z26` (the rest regenerate with the two tools).

FPS (`gb_fire_shots.gd perf=1`, Fire base zoom 30, 1920 x 1080; the machine was shared with 3-4 other agents' Godot
runs, so single numbers are noisy): High, quietest pair, before 120.7 fps (GPU median 6.91 ms) / after 93.1 fps (8.18 ms),
about +1.3 ms GPU (Fire layer + ~10 haze quads); Ultra before 31.5 fps (GPU 25.1 ms) / after 30.0 fps (23.6 ms), within
noise. Draw calls ~1300 -> ~1355. Headless perf test PERF OK (norm 5.72, limit 6.72); smoke victory=true.

Tests: `tests/test_gb_fire.gd` PASS; also PASS test_2_s1, 2_s3, 2_u1, 6_s2, 6_b2, 7_s1, a_9, 9_c1, 9_c3, 10_a1, 10_c1-c4,
10_v1, 12_a2, 12_c5, 12_c10, 13_v25, 13c_v7, g1_settings. `test_tiers` part gates OK (Stronghold + Citadel on a Fire keep, keep HP
3500); its slow bot part (60000 frames) was not run here.

## Open issues

- Fire Stables: the Stables draw with their own one-material `stables_painted.gdshader` (shared `stables_model.gd`, not
  owned here); unchanged (the haze tried there broke the B8 budget and was removed). A Fire variant of that shader would be the next step.
- The Ember Crucible's `ec_painted.tres` is switched to the Fire shader in memory at `_ready` (the .tres on disk keeps
  `painted_vc`).
- Lit windows at night: the windows / gate are already emissive glow materials; no day-night hook was added.
