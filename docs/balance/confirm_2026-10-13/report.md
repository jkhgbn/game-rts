# Balance confirmation after the code-review fixes (2026-10-13)

Measured by a balance agent (Opus medium, measure only); saved by the lead. Current main (after 81750691 and the
mission commits), shipped values, bot normal, all 12 ordered pairs, Crown Hollow + Thornwater.
Harness `tools/balance_lab/faster_games/run_fg.py` (same setup as `docs/balance/shadow_fire_2026-10-12/report.md`):
Normal = arm `baseline` tick 60; Blitz = `variants/bz_shipped.json` (real PaceSwitch.BLITZ) tick 30.
Runs `Documents\four-wizards-lab-runs\fg-confirm-1013-{n-ch,n-tw,bz-ch,bz-tw}`. Wall time 2 h 20.

**Résumé pour JS**
1. Blitz va bien : Fire 58 / Nature 60 / Shadow 52, Fire contre Shadow 8-8. Seul Ice reste faible (29 %, sous 35 % sur les deux cartes).
2. En vitesse normale, ça a dérivé depuis les correctifs : Fire 72-75 %, Shadow 28-31 % (17 % sur Crown Hollow), Fire bat Shadow 13 fois sur 16. Plus grand que le bruit ; cause en cours d'enquête.
3. Pas de crash ni de partie bloquée ; durée stable (Blitz ≈ 10:40 réel). Petit bogue `thief_band.gd:690` (nœud de cristal libéré), sans plantage.

## Normal (seeds 1-3, 72 games, 36 per kingdom)
| Map | N | Fire | Ice | Nature | Shadow | Fire-Shadow | Median |
|---|---|---|---|---|---|---|---|
| Crown Hollow | 36 | 72 % (13/18) | 39 % (7/18) | 72 % (13/18) | 17 % (3/18) | 6/6 | 18:03 |
| Thornwater | 36 | 78 % (14/18) | 28 % (5/18) | 50 % (9/18) | 44 % (8/18) | 4/6 | 15:38 |
| **All** | 72 | **75 %** | **33 %** | 61 % | **31 %** | **10/12** | 16:26 |

All 91 games (seed 4 partial): Fire 72 % (34/47), Ice 39 % (18/46), Nature 60 % (26/43), Shadow 28 % (13/46),
Fire-Shadow 13/16, median 16:34. Pairs (first named wins): Fire-Ice 10/16, Fire-Nature 11/15, Fire-Shadow 13/16,
Ice-Nature 3/14, Ice-Shadow 9/16, Nature-Shadow 11/14. Player seat 57 % (52/91).
vs the measured 10-12 baseline (Fire 60 / Ice 23 / Nature 67 / Shadow 50, F-S 7/16): Fire up, Shadow down beyond noise.
(The 10-12 report's "after" numbers 54 / 43 / 60 / 44 were composites, not measured.)

## Blitz shipped (seeds 1-3, 72 games)
| Map | N | Fire | Ice | Nature | Shadow | Fire-Shadow | Median game / real |
|---|---|---|---|---|---|---|---|
| Crown Hollow | 36 | 61 % | 28 % | 56 % | 56 % | 2/6 | 13:39 / 10:30 |
| Thornwater | 36 | 61 % | 28 % | 56 % | 56 % | 4/6 | 13:56 / 10:43 |
| **All** | 72 | 61 % | **28 %** | 56 % | 56 % | 6/12 | 13:48 / 10:37 |

All 96 games: Fire 58 % (28/48), Ice 29 % (14/48), Nature 60 % (29/48), Shadow 52 % (25/48), Fire-Shadow 8/16,
median 13:50 game / 10:38 real. Pairs: Fire-Ice 12/16, Fire-Nature 8/16, Fire-Shadow 8/16, Ice-Nature 4/16,
Ice-Shadow 6/16, Nature-Shadow 9/16. Seat 47/96. One game before 5:00.

## Health
No crash, timeout, requeue or missing result. 3 normal Crown Hollow games went to 30:00 (decided on score).
`SCRIPT ERROR scripts/ai/thief_band.gd:690` in 2 games (freed crystal node in `_start_strike`): fix routed to ai-coder.

## Diagnosis of the normal-pace drift (read-only agent, no Godot)
- The 10-12 normal baseline (`fg-twfix-ch|tw`) matches commit 5c58a538, so the gap also holds bot fixes D1-D4, C1-C7,
  B1-B8, E1, the Ice train-time buff (both paces) and single-threaded avoidance.
- Drift is concentrated: Fire-Shadow Crown Hollow 3/8 -> 8/8 (p ~ 0.03, 8 games), Thornwater 4/8 -> 5/8; Ice-Shadow
  6/16 -> 9/16 (expected from the Ice buff); Nature-Shadow unchanged.
- Clocks ruled out at normal pace (match_time = frames / 60 at tick 60; E1 / Fireball x0.75 / Shadow +500 are Blitz-only).
- Suspects: (1) R2-3 Mother Hush no longer `command_stop`s attackers (`helper_abilities.gd:617-620`): Shadow's late
  helper lost an effect that wiped enemy attack-moves (a bug Shadow leaned on); (2) D1 trade routes "held by the enemy"
  count as unsafe (`ai_trade.gd:536-539`): Shadow gold -22 % on Crown Hollow, Fire +19 % (may be effect, not cause);
  (3) A1 natural camp creeped before X1 (`commander.gd:1797, 1819-1830, 3654-3660`): Shadow camps 3.8 -> 3.2.
- A/B plan: Crown Hollow Fire-Shadow both seats, seeds 1-6, `run_fg.py --arms baseline --pairs fire:shadow,shadow:fire`,
  one arm per reverted suspect; or one batch at 57f8851b (bot fixes without 81750691) to split bot vs gameplay.

## A/B 1 (2026-10-13 04:50): Fire-Shadow, Crown Hollow, normal, seeds 1-6 both seats, code 57f8851b
57f8851b = bot fixes A1-A7 / D / C / B / E1 in, code-review gameplay fixes (81750691) NOT in.
Fire 7 / 12 (fire-shadow seat order: Fire 2/6; shadow-fire: Fire 5/6 -> the enemy seat won 9/12).
Current main on the same pair / map: Fire 8 / 8 (confirm run). Points at 81750691 (Hush R2-3 first suspect), small n.
Runs: Documents\four-wizards-lab-runs\fg-ab-prefix-57f8.

## A/B 2: current main with the old Mother Hush (2026-10-13 morning) — INVALID

**Invalid (found 2026-10-13 night, docs/balance/b13_2026-10-13/diagnosis.md):** the CI worktree was moved to a new commit and patched without a re-import, so all 12 games ran a broken build (~55 000 Nonexistent function / parse errors, no units trained). The verdict below is NOT supported; the normal-pace drift's causes are in the diagnosis.
Run `fg-ab-hush-main`: tag playtest-2026-10-13-2 (8dcc0bb9) with `helper_abilities.gd _drop_targeting` patched back to
`if e.attack_target == helper: e.command_stop()` (patch not committed, reverted after). Crown Hollow, normal pace, Fire vs
Shadow both seats, seeds 1-6.

| Build | Fire wins |
|---|---|
| current main (R2-3 fix: `drop_target_if`) | 13 / 16 (confirmation run) |
| 57f8851b (bot fixes, no gameplay fixes) | 7 / 12 (`fg-ab-prefix-57f8`) |
| current main + old Hush `command_stop` | **2 / 12** (Shadow 6 / 6 as seat 1, 4 / 6 as seat 2) |

**Verdict:** R2-3 is the cause of the normal-pace drift. The old Hush wiped her attackers' orders (an attack-move army
stopped dead), which was worth a lot more than intended, and the swing is huge either way. Keep the fix (correct
play); compensate Shadow / Hush in a balance pass instead (designer + gameplay-coder: e.g. a short Hush pulse that
slows or dazes attackers, without touching their orders), then re-measure normal pace and Blitz.
