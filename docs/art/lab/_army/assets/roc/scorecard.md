# Art Lab scorecard: roc

Scene `res://art/units/neutral/beasts/roc/roc.tscn` · kind **beast** / tier **hero** · kingdom neutral · ground meadow · 2026-09-27 10:28:24 · lab v2.0

## Result: **WARN** · quality **89 / 100**

0 FAIL · 4 WARN · 17 PASS · 10 info · 0 skipped · 23 s

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.9 -> 1.54, or pull the widest parts in to x <= 1.58 / z <= 2.7 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #3] _(from B9m Meshes built per instance)_
3. **Shadow casters** (WARN): B7 8 -> 6 casters: cast_shadow off on the 2 smallest: `Tail1Mesh`, `Neck1Mesh` [fixes.json #2] _(from B7 Shadow casters)_
4. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (0/0/1/1/1/1/1/1 per frame): put them on parts the gait does not cover [fixes.json #4] _(from R5w Glow points while walking (flicker), shot glow)_
5. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -6 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 30 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 13 drawn (13 mesh + 0 multimesh); per pivot: (root) 1, Body 1, Head 1, Jaw 1, LegFL 1, LegFR 1 | <= 26 (map-fill.md 10 (epic beast hero budget)) |  |
| B2 | Draw instances at rest | PASS 95 | 13 | <= 16 (map-fill.md 10 (epic beast hero budget)) |  |
| B4 | Vertices | PASS 99 | 5731 (biggest: HeadMesh 1102, BodyMesh 622, WingL2Mesh 597, WingR2Mesh 597) | <= 8000 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (epic beast hero budget)) |  |
| B6 | Particle systems | INFO | 1 | no budget for beast/hero |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B7 | Shadow casters | **WARN** 41 | 8 (HeadMesh, Neck1Mesh, WingL2Mesh, WingLMesh, WingR2Mesh, WingRMesh) | <= 6 soft (map-fill.md 10 (epic beast hero budget)) | cast_shadow only on the 3-4 biggest parts (art-units 1.5 / 8) |
| B8 | Unique materials | INFO | 5 | no budget for beast/hero |  |
| B1a | Authored build parts (before the merge) | INFO | 13 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 17 surfaces over 13 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2211 of 8620 triangles (25%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 1.14 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 2.69 / z 1.68 m (radius 0.9, from duskwing_roc.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 2782 px (129 x 75 bbox; 55 m: 1449 px) | >= 350 px (FAIL < 150) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 86.2, 0% of the body melts (within dE 15 of the ground); body L* 52.4 C 35.8 vs ground L* 59.8 C 51.8, hue gap 156 deg; top third (world height) dE 87.3, L* 52.0; per-pixel dE 89.0, outline 57.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 45.6 (heath dE 65.8, old_wood dE 61.5, riverbank dE 62.3, snow dE 53.8, ash dE 45.6, sand dE 73.2, marsh dE 57.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -30 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 4.1 m, 2.34 m wide |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 0/1/1): Neck2Mesh; soft glows under the bloom (v1 count, luma > 0.4): 1 | 0-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.27 (min 0.25), area kept 126-129% (min 3252 px), frame-to-frame IoU min 0.8; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 350 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 50 | points per frame 0/0/1/1/1/1/1/1 (median 1, range 1, 2 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 89% of the silhouette (t 0.24 s) | >= 10% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.8 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.83 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 0 | top third L* 46.4, bottom third L* 52.8 (-6, screen rows) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.7 at 25 m, 10.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

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
- Per-mesh vertices (biggest first): Root/Body/Neck1/Neck2/Head/HeadMesh 1102 v / 3 s; Root/Body/BodyMesh 622 v / 1 s; Root/Body/WingL/WingL2/WingL2Mesh 597 v / 1 s; Root/Body/WingR/WingR2/WingR2Mesh 597 v / 1 s; Root/Body/Tail1/Tail1Mesh 504 v / 1 s; Root/Body/WingL/WingLMesh 499 v / 1 s; Root/Body/WingR/WingRMesh 499 v / 1 s; Root/Body/LegFL/LegFLMesh 386 v / 2 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 4 in fixes.json (top: R10: raise UnitType.radius 0.9 -> 1.54, or pull the widest parts in to x <= 1.58 / z <= 2.7 m)
