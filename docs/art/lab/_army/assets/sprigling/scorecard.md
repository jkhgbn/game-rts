# Art Lab scorecard: sprigling

Scene `res://art/units/nature/sprigling.tscn` · kind **unit** / tier **worker** · kingdom nature · ground meadow · 2026-09-27 10:10:48 · lab v2.0

## Result: **WARN** · quality **89 / 100**

0 FAIL · 4 WARN · 26 PASS · 9 info · 0 skipped · 20 s

## Improve next
1. **Head height vs body_height** (WARN): R8: body_height 1.2 -> 1.97 in res://art/units/nature/sprigling.tscn (root) and res://data/units/sprigling.tres (the head top; x1.64 now), or lower the head / crest 0.47 m [fixes.json #1] _(from R8 Head height vs body_height)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow SproutMesh 0.55 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **HP bar over the body at 40 m** (WARN): R7 HP bar over the body at 40 m: The HP bar hides 9% of the body: lower / narrow what sticks up, or fix body_height [fixes.json #3] _(from R7 HP bar over the body at 40 m, shot z40)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.5): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 20.4): value is close to the ground (dL +7): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 5 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.18): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, Hips 1 | <= 22 (art-units.md 8) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8) |  |
| B4 | Vertices | PASS 91 | 2212 (biggest: Merged 603, Merged 405, Merged 264, Merged 239) | <= 2500 (art-units.md 8) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/worker |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 0 soft (art-units.md 8) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/worker |  |
| B1a | Authored build parts (before the merge) | INFO | 28 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 22 |  |
| B11 | Surfaces per instance | INFO | 24 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 618 of 3294 triangles (18%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 35 | head top 1.97 m / body_height 1.2 (x1.64) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | SproutMesh 0.55 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | PASS 100 | x 0.48 / z 0.49 m (radius 0.35, from sprigling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 426 px (19 x 38 bbox; 55 m: 217 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 83 | mean-colour dE 20.4, 1% of the body melts (within dE 15 of the ground); body L* 69.9 C 29.7 vs ground L* 62.5 C 48.3, hue gap 5 deg; top third (world height) dE 36.7, L* 86.8; per-pixel dE 37.4, outline 39.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 42.3, 1% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 85 | worst sand: dE 18.2 (heath dE 27.7, old_wood dE 42.3, riverbank dE 38.7, snow dE 34.7, ash dE 56.5, sand dE 18.2, marsh dE 59.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 34% of body pixels change between kingdom colours (min pair 33%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 86 | worst nature colour: dE 20.1 (fire 39.4, shadow 48.9, ice 37.1, nature 20.1) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 45 | worst pair fire / nature (deutan): dE 11.5 on the team-colour area (normal vision 72.3; 150 px); deutan: fire / nature dE 11.5; protan: fire / nature dE 25.6; worst vs ground: fire colour (deutan) dE 13.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | **WARN** 56 | bar hides 9% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.7 m, 1.0 m wide | Keep tall parts under body_height + 0.4 or narrower than 0.35 m, or raise body_height to the real head top |
| R5c | Glow points stand out (1 m surround) | PASS 86 | worst dL +25 (point 1 dL +27, soft 1 dL +25 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/0/1): SproutMesh; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 93 | walk frames vs rest: mean IoU 0.73 (min 0.61), area kept 92-95% (min 402 px), frame-to-frame IoU min 0.64; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 0/0/0/0/1/1/1/0 (median 0, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 53% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 68 | outline complexity 2.18 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 86.8, bottom third L* 55.5 (+31, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.6 at 25 m, 16.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":22,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":0,"separate":6},"src":"art-units.md 8","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 603 v / 4 s; Root/Chest/ArmR/Merged 405 v / 6 s; Root/Chest/ArmL/Merged 264 v / 2 s; Root/Hips/LegL/Merged 239 v / 1 s; Root/Hips/LegR/Merged 239 v / 1 s; Root/Chest/Head/Merged 198 v / 4 s; Root/Chest/Head/Sprout/SproutMesh 141 v / 4 s; Root/Hips/Merged 119 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: R8: body_height 1.2 -> 1.97 in res://art/units/nature/sprigling.tscn (root) and res://data/units/sprigling.tres (the head top; x1.64 now), or lower the head / c)
