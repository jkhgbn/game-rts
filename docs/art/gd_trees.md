# G-D - trees and bushes (2026-10-15)

Goal (JS: "make the graphics as beautiful as possible"): trees cover most of the screen, so the forests should look
lush and painterly at zoom 30-40 and zoom 10. This pass rebuilds the tree and bush MESHES. The shared painted
material (`nature_mat.tres`, `nature_painted.gdshader`) was upgraded by G-D props (`docs/art/gd_props.md`). This pass
adds only a small crown rustle to it.

## What changed
Builder: `art/environment/nature_props/build_nature.gd`. Run it with the new `trees` mode:

    & tools\godot_run.ps1 --headless --path . -s res://art/environment/nature_props/build_nature.gd --quit-after 600 '--' trees

`trees` rebuilds `meshes/tree_{pine,fir,broadleaf,birch,gold}.res` (+ `_v0/_v1/_v2`) and `meshes/decor_bush.res`,
`decor_bush_berry.res`. It does not touch the materials, the `tree_*.tscn` scenes (they still point at the same
`.res`), the far stand-ins, rocks or pillars. A run without `trees` still rebuilds everything, as before.
**Caveat:** `build_env.gd` still has its old decor bush code. A FULL `build_env.gd` run (not `-- edge` / `-- ruins`)
puts the old bushes back. Re-run `build_nature.gd -- trees` after it.

| Piece | Before (A2.8) | After |
|---|---|---|
| Broadleaf / birch / gold crowns | 4-7 faceted balls (7 x 4 segments), normals bent to one crown centre | 4-5 main **leaf puffs** (10 x 5 staggered rings, 5 soft lumps each, so one puff already has an uneven, clumpy outline) + 1 smaller puff per lobe on its outer side, which scallops the silhouette. Baked shade: each puff is darker underneath (its own shadow side), and the vertices that run into a neighbour puff are darker (baked crevice occlusion), so every lobe has a soft dark seam instead of melting into one blob. Lower / inner puffs darker, upper / outer ones lighter. Normals are bent less toward the crown centre (0.42 instead of 0.62), so each lobe has its own lit and shadow side. |
| Pine / fir tiers | Star-edged cones ("paper plates") | **Clumped tiers**: 6-9 rounded needle bunches per tier. Each bunch is a convex lobe (a raised ridge out to a drooping tip between two shoulders), with a dark notch between bunches. Tip length and droop vary per bunch. Baked shade: notches and undersides dark, ridges and tips light. |
| Trunks | Tapered cylinder + 5 wedge roots | One **lathe trunk with a root flare**: the foot swells and splits into 3-5 buttress ribs at the ground line, with a slight bow. Plus 3 small surface roots. Birch keeps its pale bark kind. |
| Decor bushes (legacy map decor) | 5 / 4 faceted balls on `env_painted_mat.tres` (540 / 864 vertices, 180 / 288 triangles, flat shaded) | 4 puffs at the lower 8 x 4 resolution, no satellite puffs (map-wide decor that casts shadows: <= 2x the old triangles), on the shared nature material (136 / 276 vertices, 256 / 480 triangles): painted crown shading, wind, per-instance hue. Sunk 4 cm into the ground (map_dressing_art places them at y 0 with no contact disc). Kind `IVY`, so they never take the 12 % autumn crown on green maps. The berry bush has 14 small berries. |
| Crown rustle (`nature_painted.gdshader`, Medium+) | - | In `vertex()`, behind `if (gd_detail > 0.5)`: a slow wave across the crown (about one puff per half wavelength) makes neighbouring clumps swell and lean out of step, instead of the crown moving as one block. Needle tiers move half as much. Tree crowns only: the amplitude ramps in with `smoothstep(1.6, 2.6, UV.y)` (local height), the same 1.6 m line nature_autumn uses for low leaf geometry, so grass tufts, ferns, reeds and bushes on the shared material keep the old motion. No new uniform (its size is `flutter_strength`). The same block is copied into `autumn/nature_autumn.gdshader` (test_20_v0 PASS). Low keeps the old vertex path and cost. |

The 3 shape variants per species are kept (pine: classic / tall slim / old bushy with a broken top; fir: spire /
twin leaders / windswept; broadleaf: round oak / tall oval / wide spreading on a forked trunk; birch: single / twin
/ leaning; gold: dome / layered / small crooked). Per-instance colour, crown height, lean and the rare autumn crown
come from the shader (world-position hash, no instance data), as before. The autumn swap (`AutumnSwap`) works on the
new meshes unchanged: see the autumn grove shot.

Not done: no dead / Shadow-blighted tree. No biome set or map places one, and a new kind would need a placement
change in `scripts/world/` (not owned here). Willows (`biomes/riverbank`) and the far stand-ins (border forest) are
unchanged.

## Contracts kept
- Same mesh paths and names (`meshes/tree_*.res`, `_v0.._v2`, `decor_bush*.res`). EnvProps, map_dressing, World
  Forge kits and the menu diorama load them unchanged. Same 2 surfaces for trees (nature + contact disc), 1 for bushes.
- No collider, physics node, nav layer or footprint changed. The tree colliders are the map's own (r 0.45 s, h 2,
  `main.gd` / `skirmish.gd`), and the scenes stay mesh-only (test_gd_trees checks this). The MultiMesh layout is the
  same: EnvProps builds it from the same transforms.
- Every variant still sinks 0.16-0.23 m into the ground (test_a2_8).

## Cost
Vertices per mesh (what one MultiMesh instance runs through the vertex shader: the combined mesh carries all 3
variants, the hidden ones collapse to a point):

| Mesh | Before | After | Ratio | Triangles before -> after |
|---|---|---|---|---|
| tree_pine | 706 | 1287 | 1.82x | 862 -> 1592 |
| tree_fir | 782 | 1455 | 1.86x | 958 -> 1800 |
| tree_broadleaf | 726 | 1370 | 1.89x | 1220 -> 2480 |
| tree_birch | 484 | 898 | 1.86x | 848 -> 1620 |
| tree_gold | 564 | 1015 | 1.80x | 954 -> 1820 |
| decor_bush | 540 | 136 | 0.25x | 180 -> 256 |
| decor_bush_berry | 864 | 276 | 0.32x | 288 -> 480 |

Primitives in frame (Crown Hollow, all passes): full map 3.01 M -> 3.22 M (+7 %) at High, forest zoom 30
2.58 M -> 2.84 M (+10 %). Draw calls unchanged (1160 / 918): same MultiMeshes, same materials.

FPS: Crown Hollow, 1920x1080, vsync off, RTX 3070 Laptop, 900 frames per view. Interleaved before / after pairs in
one build (`gd_trees_shots.gd --fps`, `--trees=<old meshes>` for before; the crown rustle is in both, it is a
shader change). The machine was shared with other agents' Godot runs (perf_test, a balance match, an Art Lab batch),
so single runs swing from 60 to 116 fps. These pairs were measured before the review fixes, with the heavier first
bushes (568 / 988 triangles), so the final cost is a little lower. Medians of 3 pairs, avg fps (GPU ms):

| Tier | View | Before | After |
|---|---|---|---|
| High | full map, zoom 55 | 67.1 (12.96) | 77.7 (12.72) |
| High | forest, zoom 30 | 67.8 (12.86) | 76.7 (12.21) |
| Ultra | full map, zoom 55 | 82.6 (12.51) | 82.9 (10.83) |
| Ultra | forest, zoom 30 | 66.6 (14.19) | 78.8 (14.61) |

The quietest pair (High pair 3): full map 110.0 -> 111.3 fps, forest 103.5 -> 116.1 fps (GPU 8.13 -> 8.07 ms and
9.35 -> 7.93 ms). No regression can be measured above the noise: the added cost is vertex work (about 600 more
vertices per tree instance, in 6 passes), small next to the fragment shading. Re-measure on a quiet PC if a
number is needed for the release notes.

## Shots (`docs/art/lab/gd_trees/`, `.gdignore`)
Tools (windowed):
- `art/environment/nature_props/gd_trees_shots.gd`: `'--' --map=crown|thornwater|quartermeet --gfx=high --tag=..
  [--trees=<folder>] [--fps] [--no-shots]`. Views: `forest30` / `forest10` (the densest tree group in the play area),
  `edge30` / `edge10`, `full55`. `--trees=<folder>` swaps every mesh whose file exists in that folder (the pre-G-D
  meshes, kept outside the project), so before / after run in ONE build, interleaved.
- `art/environment/nature_props/gd_trees_lineup.gd`: the 5 species x 3 variants, the bushes and a 70-tree mixed grove
  (the map's pine / broadleaf / fir pick) on the painted ground under the lighting rig. `--autumn` applies AutumnSwap.

Committed: `gd_trees_contact.jpg` (before | after: Crown Hollow forest zoom 10 and 30, Thornwater forest zoom 30,
broadleaf variants, pine / fir variants, mixed grove zoom 30, autumn grove zoom 30) and 4 key PNGs
(`after_crown_high_forest30.png`, `lineup_after_high_grove30.png`, `lineup_after_autumn_high_grove30.png`,
`lineup_after_high_broadleaf.png`). The other PNGs stay local.
Quartermeet (catalog biome "autumn") renders green in game: no level calls AutumnSwap today, so the autumn look is
shown with the lineup's `--autumn`.

## Tests
- `tests/test_gd_trees.gd` (new): PASS. Every tree mesh, variant mesh, far stand-in and decor bush exists, is on the
  shared nature material (+ the contact disc for trees), and stays <= 2x its vertex count before G-D trees (table in
  the test). The tree scenes stay mesh-only (no physics node, light or script) and point at their `.res`.
  `gd_detail` defaults to 0, and the crown rustle sits behind `if (gd_detail > 0.5)`. Bushes: triangles <= 2x the
  old ones and bottom y <= -0.03 (no floating). `-- --report` prints the counts.
- `tests/test_a2_8.gd`: triangle budgets of the 5 tree meshes raised (whole mesh / one variant: pine 1750 / 700, fir
  1950 / 760, broadleaf 2650 / 900, birch 1800 / 680, gold 2000 / 720). The vertex budget is test_gd_trees. PASS.
- PASS: smoke (`victory=true`), test_ws_perf (budget scaled by load x2.17), test_gd_props, test_shader_lint (rule A
  0 / rule B 0), test_20_v0, test_10_v10, test_g2a_ground, test_12_v3 / v5-v14 / v24 / v32 (map dressing, river,
  navmesh v13 / v14), test_12b_v2-v5, test_map_p3.
- perf_test: norm 7.13, then 7.16 against a limit of 6.72, with 3-4 other Godot runs on the machine (load x1.26 on
  its own calibration). perf_test is headless, so no tree is drawn there; the meshes only load once. G-D props saw
  the same 6.86-7.01 under load before this pass. Re-run it on a quiet PC.

## Next ideas
- The pine / fir leader spike (a 5-sided cone) still reads as a flat paper point at zoom 10. A small clump tier
  costs ~55 vertices per variant, which is over the 2x budget for pine / fir.
- Willows (`biomes/riverbank/build_riverbank.gd`) could get the same puff crown on top of their curtains.
- The far stand-ins could use 3 lumpy puffs (same triangle count) so the border forest matches.
