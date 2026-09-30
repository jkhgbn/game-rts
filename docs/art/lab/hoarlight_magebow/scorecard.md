# Art Lab scorecard: hoarlight_magebow

Scene `res://art/units/ice/hoarlight_magebow/hoarlight_magebow.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-09-30 11:02:48 · lab v3.1

## Result: **PASS** · quality **96 / 100** (95.5) (previous run 94, +2)

0 FAIL · 0 WARN · 33 PASS · 17 info · 0 skipped · 24 s

## Before / after (vs the run of 2026-09-27 17:59:13 in `docs/art/lab/hoarlight_magebow`: quality 94 -> 96, +2)
### What got worse (0)
Nothing got worse.

### What got better (7)
C3 Palette depth (close-up): INFO 88 -> INFO 100 (+13); C4 Inner detail (close-up / 25 m): INFO 89 -> INFO 100 (+11); C1 Shape richness (secondary shapes): INFO 33 -> INFO 38 (+5); P1 Silhouette hook: INFO 46 -> INFO 54 (+8); R3t Contrast in every team colour (meadow): PASS 92 -> PASS 95 (+3); R4k Contrast on the home ground (snow): PASS 97 -> PASS 100 (+3); B4 Vertices: PASS 87 -> PASS 89 (+2)

### Score delta per check (9 changed, 43 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B2 | Draw instances at rest | PASS 100 | PASS 99 | -0.6 |
| B4 | Vertices | PASS 87 | PASS 89 | +2.4 |
| C1 | Shape richness (secondary shapes) | INFO 33 | INFO 38 | +5.0 |
| C3 | Palette depth (close-up) | INFO 88 | INFO 100 | +12.5 |
| C4 | Inner detail (close-up / 25 m) | INFO 89 | INFO 100 | +10.7 |
| R4k | Contrast on the home ground (snow) | PASS 97 | PASS 100 | +2.5 |
| R3t | Contrast in every team colour (meadow) | PASS 92 | PASS 95 | +2.7 |
| P1 | Silhouette hook | INFO 46 | INFO 54 | +8.3 |
| B13 | Frame cost | PASS 98 | PASS 100 | +2.3 (noisy) |

Changed pixels per shot: z40 0.6 %, z55 0.4 %, z25 0.6 %, close 5.3 %, strike_side 78.5 %, turns 2.8 %, cast 4.2 %, anim 4.6 %, silhouette 15.7 %, lineup 54.5 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 80% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.85): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
2. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.0): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
3. **Distinct from references (black masks)** (PASS): Make it read apart from frostbow (IoU 0.67): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Bow 2, Head 2, (root) 1, ArmL 1, ArmR 1, Chest 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 99 | 10 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 89 | 2304 (body + face above its allowance: face 492 v, allowance 800, total 2796; biggest: Stave 532, Merged 526, Face 492, Merged 453) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 5 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Stave, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 7 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 31 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 267 of 3512 triangles (7%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0012 ms process per instance (100 animated at 40 m: +0.12 ms process, render CPU +0.8 ms, GPU +0.24 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.008 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 93 | head top 1.89 m / body_height 1.7 (x1.11) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.55 / z 0.45 m (radius 0.45, from hoarlight_magebow.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 366 px (19 x 32 bbox; 55 m: 183 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 62.5, 0% of the body melts (within dE 15 of the ground); body L* 63.9 C 17.2 vs ground L* 63.0 C 48.3, hue gap n/a (body C* <= 25); top third (world height) dE 56.2, L* 81.8; per-pixel dE 67.0, outline 49.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 33.8, 20% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 33.8 (heath dE 34.7, old_wood dE 50.6, riverbank dE 51.8, snow dE 33.8, ash dE 44.7, sand dE 52.7, marsh dE 55.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 67% of body pixels change between kingdom colours (min pair 66%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 95 | worst nature colour: dE 27.8 (fire 55.7, shadow 84.3, ice 62.9, nature 27.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 77 | worst pair fire / nature (deutan): dE 9.1 on the team-colour area (normal vision 70.6; 252 px); deutan: fire / nature dE 9.1; protan: fire / nature dE 20.0; worst vs ground: fire colour (deutan) dE 24.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.2 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 92 | worst dL +31 (point 1 dL +31; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Breath, 2 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 57.8, dL +1 (warm dE 63.4, ice dE 59.6, night dE 60.7, autumn dE 57.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.84 (min 0.76), area kept 98-103% (min 361 px), frame-to-frame IoU min 0.77; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.67 (frostbow 0.67, magpie 0.63, shardcaster 0.62, frostrune_rifleman 0.61, tracker 0.51, frost_mortar_placeholder 0.4) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.97 m from the body centre at t 0.08 s (0.92 m forward; geometry clipped at the ground); declared 9.5 m (UnitType attack_range (hoarlight_magebow.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 42% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 33% of the silhouette at its peak (t 0.4 s; 0.12 s 22%, 0.25 s 32%, 0.4 s 33%, 0.6 s 32%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 38 | 86 shapes over 7 body parts (12.3 per part: LegL 7, LegR 7, Head 27, Bow 20, ArmL 5, ArmR 4, Chest 16); 80% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.852 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 111% of the 2500 verts budget used (2792) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 14 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.43 at the close-up (78137 px), 1.53 at 25 m; close-up outline complexity 4.59 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 54 | outline complexity 2.0 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 81.8, bottom third L* 45.4 (+36, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.0 at 25 m, 12.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 56.2, 0% melts; body L* 60.1 C 12.5 vs floor L* 52.1 C 43.1; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.29 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/ArmL/Bow/Stave 532 v / 3 s; Root/Chest/Merged 526 v / 7 s; Root/Chest/Head/Face 492 v / 1 s; Root/Chest/Head/Merged 453 v / 5 s; Root/Chest/ArmL/Merged 203 v / 4 s; Root/Hips/LegL/Merged 186 v / 3 s; Root/Hips/LegR/Merged 186 v / 3 s; Root/Chest/ArmR/Merged 156 v / 3 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
