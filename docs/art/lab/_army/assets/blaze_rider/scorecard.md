# Art Lab scorecard: blaze_rider

Scene `res://art/units/fire/blaze_rider.tscn` · kind **unit** / tier **cavalry** · kingdom fire · ground meadow · 2026-09-27 09:45:53 · lab v2.0

## Result: **FAIL** · quality **90 / 100**

1 FAIL · 4 WARN · 25 PASS · 8 info · 0 skipped · 22 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 17 -> 17 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Lance 0.71 m, Pennon 0.37 m so the HP bar reads over the head [fixes.json #4] _(from R8w Parts above body_height + 0.4)_
3. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.6 -> 1.01, or pull the widest parts in to x <= 1.05 / z <= 1.05 m [fixes.json #2] _(from R10 Footprint vs selection radius)_
4. **Vertices** (WARN): B4 9548 -> 4798 (want <= 2500): `Merged` 2481 -> 1241 verts; `Merged` 1197 -> 599 verts; `Merged` 1084 -> 542 verts; `Merged` 945 -> 473 verts; `Merged` 815 -> 408 verts; `Merged` 389 -> 195 verts; `Merged` 389 -> 195 verts; `Lance` 381 -> 191 verts; `Merged` 377 -> 189 verts; `Merged` 297 -> 149 verts; `Merged` 297 -> 149 verts; `Merged` 283 -> 142 verts; `Merged` 220 -> 110 verts; `Merged` 220 -> 110 verts; `Merged` 137 -> 69 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #3] _(from B4 Vertices)_
5. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (3/4/2/2/3/4/2/2 per frame): put them on parts the gait does not cover [fixes.json #5] _(from R5w Glow points while walking (flicker), shot glow)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 41 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 93 | 17 drawn (17 mesh + 0 multimesh); per pivot: ArmR 2, Head 2, ArmL 1, Boar 1, Chest 1, Hips 1 | <= 20 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B2 | Draw instances at rest | **FAIL** 0 | 17 | <= 12 (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B4 | Vertices | **WARN** 35 | 9548 (biggest: Merged 2481, Merged 1197, Merged 1084, Merged 945) | <= 2500 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6 | Particle systems | PASS 94 | 1 | <= 1 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Merged, Merged, Merged) | <= 4 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B8 | Unique materials | INFO | 18 | no budget for unit/cavalry |  |
| B1a | Authored build parts (before the merge) | INFO | 18 (model says 22) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 20 |  |
| B11 | Surfaces per instance | INFO | 67 surfaces over 17 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1644 of 12124 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.003 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Lance 0.71 m, Pennon 0.37 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 0.68 / z 1.76 m (radius 0.6, from blaze_rider.tres) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1372 px (51 x 60 bbox; 55 m: 706 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 54.5, 0% of the body melts (within dE 15 of the ground); body L* 44.3 C 41.7 vs ground L* 62.5 C 48.4, hue gap 69 deg; top third (world height) dE 61.0, L* 57.9; per-pixel dE 66.7, outline 53.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (ash) | PASS 100 | dE 45.2, 5% melts (ash is where fire units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 32.3 (heath dE 32.3, old_wood dE 43.3, riverbank dE 55.3, snow dE 60.6, ash dE 45.2, sand dE 43.5, marsh dE 42.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 32% of body pixels change between kingdom colours (min pair 28%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 34.5 (fire 53.0, shadow 61.0, ice 45.2, nature 34.5) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 79 | worst pair fire / nature (deutan): dE 12.2 on the team-colour area (normal vision 56.4; 521 px); deutan: fire / nature dE 12.2; protan: fire / nature dE 17.8; worst vs ground: nature colour (deutan) dE 16.3 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 98 | bar hides 1% of the silhouette (gap -3 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.8 m, 1.56 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +22 (point 1 dL +34, point 2 dL +22; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): Merged, Pennon; soft glows under the bloom (v1 count, luma > 0.4): 4 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.76 (min 0.74), area kept 98-101% (min 1361 px), frame-to-frame IoU min 0.79; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 43 | points per frame 3/4/2/2/3/4/2/2 (median 3, range 2, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 40% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.0 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.74 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 57.9, bottom third L* 23.0 (+34, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 9.0 at 25 m, 12.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Boar/Root/Mount/Merged 2481 v / 8 s; Boar/Root/Mount/Head/Merged 1197 v / 7 s; Rider/Root/Chest/Merged 1084 v / 6 s; Rider/Root/Chest/Head/Merged 945 v / 6 s; Rider/Root/Chest/ArmL/Merged 815 v / 5 s; Rider/Root/Hips/LegL/Merged 389 v / 3 s; Rider/Root/Hips/LegR/Merged 389 v / 3 s; Rider/Root/Chest/ArmR/Lance 381 v / 4 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: B2 17 -> 17 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one Mult)
