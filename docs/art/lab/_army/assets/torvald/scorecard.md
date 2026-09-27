# Art Lab scorecard: torvald

Scene `res://art/units/wizards/torvald.tscn` · kind **unit** / tier **wizard** · kingdom ice · ground meadow · 2026-09-27 10:02:01 · lab v2.0

## Result: **WARN** · quality **91 / 100**

0 FAIL · 4 WARN · 26 PASS · 10 info · 0 skipped · 25 s

## Improve next
1. **Contrast on the home ground (snow)** (WARN): shader_parameter/base_color of `torvald_fur_pale` #bdcce0 -> #75aad5 (15% of the visible body): predicted dE R3 meadow 59.3 -> 61.3, R3t fire 49.7 -> 51.3, R3t shadow 60.7 -> 64.0, R3t ice 58.6 -> 60.7, R3t nature 39.9 -> 41.4, R4k snow 18.9 -> 24.0 (want >= 24); other grounds heath 43.3, old_wood 56.8, riverbank 55.5, ash 53.0, sand 47.5, marsh 63.1 [fixes.json #1] _(from R4k Contrast on the home ground (snow), shot z40)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.81 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Vertices** (WARN): B4 4596 -> 2920 (want <= 3000): `Merged` 1389 -> 695 verts; `StaffMesh` 632 -> 316 verts; `Flake` 576 -> 288 verts; `Merged` 543 -> 272 verts; `Merged` 507 -> 400 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 8.6): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Contrast on the other grounds** (PASS): On snow the body drops to dE 18.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Attack reads at 40 m** (PASS): Push the attack pose: the strike should change >= 30% of the 40 m silhouette (now 25%) _(from A3 Attack reads at 40 m, shot anim)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 29 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (9 mesh + 1 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, Hips 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 100 | 11 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 35 | 4596 (biggest: Merged 1389, StaffMesh 632, Flake 576, Merged 543) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (OrbLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 6 | no budget for unit/wizard |  |
| B6l | Looping particle systems | PASS 94 | 1 (SnowMotes) | <= 1 soft (art-units.md 8 (wizard)) |  |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, StaffMesh, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 19 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 10 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 35 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 996 of 5604 triangles (17%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 80 | head top 2.8 m / body_height 2.1 (x1.34) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.81 m | narrower than 0.7 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.99 / z 0.77 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1729 px (46 x 66 bbox; 55 m: 876 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 59.3, 0% of the body melts (within dE 15 of the ground); body L* 77.1 C 10.5 vs ground L* 62.6 C 48.3, hue gap n/a (body C* <= 25); top third (world height) dE 63.4, L* 87.1; per-pixel dE 63.7, outline 43.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | **WARN** 52 | dE 18.9, 62% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 86 | worst snow: dE 18.9 (heath dE 41.9, old_wood dE 57.6, riverbank dE 56.3, snow dE 18.9, ash dE 55.0, sand dE 43.4, marsh dE 64.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 32% of body pixels change between kingdom colours (min pair 29%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 39.9 (fire 49.7, shadow 60.7, ice 58.6, nature 39.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 41 | worst pair fire / nature (deutan): dE 8.6 on the team-colour area (normal vision 58.3; 619 px); deutan: fire / nature dE 8.6; protan: fire / nature dE 19.3; worst vs ground: fire colour (deutan) dE 34.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -17 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.6 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 87 | worst dL +20 (point 1 dL +34, point 2 dL +20; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Flake, Merged; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.87 (min 0.84), area kept 97-101% (min 1713 px), frame-to-frame IoU min 0.87; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 95 | strike pose changes 25% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.02 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 87.1, bottom third L* 66.8 (+20, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.4 at 25 m, 9.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 1389 v / 6 s; Root/Chest/ArmR/Staff/StaffMesh 632 v / 4 s; Root/Chest/ArmR/Staff/Snowflake/Flake 576 v / 1 s x24; Root/Chest/Merged 543 v / 4 s; Root/Chest/ArmL/Merged 507 v / 6 s; Root/Chest/ArmR/Merged 507 v / 6 s; Root/Hips/Merged 390 v / 5 s; Root/Hips/LegL/Merged 24 v / 1 s
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: shader_parameter/base_color of `torvald_fur_pale` #bdcce0 -> #75aad5 (15% of the visible body): predicted dE R3 meadow 59.3 -> 61.3, R3t fire 49.7 -> 51.3, R3t )
