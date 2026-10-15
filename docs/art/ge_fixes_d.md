# G-E fixes D (2026-10-15)

The follow-ups of `ge_value_pass.md` ("Not done") and `gc_leftovers.md` ("Left undone"), plus the hovel R5c WARN.
Shots: `docs/art/lab/ge_fixes_d/gd_contact_sheet.jpg` (before | after pairs), key PNGs `gd_key_nature_z30.png`,
`gd_key_riders_z7.png`, `gd_key_dusk_keep_z30.png`, `gd_key_dusk_keep_crop.png`. Every other shot stays local
(`before_*` / `after_*` / `v*_measure` / `leaves1` / `battle1`, the folder has a `.gdignore`). Windowed, High, 1600 x 900.

Tools (`docs/art/lab/ge_fixes_d/tools/`): `gd_shots.gd` = the value pass's `gv_shots.gd` plus modes `riders` (the two
Nature riders close, z7 / z12), `keep` (a Shadow base, Dusk Keep z12 / z30 / z40, a hovel z10), `leaves` (Nature war
units killed on the meadow with CombatFxG hidden), `battle` (the 4-kingdom battle only) and `matmap` (per material:
visible pixel count and mean colour of a kingdom's unit grid: which material makes the read). `gd_camo.py` (Nature unit
pixels vs the meadow: L* / hue histograms, camo pixels, `--show` marks them), `gd_violet.py` (loud violet share of a
frame), `gd_sheet.py` (sheet + keys); `gv_measure.py` copied unchanged.

## 1 Nature units vs the meadow

`matmap` showed what the Nature grid is made of: team cloth 19 % of the pixels (pale mint, the gold top lift pushed it
to hue 75, the meadow is 87), bark 15 %, skin / antler / moss / thorn / dry leaves ~25 % (cream / gold), and the
riders' and mounts' STRAW drew in the team colour: `nature_bell_cloth` ends in `_cloth`, so the kit's
`_team_variant` recoloured every straw hat, shield, fletching and hem.

Changes (material level, plus the straw material):
- `nature_bark` (0.52, 0.35, 0.18) -> (0.27, 0.175, 0.09), lichen 0.32 -> 0.22: the dark body mass.
- `nature_leaf` / `nature_moss` deeper bronze-olive (0.5, 0.38, 0.17) / (0.46, 0.38, 0.17), cream top lift 0.3 -> 0.18;
  `nature_leaf_dark` (0.32, 0.24, 0.11).
- `nature_cloth` (team): top colour gold (0.9, 0.78, 0.46) -> pale cream (0.92, 0.88, 0.76) at 0.15 (no yellow-green
  mix), dye 0.8 / 1.0 (pale, a clean team green); `nature_cape` dye 0.8 / 1.0; `nature_cloth_dark` (the stripe) dye
  1.0 / 0.5, no top lift: a deep value step, not grass-green.
- Mount coats `tb_coat` / `bh_coat` darker brown.
- New `nature_straw.tres` (the bell-cloth look under a name the kit never recolours), used by the warden, dartcaster,
  elk and hare: the dartcaster's big hat, the warden's shield, fletchings and hems are cream straw again (as their
  headers always said). Bloomtender keeps `nature_bell_cloth` (its bell is meant to be team cloth).

Tried and dropped (measured): a darker team cloth (dye_val 0.72 / 0.55 / 0.4) put the cloth right at the grass value
(camo 0.057 -> 0.077 / 0.089 / 0.107); without dye the cloth stays pale and separates by value.

Measure (zoom 35, meadow, all Nature unit types x2, `gv_measure.py` / `gd_camo.py`):

| Nature units | before | after |
|---|---|---|
| Camo (grass hue and value) | 0.057 | 0.048 |
| mid grass band (hue 50-110, L* 40-66) | 3.4 % | 2.6 % |
| green share (hue 60-160) | 21.9 % | 16.8 % |
| dark body pixels (L* < 30) | 5.4 % | 13.9 % |
| pale pixels (L* > 75) | 49.1 % | 43.8 % |
| Lu (mean L*) | 0.680 | 0.630 |
| dEpx | 41.7 | 42.1 |
| CL / Fire | 1.09 | 1.10 |

Every kingdom within 25 % of Fire's unit L* contrast (after): Fire 0.231 (1.00), Ice 0.187 (0.81), Nature 0.254 (1.10),
Shadow 0.247 (1.07); buildings unchanged (Ice 0.90, Nature 1.06, Shadow 1.10).
Art Lab R3 (meadow) up on every Nature unit rescored: thornling 83 -> 88, sapling 85 -> 89, burr slinger 85 -> 89,
sprigling 87 -> 88, bramble harrier 93 -> 95, thornback charger 97 -> 98; R6cb WARN -> PASS on thornling (36 -> 76)
and burr slinger (35 -> 76). R6 (team area) drops on the riders (thornback 88 -> 80, harrier 100 -> 88, still PASS):
the straw is no longer team-coloured, by design.

## 2 Rider saddle-cloth panels

New `art/units/nature/nature_drape.gd` (`NatureDrape.panel`, preloaded by the riders): a two-sided panel grid
(7 x 4 per face, 56 vertices vs a box's 24, merged into the existing material surface: no extra draw) with taper /
flare, body wrap, a bow along the length, folds deepening to the hem and a leaf-point / scalloped hem; a window +
offset builds stripes and hem bands that follow the cloth. Thornback warden: hip flap, chest tabard and the back cape
(flared 0.44 -> 0.64 m, three folds, scalloped hem), each with its dark stripe. Bramble dartcaster: the sash bows round
the jerkin, the mantle flares with three folds, its stripe and a straw hem band follow it.

## 3 Nature death leaves

`NatureWarModel.add_death_bloom`: leaf quads 0.15 -> 0.09 m (`DEATH_LEAF_SIZE`), default colour deeper (0.40, 0.58, 0.17).
Finding: the big pale-green leaf cloud in the deaths shots is NOT this one. With CombatFxG hidden the cloud stays the
same: it is `art/vfx/combat_vfx.gd` `death_nature` (18 leaves x `_size_hold(m, 0.28, 0.46)`, 1.5 s, line ~1140), outside
this task's files. Suggested fix for its owner: size 0.12-0.2, 12-14 leaves, life ~1.1 s, the greens 15 % darker.

## 4 Dusk Keep

The dusk_keep_glow parts are accents now (the glow cap squeezes everything above ~0.9, so the energies had to drop
under the knee to change the read): Windows 2.2 -> 1.0, FinTips 3.0 -> 1.2, RuneRing 3.0 -> 1.0 (`DuskKeep.RING_ENERGY`)
with a thinner band (0.30 -> 0.16 m), GateSlits 2.5 -> 1.2, lantern orbs 3.0 -> 1.6, ShardCore 4.0 -> 3.2 (the top eye
stays the brightest point); tier rune slits 2.4 -> 1.1, second ring 2.2 -> 1.0, soul crown 2.6 -> 1.2; ground crack
emission 2.2 -> 1.1; wall / obsidian crack glow 0.45 / 0.7 -> 0.3 / 0.45. Same values in `dusk_keep.tscn` and the
`dusk_keep_build.gd` generator. Violet kept everywhere.
Loud violet (hue 260-320, s > 0.45, v > 0.7, `gd_violet.py`): keep crop z30 7.9 % -> 5.6 %, keep z12 5.6 % -> 3.5 %,
whole base z30 1.33 % -> 1.15 %. Art Lab: 0 FAIL; R5 (glow point count, WARN before too) 43-46 -> 27 points;
R5c PASS on the rerun (the first run gave a noisy WARN 57).

## 5 Hovel R5c

Point 1 (dL 0) was the roof tip shard: a capped violet core has about the meadow's L*, and it sits at the silhouette's
top. A dark iron hood over the last metre of the tip, a slightly bigger shard and a pale lilac core
(`glow_color.lerp(WHITE, 0.6)`, not team-tinted): R5c WARN 55-60 -> PASS 92-94 (worst dL 0 -> +10, two runs), hovel PASS 85.

## Also

G-F offscreen emitters: the 4 Nature rider roots (bramble_harrier, glade_outrider, stagrunner, thornback_charger) got the
`offscreen_freeze` setter forwarding through `OffscreenEmitters.forward_freeze` (blaze_rider's pattern).

Tiers: all changes are material values, geometry or emitter sizes on existing paths: same cost at Low.
Test: `tests/test_ge_fixes_d.gd`.
