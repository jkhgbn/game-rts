# Art Lab scorecard: vessa

Scene `res://art/units/wizards/vessa.tscn` · kind **unit** / tier **wizard** · kingdom fire · ground meadow · 2026-09-27 09:53:48 · lab v2.0

## Result: **WARN** · quality **89 / 100**

0 FAIL · 5 WARN · 24 PASS · 11 info · 0 skipped · 29 s

## Improve next
1. **Head height vs body_height** (WARN): R8: body_height 2.0 -> 2.92 in res://art/units/wizards/vessa.tscn (root) (the head top; x1.46 now), or lower the head / crest 0.02 m [fixes.json #1] _(from R8 Head height vs body_height)_
2. **Contrast in every team colour (meadow)** (WARN): shader_parameter/base_color of `fire_bronze` #9e6629 -> #e47a5a (13% of the visible body): predicted dE R3 meadow 67.0 -> 70.4, R3t fire 67.1 -> 70.4, R3t shadow 70.0 -> 71.6, R3t ice 41.4 -> 45.8, R3t nature 13.9 -> 24.1, R4k ash 69.0 -> 71.0 (want >= 24); other grounds heath 53.4, old_wood 71.0, riverbank 82.8, snow 68.7, sand 49.1, marsh 68.8; shared material (res://art/units/kit/materials/fire_bronze.tres): give vessa its own copy first, other assets use it too [fixes.json #2] _(from R3t Contrast in every team colour (meadow), shot teams)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (protan) look alike on this model (dE 10.1): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Vertices** (WARN): B4 3795 -> 2960 (want <= 3000): `Merged` 786 -> 393 verts; `Merged` 768 -> 384 verts; `Merged` 547 -> 489 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_
5. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (1/1/1/0/0/1/1/0 per frame): put them on parts the gait does not cover [fixes.json #5] _(from R5w Glow points while walking (flicker), shot glow)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (10 mesh + 1 multimesh); per pivot: Head 3, ArmR 2, Chest 2, Hips 2, (root) 1, ArmL 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 37 | 3795 (biggest: Merged 786, Merged 768, Merged 547, Merged 521) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (OrbLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (EmberMotes) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 14 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 12 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 30 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 616 of 4610 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.024 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 38 | head top 2.92 m / body_height 2.0 (x1.46) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | INFO | identity crest: CrownFlames 0.6 m, Merged 0.43 m, Orb 0.41 m, Merged 0.46 m | wizard tier: a crest up to 0.7 m wide is part of the identity (the HP bar sits on it) |  |
| R10 | Footprint vs selection radius | INFO | x 0.75 / z 0.74 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1336 px (37 x 57 bbox; 55 m: 686 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 67.0, 0% of the body melts (within dE 15 of the ground); body L* 58.0 C 63.8 vs ground L* 61.7 C 48.8, hue gap 71 deg; top third (world height) dE 73.9, L* 66.9; per-pixel dE 73.8, outline 60.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 69.0, 0% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst sand: dE 48.4 (heath dE 51.2, old_wood dE 67.8, riverbank dE 79.6, snow dE 70.3, ash dE 69.0, sand dE 48.4, marsh dE 65.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 69% of body pixels change between kingdom colours (min pair 67%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | **WARN** 45 | worst nature colour: dE 13.9 (fire 67.1, shadow 70.0, ice 41.4, nature 13.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) | Keep the team colour off the silhouette's biggest mass or give it a value step (trim, dark border) |
| R6cb | Team colours for colour-blind players | **WARN** 35 | worst pair fire / nature (protan): dE 10.1 on the team-colour area (normal vision 76.2; 987 px); deutan: fire / nature dE 20.4; protan: fire / nature dE 10.1; worst vs ground: nature colour (deutan) dE 5.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 6% of the silhouette (gap -13 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 87 | worst dL +27 (point 1 dL +27; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Orb; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.85 (min 0.78), area kept 96-103% (min 1297 px), frame-to-frame IoU min 0.82; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 41 | points per frame 1/1/1/0/0/1/1/0 (median 1, range 1, 3 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 97 | strike pose changes 27% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.07 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 74 | outline complexity 2.26 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 66.9, bottom third L* 44.4 (+22, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.6 at 25 m, 10.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (wizard))
`{"draw":16,"frame_ms":0.005,"lights":1,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"art-units.md 8 (wizard)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 786 v / 4 s; Root/Chest/ArmR/Merged 768 v / 5 s; Root/Chest/Head/Merged 547 v / 4 s; Root/Hips/Merged 521 v / 5 s; Root/Chest/Cape 398 v / 3 s; Root/Chest/ArmL/Merged 273 v / 3 s; Root/Chest/Head/CrownFlames 174 v / 1 s x6; Root/Hips/HemGlow 119 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: R8: body_height 2.0 -> 2.92 in res://art/units/wizards/vessa.tscn (root) (the head top; x1.46 now), or lower the head / crest 0.02 m)
