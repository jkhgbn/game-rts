# Balance Lab suggest: 2026-09-27_0001

Win rates from `C:/Users/elzzo/Documents/four-wizards-lab-runs/first-batch-sim/results.jsonl` (non-mirror, baseline arm). Table = Data Lab B1 formulas: EHP = max_hp x (1 + armor / 100), DPS = attack_damage / attack_cooldown, per 100 crystals; ratios vs the slot's peers: combat units vs combat units, support units vs support units (their support is not in these stats, so they get no DPS or cost knob). Power = sqrt(EHP/100 x DPS/100). Expected shift = 3.0 pts per 10 % unit power (a prior; run the variant to measure).

## Kingdom win rates

| Kingdom | Win rate | Need |
|---|---|---|
| fire | 83 % (5/6) | nerf |
| shadow | 17 % (1/6) | buff |
| ice | 17 % (1/6) | buff |
| nature | 83 % (5/6) | nerf |

## Top knobs (one per unit, written as variants)

1. **blaze_rider** (fire, slot C): cost 180 -> 212. power/cost x1.40 of row. Score 20.7, toward 45-55 %.
   `run_balance.ps1 -Variants "C:/Users/elzzo/Documents/four-wizards-rts/docs/balance/lab/suggest_first-batch/variants/blaze_rider_cost.json"`
2. **rimeshield** (ice, slot Z): max_hp 150 -> 132, attack_damage 11 -> 12.4. shape EHP x1.29 / DPS x0.78 of peers. Score 12.4, neutral.
   `run_balance.ps1 -Variants "C:/Users/elzzo/Documents/four-wizards-rts/docs/balance/lab/suggest_first-batch/variants/rimeshield_trade.json"`
3. **rime_colossus** (ice, slot V): max_hp 520 -> 463, attack_damage 28 -> 31. shape EHP x1.15 / DPS x0.73 of peers. Score 11.4, neutral.
   `run_balance.ps1 -Variants "C:/Users/elzzo/Documents/four-wizards-rts/docs/balance/lab/suggest_first-batch/variants/rime_colossus_trade.json"`

## Data Lab leads

Units the Data Lab flags (B1 per-100 ratio beyond x1.6 of the whole row, or raw max_hp / damage beyond x2.5): what the lab says.

- **blaze_rider** (fire, slot C): flagged for raw max_hp x3.14 of the row, raw damage x2.57 of the row. Against its peers (blaze_rider, grave_hound): EHP x1.10, DPS x0.81, power/cost x0.95 (within x1.25: the flag comes from mixing combat and support units in one slot). fire win rate 83 % (5/6). Top knob: cost 180 -> 212 (row basis, power -15 %, toward 45-55 %, score 20.7).
- **ash_hurler** (fire, slot V): flagged for EHP/100 x0.23 of the row, raw max_hp x0.14 of the row. Against its peers (ash_hurler, rime_colossus, bramblehorn, shadow_knight): EHP x0.23, DPS x1.06, power/cost x0.52. fire win rate 83 % (5/6). Top knob: max_hp 60 -> 75 (peers basis, power +12 %, away from 45-55 %, score 8.0). Without pushing fire away from 45-55 %: max_hp 60 -> 80, attack_damage 24 -> 18 (neutral, score 6.1).
- **rime_seer** (ice, slot C): flagged for DPS/100 x0.45 of the row. Against its peers (rime_seer, bloomtender): EHP x0.96, DPS x0.95, power/cost x0.95 (within x1.25: the flag comes from mixing combat and support units in one slot). ice win rate 17 % (1/6). Top knob: max_hp 70 -> 82 (row basis, power +8 %, toward 45-55 %, score 10.1).
- **bloomtender** (nature, slot C): flagged for DPS/100 x0.50 of the row. Against its peers (rime_seer, bloomtender): EHP x1.04, DPS x1.05, power/cost x1.05 (within x1.25: the flag comes from mixing combat and support units in one slot). nature win rate 83 % (5/6). Top knob: max_hp 60 -> 67 (row basis, power +6 %, away from 45-55 %, score 4.1). Without pushing nature away from 45-55 %: max_hp 60 -> 67, cost 90 -> 95 (neutral, score 2.8).
- **grave_hound** (shadow, slot C): flagged for DPS/100 x2.20 of the row. Against its peers (blaze_rider, grave_hound): EHP x0.90, DPS x1.19, power/cost x1.05 (within x1.25: the flag comes from mixing combat and support units in one slot). shadow win rate 17 % (1/6). Top knob: cost 70 -> 87 (row basis, power -19 %, away from 45-55 %, score 13.0). Without pushing shadow away from 45-55 %: attack_damage 8 -> 6, cost 70 -> 61 (neutral, score 0.3).


## All candidates

| # | Unit | Kingdom | Basis | Knob | Reason | Power | Expected shift | Verdict | Score |
|---|---|---|---|---|---|---|---|---|---|
| 1 | blaze_rider | fire | row | cost 180 -> 212 | power/cost x1.40 of row | -15 % | -4.6 pts | toward 45-55 % | 20.7 |
| 2 | grave_hound | shadow | row | cost 70 -> 87 | power/cost x1.54 of row | -19 % | -5.8 pts | away from 45-55 % | 13.0 |
| 3 | blaze_rider | fire | row | attack_damage 18 -> 14.8 | DPS/100 x1.50 of row | -9 % | -2.8 pts | toward 45-55 % | 12.5 |
| 4 | rimeshield | ice | peers | max_hp 150 -> 132, attack_damage 11 -> 12.4 | shape EHP x1.29 / DPS x0.78 of peers | -0 % | -0.1 pts | neutral | 12.4 |
| 5 | blaze_rider | fire | row | max_hp 220 -> 183 | EHP/100 x1.47 of row | -9 % | -2.7 pts | toward 45-55 % | 11.7 |
| 6 | rime_colossus | ice | peers | max_hp 520 -> 463, attack_damage 28 -> 31 | shape EHP x1.15 / DPS x0.73 of peers | -0 % | -0.0 pts | neutral | 11.4 |
| 7 | grave_hound | shadow | row | attack_damage 8 -> 6 | DPS/100 x2.20 of row | -13 % | -4.0 pts | away from 45-55 % | 10.8 |
| 8 | rime_colossus | ice | peers | attack_damage 28 -> 33 | DPS/100 x0.73 of peers | +8 % | +2.4 pts | toward 45-55 % | 10.1 |
| 9 | rime_seer (support) | ice | row | max_hp 70 -> 82 | EHP/100 x0.74 of row | +8 % | +2.4 pts | toward 45-55 % | 10.1 |
| 10 | shardcaster | ice | peers | attack_damage 9 -> 10.3 | DPS/100 x0.77 of peers | +7 % | +2.0 pts | toward 45-55 % | 8.4 |
| 11 | ash_hurler | fire | peers | max_hp 60 -> 75 | EHP/100 x0.23 of peers | +12 % | +3.5 pts | away from 45-55 % | 8.0 |
| 12 | rime_colossus | ice | peers | attack_damage 28 -> 33, cost 290 -> 313 | DPS/100 x0.73 of peers, cost keeps power | +0 % | +0.0 pts | neutral | 7.9 |
| 13 | rimeshield | ice | peers | attack_damage 11 -> 12.4 | DPS/100 x0.78 of peers | +6 % | +1.9 pts | toward 45-55 % | 7.8 |
| 14 | shardcaster | ice | peers | attack_damage 9 -> 10.3, cost 110 -> 118 | DPS/100 x0.77 of peers, cost keeps power | -0 % | -0.1 pts | neutral | 6.5 |
| 15 | rimeshield | ice | peers | max_hp 150 -> 132, cost 95 -> 89 | EHP/100 x1.29 of peers, cost keeps power | -0 % | -0.1 pts | neutral | 6.3 |
| 16 | rimeshield | ice | peers | attack_damage 11 -> 12.4, cost 95 -> 101 | DPS/100 x0.78 of peers, cost keeps power | +0 % | +0.1 pts | neutral | 6.2 |
| 17 | ash_hurler | fire | peers | max_hp 60 -> 80, attack_damage 24 -> 18 | shape EHP x0.23 / DPS x1.06 of peers | -0 % | -0.0 pts | neutral | 6.1 |
| 18 | ash_hurler | fire | peers | max_hp 60 -> 75, cost 140 -> 157 | EHP/100 x0.23 of peers, cost keeps power | -0 % | -0.1 pts | neutral | 6.1 |
| 19 | rimeshield | ice | peers | max_hp 150 -> 132 | EHP/100 x1.29 of peers | -6 % | -1.9 pts | away from 45-55 % | 4.7 |
| 20 | bloomtender (support) | nature | row | max_hp 60 -> 67 | EHP/100 x0.80 of row | +6 % | +1.7 pts | away from 45-55 % | 4.1 |
| 21 | rime_seer (support) | ice | row | max_hp 70 -> 82, cost 120 -> 130 | EHP/100 x0.74 of row, cost keeps power | +0 % | +0.0 pts | neutral | 4.0 |
| 22 | bloomtender (support) | nature | row | max_hp 60 -> 67, cost 90 -> 95 | EHP/100 x0.80 of row, cost keeps power | -0 % | -0.0 pts | neutral | 2.8 |
| 23 | grave_hound | shadow | row | attack_damage 8 -> 6, cost 70 -> 61 | DPS/100 x2.20 of row, cost keeps power | -0 % | -0.1 pts | neutral | 0.3 |
| 24 | blaze_rider | fire | row | max_hp 220 -> 183, cost 180 -> 164 | EHP/100 x1.47 of row, cost keeps power | +0 % | +0.0 pts | neutral | -0.1 |
| 25 | blaze_rider | fire | row | attack_damage 18 -> 14.8, cost 180 -> 162 | DPS/100 x1.50 of row, cost keeps power | +1 % | +0.2 pts | neutral | -0.8 |
| 26 | ash_hurler | fire | peers | cost 140 -> 105 | power/cost x0.52 of peers | +33 % | +10.0 pts | away from 45-55 % | -9.0 |

## Unit table (barracks slots)

| Unit | Kingdom | Slot | Cost | EHP/100 | DPS/100 | Power | vs combat peers (EHP / DPS / power) | vs whole row (EHP / DPS) |
|---|---|---|---|---|---|---|---|---|
| flame_guard | fire | Z | 90 | 144 | 13.3 | 43.9 | x1.02 / x0.98 / x1.01 | x1.02 / x0.98 |
| ember_archer | fire | X | 100 | 70 | 7.5 | 22.9 | x0.99 / x0.99 / x1.01 | x0.99 / x0.99 |
| blaze_rider | fire | C | 180 | 122 | 11.1 | 36.9 | x1.10 / x0.81 / x0.95 | x1.47 / x1.50 |
| ash_hurler | fire | V | 140 | 43 | 7.8 | 18.3 | x0.23 / x1.06 / x0.52 | x0.23 / x1.06 |
| rimeshield | ice | Z | 95 | 182 | 10.5 | 43.7 | x1.29 / x0.78 / x1.00 | x1.29 / x0.78 |
| shardcaster | ice | X | 110 | 76 | 5.8 | 21.1 | x1.08 / x0.77 / x0.93 | x1.08 / x0.77 |
| rime_seer (support: shield) | ice | C | 120 | 61 | 3.3 | 14.3 | x0.96 / x0.95 / x0.95 | x0.74 / x0.45 |
| rime_colossus | ice | V | 290 | 215 | 5.4 | 34.0 | x1.15 / x0.73 / x0.97 | x1.15 / x0.73 |
| thornling | nature | Z | 60 | 117 | 14.8 | 41.6 | x0.83 / x1.09 / x0.95 | x0.83 / x1.09 |
| burr_slinger | nature | X | 70 | 71 | 8.3 | 24.4 | x1.01 / x1.10 / x1.08 | x1.01 / x1.10 |
| bloomtender (support: heal) | nature | C | 90 | 67 | 3.7 | 15.7 | x1.04 / x1.05 / x1.05 | x0.80 / x0.50 |
| bramblehorn | nature | V | 200 | 190 | 7.5 | 37.7 | x1.01 / x1.02 / x1.07 | x1.01 / x1.02 |
| shade | shadow | Z | 80 | 138 | 13.8 | 43.5 | x0.98 / x1.02 / x1.00 | x0.98 / x1.02 |
| nightbolt | shadow | X | 100 | 65 | 7.7 | 22.4 | x0.92 / x1.01 / x0.99 | x0.92 / x1.01 |
| grave_hound | shadow | C | 70 | 100 | 16.3 | 40.4 | x0.90 / x1.19 / x1.05 | x1.20 / x2.20 |
| shadow_knight | shadow | V | 260 | 185 | 7.1 | 36.3 | x0.99 / x0.98 / x1.03 | x0.99 / x0.98 |
