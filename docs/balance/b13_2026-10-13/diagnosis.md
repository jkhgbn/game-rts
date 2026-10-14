# B13 diagnosis: why Shadow and Ice lose at normal pace (2026-10-13)

(Intended path `docs/balance/b13_2026-10-13/diagnosis.md`: the ownership hook blocked this agent there; lead, please move it.)

Read-only diagnosis (no game code changed). Data: `Documents\four-wizards-lab-runs\fg-b13c-{n,bz}-{ch,tw}` (current build,
96 normal + 96 Blitz games, all 12 pairs), `fg-b13r2-*`, `fg-confirm-1013-*`, `fg-ab-*`, the Blitz kill probes
`fg-sf2-probe-bz-*` / `fg-sf2-bzD-*`, plus **10 new normal games** on the CI worktree (69b0b985, Crown Hollow, seeds 1-2,
`tools/map_lab/tw_probe.gd` + `--log=1`: who killed whom + bot decision logs): fire-shadow s1 / s2, shadow-fire s1 / s2,
shadow-nature, ice-nature, nature-ice, fire-ice, ice-fire, ice-shadow (agent scratchpad `dg/`, not kept).

## 0. First: the Hush A/B was invalid
`fg-ab-hush-main` (A/B 2, "old Hush = Fire 2 / 12") did not play the game: **all 12 logs** carry ~55 000
`Nonexistent function 'keep_types'` / `'bot_tick'` / `'bot_try_helper'` errors and parse errors (`VfxText`,
`ClockMetaLedger` not declared: the patched tree was not re-imported). Both sides: `bot_tick_ms 0`, `units_trained 0`,
3 workers all game, peak army 0. No other fg run is broken (all scanned). So **"R2-3 is the cause" is unproven**, which
fits what B13 measured (H1 a little, H2 nothing). Hush also arrives late: in the 6 logged Shadow games the bot called its
helper at 9:53 and 13:12, and never in 4 (games end 11:00-21:00). The normal-pace drift itself is real but small-n:
Fire-Shadow normal 14 / 28 before (10-12 `fg-twfix` 7 / 16 + `fg-ab-prefix-57f8` 7 / 12, the latter with a 9 / 12 seat
bias) vs ~50 / 68 now (b13c 11 / 16, confirm 13 / 16, r2 18 / 24, h1 8 / 12). To pin it, re-run A/B 2 after `--import` on
the patched tree (12 games).

## What a normal game is (bots, current build)
- 83 / 96 games end by **concede**; the loser has lost **0.5 buildings** on average but **15-17 workers** by 15:00
  (`worker_deaths`, first 15 min): ~60 % to enemy **champions**, then the enemy **wizard**. Armies stay tiny: peak army
  pop 11-15 (cap 200), army pop at 10:00 = 4-7.
- Probe (10 normal games, per game): wizards are the top soldier killers (7-12 soldiers each), champions kill 8-12
  workers; soldiers kill 2-8 soldiers. **Matches are decided by wizards, champions and worker raids, not army trades.**
  Unit Lab (army vs army) cannot see it: Shadow's mix beats Fire's at equal cost 70 % (shadow_fire 10-12, 2a).
- Blitz changes exactly these levers: Fireball x0.75 (`spell_type_x`), workers x2 HP and spells x0.5 on workers, 9 start
  workers, Shadow +500 / Ice +800 crystals, Ice-only aggression knobs. That is why Blitz is fair and normal is not.

## Cause 1 (Fire > Shadow): Fireball rank 2 / 3 one-shots Shadow's 70-HP units at normal pace
- Fireball `damage_by_rank` 60 / **72 / 85**, radius 3.5-4.0, cooldown 3 / 3 / 2.5 s (F2 at level 3, ~5-6 min). Shadow's
  Hall roster: Nightbolt **70** HP, Grave Hound **70**, Bleakbow **70**, Barrow Ghoul **75**, armor 0 (Shade 100). From
  F2 each Fireball on a clump kills them outright; in Blitz (x0.75: 54 / 64) it never does.
- Same bots, same maps, Blitz Fire-Shadow with Fireball 60 (`fg-sf2-probe-bz`, 12 games): Fire **9 / 12**, Vessa kills
  **32.2** units / game; with Fireball 45 (`fg-sf2-bzD`, 12 games): Fire **6 / 12**, Vessa 25.9. Normal (4 logged F-S
  games): Vessa 25 kills / game, Fire 3 / 4.
- Shadow's army evaporates at normal: Shadow soldiers kill **1.8-2.2** soldiers / game (Fire 4.2-4.7, Ice 5.8, Nature
  8.0); Shadow army pop at 10:00 **4.2** (lowest; Fire 6.1); attacks **1.2 / 10 min** at normal vs **3.4** in Blitz (Fire
  1.8 / 1.4). Fire-Shadow is a mirror bot (both `shadow_default`): economy equal to 10:00 (gathered +39 for Fire), the
  worth gap opens after 10:00 (+242 at 15:00), i.e. after F2 / F3.
- **Lever (gameplay-coder, `data/spells/fireball.tres`):** `damage_by_rank` **60 / 72 / 85 -> 60 / 66 / 78** (`damage` stays
  60). Removes the 70-HP breakpoint at ranks 2-3 (check the bot's item `spell_power` does not push 66 back over 70; if it
  does, 64 / 74 + Shadow's 70-HP units +6 HP is the fallback). Blitz barely moves: x0.75 gives 49.5 / 58.5 instead of
  54 / 64, both already non-lethal. Missions: Vessa is the player in several (run `test_2_g1`, `test_2_g2`, `test_3_g1`,
  smoke). **Predicted:** Fire-Shadow normal ~70 % -> 55-60 %, Fire overall 63 -> ~57 %; Ice / Nature vs Fire + a few points.

## Cause 2 (Shadow and Ice): their wizards die, Vessa does not (bot hero AI asymmetry)
- Wizard deaths per game, normal probe: **Fire 0.17** (1 in 6 games), **Shadow 0.83** (5 / 6; three at **7:07, 7:24, 7:33**),
  **Ice 1.2** (6 in 5; `ice-nature s1` died 6:04 / 7:50 / 9:31, lost at 11:01), Nature 0. Blitz probe with Fireball 60:
  Fire 0.17 vs Shadow 0.75 (12 games); bzD (120 games): Ice highest, 0.83. All 4 deaths before 10:00 were in lost games.
- Every death follows the same log line: `WIZARD low (23-34 %), goes home`, then dead 2-30 s later on the walk home
  (`commander.gd _rule_wizard`, `HERO_LOW 0.35`). Vessa has her own cast brain (`ai_casts.gd suggest_vessa`: Ember Step
  **escape** below 35 %, Fireball focus on the enemy wizard, Ember Step engage on a wizard under 50 %), and the shared
  `spell_order` Q1-first gives her the blink at **level 2** (~3:25). Malrik's escape (Umbral Shroud) and Torvald's (Rime
  Aegis) are slot E, which needs **level 4** (levels.md), learned ~7:30: Malrik's three early deaths fall just before it.
- Knock-on: Shadow buys the fewest items (6.3 per game vs Fire 11.5, Ice 9.4, Nature 8.3; the side with more items won
  8 / 10 logged games); its wizard kills the fewest workers at normal (1.1 / game vs Fire 3.6; Blitz 2.4).
- Ice losses: Ice workers killed by the enemy wizard **3.9 / game** in losses vs 1.0 in wins (normal, 48 games); Torvald is
  the weakest killer (Blitz probe: 16.5 units / game vs Vessa 31.6, Malrik 24, Ysolde 21.9). The Flash Freeze / Rime Bolt
  buffs cannot show while he is dead or walking home.
- **Lever (ai-coder, `scripts/ai/commander.gd` + `ai_casts.gd`; the spell rules in `spell_caster.gd suggest_cast` are
  gameplay-coder's):** for wizards without a blink (Malrik, Torvald): go home at **50 %** HP instead of 35 %, on a path
  away from the nearest enemy fighter (as `_escape_point`); while retreating Torvald casts Flash Freeze on the closest
  chaser, Malrik Soul Siphon when >= 2 foes are near. **Predicted:** Shadow / Ice early deaths -> near Fire's, +5-8 pts
  each at normal. Blitz moves too (deaths there 0.72 / 0.83): watch Blitz Shadow (44 %) and Ice (42 %), both have room.

## Cause 3 (Shadow and Ice): the normal-pace bots are passive / short of workers; Blitz fixed it only in Blitz
- Attacks per 10 game min (96 + 96 games): normal **Shadow 1.2, Ice 1.8**, Fire 1.8, Nature 3.7; Blitz **Shadow 3.4,
  Ice 3.9**, Fire 1.4, Nature 3.7. The Blitz-only Ice knobs (`PaceSwitch.BLITZ.ai_kingdom.ice`: `min_attack_pop 6`,
  `attack_ratio x0.8`, `attack_reserve 1`) and the Shadow / Ice start banks are what make them attack in Blitz.
- Shadow economy: Fire and Shadow run one profile (`shadow_default`, 6 home workers): workers at 5:00 **6.0** vs Ice /
  Nature **8.8** (7 home, earlier X1). Gathered vs opponent at 10:00: Shadow **-690** (wins -450, losses -822); vs Nature
  -1 059 (Shadow 4 / 16), vs Ice -972. Fire has the same deficit, but Vessa (causes 1-2) covers it.
- Ice: the richest kingdom (gathered +509 at 10:00, peak army value **1 273**, highest) still loses 65 %: it sits (first
  attack 6:12 in losses, many `pop` / `no army` blocks) while champions and the enemy wizard raid its line (`no_workers`
  flag in 17 / 48 Ice games, most). One logged game: Ice's first hire refused at 3:19, "Enemies hold both taverns".
- **Levers (ai-coder, data only):** (a) give Shadow its own normal profile (today Fire and Shadow both resolve to
  `shadow_default`, `AIProfile.id_for_faction`): `worker_target_home 6 -> 7` (Blitz sets 9 itself: unchanged). (b) Ice
  normal (`data/ai/ice_normal.tres`): `min_attack_pop 6`, `attack_ratio` / `attack_ratio_floor` x0.8, `attack_reserve 1`
  (the Blitz values). Blitz multiplies `ai_kingdom` on top, so systems-coder makes `PaceSwitch` skip Ice's `ai_kingdom`
  knobs (or sets them as absolute numbers) so Blitz stays as measured. **Predicted:** Shadow +3-5 pts, Ice +4-6 pts at
  normal; Blitz unchanged.

## Order and measurement
1. Cause 1 alone first (largest, data only, Blitz-neutral): Fire-Shadow normal CH + TW, seeds 1-6, both seats (24 games,
   bar Fire <= 14 / 24), plus the 6 Fire pairs normal seeds 1-3 (Fire must stay >= 45 %).
2. Cause 3 (bot data) with it or right after; Cause 2 last (code, moves Blitz); then the full B13 confirmation (96 + 96).
3. H1 / I1 stay (small, correct, already measured).

## Caveats
- The 10 logged games are one or two seeds per pair: wizard-death, item and kill-by-kind numbers at normal pace are a
  small sample. The W / L, worker, attack and economy numbers come from the 96 + 96 games.
- `worth` in the `at` snapshots includes the bank (Ice's +620 at 7:00 is partly unspent crystals).
