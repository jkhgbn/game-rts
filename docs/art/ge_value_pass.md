# G-E value pass (2026-10-15)

Item 3 of `docs/art/ge_review.md`: Shadow dominated every shot (full-saturation violet everywhere), Nature units read
green on green grass, Ice snow / white trim was the brightest thing on screen. Fire was the reference. This pass
rebalances the four kingdoms with shared, material-level grades (no per-model rebuilds), keeping every kingdom's identity
and every team colour (the colour logic in `scripts/units` is untouched: the grades act on what the material draws, hue
kept, so the alt mirror palettes are graded the same way).

Shots: `docs/art/lab/ge_value/gv_contact_sheet.jpg` (before | after pairs: the 4 bases side by side, Shadow / Ice bases
z30 / z40, the 4-kingdom battle z30 / z40, the Shadow mirror z30 / z40, the Nature / Ice lineups), key PNGs
`gv_key_bases.png`, `gv_key_battle_z30.png`, `gv_key_mirror_z40.png`. Every other shot stays local
(`docs/art/lab/ge_value/{before,after}_{fs,in,mirror}/`, `.gdignore`). Windowed, High, 1600 x 900.
Note: the battle "after" shot also shows the team-readability work running in parallel (enemy sides wear the new
team palettes); the value pass itself does not change any team colour.

## Tools

- `docs/art/lab/ge_value/tools/gv_shots.gd`: a copy of the G-E review shot tool (modes `bases` / `map` / `mission`, base
  and lineup shots at z30 + z40 with `--quick`) plus two modes:
  - `--mode=measure [--kingdoms=fire,ice,nature,shadow] --out=<dir>`: Crown Hollow open meadow at (12, -33), fog / HUD
    off, zoom 35. Per kingdom: every unit type x2 (team 0, main palette) in a 6-wide grid, then a building row (Hall,
    house, tower, Stables, Forge). Three PNGs each: normal, mask (every body mesh unshaded magenta; glows, rings,
    decals and particles left out), ground (models hidden).
  - `--mode=scout --pts="x,z;..."`: candidate measure spots.
- `docs/art/lab/ge_value/tools/gv_measure.py <dir>`: per kingdom, unit / building pixels vs the ground right behind
  them (column meanings in its header). `CL` = mean per-pixel L* contrast (perceived value), `Camo` = share of pixels
  with the ground's hue and value, `Sbase` = median saturation of the 80 % darkest pixels (base materials).
- `docs/art/lab/ge_value/tools/gv_sheet.py`: the contact sheet and key PNGs.

Why L* and not HSV V for the target: HSV value is max(R, G, B), so any saturated colour reads V ~ 1 (pure orange and pure
violet both). Fire's lead in `Cpx` (HSV) is mostly its saturation; desaturating Shadow lowers its HSV contrast by
definition. The value-contrast target is judged on `CL` (perceived lightness); both are in the table.

## Before / after (zoom 35, meadow, High)

Units (all unit types of the kingdom, x2):

| kingdom | Su before | Su after | Sbase before | Sbase after | CL before | CL after | CL / Fire after | Camo before | Camo after | V95 before | V95 after |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Fire (ref) | 0.604 | 0.602 | 0.624 | 0.623 | 0.230 | 0.232 | 1.00 | 0.009 | 0.009 | 1.000 | 1.000 |
| Ice | 0.325 | 0.344 | 0.337 | 0.376 | 0.187 | 0.186 | 0.80 | 0.005 | 0.004 | 0.902 | 0.902 |
| Nature | 0.444 | 0.453 | 0.468 | 0.484 | 0.253 | 0.249 | 1.08 | 0.055 | 0.056 | 0.949 | 0.953 |
| Shadow | 0.457 | 0.332 (-27 %) | 0.545 | 0.370 (-32 %) | 0.228 | 0.251 | 1.08 | 0.001 | 0.001 | 0.910 | 0.906 |

Buildings (Hall, house, tower, Stables, Forge):

| kingdom | Su before | Su after | Sbase before | Sbase after | CL before | CL after | CL / Fire after | Camo before | Camo after | V95 before | V95 after |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Fire (ref) | 0.600 | 0.600 | 0.600 | 0.599 | 0.242 | 0.242 | 1.00 | 0.036 | 0.036 | 1.000 | 1.000 |
| Ice | 0.252 | 0.281 | 0.249 | 0.301 | 0.237 | 0.217 | 0.90 | 0.001 | 0.001 | 0.902 | 0.867 |
| Nature | 0.496 | 0.493 | 0.526 | 0.522 | 0.256 | 0.259 | 1.07 | 0.076 | 0.072 | 0.918 | 0.918 |
| Shadow | 0.566 | 0.416 (-27 %) | 0.722 | 0.505 (-30 %) | 0.224 | 0.266 | 1.10 | 0.003 | 0.002 | 0.800 | 0.792 |

HSV value contrast (`Cpx / Fire`, for the record): units Ice 0.68 -> 0.66, Nature 0.92 -> 0.93, Shadow 0.73 -> 0.72;
buildings Ice 0.68 -> 0.62, Nature 0.74 -> 0.74, Shadow 0.54 -> 0.57.

Ice whites (pixels with saturation < 0.25 and value > 0.6): buildings share 52 % -> 40 %, mean value 0.806 -> 0.786
(the Frost Hall roof slab 0.879 -> 0.793); units 0.796 -> 0.797 (they were already ~0.8 on average; the near-white hair /
skin / pale fur came down, the darker steel and leather lifted the share-weighted mean back).
Nature: green (hue 70-160 deg, saturation > 0.25) share of the unit pixels 19.7 % -> 14.3 %.

Reading the numbers:
- Shadow: base-material saturation -30 / -32 %, overall saturation -27 %; L* contrast up (darker slate bodies, bone /
  silver accents). Violet stays on the team cloth / roof courses (graded, still violet), glows, runes and banners.
- Every kingdom's L* contrast is within 25 % of Fire's (Ice units the lowest at 0.80 of Fire, the same as before the
  pass: its whites came down and its steel / leather went darker).
- Nature: the units already read by value (L* 0.69 vs ground ~0.5); the pass moves them warmer (less green, gold leaf
  rims, bone lichen tops, warmer bark / moss / leaf). The Camo metric does not move: the warm gold sits within 30 deg of
  the meadow's yellow-green hue (85 deg). The team-cloth grade is kept mild (0.88 / 0.9, gold top 0.2) so the team colour
  stays full: a stronger one (0.72 / 0.84 + a 0.45 gold top) took the green share to 10 % at a team-read cost.
- Ice: building whites capped near 0.79 mean; the remaining p90 (~0.87) is crystal edges / glints and glows.

## Art Lab team-colour / contrast checks (after; "prev" = the lab's previous run of that asset)

| asset | R3 meadow | R3t | R6 | R6cb |
|---|---|---|---|---|
| shade | PASS 100 (unchanged) | PASS 100 | PASS 100 (68 %) | PASS 79 |
| gloom_thrall | PASS 100 | PASS 100 | PASS 100 (51 %) | PASS 82 |
| barrow_knight | PASS 100 | PASS 100 | PASS 92 (prev 95, an older run) | PASS 78 (prev 76) |
| sapling | WARN 49 -> PASS 87 | WARN 53 -> PASS 91 | PASS 100 | PASS 76-78 |
| thornling | PASS 85 -> 87 | PASS 88 -> 91 | PASS 100 | WARN 36-38 (see below) |
| sprigling | PASS 84 -> 87 | PASS 88 -> 91 | PASS 100 | PASS 76 (prev 79) |
| shadow_hall | PASS 100 | PASS 100 | PASS 100 (34 %) | PASS 83 (prev 80) |
| ice_hall | PASS 100 | PASS 100 | PASS 100 | PASS 77 (prev 79) |
| rimeshield | PASS 100 | PASS 100 | PASS 87-88 (prev 94, an older run) | WARN 36 (prev 38) |

Thornling R6cb (deutan fire / nature too close to the meadow) stays WARN 36-37 with EVERY Nature change of this pass
reverted (checked: same value), so it predates the pass. Rimeshield R6 87 does not move when the Ice dye / metal changes
are reverted (checked), so its previous 94 comes from an older model state. The Ice team-cloth dye was dropped anyway
(no white is team cloth). `hovel` R5c (glow point contrast, flagged noisy by the lab) WARN 55-60 vs 90 before: a sixth
glow point with dL 0 after the slate grade; worth a look in a Shadow pass (`docs/art/lab/hovel/scorecard.md`).

## What changed (shared, material-level)

Grade uniforms (default 1.0 = unchanged for every other user; graded in a gamma-2 space, hue kept):
- `art/shaders/painted_vc.gdshader` (+ `art/buildings/stables/stables_painted.gdshader`): `team_sat`, `team_val`
  (team parts), `body_sat` (plain parts).
- `art/units/kit/unit_painted.gdshader`, `art/units/nature/nature_living.gdshader`, `art/shaders/banner.gdshader`:
  `dye_sat`, `dye_val` on the base / cloth colour. Set on a palette `.tres`; the kit's team-cloth duplicates keep it.

Shadow:
- `ShadowDress.grade(model)` (`art/buildings/shadow_dress.gd`), called by `attach_at` before the tier check (so Low too):
  team parts saturation x0.40 / value x0.88, plain parts saturation x0.40, banners dye-graded. Every Shadow building
  that attaches the dress (keep, Hall, house, tower, Stables, Forge via the Hall) gets it.
- Unit palette (`art/units/kit/materials/`): `shadow_cloth`, `shadow_cloth_dark`, `shadow_cape`, `shadow_cape_plain`,
  `shadow_sec_bolt` dye 0.55 / 0.86; `shadow_iron`, `shadow_leather`, `shadow_obsidian` neutral dark iron / slate with
  neutral top lifts, rims (0.62, 0.58, 0.74); `shadow_silver`, `shadow_skin`, `shadow_sec_worker` neutral.
- Dusk Keep stone / silver / dark stone / obsidian toward slate (`dusk_keep.tscn` + `dusk_keep_build.gd`).

Nature (units; the Nature base was already fine, unchanged):
- `nature_cloth` (team leaves / cloth): dye 0.88 / 0.9, warm gold top lift 0.2; `nature_cloth_dark` dye 0.9 / 0.9 +
  bronze top lift 0.15; `nature_cape` dye 0.88 / 0.9.
- `nature_leaf` amber-olive + cream top, `nature_leaf_dark`, `nature_moss` moss-gold + cream top, `nature_bark` /
  `nature_bark_dark` warmer with more lichen, `nature_sec_sapling` warm cream.
- `nature_living.gdshader` defaults: lichen pale warm bone (0.88, 0.82, 0.66; was silver-green; a gold version sat
  on the meadow hue), leaf rim warmer gold.

Ice:
- `art/buildings/ice/ice_paint.gdshaderinc`: snow colour (0.66, 0.72, 0.84), `ip_white` 0.74 on the snow kind (+ cool
  tint) and partly on frost, and `ip_white_knee` 0.40: a soft knee (x0.35 above it) with a cool tint on every pale
  non-team part (snow, frost, snowy tops, white trims). The team ice crystals and the glows stay the brightest.
- Unit palette (`art/units/ice/materials/`): `ice_hair`, `ice_skin`, `ice_fur_pale`, `ice_sec_hauler` down from near
  white; `ice_metal`, `ice_steel`, `ice_leather` darker (value structure under the whites). The team cloth is not graded.

Tier rule: the grades are uniforms on the existing paths (no new pass, texture read or particle); Low gets the same
colours (ShadowDress grades before its Low early-out).

Test: `tests/test_ge_value_pass.gd` (neutral defaults, Shadow palette saturation and dye, Shadow building graded at
Low / Fire building not, Nature warmth and the new lichen default, Ice white caps).

## Not done / follow-ups

- Nature still sits close to the meadow hue (yellow-green vs gold); a stronger separation needs either darker bark
  bodies (value 0.15 under the grass, the review's suggestion) or less team-green area on the models (per-model).
- Dusk Keep: its large violet glow panels (dusk_keep_glow) are accents by this pass's rule and stay; they are still the
  loudest Shadow element in a base shot.
- Autumn / snow biomes were not measured (meadow only); the grades are biome independent.
