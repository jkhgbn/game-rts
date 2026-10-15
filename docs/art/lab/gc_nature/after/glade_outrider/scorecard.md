# Art Lab scorecard: glade_outrider

Scene `res://art/units/nature/glade_outrider/glade_outrider.tscn` · kind **unit** / tier **heavy** · kingdom nature · ground meadow · 2026-10-15 13:01:41 · lab v3.1

## Result: **FAIL** · quality **89 / 100** (88.5)

1 FAIL · 4 WARN · 28 PASS · 16 info · 0 skipped · 31 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 20 -> 20 (want <= 16): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 2.38 m, Merged 0.66 m so the HP bar reads over the head [fixes.json #4] _(from R8w Parts above body_height + 0.4)_
3. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.7 -> 0.87, or pull the widest parts in to x <= 1.22 / z <= 1.22 m [fixes.json #2] _(from R10 Footprint vs selection radius)_
4. **Vertices** (WARN): B4 11397 -> 5730 (want <= 6000): `Merged` 2791 -> 1396 verts; `Merged` 2558 -> 1279 verts; `Merged` 1030 -> 515 verts; `Merged` 885 -> 443 verts; `Merged` 479 -> 240 verts; `Merged` 406 -> 203 verts; `Merged` 406 -> 203 verts; `Merged` 385 -> 193 verts; `Merged` 385 -> 193 verts; `Bow` 343 -> 172 verts; `Merged` 325 -> 163 verts; `Merged` 325 -> 163 verts; `Merged` 321 -> 161 verts; `Cloak` 275 -> 138 verts; `Merged` 244 -> 122 verts; `Arrow` 235 -> 142 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_
5. **Attack reads at 40 m** (WARN): A3 Attack reads at 40 m: Push the attack pose: the strike should change >= 30% of the 40 m silhouette (now 5%) [fixes.json #5] _(from A3 Attack reads at 40 m, shot anim)_
6. **Palette depth (close-up)** (INFO): Flat palette (10 colour / 12 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 43 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 20 drawn (20 mesh + 0 multimesh); per pivot: Head 3, ArmL 2, ArmR 2, Chest 2, Bow 1, Hips 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | **FAIL** 6 | 20 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | **WARN** 35 | 11397 (body + face above its allowance: face 892 v, allowance 800, total 12197; biggest: Merged 2791, Merged 2558, Merged 1030, Merged 885) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 4 (Merged, Merged, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 20 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 7 (model says 22) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 90 surfaces over 20 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1818 of 16218 triangles (11%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (100 animated at 40 m: +-0.05 ms process, render CPU +2.35 ms, GPU +10.53 ms) | <= 0.005 ms per instance (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.018 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 2.38 m, Merged 0.66 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 1.31 / z 1.52 m (radius 0.7, from glade_outrider.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1433 px (56 x 69 bbox; 55 m: 721 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 87 | mean-colour dE 25.5, 1% of the body melts (within dE 15 of the ground); body L* 68.1 C 27.8 vs ground L* 61.9 C 49.0, hue gap 19 deg; top third (world height) dE 34.8, L* 81.0; per-pixel dE 38.7, outline 38.9 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 41.2, 12% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 81 | worst heath: dE 15.0 (heath dE 15.0, old_wood dE 41.2, riverbank dE 38.6, snow dE 33.7, ash dE 53.0, sand dE 15.3, marsh dE 55.8) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 94 | 19% of body pixels change between kingdom colours (min pair 19%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 91 | worst nature colour: dE 24.1 (fire 34.8, shadow 43.1, ice 34.0, nature 24.1) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 76 | worst pair fire / nature (deutan): dE 12.8 on the team-colour area (normal vision 66.7; 289 px); deutan: fire / nature dE 12.8; protan: fire / nature dE 20.8; worst vs ground: fire colour (deutan) dE 11.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 96 | bar hides 3% of the silhouette (gap -15 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.9 m, 1.82 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +24 (point 1 dL +31, point 2 dL +24, point 3 dL +24, soft 1 dL +25 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): Merged x3, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 90 | worst autumn: dE 22.2, dL +9 (warm dE 25.4, ice dE 25.4, night dE 22.7, autumn dE 22.2); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 97 | walk frames vs rest: mean IoU 0.79 (min 0.72), area kept 95-102% (min 1358 px), frame-to-frame IoU min 0.75; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 3/3/4/3/3/3/3/3 (median 3, range 1, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 79 | max IoU 0.76 (stagrunner 0.76, thornback_charger 0.6, bramble_harrier_placeholder 0.57, hollow_stag 0.53, stormbottle_genie 0.32, mossback 0.29) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.54 m from the body centre at t 0.36 s (1.54 m forward; geometry clipped at the ground); declared 8.0 m (UnitType attack_range (glade_outrider.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | **WARN** 41 | strike pose changes 5% of the silhouette (t 0.36 s) | >= 12% (1 - IoU rest vs strike) | Bigger wind-up / strike: the weapon or head should leave the body outline |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 12% of the silhouette at its peak (t 0.4 s; 0.12 s 9%, 0.25 s 11%, 0.4 s 12%, 0.6 s 12%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.04 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 349 shapes over 14 body parts (24.9 per part: Neck 14, Head 142, LegFL 9, LegFR 9, LegBL 10, LegBR 10, Mount 54, LegL 8, LegR 8, Hips 29, ArmL 15, Bow 8, ArmR 7, Chest 26); 16% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.946 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 203% of the 6000 verts budget used (12193) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 70 | 10 colour steps (L*a*b* bins >= 2 % of the body), 12 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 2.71 at the close-up (51938 px), 2.08 at 25 m; close-up outline complexity 16.56 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.64 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 81.0, bottom third L* 34.0 (+46, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.6 at 25 m, 14.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 43 | on the autumn floor: dE 21.7, 5% melts; body L* 66.5 C 32.3 vs floor L* 50.3 C 41.9; nature team colour vs the floor swatches: min dE 55.3 (grass_dry) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.37 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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
- Per-mesh vertices (biggest first): Stag/Root/Mount/Head/Merged 2791 v / 9 s; Stag/Root/Mount/Merged 2558 v / 8 s; Rider/Root/Chest/Head/Merged 1030 v / 7 s; Rider/Root/Hips/Merged 885 v / 7 s; Rider/Root/Chest/Head/Face 480 v / 1 s; Rider/Root/Chest/Merged 479 v / 6 s; Rider/Root/Hips/LegL/Merged 406 v / 4 s; Rider/Root/Hips/LegR/Merged 406 v / 4 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 5 in fixes.json (top: B2 20 -> 20 (want <= 16): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one Mult)
