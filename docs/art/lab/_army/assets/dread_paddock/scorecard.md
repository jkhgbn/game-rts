# Art Lab scorecard: dread_paddock

Scene `res://art/buildings/lair/shadow/dread_paddock.tscn` · kind **building** / tier **hall** · kingdom shadow · ground meadow · 2026-09-27 10:12:50 · lab v2.0

## Result: **FAIL** · quality **87 / 100**

1 FAIL · 2 WARN · 17 PASS · 11 info · 0 skipped · 56 s

## Improve next
1. **Unique materials** (FAIL): B8 20 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-59493` -> `StandardMaterial3D#-96331` (dE 0.0), `StandardMaterial3D#-96331` -> `StandardMaterial3D#-63412` (dE 0.0), `StandardMaterial3D#-63412` -> `StandardMaterial3D#-82736` (dE 0.0), `StandardMaterial3D#-82736` -> `StandardMaterial3D#-97460` (dE 0.0), `ShaderMaterial#-68817` -> `ShaderMaterial#-64060` (dE 6.1), `ShaderMaterial#-64060` -> `ShaderMaterial#-23208` (dE 10.3), `ShaderMaterial#-23208` -> `ShaderMaterial#-86510` (dE 23.5), `ShaderMaterial#-46612` -> `ShaderMaterial#-9298` (dE 36.0), `StandardMaterial3D#-79293` -> `StandardMaterial3D#-97460` (dE 36.8), `ShaderMaterial#-32490` -> `ShaderMaterial#-9298` (dE 46.7), `ShaderMaterial#-9298` -> `ShaderMaterial#-86510` (dE 51.5), `StandardMaterial3D#-97460` -> `StandardMaterial3D#-24307` (dE 97.8) [fixes.json #1] _(from B8 Unique materials)_
2. **Glow points at 40 m** (WARN): Glow points 10 -> 3 (want 2-4): ShaderMaterial#-86510 crack_strength 0.0 -> 0.0 (dim under the bloom level: 3 point(s), peak 4.27 x the level); StandardMaterial3D#-63412 emission x 0.17 (dim under the bloom level: 2 point(s), peak 4.45 x the level; no energy parameter found: scale its emission colour / strength); StandardMaterial3D#-96331 emission x 0.18 (dim under the bloom level: 2 point(s), peak 4.27 x the level; no energy parameter found: scale its emission colour / strength) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 33 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #3] _(from B9 Materials built per instance)_
4. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 56 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 33 material(s), 14 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 24 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 93 | 27 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 86 | 11850 (biggest: Fence 2445, PropsMesh 1708, Stalls 1629, GateStack 1585) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6 | Particle systems | INFO | 13 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 26 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 10 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 20 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 32 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 54 surfaces over 24 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1646 of 9744 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 37444 px (238 x 318 bbox; 55 m: 18911 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 86.4, 0% of the body melts (within dE 15 of the ground); body L* 29.8 C 30.3 vs ground L* 61.5 C 50.4, hue gap 168 deg; top third (world height) dE 100.0, L* 42.3; per-pixel dE 90.6, outline 58.3 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 37.6, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 27.0 (heath dE 59.5, old_wood dE 50.3, riverbank dE 60.8, snow dE 68.6, ash dE 27.0, sand dE 76.6, marsh dE 37.6) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 26% of body pixels change between kingdom colours (min pair 25%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 57.9 (fire 70.9, shadow 86.0, ice 70.7, nature 57.9) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 12.1 on the team-colour area (normal vision 74.2; 11182 px); deutan: fire / nature dE 12.1; protan: fire / nature dE 22.6; worst vs ground: fire colour (deutan) dE 48.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +25 (point 1 dL +40, point 2 dL +39, point 3 dL +37, point 4 dL +25, point 5 dL +48, point 6 dL +39, point 7 dL +28, point 8 dL +44, point 9 dL +30, point 10 dL +43, point 11 dL +44; ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 10 point(s) above the bloom level 1.2 (median of 11/7/10): Portcullis, StallRoof x2, RuneRing, Halo2, TowerBanner, Halo0, Torches x2, ScorchDecal; soft glows under the bloom (v1 count, luma > 0.4): 17 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Portcullis, StallRoof x2, RuneRing, Halo2, TowerBanner, Halo0, Torches x2, ScorchDecal |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.41 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 42.3, bottom third L* 25.6 (+16, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.9 at 25 m, 6.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 0 | 0 of 11 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Fence 2445 v / 2 s; Body/YardProps/PropsMesh 1708 v / 4 s; Body/Stalls 1629 v / 6 s; Body/Gatehouse/GateStack 1585 v / 6 s; Body/PlinthBase 1088 v / 4 s; Body/PlinthCallCircle/RuneRing 600 v / 1 s; Body/Torches 544 v / 3 s; Body/StallRoofFrame/StallRoof 529 v / 4 s
- 8 hidden parts at rest (toggled states, not counted as draws)
- 20 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: B8 20 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-59493` -> `StandardMaterial3D#-96331` (dE 0.0), `StandardMaterial3D#-96331` ->)
