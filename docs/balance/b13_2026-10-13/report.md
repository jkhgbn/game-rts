# B13 balance: Shadow (Mother Hush) and Ice, 2026-10-13

Spec: `docs/design/balance-2026-10-13-shadow-ice.md`. Changes measured:
- **H1**: Mother Hush's Smoke Cloak / Night of Knives also `daze` the enemies that were attacking her, 2.0 s (heroes 1.0 s),
  skirmish only; their orders are never touched (`helper_abilities.gd _drop_targeting`, `smoke_daze_here()`).
- **I1**: Flash Freeze damage 20/30/40 -> 40/55/70, cooldown 20/18/16 -> 18/16/14 (`data/spells/flash_freeze.tres`; also missions).

## Screens (main tree, before the other agents' edits)
| Run | Games | Result | Bar |
|---|---|---|---|
| `fg-b13-h1-n-ch` Fire-Shadow normal CH | 12 | Fire 8 / 12 | <= 8 / 12 |
| `fg-b13-h1-bz-ch` Fire-Shadow Blitz CH | 12 | Fire 5 / 12 | 4-8 / 12 |
| `fg-b13-i1-n-ch` + `-n-tw` Ice pairs normal | 36 | Ice 19 / 36 | >= 15 / 36 |

## Confirmation (CI worktree at f9b71e34 + H1 + I1 only, all 12 ordered pairs, seeds 1-4)
| Run | Fire | Ice | Nature | Shadow | Fire-Shadow | Seat 0 |
|---|---|---|---|---|---|---|
| normal Crown Hollow | 14 / 24 | 9 / 24 | 15 / 24 | 10 / 24 | 5 / 8 | 25 / 48 |
| normal Thornwater | 16 / 24 | 8 / 24 | 17 / 24 | 7 / 24 | 6 / 8 | 28 / 48 |
| **normal total** | **63 %** | **35 %** | **67 %** | **35 %** | **11 / 16** | 55 % |
| Blitz Crown Hollow | 10 / 24 | 10 / 24 | 16 / 24 | 12 / 24 | 4 / 8 | 27 / 48 |
| Blitz Thornwater | 16 / 24 | 10 / 24 | 13 / 24 | 9 / 24 | 6 / 8 | 22 / 48 |
| **Blitz total** | **54 %** | **42 %** | **60 %** | **44 %** | **10 / 16** | 51 % |

Before (confirm_2026-10-13): normal Fire 72 / Ice 39 / Nature 60 / Shadow 28, Fire-Shadow 13 / 16; Blitz Fire 58 / Ice 29 /
Nature 60 / Shadow 52, Fire-Shadow 8 / 16.

## Reading
- Shadow normal 28 -> 35 %, Fire 72 -> 63 %: the drift is much smaller but Fire-Shadow normal 11 / 16 is still above the
  6-10 bar. Blitz Ice 29 -> 42 % (bar 38 %): met. Normal Ice 35 % (bar 40 %): not met; Nature 67 % is just over 65 %.
- Kept (committed): H1 + I1 are better than before at both paces. Next round (spec fallbacks): H2 (Smoke Cloak cooldown
  22 -> 16 s, autocast at 2+ attackers) for Shadow at normal pace, I2 (Rime Bolt 45/58/72 -> 55/70/85) for Ice at normal pace,
  re-screen; Nature watch.

## Round 2 (H2 + I2) screens, normal pace — NOT kept
H2 = Smoke Cloak 16 s / autocast at 2+ attackers (skirmish); I2 = Rime Bolt 55/70/85. CI worktree at 69b0b985 + the patch
(`round2_h2_i2.patch` in this folder).
| Run | Games | Result |
|---|---|---|
| Fire-Shadow CH | 12 | Fire 10 / 12 |
| Fire-Shadow TW | 12 | Fire 8 / 12 |
| Ice pairs CH | 18 | Ice 7 / 18 |
| Ice pairs TW | 18 | Ice 5 / 18 |
Fire-Shadow 18 / 24 (round 1: 11 / 16) and Ice 12 / 36 = 33 % (round 1: 35 %): no gain within noise, so the patch is not
applied. Next: a diagnosis of WHY Shadow and Ice lose at normal pace (game logs) before another knob.

## Diagnosis levers (diagnosis.md), screens at normal pace (CI worktree, 69b0b985 + patch)
| Change | Fire-Shadow normal (24) | Ice pairs normal (36) | Blitz Fire-Shadow (12) | Kept |
|---|---|---|---|---|
| Cause 1: Fireball 60/66/78 | Fire 17 / 24 | - | - | no (no gain) |
| Causes 1 + 2 + 3 | Fire 18 / 24 | Ice 16 / 36 (44 %) | Shadow 9 / 12 (moved) | no |
| **Cause 3 alone** (Shadow 7 home workers, Ice gets the Blitz aggression knobs; normal pace + normal difficulty only) | - | **Ice 15 / 36 (42 %)** | 6 / 12 (unchanged) | **yes** |
Cause 2 (wizard retreat at 50 % without an escape) is built but OFF (AICasts.retreat_rule): it moved Blitz and did not help
Fire-Shadow. Fire-Shadow at normal pace (~70 % Fire) is still open: Shadow needs a different lever (diagnosis: champions /
worker raids decide normal games).
