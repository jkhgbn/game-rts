# Art Lab scorecard: shardguard

Scene `res://art/units/ice/shardguard/shardguard.tscn` · kind **unit** / tier **heavy** · kingdom ice · ground meadow · 2026-09-27 17:24:45 · lab v3.1

## Result: **PASS** · quality **96 / 100** (95.8) (previous run 94, +2)

0 FAIL · 0 WARN · 34 PASS · 16 info · 0 skipped · 31 s

## Before / after (vs the run of 2026-09-27 17:22:23 in `docs/art/lab/shardguard`: quality 94 -> 96, +2)
### What got worse (1)
1. **R6 Team-colour visibility at 40 m: PASS 89 -> PASS 86 (-3)**. Now: 13% of body pixels change between kingdom colours (min pair 13%). Was: 15% of body pixels change between kingdom colours (min pair 15%)

### What got better (6)
A3r Weapon reach at the strike: WARN 53 -> PASS 93 (+40); P3 Tops light, bottoms dark: INFO 68 -> INFO 100 (+32); R4 Contrast on the other grounds: PASS 90 -> PASS 95 (+5); C1 Shape richness (secondary shapes): INFO 46 -> INFO 51 (+5); R4k Contrast on the home ground (snow): PASS 89 -> PASS 93 (+5); B4 Vertices: PASS 86 -> PASS 89 (+3)

### Score delta per check (12 changed, 43 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B4 | Vertices | PASS 86 | PASS 89 | +3.2 |
| C1 | Shape richness (secondary shapes) | INFO 46 | INFO 51 | +4.7 |
| R4k | Contrast on the home ground (snow) | PASS 89 | PASS 93 | +4.5 |
| R4 | Contrast on the other grounds | PASS 90 | PASS 95 | +4.9 |
| R6 | Team-colour visibility at 40 m | PASS 89 | PASS 86 | -2.9 |
| A3r | Weapon reach at the strike | WARN 53 | PASS 93 | +40.1 |
| P3 | Tops light, bottoms dark | INFO 68 | INFO 100 | +31.5 |
| R5c | Glow points stand out (1 m surround) | PASS 90 | PASS 90 | +0.5 (noisy) |
| R11 | Reads while walking (40 m) | PASS 98 | PASS 97 | -1.6 (noisy) |
| R5w | Glow points while walking (flicker) | PASS 84 | PASS 89 | +4.5 (noisy) |
| P2 | Asymmetric secondary shape | INFO 98 | INFO 100 | +1.6 |
| B13 | Frame cost | PASS 93 | PASS 100 | +7.1 (noisy) |

Changed pixels per shot: z40 0.9 %, z55 0.6 %, z25 1.0 %, close 4.8 %, strike_side 9.0 %, turns 3.6 %, cast 3.1 %, anim 3.1 %, silhouette 0.2 %, lineup 5.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 51% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.85): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Distinct from references (black masks)** (PASS): Make it read apart from rimeshield (IoU 0.67): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
3. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 13% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
4. **Contrast on the other grounds** (PASS): On snow the body drops to dE 26.2: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Chest 1, Head 1, Hips 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 0 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 89 | 5539 (biggest: Merged 2017, Merged 1210, Merged 796, Merged 448) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 3 (Merged, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 79 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 33 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 731 of 5096 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.002 ms process per instance (100 animated at 40 m: +0.2 ms process, render CPU +1.43 ms, GPU +-0.1 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.037 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 91 | head top 2.55 m / body_height 2.2 (x1.16) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.83 / z 0.75 m (radius 0.55, from shardguard.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 863 px (35 x 45 bbox; 55 m: 444 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 57.1, 0% of the body melts (within dE 15 of the ground); body L* 68.3 C 10.6 vs ground L* 62.5 C 48.3, hue gap n/a (body C* <= 25); top third (world height) dE 58.7, L* 73.2; per-pixel dE 61.2, outline 45.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 93 | dE 26.2, 35% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 95 | worst snow: dE 26.2 (heath dE 35.3, old_wood dE 50.2, riverbank dE 50.4, snow dE 26.2, ash dE 46.8, sand dE 45.0, marsh dE 56.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 86 | 13% of body pixels change between kingdom colours (min pair 13%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 50.8 (fire 54.4, shadow 62.5, ice 57.0, nature 50.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 78 | worst pair fire / nature (deutan): dE 10.4 on the team-colour area (normal vision 69.3; 120 px); deutan: fire / nature dE 10.4; protan: fire / nature dE 20.2; worst vs ground: fire colour (deutan) dE 45.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.7 m, 1.43 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +27 (point 1 dL +27; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Merged; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 51.0, dL +7 (warm dE 56.7, ice dE 54.0, night dE 55.1, autumn dE 51.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 97 | walk frames vs rest: mean IoU 0.79 (min 0.73), area kept 92-96% (min 831 px), frame-to-frame IoU min 0.77; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 1/2/2/2/2/2/1/1 (median 2, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.67 (rimeshield 0.67, frostbow 0.43, rime_colossus 0.36) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | PASS 93 | tip reaches 2.05 m from the body centre at t 0.14 s (2.03 m forward; geometry clipped at the ground); declared 2.4 m (reach= (brief)) | the strike frame shows the weapon tip at >= 80% of the declared reach, above the ground (side frames: strike_side.jpg) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 61% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 40% of the silhouette at its peak (t 0.25 s; 0.12 s 27%, 0.25 s 40%, 0.4 s 33%, 0.6 s 37%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 51 | 131 shapes over 7 body parts (18.7 per part: LegL 5, LegR 5, Hips 30, Head 10, ArmL 4, ArmR 15, Chest 62); 51% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.848 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 92% of the 6000 verts budget used (5535) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.7 at the close-up (76366 px), 1.84 at 25 m; close-up outline complexity 8.77 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.47 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 73.2, bottom third L* 54.6 (+18, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.0 at 25 m, 12.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 48.6, 0% melts; body L* 65.5 C 3.7 vs floor L* 51.3 C 42.7; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.23 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 2017 v / 6 s; Root/Chest/ArmR/Merged 1210 v / 7 s; Root/Hips/Merged 796 v / 5 s; Root/Chest/ArmL/Merged 448 v / 3 s; Root/Chest/Head/Merged 432 v / 5 s; Root/Hips/LegL/Merged 316 v / 3 s; Root/Hips/LegR/Merged 316 v / 3 s; Shadow 4 v / 1 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
