# Art Lab scorecard: gloam_rider

Scene `res://art/units/shadow/gloam_rider/gloam_rider.tscn` · kind **unit** / tier **cavalry** · kingdom shadow · ground meadow · 2026-09-27 10:15:50 · lab v2.0

## Result: **FAIL** · quality **89 / 100**

1 FAIL · 5 WARN · 23 PASS · 9 info · 0 skipped · 24 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 19 -> 19 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Lance 0.59 m so the HP bar reads over the head [fixes.json #4] _(from R8w Parts above body_height + 0.4)_
3. **Vertices** (WARN): B4 10239 -> 5126 (want <= 2500): `Merged` 2229 -> 1115 verts; `Merged` 1747 -> 874 verts; `Merged` 985 -> 493 verts; `Lance` 867 -> 434 verts; `Merged` 745 -> 373 verts; `Merged` 402 -> 201 verts; `Merged` 402 -> 201 verts; `Merged` 386 -> 193 verts; `Merged` 386 -> 193 verts; `Merged` 339 -> 170 verts; `Merged` 339 -> 170 verts; `Merged` 307 -> 154 verts; `Merged` 289 -> 145 verts; `Merged` 278 -> 139 verts; `Pennon` 160 -> 80 verts; `ForearmR` 148 -> 74 verts; `Merged` 130 -> 65 verts; `Cloak` 96 -> 48 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
4. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 3 glow point(s) barely stand out from their 1 m surround (worst dL +4): darken around them or raise the energy [fixes.json #5] _(from R5c Glow points stand out (1 m surround), shot glow)_
5. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.8): add a value step inside the team-colour area [fixes.json #6] _(from R6cb Team colours for colour-blind players, shot teams)_
6. **Shadow casters** (WARN): B7 5 -> 4 casters: cast_shadow off on the 1 smallest: `Merged` [fixes.json #3] _(from B7 Shadow casters)_

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
| B1 | Meshes after the kit merge | PASS 88 | 19 drawn (19 mesh + 0 multimesh); per pivot: ArmR 2, Chest 2, Head 2, ArmL 1, ForearmR 1, Hips 1 | <= 20 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B2 | Draw instances at rest | **FAIL** 0 | 19 | <= 12 (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B4 | Vertices | **WARN** 35 | 10239 (biggest: Merged 2229, Merged 1747, Merged 985, Lance 867) | <= 2500 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6 | Particle systems | PASS 100 | 0 | <= 1 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 (cavalry-mounts.md 10 (cavalry rider, mount separate)) |  |
| B7 | Shadow casters | **WARN** 47 | 5 (Merged, Merged, Lance, Merged, Merged) | <= 4 soft (cavalry-mounts.md 10 (cavalry rider, mount separate)) | cast_shadow only on the 3-4 biggest parts (art-units 1.5 / 8) |
| B8 | Unique materials | INFO | 16 | no budget for unit/cavalry |  |
| B1a | Authored build parts (before the merge) | INFO | 12 (model says 21) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 20 |  |
| B11 | Surfaces per instance | INFO | 76 surfaces over 19 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1576 of 12134 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.009 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Lance 0.59 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 0.65 / z 2.14 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1179 px (59 x 56 bbox; 55 m: 598 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 96.3, 0% of the body melts (within dE 15 of the ground); body L* 28.9 C 42.0 vs ground L* 61.3 C 49.2, hue gap 167 deg; top third (world height) dE 108.6, L* 45.0; per-pixel dE 100.6, outline 74.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 47.3, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 38.8 (heath dE 67.3, old_wood dE 62.3, riverbank dE 75.3, snow dE 75.2, ash dE 38.8, sand dE 85.7, marsh dE 47.3) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 100 | 34% of body pixels change between kingdom colours (min pair 33%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 57.7 (fire 73.6, shadow 93.4, ice 74.0, nature 57.7) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 45 | worst pair fire / nature (deutan): dE 11.8 on the team-colour area (normal vision 70.2; 435 px); deutan: fire / nature dE 11.8; protan: fire / nature dE 21.6; worst vs ground: fire colour (deutan) dE 48.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 100 | bar hides 0% of the silhouette (gap 5 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.5 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 40 | worst dL +4 (point 1 dL +12, point 2 dL +4, point 3 dL +14; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/2/3): Merged x2, Pennon; soft glows under the bloom (v1 count, luma > 0.4): 3 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 87 | walk frames vs rest: mean IoU 0.61 (min 0.56), area kept 100-113% (min 1189 px), frame-to-frame IoU min 0.7; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 96 | points per frame 2/2/2/2/2/2/2/1 (median 2, range 1, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 43% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.05 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 5.37 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 45.0, bottom third L* 16.9 (+28, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 52 | inner detail 12.9 at 25 m, 15.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

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
- Per-mesh vertices (biggest first): Steed/Root/Mount/Merged 2229 v / 6 s; Steed/Root/Mount/Head/Merged 1747 v / 8 s; Rider/Root/Chest/Merged 985 v / 6 s; Rider/Root/Chest/ArmR/ForearmR/Lance 867 v / 5 s; Rider/Root/Chest/Head/Merged 745 v / 8 s; Steed/Root/Mount/LegBL/Merged 402 v / 4 s; Steed/Root/Mount/LegBR/Merged 402 v / 4 s; Rider/Root/Hips/LegL/Merged 386 v / 3 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 6 in fixes.json (top: B2 19 -> 19 (want <= 12): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one Mult)
