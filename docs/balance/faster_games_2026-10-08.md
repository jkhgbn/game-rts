# Faster games, experiment C: more starting workers (2026-10-08)

JS 2026-10-08 (`docs/ideas/jss_asks.md`): "to make skirmish games shorter, start with more workers". Same method as
`faster_games_2026-10-06.md` (bot-vs-bot, Crown Hollow, all 4 kingdoms, both seats). **Nothing is enabled by default**:
every arm is a Balance Lab variant applied in memory by the lab match script; `data/` and `scripts/` are untouched.

## Verdict
**More workers alone is a weak lever, and the strong form (triple) breaks balance. Keep A2 as the main proposal.**
- **C1** (6 workers): median **22:18 -> 20:18 (-2:00, 90 % interval -4:34 .. +0:04, p = 0.02)**. That is a small cut, and
  the interval touches 0. The bot already trains up to 6 workers by 3:00 in the baseline, so C1 is only a head start of
  about 2 minutes (+7 % crystals gathered at 3:00).
- **C2** (9 workers): **-5:38 (-10:02 .. -2:04, p < 0.001)**, the largest cut, but **Ice wins 0 of 18 games**
  (kingdom spread 89 points). Early leads snowball: the side that attacks first wins 81 % of games (58 % in baseline).
  Rejected.
- **C3** (C1 + A2): -3:24 (p = 0.002). That is **no better than A2 alone** (-4:07 in this rerun). Extra workers add nothing
  on top of A2.
- **C4** (C1 + the extra workers' cost in crystals, 400 / Nature 370): -4:16 (p = 0.02, N = 24). Fire wins 92 %, Shadow 33 % and Ice 25 %
  (spread 67). The bank does matter (C4 is shorter than C1), but it skews the kingdoms. Not recommended.

Recommendation for JS: **do not raise the starting workers for match length.** For length, playtest A2 (data half + bot
knobs, see the 10-06 doc). If JS wants a quicker *opening* (less waiting at 0:00), C1 is the only safe worker arm: rush
risk stays low (1 / 36 games ended before 8:00) and no unit stat moves. It costs a little balance, though: Ice drops
from 22 % to 11 % and early leads stick more (73 % against 53 %). Only consider C1 together with an Ice fix. The Ice bot does not turn
extra income into army: its army pop at 7:00 stays flat with more workers, while the other kingdoms gain 2-7 pop
(ai-coder item, below).

## Starting state today (what the arms double / triple)
| | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| Starting workers (`scripts/world/skirmish.gd` `_on_navigation_ready`: 2 on home node a, 1 on node b) | 3 Cinder Hand | 3 Gloom Thrall | 3 Rime Hauler | 3 Sprigling |
| Worker cost | 50 | 50 | 50 | 40 |
| Starting crystals (`scripts/economy/economy.gd` `START_CRYSTALS`, every kingdom) | 250 | 250 | 250 | 250 |
| Bot worker target (`AIProfile.worker_target_home` / expanded / x2) | 6 / 9 / 12 | 6 / 9 / 12 | 6 / 9 / 12 | 7 / 9 / 12 (Nature +1 home) |

The baseline bot reaches 6.2 workers per side at 3:00 (normal and hard), so C1 starts at the count the bot would reach
anyway, and C2 starts at the "expanded" target.

## Main table (normal, tick 30, early stop on, limit 30:00, Crown Hollow, 12 ordered pairs)
Fresh baseline and A2: `commander.gd` and unit scripts changed since 2026-10-06, so both were rerun on today's code.
N = 36 (3 seeds, 9 games per kingdom x seat cell), except A2 and C4: 24 (2 seeds, 6 per cell), for lack of machine time.

| Arm | N | **Median** | Change vs baseline (90 % interval, Mann-Whitney p) | p25-p75 | Kill / concede | Win % F / S / I / N | Spread | Ends < 8:00 | < 12:00 | 1st attack | 1st building lost | Gathered at 3:00 / side |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| baseline | 36 | **22:18** | - | 19:40-26:19 | 67 % | 67/61/22/50 | 44 | 0 | 0 | 4:52 | 16:30 | 1378 |
| A2 `fg_a2_strong` | 24 | **18:10** | **-4:07** (-7:36 .. -0:48, p = 0.007) | 11:56-22:04 | 96 % | 33/33/42/92 | 58 | 5 | 6 | 2:56 | 7:53 | 1405 |
| C1 `fg_c1_workers2x` | 36 | **20:18** | -2:00 (-4:34 .. +0:04, p = 0.020) | 13:08-21:57 | 72 % | 72/44/11/72 | 61 | 1 | 4 | 5:21 | 17:31 | 1475 |
| C2 `fg_c2_workers3x` | 36 | **16:40** | **-5:38** (-10:02 .. -2:04, p < 0.001) | 11:01-20:01 | 81 % | 89/44/0/67 | 89 | 2 | 7 | 4:54 | 13:44 | 1945 |
| C3 `fg_c3_workers2x_a2` | 36 | **18:54** | -3:24 (-6:38 .. -1:01, p = 0.002) | 11:58-21:36 | 94 % | 67/44/28/61 | 39 | 2 | 7 | 3:34 | 12:51 | 1461 |
| C4 `fg_c4_workers2x_crystals` | 24 | **18:02** | -4:16 (-10:02 .. -1:19, p = 0.018) | 12:17-22:52 | 62 % | 92/33/25/50 | 67 | 0 | 2 | 5:10 | 11:16 | 1481 |

Easy / hard (1 seed, 12 games per arm, 3 per cell: indicative only):
| Arm | Level | Median | Change | p | Ends < 8:00 | Win % F / S / I / N |
|---|---|---|---|---|---|---|
| baseline | easy | 30:00 | - | - | 0 | 67/33/33/67 |
| C1 | easy | 30:00 | 0:00 | 0.60 | 0 | 67/17/50/67 |
| C3 | easy | 30:00 | 0:00 | 0.69 | 0 | 67/50/33/33 |
| baseline | hard | 22:36 | - | - | 0 | 50/33/67/50 |
| C1 | hard | 20:55 | -1:42 | 0.56 | 0 | 67/50/17/67 |
| C3 | hard | 17:51 | -4:45 | 0.60 | 1 | 83/67/33/17 |

Easy bots still run to the 30:00 limit in most games (75-83 % time-score) whatever the start. As on 10-06, shorter easy games
need bot changes, not data.

How to read it:
- **Comparison with 10-06**: today's baseline is 22:18 (21:40 then) and A2 is 18:10 (17:31 then). Both moved by under a
  minute, and A2's cut is the same (-4:07 against -4:10), so the 10-06 conclusions hold on today's code.
- **First attack** (median per side that attacked) does not move with C1 / C2 / C4 (4:52 -> 4:54-5:21). The extra income
  goes into economy and buildings first. Only the A2 bot knobs bring the attack forward (2:56 / 3:34).
- **First building lost** comes later with C1 (17:31) and sooner with C2 / C3 / C4 (11-14 min). A2 brings it the most
  forward (7:53), because its towers are weaker.
- **Ice**: 22 % baseline -> 11 % C1 -> 0 % C2. Ice's army pop at 7:00 stays at 6-7 whatever the start (Fire goes 3.9 ->
  11.5 with C2). The Ice bot banks the extra income or spends it on non-army items. That is a Commander build-order
  issue for Ice, not a data one.

## Rush risk and early aggression
**The rusher-style batch could not be run.** `lab_match.gd --style=rusher` falls back to balanced ("LAB: the bot has no
styles yet": there is no `AIProfile.apply_style` and no Commander `style`). The `rush-balance.md` 8 rush targets
cannot be measured until ai-coder adds the rusher style. The 48 rusher games started were Balanced games in practice and
are not counted (raw data in `fg-c8rp`). The Balanced games give these proxies:

| Arm | Ends before 8:00 | Worker kills by the enemy before 8:00 / game | A 7:00 worth lead >= 1.10 x wins | First attacker wins | First attacker wins before 12:00 |
|---|---|---|---|---|---|
| baseline | 0 / 36 | 5.1 | 53 % | 58 % | 3 / 36 |
| A2 | 5 / 24 | 6.6 | 76 % | 62 % | 3 / 24 |
| C1 | 1 / 36 | 7.6 | 73 % | 72 % | 9 / 36 |
| C2 | 2 / 36 | 11.7 | 80 % | 81 % | 11 / 36 |
| C3 | 2 / 36 | 7.3 | 68 % | 64 % | 8 / 36 |
| C4 | 0 / 24 | 7.2 | 75 % | 62 % | 6 / 24 |

- **Games ending before 8:00** stay under the 15 % target in every C arm (0-6 %). A2 is the arm at risk (5 / 24 = 21 %).
- **Early aggression gets stronger with more workers.** More workers die to early raids (5.1 -> 7.6 -> 11.7 per game),
  and early leads stick: a 1.10 x worth lead at 7:00 wins 73-80 % of games, against 53 % in baseline. The first attacker
  wins 72 % (C1) / 81 % (C2) against 58 %. The game gets shorter because the first edge decides it sooner, not because
  armies grow faster. A human who loses the opening would feel this as "no comeback".

## Unit Lab
Unaffected, by construction: **C1 / C2 / C4 change no unit or building field** (their variants hold only the `fg` start
block), and C3's unit changes are A2's `train_time` only. The Unit Lab spawns units directly in an arena with no
economy and never reads `train_time` (`tools/unit_lab` has no reference to it) or the starting workers / crystals. The
Oathsworn / T2 cavalry / Flame Guard matrices of `balance_pass_2026-10-06.md` do not change, so no Unit Lab run was needed.

## Method, caveats
- **Arms**: `tools/balance_lab/variants/fg_c1_workers2x.json`, `fg_c2_workers3x.json`, `fg_c3_workers2x_a2.json` (= A2 +
  6 workers), `fg_c4_workers2x_crystals.json`. New `fg` keys in `tools/balance_lab/faster_games/fg_match.gd`:
  `"start_workers": N` (extra workers spawned on the lab's match-start frame beside the first three, on home nodes a / b
  in the same 2:1 pattern, using the side's own worker type) and `"start_crystals": 400 | "+150" | "workers"` ("workers"
  = + the extra workers' cost). Every result line logs the applied start under `fg.start`.
- **Runner**: `python tools/balance_lab/faster_games/run_fg.py --run c8n --tick 30 --arms baseline,fg_a2_strong,fg_c1_workers2x,fg_c2_workers3x,fg_c3_workers2x_a2,fg_c4_workers2x_crystals --levels normal --seeds 1-3`
  (`c8h` / `c8e`: hard / easy, seed 1). The runner now also takes `--style`, requeues a game that errored (repo mid-edit)
  with a 3-minute pause, and skips jobs whose JSON is a placeholder.
- **Report**: `python tools/balance_lab/faster_games/fg_report.py --run c8n --run c8h --run c8e`. New tables: early numbers
  (ends before 8:00 / 12:00, first attack, workers and crystals at 3:00), early aggression, and rush batches (for when a
  rusher style exists).
- **Raw output**: `..\four-wizards-lab-runs\fg-c8n|c8h|c8e\`, 264 games (`c8_report.md` beside them).
- **Tick 30**, as on 10-06 (quick sweeps; arms are compared at the same tick). Confirm the chosen arm at 60 Hz before shipping.
- **Live repo**: 6 games errored at start (a `SaveCodec` parse error while another agent edited `unit.gd` /
  `building.gd`). They were rerun and are not counted. The arms of a cell ran side by side, so each arm saw the same code.
- **Time budget**: A2 and C4 have 2 seeds (24 games), easy / hard 1 seed (12). Easy games take 5-14 real minutes each.

## Proposed follow-ups
1. ai-coder: the Ice Commander does not turn extra income into army (army pop at 7:00 stays flat across C1 / C2). This
   bot issue shows up in today's baseline too (Ice 22 %).
2. ai-coder: a rusher style (`AIProfile.apply_style` or a Commander `style`). Without it, the rush targets of
   `rush-balance.md` 8 cannot be measured for A2 or any later pacing change.
3. If C1 is wanted for the opening feel: playtest it at 60 Hz with JS, after the Ice fix.

## Files (all lab only)
`tools/balance_lab/variants/fg_c1_workers2x.json`, `fg_c2_workers3x.json`, `fg_c3_workers2x_a2.json`,
`fg_c4_workers2x_crystals.json`; `tools/balance_lab/faster_games/fg_match.gd` (start keys), `run_fg.py` (`--style`,
requeue, placeholder skip), `fg_report.py` (new tables); this doc.
