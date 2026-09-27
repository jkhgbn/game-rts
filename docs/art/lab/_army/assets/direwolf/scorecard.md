# Art Lab scorecard: direwolf

Scene `res://art/units/neutral/beasts/direwolf/direwolf.tscn` · kind **beast** / tier **hero** · kingdom neutral · ground meadow · 2026-09-27 10:22:16 · lab v2.0

## Result: **WARN** · quality **93 / 100**

0 FAIL · 1 WARN · 20 PASS · 8 info · 0 skipped · 21 s

## Improve next
1. **HP bar over the body at 40 m** (WARN): R7 HP bar over the body at 40 m: The HP bar hides 9% of the body: lower / narrow what sticks up, or fix body_height [fixes.json #1] _(from R7 HP bar over the body at 40 m, shot z40)_
2. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -14 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
3. **Contrast on the other grounds** (PASS): On ash the body drops to dE 22.6: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 14 drawn (14 mesh + 0 multimesh); per pivot: Lower 4, (root) 1, Head 1, Jaw 1, LegBL 1, LegBR 1 | <= 26 (map-fill.md 10 (epic beast hero budget)) |  |
| B2 | Draw instances at rest | PASS 92 | 14 | <= 16 (map-fill.md 10 (epic beast hero budget)) |  |
| B3 | keep_separate parts | INFO | 13 | no budget for beast/hero |  |
| B4 | Vertices | PASS 100 | 3686 (biggest: Body 916, Neck 676, Cranium 556, Mandible 225) | <= 8000 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (epic beast hero budget)) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B7 | Shadow casters | PASS 95 | 5 (Cranium, Neck, Thigh, Thigh, Body) | <= 6 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B8 | Unique materials | INFO | 8 | no budget for beast/hero |  |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 14) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 36 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 378 of 2801 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.58 / z 1.71 m (radius 0.8, from greymane_direwolf.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1161 px (50 x 59 bbox; 55 m: 598 px) | >= 350 px (FAIL < 150) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 55.7, 0% of the body melts (within dE 15 of the ground); body L* 45.9 C 5.2 vs ground L* 62.2 C 48.8, hue gap n/a (body C* <= 25); top third (world height) dE 58.4, L* 42.6; per-pixel dE 58.8, outline 41.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 91 | worst ash: dE 22.6 (heath dE 26.8, old_wood dE 30.5, riverbank dE 38.8, snow dE 44.9, ash dE 22.6, sand dE 49.2, marsh dE 32.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | **WARN** 56 | bar hides 9% of the silhouette (gap -12 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.3 m, 2.08 m wide | Keep tall parts under body_height + 0.4 or narrower than 0.35 m, or raise body_height to the real head top |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 0 | 0-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 90 | walk frames vs rest: mean IoU 0.66 (min 0.6), area kept 101-103% (min 1140 px), frame-to-frame IoU min 0.68; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 350 px (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 47% of the silhouette (t 0.08 s) | >= 10% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.26 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 42.6, bottom third L* 57.5 (-14, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.5 at 25 m, 9.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (epic beast hero budget))
`{"draw":16,"frame_ms":0.01,"lights":0,"meshes":26,"n":12,"runtime_mats":0,"soft":{"casters":6,"looping":2,"verts":8000},"src":"map-fill.md 10 (epic beast hero budget)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Body 916 v / 3 s; Root/Mount/Head/Neck 676 v / 3 s; Root/Mount/Head/Skull/Cranium 556 v / 7 s; Root/Mount/Head/Skull/Jaw/Mandible 225 v / 4 s; Root/Mount/Tail/Brush 177 v / 2 s; Root/Mount/LegFL/Lower/Shin 165 v / 2 s; Root/Mount/LegFR/Lower/Shin 165 v / 2 s; Root/Mount/LegBL/Lower/Shin 165 v / 2 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 1 in fixes.json (top: R7 HP bar over the body at 40 m: The HP bar hides 9% of the body: lower / narrow what sticks up, or fix body_height)
