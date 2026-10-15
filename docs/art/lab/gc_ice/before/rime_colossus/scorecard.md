# Art Lab scorecard: rime_colossus

Scene `res://art/units/ice/rime_colossus.tscn` · kind **unit** / tier **heavy** · kingdom ice · ground meadow · 2026-10-15 12:15:49 · lab v3.1

## Result: **WARN** · quality **91 / 100** (91.4)

0 FAIL · 2 WARN · 31 PASS · 17 info · 0 skipped · 28 s

## Improve next
1. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.8 -> 0.81, or pull the widest parts in to x <= 1.4 / z <= 1.4 m [fixes.json #1] _(from R10 Footprint vs selection radius)_
2. **Team-colour visibility at 40 m** (WARN): R6 Team-colour visibility at 40 m: Give the team colour more top-facing area (now 3% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top [fixes.json #2] _(from R6 Team-colour visibility at 40 m, shot teams)_
3. **Vertex use vs budget** (INFO): Only 36% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
4. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: only 5.6 shapes per body part (aim >= 7): add secondary / tertiary shapes (straps, plates, bark ridges, cuffs, knuckles, a collar) on Hips; few surface directions (normal variety 0.9): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
5. **Silhouette hook** (INFO): Give the 40 m silhouette a hook (now 2.18): a shape that breaks the outline, e.g. horns, a raised weapon, a crest, a tail flick, a gap between limbs (at 40 m 1 px = ~4 cm: hooks thinner than ~0.25 m barely register) _(from P1 Silhouette hook, shot silhouette)_
6. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +7 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 26 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (9 mesh + 1 multimesh); per pivot: Chest 3, (root) 1, ArmL 1, ArmR 1, Head 1, Hips 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 100 | 2311 (biggest: Merged 672, Merged 655, Merged 305, Merged 228) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 5 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 3 (Merged, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 17 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 4 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 24 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 385 of 2736 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.1 ms process, render CPU +1.12 ms, GPU +0.51 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.017 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 100 | head top 2.37 m / body_height 2.6 (x0.91) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 1.42 / z 1.15 m (radius 0.8, from rime_colossus.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 2544 px (59 x 73 bbox; 55 m: 1299 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 64.9, 0% of the body melts (within dE 15 of the ground); body L* 60.4 C 20.4 vs ground L* 61.3 C 49.4, hue gap n/a (body C* <= 25); top third (world height) dE 65.2, L* 63.3; per-pixel dE 67.4, outline 51.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 100 | dE 38.1, 3% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst snow: dE 38.1 (heath dE 47.6, old_wood dE 50.4, riverbank dE 49.8, snow dE 38.1, ash dE 43.7, sand dE 56.3, marsh dE 54.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | **WARN** 40 | 3% of body pixels change between kingdom colours (min pair 3%) | >= 8% (FAIL = set_team_color changes nothing) | Put the team colour on a big, top-facing mass (cloth, plates, cape, caparison); ~25-45 %% of the surface (art-keep 0.2 / art-units 1.3) |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 61.6 (fire 62.6, shadow 65.4, ice 63.7, nature 61.6) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 11.5 on the team-colour area (normal vision 88.4; 101 px); deutan: fire / nature dE 11.5; protan: fire / nature dE 25.5; worst vs ground: fire colour (deutan) dE 58.1 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 6% of the silhouette (gap -18 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 2.08 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 95 | worst dL +33 (point 1 dL +33, point 2 dL +36; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 2/1/1): Core; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 59.3, dL +0 (warm dE 64.7, ice dE 61.9, night dE 60.1, autumn dE 59.3); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 97 | walk frames vs rest: mean IoU 0.79 (min 0.73), area kept 92-100% (min 2304 px), frame-to-frame IoU min 0.78; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 1/1/1/1/1/1/1/1 (median 1, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.45 (frostcrown_juggernaut 0.45, frostcrown_juggernaut_placeholder 0.42, stormbottle_genie 0.4, shardguard 0.37, rime_harrier 0.33, hollow_stag 0.31) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.23 m from the body centre at t 0.08 s (2.11 m forward; geometry clipped at the ground); declared 1.9 m (UnitType attack_range (rime_colossus.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 47% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 39% of the silhouette at its peak (t 0.4 s; 0.12 s 38%, 0.25 s 39%, 0.4 s 39%, 0.6 s 22%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 78 | 39 shapes over 7 body parts (5.6 per part: LegL 3, LegR 3, Hips 2, Head 5, ArmL 3, ArmR 11, Chest 12); 31% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.896 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 18 | 36% of the 6000 verts budget used (2187) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 16 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.82 at the close-up (94253 px), 2.69 at 25 m; close-up outline complexity 2.81 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 68 | outline complexity 2.18 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 73 | top third L* 63.3, bottom third L* 55.9 (+7, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 5.0 at 25 m, 6.9 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 56.8, 0% melts; body L* 57.2 C 14.7 vs floor L* 49.6 C 41.6; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.33 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"face_verts":800,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 672 v / 5 s; Root/Chest/ArmR/Merged 655 v / 3 s; Root/Chest/ArmL/Merged 305 v / 3 s; Root/Chest/Head/Merged 228 v / 4 s; Root/Chest/Cracks 120 v / 1 s x5; Root/Hips/LegL/Merged 101 v / 2 s; Root/Hips/LegR/Merged 101 v / 2 s; Root/Chest/Core 77 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 6 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: R10: raise UnitType.radius 0.8 -> 0.81, or pull the widest parts in to x <= 1.4 / z <= 1.4 m)
