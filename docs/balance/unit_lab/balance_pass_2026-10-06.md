# Unit Lab balance pass (2026-10-06): Oathsworn, T2 cavalry, Flame Guard, C7

Follow-up of `caster_ab.md` (2026-10-05). Goal: bring the Hollow Oathsworn and the four T2 cavalry to **<= 75 %** mean score
at **equal crystals AND equal pop**, judge the line units in mixed armies, verify the bot's retreat Passage fix (C7).
All runs through `tools\unit_lab\run_unit_lab.ps1`, even seed counts (team alternation). About 60 000 fights.

## Changelog
| What | Where | Why |
|---|---|---|
| **Hollow Oathsworn** cost 170 -> **180**, max_hp 260 -> **200**, attack_damage 20 -> **17** | `data/units/hollow_oathsworn.tres` | 99 % / 98 % (crystals / pop): beat 44-45 of 46 entries |
| **Unbroken Vow** shield 100 -> **50**, attack +30 % -> **+15 %** (cd 45 s, 35 % HP, 6 s kept) | `scripts/units/new_units_12.gd` `VOW` + description; `tests/test_new_units_12.gd` checks shield 50 / +15 % | at equal pop no data knob alone got it under 80 %: the Vow was a 38 % HP top-up in every fight (fights last 15-30 s, cd 45 s) |
| **Rimehorn Rider** cost 250 -> **275**, max_hp 400 -> **320** | `data/units/rimehorn_rider.tres` | 93 / 85 |
| **Pyrehoof Lancer** cost 260 -> **285**, max_hp 400 -> **320** | `data/units/pyrehoof_lancer.tres` | 92 / 88 |
| **Barrow Knight** cost 255 -> **280**, max_hp 380 -> **310** | `data/units/barrow_knight.tres` | 91 / 84 |
| **Thornback Charger** cost 245 -> **270**, max_hp 420 -> **360** | `data/units/thornback_charger.tres` | 87 / 77 |
| **Flame Guard** max_hp 130 -> **120**, attack_damage 12 -> **11** | `data/units/flame_guard.tres` | the Fire T1 mix won 86 % of mixed-army fights (60 seeds), the only kingdom-mix outlier |
| Bramblesage con "Worst HP per crystal in the Nature army" -> "Frail for its price" (rank 3 since the caster cost cut to 120; the string has a French entry) | `data/ui/unit_guide.json` | `tests/test_unit_guide.gd` |
| Unit Lab: side key **`home_zone`** `[x, z, r]` (stand-in for a side's keep + towers: an enemy unit inside the circle drops its target and walks back to its own start) + 3 test checks | `tools/unit_lab/unit_lab_spec.gd`, `unit_lab_arena.gd`, `tests/test_unit_lab.gd` | C7 study below |
| Variants `ab_t2_hp20`, `ab_t2_hpdmg`, `ab_t2_both_strong`, `ab_t2_r2a/b/c`, `mix_fg_hp120`, `mix_fg_dmg11`, `mix_fg_both` | `tools/balance_lab/variants/` | the A/B arms |
Not changed: Rimeshield (Ice mix 37 % in mixes), Vinelasher (not in any kingdom mix; nothing in the mix test points at it).
Unit Guide claims: no rank claim of the changed units broke (`test_unit_guide` PASS, 70 units).

## 1. Passage fix (C7, `c7_passage_fix/`, 20 seeds)
| | before (2026-10-05) | after (aim at the predicted position) |
|---|---|---|
| Passage cast | 20 / 20 | 20 / 20 (2.5 s) |
| Units carried per fight (`passage_units`) | **0** | **5.0** |
| Shades alive (caster arm / control) | 0.1 / 0 | **0 / 0** |
| C7 checks | FAIL / PASS / PASS | FAIL (alive 0, min 8) / PASS / PASS |
The fix works (0 -> 5 units carried), but the >= 8 alive band still fails, and **not because of the aim**: the Flame Guards
start 5 m behind the Shades, are faster (5.0 vs 4.8 m/s), and an attack-move unit keeps chasing any target within
2 x aggro (16 m), so the "stop at (0, 0)" target never stops them: they chase the uncarried Shades all the way home and
kill the carried ones and the Deacon there (fight log: last Shade dies at 10-12 s, Deacon at 15-17 s).
With a home defence stand-in (`home_zone` r 6 or 9 around the Deacon, `c7_home_zone/`): caster arm 6.8 Shades alive,
control 8.3. So in this geometry (home 30 m away, 6 s on foot) walking home saves as many as the Passage; the carried
Shades stand idle beside the Deacon and re-engage chasers at the zone edge. The AI cannot pack more than ~5 of 12 into the
4 m circle while the group is being hit (it is spread over ~8-10 m). **Proposal (game-designer)**: rewrite C7 as a long
retreat (home >= 50 m away, chasers as fast as the group) where only the Passage can save the group, or count
`passage_units >= 8` as the band. AI left as committed.

## 2. A/B (focus matrix: the 5 units vs all 46 others; mean score)
Cost = equal crystals (720), pop = equal pop (8). "4 s" = 4-seed screen, "20 s" = 20 seeds. A cost-only change does nothing
at equal pop; an HP change acts on both.
| Variant | seeds | Oath cost / pop | Rimehorn | Pyrehoof | Barrow K. | Thornback |
|---|---|---|---|---|---|---|
| baseline (first_matrix / pop screen) | 4 | 99 / 97 | 93 / 85 | 92 / 88 | 91 / 82 | 87 / 80 |
| ab_t2_cost (+10 %; Oath 200) | 20 | 94 / = | 78 / = | 79 / = | 77 / = | 71 / = |
| ab_t2_hp (-10 %; Oath 220 HP) | 4 | 98 / 96 | 89 / 79 | 83 / 79 | 79 / 76 | 77 / 72 |
| ab_t2_hp_strong (-15 %; Oath 200 HP) | 4 | 96 / 91 | 81 / 76 | 79 / 76 | 74 / 70 | 75 / 65 |
| ab_t2_both (cost + hp) | 4 | 84 / 96 | 72 / 79 | 66 / 79 | 64 / 76 | 64 / 72 |
| ab_t2_both_strong (cost + hp_strong) | 4 | 77 / 91 | 68 / 76 | 63 / 76 | 61 / 70 | 57 / 65 |
| ab_t2_hp20 (-20 %; Oath 200 HP 17 dmg) | 4 | 87 / 84 | 78 / 71 | 73 / 71 | 69 / 65 | 69 / 60 |
| ab_t2_hpdmg (-10 % HP and dmg) | 4 | 84 / 80 | 73 / 70 | 76 / 72 | 70 / 70 | 70 / 61 |
| r2a: Vow 50 / +15 %, Oath 200 c; cav cost +10 %, HP 330/330/325/380 | 4 | 79 / 92 | 60 / 74 | 58 / 74 | 64 / 70 | 66 / 73 |
| r2b: r2a + Oath 230 HP | 4 | 67 / 87 | 65 / 73 | 59 / 74 | 64 / 76 | 66 / 75 |
| r2c: r2a + Oath 190 c, 220 HP, 18 dmg | 4 | 58 / 70 | 64 / 71 | 59 / 75 | 62 / 76 | 68 / 74 |
| final cavalry (cost +10 %, HP 320/320/310/360) + r2c Oath | 20 | 64 / **79** | 60 / 71 | 57 / 73 | 60 / 73 | 62 / 70 |
| **applied** (Oath 180 c, 200 HP, 17 dmg, Vow 50 / +15 %) | 20 | **52 / 64** | **60 / 73** | **57 / 73** | **60 / 74** | **62 / 70** |
(The applied cavalry cost column is the 20-seed run before the last Oathsworn cut; their pop column is the 20-seed rerun with
everything applied, `ab_t2_cav_pop_final/`. Runs: `ab_t2_cost_basis/`, `ab_t2_screen_cost|pop/`, `ab_t2_screen2_cost|pop/`,
`ab_t2_final_cost|pop/`, `ab_t2_oath_cost|pop/`, `ab_t2_cav_pop_final/`.)
Reading: cost alone fixes nothing at equal pop and only reaches 71-79 at equal crystals; HP -15..-20 % gets the cavalry under
75 at pop, the cost +10 % gives the margin at crystals. The Oathsworn needed the Vow cut: data knobs alone stayed at 80-96 %
at equal pop.

## 3. Mixed armies (`mix_line_check`, 60 seeds an arm; a kingdom = the mean of its 3 arms)
Mix = caster (full mana, bot AI) + line unit + T1 ranged, ~1035-1080 crystals.
| Variant | Fire | Ice | Nature | Shadow |
|---|---|---|---|---|
| baseline (24 seeds, `mix_line_check/`) | 85 | 43 | 35 | 37 |
| baseline (60 seeds, `mix_line_check_fg60/`) | **86** | 37 | 28 | 49 |
| Flame Guard 120 HP | 78 | 41 | 34 | 47 |
| **Flame Guard 120 HP + 11 dmg (applied)** | **69** | 51 | 29 | 51 |
The mixes are noisy (an arm without any change moved 0-33 % between 24-seed runs): only the 60-seed runs count. Fire was
the outlier; Rimeshield's Ice mix is not (37-51 %), so the Rimeshield stays. Nature's mix is now the weak one (28-34 %):
Thornling + Burr Slinger + Bramblesage, the units the matrices already rank weak per pop (lead for the next pass, nothing
applied).

## 4. Final matrices (47 entries, 4 seeds, 4324 fights each, everything applied)
`final_matrix_t1t2/` (equal crystals), `final_matrix_t1t2_pop/` (equal pop), `final_matrix_t1t2_both/` (both budgets).
Before = `first_matrix/`, `matrix_pop/`, `matrix_both/`.
| Entry | Crystals before -> after | Pop | Both |
|---|---|---|---|
| hollow_oathsworn | 99 -> **53** | 98 -> **64** | 100 -> **67** |
| rimehorn_rider | 93 -> **65** | 85 -> 76 (20 s: **73**) | 92 -> 76 |
| pyrehoof_lancer | 92 -> **55** | 88 -> 77 (20 s: **73**) | 90 -> 73 |
| barrow_knight | 91 -> **61** | 84 -> 74 (20 s: **74**) | 91 -> 82 |
| thornback_charger | 87 -> **60** | 77 -> **70** | 83 -> 72 |
| flame_guard | 79 -> 72 | 86 -> 74 | 89 -> 81 |
The 4-seed cells carry about +/- 7 points; the 20-seed focus runs are the verdict for the five targets (all <= 75 at
crystals and at pop). "Both" was not a target; Barrow Knight's 82 there is integer army sizing (2 knights fit 720 crystals
and 8 pop exactly) plus noise; check it with 20 seeds if it matters.

**Outlier table after the pass** (mean >= 70 or <= 30 in a basis; the matrix is relative: with the five dominant units cut,
every melee unit's mean rose 5-15 points):
| Entry | Crystals | Pop | Both | Reading |
|---|---|---|---|---|
| scorchling | 95 | 33 | 42 | crystal-cheap swarm, priced by supply: not an outlier at pop |
| rimeshield | 90 | 93 | 92 | **strong line unit alone**; fair in mixes (Ice mix 37-51 %) |
| shade | 88 | 70 | 78 | **next candidate** (Shadow line) |
| greenheart_oathkeeper | 87 | 78 | 86 | **next candidate** (T2) |
| snowdrift_rider | 81 | 79 | 83 | **next candidate** (T2 light rider) |
| shadow_knight | 79 | 82 | 83 | **next candidate** (T2) |
| bramblehorn | 79 | 94 | 93 | **next candidate** |
| rime_colossus | 76 | 94 | 89 | **next candidate** |
| vinelasher | 69 | 97 | 83 | strong per pop (pop 1, 120 crystals); not in a kingdom mix |
| gloom_deacon+shade | 82 | 51 | 58 | Shade line effect; caster fair at pop |
| barrow_ghoul / rimeling / thornling | 80 / 73 / 68 | 38 / 14 / 24 | 43 / 27 / 35 | cheap pop-1 bodies: priced by supply |
| pyre_adept / frost_mortar / cinder_arbalest | 76 / 76 / 30 | 93 / 76 / 76 | 77 / 78 / 40 | T2 ranged that win head-on; check in mixes |
| flame_guard | 72 | 74 | 81 | judged in mixes: fair after the change |
| gloam_rider / blaze_rider | 64 / 68 | 79 / 72 | 81 / 81 | light riders, strong per pop |
| bramblesage+thornling | 43 | 9 | 14 | weakest caster entry per pop (pop 2 caster + pop-1 line) |
| harriers (emberdart, rime, duskbolt, bramble) | 33-36 | 17-29 | 35-45 | weak per pop |
**Exempt by role** (alone head-on they lose by construction; judge them in mixes): pure support **Rime Seer** (0 / 5 / 0),
**Bloomtender** (5 / 5 / 10); T1 archers **Ember Archer** (18 / 25 / 26), **Wildwood Archer** (18 / 10 / 23), **Nightbolt**
(17 / 22 / 26), **Shardcaster** (14 / 32 / 18), **Burr Slinger** (24 / 2 / 10), **Thistle Darter** (25 / 1 / 8); bowmen
**Frostbow** (16 / 62 / 23), **Scorchbow** (11 / 45 / 18), **Bleakbow** (11 / 29 / 18), **Hoarlight Magebow** (33 / 47 / 52);
**Ash Hurler** (8 / 41 / 4) and **Hexweaver** (3 / 27 / 6) (siege / debuff).

## 5. Tests (all PASS)
test_data_lab (score 95: its 1 FAIL is T8 French strings in `ui_hud_windows.po` from other work, not this pass),
test_unit_guide (70 units), test_unit_lab (74 checks), test_tiers, test_t3, test_new_units_12, test_bowmen, test_casters
(174), test_casters_ai (45), test_casters_ui (38), test_casters_bots, test_ui_card_hotkeys.
