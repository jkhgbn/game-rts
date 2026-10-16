# G-F Shadow leftovers: Night Spire slate crown, calm site outline (2026-10-15)

Two items left by `docs/art/gf_r2_buildings_fs.md` ("Not done") from `docs/art/gf_review2.md` item 3 / 8.
Shots: `docs/art/lab/gf_shadow_left/` (contact sheet `gf_shadow_left_contact_sheet.jpg`, keys
`gf_shadow_left_key_*.png`, raw `before/` and `after/`), windowed `--gfx=high`, Shadow vs Shadow skirmish:
`tools\godot_run.ps1 --path . -s docs/art/lab/gf_shadow_left/tools/gf_shadow_left_shots.gd --resolution 1600x900
--quit-after 300000 '--' --gfx=high --tag=after` (`--legacy_outline` puts the old outline back at run time; the
"before" tower shots were taken with the old collar line restored for that one run). Sheet:
`docs\art\lab\gf_shadow_left\tools\gf_shadow_left_sheet.ps1`.

## Night Spire crown (`art/buildings/shadow_tower.gd` `_crown_roof`)

The collar was one team-coloured hex frustum with a flat top: a violet slab at close zoom. It is now a slate crown
in the Gloom Hall / Hovel style, still the part named `Body/Collar` (hidden on collapse, rises with the build):

- a dark corbel flaring out of the needle and a stone core under the slates;
- a thick dark eave board (the roof edge has a thickness from above);
- a six-sided slate skirt (`ROOF` = eave radius 1.04, top radius 0.42, eave y 3.86, rise 0.42; 4 courses): single
  slates about 0.2 m wide, every other row offset half a slate, tilted 6 deg flatter than the face (a shadow line
  per row), three team shades (dark x0.74, mid x0.87, team) with a lighter row every other course, sawtooth eave;
- dark hip ribs (ridge caps) on the six corners;
- a dark socket ring the orb floats in, with six short silver spikes (the spire cap). The fins now grow out of
  the slates.

Draw cost: the collar was one `_part`; it is now one merged mesh (`_merged`), one surface after the vc_merge painted
pass, so no new draw call (Art Lab B2 11 draws at rest, soft budget 16). `_vc_team` adds the two darker team shades
so the mirror colour follows (and ShadowDress grades them like the Hovel). Every tier (geometry only, no new pass).

## Calm construction outline (`art/buildings/site_outline.gd`)

What draws it: the art models' own `BuildOutline` (art-keep 8.2: four emissive rune_glow bars round the footprint,
energy 2, 1 Hz pulse, the full team glow), shared by every kingdom in `SmallBuildingModel`
(`hearth_small_building.gd`) and `FireHallModel` (`fire_hall.gd`). New opt-in `outline_calm` on both bases
(`SiteOutline`): bars half as wide (0.1 / 0.125 m), energy 0.45 (albedo ~0.8 x colour instead of ~2.4 x), a slow
1.6 rad/s breath, and the team glow graded like the Dusk Keep lights: hue kept, saturation <= 0.4, value <= 0.7 (for
every team colour, set on each `set_team_color`). Set by the Shadow models: Night Spire, Hovel, Gloom Hall (so the
Gloom Forge, Gloom Bazaar and Dread Paddock), Gloom Stables. Fire / Ice / Nature keep the default outline.

Second line (not art): `Building._build_outline()` (`scripts/buildings/building.gd`) also draws a 0.1 m unshaded
square in the full team colour under every site, model or not; on Shadow sites it is now the brighter of the two
(the inner square in `site_tower_p000_z12`). Request for the lead / systems-coder in `docs/handoff/for-lead.md`
(hide it when the model draws its own site, or grade it the same way).

Not touched (particles, another agent's pass): the Shadow BuildRing motes. The Dusk Keep's own `Outline` node
(keeps are rarely sites) keeps its look.

## Art Lab (windowed rescore, no FAIL)

| Asset | Before | After | Notes |
|---|---|---|---|
| shadow_tower | PASS 88 | PASS 93 | C2 vertex use 24 -> 100 (3952 of 6000), C3 palette depth 50 -> 80, C4 inner detail 92 -> 100; R4 ash contrast 100 -> 95, R5c (noisy) 94 -> 88 |

## Tests

`tests/test_gf_shadow_leftovers.gd`: the collar is one surface with > 1500 vertices and three team shades (player and
mirror colour), hidden on a site at 0, collapse still finishes; the Shadow site outlines (Spire, Hovel, Hall, Stables)
are thin, energy <= 0.6, pulse <= 2 rad/s, saturation <= 0.4 / value <= 0.7 also after a saturated recolour, hidden
once built; the Fire outlines are unchanged. Passing: test_gf_shadow_leftovers, test_shader_lint, test_ge_additive_fog,
test_gf_r2_fs, test_gb_shadow, test_gc_shadow, test_10_v4, test_a2_6, test_13_v25, smoke (victory=true).
