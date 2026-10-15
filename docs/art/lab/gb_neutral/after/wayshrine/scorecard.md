# Art Lab scorecard: wayshrine

Scene `res://art/buildings/capture/wayshrine/wayshrine.tscn` · kind **building** / tier **hall** · kingdom neutral · ground meadow · 2026-10-15 12:00:19 · lab v3.1

## Result: **WARN** · quality **85 / 100** (85.1) (previous run 84, +1)

0 FAIL · 2 WARN · 16 PASS · 16 info · 0 skipped · 20 s

## Before / after (vs the run of 2026-10-15 11:51:11 in `docs/art/lab/gb_neutral/after/wayshrine`: quality 84 -> 85, +1)
### What got worse (3)
1. **C3 Palette depth (close-up): INFO 100 -> INFO 83 (-17)**. Now: 12 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %). Was: 14 colour steps (L*a*b* bins >= 2 % of the body), 8 value steps (L* bins of 8 >= 3 %)
2. **C1 Shape richness (secondary shapes): INFO 26 -> INFO 24 (-2)**. Now: 87 shapes over 3 body parts (29.0 per part: (root) 68, Float 16, Orbit 3); 14% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.777. Was: 87 shapes over 3 body parts (29.0 per part: (root) 68, Float 16, Orbit 3); 14% of the surface on plain boxes / prisms (<
3. **S1 Style bible: golden autumn (style-autumn.md 3): INFO 48 -> INFO 44 (-3)**. Now: on the autumn floor: dE 24.7, 3% melts; body L* 53.8 C 18.7 vs floor L* 52.3 C 43.2 (inside the floor band). Was: on the autumn floor: dE 26.0, 2% melts; body L* 54.5 C 17.5 vs floor L* 52.3 C 43.2 (inside the floor band)

### What got better (2)
B5 Real lights: FAIL 0 -> PASS 100 (+100); P3 Tops light, bottoms dark: INFO 8 -> INFO 15 (+6)

### Score delta per check (7 changed, 29 unchanged)
| # | Check | Before | After | Delta |
|---|---|---|---|---|
| B5 | Real lights | FAIL 0 | PASS 100 | +100.0 |
| C1 | Shape richness (secondary shapes) | INFO 26 | INFO 24 | -2.3 |
| C3 | Palette depth (close-up) | INFO 100 | INFO 83 | -16.7 |
| C4 | Inner detail (close-up / 25 m) | INFO 92 | INFO 93 | +1.0 |
| R4 | Contrast on the other grounds | PASS 92 | PASS 90 | -1.8 |
| P3 | Tops light, bottoms dark | INFO 8 | INFO 15 | +6.2 |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 48 | INFO 44 | -3.4 |

Changed pixels per shot: z40 0.6 %, z55 0.4 %, z25 0.7 %, close 0.8 %, turns 1.1 %, anim 4.7 %, silhouette 0.0 %, lineup 1.4 % · [diff sheet](diff_sheet.png) (before / after / changed mask)

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 1 -> 2 (want 2-4): add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= 1.3 x the bloom level 1.2 [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Standard hooks** (WARN): A1 Standard hooks: Implement set_team_color, set_construction_progress, set_health_ratio, play_destroyed [fixes.json #2] _(from A1 Standard hooks)_
3. **Shape richness (secondary shapes)** (INFO): Plain / blocky shapes: few surface directions (normal variety 0.78): tilt, curve and rotate parts so the light breaks on them _(from C1 Shape richness (secondary shapes), shot close)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now -2 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Vertex use vs budget** (INFO): Only 31% of the vertex budget is used: spend it on the close / 25 m read (bevels, tapers, more sides on the big curved masses, secondary shapes) _(from C2 Vertex use vs budget, shot close)_
6. **Silhouette area at 40 m** (PASS): Grow the read at 40 m (now 5776 px): push the key shape (weapon, horns, crest, back mass) 15-25 % bigger _(from R1 Silhouette area at 40 m, shot z40)_

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
| B1 | Meshes after the kit merge | INFO | 4 | no budget for building/hall |  |
| B2 | Draw instances at rest | PASS 100 | 4 | <= 32 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B4 | Vertices | PASS 100 | 3858 (biggest: Stone 3420, RuneStone 333, Shards 72, Contact 33) | <= 12000 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B5 | Real lights | PASS 100 | 0 | <= 0 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 90 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B7 | Shadow casters | INFO | 2 | no budget for building/hall |  |
| B8 | Unique materials | PASS 93 | 7 | <= 8 (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |
| B1a | Authored build parts (before the merge) | INFO | 9 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 4 surfaces over 4 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 104 of 1307 triangles (7%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |
| B13 | Frame cost | PASS 100 | 0.0 ms process per instance (8 animated at 40 m: +0.0 ms process, render CPU +0.04 ms, GPU +3.09 ms) | <= 0.05 ms per instance (art-keep.md 9 numbers, step-12/13 rules: 0 lights) |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.06 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 84 | 5776 px (126 x 116 bbox; 55 m: 3029 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 40.5, 0% of the body melts (within dE 15 of the ground); body L* 57.6 C 11.8 vs ground L* 64.0 C 48.9, hue gap n/a (body C* <= 25); top third (world height) dE 61.2, L* 53.7; per-pixel dE 46.0, outline 35.1 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 90 | worst heath: dE 15.8 (heath dE 15.8, old_wood dE 32.3, riverbank dE 33.6, snow dE 33.2, ash dE 35.4, sand dE 30.5, marsh dE 41.1) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5c | Glow points stand out (1 m surround) | PASS 92 | worst dL +30 (point 1 dL +30; ring 24 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 0 in the lit 40 m frame (WARN only) |  |
| R5 | Glow points at 40 m | **WARN** 49 | 1 point(s) above the bloom level 1.2 (median of 1/1/1): RuneStone; soft glows under the bloom (v1 count, luma > 0.4): 2 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it); 2 soft glow(s) sit under the bloom level: raise one to emission >= 2.4 |
| R2 | Distinct from references (black masks) | PASS 100 | max IoU 0.43 (essence_well 0.43, trade_post 0.19) | IoU <= 0.8 vs every reference (4 turns, 40 m), else colour must differ (dE >= 15) |  |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 42 | missing: set_team_color, set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Craft: shape and detail at the close-up / 25 m (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | Shape richness (secondary shapes) | INFO 24 | 87 shapes over 3 body parts (29.0 per part: (root) 68, Float 16, Orbit 3); 14% of the surface on plain boxes / prisms (<= 10 face directions); normal variety 0.777 | craft (lab v3.1): >= 7 separate shapes per body part, <= 35% plain boxes / prisms, normal variety >= 0.83 |  |
| C2 | Vertex use vs budget | INFO 68 | 31% of the 12000 verts budget used (3825) | craft (lab v3.1): a finished model uses >= 40% of its tier budget (under-use = detail left on the table; over is B4) |  |
| C3 | Palette depth (close-up) | INFO 83 | 12 colour steps (L*a*b* bins >= 2 % of the body), 7 value steps (L* bins of 8 >= 3 %) | craft (lab v3.1): >= 12 colour steps and >= 8 value steps at the close-up |  |
| C4 | Inner detail (close-up / 25 m) | INFO 93 | inner edges per outline px: 2.64 at the close-up (34140 px), 2.32 at 25 m; close-up outline complexity 7.24 | craft (lab v3.1): >= 2.5 inner edge px per outline px at the close-up, >= 2.5 at 25 m (shape and value breaks inside the silhouette) |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 6.15 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 15 | top third L* 53.7, bottom third L* 56.2 (-2, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 6.6 at 25 m, 9.3 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 100 | 1 of 1 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |
| S1 | Style bible: golden autumn (style-autumn.md 3) | INFO 44 | on the autumn floor: dE 24.7, 3% melts; body L* 53.8 C 18.7 vs floor L* 52.3 C 43.2 (inside the floor band) | units sit outside the autumn floor band (L* 25-55, C* <= 35): body vs floor dE >= 20, <= 35 % melting; team colour dE >= 20 to every floor swatch (INFO until the style-autumn.md 6 runs) |  |
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

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9 numbers, step-12/13 rules: 0 lights)
`{"draw":32,"frame_ms":0.05,"lights":0,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9 numbers, step-12/13 rules: 0 lights","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Stone 3420 v / 1 s; Float/RuneStone 333 v / 1 s; Float/Orbit/Shards 72 v / 1 s; Contact 33 v / 1 s
- 5 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- B13 over the budget on the first window (2.6212 ms): re-measured 0.0 ms, kept the lower
- Fix recipes: 2 in fixes.json (top: Glow points 1 -> 2 (want 2-4): add 1 glow point(s) high on the body (eyes / rune / weapon tip): an unshaded kit glow with energy >= 1.7 or emission x colour >= )
