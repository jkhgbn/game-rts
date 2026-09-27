# Art Lab scorecard: watchtower

Scene `res://art/buildings/capture/watchtower/watchtower.tscn` · kind **building** / tier **small** · kingdom neutral · ground meadow · 2026-09-27 10:30:31 · lab v2.0

## Result: **WARN** · quality **90 / 100**

0 FAIL · 3 WARN · 12 PASS · 9 info · 0 skipped · 16 s

## Improve next
1. **Glow points at 40 m** (WARN): Glow points 0 -> 2 (want 2-4): watchtower_contact_mat emission x 3.31 (raise over the bloom level: brightest soft glow 0.39 x the level; no energy parameter found: scale its emission colour / strength); watchtower_mat emission x 3.85 (raise over the bloom level: brightest soft glow 0.34 x the level; no energy parameter found: scale its emission colour / strength) [fixes.json #1] _(from R5 Glow points at 40 m, shot glow)_
2. **Vertices** (WARN): B4 7006 -> 5949 (want <= 6000): `Structure` 6911 -> 5854 verts (fewer segments: cylinders 6-8, spheres 10 x 5; drop hidden / bottom faces) [fixes.json #2] _(from B4 Vertices)_
3. **Standard hooks** (WARN): A1 Standard hooks: Implement set_construction_progress, set_health_ratio, play_destroyed [fixes.json #3] _(from A1 Standard hooks)_
4. **Tops light, bottoms dark** (INFO): Lighten the top masses / darken the legs and base (top - bottom now +6 L*, aim >= +10) _(from P3 Tops light, bottoms dark, shot z40)_
5. **Contrast on the other grounds** (PASS): On ash the body drops to dE 16.9: add a value accent that separates it there too _(from R4 Contrast on the other grounds, shot z40)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 8 nodes | instantiates without errors |  |
| B9 | Materials built per instance | PASS 100 | 0 material(s), 0 mesh(es) not shared by a 2nd instance | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 3 | no budget for building/small |  |
| B2 | Draw instances at rest | PASS 100 | 3 | <= 16 soft (lab default (towers, walls, posts): half a keep) |  |
| B4 | Vertices | **WARN** 43 | 7006 (biggest: Structure 6911, Banner 91, ContactDecal 4) | <= 6000 soft (lab default (towers, walls, posts): half a keep) | Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces |
| B5 | Real lights | PASS 100 | 0 | <= 0 (lab default (towers, walls, posts): half a keep) |  |
| B6p | Looping particles alive | PASS 100 | 0 | <= 40 soft (lab default (towers, walls, posts): half a keep) |  |
| B7 | Shadow casters | INFO | 2 | no budget for building/small |  |
| B8 | Unique materials | PASS 95 | 5 | <= 6 soft (lab default (towers, walls, posts): half a keep) |  |
| B1a | Authored build parts (before the merge) | INFO | 6 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 3 surfaces over 3 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 600 of 4512 triangles (13%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.24 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 23793 px (183 x 250 bbox; 55 m: 11737 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 50.5, 1% of the body melts (within dE 15 of the ground); body L* 36.4 C 13.5 vs ground L* 61.4 C 50.6, hue gap n/a (body C* <= 25); top third (world height) dE 49.1, L* 40.2; per-pixel dE 53.7, outline 35.2 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4 | Contrast on the other grounds | PASS 92 | worst ash: dE 16.9 (heath dE 23.6, old_wood dE 17.7, riverbank dE 24.6, snow dE 54.6, ash dE 16.9, sand dE 48.1, marsh dE 19.2) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility | INFO | neutral / no set_team_color | kingdom units only |  |
| R5 | Glow points at 40 m | **WARN** 49 | 0 point(s) above the bloom level 1.2 (median of 0/0/0); soft glows under the bloom (v1 count, luma > 0.4): 0 | 2-4 above the bloom level (art-units 1.4 / art-keep 0.4) | Add a glow point (eyes / rune / weapon, emission >= 2.5 so the bloom carries it) |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | **WARN** 49 | missing: set_construction_progress, set_health_ratio, play_destroyed | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed | Add the missing hooks (gameplay calls them through has_method; missing = no animation) |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 3.59 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 70 | top third L* 40.2, bottom third L* 33.3 (+6, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 100 | inner detail 3.9 at 25 m, 5.8 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, lab default (towers, walls, posts): half a keep)
`{"frame_ms":0.05,"lights":0,"n":8,"soft":{"draw":16,"materials":6,"particles":40,"runtime_mats":0,"verts":6000},"src":"lab default (towers, walls, posts): half a keep"}`

## Notes
- Per-mesh vertices (biggest first): Body/Structure 6911 v / 1 s; Body/Banner 91 v / 1 s; Body/ContactDecal 4 v / 1 s
- 3 hidden parts at rest (toggled states, not counted as draws)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 3 in fixes.json (top: Glow points 0 -> 2 (want 2-4): watchtower_contact_mat emission x 3.31 (raise over the bloom level: brightest soft glow 0.39 x the level; no energy parameter fou)
