# Art Lab scorecard: rimehorn_rider

Scene `res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn` · kind **unit** / tier **cavalry** · kingdom ice · ground meadow · 2026-10-15 15:15:21 · lab v3.1

## Result: **FAIL** · quality **89 / 100** (88.7)

2 FAIL · 4 WARN · 27 PASS · 16 info · 0 skipped · 30 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 17 -> 17 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Particle systems** (FAIL): B6 Particle systems: One system with emission points instead of several; pre-built one-shots [fixes.json #2] _(from B6 Particle systems)_
3. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.57 m, Axe 0.75 m so the HP bar reads over the head [fixes.json #5] _(from R8w Parts above body_height + 0.4)_
4. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.7 -> 1.37, or pull the widest parts in to x <= 1.22 / z <= 1.22 m [fixes.json #3] _(from R10 Footprint vs selection radius)_
5. **Vertices** (WARN): B4 9634 -> 4617 (want <= 2500): `Merged` 2523 -> 1262 verts; `Merged` 1439 -> 720 verts; `Merged` 1380 -> 690 verts; `Merged` 971 -> 486 verts; `Merged` 746 -> 373 verts; `Merged` 450 -> 225 verts; `Axe` 367 -> 184 verts; `Merged` 320 -> 160 verts; `Merged` 320 -> 160 verts; `Merged` 283 -> 142 verts; `Merged` 283 -> 142 verts; `Merged` 283 -> 142 verts; `Merged` 283 -> 142 verts; `Merged` 282 -> 141 verts; `Merged` 112 -> 56 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #4] _(from B4 Vertices)_
6. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 3.6): add a value step inside the team-colour area [fixes.json #6] _(from R6cb Team colours for colour-blind players, shot teams)_

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
| B1 | Meshes after the kit merge | PASS 93 | 17 drawn (17 mesh + 0 multimesh); per pivot: Head 3, ArmR 2, ArmL 1, Chest 1, Hips 1, LegBL 1 | <= 20 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B2 | Draw instances at rest | **FAIL** 0 | 17 | <= 12 (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B4 | Vertices | **WARN** 35 | 9634 (body + face above its allowance: face 876 v, allowance 1200, total 10510; biggest: Merged 2523, Merged 1439, Merged 1380, Merged 971) | <= 2500 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6 | Particle systems | **FAIL** 6 | 2 | <= 1 (cavalry-mounts.md 10 (cavalry rider, mount separate)) | One system with emission points instead of several; pre-built one-shots |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Merged, Merged, Merged) | <= 4 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B8 | Unique materials | INFO | 23 | no budget for unit/cavalry |  |
| B1a | Authored build parts (before the merge) | INFO | 19 (model says 21) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 20 |  |
| B11 | Surfaces per instance | INFO | 79 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1691 of 13242 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 90 | 0.0039 ms process per instance (100 animated at 40 m: +0.39 ms process, render CPU +2.22 ms, GPU +2.77 ms) | <= 0.005 ms per instance (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.005 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.57 m, Axe 0.75 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.98 / z 2.4 m (radius 0.7, from rimehorn_rider.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 2001 px (53 x 72 bbox; 55 m: 1031 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.6, 0% of the body melts (within dE 15 of the ground); body L* 63.8 C 6.9 vs ground L* 62.5 C 48.5, hue gap n/a (body C* <= 25); top third (world height) dE 53.8, L* 70.8; per-pixel dE 59.9, outline 46.6 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 96 | dE 28.5, 15% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 98 | worst snow: dE 28.5 (heath dE 34.2, old_wood dE 45.4, riverbank dE 46.1, snow dE 28.5, ash dE 41.5, sand dE 43.0, marsh dE 51.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 80 | 8% of body pixels change between kingdom colours (min pair 6%) | >= 8% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 51.7 (fire 53.2, shadow 55.1, ice 54.1, nature 51.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 36 | worst pair fire / nature (deutan): dE 3.6 on the team-colour area (normal vision 38.2; 177 px); deutan: fire / nature dE 3.6; protan: fire / nature dE 11.3; worst vs ground: fire colour (deutan) dE 45.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 6 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 93 | bar hides 5% of the silhouette (gap -12 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.6 m, 1.82 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +28 (point 1 dL +28; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/1/2): Merged, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst autumn: dE 49.8, dL +3 (warm dE 54.7, ice dE 53.1, night dE 52.3, autumn dE 49.8); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.86 (min 0.82), area kept 94-100% (min 1918 px), frame-to-frame IoU min 0.86; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 1/1/1/1/1/1/2/1 (median 1, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 85 | max IoU 0.68 (rime_harrier_placeholder 0.68, frostcrown_juggernaut 0.64, ruin_warden 0.46, rime_colossus 0.44, shardguard 0.37, stormbottle_genie 0.34) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 2.37 m from the body centre at t 0.08 s (2.37 m forward; geometry clipped at the ground); declared 1.8 m (UnitType attack_range (rimehorn_rider.tres)) - not a reach weapon (< 2.5 m): not judged | judged for reach weapons (declared reach >= 2.5 m, or reach= / attack_reach) |  |
| A3 | Attack reads at 40 m | PASS 88 | strike pose changes 17% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 15% of the silhouette at its peak (t 0.6 s; 0.12 s 12%, 0.25 s 13%, 0.4 s 14%, 0.6 s 15%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 255 shapes over 13 body parts (19.6 per part: Head 88, LegFL 9, LegFR 9, LegBL 9, LegBR 9, Tail 6, Mount 55, LegL 6, LegR 6, Hips 8, ArmL 16, ArmR 15, Chest 19); 12% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.953 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 420% of the 2500 verts budget used (10506) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 17 colour steps (L*a*b* bins >= 2 % of the body), 11 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 4.28 at the close-up (64694 px), 3.7 at 25 m; close-up outline complexity 5.13 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 68 | outline complexity 2.18 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 70.8, bottom third L* 43.4 (+27, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.1 at 25 m, 10.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 44.7, 0% melts; body L* 61.1 C 2.9 vs floor L* 51.0 C 42.3; ice team colour vs the floor swatches: min dE 60.7 (road_color) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (cavalry rider, mount separate))
`{"draw":12,"face_verts":1200,"frame_ms":0.005,"lights":0,"meshes":20,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":4,"separate":6,"verts":2500},"src":"cavalry-mounts.md 10 (cavalry rider, mount separate)","systems":1}`

## Notes
- Per-mesh vertices (biggest first): Rimehorn/Root/Mount/Merged 2523 v / 8 s; Rimehorn/Root/Mount/Head/Merged 1439 v / 9 s; Rider/Root/Chest/Merged 1380 v / 5 s; Rider/Root/Chest/Head/Merged 971 v / 6 s; Rider/Root/Chest/ArmL/Merged 746 v / 8 s; Rider/Root/Chest/Head/Face 464 v / 1 s; Rider/Root/Hips/Merged 450 v / 6 s; Rider/Root/Chest/ArmR/Axe 367 v / 6 s
- 2 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 6 in fixes.json (top: B2 17 -> 17 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one Mult)
