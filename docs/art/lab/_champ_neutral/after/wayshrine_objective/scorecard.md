# Art Lab scorecard: wayshrine_objective

Scene `res://art/buildings/capture/wayshrine/wayshrine.tscn` · kind **landmark** / tier **objective** · kingdom neutral · ground meadow · 2026-09-30 14:55:09 · lab v3.1

## Result: **WARN** · quality **85 / 100** (84.9) (previous run 85, +0)

0 FAIL · 1 WARN · 16 PASS · 15 info · 0 skipped · 15 s

## Before / after (vs the run of 2026-09-30 14:45:49 in `docs/art/lab/_champ_neutral/after/wayshrine_objective`: quality 85 -> 85, +0)
### What got worse (1)
1. **C1 Shape richness (secondary shapes): INFO 29 -> INFO 25 (-4)**. Now: 87 shapes over 3 body parts (29.0 per part: (root) 68, Float 16, Orbit 3); 14% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.777. Was: 87 shapes over 3 body parts (29.0 per part: (root) 68, Float 16, Orbit 3); 14% of the surface on plain boxes / prisms (<

### Score delta per check (4 changed, 31 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 29 | INFO 25 | -4.2 |
| C4 | Inner detail (close-up / 25 m) | INFO 89 | INFO 91 | +1.4 |
| P3 | Tops light, bottoms dark | INFO 5 | INFO 4 | -1.4 |
| R5c | Glow points stand out (1 m surround) | PASS 91 | PASS 91 | +0.8 (noisy) |

Changed pixels per shot: z40 0.7 %, z55 0.5 %, z25 0.8 %, close 0.5 %, turns 0.9 %, anim 3.5 %, silhouette 0.0 %, lineup 0.3 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 1 -> 4 (want 4-12): add 3 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= 1.3 x the bloom level 1.2 [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Vertex use vs budget** (INFO): Only 15% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.78): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -4 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Style bible: golden autumn (style-autumn.md 3)** (INFO): On the autumn map the body melts into the ochre floor (dE 26.1): push its main mass out of the L* 25-55 / C* <= 35 band _(from S1 Style bible: golden autumn (style-autumn.md 3), shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 12 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 4 | no budget for landmark/objective |  |
| B2 | Draw instances at rest | PASS 100 | 4 | <= 32 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B4 | Vertices | PASS 100 | 3858 (biggest: Stone 3420, RuneStone 333, Shards 72, Contact 33) | <= 24000 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B6l | Looping particle systems | PASS 100 | 0 | <= 3 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B7 | Shadow casters | INFO | 2 | no budget for landmark/objective |  |
| B8 | Unique materials | PASS 100 | 7 | <= 10 soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |
| B1a | Authored build parts (before the merge) | INFO | 9 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 4 surfaces over 4 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 104 of 1307 triangles (7%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (4 animated at 40 m: +-0.21 ms process, render CPU +0.01 ms, GPU +1.53 ms) | <= 0.05 ms per instance soft (map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.06 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 99 | 5771 px (126 x 116 bbox; 55 m: 3030 px) | >= 3000 px (FAIL < 800) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 41.8, 0% of the body melts (within dE 15 of the ground); body L* 56.2 C 10.3 vs ground L* 64.0 C 48.9, hue gap n/a (body C* <= 25); top third (world height) dE 63.1, L* 50.5; per-pixel dE 47.2, outline 35.2 | mean-colour dE >= 10 and <= 35 % melting (FAIL: dE < 5 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 100 | worst heath: dE 16.6 (heath dE 16.6, old_wood dE 31.4, riverbank dE 33.1, snow dE 34.5, ash dE 33.8, sand dE 32.6, marsh dE 39.9) | dE >= 5 on every skirmish ground (WARN only) |  |
| R5c | Glow points stand out (1 m surround) | PASS 91 | worst dL +29 (point 1 dL +29; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): RuneStone; soft glows under the bloom (v1 count, luma > 0.4): 1 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it); 1 soft glow(s) sit under the bloom level: raise one to emission >= 2.4 |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.43 (barge 0.43, giant_stump 0.32, crag_nest 0.29, colossus 0.27, standing_stones 0.17, old_wood_den 0.06) | IoU <= 0.85 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 25 | 87 shapes over 3 body parts (29.0 per part: (root) 68, Float 16, Orbit 3); 14% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.777 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 4 | 15% of the 24000 verts budget used (3825) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 100 | 13 colour steps (L*a*b* bins >= 2 % of the body), 9 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 91 | inner edges per outline px: 2.59 at the close-up (34111 px), 2.26 at 25 m; close-up outline complexity 6.95 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.23 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 4 | top third L* 50.5, bottom third L* 54.9 (-4, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.5 at 25 m, 9.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 48 | on the autumn floor: dE 26.1, 1% melts; body L* 52.6 C 17.3 vs floor L* 52.3 C 43.2 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
| P2 | Asymmetric secondary shape | INFO 100 | front-view asymmetry 0.48 | one asymmetric secondary element (art-keep 0.1): >= ~0.15 |  |

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

## Budget used (`tools/art_lab/lab_budgets.gd`, map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12)
`{"lights":0,"n":4,"soft":{"draw":32,"frame_ms":0.05,"looping":3,"materials":10,"verts":24000},"src":"map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12"}`

## Notes
- Per-mesh vertices (biggest first): Stone 3420 v / 1 s; Float/RuneStone 333 v / 1 s; Float/Orbit/Shards 72 v / 1 s; Contact 33 v / 1 s
- 5 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- Fix recipes: 1 in fixes.json (top: Glow points 1 -> 4 (want 4-12): add 3 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >=)
