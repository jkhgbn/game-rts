# Art Lab scorecard: glade_outrider

Scene `res://art/units/nature/glade_outrider/glade_outrider.tscn` · kind **unit** / tier **soldier** · kingdom nature · ground meadow · 2026-09-27 10:04:33 · lab v2.0

## Result: **FAIL** · quality **87 / 100**

2 FAIL · 3 WARN · 24 PASS · 9 info · 0 skipped · 22 s

## Improve next
1. **Vertices** (FAIL): B4 11511 -> 5764 (want <= 2500): `Merged` 2684 -> 1342 verts; `Merged` 2521 -> 1261 verts; `Merged` 1124 -> 562 verts; `Merged` 885 -> 443 verts; `Merged` 479 -> 240 verts; `Merged` 406 -> 203 verts; `Merged` 406 -> 203 verts; `Merged` 343 -> 172 verts; `Merged` 343 -> 172 verts; `Bow` 343 -> 172 verts; `Merged` 321 -> 161 verts; `Merged` 289 -> 145 verts; `Merged` 289 -> 145 verts; `Cloak` 275 -> 138 verts; `Merged` 244 -> 122 verts; `Arrow` 235 -> 118 verts; `ForearmR` 179 -> 90 verts; `Merged` 141 -> 71 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #1] _(from B4 Vertices)_
2. **Draw instances at rest** (FAIL): B2 19 -> 19 (want <= 14): no merge group found (every mesh has its own pivot and material): Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part [fixes.json #2] _(from B2 Draw instances at rest)_
3. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Merged 0.65 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
4. **Attack reads at 40 m** (WARN): A3 Attack reads at 40 m: Push the attack pose: the strike should change >= 30% of the 40 m silhouette (now 4%) [fixes.json #4] _(from A3 Attack reads at 40 m, shot anim)_
5. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 11.3): add a value step inside the team-colour area [fixes.json #5] _(from R6cb Team colours for colour-blind players, shot teams)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 21.1): value is close to the ground (dL -1): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the body sits in the ground's hue (gap 8 deg): push the main mass away from the grass hue (bronze, brown, blue-grey) or desaturate it _(from R3 Contrast vs ground (meadow), shot z40)_

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
| B1 | Meshes after the kit merge | PASS 99 | 19 drawn (19 mesh + 0 multimesh); per pivot: ArmL 2, ArmR 2, Chest 2, Head 2, Bow 1, Hips 1 | <= 26 (art-units.md 8, tier3-extras.md 12) |  |
| B2 | Draw instances at rest | **FAIL** 1 | 19 | <= 14 (art-units.md 8, tier3-extras.md 12) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B3 | keep_separate parts | PASS 100 | 4 | <= 6 soft (art-units.md 8, tier3-extras.md 12) |  |
| B4 | Vertices | **FAIL** 0 | 11511 (biggest: Merged 2684, Merged 2521, Merged 1124, Merged 885) | <= 2500 (art-units.md 8, tier3-extras.md 12) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8, tier3-extras.md 12) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 soft (art-units.md 8, tier3-extras.md 12) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 10 soft (art-units.md 8, tier3-extras.md 12) |  |
| B7 | Shadow casters | PASS 89 | 4 (Merged, Merged, Merged, Merged) | <= 4 soft (art-units.md 8, tier3-extras.md 12) |  |
| B8 | Unique materials | INFO | 20 | no budget for unit/soldier |  |
| B1a | Authored build parts (before the merge) | INFO | 19 (model says 22) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 26 |  |
| B11 | Surfaces per instance | INFO | 89 surfaces over 19 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1927 of 14696 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point 0.007 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Merged 0.65 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 1.31 / z 1.52 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 1434 px (57 x 68 bbox; 55 m: 731 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 83 | mean-colour dE 21.1, 8% of the body melts (within dE 15 of the ground); body L* 60.8 C 28.6 vs ground L* 61.9 C 49.0, hue gap 8 deg; top third (world height) dE 31.0, L* 78.0; per-pixel dE 39.4, outline 38.0 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (old_wood) | PASS 100 | dE 33.7, 13% melts (old_wood is where nature units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 77 | worst heath: dE 11.5 (heath dE 11.5, old_wood dE 33.7, riverbank dE 29.3, snow dE 39.8, ash dE 48.4, sand dE 24.3, marsh dE 50.6) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 97 | 22% of body pixels change between kingdom colours (min pair 20%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 87 | worst nature colour: dE 20.8 (fire 33.6, shadow 44.2, ice 32.6, nature 20.8) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 44 | worst pair fire / nature (deutan): dE 11.3 on the team-colour area (normal vision 55.2; 439 px); deutan: fire / nature dE 11.3; protan: fire / nature dE 18.7; worst vs ground: fire colour (deutan) dE 13.2 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -11 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 3.1 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +26 (point 1 dL +37, point 2 dL +26, point 3 dL +26, soft 1 dL +31 (counts); ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | PASS 100 | 3 point(s) above the bloom level 1.2 (median of 3/3/3): Merged x3, 2 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) |  |
| R11 | Reads while walking (40 m) | PASS 97 | walk frames vs rest: mean IoU 0.79 (min 0.73), area kept 94-103% (min 1369 px), frame-to-frame IoU min 0.75; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 93 | points per frame 3/3/4/3/3/3/3/4 (median 3, range 1, 0 frame(s) at 0; at rest 3) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | **WARN** 40 | strike pose changes 4% of the silhouette (t 0.36 s) | >= 12% (1 - IoU rest vs strike) | Bigger wind-up / strike: the weapon or head should leave the body outline |
| A2 | death_finished | PASS 100 | after 1.01 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 4.32 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 78.0, bottom third L* 27.1 (+50, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 10.8 at 25 m, 14.4 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 3 of 3 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8, tier3-extras.md 12)
`{"draw":14,"frame_ms":0.005,"lights":0,"meshes":26,"n":100,"runtime_mats":0,"soft":{"casters":4,"looping":1,"particles":10,"separate":6},"src":"art-units.md 8, tier3-extras.md 12","verts":2500}`

## Notes
- Per-mesh vertices (biggest first): Stag/Root/Mount/Head/Merged 2684 v / 8 s; Stag/Root/Mount/Merged 2521 v / 8 s; Rider/Root/Chest/Head/Merged 1124 v / 8 s; Rider/Root/Hips/Merged 885 v / 7 s; Rider/Root/Chest/Merged 479 v / 6 s; Rider/Root/Hips/LegR/Merged 406 v / 4 s; Rider/Root/Hips/LegL/Merged 406 v / 4 s; Stag/Root/Mount/LegBR/Merged 343 v / 4 s
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: B4 11511 -> 5764 (want <= 2500): `Merged` 2684 -> 1342 verts; `Merged` 2521 -> 1261 verts; `Merged` 1124 -> 562 verts; `Merged` 885 -> 443 verts; `Merged` 479 -)
