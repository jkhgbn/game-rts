# Art Lab scorecard: wildcaller

Scene `res://art/units/champions/wildcaller/wildcaller.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-30 14:39:27 · lab v3.1

## Result: **WARN** · quality **90 / 100** (90.2) (previous run 90, +0)

0 FAIL · 3 WARN · 27 PASS · 18 info · 0 skipped · 26 s

## Before / after (vs the run of 2026-09-30 11:42:07 in `docs/art/lab/_champ_neutral/before/wildcaller`: quality 87 -> 90, +3)
### What got worse (1)
1. **R4 Contrast on the other grounds: WARN 40 -> WARN 36 (-4)**. Now: worst heath: dE 6.5 (heath dE 6.5, old_wood dE 28.1, riverbank dE 34.8, snow dE 39.1, ash dE 32.2, sand dE 33.7, marsh dE 37.2). Was: worst heath: dE 9.7 (heath dE 9.7, old_wood dE 31.2, riverbank dE 35.8, snow dE 43.1, ash dE 43.0, sand dE 25.0, marsh d

### What got better (4)
B8 Unique materials: FAIL 0 -> PASS 89 (+89); R3 Contrast vs ground (meadow): PASS 90 -> PASS 100 (+10); S1 Style bible: golden autumn (style-autumn.md 3): INFO 9 -> INFO 44 (+35); R12 Contrast under every light preset (meadow): PASS 87 -> PASS 94 (+6)

gone B9m Meshes built per instance (was WARN)

### Score delta per check (9 changed, 43 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B8 | Unique materials | FAIL 0 | PASS 89 | +88.8 |
| C1 | Shape richness (secondary shapes) | INFO 79 | INFO 80 | +1.2 |
| R8 | Head height vs body_height | PASS 85 | PASS 85 | +0.7 |
| R3 | Contrast vs ground (meadow) | PASS 90 | PASS 100 | +9.5 |
| R4 | Contrast on the other grounds | WARN 40 | WARN 36 | -4.5 |
| R5c | Glow points stand out (1 m surround) | PASS 93 | PASS 95 | +2.2 (noisy) |
| R12 | Contrast under every light preset (meadow) | PASS 87 | PASS 94 | +6.3 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 9 | INFO 44 | +34.8 |
| R11 | Reads while walking (40 m) | PASS 95 | PASS 97 | +1.3 (noisy) |

Changed pixels per shot: z40 2.0 %, z55 1.4 %, z25 2.3 %, close 8.0 %, strike_side 8.3 %, turns 7.7 %, cast 4.5 %, anim 5.3 %, silhouette 0.8 %, lineup 5.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Contrast on the other grounds** (WARN): Body colour: no single recolourable body material found (all team / emissive / tiny): A value accent that works on dark and light grounds (a pale crest / dark saddle) [fixes.json #1] _(from R4 Contrast on the other grounds, shot z40)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Staff 0.71 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Vertices** (WARN): B4 26025 -> 13016 (want <= 3000): `Merged` 9415 -> 4708 verts; `Staff` 8598 -> 4299 verts; `Variant` 4226 -> 2113 verts; `Merged` 1668 -> 834 verts; `Merged` 983 -> 492 verts; `Merged` 287 -> 144 verts; `Merged` 284 -> 142 verts; `Merged` 280 -> 140 verts; `Merged` 280 -> 140 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
4. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (19.6): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 24.6): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, (root) 1, ArmL 1, Chest 1, Hips 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 35 | 26025 (body + face above its allowance: face 708 v, allowance 900, total 26733; biggest: Merged 9415, Staff 8598, Variant 4226, Merged 1668) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 94 | 1 (CrownMotes) | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | PASS 89 | 5 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B1a | Authored build parts (before the merge) | INFO | 14 (model says 13) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 14 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 2821 of 36786 triangles (7%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.08 ms process, render CPU +0.49 ms, GPU +2.17 ms) | <= 0.005 ms per instance (champions.md 4 / 13, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 85 | head top 2.49 m / body_height 2.0 (x1.24) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Staff 0.71 m | narrower than 0.6 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.92 / z 0.7 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 876 px (40 x 51 bbox; 55 m: 444 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 40.2, 1% of the body melts (within dE 15 of the ground); body L* 53.0 C 13.5 vs ground L* 62.0 C 48.6, hue gap n/a (body C* <= 25); top third (world height) dE 45.2, L* 75.4; per-pixel dE 53.6, outline 45.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | **WARN** 36 | worst heath: dE 6.5 (heath dE 6.5, old_wood dE 28.1, riverbank dE 34.8, snow dE 39.1, ash dE 32.2, sand dE 33.7, marsh dE 37.2) | dE >= 10 on every skirmish ground (WARN only) | A value accent that works on dark and light grounds (a pale crest / dark saddle) |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +36 (point 1 dL +36; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): CrownMotes; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 94 | worst night: dE 25.0, dL +7 (warm dE 40.1, ice dE 35.7, night dE 25.0, autumn dE 36.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 97 | walk frames vs rest: mean IoU 0.79 (min 0.74), area kept 94-102% (min 817 px), frame-to-frame IoU min 0.76; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 93 | max IoU 0.55 (ash_hurler 0.55, shadow_knight 0.54, gloomcap_elder 0.45, ruin_warden 0.41, stormbottle_genie 0.39, hollow_stag 0.31) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.17 m from the body centre at t 0.24 s (2.13 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 36% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 39% of the silhouette at its peak (t 0.25 s; 0.12 s 34%, 0.25 s 39%, 0.4 s 35%, 0.6 s 8%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 80 | 766 shapes over 7 body parts (109.4 per part: LegL 7, LegR 7, Hips 39, Head 172, ArmL 15, ArmR 286, Chest 240); 14% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.873 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 890% of the 3000 verts budget used (26729) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.04 at the close-up (68167 px), 2.07 at 25 m; close-up outline complexity 13.16 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.15 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 75.4, bottom third L* 31.4 (+43, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 19.6 at 25 m, 26.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 44 | on the autumn floor: dE 24.6, 5% melts; body L* 51.1 C 18.0 vs floor L* 51.0 C 42.4 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.35 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"face_verts":900,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 9415 v / 2 s; Root/Chest/ArmR/Staff 8598 v / 2 s; Root/Chest/Head/Variant 4226 v / 2 s; Root/Hips/Merged 1668 v / 1 s; Root/Chest/ArmL/Merged 983 v / 1 s; Root/Chest/Head/Face 708 v / 1 s; Root/Chest/ArmR/Merged 287 v / 1 s; Root/Chest/Head/Merged 284 v / 1 s
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 3 in fixes.json (top: Body colour: no single recolourable body material found (all team / emissive / tiny): A value accent that works on dark and light grounds (a pale crest / dark s)
