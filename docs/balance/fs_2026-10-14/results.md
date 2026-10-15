# Fire vs Shadow (normal pace) and unit research: results, night of 2026-10-14 / 15

All runs: CI worktree at `playtest-2026-10-14-5` (311d10f7), `run_fg.py`, normal pace, normal difficulty, tick 60,
3 games at a time. Runs in `Documents\four-wizards-lab-runs\fg-<run>`; reports with `fg_report.py --run <run>`.

## Unit research on vs off (UR.B1, run `ur1-normal`, Crown Hollow, all 12 pairs, seeds 1-2)
| Arm | Fire | Shadow | Ice | Nature | Median length |
|---|---|---|---|---|---|
| research on (shipped) | 58 % | 17 % | 83 % | 42 % | 15:54 |
| research off (`ur_off`) | 67 % | 25 % | 58 % | 50 % | 16:44 |
12 games per kingdom: the gaps are within noise (one SD ~14 points). The bots bought only 29 rows in 24 games
(top: Thornling Briar Coat 8, Rimeshield Frostrim 7, Shardcaster Deep Chill 3, Shade Siphoning Blades 3), so research
barely moves bot games at normal difficulty. No research number changed.

## Fire-Shadow levers (plan.md), Fire wins
| Arm | CH seeds 1-6 | CH seeds 7-12 | TW seeds 1-6 | Total |
|---|---|---|---|---|
| baseline | 11 / 12 | 8 / 12 | 7 / 12 | **26 / 36 (72 %)** |
| L1 Shadow champion at 2:00 | 5 / 12 | 8 / 12 | 10 / 12 | **23 / 36 (64 %)** |
| L2 Shadow line defence | 8 / 12 | - | - | - |
| L3 Gloom Thrall HP 70 | 9 / 12 | - | - | - |
L1 looked decisive on the first 12 games and did not hold: 12-game screens are too noisy for this pair; round 2
uses 36 games per arm. L1 on all 12 pairs (CH seeds 1-2, run `fs2-all`): Fire 42 / Shadow 42 / Ice 42 / Nature 75 %.

## Round 2 (36 games per arm: CH seeds 1-12 run `fs3-ch`, TW seeds 1-6 run `fs3-tw`), Fire wins
| Arm | CH (24) | TW (12) | Total |
|---|---|---|---|
| baseline (round 1 runs) | 19 / 24 | 7 / 12 | 26 / 36 (72 %) |
| combo A = L1 + L2 (Shadow bot only, normal pace) | 10 / 24 | 11 / 12 | 21 / 36 (58 %) |
| combo B = L1 + L2 + L3 (Gloom Thrall HP 70) | 11 / 24 | 8 / 12 | **19 / 36 (53 %)** |
| L4 armor 5 on Nightbolt / Grave Hound / Bleakbow / Barrow Ghoul | 14 / 24 | 9 / 12 | 23 / 36 (64 %) |
Combo B is closest to 50 / 50 but L3 changes a unit (Blitz, missions and the player's Shadow workers too): JS's call
(plan.md question 1). Combo A only changes the Shadow bot at normal pace. Thornwater stays Fire-heavy with combo A.

## Round 3: combo A on all 12 pairs (CH seeds 3-4, with baseline) + Fire-Shadow CH seeds 13-18
Running (`fs4-all`, `fs4-ch`).
