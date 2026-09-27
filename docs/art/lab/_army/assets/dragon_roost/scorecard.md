# Art Lab scorecard: dragon_roost

Scene `res://art/buildings/lair/fire/dragon_roost.tscn` · kind **building** / tier **hall** · kingdom fire · ground meadow · 2026-09-27 09:47:35 · lab v2.0

## Result: **FAIL** · quality **85 / 100**

1 FAIL · 4 WARN · 15 PASS · 11 info · 0 skipped · 55 s

## Improve next
1. **Unique materials** (FAIL): B8 17 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-7256` -> `StandardMaterial3D#-70684` (dE 0.0), `StandardMaterial3D#-70684` -> `StandardMaterial3D#-15114` (dE 0.0), `StandardMaterial3D#-15114` -> `StandardMaterial3D#-1255` (dE 0.0), `ShaderMaterial#-10015` -> `ShaderMaterial#-68339` (dE 5.9), `ShaderMaterial#-40748` -> `ShaderMaterial#-68339` (dE 20.1), `StandardMaterial3D#-97434` -> `StandardMaterial3D#-1255` (dE 36.8), `ShaderMaterial#-13905` -> `ShaderMaterial#-91317` (dE 37.8), `ShaderMaterial#-91317` -> `ShaderMaterial#-68339` (dE 61.2), `StandardMaterial3D#-4763` -> `StandardMaterial3D#-1255` (dE 83.4) [fixes.json #1] _(from B8 Unique materials)_
2. **Contrast on the home ground (ash)** (WARN): shader_parameter/base_color of `ShaderMaterial#-40748` #473d3b -> #55402b (21% of the visible body): predicted dE R3 meadow 57.6 -> 54.1, R3t fire 58.4 -> 54.7, R3t shadow 58.5 -> 54.9, R3t ice 56.1 -> 53.0, R3t nature 56.9 -> 53.3, R4k ash 11.3 -> 18.2 (want >= 18); other grounds heath 30.8, old_wood 19.8, riverbank 32.2, snow 60.9, sand 54.9, marsh 15.7; built in code or embedded: change it where the model script creates it [fixes.json #2] _(from R4k Contrast on the home ground (ash), shot z40)_
3. **Glow points at 40 m** (WARN): Glow points 28 -> 3 (want 2-4): ShaderMaterial#-59788 energy 3.0 -> 0.03 (dim under the bloom level: 9 point(s), peak 5.96 x the level); ShaderMaterial#-32874 energy 2.3 -> 0.05 (dim under the bloom level: 9 point(s), peak 4.49 x the level); ShaderMaterial#-36677 glyph_energy 1.0 -> 0.17 (dim under the bloom level: 3 point(s), peak 4.49 x the level); StandardMaterial3D#-70684 emission x 0.16 (dim under the bloom level: 2 point(s), peak 4.64 x the level; no energy parameter found: scale its emission colour / strength); ShaderMaterial#-87468 energy 2.2 -> 0.12 (dim under the bloom level: 2 point(s), peak 3.76 x the level) [fixes.json #3] _(from R5 Glow points at 40 m, shot glow)_
4. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 30 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #4] _(from B9 Materials built per instance)_
5. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (protan) look alike on this model (dE 11.6): add a value step inside the team-colour area [fixes.json #5] _(from R6cb Team colours for colour-blind players, shot teams)_
6. **Contrast on the other grounds** (PASS): On ash the body drops to dE 11.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 43 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 30 material(s), 10 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 16 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 19 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 5259 (biggest: NestBowl 1303, Spire 1170, Gatehouse 593, NestSpikes 504) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 13 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 36 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 10 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 17 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 24 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 42 surfaces over 16 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 562 of 3600 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 39649 px (217 x 300 bbox; 55 m: 19656 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 57.6, 0% of the body melts (within dE 15 of the ground); body L* 30.9 C 15.9 vs ground L* 60.6 C 50.2, hue gap n/a (body C* <= 25); top third (world height) dE 52.4, L* 36.1; per-pixel dE 66.6, outline 51.3 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | **WARN** 48 | dE 11.3, 32% melts (ash is where fire units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 82 | worst ash: dE 11.3 (heath dE 34.2, old_wood dE 21.8, riverbank dE 33.2, snow dE 60.2, ash dE 11.3, sand dE 58.4, marsh dE 12.9) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 28% of body pixels change between kingdom colours (min pair 22%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst ice colour: dE 56.1 (fire 58.4, shadow 58.5, ice 56.1, nature 56.9) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 45 | worst pair fire / nature (protan): dE 11.6 on the team-colour area (normal vision 15.4; 17843 px); deutan: shadow / ice dE 11.8; protan: fire / nature dE 11.6; worst vs ground: ice colour (deutan) dE 37.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | PASS 98 | worst dL +19 (point 1 dL +35, point 2 dL +52, point 3 dL +47, point 4 dL +61, point 5 dL +67, point 6 dL +69, point 7 dL +41, point 8 dL +64, point 9 dL +33, point 10 dL +70, point 11 dL +68, point 12 dL +56, point 13 dL +55, point 14 dL +66, point 15 dL +68, point 16 dL +40, point 17 dL +34, point 18 dL +47, point 19 dL +41, point 20 dL +19, point 21 dL +64, point 22 dL +56, point 23 dL +67, point 24 dL +36, point 25 dL +33, point 26 dL +43, point 27 dL +50, point 28 dL +52, point 29 dL +45, point 30 dL +36, point 31 dL +45, point 32 dL +57, point 33 dL +38; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 28 point(s) above the bloom level 1.2 (median of 33/22/28): NestSpikesFront x8, PoolScorchDecal x2, Lava, PerchParts x5, TerraceProps x3, NestSpikes, Gatehouse x3, BannerEnemy, NestBowl x2, BannerPlayer, GateScorchDecal, 3 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 28 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): NestSpikesFront x8, PoolScorchDecal x2, Lava, PerchParts x5, TerraceProps x3, NestSpikes, Gatehouse x3, BannerEnemy, NestBowl x2, BannerPlayer, GateScorchDecal |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.2 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 90 | top third L* 36.1, bottom third L* 25.8 (+10, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.8 at 25 m, 7.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 26 of 33 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Body/Nest/NestBowl 1303 v / 4 s; Body/Spire 1170 v / 4 s; Body/Gatehouse 593 v / 6 s; Body/Nest/NestSpikes 504 v / 3 s; Body/Lava 445 v / 3 s; Body/Perch/PerchParts 279 v / 5 s; Body/PlinthBase 264 v / 2 s; Rubble 216 v / 1 s x9
- 8 hidden parts at rest (toggled states, not counted as draws)
- 17 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: B8 17 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-7256` -> `StandardMaterial3D#-70684` (dE 0.0), `StandardMaterial3D#-70684` -> )
