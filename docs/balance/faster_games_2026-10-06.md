# Faster games: experiment A (pacing buff / nerf) vs B (siege) (2026-10-06)

JS 2026-10-06 (`docs/ideas/jss_asks.md`): "try to buff or nerf units or add siege units to give a huge positional advantage
and finish the game faster; try both". Measured with bot-vs-bot skirmishes on Crown Hollow. **Nothing is enabled by
default**: every arm is a Balance Lab variant applied in memory by the lab match script; `data/` and `scripts/` are untouched.

## Verdict
**A, not B, and A only in its strong form (A2, which includes bot aggression).** At normal difficulty:
- **A2** (`fg_a2_strong`): median **21:40 -> 17:31 (-4:10, 90 % interval -7:08 .. -1:16, p = 0.03)**. This is the only arm
  that is clearly shorter.
- **A** (`fg_a_pacing`, data only): -3:16 at normal (interval -5:32 .. -0:33, p = 0.19), -2:22 at hard (not significant).
  No change at easy, where the match runs to the 30:00 limit either way.
- **B** (`fg_b_siege`): -0:08. **B2** (twice the siege): +0:12. **A + B**: -1:25, which is less than A alone.

B does nothing to match length because the bots end games by **concede** (they lose their army and workers), not by
razing bases: the losing side has lost only about one building when the game ends. Siege can only help once a bot actually
pushes into a base, and the Commander never does that on purpose. It trains 1-2 siege units per game (3-4 with B2), and siege
units kill 6-9 of the 40-50 buildings lost over 36 games.

No arm breaks the Unit Lab matrices. A / A2 change no combat stat. B's two new units are weak against units, as siege
should be (crystals 11 / 28, pop 11 / 16), and they move the 47 existing entries by 3.9 points at most.

Proposal for JS: **playtest A2's data half** (buildings -40 % HP, turrets -40 % damage, training 30 % faster, workers 40 %
faster) together with the bot aggression knobs, before anything goes into `data/`. Two caveats come with it: Fire wins
78 % in A2 (72 % in baseline), and three games out of 36 ended before 8:00 (1 out of 36 in baseline). The rush targets
(`rush-balance.md` 8) need a rerun with the rusher style before anything ships. Keep B as a later design topic: it needs a
Commander siege rule (ai-coder) and has to be judged by humans, because the bots cannot show its value.

## Main table (tick 30, early stop on, limit 30:00, Crown Hollow, 12 ordered pairs = 4 kingdoms x both seats)
Normal: 3 seeds, 36 games per arm (9 per kingdom x seat cell). Easy / hard: 2 seeds, 24 games (6 per cell, below the 8 we
aimed for, for lack of machine time). "1st building lost" = median time of the first building destroyed in a game (walls
and sites not counted). "Matrix delta" = how far the arm moves the Unit Lab matrices (section 3).

| Arm | Level | N | **Median** | p25-p75 | Kill / concede | Early-score | Time-score | Win % F / S / I / N | Spread | Player seat | 1st building lost | 1st tower lost | Loser bldgs lost | Siege / side | Matrix delta |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| baseline | easy | 24 | **30:00** | 23:10-30:00 | 46 % | 0 % | 54 % | 83/50/33/33 | 50 | 58 % | 11:00 | - | 0.2 | 0 | - |
| baseline | normal | 36 | **21:40** | 16:49-24:30 | 75 % | 14 % | 11 % | 72/50/28/50 | 44 | 44 % | 18:46 | 20:32 | 0.9 | 0 | - |
| baseline | hard | 24 | **22:24** | 15:43-25:45 | 79 % | 17 % | 4 % | 75/50/25/50 | 50 | 58 % | 16:57 | - | 0.9 | 0 | - |
| A `fg_a_pacing` | easy | 24 | **30:00** | 27:20-30:00 | 29 % | 0 % | 71 % | 75/42/42/42 | 33 | 46 % | 10:34 | 15:43 | 0.4 | 0 | 0 |
| A `fg_a_pacing` | normal | 36 | **18:24** | 13:34-23:16 | 78 % | 17 % | 6 % | 67/33/22/78 | 56 | 44 % | 14:28 | 17:59 | 1.4 | 0 | 0 |
| A `fg_a_pacing` | hard | 24 | **20:02** | 15:05-23:26 | 79 % | 17 % | 4 % | 67/75/8/50 | 67 | 46 % | 13:19 | 17:05 | 1.8 | 0 | 0 |
| A2 `fg_a2_strong` | normal | 36 | **17:31** | 11:58-22:08 | 81 % | 14 % | 6 % | 78/33/22/67 | 56 | 42 % | 10:17 | 12:11 | 1.4 | 0 | 0 |
| B `fg_b_siege` | normal | 36 | **21:32** | 16:16-24:07 | 72 % | 22 % | 6 % | 50/50/28/72 | 44 | 36 % | 18:20 | 18:28 | 1.1 | 1.3 | <= 3.9 |
| B2 `fg_b2_siege_heavy` | normal | 36 | **21:53** | 17:08-26:29 | 81 % | 8 % | 11 % | 56/61/28/56 | 33 | 36 % | 15:46 | 18:03 | 0.9 | 1.6 | <= 3.9 |
| A + B `fg_ab_both` | normal | 36 | **20:16** | 17:52-23:06 | 81 % | 14 % | 6 % | 61/44/33/61 | 28 | 47 % | 17:01 | 17:01 | 1.1 | 1.1 | <= 3.9 |

Median change against baseline at the same level (bootstrap 90 % interval over 2000 resamples, Mann-Whitney two-sided p):
| Arm | Level | Change | 90 % interval | p |
|---|---|---|---|---|
| A2 | normal | **-4:10** | -7:08 .. -1:16 | **0.028** |
| A | normal | -3:16 | -5:32 .. -0:33 | 0.19 |
| A | hard | -2:22 | -5:46 .. +2:16 | 0.45 |
| A | easy | 0:00 | 0:00 .. +4:46 | 0.29 |
| A + B | normal | -1:25 | -3:22 .. +0:52 | 0.66 |
| B | normal | -0:08 | -2:18 .. +2:02 | 0.85 |
| B2 | normal | +0:12 | -2:05 .. +2:25 | 0.62 |

Other numbers (normal):
| Arm | Ends before 8:00 (kill / concede) | Before 12:00 | Median first attack | Buildings killed by siege / all lost |
|---|---|---|---|---|
| baseline | 1 / 36 | 3 / 36 | 4:52 | 0 / 42 |
| A | 2 / 36 | 3 / 36 | 3:30 | 0 / 59 |
| A2 | 3 / 36 | 8 / 36 | 2:57 | 0 / 61 |
| B | 0 / 36 | 2 / 36 | 5:54 | 6 / 40 |
| B2 | 0 / 36 | 1 / 36 | 5:04 | 9 / 50 |
| A + B | 0 / 36 | 1 / 36 | 3:42 | 3 / 59 |

How to read the table:
- **Win spread** is the same in every arm, given the noise. With N = 18 games per kingdom, one kingdom's win rate carries
  about +/- 12 points. Fire is strong (67-78 %) and Ice is weak (22-28 %) in every arm, baseline included, so that
  imbalance belongs to the current game and not to A or B. A2 makes Fire a little stronger (78 % against 72 %). Seat bias
  stays inside 36-58 %.
- **Building kills**: A and A2 bring the first building loss forward (18:46 -> 14:28 / 10:17) and the first tower loss
  (20:32 -> 17:59 / 12:11), and the loser loses more buildings (0.9 -> 1.4). Bases fall sooner, but games still end by
  concede.
- **Easy bots** rarely close a game: 54 % of baseline games reach the 30:00 limit, 71 % with A. Shorter games at easy level
  would need bot changes (ai-coder), not data.
- **B** is noise. The bot trains about one siege unit per side per game, and the siege units shoot buildings only when the
  army happens to get that far. A + B is slower than A alone (-1:25 against -3:16). A likely cause is the siege units
  taking soldier pop away from the bot's line, but the arms are within noise of each other.

Per kingdom x seat cells (wins-games) and median length per kingdom: `fg_report.py` output (command below).

## 1. What each arm changes
**A `fg_a_pacing`** (`tools/balance_lab/variants/fg_a_pacing.json`, data only):
- all 30 buildings of the 4 kingdoms: -25 % max HP (keeps -30 %, Ice walls -40 %)
- towers -25 % damage, keep arrows -20 %
- the 59 trained units: soldiers train 20 % faster, workers 25 % faster

**A2 `fg_a2_strong`** (`fg_a2_strong.json`):
- buildings -40 % HP (walls -50 %); towers and keep arrows -40 % damage
- soldiers train 30 % faster, workers 40 % faster
- bot knobs, both sides: `attack_ratio` and `attack_ratio_floor` x0.85, `attack_patience` 90 -> 60 s,
  `attack_full_pop` 20 -> 16, `first_attack_by` 10:00 -> 7:00

The first attack comes at 2:57 instead of 4:52. The run cannot tell how much of the -4:10 comes from the data half and how
much from the bot half. The next run should split them (A2 data only, and baseline + the bot knobs only).

**B `fg_b_siege`** (`fg_b_siege.json`):
- one siege unit per kingdom, x damage against buildings only:

  | Kingdom | Siege unit | Tier | Factor vs buildings |
  |---|---|---|---|
  | Fire | Ash Hurler (existing) | T1 | x2.0 |
  | Ice | Frost Mortar (existing) | T2 | x2.6, on top of its own Frost Shell x1.5 |
  | Shadow | **Grave Mangonel** (new) | T2 | x3.5 |
  | Nature | **Stoneroot Hurler** (new) | T2 | x3.5 |

  Each siege unit does about 22-29 DPS against buildings (0.15 DPS per crystal), so 4 of them drop a tower in about 7 s and
  a keep in about 23 s.
- siege units range 12-13 m, which outranges towers (11 m) and keeps (10 m)
- siege units pick an enemy building in range before any unit (`Unit.set_auto_target`, every 0.5 s)
- bots keep 15 % of soldier pop as siege, from Stronghold

**B2** = B with 30 % of soldier pop as siege (Ash Hurler included).

**A + B** = A's data + B's block.

The new units are lab data in `tools/balance_lab/faster_games/units/` (not in `data/units/`, so no game list, Data Lab, i18n
or Unit Guide scan sees them):

| Unit | Kingdom | Tier | Cost | Pop | Train | HP | Armor | Damage | Range | Cooldown | Speed |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Grave Mangonel | Shadow | T2 | 190 | 2 | 40 s | 170 | 5 | 28 | 13 | 3.4 s | 3.4 |
| Stoneroot Hurler | Nature | T2 | 185 | 2 | 40 s | 190 | 8 | 26 | 12.5 | 3.2 s | 3.2 |

In the lab, each sits in the Hall after the Hall bowman (slot 6, before the three new-units-12 slots). Its placeholder look
is the code-built capsule (no model).

## 2. Current median length (read first)
Map gate reports (both of these are mirror-only, so they are not comparable with this run):

| Map | Matches | Median | Notes |
|---|---|---|---|
| Thornwater, normal (`docs/tools/map_gate/thornwater/bots/normal/report.md`) | 40 | **14:04** | 88 % concede, 20 % with no winner by 24:00 |
| Quartermeet (`docs/tools/map_gate/quartermeet/`) | - | - | no median in the scorecard |

The target is 15:00-20:00 per pair (`docs/design/rush-balance.md` 8). The Crown Hollow non-mirror baseline here is **21:40
at normal** (22:24 hard, 30:00 easy), above the band, so a cut of 2-4 minutes would bring normal into the target.

## 3. Unit Lab matrix deltas
- **A / A2: 0 by construction.** They change only `train_time` (soldiers / workers) and building stats. Unit Lab fights
  spawn the units directly in an arena with no buildings, and no `max_hp`, damage, armor, speed or range of a unit changes.
  `balance_pass_2026-10-06.md` (Oathsworn / T2 cavalry / Flame Guard) is untouched.
- **B**: B's building factor and its target preference act only on buildings, so every existing pairwise result is
  unchanged. The only change is two more opponents in each mean. The focus matrix covered the 2 new units against all 47
  applied entries, 4 seeds, 380 fights per basis (`tools/balance_lab/faster_games/fg_unit_lab_run.gd`,
  `fg_unitlab_delta.py`).

| | Equal crystals (720) | Equal pop (8) |
|---|---|---|
| Grave Mangonel mean score | **11** | **11** |
| Stoneroot Hurler mean score | **28** | **16** |
| Ash Hurler / Frost Mortar, for reference (final matrix) | 8 / 76 | 41 / 76 |
| Largest move of an existing entry | 3.9 points (Bloomtender 5 -> 9) | 3.3 points (Nightbolt 22 -> 25) |
| Entries crossing a 70 / 30 outlier line | Vinelasher (69 -> 70) | Duskbolt / Emberdart Harrier, Bleakbow (28-29 -> 31-32) |

The two new units are weak against units, as asked ("strong vs buildings, weak vs units"). Stoneroot beats only
archers, casters and other siege at equal crystals. The four line crossings are entries that sat on the line already: each
moved 1-3 points. The Frost Mortar stays a strong unit against units (76 / 76), which matters only if B is kept.

## 4. If B is kept later: Unit Guide and French drafts (not written to the game files)
`data/ui/unit_guide.json` blocks, to add only with the `.tres` moved to `data/units/` (then `gen_guide.gd`,
`test_unit_guide`). Unit names stay English in French (glossary). Role `siege`.
- **Grave Mangonel**
  - class "Shadow siege"
  - pros: "Wrecks buildings from outside tower range", "Shoots buildings before units", "Long range and sight"
  - cons: "Helpless against any army", "Slow and costly in pop"
  - strong vs: Buildings, Towers
  - weak vs: Cavalry, Fast raiders
  - good with: Shadow Knight, Barrow Knight
- **Stoneroot Hurler**
  - class "Nature siege"
  - pros: "Wrecks buildings from outside tower range", "Sturdiest siege unit", "Outranges towers"
  - cons: "Slowest Nature unit", "Weak against units"
  - strong vs: Buildings, Towers
  - weak vs: Cavalry, Fast raiders
  - good with: Bramblehorn, Greenheart Oathkeeper
- French drafts (Québec French, per the glossary; to check with the translator pass): "Démolit les bâtiments hors de
  portée des tours" / "Tire sur les bâtiments avant les unités" / "Grande portée et vision" / "Sans défense contre une armée"
  / "Lent et coûteux en population" / "Arme de siège la plus robuste" / "Dépasse la portée des tours" / "Unité Nature la plus
  lente" / "Faible contre les unités". Class "Siège de l'Ombre" / "Siège de la Nature".
- Rank claims to verify if kept: "Slowest Nature unit" (3.2 m/s), "Sturdiest siege unit" (190 HP; the Frost Mortar has
  160 HP + 10 armor).

## 5. Method, caveats
- **Runner**: `python tools/balance_lab/faster_games/run_fg.py --run <name> --tick 30 --arms baseline,fg_a_pacing,...
  --levels normal --seeds 1-3`. Every match goes through `tools/godot_run.ps1`; the runner is resumable.
- **Report**: `python tools/balance_lab/faster_games/fg_report.py --run t30n --run t30b2 --run t30a2 --run t30x`.
- **Raw output**: `..\four-wizards-lab-runs\fg-t30n|t30b2|t30a2|t30x\`, 312 games in total.
- **Match script**: `tools/balance_lab/faster_games/fg_match.gd`. It extends `balance_match.gd`, applies the variant's
  `fg` block, and writes per-building death times, siege damage and siege units seen under `"fg"` in every result line.
- **Tick 30** (`docs/plan/bot-lab.md`: "quick sweeps"): the machine was shared with the Wave Strike / campaign agents (8-14
  Godot processes), and a tick-60 game took 15-20 real minutes. Arms are compared at the same tick, but the absolute medians
  can sit a little off a 60 Hz run. Confirm A2 at 60 Hz before shipping.
- **Live repo**: matches ran against the working tree while other agents edited it, and the arms of a cell ran side by side,
  so each arm saw the same code. A broken `unit.gd` (an identifier "Teams" mid-edit, about 20 minutes) and one navmesh bake
  that never finished gave 7 failed or errored games. They were rerun and are not counted.
- **Early stop**: ON, the same rule as the map gate. 8-22 % of games end "early-score"; the lab calls those as decided, and
  the bot would concede soon after.
- **Rush risk**: the rush targets (`rush-balance.md` 8: rush games ending before 8:00 <= 15 %, the early tower not to be
  weakened by a building-damage cut) were not rerun. A / A2 cut tower HP and damage, so a rusher-style batch is required
  before A2 goes in.
- **Shipping**: to try A2 in a real game, its data half would have to go into `data/` (gameplay / systems owners) and its
  bot half into `AIProfile` (ai-coder). A dev-only "apply variant at start" switch in `main.gd` (lead file) would let JS
  playtest it without changing the defaults.

## Files (all new, lab only)
`tools/balance_lab/variants/fg_a_pacing.json`, `fg_a2_strong.json`, `fg_b_siege.json`, `fg_b2_siege_heavy.json`,
`fg_ab_both.json`; `tools/balance_lab/faster_games/fg_match.gd`, `fg_unit_lab_run.gd`, `run_fg.py`, `fg_report.py`,
`fg_unitlab_delta.py`, `units/grave_mangonel.tres`, `units/stoneroot_hurler.tres`; this doc.
