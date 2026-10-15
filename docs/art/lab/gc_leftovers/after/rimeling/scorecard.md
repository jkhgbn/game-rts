# Art Lab scorecard: rimeling

Scene `res://art/units/ice/rimeling/rimeling.tscn` · kind **unit** / tier **soldier** · kingdom ice · ground meadow · 2026-10-15 15:18:42 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.8)

0 FAIL · 2 WARN · 29 PASS · 16 info · 0 skipped · 25 s

## Improve next
1. **Contrast on the home ground (snow)** (WARN): shader_parameter/base_color of `ice_fur_pale` #a3adbf -> #1b9aff (21% of the visible body): predicted dE R3 meadow 52.7 -> 58.3, R3t fire 45.9 -> 51.7, R3t shadow 71.1 -> 77.7, R3t ice 52.7 -> 58.3, R3t nature 35.0 -> 41.8, R4k snow 19.3 -> 24.0 (want >= 24); other grounds heath 31.7, old_wood 52.9, riverbank 53.7, ash 50.1, sand 45.3, marsh 59.9; `ice_fur_pale` is a shared palette material (other assets use it): do not edit it, **snap** these surfaces to `ice_frost_glass.tres` (#337ac7, dE 17.3 from the wanted colour; no palette entry is close: a new palette entry is needed, or give the asset its own copy); team-coloured (set_team_color overwrites their albedo, so editing the material does nothing): `ice_cloth` 30% - to move those, change the team-colour path instead (the colour the kit mixes into them: a darker / lighter team shade or the scene's default kingdom colour constant), or put a value-step trim around them [fixes.json #1] _(from R4k Contrast on the home ground (snow), shot z40)_
2. **Glow points at 40 m** (WARN): Glow points 0 -> 1 (want 1-3): add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= 1.3 x the bloom level 1.2 [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 11 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
4. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.14): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
5. **Contrast on the other grounds** (PASS): On snow the body drops to dE 19.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
6. **Distinct from references (black masks)** (PASS): Make it read apart from rimeling_placeholder (IoU 0.64): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_

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
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: Head 2, (root) 1, ArmL 1, ArmR 1, Chest 1, LegL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 100 | 1620 (body + face above its allowance: face 416 v, allowance 800, total 2036; biggest: Merged 646, Merged 466, Face 416, Merged 157) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 5 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 3 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 26 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 233 of 2646 triangles (8%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.001 ms process per instance (100 animated at 40 m: +0.1 ms process, render CPU +-0.14 ms, GPU +-0.73 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 1.2 m / body_height 1.2 (x1.0) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | PASS 100 | x 0.42 / z 0.6 m (radius 0.4, from rimeling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 308 px (24 x 28 bbox; 55 m: 160 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 52.7, 0% of the body melts (within dE 15 of the ground); body L* 72.7 C 5.0 vs ground L* 63.6 C 48.0, hue gap n/a (body C* <= 25); top third (world height) dE 53.0, L* 89.1; per-pixel dE 58.5, outline 44.8 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | **WARN** 52 | dE 19.3, 63% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) | A value step against the home ground: pale crests on dark ash / marsh, dark trims on snow |
| R4 | Contrast on the other grounds | PASS 87 | worst snow: dE 19.3 (heath dE 28.1, old_wood dE 50.6, riverbank dE 51.8, snow dE 19.3, ash dE 50.1, sand dE 38.3, marsh dE 59.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 35% of body pixels change between kingdom colours (min pair 34%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 35.0 (fire 45.9, shadow 71.1, ice 52.7, nature 35.0) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 82 | worst pair fire / nature (deutan): dE 14.1 on the team-colour area (normal vision 65.3; 112 px); deutan: fire / nature dE 14.1; protan: fire / nature dE 19.9; worst vs ground: fire colour (deutan) dE 28.0 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.7 m, 1.04 m wide |  |
| R5 | Glow points at 40 m | **WARN** 49 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it); 2 soft glow(s) sit under the bloom level: raise one to emission >= 2.4 |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 49.0, dL +10 (warm dE 53.1, ice dE 49.9, night dE 54.5, autumn dE 49.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.76 (min 0.72), area kept 90-96% (min 284 px), frame-to-frame IoU min 0.7; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.64 (rimeling_placeholder 0.64, magpie 0.55, hoarlight_magebow_placeholder 0.55, rime_hauler 0.49, bristleback 0.41, frost_mortar 0.2) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.96 m from the body centre at t 0.14 s (0.96 m forward; geometry clipped at the ground); declared 1.4 m (UnitType attack_range (rimeling.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 42% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 43% of the silhouette at its peak (t 0.4 s; 0.12 s 35%, 0.25 s 37%, 0.4 s 43%, 0.6 s 4%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 59 shapes over 6 body parts (9.8 per part: LegL 3, LegR 3, Head 28, ArmL 5, ArmR 5, Chest 15); 7% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.939 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 81% of the 2500 verts budget used (2032) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 60 | 9 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 85 | inner edges per outline px: 3.75 at the close-up (77644 px), 1.28 at 25 m; close-up outline complexity 3.4 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 65 | outline complexity 2.14 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 89.1, bottom third L* 44.6 (+44, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.6 at 25 m, 11.6 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 47.1, 0% melts; body L* 70.0 C 0.6 vs floor L* 52.8 C 43.3; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 646 v / 7 s; Root/Chest/Head/Merged 466 v / 3 s; Root/Chest/Head/Face 416 v / 1 s; Root/Chest/ArmL/Merged 157 v / 4 s; Root/Chest/ArmR/Merged 157 v / 4 s; Root/Hips/LegL/Merged 95 v / 3 s; Root/Hips/LegR/Merged 95 v / 3 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 5 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: shader_parameter/base_color of `ice_fur_pale` #a3adbf -> #1b9aff (21% of the visible body): predicted dE R3 meadow 52.7 -> 58.3, R3t fire 45.9 -> 51.7, R3t shad)
