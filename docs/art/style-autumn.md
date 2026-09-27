# Style bible: GOLDEN AUTUMN (Fourfold Hollow, the 2v2 map)

Task 20.V0, 2026-09-26, tech-artist / art director. User choice: **golden autumn** for Fourfold Hollow
(`docs/design/map-2v2.md`): russet and golden forests, ochre grass, soft ground mist, warm lanterns, **the same painted
look as Crown Hollow** (`docs/design/art-keep.md` 0: chunky shapes, colour blocks, toon ramp, light tops / dark feet,
no textures, no outlines). Nothing new is modelled for the mood: the map swaps **materials and uniforms** onto the
existing meshes (map-2v2.md: "a maximum of what we already have").

Files (all new, nothing existing edited): `art/environment/autumn/`
| File | What |
|---|---|
| `autumn_ground_params.gd` | The ground preset: every colour uniform of `ground.gdshader` (grass, dirt, road, banks, biome tints, flowers = fallen leaves, canopy, haze). Colours only, never zones. `load()` it, `apply(mat)` |
| `nature_autumn.gdshader` + `nature_autumn_mat.tres` | Variant of `nature_painted.gdshader` (trees, decor, rocks, border forest). One marked block `AUTUMN 20.V0`; a superset of the original's uniforms (test) |
| `horizon_autumn.gdshader` + `horizon_autumn_mat.tres` | Variant of `horizon.gdshader`: the baked green vertex colours remapped to autumn canopy blocks per ~9 m cell |
| `water_autumn_mat.tres` | `water.gdshader` with autumn colours (only colour keys are copied onto the ford / mouth water) |
| `world_env_autumn.tres` + `preset_autumn.tres` | The lighting preset (a `LightingPreset` resource, values only: the rig makes the lights) |
| `autumn_swap.gd` | Runtime swap for an already-built map: `swap_shared_materials()`, `apply_ground(root)`, `apply_lighting(root)`, `release()` |
| `autumn_preview.gd` | The preview renderer (section 7) |
Test: `tests/test_20_v0.gd` (`PASS 20.v0`).

## 1. Palette (sRGB; the ground / material uniforms are `source_color`)
### 1.1 Ground (`autumn_ground_params.gd`)
| Role | Uniform | Value | Hex |
|---|---|---|---|
| Grass shade side | `grass_dark` | (0.26, 0.23, 0.13) | `#423B21` olive umber |
| Grass lit patch | `grass_light` | (0.45, 0.39, 0.20) | `#736333` ochre |
| Grass warm patch | `grass_warm` | (0.50, 0.35, 0.17) | `#80592B` russet ochre |
| Grass cool patch (the last green) | `grass_cool` | (0.22, 0.26, 0.15) | `#384226` |
| Grass dry patch | `grass_dry` | (0.56, 0.47, 0.28) | `#8F7847` straw |
| Clover | `clover_color` | (0.28, 0.29, 0.13) | `#474A21` |
| "Flowers" = seed heads / fallen leaves | `flower_a..d` | cream / gold / aster / russet | `#EDDBA8` `#F2AD33` `#945C80` `#C75429` (amount 0.85) |
| Dirt / dark dirt | `dirt_color` / `dirt_dark` | (0.42, 0.33, 0.23) / (0.28, 0.20, 0.14) | `#6B543B` / `#473324` |
| Road / dark road / cobble | `road_color` / `road_dark` / `cobble_color` | | `#80664C` / `#574230` / `#8C8273` |
| Rock rim | `rock_color` | (0.38, 0.35, 0.33) | `#615954` |
| Painted canopy beyond the edge | `canopy_dark` / `canopy_light` | | `#2B140D` / `#8F4F1A` |
| Edge haze | `haze_color` | (0.62, 0.52, 0.42) | `#9E856B` |
| River banks wet / damp / sand | `bank_wet` / `bank_damp` / `bank_sand` | | `#291F17` / `#52402B` / `#947D57` |
| Heath accents: bracken, gorse, blossom | `heather_color` / `gorse_color` / `blossom_color` | | `#784038` / `#9E752E` / `#F2A838` |
| Old Wood floor: leaf litter, moss | `needle_color` / `moss_color` | | `#5C361C` / `#474C1F` |
| Biome tints: meadow, heath, old wood, riverbank | `biome_tints[4]` (strength 0.62) | | `#6E6130` `#804F2E` `#3B2617` `#474F2B` |
Knobs: `patch_contrast` 0.8 (vs 0.58: autumn ground needs its big light / dark patches to avoid a flat ochre sheet),
`tuft_density` 0.5.

### 1.2 Foliage tiers (`nature_autumn_mat.tres`)
| Tier | How it is chosen | Colour | Hex |
|---|---|---|---|
| Crown: russet 30 % | leaf crowns (kind 2), instance hash | (0.62, 0.22, 0.08) | `#9E3814` |
| Crown: amber 30 % | | (0.80, 0.44, 0.11) | `#CC701C` |
| Crown: gold 30 % | | (0.86, 0.64, 0.17) | `#DBA32B` |
| Crown: late green 10 % | | (0.44, 0.45, 0.16) | `#707329` |
| Undergrowth (leaves below 1.1-2.1 m: ferns, bushes) | bracken / straw by hash | (0.58, 0.34, 0.13) / (0.56, 0.46, 0.22) | `#945721` / `#8F7538` |
| Evergreens (pines, firs: dark needles) | kept, `needle_tint` (0.86, 0.94, 0.80) | the baked greens, a bit darker | the **cool anchor** |
| Willows, ivy, bright needles | `willow_tone` x 0.8 | (0.56, 0.47, 0.17) | `#8F782B` |
| Grass blades (needles / ivy below 0.45-0.95 m) | straw | `#8F7538` | |
| Gold trees (kind 6), stone, bark | unchanged | | |
Every recolour keeps the baked value (`tone * clamp(lum / 0.10, 0.35, 1.7)`): the light / dark structure of the
painted crowns survives, only the hue moves.

### 1.3 Horizon, river, sky, light
| Part | Values |
|---|---|
| Horizon canopy blocks (`horizon_autumn_mat`) | russet `#8C381A`, amber `#B26B24`, gold `#C29938`, evergreen `#33452B` (22 %); per 9 m cell; 88 % remap (keeps a little baked aerial cooling) |
| River (`water_autumn_mat`) | deep `#0D2626`, water `#1F453B`, bank `#455E40`, sky reflection `#B8AD94` (warm), foam `#EDE6CC`, glint `#FFDB99`. The water stays the one **cool, dark** band of the map |
| Sky (`world_env_autumn`) | zenith `#5C7AB2`, horizon `#F0C48A`, ground horizon `#6B5238`, sun tint `#FFBD6B`, halo 0.55 |
| Sun | `#FFD199` (1.0, 0.82, 0.60), energy 1.32, pitch -44 / yaw 34 (lower than warm's -52: longer, softer shadows), blur 1.8, opacity 0.95 |
| Fill | `#8599EB`, energy 0.28 (the cool shadow side matters more on a warm map) |
| Ambient | `#8085A8`, energy 0.68 |
| Fog (depth) | light `#E6BF8F`, density 0.6, begin 50 / end 180, sun scatter 0.25, aerial 0.3 |
| Ground mist (screen haze of the vignette) | `#FADBA8`, strength 0.16, height 0.30; vignette `#1F0F08` 0.36 |
| Lanterns / glows | unchanged (`lantern_glow_mat`, `ember_glow_mat`): warm points read even better on the darker ochre |

## 2. How a map goes autumn (no new meshes)
1. Build the zones as usual: `GroundParams.apply(ground_mat, river)` + biomes (1v1: `skirmish_biomes()`, 2v2:
   `fourfold_biomes()` from 20.V3).
2. `load("res://art/environment/autumn/autumn_ground_params.gd").apply(ground_mat)` (and on `plateau_mat` for the
   forest floor ring). It overrides `biome_tints`, never zones.
3. Materials: the 2v2 level uses `nature_autumn_mat.tres` / `horizon_autumn_mat.tres` / `water_autumn_mat.tres` where
   the 1v1 uses the shared ones. Until the builders take a material argument, `autumn_swap.gd`
   `swap_shared_materials()` edits the cached shared materials in memory (process-wide: only in the 2v2 match
   process, never in tests that build the 1v1 afterwards).
4. Lighting: `main.gd _lighting_preset()` returns `&"autumn"` in `Skirmish2v2` once `LightingRig.PRESET_PATHS` has
   `&"autumn": "res://art/environment/autumn/preset_autumn.tres"` (a one-line request, 20.V3 owner). Until then
   `autumn_swap.gd apply_lighting(root)`.

## 3. Value structure: units of all 4 kingdoms stay readable
The autumn ground sits in a **mid-dark, low-chroma value band** so the team colours sit outside it:
| Layer | L* (CIE) | Chroma | Rule |
|---|---|---|---|
| Ground (grass mean) | 25-55 (measured 37) | <= 35 | No play-area ground tone above L* 55 or with chroma above ~40 |
| Road / dirt | 35-45 | <= 25 | Reddish brown, darker than the lit grass |
| Crowns (above the units, not behind them) | 35-70 | high | Saturated autumn lives **up in the trees**, never on the floor where units stand |
| Evergreens, river | < 30 | low | The cool dark anchors |
| Fire team `#D94D1F` | 52 | ~75 | Much more chroma than any ground tone: dE >= 46 to the whole autumn ground (test) |
| Shadow team `#6B3899` | 36 | ~65 (purple) | Opposite hue to the ochre: dE ~70; its glow `#B34DFF` carries it at zoom 55 |
| Ice team `#73BFF2` | 74 | ~35 (blue) | Lightest thing on the map + opposite hue: dE ~61 |
| Nature team `#59B340` | 65 | ~65 (green) | Brighter and far greener than `grass_cool` (the only green floor tone): dE ~56 |
`tests/test_20_v0.gd` asserts dE76 >= 20 between each team colour and every ground tone (measured: Fire 46.3, Shadow 69.7,
Ice 60.9, Nature 55.7) and the grass mean L* in 25-55 (measured 37.3).
Risks and rules:
- **Fire vs russet crowns** (dE ~20): Fire units under a russet crown are the weakest case. Keep lanes, fords and
  capture points clear of russet crowns by 3 m (they already are: forest clearings) and never use russet on the floor.
- **Fallen-leaf flowers** (`flower_b`, `flower_d`) are small dots (tufts); keep `flower_amount` <= 0.9 so they never
  form orange sheets that a Fire squad melts into.
- **Nature units** read against the ochre by hue; the late-green crown share stays <= 10 % and `grass_cool` stays dark.
- Selection rings and health bars keep their team colours; nothing changes in the unit art.

## 4. What each asset family becomes
| Family | Autumn version | How (files) |
|---|---|---|
| Ground shader | Ochre / olive grass with russet and straw patches, fallen leaves for flowers, reddish-brown roads | `autumn_ground_params.gd` |
| Biome: Hearth Meadow (hubs) | Ochre meadow, gold leaf dots, straw tufts | tint `#6E6130`; meadow decor via the nature material |
| Biome: heath (`max(|x|,|z|) > 68`) | Bracken russet heath, gorse ochre; the heather bushes keep their baked mauve / pink (vertex colours) | tint `#804F2E`; 20.V4 decides whether heath decor density drops (see 5) |
| Biome: Old Wood (`(+-62, 0)`) | Dark leaf-litter floor, russet ferns, evergreens and glowcaps (the blue glowcaps become the Old Wood's accent) | tint `#3B2617`, `needle_color` litter |
| Biome: riverbank | Damp olive, yellow willows, straw reeds | tint `#474F2B`, `willow_tone` |
| Biome: ruins / glade | Unchanged stone; glade decor turns straw / bracken | nature material |
| Trees: broadleaf, birch | Russet / amber / gold / late-green crowns by position hash | `nature_autumn_mat` |
| Trees: pine, fir | Evergreen, a touch darker | `needle_tint` |
| Trees: willow | Yellow-olive curtains | ivy kind -> `willow_tone` |
| Trees: gold | Unchanged (already autumn) | |
| Border forest (lite stand-ins) | Autumn crowns too (the original excluded them from the rare autumn crown) | `nature_autumn` |
| Horizon | Autumn canopy blocks, ochre hills, evergreen clumps | `horizon_autumn_mat` |
| Landmarks (colossus, stump, stones, aqueduct, barge) | Stone unchanged; their moss caps turn olive (`moss_color`), rune glows unchanged | nature material moss |
| Camps (mud, glow) | Unchanged (mud is already brown; camp glows are warm points) | |
| River, fords, mouths | Warmer sky reflection, darker teal: the cool band | `water_autumn_mat` (colour keys only) |
| Crown Isle | Unchanged (paving, lava, runes): its glow becomes the warmest point of the map | |
| Lighting | Golden low sun, cool fill, warm fog and ground haze | `preset_autumn.tres` |
| Critters | Butterflies stay; (20.V7) swap some butterflies for drifting leaves | |

## 5. Refined 20.V tasks (map-2v2.md 7 + the autumn look)
| Id | Task (refined) | Done when |
|---|---|---|
| 20.V1 | Map edge for 168 m as in map-2v2.md, **plus** the cliff / plateau builds read `plateau_mat` with the autumn ground params applied at runtime (no new plateau material) | 1v1 byte-identical; 2v2 ring closes; plateau shows litter + autumn canopy |
| 20.V2 | Horizon re-bake for 168 m **with `horizon_autumn_mat.tres`** as the 2v2 material (the bake keeps green vertex colours; the shader remaps) | Seamless at zoom 40-55, 4 corners; 8 meshes, 1 material, no shadows |
| 20.V3 | Ground zones for 4 hubs (`fourfold_biomes()`), **then** `autumn_ground_params.apply`; add `&"autumn"` to `LightingRig.PRESET_PATHS` and `Skirmish2v2._lighting_preset() -> &"autumn"` (request to 20.C4) | 2v2 screenshot shows the section-4 biomes in autumn; 1v1 identical |
| 20.V4 | Map dressing 2v2 **with a material table**: `MapDressingArt` takes the nature material from the level (2v2 = `nature_autumn_mat`), so the in-memory swap of `autumn_swap.gd` is no longer needed; heath decor density -20 % (the mauve heather bushes are spring-coloured) | <= 12 000 instances, <= 140 draw nodes; 1v1 counts unchanged |
| 20.V5 | River dressing for the straight arms; the barges / aqueducts take `water_autumn_mat` for their water; leaf rafts (flat draw-only quads in `nature_autumn_mat`) on the slow bends | Arms do not read as a canal at zoom 55; 0 colliders |
| 20.V6 | Lobby map preview rendered **with the autumn look** (autumn_swap + the 2v2 map) | Matches the built map |
| 20.V7 (new, small) | Autumn atmosphere: ground mist cards (reuse `river_mouths/mouth_mist.gdshader` as low 8-12 m cards in the Old Wood and over the river, no lights), a falling-leaf GPU particle band per Old Wood (<= 2 emitters, <= 200 particles each), lantern posts at the 8 posts / ring-road bridges (reuse `lantern_glow_mat`, emission 2.5, no real lights) | GPU <= +0.3 ms at zoom 40 on the user's desktop; no unit readability loss (Art Lab v2 runs of 8) |

## 6. Art Lab v2 runs to do (once v2 lands; not run in 20.V0: the lab is being rebuilt)
Art Lab v1 grounds are `meadow | heath | old_wood | riverbank | dirt` and lights `warm | ice`. v2 needs a ground
override that takes a **ground param preset script** (`ground=res://art/environment/autumn/autumn_ground_params.gd`
plus a biome name, e.g. `ground=autumn:meadow`) and a lighting preset path (`light=res://art/environment/autumn/preset_autumn.tres`).
Runs (8, `quick=1` first, then full):
| # | scene | kind | kingdom | ground | Expected |
|---|---|---|---|---|---|
| 1 | `res://art/units/fire/flame_guard.tscn` | unit | fire | autumn:heath (bracken, the worst case) | PASS: body vs ground dE >= the unit budget (`de_*` of lab_budgets), melt fraction under budget |
| 2 | `res://art/units/fire/ember_archer.tscn` | unit | fire | autumn:meadow | PASS; team colour check |
| 3 | `res://art/units/shadow/shade.tscn` | unit | shadow | autumn:old_wood (darkest floor) | WARN possible on dL (dark on dark): the hue gap + glow must carry it; if FAIL, raise `tint_oldwood` to `#47301D` |
| 4 | `res://art/units/shadow/nightbolt.tscn` | unit | shadow | autumn:meadow | PASS |
| 5 | `res://art/units/ice/rimeshield.tscn` | unit | ice | autumn:riverbank | PASS (lightest on mid) |
| 6 | `res://art/units/ice/shardcaster.tscn` | unit | ice | autumn:meadow | PASS |
| 7 | `res://art/units/nature/thornling.tscn` | unit | nature | autumn:riverbank (the greenest floor) | PASS by hue; watch `hue_gap` |
| 8 | `res://art/units/nature/bramblehorn.tscn` | unit | nature | autumn:old_wood | PASS |
| 9 | `res://art/environment/biomes/meadow/meadow_set.gd` | decor_set | neutral | autumn:meadow | PASS instance / draw budgets unchanged (materials only) |
| 10 | `res://art/environment/biomes/old_wood/old_wood_set.gd` | decor_set | neutral | autumn:old_wood | PASS; glowcaps are the only emissive |
Decor sets need the lab to accept a material override (`material=res://art/environment/autumn/nature_autumn_mat.tres`)
or run after `autumn_swap.swap_shared_materials()` in the lab process.

## 7. Previews (`docs/art/screens/20_v0_*.png`, 1600 x 900, game camera pitch 55, fov 50)
Command: `tools/godot_run.ps1 --path . -s res://art/environment/autumn/autumn_preview.gd --resolution 1600x900
--fixed-fps 60 --quit-after 9000 '--' tag=autumn` (`tag=warm autumn=0` renders the same staging in the default look).
The real Crown Hollow skirmish, bot / fog / HUD off, with Fire + Nature (team 0) and Shadow + Ice (team 1) squads idle
on the field and by the north edge, and fighting in the centre.
| Shot | Autumn | Warm (same staging) |
|---|---|---|
| Field, 4 kingdoms, zoom 40 / 55 | `20_v0_autumn_field_z40.png`, `_field_z55` | `20_v0_warm_field_z40.png`, `_field_z55` |
| Centre fights, zoom 40 / 55 | `20_v0_autumn_fight_z40.png`, `_fight_z55` | `20_v0_warm_fight_*` |
| Fire base, zoom 40 | `20_v0_autumn_base_z40.png` | `20_v0_warm_base_z40.png` |
| North edge + horizon, zoom 55 | `20_v0_autumn_edge_n_z55.png` | `20_v0_warm_edge_n_z55.png` |
Eye check (lead): all four kingdoms read at zoom 40 and 55 (Fire orange by chroma, Shadow purple by hue, Ice by
value, Nature green by hue); the forests read russet / amber / gold with dark pines as anchors; the river is the cool
band. Known limits: the heath heather bushes keep their baked mauve / pink; cliffs and ruins keep their stone greys
(correct); some small props (tavern roofs) are orange-ochre and sit close to the grass hue (they are buildings, fine).
