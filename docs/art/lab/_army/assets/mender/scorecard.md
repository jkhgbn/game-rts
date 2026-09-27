# Art Lab scorecard: mender

Scene `res://art/units/champions/mender/mender.tscn` · kind **unit** / tier **champion** · kingdom neutral · ground meadow · 2026-09-27 10:26:46 · lab v2.0

## Result: **FAIL** · quality **92 / 100**

1 FAIL · 1 WARN · 24 PASS · 11 info · 0 skipped · 21 s

## Improve next
1. **Unique materials** (FAIL): B8 8 -> 7 materials: use one material for look-alike pairs: `StandardMaterial3D#-30189` -> `StandardMaterial3D#-65657` (dE 124.0) [fixes.json #1] _(from B8 Unique materials)_
2. **Vertices** (WARN): B4 7814 -> 3911 (want <= 3000): `Merged` 2993 -> 1497 verts; `Merged` 884 -> 442 verts; `Merged` 707 -> 354 verts; `StaffMesh` 544 -> 272 verts; `Kettle` 510 -> 255 verts; `Core` 432 -> 216 verts; `Jars` 344 -> 172 verts; `Merged` 338 -> 169 verts; `Merged` 338 -> 169 verts; `Variant` 270 -> 135 verts; `Merged` 225 -> 113 verts; `Merged` 225 -> 113 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Contrast on the other grounds** (PASS): On sand the body drops to dE 16.4: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +8 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 36.1): value is close to the ground (dL +4): lighten the top / back 15-20 % or add a dark saddle / pale belly band _(from R3 Contrast vs ground (meadow), shot z40)_
6. **Detail density 25 m / 40 m** (INFO): Busy at 25 m (11.4): merge small value changes into bigger blocks so the 40 m read stays clean _(from P4 Detail density 25 m / 40 m, shot z25)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 28 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 13 drawn (13 mesh + 0 multimesh); per pivot: Censer 2, Chest 2, Head 2, (root) 1, ArmL 1, ArmR 1 | <= 26 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | PASS 92 | 14 | <= 16 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B4 | Vertices | **WARN** 35 | 7814 (biggest: Merged 2993, Merged 884, Merged 707, StaffMesh 544) | <= 3000 soft (champions.md 4 / 13, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/champion |  |
| B6l | Looping particle systems | PASS 94 | 1 (Steam) | <= 1 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 98 | 6 | <= 8 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 98 | 3 (Merged, Merged, Merged) | <= 4 soft (champions.md 4 / 13, tier3-extras.md 12) |  |
| B8 | Unique materials | **FAIL** 0 | 8 | <= 5 (champions.md 4 / 13, tier3-extras.md 12) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 25 (model says 25) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 16 surfaces over 13 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1657 of 11094 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.02 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | PASS 93 | head top 1.9 m / body_height 1.7 (x1.12) | x0.75-1.35 (art-units 1.1: the HP bar hangs at body_height + 0.5; identity crest allowed for champion) |  |
| R8w | Parts above body_height + 0.4 | INFO | identity crest: Merged 0.42 m | champion tier: a crest up to 0.6 m wide is part of the identity (the HP bar sits on it) |  |
| R10 | Footprint vs selection radius | INFO | x 0.9 / z 0.72 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 975 px (38 x 55 bbox; 55 m: 493 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 97 | mean-colour dE 36.1, 2% of the body melts (within dE 15 of the ground); body L* 66.8 C 28.1 vs ground L* 62.0 C 48.4, hue gap 47 deg; top third (world height) dE 42.9, L* 69.7; per-pixel dE 47.5, outline 45.4 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 83 | worst sand: dE 16.4 (heath dE 17.7, old_wood dE 43.3, riverbank dE 47.7, snow dE 34.5, ash dE 50.6, sand dE 16.4, marsh dE 53.2) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 92 | bar hides 6% of the silhouette (gap -19 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 2.2 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +29 (point 1 dL +29, point 2 dL +37; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 1 point(s) above the bloom level 1.2 (median of 2/1/1): Jars, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-4 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 94 | walk frames vs rest: mean IoU 0.75 (min 0.67), area kept 98-104% (min 935 px), frame-to-frame IoU min 0.63; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 2/2/2/2/2/2/2/2 (median 2, range 0, 0 frame(s) at 0; at rest 1) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 46% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.06 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 82 | top third L* 69.7, bottom third L* 60.8 (+8, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 91 | inner detail 11.4 at 25 m, 15.0 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 2 of 2 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, champions.md 4 / 13, tier3-extras.md 12)
`{"draw":16,"frame_ms":0.005,"lights":0,"materials":5,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":8,"separate":6,"verts":3000},"src":"champions.md 4 / 13, tier3-extras.md 12"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 2993 v / 4 s; Root/Chest/Head/Merged 884 v / 1 s; Root/Hips/Merged 707 v / 1 s; Root/Chest/ArmR/Staff/StaffMesh 544 v / 1 s; Root/Chest/ArmR/Staff/Censer/Kettle 510 v / 1 s; Root/Chest/ArmR/Staff/Censer/Core 432 v / 1 s; Root/Chest/Jars 344 v / 1 s; Root/Chest/ArmL/Merged 338 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 2 in fixes.json (top: B8 8 -> 7 materials: use one material for look-alike pairs: `StandardMaterial3D#-30189` -> `StandardMaterial3D#-65657` (dE 124.0))
