# Art Lab scorecard: dusk_steed

Scene `res://art/units/mounts/dusk_steed/dusk_steed.tscn` · kind **mount** / tier **mount** · kingdom shadow · ground meadow · 2026-09-30 11:43:31 · lab v3.1

## Result: **PASS** · quality **95 / 100** (94.5)

0 FAIL · 0 WARN · 24 PASS · 14 info · 0 skipped · 21 s

## Improve next
1. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 6 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (35 surfaces for 8 meshes = 35 draw calls) _(from B11)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 20 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, Head 1, LegBL 1, LegBR 1, LegFL 1, LegFR 1 | <= 12 (cavalry-mounts.md 10 (mount)) |  |
| B2 | Draw instances at rest | PASS 88 | 8 | <= 8 (cavalry-mounts.md 10 (mount)) |  |
| B4 | Vertices | PASS 88 | 5581 (body + face above its allowance: face 416 v, allowance 600, total 5997; biggest: Merged 2229, Merged 1975, Merged 402, Merged 402) | <= 6000 soft (cavalry-mounts.md 10 (mount)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (mount)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (cavalry-mounts.md 10 (mount)) |  |
| B7 | Shadow casters | PASS 100 | 1 (Merged) | <= 2 soft (cavalry-mounts.md 10 (mount)) |  |
| B8 | Unique materials | INFO | 13 | no budget for mount/mount |  |
| B1a | Authored build parts (before the merge) | INFO | 9 (model says 10) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 12 |  |
| B11 | Surfaces per instance | INFO | 35 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 698 of 7368 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.009 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.4 / z 1.55 m (radius 0.7, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 785 px (38 x 53 bbox; 55 m: 399 px) | >= 150 px (FAIL < 60) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 98.5, 0% of the body melts (within dE 15 of the ground); body L* 19.9 C 40.8 vs ground L* 62.2 C 48.7, hue gap 168 deg; top third (world height) dE 96.9, L* 20.9; per-pixel dE 101.7, outline 71.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 45.0, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 37.5 (heath dE 65.3, old_wood dE 61.0, riverbank dE 75.1, snow dE 82.0, ash dE 37.5, sand dE 90.7, marsh dE 45.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 25% of body pixels change between kingdom colours (min pair 24%) | >= 6% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 68.4 (fire 79.7, shadow 95.6, ice 80.0, nature 68.4) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 11.8 on the team-colour area (normal vision 79.9; 200 px); deutan: fire / nature dE 11.8; protan: fire / nature dE 22.9; worst vs ground: fire colour (deutan) dE 60.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 77 | worst dL +3 (point 1 dL +3; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 1/0/0); soft glows under the bloom (v1 count, luma > 0.4): 1 | 0-2 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 98 | walk frames vs rest: mean IoU 0.81 (min 0.76), area kept 96-99% (min 762 px), frame-to-frame IoU min 0.8; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 150 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 84 | points per frame 1/1/1/1/0/0/1/1 (median 1, range 1, 2 frame(s) at 0; at rest 0) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 8 present | set_team_color, set_moving, play_hit, play_death, signal:death_finished, set_barded, play_charge, seat_transform |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 31% of the silhouette at its peak (t 0.25 s; 0.12 s 29%, 0.25 s 31%, 0.4 s 28%, 0.6 s 9%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 83 | 161 shapes over 7 body parts (23.0 per part: Head 63, LegFL 10, LegFR 10, LegBL 11, LegBR 11, Tail 11, Mount 45); 25% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.879 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 99% of the 6000 verts budget used (5993) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 33 | 10 colour steps (L*a*b* bins >= 2 % of the body), 6 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.37 at the close-up (47844 px), 1.95 at 25 m; close-up outline complexity 10.81 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.93 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 98 | top third L* 20.9, bottom third L* 9.3 (+11, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.3 at 25 m, 12.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- cast: [cast.jpg](cast.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (mount))
`{"draw":8,"face_verts":600,"frame_ms":0.005,"lights":0,"meshes":12,"n":50,"runtime_mats":0,"soft":{"casters":2,"looping":1,"verts":6000},"src":"cavalry-mounts.md 10 (mount)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 2229 v / 6 s; Root/Mount/Head/Merged 1975 v / 9 s; Root/Mount/LegBL/Merged 402 v / 4 s; Root/Mount/LegBR/Merged 402 v / 4 s; Root/Mount/LegFL/Merged 339 v / 4 s; Root/Mount/LegFR/Merged 339 v / 4 s; Root/Mount/Tail/Merged 307 v / 3 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
