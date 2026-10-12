# Shadow / Fire balance, normal and Blitz (2026-10-12)

Measured by a balance agent (Opus medium); saved by the lead (the subagent's Write was blocked by the harness).

**Résumé pour JS**
1. En vitesse normale, Fire et Shadow sont déjà corrects depuis le correctif Thornwater (Fire 60 %, Shadow 50 %, Fire-Shadow 7 / 16). Le vrai problème en normal, c'est Ice (23 %).
2. En Blitz, Fire gagne 75 % et Shadow 29 % (Thornwater : Shadow 23 %). La cause : la Fireball de Vessa. À coût égal, l'armée du bot Fire perd contre Shadow (30 %) et contre Ice (0 %).
3. Bogue trouvé : les sorts à projectile (Fireball, Shadow Lance, Rime Bolt) ignorent les facteurs Blitz `spell_damage_x` et `worker_spell_x`. Le « sorts x0,5 sur les travailleurs » du Blitz ne s'est donc jamais appliqué à la Fireball.
4. Changements proposés : Ice s'entraîne plus vite (5 unités, `train_time`, les deux vitesses), Shadow +500 cristaux au départ en Blitz (au lieu de +300), dégâts de la Fireball x0,75 en Blitz seulement (petit ajout de code dans `PaceSwitch`).
5. Résultat : normal Fire 54 / Ice 43 / Nature 60 / Shadow 44 ; Blitz Fire 50 / Ice 42 / Nature 64 / Shadow 44. Tous dans 35-65, mais sur 36 à 60 parties par royaume (environ ± 15 points).

## 1. Baseline (current code, bot normal difficulty, all 12 ordered pairs)
Normal = faster-games lab, tick 60. Blitz = shipped `PaceSwitch.BLITZ`, tick 30. Medians in game minutes; Blitz real
time = game time / 1.3.

**Normal** (`fg-twfix-ch|tw`, 96 games, 48 per kingdom)
| Map | N | Fire | Ice | Nature | Shadow | Fire-Shadow (Fire wins) | Median |
|---|---|---|---|---|---|---|---|
| Crown Hollow | 48 | 54 % (13/24) | 29 % (7/24) | 71 % (17/24) | 46 % (11/24) | 3/8 | 16.9 |
| Thornwater | 48 | 67 % (16/24) | 17 % (4/24) | 62 % (15/24) | 54 % (13/24) | 4/8 | 16.0 |
| **All** | 96 | **60 %** | **23 %** | **67 %** | **50 %** | 7/16 | 16.5 |

24 more baseline Ice games (`fg-sf-ice-n-*` arm `baseline`, seeds 5-6): Ice 29 % (7/24), same picture. The brief's
"Fire 67 / Shadow 35" predates the Thornwater roster fix.

**Blitz** (`fg-sf-base-bz-ch|tw` 72 games + `fg-twfix-bz-tw` 24 = 96 games, 48 per kingdom)
| Map | N | Fire | Ice | Nature | Shadow | Fire-Shadow | Median (game / real) |
|---|---|---|---|---|---|---|---|
| Crown Hollow | 36 | 61 % (11/18) | 22 % (4/18) | 78 % (14/18) | 39 % (7/18) | 4/6 | 14.6 / 11.2 |
| Thornwater | 60 | 83 % (25/30) | 27 % (8/30) | 67 % (20/30) | 23 % (7/30) | 10/10 | 12.1 / 9.3 |
| **All** | 96 | **75 %** | **25 %** | **71 %** | **29 %** | 14/16 | 12.7 / 9.8 |

12 probe games (same values): Fire 8/12, so Fire-Shadow Blitz ~22/28 (79 %). First attacker wins 50 %; games ending
before 5:00: 3 %.

## 2. Diagnosis (Blitz)
**a) Armies alone don't explain it.** Unit Lab `unit_lab/sf2_mixes/`, 20 seeds per arm, bots' Hall mixes at ~equal cost
(Fire 4 Flame Guard + 3 Ember Archer + 1 Blaze Rider + 1 Ash Hurler = 980 c; Shadow 4 Shade + 3 Nightbolt + 1 Grave Hound
+ 1 Shadow Knight = 955 c; Ice 4 Rimeshield + 3 Shardcaster + 1 Rime Colossus = 1000 c):
| Fight | Fire score | 95 % interval |
|---|---|---|
| Fire mix vs Shadow mix | 30 % (6/20) | 15-52 |
| Fire mix vs Ice mix | 0 % (0/20) | 0-16 |
| Early T1: 3 Flame Guard + 2 Ember Archer vs 3 Shade + 2 Nightbolt | 65 % (13/20) | 43-82 |
| Mixes + level-6 wizards, vs Shadow / vs Ice | 5 % / 0 % | |
In Unit Lab Vessa only auto-attacks while the other wizards cast: Fire's real-game edge is Vessa's spells.

**b) Phase and economy** (Blitz Fire-Shadow, 16 games, Fire minus Shadow): at 3:00 Shadow has +7.8 army pop (its +300
bank, trains at x0.5 vs Fire x0.9); Shadow attacks first in every game (median 2:47, Fire 7:18); from 5:00 armies and
crystals are even. Shadow loses its army in the 2:45-5:00 fights (Fire kills 67, loses 47 per game). Normal pace has no
early gap. **The deciding fight is Shadow's first push, 2:45-5:00.**

**c) Who kills** (probe `tools/map_lab/tw_probe.gd`, 12 Blitz Fire-Shadow games, per game)
| Map | Shadow units killed by Vessa (soldiers / workers / champions) | Fire units killed by the Shadow wizard | Shadow soldiers killed by Vessa before 5:00 | Fire soldiers killed by the Shadow wizard before 5:00 |
|---|---|---|---|---|
| Thornwater | 18.0 / 12.8 / 4.3 = **35** | 12.3 / 5.3 / 3.2 = 21 | **5.7** | 2.0 |
| Crown Hollow | 15.0 / 7.7 / 6.7 = 29 | 13.7 / 5.2 / 6.8 = 26 | 5.2 | 2.5 |
Thornwater's narrow crossings clump Shadow's melee push into Fireball circles. Shadow also loses 2.7-4.3 soldiers to
neutral camps before 5:00 (Fire 0.3-0.8).

**d) Code bug.** `PaceSwitch.spell_damage_x` / `worker_spell_x` are applied in `SpellCaster.deal_damage`
(`scripts/spells/spell_caster.gd:1053`); projectile spells skip it: Fireball (`_cast_fireball` ->
`Projectile.launch_at_point`), Shadow Lance and Rime Bolt deal damage in `scripts/units/projectile.gd` `_impact()`
(119-136). The shipped Blitz `worker_spell_x 0.5` never applied to Fireball; the 10-10 arms v19 / v22 and arms B / C
below only touched Ember Step's scorch zone.

**e) Fire's slow training is not the cause** (arm A: Fire soldier_train_x 0.9 -> 0.5 leaves Fire at 72 %).

## 3. Variants tested
**Normal: `ice_t`** (last night, reused): Rimeshield 22 -> 18, Shardcaster 22 -> 18, Rime Seer 24 -> 20, Frostbow 28 -> 24,
Rime Colossus 52 -> 44 (train_time only). 60 Ice games; non-Ice games from the baseline.
| Map | N | Fire | Ice | Nature | Shadow | Fire-Shadow |
|---|---|---|---|---|---|---|
| Crown Hollow | 54 | 46 % | 40 % | 65 % | 50 % | 3/8 |
| Thornwater | 54 | 62 % | 47 % | 54 % | 38 % | 4/8 |
| **All** | 108 | **54 %** | **43 %** | **60 %** | **44 %** | 7/16 |
`ice_s` (ice_t + partial revert of Ice hp / damage nerfs, 24 Ice games): Ice 42 %, no gain.

**Blitz arms** (all include `ice_t`; only changed pairs re-played; seeds 1-3, both maps, tick 30)
| Arm | Change | New games | Fire | Ice | Nature | Shadow | Fire-Shadow | CH F/I/N/S | TW F/I/N/S |
|---|---|---|---|---|---|---|---|---|---|
| Baseline | shipped | 96 | 75 | 25 | 71 | 29 | 14/16 | 61/22/78/39 | 83/27/67/23 |
| `bz_ice_t` | + ice_t | 36 | 68 | 44 | 64 | 23 | 14/16 | 56/39/67/39 | 77/50/62/12 |
| A `bz2_fire5` | Fire soldier_train_x 0.9 -> 0.5 | 36 | 72 | 44 | 55 | 30 | 8/12 | 78/33/56/33 | 67/56/55/27 |
| B `bz2_fsp75` | spell_damage_x fire 0.75 (misses Fireball) | 36 | 69 | 42 | 58 | 32 | 7/12 | 67/33/56/44 | 72/50/59/23 |
| C `bz2_c` | spell_damage_x fire 0.65 (misses Fireball) + Shadow start +500 | 60 | 69 | 44 | 47 | 39 | 7/12 | 61/50/50/39 | 78/39/44/39 |
| **D `bz2_d`** | **Shadow start +500 + Fireball damage x0.75** | 60 | **50** | **42** | **64** | **44** | 6/12 | 39/44/61/56 | 61/39/67/33 |
Noise ~± 15 points per kingdom overall, ~± 20 per map. Arm D pairs (12 games each): Fire-Ice 8/12, Fire-Nature 4/12,
Fire-Shadow 6/12, Ice-Shadow 6/12, Nature-Shadow 8/12 (Nature). Arm D median 14.4 game min = 11.1 real (target 8-12).
Only the Fireball cut (D) brings Fire down (68 -> 50 %); the Shadow bank +500 lifts Shadow 23 -> 39 %.

## 4. Recommended change set
| # | File | Change |
|---|---|---|
| 1 | `data/units/rimeshield.tres` | train_time 22.0 -> 18.0 |
| 2 | `data/units/shardcaster.tres` | train_time 22.0 -> 18.0 |
| 3 | `data/units/rime_seer.tres` | train_time 24.0 -> 20.0 |
| 4 | `data/units/frostbow.tres` | train_time 28.0 -> 24.0 |
| 5 | `data/units/rime_colossus.tres` | train_time 52.0 -> 44.0 |
| 6 | `scripts/world/pace_switch.gd` `BLITZ.start_crystals_add` | shadow 300 -> 500 (fire 0, nature 100, ice 800 unchanged) |
| 7 | `scripts/world/pace_switch.gd` | new Blitz key, e.g. `"spell_type_x": {"fireball": 0.75}`: while Blitz is applied, edit `data/spells/fireball.tres` in memory (`damage` 60 -> 45, `damage_by_rank` [60, 72, 85] -> [45, 54, 63.75]), restored through the same `_edit` / `_originals` path as the unit edits (normal pace and missions untouched). `spell_damage_x {"fire": 0.75}` would do nothing to Fireball (bug 2d). |

**Item 8 (bug, separate):** projectile spells should apply `PaceSwitch.spell_damage_x(target, attacker)` like
`deal_damage`. Once fixed, `worker_spell_x 0.5` starts hitting Fireball / Shadow Lance / Rime Bolt on workers: a new Blitz
nerf arm D did not include. Do not ship with item 7 without re-running arm D (60 games).

Unchanged: Fire soldier_train_x 0.9, `spell_damage_x {}`, Fire / Shadow unit stats, AI knobs, Ice bot economy fix, T3s.
Owners: items 1-5 and 8 gameplay-coder; 6-7 systems-coder.

**Tests touching these values:** `tests/test_7_g2.gd` 13-16 pins Rimeshield / Shardcaster / Rime Seer / Rime Colossus
train_time (22 / 22 / 24 / 52) and also Rimeshield max_hp 150 / Colossus 520 while data has 140 / 410 (probably failing
already); `tests/test_bowmen.gd` (Frostbow row, line 88); `tests/test_unit_guide.gd` (rank claims); `tests/test_blitz.gd`,
`tests/test_pace_switch.gd` (add: the new key cuts Fireball only while Blitz is applied, restored after); Fireball tests
(smoke, `test_2_g1`, `test_2_g2`, `test_3_g1`) are affected by item 8 only; Ice mission sims (`test_e6m*`, `test_e7m*`).

## 5. Caveats
- Blitz arm D composite: 36 games per kingdom (< the 10-11 sheet's 48). Confirmation run advised: Blitz 12 pairs x 4
  seeds x 2 maps, plus the normal-pace Ice pairs.
- Per map slightly outside 35-65: Blitz Thornwater (D) Nature 67 %, Shadow 33 % (18 games each); normal Crown Hollow
  Nature 65 %.
- Normal bot difficulty only (no hard). Composites assume a change only affects its kingdom's games (true for train
  times, start bank, Fireball).

## Files
- Variants (`variants/`): `bz2_fire5.json` (A), `bz2_fsp75.json` (B), `bz2_c.json` (C), `bz2_d.json` (D); last night's
  `ice_t`, `ice_s`, `bz_ice_t`, `bz_ice_s`, `bz_shipped`.
- Unit Lab: `unit_lab/sf2_mixes.json`, `unit_lab/sf2_mixes/scorecard.md|json`.
- Runs (`Documents\four-wizards-lab-runs\`): `fg-sf2-probe-bz-ch|tw` (12), `fg-sf2-bzA-ch|tw` (72, A + B),
  `fg-sf2-bzC-ch|tw` (60), `fg-sf2-bzD-ch|tw` (60, with kill data); reused `fg-twfix-*`, `fg-sf-*`.
- Arm D and the probes ran `tools/map_lab/tw_probe.gd` (for the `spells` override) through a scratchpad copy of
  `run_fg.py` reading the match script from env `FG_SCRIPT` (`run_fg.py` hard-codes `fg_match.gd`).

## Other notes
- `blitz_report.py` reads Blitz `game_speed` only from the lab's `tuning`; with the shipped values it prints game time as
  real time (14:02 instead of 10:48 real).
- Shadow's Blitz bot attacks at ~2:30 with the biggest early army and loses it (+bank and x0.5 training with the Blitz
  `first_attack_by 300` / `full_pop 10` knobs).
