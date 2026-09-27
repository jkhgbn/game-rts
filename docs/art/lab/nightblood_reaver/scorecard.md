# Art Lab scorecard: nightblood_reaver

Scene `res://art/units/shadow/nightblood_reaver/nightblood_reaver.tscn` · kind **unit** / tier **soldier** · kingdom shadow · ground meadow · 2026-09-27 17:45:39 · lab v3.1

## Result: **PASS** · quality **92 / 100** (91.6) (previous run 89, +3)

0 FAIL · 0 WARN · 33 PASS · 17 info · 0 skipped · 33 s

## Before / after (vs the run of 2026-09-27 17:34:56 in `docs/art/lab/nightblood_reaver`: quality 89 -> 92, +3)
### What got worse (1)
1. **P4 Detail density 25 m / 40 m: INFO 25 -> INFO 0 (-25) (noisy check: re-run before acting)**. Now: inner detail 16.1 at 25 m, 22.0 at 40 m (mean /grad L*/ per px). Was: inner detail 14.0 at 25 m, 18.6 at 40 m (mean /grad L*/ per px)

### What got better (3)
P5 Glow placement: INFO 0 -> INFO 100 (+100); P3 Tops light, bottoms dark: INFO 0 -> INFO 48 (+48); C3 Palette depth (close-up): INFO 25 -> INFO 45 (+20)

### Score delta per check (8 changed, 46 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C3 | Palette depth (close-up) | INFO 25 | INFO 45 | +20.0 |
| R4 | Contrast on the other grounds | PASS 90 | PASS 89 | -1.5 |
| R6cb | Team colours for colour-blind players | PASS 80 | PASS 79 | -1.0 |
| P3 | Tops light, bottoms dark | INFO 0 | INFO 48 | +48.1 |
| P4 | Detail density 25 m / 40 m | INFO 25 | INFO 0 | -24.6 (noisy) |
| R5c | Glow points stand out (1 m surround) | PASS 80 | PASS 83 | +2.7 (noisy) |
| P5 | Glow placement | INFO 0 | INFO 100 | +100.0 |
| B13 | Frame cost | PASS 98 | PASS 100 | +2.0 (noisy) |

Changed pixels per shot: z40 0.3 %, z55 0.2 %, z25 0.3 %, close 0.9 %, strike_side 6.7 %, turns 2.3 %, cast 1.4 %, anim 2.2 %, silhouette 0.0 %, lineup 2.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 57% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.84): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 7 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
3. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (16.1): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +3 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Contrast on the other grounds** (PASS): On ash the body drops to dE 20.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 19% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 21 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 85 | 2494 (biggest: Merged 614, Merged 571, Merged 400, Merged 309) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 64 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 35 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 318 of 2630 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0004 ms process per instance (100 animated at 40 m: +0.04 ms process, render CPU +1.92 ms, GPU +0.29 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.035 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 2.03 m / body_height 2.1 (x0.96) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.57 / z 0.78 m (radius 0.55, from nightblood_reaver.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 614 px (32 x 38 bbox; 55 m: 299 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 81.2, 0% of the body melts (within dE 15 of the ground); body L* 25.1 C 24.1 vs ground L* 62.3 C 48.4, hue gap n/a (body C* <= 25); top third (world height) dE 79.2, L* 27.8; per-pixel dE 86.3, outline 68.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 98 | dE 30.3, 1% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 89 | worst ash: dE 20.9 (heath dE 49.6, old_wood dE 44.7, riverbank dE 58.7, snow dE 70.0, ash dE 20.9, sand dE 76.0, marsh dE 30.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 94 | 19% of body pixels change between kingdom colours (min pair 19%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 60.0 (fire 69.3, shadow 81.1, ice 69.9, nature 60.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.4 on the team-colour area (normal vision 85.1; 123 px); deutan: fire / nature dE 11.4; protan: fire / nature dE 24.5; worst vs ground: fire colour (deutan) dE 53.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.6 m, 1.43 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 83 | worst dL +2 (point 1 dL +2, point 2 dL +24; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/1/2): Merged x2; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 46.7, dL -10 (warm dE 81.4, ice dE 73.9, night dE 46.7, autumn dE 74.1); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.86 (min 0.79), area kept 99-102% (min 611 px), frame-to-frame IoU min 0.82; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 2/2/2/1/1/1/1/1 (median 1, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 96 | max IoU 0.51 (shade 0.51, hexweaver 0.45, shadow_knight 0.42, gloom_thrall 0.41) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.5 m from the body centre at t 0.24 s (1.48 m forward; geometry clipped at the ground); declared 1.8 m (UnitType attack_range (nightblood_reaver.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 62% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 21% of the silhouette at its peak (t 0.6 s; 0.12 s 16%, 0.25 s 20%, 0.4 s 21%, 0.6 s 21%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 42 | 81 shapes over 7 body parts (11.6 per part: LegL 5, LegR 5, Hips 10, Head 8, ArmL 12, ArmR 21, Chest 20); 57% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.836 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 99% of the 2500 verts budget used (2490) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 45 | 10 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.9 at the close-up (85710 px), 2.02 at 25 m; close-up outline complexity 8.69 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.24 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 48 | top third L* 27.8, bottom third L* 24.6 (+3, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 0 | inner detail 16.1 at 25 m, 22.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 60.8, 0% melts; body L* 23.3 C 20.6 vs floor L* 51.2 C 42.7; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 73 | front-view asymmetry 0.15 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/ArmR/Merged 614 v / 6 s; Root/Chest/Merged 571 v / 6 s; Root/Chest/ArmL/Merged 400 v / 4 s; Root/Hips/Merged 309 v / 6 s; Root/Chest/Head/Merged 252 v / 4 s; Root/Hips/LegL/Merged 172 v / 4 s; Root/Hips/LegR/Merged 172 v / 4 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
