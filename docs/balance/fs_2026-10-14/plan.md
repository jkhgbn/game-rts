# Fire vs Shadow at normal pace: lever plan (FS, 2026-10-14)

Intended home: `docs/balance/fs_2026-10-14/` (the ownership hook blocks game-designer there; lead, move this folder
and change the `V` path in section 4). Inputs: `docs/balance/b13_2026-10-13/report.md` + `diagnosis.md`,
`scripts/ai/ai_profile.gd` (NORMAL_PACE_KNOBS), `fg_match.gd` / `balance_match.gd` variant format, `data/units/*.tres`.

## 1. Problem and what is already ruled out
- Normal pace, bot vs bot: Fire beats Shadow ~70 % (B13 screens 17-18 / 24). Blitz Fire-Shadow is fair (5-6 / 12).
- What decides a normal game (diagnosis): **worker raids** (loser loses 15-17 workers by 15:00, ~60 % to enemy
  **champions**, then the enemy wizard), not army trades. Shadow attacks least (1.2 / 10 min), buys fewest items
  (6.3 vs 11.5), Malrik dies early (0.83 / game vs Vessa 0.17).
- Fire and Shadow run the **same** bot profile (`shadow_default`); only difference at normal = Shadow
  `worker_target_home 7` (B13 Cause 3, kept). So any bot knob given to Shadow alone is a clean asymmetry.
- Tried, NOT kept: Hush cooldown 16 s (H2), Fireball 60 / 66 / 78 (no gain: 17 / 24), causes 1+2+3 together (moved
  Blitz), wizard retreat at 50 % (moved Blitz, no F-S gain). So: no more Fireball / Hush / retreat-rule levers here.

## 2. Levers (ranked)
Variant files in `variants/` (format = `run_fg.py --arms` path arms; `ai_kingdom.shadow` lays on top of the Shadow
bot's normal profile, which already has `worker_target_home 7`).

| # | Variant | Change | Targets | Expected Fire wins / 24 (base ~17) | Moves Blitz? |
|---|---|---|---|---|---|
| L1 | `fs_l1_shadow_champs_early.json` | Shadow bot: `champion_earliest` 180 -> **120** (tavern opening), `bounty_max_flags` 2 -> **3**, `bounty_budget_pct` 0.25 -> **0.35** | Champions decide: today both bots hire at 3:00 and Fire often holds the taverns first ("Enemies hold both taverns" refusal). Shadow's first champion out 60 s sooner guards / raids first; an extra Guard flag covers the line. | 14-15 | no (normal-pace knob) |
| L2 | `fs_l2_shadow_line_defence.json` | Shadow bot: `defend_radius` 28 -> **36 m**, `reaction_delay` 1.5 -> **0.75 s**, `attack_reserve` 2 -> **3** pop | Worker raids: the line answers a raiding champion / Vessa in half the time and from further (forward-hall line), and keeps one more pop home. `reaction_delay` also halves Malrik's cast reaction (Shroud / Siphon) -> fewer early wizard deaths. | 14-15 | no (normal-pace knob) |
| L3 | `fs_l3_thrall_hp70.json` | Gloom Thrall `max_hp` 50 -> **70** | Workers die in one Fireball rank 1 (60) and in 2-3 champion hits. 70 HP survives Fireball rank 1 and buys flee time vs champions. Blitz's fairness comes from exactly this (workers x2 HP). | 13-14 | **yes** (Blitz thrall 140 vs Fire 100): run `fs_l3_thrall_hp70_bz` |
| L4 | `fs_l4_shadow_hall_armor5.json` | Nightbolt, Grave Hound, Bleakbow, Barrow Ghoul `armor` 0 -> **5** (x0.952 damage) | The 70-HP Fireball breakpoint: rank 2 72 -> 68.6 (survives), rank 3 still kills. Small, since the Fireball cut gave nothing. | 15-16 | yes: run `fs_l4_shadow_hall_armor5_bz` |
| L5 | `fs_l5_shadow_mix_shades.json` | Shadow bot mix: Shade 0.40 -> **0.48**, Nightbolt 0.30 -> **0.22**, Grave Hound **0.15**, Shadow Knight **0.15** (all three mixes) | Fewer 70-HP units in the clump Vessa Fireballs; Shade 100 HP. Weak link to the cause (army trades rarely decide). | 15-16 | no (normal-pace knob) |
| L6 | `fs_l6_fire_champs_late.json` | **Fire** bot: `champion_earliest` 180 -> **240** | Same cause from the other side: Fire's champions raid later. Last resort: weakens the Fire bot vs every kingdom and vs the player. | 14-15 | no (normal-pace knob) |
| A | `fs_combo_a_bot.json` | L1 + L2 | bot-only fix, Blitz untouched by construction | 12-14 | no |
| B | `fs_combo_b_bot_thrall.json` | L1 + L2 + L3 | if A is not enough | 11-13 (overshoot risk) | yes (thrall): `fs_l3_thrall_hp70_bz` |

Blitz arms: `fs_bz_baseline.json` (real Blitz, no change), `fs_l3_thrall_hp70_bz.json`, `fs_l4_shadow_hall_armor5_bz.json`.
L1 / L2 / L5 / L6 / A ship as normal-pace-only knobs: Blitz never reads them, so no Blitz arm (the harness would
apply `ai_kingdom` in Blitz too, which would not match what ships).

## 3. How each lever ships if kept
| Lever | File | Owner | Change |
|---|---|---|---|
| L1, L2, A | `scripts/ai/ai_profile.gd` `NORMAL_PACE_KNOBS["shadow"]["normal"]` | ai-coder | add the knobs next to `worker_target_home: 7` (numbers as in the variant) |
| L6 | same const, new key `"fire": {"normal": {"champion_earliest": 240}}` | ai-coder | 1 line |
| L5 | same const + `apply_normal_pace_knobs` | ai-coder | accept an Array value for `mix_default` / `mix_vs_ranged` / `mix_vs_melee` (set as PackedFloat32Array; Shadow slot order Shade, Nightbolt, Grave Hound, Shadow Knight = [0.48, 0.22, 0.15, 0.15]); a `data/ai/shadow_normal.tres` must NOT be used (Fire also resolves to `shadow_default`) |
| L3 | `data/units/gloom_thrall.tres` `max_hp = 70.0` | gameplay-coder | + `data/ui/unit_guide.json` thrall text if it states HP; run `test_unit_guide`, smoke, missions with Shadow workers (mission harness) |
| L4 | `data/units/{nightbolt,grave_hound,bleakbow,barrow_ghoul}.tres` `armor = 5.0` | gameplay-coder | + Unit Guide rank claims; Unit Lab `shadow_fire` preset re-run (Shadow already wins 70 % army vs army: watch it) |

## 4. Screening order and commands
Run from the repo root (PowerShell). Each layout needs its **own `--run`** (output names carry no layout).
`$V = "docs/balance/fs_2026-10-14/variants"` (after the move: `docs/balance/fs_2026-10-14/variants`).
Common flags: `$C = "--levels normal --pairs fire:shadow,shadow:fire --seeds 1-6 --parallel 4"`.

Round 1 (cause-targeted, 4 arms x 24 games = 96):
```
python tools/balance_lab/faster_games/run_fg.py --run fs1-ch --arms "baseline,$V/fs_l1_shadow_champs_early.json,$V/fs_l2_shadow_line_defence.json,$V/fs_l3_thrall_hp70.json" --levels normal --pairs fire:shadow,shadow:fire --seeds 1-6 --parallel 4
python tools/balance_lab/faster_games/run_fg.py --run fs1-tw --arms "baseline,$V/fs_l1_shadow_champs_early.json,$V/fs_l2_shadow_line_defence.json,$V/fs_l3_thrall_hp70.json" --levels normal --pairs fire:shadow,shadow:fire --seeds 1-6 --parallel 4 --layout res://data/maps/thornwater_layout.tres
python tools/balance_lab/faster_games/fg_report.py --run fs1-ch --run fs1-tw
```
Round 2 (combos; plus L4-L6 only if no single lever moved >= 2 games): same two commands with `--run fs2-ch` /
`fs2-tw` and `--arms "baseline,$V/fs_combo_a_bot.json,$V/fs_combo_b_bot_thrall.json"` (add
`$V/fs_l4_shadow_hall_armor5.json,$V/fs_l5_shadow_mix_shades.json,$V/fs_l6_fire_champs_late.json` when needed).
Always keep `baseline` in the same run (same tree, same machine load).

Round 3, Blitz check (only for a candidate that contains L3 or L4): `--run fs3bz-ch` / `fs3bz-tw`,
`--arms "$V/fs_bz_baseline.json,$V/fs_l3_thrall_hp70_bz.json"` (or `..._armor5_bz.json`), same pairs / seeds / layouts
(`--levels normal`: the Blitz pace comes from the variant's `"blitz": {}`).

Round 4, confirmation of the chosen candidate: seeds **7-12**, same two layouts and pairs (another 24 games), then all
12 pairs `--seeds 1-3` both layouts, baseline vs candidate (pairs flag omitted = all 12).

Before counting: each JSON line's `variant.errors` must be empty (a misspelled knob is reported, not applied).

## 5. Keep bar
- **Normal Fire-Shadow**: Fire **9-15 / 24** (seeds 1-6, CH + TW, both seats), and still 18-30 / 48 once seeds 7-12 are
  added (a lucky screen is not enough).
- **Blitz Fire-Shadow**: candidate within **±3 / 24** of `fs_bz_baseline` in the same run (only levers with L3 / L4;
  bot-knob levers are Blitz-neutral by construction).
- **Other pairs (round 4, 72 games per arm)**: Fire overall >= 45 %; no kingdom above 65 %; Shadow vs Ice / Nature may
  rise (Shadow is 35 % overall) but Shadow overall <= 60 %; seat-0 rate 45-55 %.
- Pick the smallest kept change: L1 or L2 alone over A, A over B, anything over L6.

## 6. Done when
- FS.1 rounds 1-2 screened, results table appended here (arm, CH, TW, total / 24, Malrik deaths, Shadow workers lost by 15:00).
- FS.2 the chosen lever passes round 3 (if needed) and round 4.
- FS.3 the owner ships it (section 3), `ci_quick` green, smoke `victory=true`, and the lead records it in `decisions.md`.
