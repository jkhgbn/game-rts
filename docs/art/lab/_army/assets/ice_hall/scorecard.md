# Art Lab scorecard: ice_hall

Scene `res://art/buildings/ice_hall.tscn` · kind **building** / tier **hall** · kingdom ice · ground meadow · 2026-09-27 09:55:08 · lab v2.0

## Result: **FAIL** · quality **87 / 100**

1 FAIL · 3 WARN · 16 PASS · 11 info · 0 skipped · 53 s

## Improve next
1. **Unique materials** (FAIL): B8 14 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-46761` -> `StandardMaterial3D#-33009` (dE 0.0), `ShaderMaterial#-2355` -> `ShaderMaterial#-28083` (dE 8.2), `ShaderMaterial#-73393` -> `ShaderMaterial#-79821` (dE 13.4), `ShaderMaterial#-28083` -> `ShaderMaterial#-50643` (dE 20.3), `ShaderMaterial#-96182` -> `ShaderMaterial#-79821` (dE 28.9), `ShaderMaterial#-79821` -> `ShaderMaterial#-50643` (dE 58.9) [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 15 -> 4 (want 2-4): ShaderMaterial#-41919 energy 3.0 -> 0.18 (dim under the bloom level: 6 point(s), peak 4.42 x the level); ShaderMaterial#-64450 energy 2.2 -> 0.04 (dim under the bloom level: 5 point(s), peak 4.42 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 25 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 7 glow point(s) barely stand out from their 1 m surround (worst dL +0): darken around them or raise the energy [fixes.json #4] _(from R5c Glow points stand out (1 m surround), shot glow)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.65): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.5): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 43 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 25 material(s), 10 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 16 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 19 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 6340 (biggest: Walls 1777, Roof 1251, PlinthBase 1214, RackParts 631) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 11 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 36 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 6 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 14 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 23 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 39 surfaces over 16 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 944 of 4150 triangles (22%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.38 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 36239 px (221 x 273 bbox; 55 m: 18299 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 60.0, 0% of the body melts (within dE 15 of the ground); body L* 64.2 C 12.4 vs ground L* 61.2 C 50.7, hue gap n/a (body C* <= 25); top third (world height) dE 57.3, L* 82.3; per-pixel dE 64.8, outline 35.6 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 30.3, 30% melts (snow is where ice units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 30.3 (heath dE 39.3, old_wood dE 48.1, riverbank dE 43.7, snow dE 30.3, ash dE 43.4, sand dE 47.6, marsh dE 53.7) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 36% of body pixels change between kingdom colours (min pair 35%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 39.0 (fire 57.1, shadow 74.8, ice 59.8, nature 39.0) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 13.5 on the team-colour area (normal vision 81.6; 14148 px); deutan: fire / nature dE 13.5; protan: fire / nature dE 25.3; worst vs ground: fire colour (deutan) dE 31.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 52 | worst dL +0 (point 1 dL +35, point 2 dL +10, point 3 dL +40, point 4 dL +37, point 5 dL +11, point 6 dL +14, point 7 dL +25, point 8 dL +37, point 9 dL +39, point 10 dL +40, point 11 dL +10, point 12 dL +54, point 13 dL +0, point 14 dL +0, point 15 dL +38, point 16 dL +5; ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 15 point(s) above the bloom level 1.2 (median of 16/14/15): StoreParts x2, TurretCapR, HaloShards x2, BannerR, CrystalBase x3, Roof x4, Rubble, RackParts, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 24 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): StoreParts x2, TurretCapR, HaloShards x2, BannerR, CrystalBase x3, Roof x4, Rubble, RackParts |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 27 | outline complexity 1.65 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 82.3, bottom third L* 45.4 (+36, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 88 | inner detail 2.5 at 25 m, 3.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 8 of 16 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Walls 1777 v / 7 s; Body/Roof 1251 v / 7 s; Body/PlinthBase 1214 v / 4 s; Body/WeaponRack/RackParts 631 v / 3 s; Body/RidgeCrystal/CrystalBase 452 v / 3 s; Body/IceStore/StoreParts 262 v / 5 s; Rubble 216 v / 1 s x9; Body/RidgeCrystal/Halo/HaloShards 186 v / 1 s
- 7 hidden parts at rest (toggled states, not counted as draws)
- 14 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B8 14 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-46761` -> `StandardMaterial3D#-33009` (dE 0.0), `ShaderMaterial#-2355` -> `Sha)
