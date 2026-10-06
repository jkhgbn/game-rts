# Unit Lab: first matrix (2026-10-05)

First balance finding of the Unit Lab (`docs/plan/unit-lab.md`). Run: `tools\unit_lab\run_unit_lab.ps1 matrix_t1t2 -Run first_matrix`.
Full tables: `first_matrix/scorecard.md` (ranking, top 10, counter table), `first_matrix/matrix.md` / `matrix.csv` (every cell).

**Setup.** 47 entries: every trained tier-1 / tier-2 soldier of the 4 kingdoms (43) + the 4 casters, each as "1 caster at
full mana + the rest of the budget in its kingdom's line unit" (Kilnwarden + Flame Guards, Rimecarver + Rimeshields,
Bramblesage + Thornlings, Gloom Deacon + Shades). Every pair fights at **equal cost** (~720 crystals a side, the
normaliser picks the counts), 20 m apart on flat open ground, both sides attack-move, casters on their default
autocast, level 1, no upgrades. 1081 pairs x 4 seeds = **4324 fights**, 0 script errors, 0 time-outs (every fight ended on
a kill). Score = win 1 / draw 0.5, averaged over the 46 opponents (each opponent weighted equally); 95 % Wilson interval
over ~184 fights per entry (+/- 6-7 points).

**Read it with the setup in mind.** This is the "same crystals, head-on, no micro, no terrain" fight. It measures raw
value per crystal; it does not reward a role that needs a mix (support, artillery behind a wall, archers behind melee).
Realised DPS is 75-85 % of the nominal `damage / cooldown` for melee and ranged alike (walking + armour), so ranged
units are not handicapped by the lab; they lose because, alone and head-on, melee reaches them with more HP per crystal.

## Top 10 outliers (all entries)
| # | Entry | Role | Mean score | Beats / loses to (of 46) | Crystal trade | Verdict |
|---|---|---|---|---|---|---|
| 1 | rime_seer (Ice) | support (shield) | 0 % | 0 / 46 | 0.19 | too weak (support alone: expected) |
| 2 | **hollow_oathsworn** (Shadow T2) | melee | **99 %** | 46 / 0 | 2.44 | **too strong**: beats every entry, incl. the 250+ crystal cavalry |
| 3 | bloomtender (Nature) | support (heal) | 5 % | 2 / 44 | 0.29 | too weak (support alone: expected) |
| 4 | **hexweaver** (Shadow T2) | ranged | **5 %** | 2 / 44 | 0.33 | **too weak**: last of the 19 ranged units too |
| 5 | **ash_hurler** (Fire) | ranged / artillery | **6 %** | 3 / 43 | 0.39 | **too weak**: 60 HP for 140 crystals (balance-lab.md already flagged it) |
| 6 | rimehorn_rider (Ice T2) | melee cavalry | 93 % | 44 / 2 | 1.93 | too strong |
| 7 | pyrehoof_lancer (Fire T2) | melee cavalry | 92 % | 42 / 3 | 1.86 | too strong |
| 8 | barrow_knight (Shadow T2) | melee cavalry | 91 % | 42 / 3 | 1.86 | too strong |
| 9 | bleakbow (Shadow) | ranged (bowman) | 10 % | 4 / 40 | 0.44 | too weak |
| 10 | scorchling (Fire T1) | melee swarm | 89 % | 41 / 5 | 1.75 | too strong |
Next in line: thornback_charger 87 % (the 4th T2 cavalry), frostbow / shardcaster / scorchbow 13-14 %.

## Same-role view (the fairer reading)
Mean score against entries of the **same role only** (melee vs melee, ranged vs ranged), from `matrix.csv`:
- **Melee** (22): hollow_oathsworn 99, rimehorn_rider 86, scorchling 85, pyrehoof_lancer 82, barrow_knight 81,
  thornback_charger 71, rimeshield 64, shade 63, flame_guard 63, greenheart_oathkeeper 54, barrow_ghoul 48,
  bramblehorn 43, snowdrift_rider 40, rime_colossus 39, shadow_knight 37, thornling 31, vinelasher 29, blaze_rider 26,
  rimeling 21, gloam_rider 19, grave_hound 15, **stagrunner 4**.
- **Ranged** (19): frost_mortar 100, pyre_adept 92 (both splash), rime_harrier 83, emberdart_harrier 79,
  hoarlight_magebow 76, duskbolt_harrier 74, bramble_harrier 69, cinder_arbalest 68, thistle_darter 54, burr_slinger 53,
  nightbolt 38, wildwood_archer 36, ember_archer 35, frostbow 24, shardcaster 21, scorchbow 21, bleakbow 15,
  **hexweaver 8, ash_hurler 4**.

## Findings (what to look at first)
1. **Hollow Oathsworn is the clearest outlier** (99 %, beats all 46, trade 2.4). 260 HP, armour 10, 20 damage / 1.2 s for 170
   crystals is already the best EHP x DPS per crystal of the melee line, and Unbroken Vow (shield 100 + 30 % damage
   under 35 % HP) lands in every fight. First knobs to A/B: cost 170 -> 200, or max_hp 260 -> 220, or Vow shield 100 -> 60.
2. **The four T2 cavalry** (Rimehorn Rider, Pyrehoof Lancer, Barrow Knight, Thornback Charger: 245-260 crystals, pop 3)
   all sit at 87-93 % while the T1 cavalry (Blaze Rider 62 %, Gloam Rider 56 %, Stagrunner 46 %, Snowdrift Rider 70 %)
   are mid / low: the T2 step is too big per crystal (HP 380-420, armour 10-20, 25-30 damage for ~+40 % cost over T1).
   Pop 3 is their real price in a match (supply), which an equal-crystal duel does not charge: re-run with an
   equal-pop matrix before nerfing (next step), and A/B a +10 % cost first.
3. **Scorchling** (50 crystals, 89 %) is the best T1 per crystal: 14 bodies at 720 crystals overwhelm everything single-target.
   Its counters in the counter table: the T2 cavalry and the Frost Mortar's splash (0 % each). Knob: cost 50 -> 55.
4. **Weak ranged: Hexweaver and Ash Hurler** (5-6 %, last of the ranged group too). Ash Hurler: 60 HP for 140 crystals
   dies before its 2.2 s reload matters; Hexweaver: 85 HP and 5.7 DPS for 125 crystals at T2 (Wither Hex does not
   compensate). Knobs: Ash Hurler HP 60 -> 85; Hexweaver damage 8 -> 10 or cost 125 -> 105.
5. **Bowmen** (Scorchbow, Frostbow, Bleakbow 10-14 %, Wildwood Archer 18 %) and the T1 archers (Ember Archer 18 %, Nightbolt
   19 %) all lose alone: expected for a back-line unit, but the bowmen (115-140 crystals) are below the T1 archers in
   the ranged-only view (15-24 vs 35-38): their crits / Hamstring / upgrades are not in this run (level 1, no Hall
   upgrades). Re-run with `"bowman": [...]` upgrades before judging.
6. **Stagrunner** (Nature T1 cavalry, 160 crystals) is last of the melee group (4 %): 180 HP, armour 0 for 160 crystals.
   Knob: max_hp 180 -> 220.
7. **Support units** (Rime Seer 0 %, Bloomtender 5 %) are weak alone by construction; judge them in a mix (a "line +
   support" entry, like the caster entries), not from this table.

## Casters (matrix + the C1-C7 duels)
In the matrix each caster entry scored **below its own line unit alone** at the same crystals:
| Entry | Mean score | The line unit alone | Head-to-head vs the line alone |
|---|---|---|---|
| kilnwarden + flame_guard | 60 % | flame_guard 79 % | 0 / 4 |
| gloom_deacon + shade | 61 % | shade 79 % | 0 / 4 |
| rimecarver + rimeshield | 46 % | rimeshield 79 % | 0 / 4 |
| bramblesage + thornling | 42 % | thornling 63 % | 0 / 4 |
The C1-C7 presets (caster-units.md 7.2, 10 seeds each, scorecards in `docs/balance/unit_lab/c*/`) agree:
| Duel | Caster arm | Control arm | Band | Result |
|---|---|---|---|---|
| C1 Kilnwarden vs Rimeshields | 40 % (Slag Rain 3 per fight) | 100 % | +20..+60 | FAIL (-60) |
| C2 Bramblesage vs Ember Archers | 100 % (one Haze per fight) | 100 % | +20..+60 | FAIL (+0: the Thornlings win anyway) |
| C3 Rimecarver dive guard (real AICasters) | 0 % (3.5 Bulwarks per fight) | 10 % | +20..+60 | FAIL (-10) |
| C4 Gloom Deacon vs Flame Guards | 0 % (Tithe 3.2 per fight) | 60 % | +20..+60 | FAIL (-60) |
| C5 Kilnwarden vs Thornlings / Bramblesage vs Flame Guards | 30 % / 0 % | 100 % / 0 % | >= -10 | FAIL / PASS |
| C6 Kilnwarden vs Bramblesage | Fire wins 10 / 10, Kilnwarden alive 10 / 10 | - | Scald first >= 6, Snagroot >= 8 | Scald first 3 / 10 FAIL, Snagroot 8 / 10 PASS |
| C7 Passage retreat (real AICasters) | 0 Shades alive (Passage cast 10 / 10) | 0 alive | >= 8 / <= 4 | FAIL (lab setup to review: no home defence, the chasers reach the rift) |
**Reading**: at level 1 with full mana, the 7.1 budget estimate is optimistic: a caster (150 crystals, pop 2, 3 DPS)
is worth less than the 1.5-2 line units it replaces in a 15-25 s head-on fight. The spells fire (casts per fight above),
so this is a value question, not a bug. Per 7.2's own knobs ("if one is useless: mana start 50 -> 75, cost 150 -> 135"),
the first A/B to run is caster **cost 150 -> 120** (`-Variants` with `{"units": {"kilnwarden": {"cost": 120}, ...}}`),
then the spell numbers. Caveats: the duels use attack-move for the whole army (a player keeps casters back), no
micro, flat ground; C3 / C7 test the bot rules, which the lab plays for real.

## Lab sanity (same day)
- 6 v 6 Flame Guard mirror, 80 seeds: **50 %** (40 / 40). Per team: the player-team side wins 62 % of mirrors (25 / 40)
  -> the game's processing order favours team 0 a little; the lab alternates teams every seed, so use an **even** number
  of seeds (the presets do). With 10 seeds the mirror read 20 % (2 / 10, inside noise at that N).
- 6 Flame Guards +25 % damage vs 6 Flame Guards: 20 / 20 (100 %).
- `tests/test_unit_lab.gd` PASS (49 checks: spec, equal cost, stats, determinism, 1 v 1 mirror tie, +25 % > 60 %, 4-unit
  matrix), `tests/test_unit_lab_sandbox.gd` PASS (24 checks).

## Next runs suggested
1. Equal-**pop** matrix: done (`-Basis pop` / `both`, results in `caster_ab.md`).
2. A/B the top knobs with `-Variants`: hollow_oathsworn cost 200; T2 cavalry cost +10 %; scorchling cost 55; ash_hurler
   HP 85; hexweaver damage 10; casters cost 120.
3. Ranged entries behind a melee screen ("line + 3 archers" entries) to judge the back line in its real job.
