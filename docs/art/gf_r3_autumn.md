# G-F review 3 item 5: lift the autumn haze

Source: `docs/art/gf_review3.md` top-6 item 5 (problem 6). Ashwind Reach (Wave Strike) and Quartermeet share
`art/environment/autumn/world_env_autumn.tres`; both sat under a beige-orange veil, and the Ashwind lane read as a
maroon smear.

## Changes

| File | Value | Before | After |
|---|---|---|---|
| `art/environment/autumn/world_env_autumn.tres` | `fog_density` | 0.3 | 0.15 |
| | `fog_aerial_perspective` | 0.22 | 0.1 |
| | `fog_light_color` | (0.84, 0.81, 0.74) | (0.78, 0.80, 0.80) |
| `art/environment/lane_dressing/lane_dressing.gd` | `LANE_GROUND` road / road_dark | autumn (0.33, 0.22, 0.155) / (0.23, 0.15, 0.11) | (0.43, 0.33, 0.22) / (0.30, 0.23, 0.155) |
| | dirt / dirt_dark | autumn (0.31, 0.20, 0.14) / (0.21, 0.135, 0.10) | (0.41, 0.315, 0.21) / (0.285, 0.215, 0.145) |

- The review's starting values were kept for the fog. The lane started at (0.42, 0.30, 0.20) and was nudged a little
  toward ochre by eye: at z45 under the autumn grade the first value still read rust-red.
- The lane colours are painted by `LaneDressing.paint_lane_ground(level)`, called from `ensure_for_level` before the
  tier gate. It runs at every tier (colour only, no cost) on the lane level's own ground material. Shared `.tres` ground
  materials (the plateau) are skipped, so Quartermeet and the other autumn maps keep `autumn_ground_params.gd`'s
  red-brown roads. Like the other level looks, it runs from GroundDetail (windowed only), so headless tests and labs
  are unchanged.

## Quartermeet

Quartermeet keeps its own palette (`quartermeet_palette.gd`); only the shared fog changed. In the overview the haze is
lighter and the fields, roads and the moor rim keep their golden-highland read. No handoff is needed.

## Shots

`docs/art/lab/gf_r3_autumn/` (`.gdignore`): `gf_r3_autumn_contact_sheet.jpg` (before / after: Ashwind overview and
centre z45, Quartermeet overview and centre z45), key PNGs `key_ashwind_centre_before.png`,
`key_ashwind_centre_after.png`, `key_ashwind_overview_after.png`, `key_quartermeet_overview_after.png`.
Tool: `docs/art/lab/gf_r3_autumn/tools/r3_autumn_shots.gd` (windowed, `'--' --gfx=high --map=<id> --tag=<tag>`).

## Test

`tests/test_gf_r3_autumn.gd`: the `.tres` and the live Environment on real Ashwind Reach and Quartermeet levels have
density 0.10-0.20, aerial 0.05-0.14, and a cool grey fog light. Ashwind's ground road is about (0.42, 0.30, 0.20) with
s <= 0.55. Quartermeet is not painted, and the shared plateau material is untouched.
