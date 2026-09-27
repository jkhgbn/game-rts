# Art Lab scorecard: rimehorn_rider

Scene `res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn` · kind **unit** / tier **cavalry** · kingdom ice · ground meadow · 2026-09-27 10:00:56 · lab v2.0

## Result: **FAIL** · quality **92 / 100**

1 FAIL · 2 WARN · 25 PASS · 9 info · 0 skipped · 22 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 16 -> 16 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Vertices** (WARN): B4 9180 -> 4597 (want <= 2500): `Merged` 2523 -> 1262 verts; `Merged` 1215 -> 608 verts; `Merged` 941 -> 471 verts; `Merged` 804 -> 402 verts; `Merged` 713 -> 357 verts; `Merged` 404 -> 202 verts; `Merged` 404 -> 202 verts; `Axe` 367 -> 184 verts; `Merged` 296 -> 148 verts; `Merged` 283 -> 142 verts; `Merged` 283 -> 142 verts; `Merged` 283 -> 142 verts; `Merged` 283 -> 142 verts; `Merged` 265 -> 133 verts; `Merged` 112 -> 56 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 4.7): add a value step inside the team-colour area [fixes.json #3] _(from R6cb Team colours for colour-blind players, shot teams)_
4. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 7% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_
5. **Attack reads at 40 m** (PASS): Push the attack pose: the strike should change >= 30% of the 40 m silhouette (now 17%) _(from A3 Attack reads at 40 m, shot anim)_
6. **Contrast on the other grounds** (PASS): On snow the body drops to dE 27.1: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 40 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 95 | 16 drawn (16 mesh + 0 multimesh); per pivot: ArmR 2, Head 2, ArmL 1, Chest 1, Hips 1, LegBL 1 | <= 20 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B2 | Draw instances at rest | **FAIL** 2 | 16 | <= 12 (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 100 | 1 | <= 6 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B4 | Vertices | **WARN** 35 | 9180 (biggest: Merged 2523, Merged 1215, Merged 941, Merged 804) | <= 2500 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6 | Particle systems | PASS 94 | 1 | <= 1 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Merged, Merged, Merged) | <= 4 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B8 | Unique materials | INFO | 22 | no budget for unit/cavalry |  |
| B1a | Authored build parts (before the merge) | INFO | 10 (model says 21) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 20 |  |
| B11 | Surfaces per instance | INFO | 78 surfaces over 16 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1600 of 10790 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.005 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R10 | Footprint vs selection radius | INFO | x 0.98 / z 2.4 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 2028 px (53 x 74 bbox; 55 m: 1041 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 53.5, 0% of the body melts (within dE 15 of the ground); body L* 64.8 C 5.4 vs ground L* 62.5 C 48.4, hue gap n/a (body C* <= 25); top third (world height) dE 52.5, L* 73.0; per-pixel dE 59.1, outline 48.0 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (snow) | PASS 94 | dE 27.1, 22% melts (snow is where ice units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 96 | worst snow: dE 27.1 (heath dE 33.2, old_wood dE 45.4, riverbank dE 46.2, snow dE 27.1, ash dE 42.1, sand dE 41.2, marsh dE 51.4) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 79 | 7% of body pixels change between kingdom colours (min pair 6%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 50.9 (fire 52.4, shadow 54.1, ice 53.0, nature 50.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 36 | worst pair fire / nature (deutan): dE 4.7 on the team-colour area (normal vision 37.9; 177 px); deutan: fire / nature dE 4.7; protan: fire / nature dE 11.7; worst vs ground: fire colour (deutan) dE 43.9 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap -3 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.2 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +30 (point 1 dL +30; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 1/2/1): Merged, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 100 | walk frames vs rest: mean IoU 0.84 (min 0.81), area kept 94-100% (min 1931 px), frame-to-frame IoU min 0.85; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 2/2/1/2/1/2/2/1 (median 2, range 1, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 88 | strike pose changes 17% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 70 | outline complexity 2.2 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 73.0, bottom third L* 45.5 (+27, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 8.1 at 25 m, 11.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, cavalry-mounts.md 10 (cavalry rider, mount separate))
`{"draw":12,"frame_ms":0.005,"lights":0,"meshes":20,"n":100,"particles":10,"runtime_mats":0,"soft":{"casters":4,"separate":6,"verts":2500},"src":"cavalry-mounts.md 10 (cavalry rider, mount separate)","systems":1}`

## Notes
- Per-mesh vertices (biggest first): Rimehorn/Root/Mount/Merged 2523 v / 8 s; Rimehorn/Root/Mount/Head/Merged 1215 v / 8 s; Rider/Root/Chest/Head/Merged 941 v / 7 s; Rider/Root/Chest/Merged 804 v / 5 s; Rider/Root/Chest/ArmL/Merged 713 v / 8 s; Rider/Root/Hips/LegL/Merged 404 v / 5 s; Rider/Root/Hips/LegR/Merged 404 v / 5 s; Rider/Root/Chest/ArmR/Axe 367 v / 6 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: B2 16 -> 16 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one Mult)
