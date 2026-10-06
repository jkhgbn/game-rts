# Unit Lab: equal-pop matrix + caster A/B (2026-10-05)

Follow-up of `first_matrix.md`. Three questions: (1) do the outliers of the equal-crystal matrix survive at **equal pop**
and with **both budgets**? (2) is a caster worth the same crystals of its kingdom's line unit, and which of three knobs
(cost 150 -> 120, mana regen +25 %, HP +15 %) fixes it? (3) do the C1-C7 bands (caster-units.md 7.2) pass, and is the C7
setup sound? About 13 000 fights, all through `tools\unit_lab\run_unit_lab.ps1`, even seed counts (team alternation).

## Changelog
| What | Where | Why |
|---|---|---|
| **Caster cost 150 -> 120** (Kilnwarden, Rimecarver, Bramblesage, Gloom Deacon; pop 2 and kill_xp 75 kept) | `data/units/{kilnwarden,rimecarver,bramblesage,gloom_deacon}.tres`, caster-units.md 3.1 / 4 / 6 / 7.2b | No caster is worth 150 crystals of line units in any test below; cost is the only one of the three knobs that moves the result; even at 120 each stays at or below parity, so the cut cannot overshoot |
| Tests: cost 150 -> 120 in the data check, bot strength 75 / 150 -> 60 / 120 | `tests/test_casters.gd`, `tests/test_casters_ai.gd` | follow the data |
| Unit Lab: `basis` cost / pop / both (+ `pop_budget`, default budget / 90 = 8 pop at 720) for `equal`, `matrix`, the text line (`; basis=pop pop=8`), `-Basis` / `-PopBudget` in the ps1, `--basis` / `--pop_budget` in the runner; arms may hold their own `equal`; `fill_a` / `fill_b` (a side sized from an entry at a budget vs a fixed opponent); variant key `unit_mods` (Stats modifiers per unit id, for knobs that are not UnitType fields); the result counts `passage_units` | `tools/unit_lab/unit_lab_spec.gd`, `unit_lab_run.gd`, `unit_lab_arena.gd`, `unit_lab_report.gd`, `run_unit_lab.ps1`; `tests/test_unit_lab.gd` (+15 checks) | the equal-pop question; the caster A/B design |
| Presets `matrix_t1t2_pop`, `matrix_t1t2_both`, `caster_ab` (mirror), `caster_ab_mix` (vs 4 T1 mixes), `caster_ab_sweep` (6 budgets); C7 chasers stop at (0, 0) | `tools/unit_lab/presets/` | see below |
| Variants `caster_cost120`, `caster_regen125` (unit_mods `mana_regen_pct` 0.25), `caster_hp115`, `caster_combined` | `tools/balance_lab/variants/` | the A/B arms |
| Handoff: the bot's retreat Passage carries 0 units | `docs/handoff/for-ai-coder.md` | C7 |

## 1. Equal-pop and both-budget matrices (47 entries, 4324 fights each)
Runs: `matrix_pop/` (8 pop a side, basis pop), `matrix_both/` (720 crystals AND 8 pop, whichever binds first; this one ran
after the caster cost change, so its caster entries are at 120). Mean score vs the 46 others:

| Entry | Equal crystals | Equal pop | Both | Reading |
|---|---|---|---|---|
| hollow_oathsworn | 99 | 98 | 100 | **too strong in all three** |
| rimehorn_rider | 93 | 85 | 92 | **too strong in all three** (pop 3 does not explain it) |
| pyrehoof_lancer | 92 | 88 | 90 | **too strong in all three** |
| barrow_knight | 91 | 84 | 91 | **too strong in all three** |
| thornback_charger | 87 | 77 | 83 | **too strong in all three** |
| rimeshield | 79 | 91 | 86 | strong line unit (head-on vs a pool that is 40 % ranged) |
| flame_guard | 79 | 86 | 89 | same |
| scorchling | 89 | 31 | 41 | **not an outlier at equal pop**: a crystal-cheap swarm, its price is supply |
| barrow_ghoul / thornling / rimeling | 72 / 63 / 58 | 39 / 22 / 16 | 45 / 37 / 28 | same pattern (cheap pop-1 bodies) |
| vinelasher | 61 | 96 | 72 | strong per pop (120 crystals, pop 1) |
| ash_hurler / hexweaver | 6 / 5 | 41 / 29 | 6 / 6 | weak per crystal, fair per pop: their price is crystals |
| frostbow / scorchbow / cinder_arbalest | 14 / 12 / 31 | 59 / 46 / 68 | 23 / 20 / 42 | same |
| wildwood_archer, ember_archer, nightbolt, burr_slinger | 18 / 18 / 19 / 25 | 10 / 21 / 25 / 3 | 20 / 26 / 25 / 10 | weak in all three (ranged alone, head-on: by role) |
| rime_seer, bloomtender | 0 / 5 | 5 / 5 | 0 / 9 | support alone: by construction |
| kilnwarden+flame_guard | 60 | 61 | 67 | |
| gloom_deacon+shade | 61 | 52 | 57 | |
| rimecarver+rimeshield | 46 | 55 | 61 | |
| bramblesage+thornling | 42 | 9 | 14 | pop 2 caster + pop-1 Thornlings: worst per pop |

**Outliers by more than 25 points at equal pop AND equal crystals** (proposals for JS, nothing applied):
- **Too strong**: Hollow Oathsworn (99 / 98), Rimehorn Rider (93 / 85), Pyrehoof Lancer (92 / 88), Barrow Knight (91 / 84),
  Thornback Charger (87 / 77); Rimeshield (79 / 91) and Flame Guard (79 / 86) also pass the bar, but they are the line
  units the pool's 19 ranged entries are built to sit behind: judge them in mixes first.
  Proposals (first_matrix knobs, A/B them with `-Variants` before applying): Hollow Oathsworn cost 170 -> 200 or Unbroken
  Vow shield 100 -> 60; the four T2 cavalry +10 % cost (245-260 -> 270-285) or -10 % HP; the equal-pop run shows the pop 3
  is not what keeps them in line.
- **Too weak**: Wildwood Archer (18 / 10), Ember Archer (18 / 21), Nightbolt (19 / 25), Burr Slinger (25 / 3), Rime Seer and
  Bloomtender (support). Ranged and support units alone head-on are weak by role; the fair test is a "line + 3 archers"
  entry (first_matrix next step 3) before any change. Ash Hurler / Hexweaver / Scorchling / the bowmen are **not**
  outliers at equal pop: their only problem is the crystal price, which a match with income limits does charge.

## 2. Caster A/B (does adding the caster beat adding the same crystals of line units?)
Three designs, all at level 1, caster at full mana, attack-move, flat ground, Rimecarver on the real bot brain
(`casters: bot`; its spells are autocast off):
- **Mirror** (`caster_ab`, 40 seeds a cell): caster + line vs the same line alone, equal cost (~1080) and equal pop (12).
- **Vs mixes** (`caster_ab_mix`, 24 seeds a cell): caster arm (caster + line, ~900) and control arm (line alone, ~900),
  each against the same T1 mix of each kingdom (line + archers, 1070-1120 crystals); caster minus control.
- **Budget sweep** (`caster_ab_sweep`, 12 seeds x 6 budgets 840-990 x 4 mixes): integer counts leave the two arms up to
  70 crystals apart at one budget (one extra Flame Guard swings a mirror from 5 % to 67 %), so the read is a regression of
  (caster - control) on the arms' crystal difference: intercept = worth at exactly equal crystals, slope = what 30
  crystals buy. "Margin" = (own value left / own cost - enemy value left / enemy cost) x 100, a continuous score that
  still reads when win rates saturate.

**Budget sweep (baseline data), caster minus control at exactly equal crystals, mean of the 4 mixes**:
| Caster | Win-rate delta | Margin delta | Margin per 30 crystals | Predicted at cost 120 (margin / win) |
|---|---|---|---|---|
| Kilnwarden | -17 | -9 | +11.6 | **+3 / -2: about parity** |
| Bramblesage | -18 | -27 | +4.2 | -23 / -17 |
| Gloom Deacon | -41 | -28 | +12.1 | -16 / -24 |
| Rimecarver | -50 | -46 | +7.8 | -38 / -46 |
Per mix (margin at equal crystals): Kilnwarden best vs Ice (-2) and Shadow (-3), worst vs Nature (-19, armour-0 swarm:
as 6 predicts); Bramblesage best vs Fire (-15), worst vs Nature (-46); Deacon -21..-34; Rimecarver -42..-51.

**Variants, vs mixes (`caster_ab_mix`), mean of the 4 mixes, win delta / margin delta** (a cost variant also re-sizes the
arms, so its column mixes the knob with a rounding jump of up to 60 crystals; the sweep above is the clean read for cost):
| Caster | baseline | cost 120 | regen +25 % | HP +15 % | combined |
|---|---|---|---|---|---|
| Kilnwarden | -51 / -32 | +27 / +22 | -47 / -30 | -45 / -31 | +29 / +21 |
| Rimecarver | -25 / -29 | -17 / -24 | -19 / -24 | -14 / -22 | -11 / -22 |
| Bramblesage | -12 / -30 | -11 / -22 | -15 / -29 | -17 / -31 | -17 / -23 |
| Gloom Deacon | -24 / -27 | +8 / +7 | -21 / -29 | -23 / -28 | +9 / +6 |

**Mirror (`caster_ab`), caster army win rate / margin (its crystals vs the line's)**:
| Caster | basis | baseline | cost 120 | regen +25 % | HP +15 % | combined |
|---|---|---|---|---|---|---|
| Kilnwarden | cost | 5 % / -21 (1050 v 1080) | 67 % / +14 (1110 v 1080) | 0 % / -22 | 10 % / -18 | 72 % / +15 |
| Kilnwarden | pop 12 | 5 % / -21 | 10 % / -19 | 10 % / -18 | 5 % / -20 | 10 % / -15 |
| Rimecarver | cost | 0 % / -43 (1100 v 1140) | 2 % / -29 (1070 v 1045) | 2 % / -41 | 0 % / -42 | 2 % / -27 |
| Rimecarver | pop 12 | 2 % / -39 | 2 % / -41 | 0 % / -42 | 0 % / -41 | 0 % / -42 |
| Bramblesage | cost | 0 % / -31 (1110 v 1080) | 0 % / -31 (1080 v 1080) | 0 % / -33 | 0 % / -33 | 0 % / -32 |
| Bramblesage | pop 12 | 0 % / -41 | 0 % / -41 | 0 % / -42 | 0 % / -40 | 0 % / -42 |
| Gloom Deacon | cost | 5 % / -26 (1110 v 1120) | 7 % / -25 (1080 v 1120) | 2 % / -26 | 0 % / -28 | 5 % / -28 |
| Gloom Deacon | pop 12 | 0 % / -32 | 2 % / -33 | 2 % / -30 | 0 % / -32 | 7 % / -28 |

**Reading.**
- **HP +15 % and mana regen +25 % do nothing measurable** (margins within 0 +/- 3 of the baseline in every design): fights
  end in 15-30 s, a full bar is never the limit, and with attack-move armies the caster stands behind and rarely dies
  first. Not applied.
- **Cost is the lever**, and every caster is below parity at 150. At 120 the Kilnwarden reaches about parity in the
  head-on fight (its good matchups Ice / Shadow slightly above); the other three stay below. **Applied: 150 -> 120.**
- **At equal pop** (pop 2 = two line units, 160-190 crystals of them) every caster loses, also at 120 (mirror, pop rows).
  Pop 2 -> 1 is the next knob if the playtest still finds them weak; it is a bigger design change (supply is the late
  game limit), so only proposed.
- The remaining gap is the spells' value in a head-on fight, a design call (game-designer), proposals:
  Blood Tithe heal 10 -> 14 / s (the Deacon loses 2 Shades of value for ~150 HP healed per fight; C4 0 % vs 75 %);
  the Bramblesage's Pollen Haze fires in 20-24 of 24 fights against the T1 mixes, but blinding 4-5 archers for 6 s does
  not pay for 2 Thornlings when the melee lines decide the fight; its Snagroot never fires there (it only pulls casters /
  artillery): let Snagroot also take "the enemy's lowest-HP ranged unit", or Haze 6 -> 8 s;
  the Rimecarver is a dive / retreat tool with no damage: judge it in C3-style dives, not head-on.

## 3. C1-C7 bands (20 seeds, `ab20_c*/scorecard.md`, presets unchanged except C7)
| Duel | Caster arm | Control | Band | Result | Note |
|---|---|---|---|---|---|
| C1 Kilnwarden vs Rimeshields | 25 % (Slag 3 / fight) | 100 % | +20..+60 | **FAIL** (-75) | the caster arm is 6 FG + caster (690) vs 8 FG (720): the preset prices the caster at 2 FG (180), not 150 |
| C2 Bramblesage vs Ember Archers | 100 % | 100 % | +20..+60 | FAIL (+0) | saturated: 11-13 Thornlings beat 8 archers anyway; margin +61 vs +65 |
| C3 Rimecarver dive guard (bot) | 5 % (3.6 Bulwarks) | 5 % | +20..+60 | FAIL (+0) | Bulwarks rise every fight but do not save the Shardcasters; margin -39 vs -19 |
| C4 Gloom Deacon vs Flame Guards | 0 % (Tithe 3.5) | 75 % | +20..+60 | **FAIL** (-75) | the clearest: Tithe is worth far less than 2 Shades |
| C5 bad matchups | Kiln 15 % / Sage 0 % | 100 % / 5 % | >= -10 | FAIL / PASS | |
| C6 counter-casters | Fire 20 / 20, Kilnwarden alive 20 / 20 | - | Scald first >= 60 %, Snagroot >= 80 % | Scald first 6 / 20 **FAIL**, Snagroot 17 / 20 PASS | |
| C7 Passage retreat (bot) | 0.1 Shades alive, **Passage carries 0** (cast 20 / 20) | 0 alive | >= 8 / <= 4 | FAIL / PASS | AI aiming, see below |
The four variants did not change a band result (C1-C5 use fixed counts, so the cost variant changes nothing there; HP and
regen moved the arms by noise only, e.g. C1 caster 25-50 %).

**C7 decision.** The setup had a real flaw: with no keep or towers in the arena, the chasers attack-moved to (-8, 0), 12 m
from home, so carried Shades would have been chased down at the rift. **Fixed**: the chasers now stop at (0, 0), the home
perimeter 24 m from home where the towers would stand (preset notes say why). But that is not why C7 fails: the arena now
records `passage_units`, and the bot's retreat Passage carries **0 units in 20 / 20 fights**: `AICasters._deacon` aims at
the group's densest point at cast time, the group keeps retreating at 4.8 m/s through the 2.5 s channel and is 10-12 m
past the 4 m pick circle when the rift opens. Sent to the ai-coder (`docs/handoff/for-ai-coder.md`: aim at the predicted
position, or hold the group for the channel). The 7.2 band stays; re-run C7 after that fix.

## 4. Checks after the change
- Tests: test_casters (174), test_casters_ai (45), test_casters_bots, test_casters_ui (38), test_data_lab, test_unit_lab
  (70), test_unit_lab_sandbox (24), test_tiers, test_ui_card_hotkeys, test_t3: all PASS.
- Data Lab `docs/data/lab/caster-cost120/`: CU1 Casters PASS; score 95 with 1 FAIL that is not a caster
  (`data/buildings/fire_watch_keep.tres` trains nothing, another agent's new file).
- Bot Lab quick check (`..\four-wizards-lab-runs\botlab-caster120b\`, normal, 15:00 limit, early stop off): fire:ice ->
  Ice on score at 15:00, nature:shadow -> Nature concede at 10:09; 0 script errors, no stall flags. The Bot Lab's
  results do not count casters, so "bots field casters sanely" rests on `tests/test_casters_bots.gd` (PASS: a bot match
  where the bots train their caster and cast). A first try with 4 pairs waited 2 h for a Godot slot behind the map
  gate's Thornwater bot runs and was stopped. Suggestion for the Bot Lab owner: casters trained / alive / casts per side
  in the `lab_match.gd` stats.
