# G2a - ground and foliage (2026-10-15)

Goal (JS: "make the graphics as beautiful as possible"): a richer ground from the RTS camera (zoom 10 / 30 / 50)
that keeps the painted, readable style. Units, selection rings and team colours must always read on it.

## What changed

| Piece | File | Tiers |
|---|---|---|
| Painted relief: dirt sits below the grass, ruts and river banks dip, plaza stones stand above their joints. The light ramp is shaded by that relief, so lips facing the sun are lit and the others are cool. It fades out when a pixel is wider than about 0.12 m. | `art/environment/ground.gdshader` (`relief`, `light()`) | High 0.22, Ultra 0.28, Low / Medium 0 (today's flat light, same code path) |
| Top-down bake modes: `bake_mode` 1 = unlit grass colour (biome tints, outer frame, cliff AO, no tufts or dirt); 2 = mask (R grass, G flower patches, B blade height x 0.5, sRGB-corrected) | `ground.gdshader` | used by GroundDetail only (default 0) |
| 3D grass field: wind-swept clumps of 7 tapered blades in a MultiMesh ring that follows the camera. The ring snaps to the clump grid, so blades never swim. Blades grow only where the ground paints grass and take its exact colour at the root, with warm/cool and value variety per clump, lit tips, darker roots and flower heads in the flower patches. Wind matches the trees. Units the player can see flatten the blades around them (enemies hidden in fog do not, so there is no info leak). Buildings and crystal nodes clear them. Blades fade with camera distance. | `art/environment/grass/ground_detail.gd` (`GroundDetail`), `grass_blades.gdshader`, `grass_clump.gd` (`GrassClump`) | Low: nothing (no bake, no node). Medium: 18 m ring, 0.40 m spacing. High: 24 m, 0.32 m. Ultra: 28 m, 0.29 m |
| Hook | `art/environment/map_dressing_art.gd` `_ready` -> `GroundDetail.ensure(level)` | Crown Hollow layouts today; every map once the main.gd hook lands (`docs/handoff/for-systems-coder.md`, "G2a ground detail hook") |
| Shots / fps tool | `art/environment/grass/g2a_shots.gd` | windowed; `'--' --map=crown|thornwater --gfx=high|ultra --tag=after [--fps] [--no-detail] [--gd-q=N] [--dump-bake] [--fog]` |
| Test | `tests/test_g2a_ground.gd` | prints `G2A_GROUND PASS` |

Tier = `GameSettings.effective_graphics_quality()` (load-guarded). GroundDetail is in the `lighting_rigs` group, so a
change in Settings reaches it through `apply_graphics` -> `set_quality(q)`. Headless runs and the sim mode never build
it. Low matches the lead's ruling: no grass density and no extra pass at Low. The ground shader's new code sits behind
uniform branches that stay off.

Readability: the blades take the ground's own colour (no new hues on the field), they are 0.36-0.42 m tall, and they
lie flat under and around every visible unit, so feet and selection rings stay clear. Dirt clearings, roads, plazas,
banks and building footprints have no blades at all.

## Bake cost (`GroundDetail.bake_stats()`, printed by g2a_shots.gd)
- Two renders of a 1000 x 1000 SubViewport (own world, ortho camera, the ground material with `bake_mode` 1 then 2). The
  game frames keep running during it. The only blocking steps are the two GPU readbacks (`get_image`): 52 ms in total
  on Crown Hollow, 61 ms on Thornwater. That is about 25-30 ms per frame, on 2 frames. With the main.gd hook it runs
  3 frames after the map builds, during "Baking pathfinding...", before the match starts, so no hitch reaches play.
- Wall time is 0.27 s on Thornwater. On Crown Hollow it is about 5 s, because it overlaps the level's own loading frames.
- VRAM kept: 2 RGBA8 textures of 1000 x 1000 without mipmaps = 7.6 MB. The SubViewport is freed after the bake.

## Lead review fixes (2026-10-15)
- Fog: units that flatten the grass must be `is_visible_in_tree()` (FogOfWar hides every enemy / neutral unit outside
  the player's sight). Buildings and crystal nodes clear grass only when they are shown now or were seen once (their
  ghost shows them anyway). A building never seen leaves no bald patch. `tests/test_g2a_ground.gd` checks this.
- Per-frame cost: pushers refresh every 0.1 s and clears every 0.5 s. Each refresh makes one pass over the group, keeps
  the nearest 48 / 32 entries in reused member buffers, and does no sort, lambda or per-refresh array.
- Map size comes from `MapInfo.half_x() / half_z()`; the ground uniforms are only a fallback.

## Rejected after measuring
- A far ring of bigger clumps (spacing x2, size x1.55, out to 46 m) cost +18 ms GPU at zoom 50 at High. Blades 1-2 px
  wide are micro-triangles under MSAA. Replaced by the camera-distance fade: High 36 -> 50 m, Ultra 38 -> 52 m. At
  zoom 50 the painted 2D tufts carry the look, as before.
- Ultra with a 30 m ring, 0.26 m spacing and a fade out to 58 m: +16 ms at zoom 30 under 8x MSAA. Cut to 28 m / 0.29 m /
  52 m.

## Shots (`docs/art/lab/g2a_ground/`)
`before_*` = before this task. The Thornwater before shots use `--no-detail`. `after_*` = the final state. Crown Hollow
(`scenes/skirmish.tscn`) views: `z10` / `z30` / `z50` by the player keep, `meadow30` / `meadow10` west meadow, `centre45`
Crown Isle. Thornwater (`LayoutLevel` + `data/maps/thornwater_layout.tres`) views: `z10` / `z30` / `z50` / `centre45`. All
at 1920x1080, HUD hidden, fog off. The biggest difference shows in `after_crown_high_meadow10` / `meadow30` against the
before shots, and in `after_thornwater_high_z30`.

## FPS (1920x1080, vsync off, RTX 3070 Laptop, real-time match, 900 frames per view; avg / 1 % low, GPU ms)
Other agents' Godot runs (up to 4) shared the machine, so the runs were noisy. The GPU ms of A/B runs (`--gd-q=0` =
detail off, same build) is the fairest comparison.

| Map / tier | View | Detail off | Detail on (final) |
|---|---|---|---|
| Crown High | z30 | 101 / 87 fps, 8.3 ms | 126 / 111 fps, 7.7 ms |
| Crown High | z50 | 85 / 74 fps, 10.4 ms | 102 / 76 fps, 10.4 ms |
| Crown High | z10 | 109 / 91 fps, 7.7 ms | 110 / 95 fps, 8.7 ms |
| Crown Ultra | z30 | 67 / 55 fps, 12.8 ms | 87 / 61 fps, 10.7 ms |
| Crown Ultra | z50 | 55-63 / 48 fps, 15.9 ms | 76 / 56 fps, 15.1 ms |
| Crown Ultra | z10 | 46-63 / 25-41 fps, 12-17 ms | 67 / 56 fps, 14.2 ms |
| Thornwater High | z30 / z50 / z10 | - | 72 (one load spike) / 111 / 127 fps, 6.9 / 8.6 / 6.3 ms |

Target High >= 90 and Ultra >= 60 average: met in the final runs. The grass costs about 0-1 ms of GPU. Ultra's 1 % low
sits near 55-61, set by 8x MSAA and the G1 lighting, not by the ground. Headless gates: `perf_test` PERF OK (norm
5.59 / limit 6.72), smoke `victory=true`, `test_ws_perf` PASS.

## Ideas not done (next)
- Main.gd hook for all maps (handoff above). Until then only Crown Hollow layouts get grass and relief.
- Trees: backlit leaf translucency and bigger leaf-cluster silhouettes. The wind and moss already exist
  (`nature_props/nature_painted.gdshader`).
- Pebble / stone 3D scatter on the dirt at Ultra, and blades trampled along heavily used paths (a decaying trample map).
