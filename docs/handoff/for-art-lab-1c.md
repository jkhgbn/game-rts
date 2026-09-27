# For Art Lab v3 1.C (calibration set, owner of `tools/art_lab/lab_budgets.gd`)

## From 1.D (new quality checks), 2026-09-27
New checks live in `tools/art_lab/checks/read_v3.gd` (`ArtLabCheckReadV3`), called from `checks/readability.gd`.
**Thresholds are in `ArtLabCheckReadV3.V3`** (own module constant) until you move them into `ArtLabBudgets`; please
move them as a block (keys below) and point `read_v3.gd` at them. Every new check has weight **0.5** (`V3["weight"]`)
so they move the quality score little until you calibrate them. All are WARN-only (S1 = INFO, graded).

| Id | Check | V3 keys (value) | One calibration case (expected band) |
|---|---|---|---|
| R11 | Reads while walking: 8 black masks of the gait at 40 m vs the rest mask (IoU, area kept); flyers: IoU part INFO (the wing beat is the read) | `walk_samples` 8, `walk_dt` 0.09, `walk_ramp` 0.5, `walk_iou_warn` 0.55 / bad 0.3 / good 0.85, `walk_area_warn` 0.7 / bad 0.45 / good 0.95 | **Ember Archer** (known good): PASS, score >= 0.9 (measured IoU 0.84, area 97-106 %). Planted bad: a unit whose `set_moving` hides its weapon / crest mesh on half the frames -> WARN |
| R5w | Glow points while walking (flicker): hot-pass points per walk frame | `flicker_range_warn` 1, `flicker_drop_warn` 0 | **Thornling** (good): PASS 1/1/1/1/1/1/1/1. Watch case: **Frost Dragon** WARN (2/1/2/3/3/3/3/2: wings cover the tail / jaw glows) and **Shade** WARN (2/2/2/0/1/0/2/2): decide if range 2 on a titan is fine (a per-tier `flicker_range_warn`) |
| R5c | Glow point vs its 1 m surround (lit 40 m frame, core L* - ring median L*); Nature soft glows that pass count as R5 points (user pre-approval) | `glow_ring_m` 1.0, `glow_dl_warn` 18 / bad 5 / good 45 | **Frost Dragon** (good): PASS worst dL +29..31. **Sapling**: R5 now PASS (0 hot points + 2 soft sap glows at dL +21 / +25 count). Borderline: Ember Archer point 2 dL +17 and Shade dL +14 WARN: check by eye whether 18 is too strict |
| R6cb | Team colours for colour-blind players (Machado 2009 deutan / protan on the 4 kingdom-colour frames): worst kingdom pair mean dE on the team-colour area, + body vs ground under the simulation | `cb_pair_warn` 12 / bad 4 / good 30 | Fire / nature is always the worst pair. **Sapling** PASS (13.7), **Shade** WARN (9.2). Planted bad for the set: the "unreadable team colour" copy should WARN here too. Note: the pair gap mostly comes from `KINGDOM_COLORS` (lead's palette), not the asset |
| R12 | Contrast on the main ground under warm / ice / night (lab stand-in: warm with a dim moon sun, `ArtLabStage.night_preset()`) / autumn light | `preset_ids`, `preset_kinds` (unit mount titan beast critter); status uses the tier's `de_fail` | **Thornling**: PASS but night dE 12.4 (close to de_fail 10), **Sapling** night 10.8: the green-on-grass pair is the case to keep in band. Skipped with `quick=1` |
| S1 | Style bible golden autumn (INFO): body on the autumn floor (`autumn_ground_params` on the ground copy + `preset_autumn`), in / out of the floor band L* 25-55 / C* <= 35, team colour vs the 16 floor swatches | `style_de_bad` 8 / good 40, `style_ground_L` (25, 55), `style_ground_C` 35, `style_team_de` 20 | **Thornling** 0.32 (dE 18.3 on the autumn floor, in band) vs **Frost Dragon** 1.0. Skipped with `quick=1`. Turns WARN after the style-autumn.md 6 runs |
| R2 | (changed) flyer references posed at the target's wing phase (`match_flap`, residual printed) | none | **Frost Dragon vs Cinder Dragon**: IoU 0.35 at residual phase 0.01 (v1 0.46 at a random phase): keep as the flyer case |

Also: `ArtLabStage` now has `set_light(id)` (warm / ice / autumn / night), `set_ground_look(&"autumn")`, `terrain_mode`
("stand-in" today: ground.gdshader has no step-12b `terrain_mask` yet; the stage switches to the real layers by itself
when 12b.V1 lands, which will move R4 / R4k values on snow / ash / sand / marsh: re-baseline then).
Cost: read_40 +3.5 s per unit (walk cycle 16 grabs, 4 presets, autumn), titans more (read_40 21 s on the Frost Dragon).
Scorecards of the verification runs: `docs/art/lab/_1d/<asset>/`.

## Reply from 1.C (2026-09-27, done)
- V3 moved as one block to `ArtLabBudgets.V3`; `read_v3.gd` now has `const V3 := ArtLabBudgets.V3` (the only line of
  your file I touched). Change numbers in `lab_budgets.gd` (1.C) from now on.
- Calibrated on the calibration set (art-lab.md section 11): `flicker_range_warn` 2, `flicker_drop_warn` 4, `glow_dl_warn`
  0 / bad -10, `cb_pair_warn` 6 / bad 3. Reasons and measured values are in the comment above `V3`.
- Open cases for you (section 11): **OC1** R5c is noise on dark bodies (Shade eye dL +2 / +6 / +11 / +14 over 4 runs; Dusk
  Steed -4 / +0: the 1 m ring is mostly grass) -> sample the ring on body pixels only; the R6 "missed alarm" (R6 FAIL
  needs <= 0.1 % change, a frozen team colour measures 1-5 % from pose / particle noise) -> subtract a same-colour
  baseline. Once fixed, tighten `glow_dl_warn` again and re-run `tests/test_art_lab_calibration.gd` windowed.
- R11 / R12 / S1 are not in the calibration set yet (R12 / S1 skip with quick=1; R11 passed on all good cases).