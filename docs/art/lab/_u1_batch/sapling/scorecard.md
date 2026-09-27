# Art Lab scorecard: sapling

Scene `res://art/units/nature/sapling.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-27 14:11:49 · lab v3.1

## Result: **WARN** · quality **93 / 100** (92.7) (previous run 94, -1)

0 FAIL · 1 WARN · 31 PASS · 16 info · 0 skipped · 29 s

## Improve next
1. **Head height vs body_height** (WARN): R8: body_height 1.2 -> 1.58 in res://art/units/nature/sapling.tscn (root) and res://data/units/sapling.tres (the head top; x1.32 now), or lower the head / crest 0.08 m [fixes.json #1] _(from R8 Head height vs body_height)_
2. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 10 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
3. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 20.9): value is close to the ground (dL -6): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 7 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_
4. **Distinct from references (black masks)** (PASS): Make it read apart from magpie (IoU 0.65): change one big shape of the silhouette _(from R2 Distinct from references (black masks), shot silhouette)_
5. **Contrast in every team colour (meadow)** (PASS): In the nature team colour the body drops to dE 21.2 on meadow: add a value step around the team-colour area _(from R3t Contrast in every team colour (meadow), shot teams)_
6. **Contrast under every light preset (meadow)** (PASS): Under the night light the body drops to dE 10.8: add a value step (light top / pale crest) that survives a dim light _(from R12 Contrast under every light preset (meadow), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 7 drawn (7 mesh + 0 multimesh); per pivot: (root) 1, ArmL 1, ArmR 1, Canopy 1, Chest 1, LegL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 100 | 7 | <= 14 (art-units.md 8, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | PASS 88 | 2343 (biggest: CanopyMesh 992, Merged 474, Merged 314, Merged 263) | <= 2500 (art-units.md 8, tier3-extras.md 12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 3 | no budget for unit/soldier |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 100 | 2 (Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 12 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 2 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 7 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 742 of 3390 triangles (21%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 98 | 0.0023 ms process per instance (100 animated at 40 m: +0.23 ms process, render CPU +1.04 ms, GPU +0.1 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.039 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 47 | head top 1.58 m / body_height 1.2 (x1.32) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R10 | Footprint vs selection radius | PASS 100 | x 0.57 / z 0.47 m (radius 0.4, from sapling.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 433 px (25 x 32 bbox; 55 m: 221 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 83 | mean-colour dE 20.9, 1% of the body melts (within dE 15 of the ground); body L* 56.8 C 29.2 vs ground L* 63.5 C 48.3, hue gap 7 deg; top third (world height) dE 22.4, L* 80.4; per-pixel dE 43.5, outline 37.0 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 97 | dE 29.4, 6% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 93 | worst riverbank: dE 24.3 (heath dE 27.2, old_wood dE 29.4, riverbank dE 24.3, snow dE 43.5, ash dE 46.4, sand dE 31.2, marsh dE 48.9) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 46% of body pixels change between kingdom colours (min pair 45%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 88 | worst nature colour: dE 21.2 (fire 47.3, shadow 70.2, ice 45.7, nature 21.2) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 83 | worst pair fire / nature (deutan): dE 14.6 on the team-colour area (normal vision 78.7; 204 px); deutan: fire / nature dE 14.6; protan: fire / nature dE 26.3; worst vs ground: fire colour (deutan) dE 19.7 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -2 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 1.7 m, 1.04 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +19 (soft 1 dL +19 (counts), soft 2 dL +25 (counts), soft 3 dL +23 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 0 point(s) above the bloom level 1.2 (median of 0/0/0), 2 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 3; + 3 Nature soft glow(s) that stand out from their 1 m surround count as points (R5c) | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 76 | worst night: dE 10.8, dL +6 (warm dE 21.2, ice dE 18.0, night dE 10.8, autumn dE 19.5); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.75 (min 0.66), area kept 95-99% (min 413 px), frame-to-frame IoU min 0.69; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.65 (magpie 0.65, sprigling 0.58, thornling 0.56, burr_slinger 0.53, tracker 0.51, vinelasher 0.45) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 0.79 m from the body centre at t 0.14 s (0.68 m forward; geometry clipped at the ground); declared 1.5 m (UnitType attack_range (sapling.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 41% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 33% of the silhouette at its peak (t 0.4 s; 0.12 s 27%, 0.25 s 32%, 0.4 s 33%, 0.6 s 25%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 93 | 37 shapes over 6 body parts (6.2 per part: LegL 2, LegR 2, Canopy 21, ArmL 4, ArmR 3, Chest 5); 17% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.948 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 93% of the 2500 verts budget used (2339) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 60 | 9 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.25 at the close-up (73355 px), 1.52 at 25 m; close-up outline complexity 7.41 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 81 | outline complexity 2.35 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 80.4, bottom third L* 19.1 (+61, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.5 at 25 m, 15.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 54 | on the autumn floor: dE 28.2, 0% melts; body L* 53.7 C 29.6 vs floor L* 52.7 C 43.4 (inside the floor band); nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.28 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Canopy/CanopyMesh 992 v / 6 s; Root/Chest/ArmL/Merged 474 v / 3 s; Root/Chest/ArmR/Merged 314 v / 2 s; Root/Chest/Merged 263 v / 2 s; Root/Hips/LegL/Merged 148 v / 1 s; Root/Hips/LegR/Merged 148 v / 1 s; Shadow 4 v / 1 s
- 3 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: R8: body_height 1.2 -> 1.58 in res://art/units/nature/sapling.tscn (root) and res://data/units/sapling.tres (the head top; x1.32 now), or lower the head / crest)
