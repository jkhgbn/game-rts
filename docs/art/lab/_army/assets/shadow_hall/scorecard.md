# Art Lab scorecard: shadow_hall

Scene `res://art/buildings/shadow_hall.tscn` · kind **building** / tier **hall** · kingdom shadow · ground meadow · 2026-09-27 10:19:25 · lab v2.0

## Result: **FAIL** · quality **84 / 100**

2 FAIL · 2 WARN · 16 PASS · 11 info · 0 skipped · 55 s

## Improve next
1. **Unique materials** (FAIL): B8 13 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-73222` -> `StandardMaterial3D#-59258` (dE 0.0), `StandardMaterial3D#-23843` -> `StandardMaterial3D#-59258` (dE 0.0), `ShaderMaterial#-54303` -> `ShaderMaterial#-77039` (dE 13.7), `StandardMaterial3D#-55568` -> `StandardMaterial3D#-59258` (dE 36.8), `ShaderMaterial#-22794` -> `ShaderMaterial#-1172` (dE 46.7) [fixes.json #1] _(from B8 Unique materials)_
2. **Real lights** (FAIL): B5 Real lights: No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4) [fixes.json #2] _(from B5 Real lights)_
3. **Glow points at 40 m** (WARN): Glow points 5 -> 2 (want 2-4): ShaderMaterial#-68444 energy 3.0 -> 0.17 (dim under the bloom level: 3 point(s), peak 4.49 x the level) [fixes.json #3] _(from R5 Glow points at 40 m, shot glow)_
4. **Materials built per instance** (WARN): B9 Materials built per instance: Share the 24 per-instance material(s) (static cache) so 200 units do not build 200 copies [fixes.json #4] _(from B9 Materials built per instance)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.38): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Detail density 25 m / 40 m** (INFO): Detail density is low at 25 m (2.7): add 1-2 mid-size value blocks (trim band, belt, plate edge) that read at 25 m and merge at 40 m _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 38 nodes | instantiates without errors |  |
| B9 | Materials built per instance | **WARN** 35 | 24 material(s), 10 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) | Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 13 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 16 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 2795 (biggest: Walls 739, Roof 729, PlinthBase 429, Rubble 216) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | **FAIL** 0 | 1 (HallLight) | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4) |
| B6 | Particle systems | INFO | 11 | no budget for building/hall |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/hall |  |
| B6p | Looping particles alive | PASS 100 | 44 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 7 | no budget for building/hall |  |
| B8 | Unique materials | **FAIL** 0 | 13 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 20 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 13 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 330 of 2082 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.28 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 41302 px (242 x 297 bbox; 55 m: 21011 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 91.3, 0% of the body melts (within dE 15 of the ground); body L* 31.3 C 36.4 vs ground L* 60.7 C 50.4, hue gap 169 deg; top third (world height) dE 115.3, L* 40.8; per-pixel dE 95.7, outline 56.0 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 43.5, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 33.7 (heath dE 64.4, old_wood dE 56.3, riverbank dE 63.3, snow dE 70.2, ash dE 33.7, sand dE 79.9, marsh dE 43.5) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 37% of body pixels change between kingdom colours (min pair 34%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 47.8 (fire 67.9, shadow 91.1, ice 68.0, nature 47.8) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 82 | worst pair fire / nature (deutan): dE 14.7 on the team-colour area (normal vision 81.5; 16715 px); deutan: fire / nature dE 14.7; protan: fire / nature dE 24.9; worst vs ground: fire colour (deutan) dE 39.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 97 | worst dL +29 (point 1 dL +57, point 2 dL +58, point 3 dL +54, point 4 dL +55, point 5 dL +29, point 6 dL +35, point 7 dL +48; ring 27 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 5 point(s) above the bloom level 1.2 (median of 7/5/5): TowerStack, ScorchDecal x2, TowerBanner, Walls; soft glows under the bloom (v1 count, luma > 0.4): 9 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): TowerStack, ScorchDecal x2, TowerBanner, Walls |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 6 | outline complexity 1.38 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 40.8, bottom third L* 12.1 (+28, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 93 | inner detail 2.7 at 25 m, 3.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 57 | 2 of 7 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Body/Walls 739 v / 4 s; Body/Roof 729 v / 5 s; Body/PlinthBase 429 v / 2 s; Rubble 216 v / 1 s x9; Body/PikeRack/RackParts 156 v / 2 s; Body/BellTower/TowerTop 150 v / 3 s; Body/BellTower/TowerStack 120 v / 4 s; Body/SoulOrb 104 v / 1 s
- 7 hidden parts at rest (toggled states, not counted as draws)
- 13 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B8 13 -> 8 materials: use one material for look-alike pairs: `StandardMaterial3D#-73222` -> `StandardMaterial3D#-59258` (dE 0.0), `StandardMaterial3D#-23843` ->)
