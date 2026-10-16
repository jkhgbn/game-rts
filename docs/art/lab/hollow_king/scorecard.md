# Art Lab scorecard: hollow_king

Scene `res://art/units/titans/hollow_king/hollow_king.tscn` · kind **titan** / tier **titan** · kingdom neutral · ground meadow · 2026-10-16 10:45:55 · lab v3.1

## Result: **PASS** · quality **91 / 100** (91.4) (previous run 87, +4)

0 FAIL · 0 WARN · 25 PASS · 17 info · 0 skipped · 32 s

## Before / after (vs the run of 2026-10-16 10:26:47 in `docs/art/lab/hollow_king`: quality 87 -> 91, +4)
### What got worse (1)
1. **P3 Tops light, bottoms dark: INFO 100 -> INFO 96 (-4)**. Now: top third L* 60.7, bottom third L* 49.3 (+11, world height). Was: top third L* 61.3, bottom third L* 47.7 (+13, world height)

### What got better (3)
B9 Materials built per instance: FAIL 0 -> PASS 100 (+100); R5w Glow points while walking (flicker): WARN 44 -> PASS 89 (+45) (noisy check: re-run before acting); R5c Glow points stand out (1 m surround): WARN 56 -> PASS 89 (+34) (noisy check: re-run before acting)

### Score delta per check (7 changed, 38 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B9 | Materials built per instance | FAIL 0 | PASS 100 | +100.0 |
| R4 | Contrast on the other grounds | PASS 84 | PASS 83 | -1.1 |
| P3 | Tops light, bottoms dark | INFO 100 | INFO 96 | -3.7 |
| R5c | Glow points stand out (1 m surround) | WARN 56 | PASS 89 | +33.8 (noisy) |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 57 | INFO 59 | +1.5 |
| R5w | Glow points while walking (flicker) | WARN 44 | PASS 89 | +45.3 (noisy) |
| P2 | Asymmetric secondary shape | INFO 60 | INFO 61 | +0.8 |

Changed pixels per shot: z40 1.1 %, z55 0.6 %, z25 1.3 %, close 0.9 %, strike_side 1.1 %, turns 1.7 %, cast 1.0 %, anim 0.5 %, silhouette 6.8 %, lineup 32.7 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Vertex use vs budget** (INFO): Only 42% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 43% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.84): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Asymmetric secondary shape** (INFO): Add an asymmetric secondary element to the front read (asymmetry 0.13): a shoulder banner, a one-sided weapon / shield, a broken horn (>= ~0.25 m wide, or it does not register at 40 m) _(from P2 Asymmetric secondary shape, shot silhouette)_
4. **Contrast on the other grounds** (PASS): On heath the body drops to dE 16.5: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 30.1): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 37 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: ArmL 2, ArmR 2, LegL 2, LegR 2, (root) 1, Chest 1 | <= 36 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B2 | Draw instances at rest | PASS 100 | 12 | <= 20 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B4 | Vertices | PASS 100 | 5056 (biggest: HollowKing 825, HKChain_arm_l 637, HKChain_arm_r 637, HollowKing 617) | <= 12000 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 (cavalry-mounts.md 10, titans-2.md 11) |  |
| B7 | Shadow casters | PASS 100 | 4 (HollowKing, HollowKing, HollowKing, HollowKing) | <= 12 soft (cavalry-mounts.md 10, titans-2.md 11) |  |
| B8 | Unique materials | INFO | 29 | no budget for titan/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 74 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 29 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 864 of 6442 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (12 animated at 40 m: +-0.1 ms process, render CPU +0.18 ms, GPU +0.03 ms) | <= 0.02 ms per instance soft (cavalry-mounts.md 10, titans-2.md 11) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.061 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 3472 px (145 x 115 bbox; 55 m: 1774 px) | >= 900 px (FAIL < 350) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 47.2, 0% of the body melts (within dE 15 of the ground); body L* 51.1 C 18.0 vs ground L* 62.1 C 49.0, hue gap n/a (body C* <= 25); top third (world height) dE 45.7, L* 60.7; per-pixel dE 56.4, outline 45.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 83 | worst heath: dE 16.5 (heath dE 16.5, old_wood dE 32.7, riverbank dE 40.6, snow dE 42.5, ash dE 30.3, sand dE 36.3, marsh dE 35.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 94 | bar hides 4% of the silhouette (gap -10 px) | <= 6% (FAIL > 20%); bar at body_height + 0.5 = 3.1 m, 4.16 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +1 (point 1 dL +17, point 2 dL +1, point 3 dL +22, point 4 dL +42, point 5 dL +49; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 5 point(s) above the bloom level 1.2 (median of 5/6/5): HKChain_arm_r, HKChain_arm_l, HKChain_leg_l, HollowKing x2, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 8 | 1-5 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 32.2, dL +4 (warm dE 48.5, ice dE 45.7, night dE 32.2, autumn dE 43.7); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 89 | walk frames vs rest: mean IoU 0.66 (min 0.59), area kept 96-99% (min 3336 px), frame-to-frame IoU min 0.62; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 900 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 4/4/4/4/5/4/5/6 (median 4, range 2, 0 frame(s) at 0; at rest 5) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.4 (elder_treant 0.4, grizzlemaw 0.38, roc 0.36, nightmare_knight 0.35, war_mammoth 0.3, cinder_dragon 0.18) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 4.17 m from the body centre at t 0.14 s (3.66 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 49% of the silhouette (t 0.24 s) | >= 8% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 38% of the silhouette at its peak (t 0.4 s; 0.12 s 37%, 0.25 s 38%, 0.4 s 38%, 0.6 s 31%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.0 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 57 | 116 shapes over 7 body parts (16.6 per part: LegL 17, LegR 17, Hips 2, Head 18, ArmL 21, ArmR 21, Chest 20); 43% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.84 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 35 | 42% of the 12000 verts budget used (5052) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 17 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.16 at the close-up (41082 px), 1.81 at 25 m; close-up outline complexity 12.37 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 8.98 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 96 | top third L* 60.7, bottom third L* 49.3 (+11, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.7 at 25 m, 11.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 40 | 1 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 59 | on the autumn floor: dE 30.1, 0% melts; body L* 48.7 C 25.1 vs floor L* 59.5 C 39.8 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 61 | front-view asymmetry 0.13 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10, titans-2.md 11)
`{"draw":20,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":12,"frame_ms":0.02,"verts":12000},"src":"cavalry-mounts.md 10, titans-2.md 11"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/HollowKing 825 v / 7 s; Root/Chest/ArmL/HKChain_arm_l 637 v / 1 s; Root/Chest/ArmR/HKChain_arm_r 637 v / 1 s; Root/Chest/Head/HollowKing 617 v / 3 s; Root/Hips/LegL/HKChain_leg_l 588 v / 1 s; Root/Hips/LegR/HKChain_leg_r 588 v / 1 s; Root/Chest/ArmL/HollowKing 305 v / 3 s; Root/Chest/ArmR/HollowKing 305 v / 3 s
- 15 hidden parts at rest (toggled states, not counted as draws)
- 18 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
