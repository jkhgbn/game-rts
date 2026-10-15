# G-E fixes B (2026-10-15): night mission, Ice mission snow, depth fog

From the art-direction review `docs/art/ge_review.md`: top-8 items 6 (night mission too dark) and 8 (Ice mission snow
glare), plus review item 14 (depth fog starting at the max zoom). Shots: `docs/art/lab/ge_fixes_b/` (folder has a
`.gdignore`): `gb_contact_sheet.jpg` (before / after pairs, windowed High) and `gb_key_{night,ice_lake,overview_fog}.png`.
Tool: `docs/art/lab/ge_fixes_b/tools/gb_shots.gd` (modes `mission` / `map`, `--dress`, `--lake`) + `gb_sheet.py`.
Test: `tests/test_ge_fixes_b.gd`.

## 1. Night (m00, also e2_04 / e2_05 / e3_02): moonlit, not black

`art/environment/lighting/emberfall_night.gd` `night()` (still built from the warm preset):

| | before | after |
|---|---|---|
| moon (sun) | (0.55, 0.66, 1.0) x 0.55, pitch -38 | (0.62, 0.72, 1.0) x 0.80, pitch -50 from behind the camera's left (shadows fall up the screen, unit fronts lit) |
| fill | (0.30, 0.38, 0.70) x 0.18 | cool rim from the far side (0.42, 0.52, 0.95) x 0.40 |
| ambient | sky contribution 1.0 (the near-black sky) x 0.42 | colour (0.34, 0.43, 0.70), sky contribution 0.35, x 0.46 |
| exposure / brightness / saturation | 0.82 / 0.92 / 0.78 | 1.0 / 1.0 / 0.70 |
| night sky | zenith (0.03, 0.05, 0.12) | (0.04, 0.07, 0.16), horizon a step lighter |

Measured (z45, fog of war off): ground value 0.10 -> 0.20 (target 0.18-0.22); units, the escort and Shadow units read;
torches, braziers and the Fire keep stay the only warm lights. The moon stays under AmbientLife's night test (energy <
0.85, blue > red: fireflies / moths / no birds unchanged) and the ambient energy under test_g1_lighting's 0.5.

Flower noise at night: `LightingPreset.ground_night` (new, 0 = day; `night()` = 1). `EmberfallNight.apply_to` /
`fade_to` call `set_ground_night(level, t)`: the painted ground flowers (ground.gdshader `flower_a..d`) go grey-blue
and darker, `flower_amount` x 0.35, the 3D grass blades follow (`GroundDetail.refresh_flowers()`), and the map
dressing's flower kinds (GladeFlowers, MeadowDaisies, Heather, Gorse, ButterflyBush...) get the per-instance
`night_mute` of `nature_painted.gdshader` (MapDressingArt calls `EmberfallNight.mute_decor` for chunks built after the
night started). Day values are kept on the material (meta `_day_flowers`) and the dawn fade gives them back. Nothing
shared is written (per-level material copy, per-instance uniform).

Not mine (lead / systems / ui): the in-game minimap is still black at night (review item 6), the Fire keep orb bloom
(G-E fixes A), fog of war tint (fog_of_war.gd).

## 2. Ice mission (m02) snow, drifts, lake, border

Where it came from: `scripts/campaign/mission_02.gd` paints the ground snow (`_build_ground`: albedo 0.93-0.98),
builds 28 sphere "sausage" snowbanks (`_add_snowbank`, 5 x 2.9 m capsules every 10 degrees) and white sphere rock caps;
`scripts/campaign/glasswater_lake.gd` builds the lake as a flat StandardMaterial disc; the "cliff fish scales" were not
a cliff: m02 has no map dressing, so the border is ground.gdshader's painted canopy in m02's pale snow colours.
The 3D grass field also grew white blades on the snow and through the lake ice.

New, all in art (`art/environment/snow/`):
- `frozen_look.gd` (`FrozenLook`): `GROUND` values (lit snow albedo 0.59-0.64, packed-snow paths, dark fir canopy),
  `apply_ground(mat, q)`, `drift_mesh(seed, length, depth, height)` (gentle windward slope, steep lee with a small
  cornice, 2-3 humps of different heights, skirt sunk 0.25 m; 6-7.4 m long so the ring reads as one uneven drift wall),
  `shore_lip(radius)`, `snow_material()`, `lake_material(radius, old_ice)`, `dress_level(level)` (idempotent restyle of
  a built frozen level: ground, group `snowbanks`, rock caps, group `glasswater_lake` IceDisc + ShoreLip, GroundDetail).
- `snow_drift.gdshader`: snow at value ~0.8 with cool blue on faces away from the sky and at the mound foot, faint wind
  ripples, glints (`sparkle`, 0 at Low).
- `frozen_lake.gdshader`: deep blue-green ice with a parallax depth layer, ~6 m plates with pale fracture planes (in
  patches, not a mosaic), fine dark hairlines, trapped bubbles, wind-blown snow dust, a frosted rim and the Old Ice
  ring. Integer cell hash (the sine hash gave block seams between value-noise cells on this GPU).
- `ground.gdshader`: `snow_mode` (0 = off, every other map: one uniform test) = drift shading + sastrugi (wind ridges
  in patches, lee shadow + lit crest, faded at range) + no grass in the G2a mask + snow-dusted dark firs on the border
  canopy; `snow_sparkle` (FrozenLook: 0 Low, 0.7 Medium, 1 High / Ultra), `snow_wind`, `snow_shade`.
- `GroundDetail`: `grass_wanted()` (false on snow: no bake, no rings), `refresh()`, `refresh_flowers()`.

Measured (High, same views): lit snow 0.94-0.96 -> 0.76-0.82 (z14 bank 0.76, z30 0.79-0.82, z45 0.81).

**Hook still needed** (systems-coder, `docs/handoff/for-systems-coder.md` "G-E fixes B"): one load-guarded
`FrozenLook.dress_level(self)` call at the end of `mission_02.gd` `_build_map()`. Until it lands the game shows the old
look; the after shots use `gb_shots.gd --dress`, which makes that same call once the mission has started.

## 3. Depth fog: crisp at gameplay zoom, haze only far

RTS camera: max zoom 55 at pitch 55, fov 50 -> the top of the screen is ~90 m away (z40: ~65 m). The old fog began at
55 m (warm) / 40 m (ice) / 50 m (autumn), so every max-zoom view was already tinted at the top.

| preset (Environment) | begin | end | curve | density | fog at 90 m | at 220 m |
|---|---|---|---|---|---|---|
| warm `world_env.tres` (all skirmish maps, night / dawn) | 55 -> 85 | 190 -> 280 | 1.6 -> 1.5 | 0.55 | 0.031 -> 0.000 | 0.55 -> 0.38 |
| ice `world_env_ice.tres` | 40 -> 80 | 160 -> 260 | 1.4 -> 1.5 | 0.7 -> 0.65 | 0.178 -> 0.001 | 0.70 -> 0.53 |
| autumn `world_env_autumn.tres` (Quartermeet, Ashwind, Fourfold) | 50 -> 85 | 180 -> 280 | 1.5 | 0.6 | 0.064 -> 0.000 | 0.60 -> 0.41 |

No height fog: it would tint the near ground at every zoom. `preset_golden.tres` (forge_evenmead stage set, ground-level
cinematic camera, generated by its own make_light.gd tool) and the menu diorama are not gameplay views: unchanged.
Crown Hollow z55 and overview, Thornwater and Quartermeet z55 checked: the overview top went from tan wash (corner
value 0.65 tan) to readable forest (0.53). A 176 m map's free-camera overview (185 m up) still shows aerial haze by
design; no gameplay camera goes there.

## Tier rule
Low keeps today's cost: no new pass, particles or post-process. The night is a preset change; the snow branch only
runs on frozen maps (uniform-gated), glints are 0 at Low; `night_mute` is one instance uniform read. test_g1_lighting
(Low = the .tres exactly) passes unchanged.
