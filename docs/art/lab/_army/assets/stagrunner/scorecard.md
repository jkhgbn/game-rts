# Art Lab scorecard: stagrunner

Scene `res://art/units/nature/stagrunner/stagrunner.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-27 10:11:09 · lab v2.0

## Result: **FAIL** · quality **88 / 100**

2 FAIL · 2 WARN · 24 PASS · 9 info · 0 skipped · 23 s

## Improve next
1. **Vertices** (FAIL): B4 10968 -> 5490 (want <= 2500): `Merged` 2684 -> 1342 verts; `Merged` 2521 -> 1261 verts; `Merged` 668 -> 334 verts; `Merged` 579 -> 290 verts; `Spear` 488 -> 244 verts; `Merged` 448 -> 224 verts; `Merged` 448 -> 224 verts; `Merged` 441 -> 221 verts; `Cloak` 346 -> 173 verts; `Merged` 343 -> 172 verts; `Merged` 343 -> 172 verts; `Merged` 296 -> 148 verts; `Merged` 289 -> 145 verts; `Merged` 289 -> 145 verts; `Merged` 244 -> 122 verts; `CloakTail` 216 -> 108 verts; `ForearmR` 180 -> 90 verts; `Merged` 141 -> 71 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Draw instances at rest** (FAIL): B2 19 -> 18 (want <= 14): `Spear`, `Cloak` are keep_separate under `Chest`: keep only the animated / toggled one separate [fixes.json #2] _(from B2 Draw instances at rest)_
3. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `nature_bark_dark` #2e2414 -> #302515 (11% of the visible body): predicted dE R3 meadow 25.0 -> 25.0, R3t fire 32.8 -> 32.8, R3t shadow 38.2 -> 38.2, R3t ice 31.8 -> 31.8, R3t nature 25.8 -> 25.8, R4k old_wood 33.4 -> 33.4 (want >= 24); other grounds heath 6.9, riverbank 32.4, snow 39.5, ash 46.5, sand 22.3, marsh 48.4; shared material (res://art/units/nature/materials/nature_bark_dark.tres): give stagrunner its own copy first, other assets use it too [fixes.json #3] _(from R4 Contrast on the other grounds, shot z40)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 10.0): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 25.0): value is close to the ground (dL -1): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 20 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.4): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 41 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 99 | 19 drawn (19 mesh + 0 multimesh); per pivot: Chest 3, ArmR 2, Head 2, ArmL 1, Cloak 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | **FAIL** 1 | 19 | <= 14 (art-units.md 8, tier3-extras.md 12) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 10968 (biggest: Merged 2684, Merged 2521, Merged 668, Merged 579) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 12 (model says 22) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 85 surfaces over 19 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1950 of 13577 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 1.31 / z 1.52 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1513 px (57 x 63 bbox; 55 m: 766 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 87 | mean-colour dE 25.0, 9% of the body melts (within dE 15 of the ground); body L* 60.0 C 28.0 vs ground L* 61.6 C 49.1, hue gap 20 deg; top third (world height) dE 37.9, L* 77.0; per-pixel dE 42.5, outline 37.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 33.4, 12% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | **WARN** 36 | worst heath: dE 6.9 (heath dE 6.9, old_wood dE 33.4, riverbank dE 32.3, snow dE 39.6, ash dE 46.5, sand dE 22.4, marsh dE 48.4) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility at 40 m | PASS 86 | 13% of body pixels change between kingdom colours (min pair 11%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 93 | worst nature colour: dE 25.8 (fire 32.8, shadow 38.2, ice 31.8, nature 25.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 43 | worst pair fire / nature (deutan): dE 10.0 on the team-colour area (normal vision 46.5; 328 px); deutan: fire / nature dE 10.0; protan: fire / nature dE 16.6; worst vs ground: fire colour (deutan) dE 12.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 3% of the silhouette (gap -6 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +26 (point 1 dL +41, point 2 dL +26, point 3 dL +27, soft 1 dL +28 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): Merged x3; soft glows under the bloom (v1 count, luma > 0.4): 4 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 92 | walk frames vs rest: mean IoU 0.71 (min 0.67), area kept 108-115% (min 1645 px), frame-to-frame IoU min 0.75; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 3/3/3/3/3/3/3/3 (median 3, range 0, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 36% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.25 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 77.0, bottom third L* 27.0 (+50, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 64 | inner detail 12.4 at 25 m, 17.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Stag/Root/Mount/Head/Merged 2684 v / 8 s; Stag/Root/Mount/Merged 2521 v / 8 s; Rider/Root/Chest/Head/Merged 668 v / 8 s; Rider/Root/Chest/Merged 579 v / 6 s; Rider/Root/Chest/Spear 488 v / 8 s; Rider/Root/Hips/LegR/Merged 448 v / 4 s; Rider/Root/Hips/LegL/Merged 448 v / 4 s; Rider/Root/Hips/Merged 441 v / 6 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: B4 10968 -> 5490 (want <= 2500): `Merged` 2684 -> 1342 verts; `Merged` 2521 -> 1261 verts; `Merged` 668 -> 334 verts; `Merged` 579 -> 290 verts; `Spear` 488 -> )
