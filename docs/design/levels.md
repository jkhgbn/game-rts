# Hero levels: XP, stat growth, spell ranks (wave 3)

Source of truth for 3.G2 (XP + levels), 3.G3 (spell ranks), 3.U1 (level HUD, learn flow), 3.A1 (the bot
spends points) and the rank rules that 3.G1 must leave room for. Written 2026-09-25 (task 3.D1).
Two systems share one victim table: **wizard levels** (1-8, stats + spell ranks) and **unit veterancy**
(soldiers, 4 levels, chevrons; section "Unit veterancy" below). Rank 1 of every spell is exactly the
`spells.md` table; ranks 2-3 are here. Metres, seconds, `m:ss` since the navmesh was ready. A 1v1 lasts
15-25 min; a normal match ends around wizard level 5-6, a long one near level 8 (max).

## XP sources (the victim table; used by wizards and by soldiers)
Wizard XP is credited to the **wizard of the team that dealt the killing blow** (`take_damage(amount, attacker)`:
the attacker's team; spells and lingering effects like scorched ground or Soul Siphon pass the caster as
attacker). Kills by Ruin Wardens credit nobody. Both wizards use the same table (mirror).
| Victim | XP | Note |
|---|---|---|
| Cinder Hand / Gloom Thrall (worker) | 15 | Worker hunting pays, but slowly |
| Flame Guard | 45 | Soldiers: cost / 2, rounded to 5 |
| Ember Archer | 50 | |
| Blaze Rider | 90 | |
| Ash Hurler | 70 | |
| Shade | 40 | |
| Nightbolt | 50 | |
| Grave Hound | 35 | |
| Shadow Knight | 150 | |
| Ruin Warden (neutral) | 60 | The camp = 240 XP, about one level early on |
| Enemy wizard | **120 + 30 x victim's level** | L1 = 150, L4 = 270, L8 = 390 |
| Ember Hall / Gloom Hall | 100 | Buildings: killing blow by any unit or wizard of the team |
| Hearth / Hovel | 40 | |
| Ember Spire / Night Spire | 80 | |
| Keep / Dusk Keep | 200 | |
| Construction site | 25 % of the finished building's XP (rounded down) | |

**Share rule** (replaces "only the killer levels"): one wizard per team, so nothing is split.
| Wizard state at the kill | XP received |
|---|---|
| Alive and within **20 m** of the victim | 100 % |
| Alive but farther than 20 m | **25 %** (rounded to the nearest, min 1) |
| Dead (respawn timer running) | 25 %, same as far away |
20 m = "in the fight" (aggro 9, Fireball range 16). Staying home still levels a little; fighting levels fast.
**No decay** with repeated kills of the same type: costs already scale it and a 1v1 is too short.
No passive XP over time, no XP loss on death. Levels, XP, spell ranks and unspent points **survive death and
respawn** (the `skirmish-1v1.md` respawn rules are unchanged: 30 s + 15 s per death, no level interaction).

## Level curve (max level 8)
| Level | XP from the previous level | Total XP | Typical time (normal, active player) |
|---|---|---|---|
| 1 | - | 0 | 0:00 |
| 2 | 150 | 150 | 3:00-4:30 (4 Shades or 10 workers) |
| 3 | 250 | 400 | 5:30-7:00 (after the crown camp) |
| 4 | 350 | 750 | 8:00-10:00 |
| 5 | 450 | 1 200 | 11:00-13:00 |
| 6 | 550 | 1 750 | 14:00-17:00 |
| 7 | 700 | 2 450 | 19:00-22:00 |
| 8 | 900 | 3 350 | 25:00+ |
Estimate behind it: a 20-minute match kills ~30 enemy units (~1 400 XP, ~70 % near the wizard), the camp
(240), 4-5 buildings (~400) and the enemy wizard once or twice (~400): about 2 000 XP = level 6.
Overflow carries into the next level. At level 8 the bar reads `MAX`.

## Stat growth per level (levels 2-8; `UnitType` numbers are level 1)
| Wizard | Base (L1) | Per level | Level 6 | Level 8 (max) |
|---|---|---|---|---|
| Vessa HP / damage / mana / regen | 350 / 14 / 100 / 4.0 | +25 / +2 / +10 / +0.25 | 475 / 24 / 150 / 5.25 | 525 / 28 / 170 / 5.75 |
| Malrik HP / damage / mana / regen | 400 / 16 / 100 / 4.0 | +30 / +2 / +10 / +0.25 | 550 / 26 / 150 / 5.25 | 610 / 30 / 170 / 5.75 |
- Level-up: the new max applies at once and the wizard is **healed by the same amount** (+25 / +30 HP,
  +10 mana). No full heal. Range, speed, cooldown and aggro never change.
- The Ember Crown (+100 HP / +50 mana) stacks on top and is still removed on death.

## Spells: points, ranks, level requirements
- Spell 1 (F: Fireball / Shadow Lance) **rank 1 is known at level 1**, free (today's behaviour stays).
- **1 spell point per level from level 2 to 8** = 7 points; the 7 remaining ranks below cost 1 each, so a
  level-8 wizard has everything. Points can be banked; unspent points are kept through death.
- Rank `r` needs rank `r - 1` and the level below. **Spell 3 (E) is not an ultimate**, but it needs level 4.
| Minimum level | Spell 1 (F) | Spell 2 (Q) | Spell 3 (E) |
|---|---|---|---|
| Rank 1 | 1 (free) | 2 | 4 |
| Rank 2 | 3 | 4 | 7 |
| Rank 3 | 5 | 6 | - (2 ranks only) |
There is always something to buy: L2 Q1 · L3 F2 · L4 Q2 or E1 · L5 F3 · L6 Q3 · L7 E2 · L8 the last one.
- **Mana cost never changes with rank** (the AI's mana thresholds and `Not enough mana` stay valid).
  Statuses `haste` and `shroud` keep their `spells.md` numbers; ranks change duration and radius only.

### Vessa
| Spell | Rank 1 (= spells.md) | Rank 2 | Rank 3 |
|---|---|---|---|
| Fireball (F), 40 mana, range 16 | 60 damage, radius 3.5 | 72 damage, radius 3.75 | 85 damage, radius 4.0 |
| Ember Step (Q), 30 mana | cooldown 12, range 12, scorch 4 s at 5 / 0.5 s (40 total), radius 2.5 | cooldown 10, range 14, scorch 5 s (50) | cooldown 8, range 16, scorch 6 s at 6 / 0.5 s (72), radius 3.0 |
| Kindle (E), 50 mana | cooldown 30, radius 8, haste 8 s | cooldown 25, radius 10, haste 12 s | - |
Fireball's scorch disc and targeting ring follow the rank's radius. A rank-3 Fireball (85) still does not
one-shot a Shade (90) or a Flame Guard (130): deliberate.

### Malrik
| Spell | Rank 1 (= spells.md) | Rank 2 | Rank 3 |
|---|---|---|---|
| Shadow Lance (F), 35 mana, range 12, heals 50 % of damage dealt | 50 damage, cooldown 8 | 65 damage, cooldown 7 | 80 damage, cooldown 6 |
| Soul Siphon (Q), 45 mana, range 12, heals 50 % per tick | 5 s at 4 / 0.5 s (40 total), radius 4 | 6 s (48 total), radius 4.5 | 7 s at 5 / 0.5 s (70 total), radius 5 |
| Umbral Shroud (E), 40 mana | cooldown 25, shroud 5 s | cooldown 20, shroud 7 s | - |

### Framework hooks (3.G1 / 3.G2; the lead adds them to the Wizard contract)
- `Wizard`: `level: int`, `xp: int`, `xp_to_next() -> int` (0 at max), `spell_points: int`, `add_xp(amount: int)`,
  `spell_rank(spell_id) -> int` (0 = not learned), `can_learn(spell_id) -> String` (`""` = ok, else in this
  order `"Max rank"`, `"Needs level 4"`, `"No spell points"`), `learn_spell(spell_id) -> String` (same reasons).
  Signals: `xp_changed(xp, xp_to_next)`, `level_changed(level)`, `spell_points_changed(points)`,
  `spell_learned(spell_id, rank)`. Level, XP, ranks and points are public so the HUD and the bot can read them.
- `command_cast` gains the reason **`"Not learned"`, after `"Unknown spell"` and before `"On cooldown"`**
  (added to `spells.md`). Ranks are read at cast time.
- Suggested data: `SpellType` gains `max_rank: int`, `level_required: Array[int]` and `*_by_rank` arrays
  (`damage_by_rank`, `cooldown_by_rank`, `range_by_rank`, `radius_by_rank`, `duration_by_rank`, index = rank - 1);
  the wave 2 scalar fields become rank 1. Gameplay decides the exact shape.
- Level stats: `UnitType` numbers stay level 1; growth lives in the wizard script as the two per-level rows above.
- Level-up while dead is allowed (25 % XP); points can be spent while dead; casting still refuses `"Dead"`.

## Unit veterancy (3.G2, part 2): soldiers level too
The user asked for unit levels (2026-09-25). Kept small: one counter per unit, one loop per kill, no choices.
- **Who levels**: soldiers only (units with a `UnitType` that is not a worker; the wizards have their own
  system above). **Workers, towers, buildings and Ruin Wardens never level.** Workers and buildings can be
  killed for XP, they just never receive any. A unit's XP dies with it; nothing carries over.
- **XP per kill** (same victim table as the wizards, independent of the wizard's share):
| Who | Gets |
|---|---|
| The soldier that dealt the killing blow | 100 % of the victim's XP |
| Every other friendly soldier within **8 m** of the victim (whoever killed it: a soldier, the wizard, a tower) | **25 %**, rounded up, min 1 |
  A wizard, tower or worker killing blow gives the 100 % share to nobody; the 8 m rule still feeds the
  soldiers around. No split by head count: 8 Flame Guards around a dying Shade each get 10.
- **Levels** (cumulative XP; a level-up is checked right after the XP is added):
| Level | Name | XP | Mark above the head | Max HP | Damage |
|---|---|---|---|---|---|
| 1 | Recruit | 0 | none | x 1.0 | x 1.0 |
| 2 | Veteran | 100 | `^` | x 1.1 | x 1.1 |
| 3 | Elite | 300 | `^^` | x 1.2 | x 1.2 |
| 4 | Champion | 700 | `^^^` | x 1.3 | x 1.3 |
  Multipliers apply to the `UnitType` base (never compounding): `max_hp = round(base x mult)`,
  `attack_damage = base x mult`. Level-up **heals the HP gained** (a Shade 90 -> 99 gains 9 HP). Attack
  cooldown, range, speed and aggro never change (so `haste` maths stays simple). Examples at Champion:
  Shade 117 HP / 13 dmg, Flame Guard 169 / 15.6, Shadow Knight 546 / 33.8, Ash Hurler 78 / 31.2.
- **Pacing**: a group of 8 that wins a 10-kill fight gets ~90-140 XP each (1-2 kills + neighbours' shares):
  most survivors become Veterans after one won fight, Elites after 3-4, Champions only in a long match
  (~15 kills' worth). A lone Blaze Rider needs 7 worker kills to reach Veteran: raids pay, slowly.
- **Feedback**: the unit flashes gold `(1.0, 0.85, 0.4)` (modulate) for 0.2 s; no message, no sound.
- **Unit contract additions** (the lead adds them): `Unit.level: int` (1-4), `Unit.xp: int`, `add_xp(amount: int)`,
  signal `level_changed(unit, level)`. Wizards report `level` too (their own scale); `add_xp` on a worker or a
  wizard's unit-XP share does nothing.

## HUD (3.U1; positions at 1600 x 900, hero column of `ui-hud.md` = x 272-572, y 660-884, margin 10)
| Element | Position / size | Look |
|---|---|---|
| Level badge | 28 x 28 at (282, 670) | Rounded square radius 4, bg `(0.15, 0.12, 0.05)`, border 2 px `(1.0, 0.85, 0.4)`, the level number font 16 gold, centred. Greyed like the name while dead |
| Name | font 20 at (318, 670) | `Vessa, Fire Wizard` (existing, shifted right of the badge) |
| HP bar | 280 x 22 at (282, 706) | Existing |
| Mana bar | 280 x 22 at (282, 734) | Existing |
| **XP bar** | 280 x 16 at (282, 762) | Fill `(1.0, 0.85, 0.4)` on `(0.2, 0.17, 0.1)`; text font 12 white `XP  320 / 450`; at max `XP  MAX`, bar full |
| **Points chip** | 70 x 20 at (492, 784), only while `spell_points > 0` | Bg `(1.0, 0.85, 0.4)`, black text font 12 `+1 point` (`+2 points`...), alpha pulses 0.7 <-> 1.0 every 0.8 s. Tooltip `Learn a spell: click + on a spell, or Ctrl+F / Ctrl+Q / Ctrl+E` |
- **Level-up**: `show_message("Vessa reaches level 3")` (`Malrik reaches level 3` for the bot: the player
  sees it too), the badge scales 1.0 -> 1.4 -> 1.0 over 0.4 s, the XP bar flashes white for 0.2 s.
  In the world (3.U2): a flat gold ring `(1.0, 0.85, 0.4, 0.7)` at the wizard's feet grows from radius 0 to 3
  in 0.4 s then fades in 0.3 s, plus 30 gold sparks rising 2 m. Sound: hook `level_up` only; the file comes with 4.U3.
- **Enemy level**: selecting Malrik (single-unit view) shows `Level 4 · Damage 22 · Range 7.0 · Speed 4.4`;
  Vessa's own line gets the same `Level n ·` prefix. Nothing on the minimap.
- **Spell buttons** (command card r2c1-r2c3, the `spells.md` layout):
| State | Look |
|---|---|
| Not learned | `disabled`, alpha 0.45, tooltip third line `Not learned · needs level 4` (or `Not learned` when only a point is missing). Its key does nothing and never triggers another order |
| Learned | As `spells.md`, plus **rank pips**: 6 x 6 squares at (x + 4, y + 54), gap 2, one per possible rank (3, or 2 for E), filled `(1.0, 0.85, 0.4)` for learned ranks, `(0.3, 0.3, 0.3)` otherwise |
| Learnable (`can_learn == ""`) | A **`+` chip** 16 x 16 at the button's top-left (x + 2, y + 2), bg `(1.0, 0.85, 0.4)`, black `+` font 14, pulsing with the points chip. Clicking the chip = `learn_spell`, never a cast. The button border pulses gold |
- **Learn flow**: click the `+` chip, or **Ctrl+F / Ctrl+Q / Ctrl+E** (physical keycodes) with the wizard
  selected or not (the hero column is always visible, so the keys always work for Vessa). Ctrl + spell key
  never starts targeting; F / Q / E without Ctrl still cast. Learning is instant, plays the badge flash (no
  message) and updates pips, tooltip and cooldown overlay.
- Tooltip with ranks: line 1 `Fireball  [F]  Rank 2 / 3`, line 2 = the rank's numbers (`40 mana · 72 damage ·
  radius 3.75`), line 3 = the `spells.md` description; when learnable a 4th line
  `Ctrl+F: rank 3 = 85 damage, radius 4.0` (only what changes). Unlearned: `Fireball  [F]  Not learned`.
- The lead's Keys line gains: **Ctrl + F / Q / E = learn / upgrade spell 1 / 2 / 3** (lead-only edit to `CLAUDE.md`).
- **Unit veterancy in the world (3.U2)**: a `Label3D` billboard above the unit, text `^` / `^^` / `^^^`, gold
  `(1.0, 0.85, 0.4)` with a 2 px black outline, font 48 at `pixel_size` 0.006 (~0.3 m tall), centred 0.3 m
  above the unit's `height`, hidden at Recruit, shown for **both teams** (the player reads enemy veterans too).
  Created by the unit's `level_changed` signal, removed with the unit.
- **Unit veterancy in the selection panel (3.U1)**: single unit: name line `Flame Guard · Veteran` (nothing at
  Recruit), stat line `Damage 13.2 · Range 1.6 · Speed 5.0 · XP 120 / 300` (`XP MAX` at Champion; the numbers
  shown are the boosted ones). Multi-select icons: 1-3 gold 3 x 3 px dots in the icon's top-right corner, 1 px
  gap, above the HP strip.

## The bot (3.A1; extends `ai.md`)
- **Spending**: on the tick after `level_changed`, Malrik learns the **first learnable** entry of his difficulty's
  list (`can_learn == ""`); repeat while points remain. Lists (spell + rank):
| Difficulty | Order |
|---|---|
| Easy | F2, F3, Q1, Q2, Q3, E1, E2 (Lance-heavy; the level rules delay F2 to L3, so L2 buys Q1) |
| Normal | Q1, F2, E1, F3, Q2, Q3, E2 |
| Hard | Q1, F2, E1, Q2, F3, Q3, E2 |
- **Casting**: the `spells.md` rules 1-4 are unchanged; a rule is skipped when its spell is not learned
  (Umbral Shroud from level 4 on normal). Mana thresholds are unchanged (constant costs).
- **Strength** (`ai.md`): a wizard is worth **170 + 30 x level** (L1 = 200, unchanged from wave 2; L6 = 350;
  L8 = 440). Vessa's level is read from `Wizard.level` when she is seen. While Vessa is dead (public
  `Events.unit_died` and the on-screen message), her strength leaves `seen_strength` until she respawns:
  a wizard death is the bot's best attack window.
- `malrik_joins` (normal): 2nd attack, or `own_strength >= 800`, **or Malrik level >= 4**. Hard: every attack
  (unchanged). Easy: never (unchanged).
- **Veteran soldiers in strength**: a soldier is worth `cost x (0.8 + 0.2 x level)` (Recruit 1.0, Veteran 1.2,
  Elite 1.4, Champion 1.6 x cost), in `own_strength` and in `seen_strength` alike (`Unit.level` is public and
  the chevrons are visible). Same knob, no new rule: a veteran enemy army makes the bot wait for more units,
  and its own veterans make it attack sooner.
- Nothing else changes: Malrik does not hunt XP on purpose; the bot never protects or retreats veterans
  specially. The reserve rule ("2 soldiers with the highest HP") naturally keeps veterans home.

## Balance note: veteran soldiers
- Combat power scales with HP x damage: Veteran 1.21x, Elite 1.44x, **Champion 1.69x** a Recruit.
  10 Champion Shades vs 10 Recruit Shades: the champions win with ~6 left; 10 Champions ~ 13 Recruits,
  i.e. **+240 crystals** of value (35 s of income). 10 Veterans ~ 11 Recruits. Nothing a level gives beats
  one extra barracks cycle, and champions need ~15 kills' worth of XP each, so full champion armies are rare.
- Veterancy is a snowball: the side that wins fights keeps stronger survivors. The share rule (25 % only
  within 8 m) and "XP dies with the unit" keep it mild; the counter is Fireball / Soul Siphon, which do not
  care about chevrons. Knobs if playtest 3 says it snowballs: +10 % -> +8 % per level, or thresholds
  100 / 300 / 700 -> 150 / 400 / 900.

## Balance note: a level-6 wizard vs 10 soldiers
- Level-6 Vessa: 475 HP, 24 auto-attack damage (~18 DPS), 150 mana = **3 Fireballs at 85** (255 area damage),
  Ember Step rank 3, Kindle rank 1. Level 1: 350 HP, 2 Fireballs at 60. She is about **2x** her level-1 self.
- Vs 10 Shades (800 crystals, 900 HP, 100 DPS in melee): if they clump, 2 Fireballs kill every Shade inside
  4 m, realistically 5-6 of 10; the 4-5 left deal ~45 DPS and kill her in ~10 s unless she Ember Steps out.
  Alone she trades her life for ~400-500 crystals of Shades; with 5 soldiers behind her she wins cleanly.
- Vs 10 Nightbolts (10 damage, range 9, spread out): ~100 DPS from range, fewer units per Fireball: she dies
  in ~5 s if she stays. **Ranged lines and the Shadow Knight (420 HP, survives 4 Fireballs) are the counters.**
- Rule of thumb: a wizard is worth ~350 crystals of soldiers at level 1, ~600 at level 6, ~750 at level 8.
  A base makes ~420 crystals / min, so no level is worth more than two minutes of income; levels reward the
  active player without replacing the army. Playtest 3 checks this ("is a level 5+ wizard too strong?").
  Knobs if it fails: per-level HP (+25 -> +20), Fireball rank 3 (85 -> 78), or the far-away share (25 % -> 15 %).

## What changed in other specs
- `spells.md`: `command_cast` reason list gains `"Not learned"` after `"Unknown spell"`; a pointer to the rank
  tables here. Rank 1 numbers untouched. AI cast rules skip unlearned spells.
- `ai.md`: wizard strength 200 becomes `170 + 30 x level` (same at L1); soldier strength = `cost x (0.8 + 0.2 x level)`
  (same at Recruit); `malrik_joins` gains "or level >= 4"; a dead Vessa leaves `seen_strength`.
- `ui-hud.md`: the hero column gains the badge, XP bar and points chip (positions above); name shifts to x 318;
  the single-unit view gains the veterancy name and `XP x / y`; multi-select icons gain the gold dots.
- `units-fire-shadow.md`: nothing changes; every number there is level 1 / Recruit.
- `skirmish-1v1.md`: nothing changes (respawn rules as written; levels survive death).

## Done when
- [ ] 3.G1: `command_cast` returns `"Not learned"` for a rank-0 spell, in the order Dead / Unknown spell / Not learned / On cooldown / Not enough mana / Invalid target; spell numbers are read per rank; mana cost is the same at every rank.
- [ ] 3.G2: the XP table and share rule hold (test: a Shade killed by a Flame Guard 10 m from Vessa gives 40 XP, at 30 m gives 10, while Vessa is dead gives 10; a Ruin Warden killed by a warden gives 0); level 2 at 150 XP and level 8 at 3 350 total, `MAX` after; each level adds exactly the per-level row (Vessa L6 = 475 HP / 24 dmg / 150 mana / 5.25 regen) and heals by the gain; 1 point per level from 2 to 8; `can_learn` refuses `Max rank` / `Needs level n` / `No spell points` in that order; level, XP, ranks and points survive respawn.
- [ ] 3.G2 (veterancy): a Shade killed by a Flame Guard gives that guard 40 XP and 10 to each friendly soldier within 8 m of the Shade, 0 to a worker, 0 to a soldier 9 m away; a kill by Vessa or a tower gives only the 25 % shares; a soldier reaches Veteran at 100, Elite at 300, Champion at 700 XP with HP and damage x 1.1 / 1.2 / 1.3 of the `UnitType` base (Shade Champion = 117 HP, 13 dmg) and is healed by the HP gained; cooldown, range and speed unchanged; workers, towers and Ruin Wardens never level; `level_changed` fires once per level.
- [ ] 3.G3: the six spells use the rank tables exactly (test: Fireball rank 3 deals 85 in radius 4.0; Ember Step rank 3 blinks 16 m and its scorch deals 72 over 6 s; Kindle rank 2 lasts 12 s in radius 10; Shadow Lance rank 3 deals 80 and heals 40 on a full hit with a 6 s cooldown; Soul Siphon rank 3 deals 70 over 7 s and heals 35; Umbral Shroud rank 2 lasts 7 s with a 20 s cooldown); rank 1 of each equals `spells.md`.
- [ ] 3.U1: level badge at (282, 670), XP bar at (282, 762) with `XP  x / y` and `MAX`, points chip at (492, 784) only while points exist; level-up message + badge scale + bar flash; unlearned spell buttons disabled with the reason, rank pips at (x + 4, y + 54), `+` chip at (x + 2, y + 2) that learns without casting; Ctrl+F / Q / E learn by physical keycode and never start targeting; tooltips follow the rank format; selecting either wizard shows `Level n` in the stat line; a selected Veteran+ soldier shows its rank name and `XP x / y`, multi-select icons show 1-3 gold dots; nothing in `scripts/ui/` calls a `_private` function.
- [ ] 3.U2: the level-up ring (radius 0 -> 3 in 0.4 s, fade 0.3 s, 30 gold sparks) plays on both wizards; Fireball's disc and Ember Step's scorch use the rank's radius; effects removed when their spell ends; `^` / `^^` / `^^^` chevrons above Veteran / Elite / Champion soldiers of both teams, none at Recruit, gone when the unit dies; the 0.2 s gold flash on a unit level-up; `PERF OK` with 200 units carrying chevrons.
- [ ] 3.A1: Malrik spends every point on the tick after levelling, following the difficulty list (test: normal at level 4 has Q1, F2, E1); unlearned spells are never cast; a wizard counts `170 + 30 x level` and a soldier `cost x (0.8 + 0.2 x level)` in `own_strength` / `seen_strength`; a dead Vessa counts 0 until respawn; `malrik_joins` at level 4 on normal; `PERF OK` unchanged.
