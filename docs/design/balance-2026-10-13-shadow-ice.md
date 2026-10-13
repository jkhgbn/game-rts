# Balance 2026-10-13: Shadow (Mother Hush) and Ice

Source: `docs/balance/confirm_2026-10-13/report.md` (A/B 2), `docs/balance/shadow_fire_2026-10-12/report.md`,
`docs/ideas/ice-suggestions-2026-10-10.md`, `t3-helpers.md` 4.3, `kingdom-ice.md` 4. Skirmish balance only; every change
below lists its owner. Task ids `B13.*` (this file). Nothing here changes a contract.

## 1. Shadow: compensate Mother Hush without touching orders
**Cause (measured):** R2-3 (`helper_abilities.gd _drop_targeting`) now only makes attackers drop her as target. The old
`command_stop` froze every enemy within 20 m that was attacking her until its bot re-ordered it (Smoke Cloak every 22 s,
Night of Knives every 75 s). Fire-Shadow normal: old Hush 2 / 12, no compensation 13 / 16. The fix stays.
**Rule for every option:** no `command_*`, no write to orders / `order_serial` / attack-move; statuses only.

### Options, ranked
| # | Change | Numbers | Why / risk |
|---|---|---|---|
| **H1 (recommended)** | **"Lost in the smoke"**: when Smoke Cloak or Night of Knives runs `_drop_targeting`, each enemy it makes drop her also gets `dazed` | **2.0 s** (heroes 1.0 s through the existing `hero_mult` 0.5); radius unchanged **20 m**; only units that were attacking her | Same trigger and same victims as the old stop, but bounded: a 2 s pause, then the attack-move resumes. Targets the exact effect A/B 2 showed. `dazed` already exists (no immunity, orders kept) |
| H2 | Smoke Cloak more often | cooldown **22 -> 16 s**; autocast at **2+** enemies targeting her (was 3+) | Pairs with H1 as a second knob only; alone it re-casts a drop-target that does little |
| H3 (fallback) | Tougher Hush (data only) | `helper_hush.tres` `hp_base` **520 -> 600**, `hp_per_level` **35 -> 40**, `armor` **10 -> 15** | Weaker: she lives longer but never stalls an army; the A/B swing came from the stall, not her HP |
| Not chosen | Shadow army-wide buff | - | The drift is Hush-only (Nature-Shadow unchanged vs 10-12); an army buff would also lift Shadow in Blitz (52 % now) and early game |

**H1 spec (gameplay-coder, `scripts/units/helper_abilities.gd`):**
- New constant `SMOKE["daze"] = 2.0` (Knives reuses it). `_drop_targeting(r)` applies `dazed` for that long to each enemy
  whose `attack_target` was the helper, then `drop_target_if(helper)` as now. Buildings / towers are not units: untouched.
- **Skirmish helpers only:** the daze runs only where `T3Kit.helpers_here()` is true. Story Hush in missions (e3m2, e2m4, e4m2,
  e8m1...) keeps today's behaviour (mission sims must not move).
- Visual: none new (the `dazed` status colour already shows). No new text, no i18n.
- Pace: **not pace-dependent** (Hush is called in both paces; Blitz Citadel comes earlier). Blitz guard in 3.3.

## 2. Ice: Torvald's spells are the remaining gap
Already done and measured: bot B1-B3 (Ice 17 -> 42 % on 24 games), `ice_t` train times (+~10 pts). Tried, no gain:
Frost Hall 45 s + Rimeshield 19 s (`ice_u1_u2`), Blitz +800 crystals / x0.35 training. Unit Lab: Ice armies win at
equal cost (Fire mix vs Ice mix 0 / 20). What is left: **Torvald kills least and ends lowest** (1.2 workers per game vs
Vessa 4.7; level 6.3, lowest), and Ice's worst pair is **Nature's cheap swarm** (Ice-Nature 3 / 14 normal, 4 / 16 Blitz),
which area damage answers. Vessa's spells are Fire's real-game edge (10-12 report 2a); Torvald's area spell deals 20
every 20 s against Fireball 60 every 3 s.

| # | Change | Numbers (rank 1 / 2 / 3) | Owner |
|---|---|---|---|
| **I1 (recommended)** | Flash Freeze hits like an area spell | `data/spells/flash_freeze.tres` `damage_by_rank` **20 / 30 / 40 -> 40 / 55 / 70** (`damage` 20 -> 40); `cooldown_by_rank` **20 / 18 / 16 -> 18 / 16 / 14** (`cooldown` 20 -> 18). Radius, freeze time, mana unchanged | gameplay-coder |
| **I2 (with I1 if I1 alone < 40 %)** | Rime Bolt | `data/spells/rime_bolt.tres` `damage_by_rank` **45 / 58 / 72 -> 55 / 70 / 85** (`damage` 45 -> 55); cooldown unchanged | gameplay-coder |
| I3 (fallback, bot) | Ice bot mix and towers (ideas doc B4 + B6) | `data/ai/ice_*.tres` + `ai_profile.gd ice()`: `mix_default` **[0.40, 0.30, 0.10, 0.20] -> [0.45, 0.35, 0.05, 0.15]**; `tower1_time` **210 -> 300**, `tower2_time` **420 -> 480** | ai-coder |
- Why not unit stats: Rimeshield / Colossus are already top of the matrices; more HP breaks the 10-06 pass.
- Why not speed (4.2 -> 4.5): it changes Ice's identity line in `kingdom-ice.md` 1; keep it as the next knob.
- I1 / I2 apply in **both paces** (Ice is low in both) **and in missions** (Torvald ally / enemy, player Torvald in
  e6 / e7): run the Ice mission sims (`test_e6m*`, `test_e7m*`). Flash Freeze stays capped by radius 3-3.5, half freeze
  on wizards and the 2 s freeze immunity.
- Tooltips read the numbers from data; if any hard-coded text says "20 damage", fix it and its `.po` line.

## 3. Measurement plan (run from the repo root; normal = tick 60, Blitz = tick 30)
Changes are applied as an uncommitted patch, measured with `--arms baseline`, compared with the confirm run (same
seeds). One patch at a time (disk: no second worktree). Blitz arm = the file
`docs/balance/shadow_fire_2026-10-12/variants/bz_shipped.json` (run_fg.py has no ARMS table: an arm is `baseline` or
a variant JSON). TW = add `--layout res://data/maps/thornwater_layout.tres`.

### 3.1 Screens (each ~12-36 games)
```
H1 normal:  python tools/balance_lab/faster_games/run_fg.py --run b13-h1-n-ch --arms baseline --pairs fire:shadow,shadow:fire --seeds 1-6 --parallel 3 --tick 60
H1 Blitz:   python tools/balance_lab/faster_games/run_fg.py --run b13-h1-bz-ch --arms docs/balance/shadow_fire_2026-10-12/variants/bz_shipped.json --pairs fire:shadow,shadow:fire --seeds 1-6 --parallel 3 --tick 30
I1 normal:  python tools/balance_lab/faster_games/run_fg.py --run b13-i1-n-ch --arms baseline --pairs ice:fire,fire:ice,ice:nature,nature:ice,ice:shadow,shadow:ice --seeds 1-3 --parallel 3 --tick 60
I1 normal TW: same with --run b13-i1-n-tw --layout res://data/maps/thornwater_layout.tres
I1 Blitz:   same pairs, --run b13-i1-bz-ch (and -tw) --arms docs/balance/shadow_fire_2026-10-12/variants/bz_shipped.json --tick 30
```
Screen bars: H1 normal Fire <= 8 / 12 (else add H2, re-screen); H1 Blitz Fire 4-8 / 12. I1 Ice >= 15 / 36 normal
(CH + TW) and >= 13 / 36 Blitz; below that add I2 and re-screen, then I3.

### 3.2 Confirmation (both kept changes together, all 12 pairs, both maps, seeds 1-4)
```
python tools/balance_lab/faster_games/run_fg.py --run b13-conf-n-ch --arms baseline --seeds 1-4 --parallel 3 --tick 60
python tools/balance_lab/faster_games/run_fg.py --run b13-conf-n-tw --arms baseline --seeds 1-4 --parallel 3 --tick 60 --layout res://data/maps/thornwater_layout.tres
python tools/balance_lab/faster_games/run_fg.py --run b13-conf-bz-ch --arms docs/balance/shadow_fire_2026-10-12/variants/bz_shipped.json --seeds 1-4 --parallel 3 --tick 30
python tools/balance_lab/faster_games/run_fg.py --run b13-conf-bz-tw --arms docs/balance/shadow_fire_2026-10-12/variants/bz_shipped.json --seeds 1-4 --parallel 3 --tick 30 --layout res://data/maps/thornwater_layout.tres
```
Report: `python tools/balance_lab/faster_games/fg_report.py --run <run>` for each.

**Pass bars (96 games per pace, 48 per kingdom, noise ~+/- 14 pts):**
| Measure | Normal | Blitz |
|---|---|---|
| Fire-Shadow, Fire wins (16 games) | **6-10** (40-60 %) | **6-10** (now 8) |
| Shadow overall | 40-60 % | 40-62 % (now 52) |
| Ice overall | **>= 40 %** | **>= 38 %** (now 29) |
| Ice-Nature, Ice wins (16) | >= 5 | >= 5 |
| Every kingdom | 35-65 % | 35-65 % |
| Median game | 15:00-18:30 | 12:30-15:30 game time |
| Crashes / timeouts | 0 | 0 |

### 3.3 If Blitz moves too far
H1 or I1 lift Blitz Shadow > 62 % or Fire-Shadow < 6 / 16: systems-coder sets `PaceSwitch.BLITZ.start_crystals_add`
shadow **500 -> 300** (its pre-10-12 value). Ice > 60 % in Blitz: ice **800 -> 500**. Both Blitz-only, normal untouched.

## 4. Tasks and done when
| Id | Owner | Task | Done when |
|---|---|---|---|
| B13.H1 | gameplay-coder | Hush daze (section 1) | `tests/test_b13_h1.gd`: an attack-moving enemy hitting Hush is `dazed` 2.0 s when Smoke Cloak fires, keeps its attack-move and `order_serial`, and moves on after; a wizard gets 1.0 s; a unit not attacking her gets nothing; with helpers off (mission) no daze. `test_f2_gameplay` (R2-3), `test_e3m2`, `test_e3m2_sim` pass |
| B13.I1 | gameplay-coder | Flash Freeze numbers | `.tres` values as 2; spell tests + `test_e6m*` / `test_e7m*` run; tooltip shows 40 at rank 1 |
| B13.I2 | gameplay-coder | Rime Bolt numbers (only if the screen asks) | as I1 |
| B13.I3 | ai-coder | Ice bot B4 + B6 (only if I1 + I2 fail) | `ice_*.tres` and `ice()` aligned; `test_8_b3`, `test_7_a1` pass |
| B13.M1 | balance agent | Runs of section 3 | `docs/balance/b13_2026-10-13/report.md` with the pass-bar table filled |
| B13.D1 | game-designer | After JS confirms | `t3-helpers.md` 4.3 Smoke Cloak row and `kingdom-ice.md` 4.1-4.2 updated |
