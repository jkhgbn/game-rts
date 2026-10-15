# Art Lab scorecard: roc

Scene `res://art/units/neutral/beasts/roc/roc.tscn` · kind **beast** / tier **hero** · kingdom neutral · ground meadow · 2026-10-15 13:32:06 · lab v3.1

## Result: **WARN** · quality **95 / 100** (95.0)

0 FAIL · 1 WARN · 22 PASS · 18 info · 0 skipped · 27 s

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.9 -> 1.54, or pull the widest parts in to x <= 1.58 / z <= 2.7 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Asymmetric secondary shape** (INFO): Add an asymmetric secondary element to the front read (asymmetry 0.1): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m) _(from P2 Asymmetric secondary shape, shot silhouette)_
3. **Surfaces per instance** (IDEA): Merge surfaces that share a material (18 surfaces for 14 meshes = 18 draw calls) _(from B11)_

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
| B1 | Meshes after the kit merge | PASS 100 | 14 drawn (14 mesh + 0 multimesh); per pivot: Head 2, (root) 1, Body 1, Jaw 1, LegFL 1, LegFR 1 | <= 26 (map-fill.md 10 (epic beast hero budget)) |  |
| B2 | Draw instances at rest | PASS 92 | 14 | <= 16 (map-fill.md 10 (epic beast hero budget)) |  |
| B3 | keep_separate parts | INFO | 1 | no budget for beast/hero |  |
| B4 | Vertices | PASS 96 | 6203 (body + face above its allowance: face 472 v, allowance 0, total 6203; biggest: HeadMesh 1102, BodyMesh 622, WingL2Mesh 597, WingR2Mesh 597) | <= 8000 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (epic beast hero budget)) |  |
| B6 | Particle systems | INFO | 1 | no budget for beast/hero |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B7 | Shadow casters | PASS 88 | 6 (HeadMesh, WingL2Mesh, WingLMesh, WingR2Mesh, WingRMesh, BodyMesh) | <= 6 soft (map-fill.md 10 (epic beast hero budget)) |  |
| B8 | Unique materials | INFO | 6 | no budget for beast/hero |  |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 18 surfaces over 14 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2209 of 9564 triangles (23%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (12 animated at 40 m: +-0.08 ms process, render CPU +0.08 ms, GPU +0.22 ms) | <= 0.01 ms per instance (map-fill.md 10 (epic beast hero budget)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 1.13 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 2.69 / z 1.68 m (radius 0.9, from duskwing_roc.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 2482 px (117 x 82 bbox; 55 m: 1270 px) | >= 350 px (FAIL < 150) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 83.2, 0% of the body melts (within dE 15 of the ground); body L* 53.3 C 33.7 vs ground L* 60.9 C 50.5, hue gap 158 deg; top third (world height) dE 79.1, L* 58.1; per-pixel dE 86.7, outline 62.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 44.7 (heath dE 67.0, old_wood dE 60.9, riverbank dE 63.1, snow dE 51.8, ash dE 44.7, sand dE 71.0, marsh dE 56.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -3 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 4.1 m, 2.34 m wide |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 2 | 0-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 74.0, dL +8 (warm dE 83.6, ice dE 79.6, night dE 74.0, autumn dE 77.3); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.25 (min 0.25), area kept 137-143% (min 3239 px), frame-to-frame IoU min 0.95; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 350 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.32 (elder_treant 0.32, war_mammoth 0.25, grizzlemaw 0.24, tusker 0.2, direwolf 0.16, frost_wyrm 0.12); wing phase matched to the target's (p 0.72; residual per flyer ref: frost_wyrm 0.01) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A3r | Weapon reach at the strike | PASS 100 | tip reaches 3.27 m from the body centre at t 0.24 s (1.77 m forward; geometry clipped at the ground); declared 3.0 m (UnitType attack_range (duskwing_roc.tres)) | the strike frame shows the weapon tip at >= 80% of the declared reach, above the ground (side frames: strike_side.jpg) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 84% of the silhouette (t 0.14 s) | >= 10% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 90% of the silhouette at its peak (t 0.12 s; 0.12 s 90%, 0.25 s 66%, 0.4 s 82%, 0.6 s 89%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.81 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 95 | 121 shapes over 12 body parts (10.1 per part: Jaw 1, Head 47, Neck2 1, Neck1 8, WingL2 17, WingL 3, WingR2 17, WingR 3, Tail1 2, LegFL 9, LegFR 9, Body 4); 3% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.908 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 77% of the 8000 verts budget used (6199) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 80 | 11 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.76 at the close-up (27083 px), 2.59 at 25 m; close-up outline complexity 8.59 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.28 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 58.1, bottom third L* 34.0 (+24, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.9 at 25 m, 10.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 66.1, 0% melts; body L* 48.2 C 28.4 vs floor L* 46.6 C 40.1 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 46 | front-view asymmetry 0.1 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- strike_side: [strike_side.jpg](strike_side.jpg)
- turns: [turns.jpg](turns.jpg)
- cast: [cast.jpg](cast.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (epic beast hero budget))
`{"draw":16,"frame_ms":0.01,"lights":0,"meshes":26,"n":12,"runtime_mats":0,"soft":{"casters":6,"looping":2,"verts":8000},"src":"map-fill.md 10 (epic beast hero budget)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Body/Neck1/Neck2/Head/HeadMesh 1102 v / 3 s; Root/Body/BodyMesh 622 v / 1 s; Root/Body/WingL/WingL2/WingL2Mesh 597 v / 1 s; Root/Body/WingR/WingR2/WingR2Mesh 597 v / 1 s; Root/Body/Tail1/Tail1Mesh 504 v / 1 s; Root/Body/WingL/WingLMesh 499 v / 1 s; Root/Body/WingR/WingRMesh 499 v / 1 s; Root/Body/Neck1/Neck2/Head/Face 472 v / 1 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R10: raise UnitType.radius 0.9 -> 1.54, or pull the widest parts in to x <= 1.58 / z <= 2.7 m)
