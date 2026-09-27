# Art Lab scorecard: mossback

Scene `res://art/units/nature/mossback/mossback.tscn` · kind **unit** / tier **heavy** · kingdom nature · ground meadow · 2026-09-27 10:06:19 · lab v2.0

## Result: **WARN** · quality **92 / 100**

0 FAIL · 1 WARN · 27 PASS · 10 info · 0 skipped · 26 s

## Improve next
1. **Contrast on the home ground (old_wood)** (WARN): shader_parameter/base_color of `mossback_moss` #45664f -> #6a9f95 (15% of the visible body): predicted dE R3 meadow 33.0 -> 34.6, R3t fire 35.6 -> 36.2, R3t shadow 40.6 -> 40.5, R3t ice 36.2 -> 37.2, R3t nature 32.5 -> 34.2, R4k old_wood 16.8 -> 24.0 (want >= 24); other grounds heath 17.5, riverbank 19.3, snow 43.7, ash 35.5, sand 39.6, marsh 40.6 [fixes.json #1] _(from R4k Contrast on the home ground (old_wood), shot z40)_
2. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.33): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
3. **Contrast on the other grounds** (PASS): On heath the body drops to dE 14.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 10% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 33.0): raise the value step between the big masses and the ground (dL -18 now) _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Attack reads at 40 m** (PASS): Push the attack pose: the strike should change >= 30% of the 40 m silhouette (now 20%) _(from A3 Attack reads at 40 m, shot anim)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 31 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 14 drawn (14 mesh + 0 multimesh); per pivot: Crown 3, (root) 1, Head 1, Jaw 1, LegBL 1, LegBR 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 92 | 14 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 86 | 5824 (biggest: Merged 2611, Merged 578, Merged 410, Merged 356) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 1 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 3 (Merged, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 21 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 14) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 46 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1145 of 6924 triangles (16%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.017 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 1.49 / z 2.49 m (radius 0.45, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 4871 px (89 x 91 bbox; 55 m: 2517 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 94 | mean-colour dE 33.0, 0% of the body melts (within dE 15 of the ground); body L* 44.6 C 21.5 vs ground L* 63.2 C 48.7, hue gap n/a (body C* <= 25); top third (world height) dE 28.4, L* 57.8; per-pixel dE 42.7, outline 32.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | **WARN** 49 | dE 16.8, 3% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 80 | worst heath: dE 14.3 (heath dE 14.3, old_wood dE 16.8, riverbank dE 16.1, snow dE 50.0, ash dE 32.6, sand dE 41.0, marsh dE 35.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 83 | 10% of body pixels change between kingdom colours (min pair 9%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 32.5 (fire 35.6, shadow 40.6, ice 36.2, nature 32.5) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 81 | worst pair fire / nature (deutan): dE 13.6 on the team-colour area (normal vision 54.6; 668 px); deutan: fire / nature dE 13.6; protan: fire / nature dE 19.8; worst vs ground: fire colour (deutan) dE 29.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -13 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 100 | worst dL +44 (point 1 dL +44; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.92 (min 0.9), area kept 98-100% (min 4828 px), frame-to-frame IoU min 0.92; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 90 | strike pose changes 20% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.61 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 2 | outline complexity 1.33 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 57.8, bottom third L* 30.9 (+26, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.9 at 25 m, 6.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 2611 v / 13 s; Root/Mount/Head/Merged 578 v / 6 s; Root/Mount/TreeA/Crown/Merged 410 v / 2 s; Root/Mount/TreeB/Crown/Merged 356 v / 2 s; Root/Mount/TreeC/Crown/Merged 302 v / 2 s; Root/Mount/LegBL/Merged 277 v / 3 s; Root/Mount/LegBR/Merged 277 v / 3 s; Root/Mount/LegFL/Merged 256 v / 3 s
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 1 in fixes.json (top: shader_parameter/base_color of `mossback_moss` #45664f -> #6a9f95 (15% of the visible body): predicted dE R3 meadow 33.0 -> 34.6, R3t fire 35.6 -> 36.2, R3t sha)
