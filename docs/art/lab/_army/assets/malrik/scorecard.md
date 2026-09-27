# Art Lab scorecard: malrik

Scene `res://art/units/wizards/malrik.tscn` · kind **unit** / tier **wizard** · kingdom shadow · ground meadow · 2026-09-27 10:17:01 · lab v2.0

## Result: **WARN** · quality **92 / 100**

0 FAIL · 3 WARN · 27 PASS · 10 info · 0 skipped · 25 s

## Improve next
1. **Vertices** (WARN): B4 3632 -> 2968 (want <= 3000): `Merged` 997 -> 499 verts; `Merged` 805 -> 639 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 1.18 m so the HP bar reads over the head [fixes.json #2] _(from R8w Parts above body_height + 0.4)_
3. **Looping particle systems** (WARN): B6l Looping particle systems: Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) [fixes.json #3] _(from B6l Looping particle systems)_
4. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (13.1): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

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
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: Head 2, (root) 1, ArmL 1, ArmR 1, CapePivot 1, Chest 1 | <= 26 (art-units.md 8 (wizard)) |  |
| B2 | Draw instances at rest | PASS 98 | 12 | <= 16 (art-units.md 8 (wizard)) |  |
| B3 | keep_separate parts | PASS 100 | 3 | <= 6 soft (art-units.md 8 (wizard)) |  |
| B4 | Vertices | **WARN** 40 | 3632 (biggest: Merged 997, Merged 805, Merged 453, Merged 349) | <= 3000 soft (art-units.md 8 (wizard)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 94 | 1 (ShardLight) | <= 1 (art-units.md 8 (wizard)) |  |
| B6 | Particle systems | INFO | 4 | no budget for unit/wizard |  |
| B6l | Looping particle systems | **WARN** 41 | 2 (VoidMotes, ShadowMist) | <= 1 soft (art-units.md 8 (wizard)) | Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D) |
| B6p | Looping particles alive | PASS 88 | 8 | <= 8 soft (art-units.md 8 (wizard)) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, StaffMesh, Merged, Merged) | <= 4 soft (art-units.md 8 (wizard)) |  |
| B8 | Unique materials | INFO | 16 | no budget for unit/wizard |  |
| B1a | Authored build parts (before the merge) | INFO | 10 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 28 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 607 of 4538 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.042 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 78 | head top 2.74 m / body_height 2.0 (x1.37) | x0.75-1.45 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for wizard) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 1.18 m | narrower than 0.7 m (art-units 1.1: the HP bar stays readable; crest tolerance) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.75 / z 0.8 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1044 px (35 x 51 bbox; 55 m: 542 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 98.0, 0% of the body melts (within dE 15 of the ground); body L* 40.5 C 48.0 vs ground L* 61.9 C 48.7, hue gap 163 deg; top third (world height) dE 85.1, L* 58.2; per-pixel dE 103.0, outline 71.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 56.1, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 47.1 (heath dE 67.3, old_wood dE 69.7, riverbank dE 81.7, snow dE 70.1, ash dE 47.1, sand dE 83.4, marsh dE 56.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 64% of body pixels change between kingdom colours (min pair 62%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 97 | worst nature colour: dE 29.7 (fire 63.4, shadow 96.1, ice 63.4, nature 29.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 80 | worst pair fire / nature (deutan): dE 12.6 on the team-colour area (normal vision 73.1; 699 px); deutan: fire / nature dE 12.6; protan: fire / nature dE 20.1; worst vs ground: fire colour (deutan) dE 22.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 95 | bar hides 4% of the silhouette (gap -10 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 86 | worst dL +22 (point 1 dL +31, point 2 dL +22; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 2 point(s) above the bloom level 1.2 (median of 2/2/2): ShardMesh, Glints; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 88 | walk frames vs rest: mean IoU 0.63 (min 0.62), area kept 97-98% (min 1058 px), frame-to-frame IoU min 0.9; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 2) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 36% of the silhouette (t 0.14 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.03 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 96 | outline complexity 2.55 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 58.2, bottom third L* 23.6 (+34, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 48 | inner detail 13.1 at 25 m, 18.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (wizard))
`{"draw":16,"frame_ms":0.005,"lights":1,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"art-units.md 8 (wizard)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Head/Merged 997 v / 7 s; Root/Chest/Merged 805 v / 5 s; Root/Hips/Merged 453 v / 3 s; Root/Chest/ArmL/Merged 349 v / 2 s; Root/Chest/ArmR/Staff/StaffMesh 322 v / 2 s; Root/Chest/ArmR/Merged 286 v / 2 s; Root/Chest/ArmR/Staff/Shard/ShardMesh 215 v / 3 s; Root/Chest/Head/Glints 102 v / 2 s
- 4 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: B4 3632 -> 2968 (want <= 3000): `Merged` 997 -> 499 verts; `Merged` 805 -> 639 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces))
