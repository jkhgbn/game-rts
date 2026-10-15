# G-D ambient life (tech-artist, 2026-10-15)

JS: "make the graphics as beautiful as possible". Wave G-D piece "ambient life" (docs/plan/graphics-week.md): the world
feels alive at zoom 30-40 without clutter. Draw-only scenery; nothing here is read by gameplay.

## Files
| File | What |
|---|---|
| `art/environment/ambient/ambient_life.gd` | `AmbientLife` (Node3D, group `"ambient_life"` + `"lighting_rigs"`): `static ensure(level)`, `set_quality(q)`, the emitters, the flocks, mood, fog filter |
| `art/environment/ambient/ambient_birds.gdshader` | high flocks: all motion in the vertex shader from AmbientLife's `clock` |
| `art/environment/ambient/ambient_wing.gdshader` | butterflies / moths (critter butterfly mesh, wing beat) and tumbling leaves |
| `art/environment/ambient/ambient_glow.gdshader` | additive motes: pollen + sunlit glints by day, fireflies (pulses) at night |
| `art/environment/ambient/ambient_soft.gdshader` | blended snow flakes, dust puffs, flat mist patches, water ripple rings |
| `art/environment/ambient/ambient_common.gdshaderinc` | fog-of-war sampling (the FogOverlay's textures), hashes, particle billboard |
| `art/environment/ambient/gd_ambient_shots.gd` | windowed shots / frame strips / fps (`--map --mood --gfx --tag --strip --fps --no-ambient --fog`) |
| `tests/test_gd_ambient.gd` | headless test (plan, moods, fog, flock scatter, night, Low) |

`art/environment/critters/` (CritterSystem: perched birds, butterflies at flower patches, fireflies, dragonflies, frogs,
splashes) is unchanged: it is the ground-level life, AmbientLife adds the layer above and around it. Its meshes
(`critter_bird.res`, `critter_butterfly.res`) are reused.

## What it draws
- **High flocks** (one MultiMesh, 7 birds per flock): circle 10-16 m up round a centre that drifts over the view; a flock
  more than 62 m from the camera focus re-enters from 78 m away (off screen). Flap-flap-glide, bank into the turn,
  3 palettes (slate swallows, pale doves, brown kites), small moving shadows on the ground at High / Ultra.
  **Scatter**: a fight (a unit with an `attack_target`) or 8+ units within 18 m under a flock make it climb (+5 m) and
  fly 55 m away in 5.5 s, 12 s cooldown. Units count only when `is_visible_in_tree()` and `VfxFog.ok(team, pos)` (a unit
  spawned in fog stays visible until the next fog pass), so a flock never betrays a hidden army (tested). None at night.
- **Seven GPUParticles3D for the whole map**, world-space particles, emitting only from points within 34 m of the camera
  focus (re-picked when the focus moves 6 m, at most every 0.5 s, or every 2 s; fog read once per refresh; max 160 points each), on ground the local player has explored:
  | Emitter | Day | Night | Points |
  |---|---|---|---|
  | Wings | butterflies (5 palettes) | dusty moths (0.45) | meadow / glade |
  | Motes | warm pollen + glints (0.55) | fireflies, 2.5-4.5 s pulses (1.0) | meadow, banks, round tree trunks |
  | Leaves | green / gold, tumbling (0.6) | 0.35 | inside the tree crowns (every EnvProps / dressing tree) |
  | Dust | puffs along roads / heath in wind gusts (3.5 s every 4-10 s) | 0.3 | road segments (ground `road_segs`), heath / ruins |
  | Mist | marsh 0.6, snow 0.35 | soft flat moonlit patches (1.0) | meadow, banks, water |
  | Ripples | rings on the water (0.8, marsh 1.0) | same | deep water |
  | Snow | snow mood only: flurries in a box over the view | same | - |
- **Mood** (re-read every 2 s, so a mission that turns to night switches): night = the rig's sun energy < 0.85 and blue
  (EmberfallNight), snow = rig `preset_id == &"ice"` or a snow / frost biome, autumn = the autumn preset
  (`autumn_swap.apply_lighting`), `autumn_hint` = a layout biome "autumn" still drawn green (late-summer leaf mix),
  marsh = biome "marsh". Mood changes are `amount_ratio` changes (no particle restart).
- **Fog**: emission points are filtered with `FogOfWar.is_explored`; the see-through shaders also fade with the
  overlay's explored / visible textures (0 in black, ~0.45 in grey), since transparent particles draw after the fog box.
  Opaque birds / butterflies / leaves are darkened by the overlay from the depth buffer like any mesh.

## Tiers (`GameSettings.effective_graphics_quality()`)
| Tier | Node | Flocks | Wings | Motes | Leaves | Dust | Mist | Ripples | Snow |
|---|---|---|---|---|---|---|---|---|---|
| Low | **none** (ensure returns null; switching to Low frees every child) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Medium | yes | 1 | 8 | 24 | 10 | 0 | 0 | 6 | 220 |
| High | yes | 3 | 20 | 70 | 30 | 22 | 16 | 14 | 520 |
| Ultra | yes | 4 | 28 | 110 | 44 | 32 | 24 | 20 | 800 |
Caps are the particle `amount` (hard), the mood scales them down. Headless / `-s` runs build nothing (ensure returns null
headless; `-s` runs are Low unless `--gfx`). A level created at Low gets no node; raising the tier in-game takes effect
next match (a node built at Medium+ follows every tier change through the "lighting_rigs" broadcast).
CPU: one `_process` (focus ray, one shader clock, the snow box), 2 Hz flock plan / scatter scan (one pass over
`"units"`), point refresh ~0.1-0.3 ms when the camera moves. Build: ~20-30 ms spread over frames (6 grid rows a frame).

## Hook (lead)
`docs/handoff/for-lead.md` "From tech-artist G-D ambient life": the 5 lines for `scripts/world/main.gd` after the G2a
GroundDetail block. Until then nothing in the game builds it (the shots tool calls `ensure` itself).

## Measured (RTX 3070 Laptop, 1920x1080, Crown Hollow day, fog on, 600 frames; machine shared with other agents)
| Tier / view | before (no node) | after | GPU ms before / after |
|---|---|---|---|
| High full map (zoom 55) | 112.8 fps (low1 81.6) | 106.5 (77.1) | 8.24 / 8.59 |
| High z35 | 121.2 (77.1) | 119.5 (73.2) | 7.53 / 7.41 |
| Ultra full map | 88.2 (66.7) | 84.7 (62.4) | 10.21 / 10.19 |
| Ultra z35 | 95.4 (64.9) | 95.1 (65.5) | 9.39 / 9.47 |
A first pair (fog off "before" vs fog on "after") read the other way round (107.1 -> 112.1 High full map): the cost is
inside the run-to-run noise, at most ~0.4 ms. +~5 draw calls. Targets High >= 90 / Ultra >= 60 kept.

## Shots (`docs/art/lab/gd_ambient/`, `.gdignore`)
To commit: `gd_ambient_sheet.jpg` (day flocks over the base, day river ripples, day meadow butterflies, night at Ultra,
snow, autumn) and 4 PNGs: `v2_crown_day_high_z35.png` (a swallow flock over the base), `v4_crown_night_ultra_meadow32.png`
(fireflies, moths, mist), `v3_crown_snow_high_meadow32.png` (flurries), `v3_quartermeet_autumn_high_centre35.png`
(autumn swap, ripples on the moat). The rest stays local. Re-take: `tools\godot_run.ps1 --path . -s res://art/environment/ambient/gd_ambient_shots.gd
--quit-after 60000 '--' --map=crown --mood=night --gfx=high --tag=x [--strip]`.

## Notes / follow-ups
- The skirmish starts with the tree paused (STR / INT pick): ambient life (particles and birds) is frozen until play.
- Quartermeet / Ashwind / Fourfold are tagged `biome autumn` but nothing swaps them to the autumn look in game yet
  (only `autumn_preview.gd`); their leaves use the late-summer mix until G-E dresses them.
- No snow map exists in the catalog; the snow mood shows on Ice missions (ice preset) and on a future snow biome.
