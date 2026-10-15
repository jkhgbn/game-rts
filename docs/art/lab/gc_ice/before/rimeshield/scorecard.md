# Art Lab scorecard: rimeshield

Scene `res://art/units/ice/rimeshield.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-10-15 12:14:22 · lab v3.1

## Result: **WARN** · quality **93 / 100** (93.4)

0 FAIL · 2 WARN · 31 PASS · 17 info · 0 skipped · 34 s

## Improve next
1. **Head height vs body_height** (WARN): R8: body_height 1.7 -> 2.19 in res://art/units/ice/rimeshield.tscn (root) and res://data/units/rimeshield.tres (the head top; x1.29 now), or lower the head / crest 0.06 m [fixes.json #1] _(from R8 Head height vs body_height)_
2. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.5 -> 0.51, or pull the widest parts in to x <= 0.88 / z <= 0.88 m [fixes.json #2] _(from R10 Footprint vs selection radius)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 58% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.84): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 19% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

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
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Head 2, (root) 1, ArmL 1, ArmR 1, Chest 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1714 (body + face above its allowance: face 652 v, allowance 800, total 2366; biggest: Face 652, Merged 480, Merged 417, Merged 270) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 44 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 334 of 2854 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0007 ms process per instance (100 animated at 40 m: +0.07 ms process, render CPU +0.92 ms, GPU +0.57 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 49 | head top 2.19 m / body_height 1.7 (x1.29) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.9 / z 0.69 m (radius 0.5, from rimeshield.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 818 px (34 x 40 bbox; 55 m: 415 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 59.5, 0% of the body melts (within dE 15 of the ground); body L* 67.2 C 15.2 vs ground L* 62.9 C 48.0, hue gap n/a (body C* <= 25); top third (world height) dE 62.9, L* 68.2; per-pixel dE 62.8, outline 49.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 97 | dE 29.6, 16% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 99 | worst snow: dE 29.6 (heath dE 37.1, old_wood dE 51.2, riverbank dE 50.8, snow dE 29.6, ash dE 47.3, sand dE 49.4, marsh dE 57.7) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 93 | 19% of body pixels change between kingdom colours (min pair 13%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 52.5 (fire 55.8, shadow 64.1, ice 59.1, nature 52.5) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 74 | worst pair fire / nature (deutan): dE 6.6 on the team-colour area (normal vision 46.8; 188 px); deutan: fire / nature dE 6.6; protan: fire / nature dE 13.6; worst vs ground: fire colour (deutan) dE 49.5 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -4 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.2 m, 1.3 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +29 (point 1 dL +29; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): Face; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 55.3, dL +5 (warm dE 59.6, ice dE 55.9, night dE 56.3, autumn dE 55.3); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.87 (min 0.82), area kept 97-98% (min 785 px), frame-to-frame IoU min 0.85; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 94 | max IoU 0.54 (gloomcap_elder 0.54, frost_mortar_placeholder 0.54, rimecarver 0.5, rime_seer 0.48, ruin_warden 0.46, frostbow 0.45) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.29 m from the body centre at t 0.08 s (1.28 m forward; geometry clipped at the ground); declared 1.6 m (UnitType attack_range (rimeshield.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 42% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 28% of the silhouette at its peak (t 0.4 s; 0.12 s 26%, 0.25 s 28%, 0.4 s 28%, 0.6 s 19%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 43 | 55 shapes over 7 body parts (7.9 per part: LegL 2, LegR 2, Hips 2, Head 27, ArmL 8, ArmR 5, Chest 9); 58% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.844 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 94% of the 2500 verts budget used (2362) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.77 at the close-up (87300 px), 2.14 at 25 m; close-up outline complexity 3.54 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 82 | outline complexity 2.37 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 68.2, bottom third L* 52.6 (+15, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.3 at 25 m, 10.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 54.8, 0% melts; body L* 64.4 C 10.4 vs floor L* 51.9 C 43.1; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.4 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 652 v / 1 s; Root/Chest/Merged 480 v / 3 s; Root/Chest/ArmL/Merged 417 v / 6 s; Root/Chest/Head/Merged 270 v / 4 s; Root/Chest/ArmR/Merged 239 v / 4 s; Root/Hips/LegL/Merged 105 v / 2 s; Root/Hips/LegR/Merged 105 v / 2 s; Root/Hips/Merged 94 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R8: body_height 1.7 -> 2.19 in res://art/units/ice/rimeshield.tscn (root) and res://data/units/rimeshield.tres (the head top; x1.29 now), or lower the head / cr)
