# Art Lab scorecard: crown_pedestal

Scene `res://art/environment/crown_pedestal.tscn` · kind **landmark** / tier **landmark** · kingdom neutral · ground meadow · 2026-09-30 14:44:40 · lab v3.1

## Result: **WARN** · quality **87 / 100** (87.0) (previous run 87, +0)

0 FAIL · 2 WARN · 14 PASS · 18 info · 0 skipped · 32 s

## Before / after (vs the run of 2026-09-30 11:48:33 in `docs/art/lab/_champ_neutral/before/crown_pedestal`: quality 87 -> 87, +0)
### What got worse (0)
Nothing got worse.

### Score delta per check (1 changed, 34 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| R5c | Glow points stand out (1 m surround) | PASS 94 | PASS 93 | -0.8 (noisy) |

Changed pixels per shot: z40 1.8 %, z55 1.3 %, z25 1.9 %, close 0.1 %, turns 0.1 %, anim 0.0 %, silhouette 0.0 %, lineup 0.0 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 9 -> 3 (want 0-3): crown_beacon_mat emission x 0.09 on Beacon (dim under the bloom level: 6 point(s), peak 7.94 x the level (>= 8, clipped); no energy / glow-colour parameter found) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Unique materials** (WARN): B8 10 -> 9 materials: use one material for look-alike pairs (albedo dE <= 15): `crown_pedestal` -> `StandardMaterial3D#-83541` (dE 0.0); 3 more to cut: no other pair is a look-alike (the rest differ by dE > 15), so fold per-part copies into the palette materials instead of merging different colours [fixes.json #2] _(from B8 Unique materials)_
3. **Inner detail (close-up / 25 m)** (INFO): Big plain panels inside the silhouette (1.18 inner edges per outline px): break the torso / limbs with secondary shapes and value breaks (belt, plates, straps, bark seams) _(from C4 Inner detail (close-up / 25 m), shot close)_
4. **Glow placement** (INFO): Move or add one glow point to the upper half (head, weapon tip, crest) so it reads above other units _(from P5 Glow placement, shot glow)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 19.2): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_
6. **Contrast vs ground (meadow)** (PASS): Raise the contrast of the key read on meadow (dE 31.6): value is close to the ground (dL -2): lighten the top / back 15-20 % or add a dark saddle / pale belly band; the top third (what reads from pitch 55) is close to the ground (dE 7.5): lighten helmets / shoulders / back _(from R3 Contrast vs ground (meadow), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 13 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 1 material(s), 0 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 5 | no budget for landmark/landmark |  |
| B2 | Draw instances at rest | PASS 100 | 6 | <= 24 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B4 | Vertices | PASS 99 | 14517 (biggest: Stone 7032, RuinDressing 5808, Runes 1548, Beacon 125) | <= 20000 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B6 | Particle systems | INFO | 2 | no budget for landmark/landmark |  |
| B6l | Looping particle systems | PASS 100 | 1 (Embers) | <= 2 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |
| B6p | Looping particles alive | INFO | 22 | no budget for landmark/landmark |  |
| B7 | Shadow casters | INFO | 2 | no budget for landmark/landmark |  |
| B8 | Unique materials | **WARN** 35 | 10 | <= 6 soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 9 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 7 surfaces over 5 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 743 of 4990 triangles (14%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0012 ms process per instance (4 animated at 40 m: +0.0 ms process, render CPU +0.02 ms, GPU +0.09 ms) | <= 0.05 ms per instance soft (map-fill.md 9 (emission only, shadows allowed); counts = lab defaults) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.25 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 25248 px (505 x 437 bbox; 55 m: 12709 px) | >= 3000 px (FAIL < 800) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 93 | mean-colour dE 31.6, 19% of the body melts (within dE 15 of the ground); body L* 57.5 C 16.3 vs ground L* 59.7 C 45.8, hue gap n/a (body C* <= 25); top third (world height) dE 7.5, L* 67.0; per-pixel dE 38.5, outline 33.5 | mean-colour dE >= 10 and <= 35 % melting (FAIL: dE < 5 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 94 | worst heath: dE 12.6 (heath dE 12.6, old_wood dE 26.6, riverbank dE 27.8, snow dE 26.8, ash dE 27.6, sand dE 26.7, marsh dE 32.5) | dE >= 5 on every skirmish ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 93 | worst dL +16 (point 1 dL +16, point 2 dL +48, point 3 dL +40, point 4 dL +37, point 5 dL +33, point 6 dL +22, point 7 dL +45, point 8 dL +23; ring 26 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 9 point(s) above the bloom level 1.2 (median of 8/9/10): Beacon x7, Runes x2; soft glows under the bloom (v1 count, luma > 0.4): 10 | 0-3 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): Beacon x7, Runes x2 |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.29 (giant_stump 0.29, aqueduct 0.28, colossus 0.27, crag_nest 0.18, standing_stones 0.13, old_wood_den 0.07) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 100 | 159 shapes over 1 body parts (159.0 per part: (root) 159); 39% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.851 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 100 | 72% of the 20000 verts budget used (14513) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 18 colour steps (L*a*b* bins >= 2 % of the body), 10 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 14 | inner edges per outline px: 1.18 at the close-up (10750 px), 1.57 at 25 m; close-up outline complexity 23.56 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 27.69 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 100 | top third L* 67.0, bottom third L* 52.8 (+14, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.7 at 25 m, 5.7 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 0 | 0 of 8 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 30 | on the autumn floor: dE 19.2, 18% melts; body L* 52.3 C 22.5 vs floor L* 47.3 C 40.8 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.6 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- silhouette: [silhouette.png](silhouette.png)
- lineup: [lineup.jpg](lineup.jpg)
- diff_sheet: [diff_sheet.png](diff_sheet.png)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 (emission only, shadows allowed); counts = lab defaults)
`{"lights":0,"n":4,"soft":{"draw":24,"frame_ms":0.05,"looping":2,"materials":6,"verts":20000},"src":"map-fill.md 9 (emission only, shadows allowed); counts = lab defaults"}`

## Notes
- Per-mesh vertices (biggest first): Stone 7032 v / 2 s; RuinDressing 5808 v / 1 s; Runes 1548 v / 2 s; Beacon 125 v / 1 s; GroundGlow 4 v / 1 s
- 4 hidden parts at rest (toggled states, not counted as draws)
- 1 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 2 in fixes.json (top: Glow points 9 -> 3 (want 0-3): crown_beacon_mat emission x 0.09 on Beacon (dim under the bloom level: 6 point(s), peak 7.94 x the level (>= 8, clipped); no ener)
