# Balance Lab scorecard: 2026-09-26_validation

**WARN, score 100 / 100** (best arm `baseline`). 4 matches, 0 failed. 2026-09-27 00:05. Limit 600 s, tick 60, sim on, wall 2058 s.

> **Low N**: as few as 2 games per kingdom in an arm. Score and win rates are a smoke of the lab, not a balance verdict (K1 / M1 stay WARN below 10 games).

Input: `C:/Users/elzzo/Documents/four-wizards-lab-runs/balance-2026-09-26_validation/results.jsonl`

Score = 100 - 2 x points outside 45-55 % (kingdoms 2/3, matchups 1/3). Arms: `baseline` 100, `grave_hound_dps` 10.

## Checks

| Id | Check | Status | Value | Target |
|---|---|---|---|---|
| R1 | Matches ran | **PASS** | 4 / 4 ok, 0 script errors | every match ends with a result, 0 SCRIPT ERROR |
| V1 | Variants applied | **PASS** | grave_hound_dps: grave_hound.attack_damage 8.0 -> 6.0 (grave_hound 9/9 live on the edited type) | every override found and applied, no variant error, every live unit of an overridden id uses the edited type |
| K1 | Kingdom win rates [baseline] | **WARN** | fire 50% (1/2), shadow 50% (1/2) | 45-55 % per kingdom (non-mirror); WARN 35-65 % or < 10 games |
| M1 | Matchups [baseline] | **WARN** | fire-shadow 1-1 | each matchup 45-55 % (both seat orders together) |
| K1 | Kingdom win rates [grave_hound_dps] | **WARN** | fire 100% (2/2), shadow 0% (0/2) | 45-55 % per kingdom (non-mirror); WARN 35-65 % or < 10 games |
| M1 | Matchups [grave_hound_dps] | **WARN** | fire-shadow 2-0 | each matchup 45-55 % (both seat orders together) |
| L1 | Median length [baseline] | **PASS** | 10:00, real ends (kill / concede) 0% (limit 10:00: length not judged) | 15:00-20:00 (rush-balance.md) |
| L1 | Median length [grave_hound_dps] | **PASS** | 10:00, real ends (kill / concede) 0% (limit 10:00: length not judged) | 15:00-20:00 (rush-balance.md) |
| S1 | Evidence [grave_hound_dps vs baseline] | **WARN** | lowest p 1.00 (fire-shadow) | a matchup change with p < 0.05 (Fisher exact on wins) |

## Improve next

1. N is small (2 games per matchup per arm): ~98 per arm are needed to see a 20-pt change, ~392 for 10 pts. Add seeds (-Seeds 1-12) and prefer -Tick 30 sweeps, confirmed at 60.

## Arm `baseline` (score 100)

| Kingdom | Wins / games | Win rate | 95 % interval |
|---|---|---|---|
| fire | 1 / 2 | 50 % | 9-91 % |
| shadow | 1 / 2 | 50 % | 9-91 % |

| Matchup | Wins | Draws | Games | Median length | Score share (first) |
|---|---|---|---|---|---|
| fire-shadow | 1-1 | 0 | 2 | 10:00 | 57 % |

Median length 10:00; ends {"time-score":2}; seat wins {"enemy":2,"none":0,"player":0}.

## Arm `grave_hound_dps` (score 10)

Overrides: `grave_hound.attack_damage` 8.0 -> 6.0

| Kingdom | Wins / games | Win rate | 95 % interval |
|---|---|---|---|
| fire | 2 / 2 | 100 % | 34-100 % |
| shadow | 0 / 2 | 0 % | 0-66 % |

| Matchup | Wins | Draws | Games | Median length | Score share (first) |
|---|---|---|---|---|---|
| fire-shadow | 2-0 | 0 | 2 | 10:00 | 59 % |

Median length 10:00; ends {"time-score":2}; seat wins {"enemy":1,"none":0,"player":1}.

## `grave_hound_dps` vs baseline

| Matchup | Win rate (first) base -> variant | Score share base -> variant | Toward 50 % | Significance |
|---|---|---|---|---|
| fire-shadow | 50 % -> 100 % | 57 % -> 59 % (+2.8 pts) | no | noise at this N (p 1.00, 4 games; ~98 per arm to see a 20-pt change) |

| Kingdom | Win rate base -> variant | Significance |
|---|---|---|
| fire | 50 % -> 100 % | noise at this N (p 1.00, 4 games; ~98 per arm to see a 20-pt change) |
| shadow | 50 % -> 0 % | noise at this N (p 1.00, 4 games; ~98 per arm to see a 20-pt change) |

Median length change +0 s. Score share is the continuous signal (sensitive at small N); win rate is the verdict.
