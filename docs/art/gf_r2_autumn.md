# G-F review 2, items 2 and 10: autumn ground + fog, Ashwind forest and Muster Pad yards (2026-10-15)

Review: `docs/art/gf_review2.md` items 2 and 10. Shots: `docs/art/lab/gf_r2_autumn/` (contact sheet
`gf_r2_contact_sheet.jpg`, before = the round-2 review shots, after = `after/`; 4 key PNGs). Test:
`tests/test_gf_r2_autumn.gd` (`PASS gf_r2_autumn`).

## Item 2: autumn maps were one ochre colour

| | Before | After |
|---|---|---|
| Grass (`grass_dark` / `grass_light`) | umber (0.26, 0.23, 0.13) / ochre (0.45, 0.39, 0.20), hue ~45 deg | olive (0.32, 0.35, 0.20) / dry olive (0.52, 0.56, 0.32), hue ~70 deg, s <= 0.45 |
| `grass_warm` / `grass_dry` / `grass_cool` | russet / straw / green | gold-olive (0.54, 0.52, 0.30) / pale dry (0.58, 0.56, 0.38) / (0.25, 0.32, 0.19) |
| Biome tints (meadow, heath, old wood, riverbank) | ochre, bracken red, litter, olive | olive, gold-olive, litter, green-olive |
| Dirt / road | (0.42, 0.33, 0.23) / (0.50, 0.40, 0.30), value = the grass | red-brown (0.31, 0.20, 0.14) / (0.33, 0.22, 0.155), hue ~20 deg |
| Value gap grass mean -> dirt / road | ~0 | 0.15 / 0.13 (test: >= 0.12) |
| Edge haze (`haze_color`) | (0.62, 0.52, 0.42) | (0.68, 0.64, 0.57) |
| Depth fog (`world_env_autumn.tres`) | begin 85 m, density 0.6, colour (0.90, 0.75, 0.56), sun scatter 0.25 | begin 80 m, density 0.3, colour (0.84, 0.81, 0.74), scatter 0.12, aerial 0.22 |
| Sky horizon | (0.94, 0.77, 0.54) | (0.92, 0.82, 0.66) (less orange sky ambient) |
| Screen haze (`preset_autumn.tres`) | (0.98, 0.86, 0.66) x 0.16 | (0.95, 0.90, 0.80) x 0.09 |

The orange lives in the tree crowns (nature_autumn, unchanged), the fallen leaves (`flower_b` / `flower_d`) and the
heath bracken accents (`heather_color`). Files: `art/environment/autumn/autumn_ground_params.gd`, `world_env_autumn.tres`,
`preset_autumn.tres`. Colour values only: the same cost at every tier. test_20_v0 still passes (grass mean L* 47.9,
min team-colour dE 39.6 Nature).

## Item 10: Ashwind Reach forest grid and grey pads

**Forest.** The grid is not map data: `WaveStrikeLevel._add_ws_block` (scripts/world, systems-coder) plants each forest
block on a 4.6 m grid with +-1.6 m jitter. The art replants it: `art/environment/lane_dressing/forest_replant.gd`
(LevelLooks, windowed runs, after `EnvProps.commit()`) rebuilds EnvProps' three tree MultiMeshes once: instances inside a
forest block (+1.8 m) are dropped, and per block it plants
- a treeline along the lane-facing edge (2.3-4 m spacing, 0.2-2.4 m deep, mostly mid / large trees; the test keeps every
  gap < 5.5 m, so the block still reads as a wall, never a walkable gap),
- 1-2 glades (r 3.5-6 m) at least 7 m back from the lane,
- clusters (one dominant species, sigma 2-3.6 m) and a few lone trees up to 1.1 x the level's grid count,
- three sizes: small 0.72-0.92, mid 1.05-1.28, large 1.45-1.78 (the level drew 0.9-1.5 uniform).
Same meshes, same draws, ~10 % more instances, no runtime cost: every tier gets it. Deterministic (seeded by the block
rectangle). Colliders and navmesh are the level's block boxes, untouched. Result: 534 trees in 8 blocks, 31 % of the
4.6 m cells empty (the old grid ~0 %).

**Pads.** The plate is drawn by `scripts/ui/wave_strike/pad_view.gd` (ui-coder): not art-owned. Art side:
- LaneDressing `_muster_pads()`: a broken flagstone apron 0.4-2.2 m outside each plate's rim (~40 flags, a few kerb
  stones) and a banner at each corner (the outer ones clamped inside the map edge). Existing kinds only: still <= 18 draws.
- A ready plate material, `art/environment/lane_dressing/muster_plate_mat.tres` (`muster_plate.gdshader`: lit worn
  sandstone flags, one per 1.5 m cell, earth joints, moss, split flags; the view's vertex colour as a value multiplier).
  Request to use it in `_build_plate`: `docs/handoff/for-lead.md` ("G-F r2 item 10").
The banners are the shared ochre / ash-red lane banner (no per-kingdom mesh yet).

## Checks
`test_gf_r2_autumn`, `test_20_v0`, `test_gd_autumn_maps`, `test_ge_fixes_b` (fog start), `test_ge_fixes_c` (lane
dressing), `test_shader_lint`, `test_ge_additive_fog`: PASS. Smoke: victory=true. test_ws_perf: see the report (headless:
none of this code runs there except the colour uniforms).
