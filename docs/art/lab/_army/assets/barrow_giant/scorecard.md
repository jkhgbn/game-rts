# Art Lab scorecard: barrow_giant

Scene `res://art/units/shadow/barrow_giant/barrow_giant.tscn` · kind **unit** / tier **heavy** · kingdom shadow · ground meadow · 2026-09-27 10:12:19 · lab v2.0

## Result: **WARN** · quality **89 / 100**

0 FAIL · 6 WARN · 24 PASS · 10 info · 0 skipped · 30 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 6 -> 2 (want 1-3): barrow_soul_glow energy 3.0 -> 0.2 (dim under the bloom level: 4 point(s), peak 4.24 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Parts above body_height + 0.4** (WARN): R8w Parts above body_height + 0.4: Narrow Gravestone 1.06 m so the HP bar reads over the head [fixes.json #3] _(from R8w Parts above body_height + 0.4)_
3. **Head height vs body_height** (WARN): R8: body_height 4.5 -> 3.06 in res://art/units/shadow/barrow_giant/barrow_giant.tscn (root) (the head top; x0.68 now), or lower the head / crest 0.0 m [fixes.json #2] _(from R8 Head height vs body_height)_
4. **death_finished** (WARN): A2 death_finished: Emit death_finished at the end of the death timeline (it must fire even at the far distance tier) [fixes.json #4] _(from A2 death_finished)_
5. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 4 glow point(s) barely stand out from their 1 m surround (worst dL +3): darken around them or raise the energy [fixes.json #5] _(from R5c Glow points stand out (1 m surround), shot glow)_
6. **Glow points while walking (flicker)** (WARN): R5w Glow points while walking (flicker): The glow points blink while walking (4/2/4/2/5/4/4/3 per frame): put them on parts the gait does not cover [fixes.json #6] _(from R5w Glow points while walking (flicker), shot glow)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 23 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 10 drawn (10 mesh + 0 multimesh); per pivot: ArmR 2, Chest 2, (root) 1, ArmL 1, Head 1, Hips 1 | <= 30 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B2 | Draw instances at rest | PASS 100 | 10 | <= 16 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B3 | keep_separate parts | PASS 100 | 2 | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B4 | Vertices | PASS 100 | 4053 (biggest: Merged 1192, Gravestone 828, Merged 499, Merged 419) | <= 6000 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6 | Particle systems | INFO | 2 | no budget for unit/heavy |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 1 (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 16 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B7 | Shadow casters | PASS 100 | 4 (Merged, Gravestone, Merged, Merged) | <= 6 soft (art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units) |  |
| B8 | Unique materials | INFO | 12 | no budget for unit/heavy |  |
| B1a | Authored build parts (before the merge) | INFO | 57 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 30 |  |
| B11 | Surfaces per instance | INFO | 31 surfaces over 10 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 315 of 1992 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | PASS 100 | lowest point -0.024 m | -0.08 .. +0.05 m (art-units 1.6) |  |
| R8 | Head height vs body_height | **WARN** 64 | head top 3.06 m / body_height 4.5 (x0.68) | x0.75-1.25 (art-units 1.1: the HP bar hangs at body_height + 0.5) | Set body_height (UnitType + scene) to the head top, or rescale the body |
| R8w | Parts above body_height + 0.4 | **WARN** 52 | Gravestone 1.06 m | narrower than 0.35 m (art-units 1.1: the HP bar stays readable) | Narrow the hat / horn / staff head above the bar line |
| R10 | Footprint vs selection radius | INFO | x 1.74 / z 1.35 m (radius 0.45, default) | x <= radius x 1.4, z <= x 1.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 5782 px (87 x 113 bbox; 55 m: 2939 px) | >= 120 px (FAIL < 45) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 77.1, 0% of the body melts (within dE 15 of the ground); body L* 40.7 C 24.7 vs ground L* 61.3 C 50.3, hue gap n/a (body C* <= 25); top third (world height) dE 64.3, L* 58.1; per-pixel dE 81.3, outline 62.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 37.5, 0% melts (marsh is where shadow units stand most) | dE >= 20 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 97 | worst ash: dE 27.2 (heath dE 51.0, old_wood dE 46.8, riverbank dE 56.0, snow dE 56.1, ash dE 27.2, sand dE 65.1, marsh dE 37.5) | dE >= 10 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 93 | 19% of body pixels change between kingdom colours (min pair 17%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 57.9 (fire 66.4, shadow 76.2, ice 67.7, nature 57.9) | dE >= 20 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | PASS 86 | worst pair fire / nature (deutan): dE 18.2 on the team-colour area (normal vision 64.6; 1363 px); deutan: fire / nature dE 18.2; protan: fire / nature dE 25.1; worst vs ground: fire colour (deutan) dE 44.6 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 10 from the ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 97 | bar hides 2% of the silhouette (gap -16 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 5.0 m, 1.17 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 47 | worst dL +3 (point 1 dL +9, point 2 dL +6, point 3 dL +3, point 4 dL +31, point 5 dL +21, point 6 dL +46, point 7 dL +17; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 6 point(s) above the bloom level 1.2 (median of 7/6/6): Merged x5, Core, 1 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 6 | 1-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Merged x5, Core |
| R11 | Reads while walking (40 m) | PASS 95 | walk frames vs rest: mean IoU 0.8 (min 0.72), area kept 87-96% (min 4985 px), frame-to-frame IoU min 0.87; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 120 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | **WARN** 52 | points per frame 4/2/4/2/5/4/4/3 (median 4, range 3, 0 frame(s) at 0; at rest 6) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) | Glow points that hide behind a swinging limb or dip under the bloom level blink at 40 m: move them to a steady part (head, chest, weapon head) or raise their energy |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 6 present | set_team_color, set_moving, play_attack, play_hit, play_death, signal:death_finished |  |
| A3 | Attack reads at 40 m | PASS 98 | strike pose changes 27% of the silhouette (t 0.24 s) | >= 12% (1 - IoU rest vs strike) |  |
| A2 | death_finished | **WARN** 45 | never (3 s) | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) | Emit death_finished at the end of the death timeline (it must fire even at the far distance tier) |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 23 | outline complexity 1.6 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 58.1, bottom third L* 19.4 (+38, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 4.8 at 25 m, 8.2 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 5 of 7 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units)
`{"draw":16,"frame_ms":0.005,"lights":0,"looping":1,"meshes":30,"n":100,"runtime_mats":0,"soft":{"casters":6,"particles":16,"separate":6,"verts":6000},"src":"art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default for big units"}`

## Notes
- Per-mesh vertices (biggest first): Root/Chest/Merged 1192 v / 6 s; Root/Chest/ArmR/Gravestone 828 v / 3 s; Root/Chest/Head/Merged 499 v / 5 s; Root/Chest/ArmL/Merged 419 v / 3 s; Root/Chest/ArmR/Merged 419 v / 3 s; Root/Hips/LegL/Merged 284 v / 3 s; Root/Hips/LegR/Merged 284 v / 3 s; Root/Hips/Merged 92 v / 3 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 6 in fixes.json (top: Glow points 6 -> 2 (want 1-3): barrow_soul_glow energy 3.0 -> 0.2 (dim under the bloom level: 4 point(s), peak 4.24 x the level))
