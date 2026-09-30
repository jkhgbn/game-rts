# Art Lab scorecard: rimecarver

Scene `res://art/units/ice/rimecarver/rimecarver.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-09-30 16:09:55 · lab v3.1

## Result: **WARN** · quality **95 / 100** (95.0) (previous run 95, +0)

0 FAIL · 1 WARN · 31 PASS · 18 info · 0 skipped · 41 s

## Before / after (vs the run of 2026-09-30 16:03:31 in `docs/art/lab/rimecarver`: quality 95 -> 95, +0)
### What got worse (1)
1. **P1 Silhouette hook: INFO 57 -> INFO 54 (-4)**. Now: outline complexity 2.0. Was: outline complexity 2.05

### Score delta per check (3 changed, 49 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| P1 | Silhouette hook | INFO 57 | INFO 54 | -3.5 |
| R5w | Glow points while walking (flicker) | PASS 100 | PASS 93 | -7.5 (noisy) |
| B13 | Frame cost | PASS 100 | PASS 93 | -6.8 (noisy) |

Changed pixels per shot: z40 0.1 %, z55 0.0 %, z25 0.1 %, close 3.2 %, strike_side 1.9 %, turns 1.4 %, cast 1.0 %, anim 1.1 %, silhouette 0.1 %, lineup 7.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **HP bar over the body at 40 m** (WARN): R7 HP bar over the body at 40 m: The HP bar hides 10% of the body: lower / narrow what sticks up, or fix body_height [fixes.json #1] _(from R7 HP bar over the body at 40 m, shot z40)_
2. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.83): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
3. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.0): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from tracker (IoU 0.6): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Frame cost** (PASS): Cut the per-frame script cost (0.0033 ms per instance): write pivots only when they change, skip work at the far tiers _(from B13 Frame cost)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 32 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: Chest 2, Head 2, Maul 2, (root) 1, ArmL 1, ArmR 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 93 | 12 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 93 | 2111 (body + face above its allowance: face 810 v, allowance 800, total 2911; biggest: Face 810, Merged 407, Merged 406, MaulMesh 251) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 6 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 21 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 43 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 32 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 326 of 3584 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 93 | 0.0033 ms process per instance (100 animated at 40 m: +0.33 ms process, render CPU +1.45 ms, GPU +0.09 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.017 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.71 m / body_height 1.7 (x1.01) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | INFO | x 0.46 / z 0.5 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 612 px (28 x 40 bbox; 55 m: 314 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 64.1, 0% of the body melts (within dE 15 of the ground); body L* 53.2 C 16.7 vs ground L* 61.9 C 48.3, hue gap n/a (body C* <= 25); top third (world height) dE 57.8, L* 61.8; per-pixel dE 69.0, outline 54.3 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 42.2, 5% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 34.7 (heath dE 35.7, old_wood dE 44.3, riverbank dE 48.7, snow dE 42.2, ash dE 34.7, sand dE 56.3, marsh dE 46.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 32% of body pixels change between kingdom colours (min pair 32%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 45.0 (fire 56.5, shadow 70.7, ice 63.7, nature 45.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 76 | worst pair fire / nature (deutan): dE 8.3 on the team-colour area (normal vision 69.0; 200 px); deutan: fire / nature dE 8.3; protan: fire / nature dE 19.6; worst vs ground: fire colour (deutan) dE 40.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | **WARN** 55 | bar hides 10% of the silhouette (gap -8 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.2 m, 1.17 m wide | Keep tall parts under body_height + 0.4 or narrower than 0.35 m, or raise body_height to the real head top |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +26 (point 1 dL +27, point 2 dL +26; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): MaulRunes, SlabRune; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 54.5, dL +6 (warm dE 63.9, ice dE 62.2, night dE 54.5, autumn dE 56.7); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.89 (min 0.83), area kept 98-105% (min 604 px), frame-to-frame IoU min 0.83; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 2/2/2/2/2/1/1/2 (median 2, range 1, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 90 | max IoU 0.6 (tracker 0.6, hoarlight_magebow 0.57, frostbow 0.57, frost_mortar_placeholder 0.53, rimeshield 0.5, gloomcap_elder 0.41) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.19 m from the body centre at t 0.08 s (1.19 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 36% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 41% of the silhouette at its peak (t 0.4 s; 0.12 s 26%, 0.25 s 29%, 0.4 s 41%, 0.6 s 33%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 67 | 88 shapes over 8 body parts (11.0 per part: LegL 3, LegR 3, Hips 11, Head 34, ArmL 3, Maul 10, ArmR 3, Chest 21); 33% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.832 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 116% of the 2500 verts budget used (2907) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 19 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.39 at the close-up (97637 px), 2.37 at 25 m; close-up outline complexity 4.17 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 54 | outline complexity 2.0 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 61.8, bottom third L* 37.9 (+23, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.3 at 25 m, 14.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 85 | on the autumn floor: dE 51.3, 0% melts; body L* 50.3 C 9.4 vs floor L* 50.9 C 42.4 (inside the floor band); ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.24 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 810 v / 1 s; Root/Hips/Merged 407 v / 6 s; Root/Chest/Merged 406 v / 6 s; Root/Chest/ArmR/Maul/MaulMesh 251 v / 5 s; Root/Chest/SlabRune 240 v / 1 s; Root/Chest/ArmL/Merged 156 v / 3 s; Root/Chest/ArmR/Merged 156 v / 3 s; Root/Hips/LegL/Merged 137 v / 2 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R7 HP bar over the body at 40 m: The HP bar hides 10% of the body: lower / narrow what sticks up, or fix body_height)
