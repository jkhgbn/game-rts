# Visual Diff Lab scorecard

**PASS** - score **100** / 100 (worst shot 100) - 2026-09-27 07:38:59 - commit `main@0fca55bc2d+wip` - tolerance 12 / 255 per channel - 1600x900

Thresholds: PASS <= 0.05 % changed pixels (or < 25 px), WARN <= 1.0 %, FAIL above. Score = 100 at 0 %, 0 at 5 %. Images in this folder: `<shot>.png` (now), `<shot>_diff.png` (heatmap: yellow small / red big change, blue ignored, magenta box), `<shot>_compare.png` (golden | now | heatmap, 1/3 size), `<shot>_focus.png` (**read this one first**: the change regions zoomed up to 3x, one row per region in the order listed below, golden | now | heatmap; written when >= 25 px changed).

| Shot | Result | Score | Changed | Pixels | Max delta | Change box (x, y, w, h) | Where | Unstable px | Ignored | Why |
|---|---|---|---|---|---|---|---|---|---|---|
| menu_main | **PASS** | 100 | 0.000 % | 0 | 0 | - | - | 0 | 0.00 % | no visible change |
| map_player_base | **PASS** | 100 | 0.000 % | 0 | 0 | - | - | 0 | 3.93 % | no visible change |
| map_centre | **PASS** | 100 | 0.000 % | 0 | 0 | - | - | 0 | 3.93 % | no visible change |
| map_west_meadow | **PASS** | 100 | 0.000 % | 0 | 0 | - | - | 0 | 3.93 % | no visible change |
| map_overview | **PASS** | 100 | 0.000 % | 1 | 16 | 1343, 3, 1, 1 | top-right | 0 | 3.93 % | 1 px (0.000 %) changed, under the noise floor (0.05 %) |
| lineup_fire | **PASS** | 100 | 0.000 % | 0 | 0 | - | - | 0 | 0.00 % | no visible change |
| lineup_ice | **PASS** | 100 | 0.000 % | 0 | 0 | - | - | 0 | 0.00 % | no visible change |
| lineup_nature | **PASS** | 100 | 0.000 % | 0 | 0 | - | - | 0 | 0.00 % | no visible change |
| lineup_shadow | **PASS** | 100 | 0.000 % | 0 | 0 | - | - | 0 | 0.00 % | no visible change |

## Look at next
- Nothing: every shot matches its golden.

## Notes
- 51 character idle phases set from the node path (determinism, see _fix_idle_phase)
