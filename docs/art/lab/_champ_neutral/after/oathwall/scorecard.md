# Art Lab scorecard: oathwall

Scene `res://art/units/champions/oathwall/oathwall.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-30 14:53:42 · lab v3.1

## Result: **PASS** · quality **93 / 100** (92.9) (previous run 93, +0)

0 FAIL · 0 WARN · 29 PASS · 18 info · 0 skipped · 30 s

## Before / after (vs the run of 2026-09-30 11:43:28 in `docs/art/lab/_champ_neutral/before/oathwall`: quality 91 -> 93, +2)
### What got worse (2)
1. **P3 Tops light, bottoms dark: INFO 100 -> INFO 50 (-50)**. Now: top third L* 67.7, bottom third L* 64.3 (+3, world height). Was: top third L* 59.7, bottom third L* 44.5 (+15, world height)
2. **C3 Palette depth (close-up): INFO 80 -> INFO 57 (-23)**. Now: 10 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %). Was: 11 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %)

### What got better (4)
B8 Unique materials: FAIL 0 -> PASS 89 (+89); P5 Glow placement: INFO 0 -> INFO 100 (+100); R4 Contrast on the other grounds: PASS 83 -> PASS 90 (+7); S1 Style bible: golden autumn (style-autumn.md 3): INFO 55 -> INFO 70 (+16)

### Score delta per check (8 changed, 41 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B8 | Unique materials | FAIL 0 | PASS 89 | +88.8 |
| C3 | Palette depth (close-up) | INFO 80 | INFO 57 | -22.5 |
| R4 | Contrast on the other grounds | PASS 83 | PASS 90 | +7.3 |
| P1 | Silhouette hook | INFO 77 | INFO 79 | +1.3 |
| P3 | Tops light, bottoms dark | INFO 100 | INFO 50 | -50.5 |
| R5c | Glow points stand out (1 m surround) | PASS 90 | PASS 86 | -4.2 (noisy) |
| P5 | Glow placement | INFO 0 | INFO 100 | +100.0 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 55 | INFO 70 | +15.7 |

Changed pixels per shot: z40 1.7 %, z55 1.3 %, z25 2.0 %, close 10.9 %, strike_side 7.5 %, turns 6.1 %, cast 7.1 %, anim 5.3 %, silhouette 14.3 %, lineup 13.9 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 88% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.74): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 8 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +3 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from ruin_warden (IoU 0.62): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Contrast on the other grounds** (PASS): On heath the body drops to dE 21.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 11 drawn (11 mesh + 0 multimesh); per pivot: Head 3, ArmL 2, (root) 1, ArmR 1, Chest 1, Hips 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 11 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 2059 (body + face above its allowance: face 746 v, allowance 900, total 2805; biggest: DoorShield 844, Face 746, Merged 332, Merged 257) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | PASS 89 | 5 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B1a | Authored build parts (before the merge) | INFO | 25 (model says 24) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 13 surfaces over 11 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 362 of 3324 triangles (10%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0003 ms process per instance (100 animated at 40 m: +0.03 ms process, render CPU +0.34 ms, GPU +0.22 ms) | <= 0.005 ms per instance (champions.md 4 / 13, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.99 m / body_height 2.0 (x0.99) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R10 | Footprint vs selection radius | INFO | x 1.12 / z 1.01 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1555 px (50 x 51 bbox; 55 m: 810 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 44.6, 0% of the body melts (within dE 15 of the ground); body L* 69.1 C 8.4 vs ground L* 63.1 C 48.1, hue gap n/a (body C* <= 25); top third (world height) dE 48.0, L* 67.7; per-pixel dE 49.0, outline 40.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 90 | worst heath: dE 21.9 (heath dE 21.9, old_wood dE 44.4, riverbank dE 46.9, snow dE 22.2, ash dE 46.0, sand dE 27.9, marsh dE 53.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 1% of the silhouette (gap -3 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 86 | worst dL +18 (point 1 dL +18; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 38.7, dL +7 (warm dE 44.9, ice dE 46.1, night dE 42.2, autumn dE 38.7); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.89 (min 0.85), area kept 96-98% (min 1483 px), frame-to-frame IoU min 0.85; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 89 | max IoU 0.62 (ruin_warden 0.62, gloomcap_elder 0.6, nightbolt 0.49, tracker 0.45, magpie 0.31, gloom_thrall 0.29) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.77 m from the body centre at t 0.08 s (1.53 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 47% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 41% of the silhouette at its peak (t 0.4 s; 0.12 s 29%, 0.25 s 33%, 0.4 s 41%, 0.6 s 40%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 33 | 86 shapes over 7 body parts (12.3 per part: LegL 2, LegR 2, Hips 5, Head 33, ArmL 30, ArmR 9, Chest 5); 88% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.74 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 93% of the 3000 verts budget used (2801) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 57 | 10 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.34 at the close-up (138370 px), 2.15 at 25 m; close-up outline complexity 3.15 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 79 | outline complexity 2.32 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 50 | top third L* 67.7, bottom third L* 64.3 (+3, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.4 at 25 m, 7.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 70 | on the autumn floor: dE 30.5, 1% melts; body L* 66.0 C 16.8 vs floor L* 52.0 C 43.0 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.42 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/ArmL/DoorShield 844 v / 1 s; Root/Chest/Head/Face 746 v / 1 s; Root/Chest/ArmR/Merged 332 v / 1 s; Root/Chest/Merged 257 v / 2 s; Root/Chest/Head/Variant 162 v / 1 s; Root/Hips/Merged 151 v / 2 s; Root/Chest/Head/Merged 120 v / 1 s; Root/Hips/LegL/Merged 71 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
