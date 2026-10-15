# Art Lab scorecard: duskbolt_harrier

Scene `res://art/units/shadow/duskbolt_harrier/duskbolt_harrier.tscn` · kind **unit** / tier **soldier** · kingdom shadow · ground meadow · 2026-10-15 14:16:13 · lab v3.1

## Result: **FAIL** · quality **89 / 100** (89.3)

2 FAIL · 2 WARN · 28 PASS · 16 info · 0 skipped · 28 s

## Improve next
1. **Vertices** (FAIL): B4 7792 -> 3714 (want <= 2500): `Merged` 3094 -> 1547 verts; `Merged` 1975 -> 988 verts; `Merged` 496 -> 248 verts; `Merged` 360 -> 180 verts; `Merged` 329 -> 165 verts; `Merged` 329 -> 165 verts; `Merged` 307 -> 154 verts; `Merged` 271 -> 136 verts; `Crossbow` 258 -> 129 verts; `Merged` 253 -> 127 verts; `Merged` 253 -> 127 verts; `Merged` 130 -> 65 verts; `Merged` 109 -> 55 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Draw instances at rest** (FAIL): B2 15 -> 15 (want <= 14): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #2] _(from B2 Draw instances at rest)_
3. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.6 -> 0.76, or pull the widest parts in to x <= 1.05 / z <= 1.05 m [fixes.json #3] _(from R10 Footprint vs selection radius)_
4. **Shadow casters** (WARN): B7 5 -> 4 casters: cast_shadow off on the 1 smallest: `Merged` [fixes.json #4] _(from B7 Shadow casters)_
5. **Palette depth (close-up)** (INFO): Flat palette (9 colour / 7 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
6. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (12.9): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 36 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 15 drawn (15 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, ArmL 1, Chest 1, Hips 1, LegBL 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | **FAIL** 15 | 15 | <= 14 (art-units.md 8, tier3-extras.md 12) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 7792 (body + face above its allowance: face 840 v, allowance 800, total 8592; biggest: Merged 3094, Merged 1975, Merged 496, Face 424) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | **WARN** 47 | 5 (Merged, Merged, Crossbow, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) | cast_shadow only on the 3-4 biggest parts (art-units 1.5 / 8) |
| B8 | Unique materials | INFO | 14 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 4 (model says 17) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 59 surfaces over 15 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 959 of 10516 triangles (9%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 98 | 0.0024 ms process per instance (100 animated at 40 m: +0.24 ms process, render CPU +1.5 ms, GPU +6.54 ms) | <= 0.005 ms per instance (art-units.md 8, tier3-extras.md 12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.62 / z 1.33 m (radius 0.6, from duskbolt_harrier.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 695 px (36 x 49 bbox; 55 m: 349 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 98.8, 0% of the body melts (within dE 15 of the ground); body L* 27.5 C 44.3 vs ground L* 62.2 C 48.9, hue gap 165 deg; top third (world height) dE 103.2, L* 37.7; per-pixel dE 102.3, outline 75.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 49.1, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 40.9 (heath dE 64.9, old_wood dE 64.2, riverbank dE 77.9, snow dE 77.6, ash dE 40.9, sand dE 88.0, marsh dE 49.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 37% of body pixels change between kingdom colours (min pair 36%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 61.1 (fire 77.0, shadow 96.4, ice 77.0, nature 61.1) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 77 | worst pair fire / nature (deutan): dE 9.5 on the team-colour area (normal vision 68.4; 263 px); deutan: fire / nature dE 9.5; protan: fire / nature dE 20.9; worst vs ground: fire colour (deutan) dE 52.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 96 | bar hides 3% of the silhouette (gap -5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.56 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 90 | worst dL +26 (point 1 dL +26; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/0/1): Crossbow; soft glows under the bloom (v1 count, luma > 0.4): 1 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst night: dE 69.2, dL -8 (warm dE 98.9, ice dE 89.2, night dE 69.2, autumn dE 90.6); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.77 (min 0.71), area kept 93-100% (min 657 px), frame-to-frame IoU min 0.73; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 75 | points per frame 1/1/1/0/0/1/0/1 (median 1, range 1, 3 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 87 | max IoU 0.64 (barrow_knight 0.64, hollow_oathsworn 0.47, gloom_deacon 0.45, stormbottle_genie 0.36, gloom_thrall 0.33, ruin_warden 0.32) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 1.32 m from the body centre at t 0.08 s (1.32 m forward; geometry clipped at the ground); declared 6.5 m (UnitType attack_range (duskbolt_harrier.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 88 | strike pose changes 17% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 13% of the silhouette at its peak (t 0.4 s; 0.12 s 10%, 0.25 s 11%, 0.4 s 13%, 0.6 s 11%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 91 | 240 shapes over 11 body parts (21.8 per part: Head 87, LegFL 6, LegFR 6, LegBL 8, LegBR 8, Tail 11, Mount 74, Hips 13, ArmL 3, ArmR 13, Chest 11); 27% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.898 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 343% of the 2500 verts budget used (8588) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 35 | 9 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.33 at the close-up (52261 px), 2.06 at 25 m; close-up outline complexity 11.28 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.44 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 37.7, bottom third L* 14.2 (+23, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 52 | inner detail 12.9 at 25 m, 15.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 74.4, 0% melts; body L* 26.3 C 40.3 vs floor L* 50.9 C 42.4; shadow team colour vs the floor swatches: min dE 62.8 (heather_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"face_verts":800,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Steed/Root/Mount/Merged 3094 v / 7 s; Steed/Root/Mount/Head/Merged 1975 v / 9 s; Rider/Root/Hips/Merged 496 v / 6 s; Rider/Root/Chest/Head/Face 424 v / 1 s; Rider/Root/Chest/Merged 360 v / 4 s; Steed/Root/Mount/LegBL/Merged 329 v / 4 s; Steed/Root/Mount/LegBR/Merged 329 v / 4 s; Steed/Root/Mount/Tail/Merged 307 v / 3 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 4 in fixes.json (top: B4 7792 -> 3714 (want <= 2500): `Merged` 3094 -> 1547 verts; `Merged` 1975 -> 988 verts; `Merged` 496 -> 248 verts; `Merged` 360 -> 180 verts; `Merged` 329 -> 1)
