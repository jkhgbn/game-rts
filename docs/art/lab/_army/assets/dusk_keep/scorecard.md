# Art Lab scorecard: dusk_keep

Scene `res://art/buildings/dusk_keep.tscn` · kind **building** / tier **keep** · kingdom shadow · ground meadow · 2026-09-27 10:13:47 · lab v2.0

## Result: **FAIL** · quality **86 / 100**

2 FAIL · 3 WARN · 14 PASS · 12 info · 0 skipped · 97 s

## Improve next
1. **Unique materials** (FAIL): B8 10 -> 8 materials: use one material for look-alike pairs: `Obsidian` -> `DarkStone` (dE 4.6), `Stone` -> `DarkStone` (dE 13.1) [fixes.json #1] _(from B8 Unique materials)_
2. **Draw instances at rest** (FAIL): B2 35 -> 31 (want <= 32): draw `LanternOrb*` (3 copies of one mesh) as one MultiMesh; draw `Banner*` (3 copies of one mesh) as one MultiMesh [fixes.json #2] _(from B2 Draw instances at rest)_
3. **Glow points at 40 m** (WARN): Glow points 43 -> 8 (want 4-12): Glow boost_mult 1.0 -> 0.09 (dim under the bloom level: 14 point(s), peak 8.0 x the level (>= 8, clipped)); Silver crack_strength 0.0 -> 0.0 (dim under the bloom level: 13 point(s), peak 6.9 x the level); Obsidian crack_strength 0.7 -> 0.07 (dim under the bloom level: 8 point(s), peak 7.47 x the level) [fixes.json #3] _(from R5 Glow points at 40 m, shot glow)_
4. **Team colours for colour-blind players** (WARN): R6cb Team colours for colour-blind players: For red-green colour-blind players fire / nature (deutan) look alike on this model (dE 7.6): add a value step inside the team-colour area [fixes.json #4] _(from R6cb Team colours for colour-blind players, shot teams)_
5. **Glow points stand out (1 m surround)** (WARN): R5c Glow points stand out (1 m surround): 3 glow point(s) barely stand out from their 1 m surround (worst dL +3): darken around them or raise the energy [fixes.json #5] _(from R5c Glow points stand out (1 m surround), shot glow)_
6. **Team-colour visibility at 40 m** (PASS): Give the team colour more top-facing area (now 17% of the 40 m body; aim ~20%): shoulder cloth, a banner, the cape top _(from R6 Team-colour visibility at 40 m, shot teams)_

## Health (errors, allocations, hooks)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H0 | Scene instantiates | PASS 100 | root Node3D, 52 nodes | instantiates without errors |  |
| B9 | Materials built per instance | INFO 100 | 9 material(s), 0 mesh(es) not shared by a 2nd instance (per-building copies, accepted by art-keep 8.6) | 0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6) |  |
| B10 | Allocations after _ready (actions) | PASS 100 | 0 node(s) created, net +0, 2nd action cycle: 0 node(s), 0 new material(s) | 0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new |  |
| H1 | Errors from the asset while running | PASS 100 | 0 error(s), 0 warning(s) | 0 (its folder + the kit) |  |

## Budgets
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Meshes after the kit merge | INFO | 32 | no budget for building/keep |  |
| B2 | Draw instances at rest | **FAIL** 13 | 35 | <= 32 (art-keep.md 9) | Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part |
| B4 | Vertices | PASS 100 | 4115 (biggest: Fins 576, RuneRing 343, Rubble 336, Thorns 288) | <= 12000 (art-keep.md 9) |  |
| B5 | Real lights | PASS 92 | 2 (SpireLight, GateLight) | <= 2 (art-keep.md 9) |  |
| B6 | Particle systems | INFO | 12 | no budget for building/keep |  |
| B6l | Looping particle systems | INFO | 3 | no budget for building/keep |  |
| B6p | Looping particles alive | PASS 89 | 84 | <= 90 (art-keep.md 9) |  |
| B7 | Shadow casters | INFO | 12 | no budget for building/keep |  |
| B8 | Unique materials | **FAIL** 8 | 10 | <= 8 (art-keep.md 9) | Snap to the closed palette (art-units 2.2); no per-part materials |
| B1a | Authored build parts (before the merge) | INFO | 34 | info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes) |  |
| B11 | Surfaces per instance | INFO | 32 surfaces over 32 meshes (each surface = 1 draw call) | about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes |  |
| B12 | Downward-facing triangles | INFO | 342 of 2722 triangles (12%) face steeply down (normal y < -0.7) | hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest |  |

## Readability at 40 m
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R9 | Ground contact | PASS 100 | lowest point -0.36 m | touches the ground (<= 0.05 m) and sinks < 1 m (art-keep 0.1 / 0.5) |  |
| R1 | Silhouette area at 40 m | PASS 100 | 61955 px (291 x 549 bbox; 55 m: 28404 px) | >= 5000 px (FAIL < 2000) at 1600 x 900 |  |
| R3 | Contrast vs ground (meadow) | PASS 100 | mean-colour dE 97.4, 0% of the body melts (within dE 15 of the ground); body L* 31.5 C 50.7 vs ground L* 57.4 C 43.8, hue gap 166 deg; top third (world height) dE 69.5, L* 34.4; per-pixel dE 101.2, outline 66.9 | mean-colour dE >= 14 and <= 35 % melting (FAIL: dE < 8 or > 60 % melting): the body must not melt into the grass |  |
| R4k | Contrast on the home ground (marsh) | PASS 100 | dE 56.6, 0% melts (marsh is where shadow units stand most) | dE >= 14 on the kingdom's own ground (WARN only; stand-in patch for snow / ash / marsh) |  |
| R4 | Contrast on the other grounds | PASS 100 | worst ash: dE 48.5 (heath dE 80.5, old_wood dE 69.3, riverbank dE 72.4, snow dE 77.5, ash dE 48.5, sand dE 90.3, marsh dE 56.6) | dE >= 8 on every skirmish ground (WARN only) |  |
| R6 | Team-colour visibility at 40 m | PASS 91 | 17% of body pixels change between kingdom colours (min pair 11%) | >= 3% (FAIL = set_team_color changes nothing) |  |
| R3t | Contrast in every team colour (meadow) | PASS 100 | worst nature colour: dE 86.6 (fire 88.5, shadow 97.3, ice 89.1, nature 86.6) | dE >= 14 in every kingdom colour (WARN only: mirror matches / enemy colours) |  |
| R6cb | Team colours for colour-blind players | **WARN** 40 | worst pair fire / nature (deutan): dE 7.6 on the team-colour area (normal vision 19.4; 14934 px); deutan: fire / nature dE 7.6; protan: fire / nature dE 9.3; worst vs ground: fire colour (deutan) dE 70.4 | deutan / protan simulation: the worst kingdom pair differs by mean dE >= 12 on the team-colour area and the body stays >= dE 8 from the ground (WARN only) | Red-green colour blindness merges hues, not values: give the team-colour area a value step or a pattern (trim, banner shape) and keep it large; a team-palette change is for the lead (KINGDOM_COLORS) |
| R5c | Glow points stand out (1 m surround) | **WARN** 59 | worst dL +3 (point 1 dL +22, point 2 dL +27, point 3 dL +38, point 4 dL +43, point 5 dL +43, point 6 dL +33, point 7 dL +30, point 8 dL +38, point 9 dL +52, point 10 dL +46, point 11 dL +25, point 12 dL +36, point 13 dL +25, point 14 dL +27, point 15 dL +48, point 16 dL +17, point 17 dL +22, point 18 dL +41, point 19 dL +46, point 20 dL +60, point 21 dL +19, point 22 dL +18, point 23 dL +35, point 24 dL +3, point 25 dL +26, point 26 dL +44, point 27 dL +26, point 28 dL +29, point 29 dL +73, point 30 dL +36, point 31 dL +58, point 32 dL +72, point 33 dL +57, point 34 dL +37, point 35 dL +24, point 36 dL +10, point 37 dL +65, point 38 dL +64, point 39 dL +22, point 40 dL +35, point 41 dL +66, point 42 dL +22, point 43 dL +44, point 44 dL +43, point 45 dL +18; ring 30 px = 1.0 m at 40 m) | each glow point's core L* >= the median L* of its 1 m surround + 18 in the lit 40 m frame (WARN only) | A point that does not stand out reads as a pale smudge: raise its emission or darken what is around it (socket, hood, dark trim) |
| R5 | Glow points at 40 m | **WARN** 49 | 43 point(s) above the bloom level 1.2 (median of 45/41/43): ShardSparks, WatchCollars x4, LanternOrb2, GateSlits x4, LanternOrb1, Banner2, LanternStems x2, RuneRing x2, LanternOrb3, Prism1 x4, BodyCap x3, Thorns, FinTips, Windows x2, Tip, Banner1 x2, WatchNeedle x6, Prism3 x3, ShardMesh, Prism2, GateFrame, 3 rim-light speck(s) ignored; soft glows under the bloom (v1 count, luma > 0.4): 46 | 4-12 above the bloom level (art-units 1.4 / art-keep 0.4) | Too many glow points read as noise: merge them or dim the small ones below the bloom level (1.2): ShardSparks, WatchCollars x4, LanternOrb2, GateSlits x4, LanternOrb1, Banner2, LanternStems x2, RuneRing x2, LanternOrb3, Prism1 x4, BodyCap x3, Thorns, FinTips, Windows x2, Tip, Banner1 x2, WatchNeedle x6, Prism3 x3, ShardMesh, Prism2, GateFrame |

## Animation
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Standard hooks | PASS 100 | all 5 present | set_team_color, set_selected, set_construction_progress, set_health_ratio, play_destroyed |  |

## Polish (scored, never fails)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | Silhouette hook | INFO 100 | outline complexity 9.52 | a blob is ~1.3-1.8; a strong hook >= 2.2 |  |
| P3 | Tops light, bottoms dark | INFO 83 | top third L* 34.4, bottom third L* 25.4 (+9, world height) | top lighter than bottom (art-keep 0.1: 0.72 x at the ground, 1.08 x at the top) |  |
| P4 | Detail density 25 m / 40 m | INFO 93 | inner detail 2.7 at 25 m, 4.5 at 40 m (mean /grad L*/ per px) | about 3-11 at 25 m: readable blocks, no noise |  |
| P5 | Glow placement | INFO 71 | 16 of 45 glow(s) in the upper half of the model's height (world) | one glow high (head / weapon / crest) reads over crowds |  |

## Shots
- z40: [z40.jpg](z40.jpg)
- z55: [z55.jpg](z55.jpg)
- z25: [z25.jpg](z25.jpg)
- close: [close.jpg](close.jpg)
- turns: [turns.jpg](turns.jpg)
- anim: [anim.jpg](anim.jpg)
- contact_sheet: [contact_sheet.png](contact_sheet.png)

## Budget used (`tools/art_lab/lab_budgets.gd`, art-keep.md 9)
`{"draw":32,"frame_ms":0.05,"lights":2,"materials":8,"n":8,"particles":90,"soft":{"runtime_mats":0},"src":"art-keep.md 9","verts":12000}`

## Notes
- Per-mesh vertices (biggest first): Model/Fins 576 v / 1 s x6; Model/RuneRing 343 v / 1 s; Model/Rubble 336 v / 1 s x14; Model/Thorns 288 v / 1 s x3; Model/SpireBands 216 v / 1 s; Model/WatchNeedle/WatchCollars 144 v / 1 s; Model/FinTips 144 v / 1 s x6; Model/Windows 144 v / 1 s x6
- 2 hidden parts at rest (toggled states, not counted as draws)
- 7 materials are built in code (fine when cached per type: see B9)
- terrain: snow / ash / sand / marsh are flat stand-in patches (biome GROUND_TINT): ground.gdshader has no step-12b terrain layers yet (terrain.md 7.1 `terrain_mask`); the lab switches to them by itself once they exist
- quick=1: light-preset sweep (R12) and style bible (S1) skipped
- quick=1: references (R2) and frame cost (B13) skipped
- Fix recipes: 5 in fixes.json (top: B8 10 -> 8 materials: use one material for look-alike pairs: `Obsidian` -> `DarkStone` (dE 4.6), `Stone` -> `DarkStone` (dE 13.1))
