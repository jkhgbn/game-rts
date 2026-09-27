# Art Lab scorecard: grizzlemaw

Scene `res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn` · kind **beast** / tier **hero** · kingdom neutral · ground meadow · 2026-09-27 10:24:22 · lab v2.0

## Result: **WARN** · quality **97 / 100**

0 FAIL · 1 WARN · 22 PASS · 10 info · 0 skipped · 24 s

## Improve next
1. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL +13): darken around them or raise the energy [fixes.json #1] _(from R5c Glow points stand out (1 m surround), shot glow)_
2. **Contrast on the other grounds** (PASS): On heath the body drops to dE 21.6: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
3. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 45.7): raise the value step between the big masses and the ground (dL -24 now) _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 28 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: Lower 4, (root) 1, Head 1, Jaw 1, LegBL 1, LegBR 1 | <= 26 (map-fill.md 10 (epic beast hero budget)) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (map-fill.md 10 (epic beast hero budget)) |  |
| B3 | keep_separate parts | INFO | 5 | no budget for beast/hero |  |
| B4 | Vertices | PASS 100 | 4821 (biggest: Merged 1469, Merged 1009, Paw 392, Paw 392) | <= 8000 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (epic beast hero budget)) |  |
| B6 | Particle systems | INFO | 2 | no budget for beast/hero |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B7 | Shadow casters | PASS 100 | 2 (Merged, Merged) | <= 6 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B8 | Unique materials | INFO | 10 | no budget for beast/hero |  |
| B1a | Authored build parts (before the merge) | INFO | 12 (model says 12) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 27 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 912 of 4577 triangles (19%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.006 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.71 / z 1.93 m (radius 1.1, from elder_grizzlemaw.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 2221 px (57 x 76 bbox; 55 m: 1155 px) | >= 350 px (FAIL < 150) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 94 | mean-colour dE 45.7, 18% of the body melts (within dE 15 of the ground); body L* 37.9 C 28.8 vs ground L* 62.8 C 48.6, hue gap 52 deg; top third (world height) dE 39.0, L* 44.7; per-pixel dE 53.3, outline 39.0 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 90 | worst heath: dE 21.6 (heath dE 21.6, old_wood dE 24.4, riverbank dE 38.4, snow dE 58.4, ash dE 29.8, sand dE 43.9, marsh dE 27.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 0 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.5 m, 2.86 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 43 | worst dL +13 (point 1 dL +13; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): JawMesh; soft glows under the bloom (v1 count, luma > 0.4): 2 | 0-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 99 | walk frames vs rest: mean IoU 0.82 (min 0.79), area kept 96-101% (min 2138 px), frame-to-frame IoU min 0.82; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 350 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 32% of the silhouette (t 0.14 s) | >= 10% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.03 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 2.63 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 44.7, bottom third L* 22.1 (+22, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.2 at 25 m, 7.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Root/Mount/Merged 1469 v / 3 s; Root/Mount/Head/Merged 1009 v / 7 s; Root/Mount/LegFL/Lower/Paw 392 v / 2 s; Root/Mount/LegFR/Lower/Paw 392 v / 2 s; Root/Mount/LegBL/Lower/Paw 367 v / 2 s; Root/Mount/LegBR/Lower/Paw 367 v / 2 s; Root/Mount/LegBL/Merged 180 v / 1 s; Root/Mount/LegBR/Merged 180 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 1 in fixes.json (top: R5c Glow points stand out (1 m surround): 1 glow point(s) barely stand out from their 1 m surround (worst dL +13): darken around them or raise the energy)
