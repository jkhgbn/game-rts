# G3b: unit materials (painted PBR for every unit)

Task G3b of the "graphics as beautiful as possible" block (2026-10-15). One shared shading layer lifts every unit at
once: all soldiers, workers, casters, champions, mounts, helpers, neutrals, beasts and titan parts that use the kit's
`unit_painted.gdshader` (225 materials) or the champions' one-material `champion_palette.gdshader`. No mesh, node,
animation, LOD or team-colour API changed.

## What changed

| Layer | Before | After |
|---|---|---|
| Diffuse | hard 2-band toon ramp | 60 % smooth wrapped ramp + 40 % the old bands (same energy at the terminator), a cool fill on the turned-away side (`shade_tint`), a warm saturated terminator (skin 0.5, cloth / fur 0.28, rest 0.12) |
| Specular | one Phong lobe when `spec_strength > 0` | per surface: metal = sharp + broad Blinn tinted by its own hue; leather / skin / wood / bone soft sheen; cloth / fur velvet sheen at grazing angles; plain keeps the old Phong |
| Rim | view rim (emission), same on every side | view rim fades on undersides (no "cut-out, floating" ring from the RTS camera) + a light-side rim (`light_rim` 0.32): a crisp sun catch along the lit silhouette |
| Value read | height gradient + contact band | + tops catch the sky (+15 %), undersides take a tinted crease AO (`crease_tint`), a stronger top-to-bottom gradient (x 0.84 legs .. x 1.07 crown) from Medium up |
| Cloth (team colour) | flat colour | soft vertical folds where the dye pools (darker, more saturated), paler worn ridges, a fine twill weave close up: the team colour reads dyed into the cloth |
| Metal | flat colour + Phong | darker diffuse + a small fake sky / horizon / ground reflection (emission, `env_strength`), brushed streaks close up |
| Leather / wood / fur / bone | flat colour | scuffs, pebble grain / wood grain / strands / pits |
| Fine detail | none | weave, brushing, grain, strands, pits also bend the normal (derivative bump); each fades out once a pixel is wider than half its period, and is skipped per pixel then (an RTS-zoom pixel never pays for it) |
| Capes / pennons (`banner.gdshader`) | one sine wave, toon ramp | opt-in `unit_cloth = 1` (unit capes only; buildings' banners unchanged): gusts, a flutter on the free edge, fold normals, woven thread tint, dye pooling at the hem, softer light, velvet sheen |
| Hit / level-up flash | | unchanged, line for line |

Files: `art/units/kit/unit_paint.gdshaderinc` (the layer), `art/units/kit/unit_painted.gdshader`,
`art/units/champions/champion_palette.gdshader` (+ `champion_palette.gd` folds `surface_kind` into `pal_extra.w`),
`art/shaders/banner.gdshader`, `art/units/kit/character_model.gd` (kit_detail), `art/units/kit/README.md` (slot table).

## Surface kinds

`surface_kind` (material uniform): -1 auto (`spec_strength >= 0.15` = metal, else plain), 0 plain, 1 cloth, 2 metal,
3 leather, 4 skin, 5 wood, 6 fur / hair / hide, 7 bone / horn / stone. Written into every unit material outside
`art/units/wizards/` (G3a's) by `art/units/kit/tools/assign_surface_kinds.ps1` from the material's name (owner prefix
stripped: `tusker_hide` -> `hide`; animal coats / hides in mounts / neutral / titans = fur). Re-run it after adding
unit materials (idempotent, keeps line endings, `-DryRun` lists). The kit palette's kinds are also in
`tools/make_materials.gd` (`SURFACE_KINDS`), so regenerating the palette keeps them. Team-colour variants are
duplicates, so they keep their kind. 213 materials tagged; 3 skipped (see Open issues).

## Cost tiers (graphics quality)

Instance uniform `kit_detail` on slot **12** (slots 7-11 are already the titans' / critters' own: `membrane_tint`,
`root_morph`, `gait`...). `CharacterModel` writes it on every painted draw instance from
`GameSettings.effective_graphics_quality()` (`DETAIL_BY_QUALITY` = Low 0, Medium 1, High 2, Ultra 2), re-read every 30
frames and applied on each model's 0.5 s tier tick, so a settings change reaches live units. Shader default 2 (a model
the kit does not drive still gets the look).

| kit_detail | Runs |
|---|---|
| 0 (Low) | new light ramp, sheen, rims only (a few ALU over the old shader) |
| 1 (Medium) | + sky catch, crease tint, folds, value gradient, metal reflection |
| 2 (High / Ultra) | + fine detail and bump (only on pixels closer than ~8 m) |

Scripts and labs are "quiet runs" (Low) unless `-- --gfx=high`. Lead ruling 2026-10-15 (CLAUDE.md "Graphics
quality"): Low keeps the pre-G1 lighting / effect cost, better materials apply at every tier while perf_test and
test_ws_perf pass, so Low keeps the new light ramp and sheen (shots `after_low_*`) and drops the rest.

## Measurements

Sample: Hall units flame_guard (fire), rimeshield (ice), thornling (nature), shade (shadow), champion oathwall, mount
dusk_steed. Art Lab before: `docs/art/lab/g3b_materials/before/<asset>/`, after (`--gfx=high`):
`docs/art/lab/g3b_materials/after/<asset>/` (batch files `batch_before.txt` / `batch_after.txt` next to them).

| Asset | Before | After | Notes |
|---|---|---|---|
| flame_guard | WARN 90 | WARN 91 | same 3 WARN (footprint, team colour vs meadow in nature green, colour-blind pair): not material issues |
| rimeshield | WARN 93 | WARN 93 | same 2 WARN (head height, footprint) |
| thornling | WARN 90 | WARN 89 | R3 meadow contrast dE 15.5 -> 16.5 (better); R5 glow point now WARN: its soft glow lost a few L* of contrast against the brighter sky-catch surround (borderline, median 1/0/0 vs 0/1/0) |
| shade | PASS 97 | WARN 96 | A2 death_finished 2.59 s = the machine was loaded (73 s run, balance batch); the death timeline is code, not material |
| oathwall | PASS 93 | PASS 95 | R12 dL +6 -> +10 under autumn |
| dusk_steed | FAIL 91 | FAIL 91 | B4 vertex FAIL is pre-existing (mesh budget) |

GPU, `art/units/kit/tools/g3b_shots.gd -- --gfx=high --perf [--legacy]`: 240 soldiers filling the zoom-30 view,
1600 x 900, MSAA 4x, RTX 3070 Laptop, while a 3-process balance batch ran: legacy 3.45 / 4.54 ms, G3b 4.17 / 4.66 ms
(whole frame incl. ground; two runs each, noisy). About +0.1 .. +0.7 ms at High for a screen full of units. The Art Lab
B13 "GPU +x ms per 100 units" figures swing from -19.7 to +12 ms between runs on this loaded machine and are noise.
perf_test / test_ws_perf are headless (CPU only): the CPU side is one `set_instance_shader_parameter` per painted draw
instance at spawn and on a tier change.

Shots (`docs/art/lab/g3b_materials/shots/`, before = the pre-G3b shaders swapped in at runtime, same scene):
`<before|after>_army_z30.png`, `_army_z30_crop2x.png`, `_army_z40.png`, `_close_<row>.png` (zoom 9) and
`_portrait_<row>.png` (zoom 4), rows fire / ice / nature / shadow / champions / mounts; `pg_perf_240.png`.

Honest read: at zoom 30-40 the change is a better value structure (lighter crowns, darker legs, a sun rim on the
silhouette, metals that catch the sky), not a new look; at portrait / cinematic distance materials now read as cloth,
metal, leather, fur and wood instead of flat colour blocks.

## Tests

`tests/test_g3b_materials.gd` (headless): shaders include the layer and keep the slot map (kit_detail 12, nobody else on
12, banner keeps one instance uniform), palette kinds, every tagged material in 0..7, unit capes on `unit_cloth`, the kit
writes `kit_detail` on every painted draw instance and the hit flash still lands. Also run: kitfix audit (KITFIX AUDIT
OK, 0 collisions), test_11_v4 PASS, test_kit_team_color PASS, test_11_v1 PASS, smoke victory=true, perf_test PERF OK
(norm 5.59 / limit 6.72), test_ws_perf PASS (march p95 20.19 ms, clash p95 23.93 ms at 200 units, budget 23.03 ms).

## Open issues

- `art/units/nature/stagrunner/materials/stagrunner_blade.tres`, `stagrunner_leaf_amber.tres`, `stagrunner_leaf_gold.tres`
  have a garbled last line (`shader_parameter/rim_strength = 0.95, 1.0, 0.8S`, no newline); the loader stops there, so
  their rim strength is the default. Not touched (the tool skips them); the owner should fix the value.
- Wizards (`art/units/wizards/`, G3a) get the new light through the shared shader, but their materials have no
  `surface_kind` yet (auto: metal by spec, else plain). G3a can add the line (or run the tool on their folder).
- `mender_painted.gdshader`, `ice_crystal`, titan / beast special shaders keep their own look (not on the kit shader).
