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
