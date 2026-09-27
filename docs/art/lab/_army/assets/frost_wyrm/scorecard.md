# Art Lab scorecard: frost_wyrm

Scene `res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn` · kind **beast** / tier **titan** · kingdom neutral · ground meadow · 2026-09-27 10:23:01 · lab v2.0

## Result: **WARN** · quality **90 / 100**

0 FAIL · 3 WARN · 18 PASS · 12 info · 0 skipped · 27 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 5 -> 2 (want 0-3): wyrm_scale_a glow_energy 1.0 -> 0.18 (dim under the bloom level: 3 point(s), peak 4.17 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Meshes built per instance** (WARN): B9m Meshes built per instance: Cache the 1 per-instance mesh(es) in a static dictionary [fixes.json #2] _(from B9m Meshes built per instance)_
3. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 2 glow point(s) barely stand out from their 1 m surround (worst dL +9): darken around them or raise the energy [fixes.json #3] _(from R5c Glow points stand out (1 m surround), shot glow)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +0 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Contrast on the other grounds** (PASS): On snow the body drops to dE 17.2: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 24 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 1 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B9m | Meshes built per instance | **WARN** 52 | 1 mesh(es) per instance | meshes shared per type | Build meshes once (static cache or .res) and share them |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 8 drawn (8 mesh + 0 multimesh); per pivot: (root) 1, FinL 1, FinR 1, Head 1, Jaw 1, LegFL 1 | <= 36 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B2 | Draw instances at rest | PASS 100 | 8 | <= 20 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B4 | Vertices | PASS 100 | 8298 (biggest: BodyMesh 4340, HeadMesh 1995, JawMesh 545, LegFLMesh 414) | <= 12000 soft (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B6 | Particle systems | INFO | 1 | no budget for beast/titan |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B7 | Shadow casters | PASS 100 | 2 (HeadMesh, BodyMesh) | <= 8 soft (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B8 | Unique materials | INFO | 8 | no budget for beast/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 8 (model says 8) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 24 surfaces over 8 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1945 of 12896 triangles (15%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 3.24 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R10 | Footprint vs selection radius | INFO | x 1.67 / z 9.62 m (radius 1.0, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 5816 px (181 x 199 bbox; 55 m: 2950 px) | >= 350 px (FAIL < 150) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 58.8, 0% of the body melts (within dE 15 of the ground); body L* 79.7 C 10.3 vs ground L* 60.8 C 50.4, hue gap n/a (body C* <= 25); top third (world height) dE 60.5, L* 78.4; per-pixel dE 61.5, outline 45.2 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 84 | worst snow: dE 17.2 (heath dE 47.0, old_wood dE 58.9, riverbank dE 52.2, snow dE 17.2, ash dE 57.9, sand dE 42.2, marsh dE 67.1) | dE >= 10 on every skirmish ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 99 | bar hides 1% of the silhouette (gap -82 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 6.5 m, 2.6 m wide |  |
| R5c | Glow points stand out (1 m surround) | **WARN** 51 | worst dL +9 (point 1 dL +40, point 2 dL +9, point 3 dL +15, point 4 dL +25, point 5 dL +26; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 5 point(s) above the bloom level 1.2 (median of 5/4/6): BodyMesh, HeadMesh x2, LegFLMesh, LegFRMesh, 5 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 3 | 0-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): BodyMesh, HeadMesh x2, LegFLMesh, LegFRMesh |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.35 (min 0.3), area kept 108-110% (min 6146 px), frame-to-frame IoU min 0.68; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 350 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 100 | points per frame 4/4/4/4/4/4/4/4 (median 4, range 0, 0 frame(s) at 0; at rest 5) | the glow-point count stays within +-1 over the walk cycle and never drops to 0 (WARN only) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 54% of the silhouette (t 0.24 s) | >= 10% (1 - IoU rest vs strike) |  |
| A2 | death_finished | PASS 100 | after 1.87 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 7.37 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 26 | top third L* 80.9, bottom third L* 81.5 (+0, screen rows) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 7.1 at 25 m, 9.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 5 of 5 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, titans-2.md 11 (Frost Wyrm uses the titan budget))
`{"draw":20,"frame_ms":0.02,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":8,"verts":12000},"src":"titans-2.md 11 (Frost Wyrm uses the titan budget)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Spine/BodyMesh 4340 v / 3 s; Root/Body/Neck1/Neck2/Head/HeadMesh 1995 v / 5 s; Root/Body/Neck1/Neck2/Head/Jaw/JawMesh 545 v / 5 s; Root/Body/LegFL/LegFLMesh 414 v / 3 s; Root/Body/LegFR/LegFRMesh 414 v / 3 s; Root/Body/FinL/FinLMesh 293 v / 2 s; Root/Body/FinR/FinRMesh 293 v / 2 s; Shadow 4 v / 1 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: Glow points 5 -> 2 (want 0-3): wyrm_scale_a glow_energy 1.0 -> 0.18 (dim under the bloom level: 3 point(s), peak 4.17 x the level))
