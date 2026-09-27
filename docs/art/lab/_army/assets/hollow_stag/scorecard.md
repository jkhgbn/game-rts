# Art Lab scorecard: hollow_stag

Scene `res://art/units/neutral/hollow_stag/hollow_stag.tscn` · kind **unit** / tier **creature** · kingdom neutral · ground meadow · 2026-09-27 10:25:07 · lab v2.0

## Result: **FAIL** · quality **84 / 100**

1 FAIL · 4 WARN · 20 PASS · 11 info · 0 skipped · 19 s

## Improve next
1. **Draw instances at rest** (FAIL): B2 13 -> 13 (want <= 10): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #1] _(from B2 Draw instances at rest)_
2. **Glow points at 40 m** (WARN): Glow points 4 -> 2 (want 1-3): hollow_stag_shade crack_strength 1.0 -> 0.19 (dim under the bloom level: 2 point(s), peak 3.92 x the level) [fixes.json #2] _(from R5 Glow points at 40 m, shot glow)_
3. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Skull 3.02 m so the HP bar reads over the head [fixes.json #5] _(from R8w Parts above body_height + 0.4)_
4. **Footprint vs selection radius** (WARN): R10: raise UnitType.radius 0.9 -> 0.96, or pull the widest parts in to x <= 1.58 / z <= 2.7 m [fixes.json #3] _(from R10 Footprint vs selection radius)_
5. **Vertices** (WARN): B4 4185 -> 2415 (want <= 2500): `Merged` 1520 -> 760 verts; `Skull` 1371 -> 686 verts; `Merged` 262 -> 131 verts; `Shin` 150 -> 75 verts; `Shin` 150 -> 75 verts; `Shin` 150 -> 106 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #4] _(from B4 Vertices)_
6. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +0 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_

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
| B1 | Meshes after the kit merge | PASS 100 | 12 drawn (12 mesh + 0 multimesh); per pivot: Lower 4, (root) 1, Crown 1, Head 1, LegBL 1, LegBR 1 | <= 18 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B2 | Draw instances at rest | **FAIL** 5 | 13 | <= 10 (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 95 | 5 | <= 6 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B4 | Vertices | **WARN** 35 | 4185 (biggest: Merged 1520, Skull 1371, Merged 262, Shin 150) | <= 2500 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/creature |  |
| B6l | Looping particle systems | PASS 94 | 1 (Leaves) | <= 1 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B6p | Looping particles alive | INFO | 8 | no budget for unit/creature |  |
| B7 | Shadow casters | PASS 98 | 3 (Skull, Merged, Merged) | <= 4 soft (map-fill.md 10 (camp creature = soldier: 18 / 10)) |  |
| B8 | Unique materials | INFO | 9 | no budget for unit/creature |  |
| B1a | Authored build parts (before the merge) | INFO | 12 (model says 12) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 18 |  |
| B11 | Surfaces per instance | INFO | 35 surfaces over 12 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 517 of 3950 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Skull 3.02 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | **WARN** 52 | x 1.69 / z 1.99 m (radius 0.9, from hollow_stag.tres) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) | Pull wide parts in, or raise UnitType.radius |
| R1 | Silhouette area at 40 m | PASS 100 | 1296 px (74 x 65 bbox; 55 m: 667 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 98 | mean-colour dE 38.3, 3% of the body melts (within dE 15 of the ground); body L* 66.8 C 12.4 vs ground L* 61.9 C 49.4, hue gap n/a (body C* <= 25); top third (world height) dE 35.0, L* 53.6; per-pixel dE 49.5, outline 44.5 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 85 | worst heath: dE 18.0 (heath dE 18.0, old_wood dE 39.7, riverbank dE 38.4, snow dE 25.7, ash dE 45.2, sand dE 25.1, marsh dE 51.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 0% of the silhouette (gap -4 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 2.34 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 88 | worst dL +28 (point 1 dL +28, point 2 dL +28, point 3 dL +31, point 4 dL +28; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 4 point(s) above the bloom level 1.2 (median of 4/4/4): Skull, Shin x2, Merged, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 4 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Skull, Shin x2, Merged |
| R11 | Reads while walking (40 m) | PASS 89 | walk frames vs rest: mean IoU 0.64 (min 0.59), area kept 97-101% (min 1298 px), frame-to-frame IoU min 0.61; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 89 | points per frame 5/5/4/4/5/4/4/4 (median 4, range 1, 0 frame(s) at 0; at rest 4) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 55% of the silhouette (t 0.08 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.02 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 7.56 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 25 | top third L* 53.6, bottom third L* 54.3 (+0, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 56 | inner detail 12.7 at 25 m, 17.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 4 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 10 (camp creature = soldier: 18 / 10))
`{"draw":10,"frame_ms":0.005,"lights":0,"meshes":18,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"separate":6,"verts":2500},"src":"map-fill.md 10 (camp creature = soldier: 18 / 10)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Mount/Merged 1520 v / 6 s; Root/Mount/Head/Crown/Skull 1371 v / 5 s; Root/Mount/Head/Merged 262 v / 3 s; Root/Mount/LegFL/Lower/Shin 150 v / 3 s; Root/Mount/LegFR/Lower/Shin 150 v / 3 s; Root/Mount/LegBL/Lower/Shin 150 v / 3 s; Root/Mount/LegBR/Lower/Shin 150 v / 3 s; Root/Mount/LegFL/Merged 114 v / 2 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: B2 13 -> 13 (want <= 10): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one Mult)
