# G2b - Water (river, moat, fords, river mouths, bridges)

Task G2b of the graphics block ("make the graphics as beautiful as possible"). Owner: tech-artist.
Painted, readable water from the RTS camera at zoom 10 / 30 / 50, driven by the graphics tier
(`GameSettings.effective_graphics_quality()`, 0 Low .. 3 Ultra).

## What changed

`art/environment/water/water.gdshader` (shared by `water_mat.tres`, `water_ford_mat.tres` and the river mouths' water)
keeps every 12.V1 / 12.V2 uniform RiverSystem and the materials set (`fords`, `ford_count`, `foam_rocks`,
`foam_rock_count`, `detail`, `noise_tex`, `flow_speed`, `foam_amount`, `shallow`, `channel_width`, colours). It stays
opaque (no screen or depth reads: the ground is discarded in the channel, so there is nothing real below the surface)
and flat (no vertex motion: lily pads, barge and wade ripples sit on it). New uniform `quality` (int) plus the tunables
`shallow_tint`, `bed_sand`, `bed_silt`, `sky_zenith`, `caustic_color`, `bed_depth`, `clarity`, `normal_strength`,
`reflect_strength`, `spec_strength`.

| Tier | Water |
|---|---|
| 0 Low | the 12.V1 look and cost exactly (flat surface, painted bands, ripple lines, glints, foam). No overlay pass. |
| 1 Medium | flow-mapped normals (2 noise layers in flow space: stretched along the river, scrolling downstream at two speeds; world basis from the UV.x screen gradient, so any mesh with the UV convention works, no tangents), painted sky reflection (reflected ray height -> horizon / zenith in 3 posterised steps, Schlick fresnel, a wobbly dark band of reflected bank inside each bank, tinted by the water so it never greys out), see-through shallows (a fake bed `bed_depth` m down with view parallax + normal refraction, absorbed with `clarity`, posterised: clear turquoise over sand / silt at the banks, the deep painted colour in the middle), the wet-stone waterline overlay on the crossings |
| 2 High | + caustic web and pebbles on the shallow bed, toon sun highlights (crisp flecks + a soft sheen in `light()`, warm from the sun colour), smooth surface (roughness 0.18, specular 0.04) so SSR mirrors bridges / banks / units when the lighting tier turns SSR on |
| 3 Ultra | + a third fine normal layer, stronger refraction wobble of the bed |

Details that fade with zoom: normal strength and the reflection amount drop as metres-per-pixel grows (no shimmer at
zoom 50), caustics fade with `fade_near`; reflection is weaker over the deep middle so the depth bands stay readable.

Bridges / fords / Crown Steps: `art/environment/bridges/waterline.gdshader` + `waterline_mat.tres`, a `material_overlay`
(multiply, unshaded, discards everything above the band) over the crossing bodies: dark teal-tinted wet band with a
ragged top and drips, a thin pale tide line, and (Medium+) light bounced off the moving water crawling on the stone just
above the surface. The body materials (`env_painted_mat.tres`, the lane bridge's) are untouched. `water_y` is an
instance uniform: -0.35 for road bridges, lane bridges and the Crown Steps, -0.15 for the ford stones (only their feet
look wet). Off on Low (no extra pass).

## Tier plumbing

`art/environment/water/water_quality.gd` (`class_name WaterQuality`):
- `apply(q)` sets `quality` on the shared materials (water, ford film, waterline) and the overlay on every node of
  group `"water_overlays"`; `current_tier()` reads `GameSettings.effective_graphics_quality()` through `load()`
  (default High without the settings script); `applied()`.
- `ensure()`: applies the current tier and adds one watcher node `/root/WaterQuality` (process ALWAYS) that re-reads
  the setting every 0.5 s, so a change in the settings menu reaches the water with no call from the menu or the
  lighting rig. Called by `WaterMeshes.channel_surface` (every water strip RiverSystem builds) and `RiverMouthsArt._ready`.
- `register_overlay(mesh_instance, water_y)`: used by `CrossingArt._ready` (road bridge, ford stones, Crown Steps)
  and `LaneBridgeArt._ready`.
- Labs: `pin(q)` / `unpin()` (the watcher leaves a pinned tier alone).
- `water.gdshader` defaults to `quality = 0`: water the tier never reaches keeps the Low (12.V1) look and cost.
  Materials covered: `water_mat`, `water_ford_mat`, `autumn/water_autumn_mat` (autumn_swap.gd), `waterline_mat`.
  The marsh puddles share `water_ford_mat` and are reached through the river's build (both marsh maps, Gloamspine
  Divide and Kinhearth Vale, have a river; the test fails if a marsh map without one appears). A handoff in
  `docs/handoff/for-tech-artist.md` gives the line for map_dressing_art.gd should one ever be made.
- The GameSettings script lookup is cached once (static), the 0.5 s poll is one static call.

Nothing in `scripts/` changed: RiverSystem's uniform names all still work, no handoff needed.

## Not done (and why)

- Unit wakes: units only enter water at the fords (deep water is not walkable) and the fords already get the 12.V1
  wade ripples (`MapFillVfx` + `wade_ripple_mat.tres`); a per-frame unit array into the shader was not worth its cost.
- Real refraction / depth colour from the depth buffer: the channel has no bed geometry (ground discarded, walls stop
  at -0.6), so a transparent surface would show the void; the parallax bed gives the look at a fraction of the cost and
  keeps the water opaque (SSR works on it, no sorting issues with the fog overlay or foam meshes).

## Measurements (RTX 3070 Laptop, 1920x1080, windowed, vsync off, other agents' Godot runs on the same PC = noisy)

Tool: `art/environment/water/water_shots.gd` (windowed `-s` script; quote the separator in PowerShell):

```
tools\godot_run.ps1 --path . -s res://art/environment/water/water_shots.gd --resolution 1920x1080 --quit-after 900000 '--' --gfx=high map=thornwater tag=after gfx-list=high,ultra shots fps
```

The camera is placed with the public `RTSCamera.fly_to(pos, 0, zoom, 0)`. `water-tier=0` renders the old (12.V1)
water for "before" shots; `fps` measures each tier at zoom 10 / 30 / 50 with
and without the water surfaces (`water_gpu_ms` = GPU time difference). Overlays (HUD, STR / INT pick) and fog are off.

Final runs (fps whole frame / water's own GPU ms; negative or tiny deltas = noise):

| Map | Tier | z10 | z30 | z50 |
|---|---|---|---|---|
| Thornwater | High | 177 fps / 0.9 ms | 153 / -0.1 | 129 / -0.5 |
| Thornwater | Ultra (after the Ultra stone simplification) | 95 / 2.0 | 108 / 1.3 | 100 / -0.8 |
| Crown Hollow | High | 99 / 1.1 | 80 / 1.3 | 81 / 0.5 |
| Crown Hollow | Ultra (before the stone simplification) | 57 / 1.9 | 54 / 0.8 | 57 / 0.4 |

Thornwater meets High >= 90 and Ultra >= 60. Crown Hollow misses both targets **without the water too** (no-water fps
85 at High z30, 57-64 at Ultra): the gap is the rest of the scene (G1 lighting / G2a ground and foliage, in progress in
parallel), the water costs 0.4-1.3 ms at High and up to ~2 ms at Ultra zoom 10 (the river filling half the screen).
Earlier "before" run (old water, same tool, before these changes): Thornwater High 46-53 fps, Ultra 34-51 fps; the
whole-scene numbers move a lot between runs on this shared PC.

Headless: `tests/test_g2b_water.gd` PASS, `perf_test` PERF OK, `smoke_test` victory=true, `test_ws_perf` PASS,
`test_12_v1..v5`, `test_12b_v5`, `test_12_c8` PASS.

## Shots (`docs/art/lab/g2b_water/`)

`<tag>_<map>_<spot>_z<zoom>.png`, spots `river` (mid-span), `bridge`, `ford`, `moat`; maps `thornwater`,
`crown_hollow` (both have the river and a Crown Isle moat); tags `before` (water tier 0 = the 12.V1 water, rest of the
frame at High), `after` (High), `ultra` (Thornwater at Ultra).
