# Art Lab scorecard: tusker

Scene `res://art/units/neutral/beasts/tusker/tusker.tscn` · kind **beast** / tier **hero** · kingdom neutral · ground meadow · 2026-09-27 10:30:08 · lab v2.0

## Result: **PASS** · quality **99 / 100**

0 FAIL · 0 WARN · 21 PASS · 9 info · 0 skipped · 22 s

## Improve next
1. **Contrast on the other grounds** (PASS): On heath the body drops to dE 24.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
2. **Surfaces per instance** (IDEA): Merge surfaces that share a material (25 surfaces for 9 meshes = 25 draw calls) _(from B11)_
3. **Idle / attack beats** (IDEA): Give the idle one secondary motion (tail flick, cloth, head turn) and the attack a 0.1 s anticipation pose so it reads at 40 m _(from anim strip)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 22 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Head 2, Mount 2, (root) 1, LegBL 1, LegBR 1, LegFL 1 | <= 26 (map-fill.md 10 (epic beast hero budget)) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 16 (map-fill.md 10 (epic beast hero budget)) |  |
| B3 | keep_separate parts | INFO | 2 | no budget for beast/hero |  |
| B4 | Vertices | PASS 100 | 3989 (biggest: Merged 1068, Merged 1043, Bristles 696, Merged 318) | <= 8000 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (epic beast hero budget)) |  |
| B6 | Particle systems | INFO | 3 | no budget for beast/hero |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B7 | Shadow casters | PASS 100 | 4 (TuskR, Merged, Bristles, Merged) | <= 6 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B8 | Unique materials | INFO | 13 | no budget for beast/hero |  |
| B1a | Authored build parts (before the merge) | INFO | 10 (model says 10) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 610 of 5284 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.025 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.77 / z 1.99 m (radius 1.0, from ironhide_tusker.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 2276 px (63 x 74 bbox; 55 m: 1174 px) | >= 350 px (FAIL < 150) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 49.1, 0% of the body melts (within dE 15 of the ground); body L* 54.8 C 8.3 vs ground L* 63.0 C 48.5, hue gap n/a (body C* <= 25); top third (world height) dE 48.9, L* 60.1; per-pixel dE 56.8, outline 41.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 93 | worst heath: dE 24.5 (heath dE 24.5, old_wood dE 35.0, riverbank dE 40.4, snow dE 35.8, ash dE 31.8, sand dE 38.1, marsh dE 39.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 93 | bar hides 5% of the silhouette (gap -9 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.6 m, 2.6 m wide |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 2 | 0-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.86 (min 0.83), area kept 97-100% (min 2231 px), frame-to-frame IoU min 0.85; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 350 px (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 31% of the silhouette (t 0.14 s) | >= 10% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.03 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 92 | outline complexity 2.49 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 60.1, bottom third L* 18.1 (+42, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.7 at 25 m, 13.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

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
- Per-mesh vertices (biggest first): Root/Mount/Head/Merged 1068 v / 7 s; Root/Mount/Merged 1043 v / 4 s; Root/Mount/Bristles 696 v / 2 s; Root/Mount/LegFL/Merged 318 v / 3 s; Root/Mount/LegFR/Merged 318 v / 3 s; Root/Mount/LegBL/Merged 241 v / 2 s; Root/Mount/LegBR/Merged 241 v / 2 s; Root/Mount/Head/TuskR 60 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
