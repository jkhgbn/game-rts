# Art Lab scorecard: frost_wyrm

Scene `res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn` · kind **beast** / tier **titan** · kingdom neutral · ground meadow · 2026-10-15 13:20:30 · lab v3.1

## Result: **WARN** · quality **91 / 100** (90.6)

0 FAIL · 1 WARN · 22 PASS · 21 info · 0 skipped · 38 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 4 -> 1 (want 0-3): wyrm_scale_a glow_energy 1.0 -> 0.18 on BodyMesh, LegFLMesh, LegFRMesh (dim under the bloom level: 3 point(s), peak 4.14 x the level) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Palette depth (close-up)** (INFO): Flat palette (8 colour / 7 value steps): add a darker and a lighter step of the main colours (trim, recesses, highlights on the top masses) _(from C3 Palette depth (close-up), shot close)_
3. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +0 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
4. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.85): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
5. **Contrast on the other grounds** (PASS): On snow the body drops to dE 17.3: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 25 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | PASS 100 | 9 drawn (9 mesh + 0 multimesh); per pivot: Head 2, (root) 1, FinL 1, FinR 1, Jaw 1, LegFL 1 | <= 36 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B2 | Draw instances at rest | PASS 100 | 9 | <= 20 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B3 | keep_separate parts | INFO | 1 | no budget for beast/titan |  |
| B4 | Vertices | PASS 98 | 8778 (body + face above its allowance: face 480 v, allowance 0, total 8778; biggest: BodyMesh 4340, HeadMesh 1995, JawMesh 545, Face 480) | <= 12000 soft (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B6 | Particle systems | INFO | 1 | no budget for beast/titan |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 2 (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B7 | Shadow casters | PASS 100 | 2 (HeadMesh, BodyMesh) | <= 8 soft (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |
| B8 | Unique materials | INFO | 9 | no budget for beast/titan |  |
| B1a | Authored build parts (before the merge) | INFO | 9 (model says 8) | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes), v1 limit 36 |  |
| B11 | Surfaces per instance | INFO | 25 surfaces over 9 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 1944 of 13864 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0004 ms process per instance (12 animated at 40 m: +0.0 ms process, render CPU +0.26 ms, GPU +0.25 ms) | <= 0.02 ms per instance (titans-2.md 11 (Frost Wyrm uses the titan budget)) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Feet on the ground | INFO | flyer: lowest point 3.27 m (hovers) | flyers hover (FlyerModel fly_height) |  |
| R10 | Footprint vs selection radius | INFO | x 1.68 / z 9.62 m (radius 1.0, default) | x <= radius x 1.4, z <= x 2.4 (art-units 1.1; parts thinner than 8 cm ignored) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 5770 px (174 x 202 bbox; 55 m: 2908 px) | >= 350 px (FAIL < 150) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 59.2, 0% of the body melts (within dE 15 of the ground); body L* 79.6 C 10.4 vs ground L* 61.0 C 50.9, hue gap n/a (body C* <= 25); top third (world height) dE 60.5, L* 78.6; per-pixel dE 61.6, outline 45.7 | mean-colour dE >= 20 and <= 35 % melting (FAIL: dE < 10 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 84 | worst snow: dE 17.3 (heath dE 46.9, old_wood dE 58.9, riverbank dE 52.4, snow dE 17.3, ash dE 57.9, sand dE 42.2, marsh dE 67.0) | dE >= 10 on every skirmish ground (WARN only) |  |
| R7 | HP bar over the body at 40 m | PASS 98 | bar hides 1% of the silhouette (gap -86 px) | <= 8% (FAIL > 25%); bar at body_height + 0.5 = 6.5 m, 2.6 m wide |  |
| R5c | Glow points stand out (1 m surround) | PASS 89 | worst dL +9 (point 1 dL +39, point 2 dL +9, point 3 dL +22, point 4 dL +25; ring 25 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 4 point(s) above the bloom level 1.2 (median of 4/4/5): BodyMesh, HeadMesh, LegFLMesh, LegFRMesh, 8 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 2 | 0-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): BodyMesh, HeadMesh, LegFLMesh, LegFRMesh |
| R12 | Contrast under every light preset (meadow) | PASS 100 | worst ice: dE 56.5, dL +22 (warm dE 60.0, ice dE 56.5, night dE 61.8, autumn dE 57.0); night = lab stand-in (warm preset, dim moon sun) | mean-colour dE >= 10 on the main ground under warm / ice / night / autumn light (WARN only: units appear on every map) |  |
| R11 | Reads while walking (40 m) (flyer: wing beat) | INFO 100 | walk frames vs rest: mean IoU 0.36 (min 0.32), area kept 106-108% (min 6145 px), frame-to-frame IoU min 0.76; 8 frames 0.09 s apart | mean IoU walk vs rest >= 0.55, >= 70% of the rest area in every frame and >= R1's 350 px (WARN only) |  |
| R5w | Glow points while walking (flicker) | PASS 85 | points per frame 4/5/3/4/5/3/4/4 (median 4, range 2, 0 frame(s) at 0; at rest 4) | the glow-point count stays within +-2 over the walk cycle and never drops to 0 (WARN only) |  |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.26 (war_mammoth 0.26, nightmare_knight 0.2, roc 0.16, grizzlemaw 0.13, tusker 0.12, direwolf 0.07); wing phase matched to the target's (p 0.0; residual per flyer ref: roc 0.0) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 7 present | set_moving, play_attack, play_hit, play_death, signal:death_finished, set_variant, play_cast |  |
| A3r | Weapon reach at the strike | INFO | tip reaches 9.62 m from the body centre at t 0.08 s (4.55 m forward; geometry clipped at the ground); no declared reach (no UnitType, no reach=) | reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene |  |
| A3 | Attack reads at 40 m | PASS 100 | strike pose changes 50% of the silhouette (t 0.24 s) | >= 10% (1 - IoU rest vs strike) |  |
| A4 | Cast pose reads (play_cast) | INFO | cast pose changes 92% of the silhouette at its peak (t 0.4 s; 0.12 s 59%, 0.25 s 91%, 0.4 s 92%, 0.6 s 92%) | shown in the strip + cast.jpg (rest / peak); INFO until calibrated (a cast should change >= 6% of the outline) |  |
| A2 | death_finished | PASS 100 | after 1.86 s | emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 72 | 121 shapes over 7 body parts (17.3 per part: Jaw 14, Head 62, LegFL 8, LegFR 8, FinL 6, FinR 6, Spine 17); 24% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.852 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.92 |  |
| C2 | Vertex use vs budget | INFO 100 | 73% of the 12000 verts budget used (8774) | craft (lab v3.1): a finished model uses >= 65% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 25 | 8 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 13 colour steps and >= 9 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 100 | inner edges per outline px: 3.34 at the close-up (16068 px), 3.16 at 25 m; close-up outline complexity 7.41 | craft (lab v3.1): >= 1.8 inner edge px per outline px at the close-up, >= 1.4 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 7.72 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 34 | top third L* 82.0, bottom third L* 81.2 (+0, screen rows) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.9 at 25 m, 9.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 4 of 4 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 100 | on the autumn floor: dE 55.6, 0% melts; body L* 76.6 C 7.2 vs floor L* 46.9 C 40.2 | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.68 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, titans-2.md 11 (Frost Wyrm uses the titan budget))
`{"draw":20,"frame_ms":0.02,"lights":0,"looping":2,"meshes":36,"n":12,"runtime_mats":0,"soft":{"casters":8,"verts":12000},"src":"titans-2.md 11 (Frost Wyrm uses the titan budget)"}`

## Notes
- Per-mesh vertices (biggest first): Root/Spine/BodyMesh 4340 v / 3 s; Root/Body/Neck1/Neck2/Head/HeadMesh 1995 v / 5 s; Root/Body/Neck1/Neck2/Head/Jaw/JawMesh 545 v / 5 s; Root/Body/Neck1/Neck2/Head/Face 480 v / 1 s; Root/Body/LegFL/LegFLMesh 414 v / 3 s; Root/Body/LegFR/LegFRMesh 414 v / 3 s; Root/Body/FinL/FinLMesh 293 v / 2 s; Root/Body/FinR/FinRMesh 293 v / 2 s
- 1 hidden parts at rest (toggled states, not counted as draws)
- 2 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: Glow points 4 -> 1 (want 0-3): wyrm_scale_a glow_energy 1.0 -> 0.18 on BodyMesh, LegFLMesh, LegFRMesh (dim under the bloom level: 3 point(s), peak 4.14 x the le)
