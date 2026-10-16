# G-F round 3 leftovers: Ember Hall chimney mouth + no grass on site pads

Date 2026-10-15, tech-artist. Follow-up of gf_review3 ("black square pit" on the Ember Hall chimney) and gf_r3_sites
(grass blades poking through the site pads).

## 1. Ember Hall chimney mouth (`art/buildings/fire_hall.gd`)
Problem: the crown was a capped 4-sided dark frustum (mat_dark) that covered the coal bed, so from above it read as
a flat black square.

Fix: the crown is now an open mouth.
- Octagonal collar `_cyl(1.45, 1.05, 0.55, 8)` and a rounded stone lip (TorusMesh, inner 0.95 / outer 1.5), both in a
  lighter stone.
- Pit floor: its own dim rune_glow channel, `CHIMNEY_PIT_COLOR` (0.25, 0.07, 0.03) (the crucible's `ec_pit` colour),
  energy 0.7. Its peak value stays about 0.3, far under the glow caps.
- The round coal bed (r 0.62) and the clinker lumps sit on the floor; the horns are unchanged.

Site readability: the pad and the scaffold must dominate below about 50 %.
- `site_glow_k()` = smoothstep(0.4, 0.6, progress). `_apply_site_glow()` multiplies the body's `crack_energy` (the lava
  lines and cracks of `fire_painted_vc`) by it, so a 30 % site has no orange veins and they come back by 60 %.
- `ChimneyTop` is hidden on a site below 85 % (`SITE_CROWN_AT`). Without this, a squashed glowing mouth sits near the
  ground. Once the hall is built, `_apply_health` owns the crown again (hidden below 50 % HP, as before).

## 2. No grass under site pads
Problem: `GroundDetail` cleared a circle (target_radius + 0.3) round each building, which left blades at the
rectangular pad's edges and corners.

Fix:
- `SiteOutline.make_pad` puts a `_grass_clear_rect` meta on the SitePad: (min x, min z, max x, max z) in pad space,
  from `SiteOutline.pad_rect(half, stakes)`. It covers the pad, the stakes and the cords.
- `GroundDetail.site_pad_box(b)` reads that meta when the pad is visible. It turns the 4 corners into a world AABB,
  so rotated models work too.
- `refresh_clears` pushes that box as `(cx, cz, hx, hz)` with w > 0 instead of the circle. Once the building is
  finished, the pad is hidden and the circle comes back.
- `grass_blades.gdshader`: a clear with w > 0 is a box (rounded-box distance), otherwise the old circle. Both use the
  same 0.7 m soft edge.

Cost: the same 0.5 s CLEAR_INTERVAL refresh, nothing per frame. Low and headless are unchanged (no blade rings are
built there).

Bug fixed on the way: the pad's stake cords used `Basis.scaled()`, which scales along the global axes. The Z cords
were stretched about 7 m along X, which made the stray long thin lines in the r3 site shots. They now use
`scaled_local()`.

## Files
- `art/buildings/fire_hall.gd`, `art/buildings/site_outline.gd`
- `art/environment/grass/ground_detail.gd`, `art/environment/grass/grass_blades.gdshader`
- `tests/test_gf_r3_leftovers.gd`
- Shots: `docs/art/lab/gf_r3_leftovers/`
  - `leftovers_sheet.jpg`: before / after rows of the 0 % edge, 0 %, 30 % and 50 % sites, plus the built chimney
    (after only)
  - 4 key PNGs
  - `tools/leftovers_shots.gd` (windowed, `'--' --gfx=high --tag=<before|after>`) and `tools/leftovers_sheet.py`

The old "before" run set the built hall to progress 1.0 without HP, so it showed the < 25 % damage look with the
crown hidden. The shot script now sets HP with progress. The chimney therefore has no valid before shot; gf_review3's
report holds the "black square" view.

## Tests
- `tests/test_gf_r3_leftovers.gd` checks:
  - the mouth geometry, with top-down rays that hit the glow floor or coals in at least 60 % of samples;
  - the pit stays dark ember red;
  - the cold 30 % site;
  - the pad rects;
  - `site_pad_box` on a rotated pad;
  - box clears while a site and a circle once built;
  - the shader box branch.
- These also pass: test_gf_r3_sites, test_gf_site_outline, test_gf_r3_fire_keep, test_gb_fire, test_g2a_ground,
  test_gf_billboard_scale, test_shader_lint, test_ge_additive_fog, test_gf_shadow_leftovers, test_gf_r2_fs.
