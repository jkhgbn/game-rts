# Art Lab scorecard: grove_stag

Scene `res://art/units/mounts/grove_stag/grove_stag.tscn` · kind **mount** / tier **mount** · kingdom nature · ground meadow · 2026-09-27 10:04:56 · lab v2.0

## Result: **WARN** · quality **88 / 100**

0 FAIL · 4 WARN · 20 PASS · 9 info · 0 skipped · 23 s

## Improve next
1. **Contrast on the other grounds** (WARN): shader_parameter/base_color of `grove_stag_antler` #c7b085 -> #c5af85 (7% of the visible body): predicted dE R3 meadow 25.7 -> 25.7, R3t fire 31.8 -> 31.8, R3t shadow 38.9 -> 38.9, R3t ice 31.8 -> 31.8, R3t nature 25.8 -> 25.9, R4k old_wood 26.7 -> 26.6 (want >= 24); other grounds heath 6.2, riverbank 25.0, snow 42.7, ash 41.3, sand 29.4, marsh 43.6 [fixes.json #1] _(from R4 Contrast on the other grounds, shot z40)_
2. **Glow points at 40 m** (WARN): Glow points 3 -> 1 (want 0-2): grove_stag_hide crack_strength 1.0 -> 0.2 (dim under the bloom level: 2 point(s), peak 3.73 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.0): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Vertices** (WARN): B4 6717 -> 5964 (want <= 6000): `Merged` 2684 -> 1931 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 25.7): value is close to the ground (dL -8): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 10 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 15% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 19 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, Head 1, LegBL 1, LegBR 1, LegFL 1, LegFR 1 | <= 12 (cavalry-mounts.md 10 (mount)) |  |
| B2 | Draw instances at rest | PASS 88 | 8 | <= 8 (cavalry-mounts.md 10 (mount)) |  |
| B4 | Vertices | **WARN** 45 | 6717 (biggest: Merged 2684, Merged 2521, Merged 343, Merged 343) | <= 6000 soft (cavalry-mounts.md 10 (mount)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (mount)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (cavalry-mounts.md 10 (mount)) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 2 soft (cavalry-mounts.md 10 (mount)) |  |
| B8 | Unique materials | INFO | 12 | no budget for mount/mount |  |
| B1a | Authored build parts (before the merge) | INFO | 1 (model says 11) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 12 |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1112 of 8188 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 1.31 / z 1.52 m (radius 0.7, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1269 px (57 x 55 bbox; 55 m: 649 px) | >= 150 px (FAIL < 60) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 87 | mean-colour dE 25.7, 15% of the body melts (within dE 15 of the ground); body L* 54.2 C 25.3 vs ground L* 62.4 C 48.7, hue gap 10 deg; top third (world height) dE 42.3, L* 77.0; per-pixel dE 40.3, outline 37.8 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 94 | dE 26.7, 14% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | **WARN** 35 | worst heath: dE 6.1 (heath dE 6.1, old_wood dE 26.7, riverbank dE 25.2, snow dE 42.6, ash dE 41.4, sand dE 29.2, marsh dE 43.7) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility at 40 m | PASS 89 | 15% of body pixels change between kingdom colours (min pair 12%) | >= 2% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 93 | worst nature colour: dE 25.8 (fire 31.8, shadow 38.9, ice 31.8, nature 25.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 44 | worst pair fire / nature (deutan): dE 11.0 on the team-colour area (normal vision 48.3; 287 px); deutan: fire / nature dE 11.0; protan: fire / nature dE 17.5; worst vs ground: fire colour (deutan) dE 18.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +23 (point 1 dL +39, point 2 dL +23, point 3 dL +25, soft 1 dL +33 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): Merged x3; soft glows under the bloom (v1 count, luma > 0.4): 2 | 0-2 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Merged x3 |
| R11 | Reads while walking (40 m) | PASS 99 | walk frames vs rest: mean IoU 0.82 (min 0.77), area kept 98-102% (min 1258 px), frame-to-frame IoU min 0.78; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 150 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 3/3/3/3/3/3/3/3 (median 3, range 0, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 8 present | set_team_color, set_moving, play_hit, play_death, signal:death_finished, set_barded, play_charge, seat_transform |  |
| A2 | death_finished | PASS 100 | after 1.0 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.32 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 77.0, bottom third L* 27.9 (+49, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.4 at 25 m, 13.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (mount))
`{"draw":8,"frame_ms":0.005,"lights":0,"meshes":12,"n":50,"runtime_mats":0,"soft":{"casters":2,"looping":1,"verts":6000},"src":"cavalry-mounts.md 10 (mount)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Head/Merged 2684 v / 8 s; Root/Mount/Merged 2521 v / 8 s; Root/Mount/LegBL/Merged 343 v / 4 s; Root/Mount/LegBR/Merged 343 v / 4 s; Root/Mount/LegFL/Merged 289 v / 4 s; Root/Mount/LegFR/Merged 289 v / 4 s; Root/Mount/Neck/Merged 244 v / 3 s; Shadow 4 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: shader_parameter/base_color of `grove_stag_antler` #c7b085 -> #c5af85 (7% of the visible body): predicted dE R3 meadow 25.7 -> 25.7, R3t fire 31.8 -> 31.8, R3t )
