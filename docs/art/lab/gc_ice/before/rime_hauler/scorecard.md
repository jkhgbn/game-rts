# Art Lab scorecard: rime_hauler

Scene `res://art/units/ice/rime_hauler.tscn` · kind **unit** / tier **worker** · kingdom ice · ground meadow · 2026-10-15 12:16:17 · lab v3.1

## Result: **WARN** · quality **90 / 100** (90.3)

0 FAIL · 2 WARN · 28 PASS · 16 info · 0 skipped · 27 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 0 -> 1 (want 1-3): add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= 1.3 x the bloom level 1.2 [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **HP bar over the body at 40 m** (WARN): R7 HP bar over the body at 40 m: The HP bar hides 10% of the body: lower / narrow what sticks up, or fix body_height [fixes.json #2] _(from R7 HP bar over the body at 40 m, shot z40)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: 70% of the surface is plain boxes / low-sided prisms: taper, bevel or bend the big limbs and the torso (tapered paths, more sides, a lathe profile); few surface directions (normal variety 0.8): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Palette depth (close-up)** (INFO): Flat palette (8 colour / 9 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 1.82): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Contrast on the other grounds** (PASS): On snow the body drops to dE 25.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: Head 2, (root) 1, ArmL 1, ArmR 1, Chest 1, LegL 1 | <= 22 (art-units.md 8) |  |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 14 (art-units.md 8) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8) |  |
| B4 | Vertices | PASS 100 | 1705 (body + face above its allowance: face 726 v, allowance 800, total 2431; biggest: Face 726, Merged 422, Merged 366, Merged 302) | <= 2500 (art-units.md 8) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/worker |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 0 soft (art-units.md 8) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/worker |  |
| B1a | Authored build parts (before the merge) | INFO | 3 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 22 |  |
| B11 | Surfaces per instance | INFO | 24 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 308 of 3344 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0017 ms process per instance (100 animated at 40 m: +0.17 ms process, render CPU +1.11 ms, GPU +0.52 ms) | <= 0.005 ms per instance (art-units.md 8) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.019 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 97 | head top 1.46 m / body_height 1.4 (x1.04) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.53 / z 0.68 m (radius 0.4, from rime_hauler.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 660 px (24 x 42 bbox; 55 m: 342 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.2, 0% of the body melts (within dE 15 of the ground); body L* 68.0 C 8.4 vs ground L* 62.5 C 48.4, hue gap n/a (body C* <= 25); top third (world height) dE 57.4, L* 74.7; per-pixel dE 60.3, outline 45.1 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 92 | dE 25.3, 33% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 94 | worst snow: dE 25.3 (heath dE 30.4, old_wood dE 48.0, riverbank dE 48.4, snow dE 25.3, ash dE 46.0, sand dE 42.6, marsh dE 55.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 40% of body pixels change between kingdom colours (min pair 40%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 31.9 (fire 50.3, shadow 77.1, ice 54.0, nature 31.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 82 | worst pair fire / nature (deutan): dE 13.5 on the team-colour area (normal vision 81.8; 267 px); deutan: fire / nature dE 13.5; protan: fire / nature dE 23.4; worst vs ground: fire colour (deutan) dE 25.8 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | **WARN** 54 | bar hides 10% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.9 m, 1.04 m wide | Keep tall parts under body_height + 0.4 or narrower than 0.35 m, or raise body_height to the real head top |
| R5 | Glow points at 40 m | **WARN** 49 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it); 2 soft glow(s) sit under the bloom level: raise one to emission >= 2.4 |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 50.4, dL +7 (warm dE 54.5, ice dE 50.8, night dE 55.6, autumn dE 50.4); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.88 (min 0.85), area kept 97-100% (min 638 px), frame-to-frame IoU min 0.85; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 91 | max IoU 0.59 (tracker 0.59, shardcaster 0.58, hoarlight_magebow_placeholder 0.58, magpie 0.52, rimeling_placeholder 0.51, frost_mortar 0.35) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.99 m from the body centre at t 0.14 s (0.98 m forward; geometry clipped at the ground); declared 1.4 m (UnitType attack_range (rime_hauler.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 40% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 16% of the silhouette at its peak (t 0.4 s; 0.12 s 14%, 0.25 s 15%, 0.4 s 16%, 0.6 s 11%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 33 | 49 shapes over 6 body parts (8.2 per part: LegL 2, LegR 2, Head 27, ArmL 2, ArmR 5, Chest 11); 70% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.801 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 97% of the 2500 verts budget used (2427) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 50 | 8 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.7 at the close-up (97035 px), 1.42 at 25 m; close-up outline complexity 1.67 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 40 | outline complexity 1.82 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 74.7, bottom third L* 24.0 (+50, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.9 at 25 m, 8.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 48.5, 0% melts; body L* 65.9 C 3.8 vs floor L* 51.4 C 42.6; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.25 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":22,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":0,"separate":6},"src":"art-units.md 8","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Face 726 v / 1 s; Root/Chest/Merged 422 v / 8 s; Root/Chest/ArmR/Merged 366 v / 5 s; Root/Chest/Head/Merged 302 v / 3 s; Root/Chest/ArmL/Merged 239 v / 2 s; Root/Hips/LegL/Merged 186 v / 2 s; Root/Hips/LegR/Merged 186 v / 2 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: Glow points 0 -> 1 (want 1-3): add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= )
