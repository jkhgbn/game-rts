# Champion classes: Spear, Sword and Shield, Two-Hand Sword, Wizard

Task 11.D1 (re-targeted 2026-09-26 on the user's request, revised the same day with the user's answers). Source of truth
for step 11 (tasks in section 12).
User request: **champions choose a combat class by themselves** (autonomous, in the spirit of indirect-control hero
games), among **Spear, Sword and Shield, Two-Hand Sword, Wizard**, each with **exactly 3 skills** that scale with the
champion's level (1-6). The player never picks the class. The class skills **add** to the 3 archetype abilities of
`champions.md` 4.3 (6 abilities at most). **The player's wizard is unchanged** (F / Q / E, levels 1-8, `levels.md`).
The bigger level-110 / masteries idea is for a future game: short notes in the appendix, no work planned.
Every name, skill and number here is our own. Builds on `champions.md` (quoted as "ch. 4.3" etc.), `items.md`,
`balance-1.md`, `balance-2.md`, `art-units.md`, `ui-champions.md`. Metres, seconds, `m:ss` since the navmesh was ready.

## 0. Decisions for the user (answered 2026-09-26)
| # | Question | User's answer |
|---|---|---|
| Q1 | When does a champion choose its class? | **At level 2**, a weighted draw: its archetype leans one way and **the bounties you paid it before level 2 tip the balance** (section 2) |
| Q2 | Class skills: replace or add? | **Add**: the 3 archetype abilities stay (Smoke Pouch included) and the class brings 3 more = **6 at most**. The extra power is paid for (section 9) so games do not get shorter |
| Q3 | Odd pairs (an Oathwall mage)? | **Allowed but rare** (5-20 % by the table of 2.1) |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Who picks | The champion, at level 2, by a weighted draw (section 2) | The player never picks; bounties (ch. 6) are the existing lever, so they become the nudge |
| What a class changes | **The weapon** (attack damage, cooldown, range, melee / ranged), a small stat change, 3 skills, the look (weapon swap), the brain's stance | The archetype keeps HP, armor, speed, sight, personality, its 3 abilities, wish list, barks: *who* it is; the class is *how* it fights |
| Abilities | 3 archetype (2 at level 1, the 3rd at level 4, ch. 4.3 unchanged) + 3 class (levels 2, 3, 5) = **6 at level 5** | Same autocast model: one cast per 0.5 s check, one priority list |
| No duplicates | The 12 class skills are all new ids with effects no archetype ability has | Any archetype x class pair has 6 different abilities |
| Skill growth | Amounts x `(1 + 0.08 x (level - 1))` x `(1 + spell_power / 100)`, cooldowns x CDR (ch. 4, unchanged) | "Skills simply scale with the level" |
| Paying for the extra power | Champion XP table **x1.25**, class weapons trimmed, class skills on long cooldowns, hire **+25 crystals** each, revive **80 + 35 x level** essence | Games are already 9-11 min (target 15-20): champions must not shorten them (section 9) |
| Permanent? | Yes for that champion: kept through death, revive and as a campaign companion; a dismissed and re-hired archetype starts over at level 1 with no class | One decision per hero, readable |

## 2. How a champion chooses its class
### 2.1 The draw
When a champion reaches **level 2** (in `add_xp`, before `level_changed` is emitted), it draws its class once:
`weight(class) = base(archetype, class) + 20 x (bounties paid to it before level 2 whose kind leans to that class)`,
at most **+40** per class. Draw with the champion's own `RandomNumberGenerator` (tests pass their own).
| Archetype | Spear | Sword and Shield | Two-Hand Sword | Wizard |
|---|---|---|---|---|
| Wayfinder | **50** | 10 | 15 | 25 |
| Oathwall | 15 | **60** | 20 | 5 |
| Coin-Cutter | 25 | 5 | **55** | 15 |
| Mender | 15 | 20 | 5 | **60** |
| Bounty kind that leans to it | Explore | Guard | Hunt | Escort |
Example: an Oathwall paid 2 Guard bounties before level 2: Sword and Shield 100 of 140 = **71 %**. A Coin-Cutter paid
one Escort bounty: Wizard 35 of 120 = 29 %. "Paid" = a `BountyBoard.bounty_paid(bounty, champion, amount)` for this
champion; a Guard / Escort service pays several ticks but counts **once per bounty**.
### 2.2 Feedback
- Message `Garran Stoneward takes up the Sword and Shield` (own champions; enemy ones only when visible).
- Bark (100 %, ch. 4.5 rules), replacing the level-up bark at level 2: Wayfinder `New road, new stick.` ·
  Oathwall `Something heavier. Finally.` · Coin-Cutter `Bigger blade, bigger cut.` · Mender `Every tool mends something.`
- VFX `class_chosen` (a 1 s ring of light at its feet); the model swaps its weapon (section 5).

## 3. The four classes: weapon and stats
Before level 2 a champion fights with its archetype weapon (ch. 4.1). From the choice on, **the class sets the weapon
numbers** (base attack damage, cooldown, range, projectile; the level growth multiplies the damage as today) and adds a
modifier `class:<id>`. The archetype keeps its HP, armor, speed, aggro, sight and flee threshold.
| id | Name | Weapon (level-1 damage / cooldown / range) | DPS L1 | Modifier `class:<id>` | Flee threshold | Model attack style |
|---|---|---|---|---|---|---|
| `spear` | Spear | 13 / 0.95 / **2.4** (melee reach) | 13.7 | `move_speed` +0.2 | unchanged | `spear_thrust` |
| `sword_shield` | Sword and Shield | 12 / 1.10 / 1.8 | 10.9 | `armor` +10, `move_speed` -0.2 | -0.05 | `sword_slash` |
| `two_hand` | Two-Hand Sword | 24 / 1.55 / 2.1 | 15.5 | none | unchanged | `great_cleave` |
| `wizard` | Wizard | 11 / 1.30 / **7.5**, bolt `(0.6, 0.75, 1.0)` 26 m/s | 8.5 (ranged) | `max_hp_pct` -0.10 | +0.05 | `staff_bolt` |
Percent modifiers add up with the level growth (Stats contract): a Mender Wizard at level 4 has `280 x (1 + 0.24 - 0.10)`
= 319 HP. `attack_range` and the projectile are fields, set by `set_champion_class`.

## 4. Abilities
### 4.1 Unlock schedule (6 abilities)
| Level | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Unlocks | Archetype 1 + 2 (ch. 4.3) | **Class choice** + class skill 1 | Class skill 2 | Archetype 3 (ch. 4.3) | Class skill 3 | `MAX` (growth only) |
| Abilities owned | 2 | 3 | 4 | 5 | 6 | 6 |
The 12 archetype abilities keep their ids, numbers and triggers (ch. 4.3). Two get a new look because the bow leaves the
Wayfinder's hands: `flare_arrow` is displayed **Signal Flare** (thrown from her lantern pole; text `Hurls a flare up to
20 m: 20 damage around it, and the spot stays in sight for 6 s.`) and Snare Line is thrown by hand (text unchanged).

### 4.2 The 12 class skills (autocast; `ChampionAbilities` checks triggers every 0.5 s, one cast per check)
Values are level 1 (x growth and spell power). "Hero" = wizard or champion (crowd control lasts half as long, ch. 4).
None of them repeats an archetype effect: no taunt, no `rooted`, no `haste`, no `braced`, no `marked`, no shield on an
ally, no heal on others, no smoke.
| Class | Unlock | id | Name | Cooldown | Range | Effect (level 1) | Autocast when |
|---|---|---|---|---|---|---|---|
| Spear | L2 | `lunge` | Lunge | 14 | 6 | Darts to the target (instant move to the closest navmesh point 1 m from it, like Ember Step) and strikes: **25 damage** + `dazed` 0.5 s | Fighting or hunting, and a preferred target (an enemy ranged unit or caster, or an enemy under 40 % HP) is 3-6 m away and not within 11 m of a known enemy tower; or its Hunt target is within 6 m and moving away |
| Spear | L3 | `hobbling_javelin` | Hobbling Javelin | 16 | 10 | A javelin (24 m/s): **25 damage** + `smoulder` 3 s (move speed -1.5; the existing status, called "hobbled" in this skill's text) | An enemy unit within 10 m under 60 % HP moving away from it or from an own unit; or its Hunt target moving away |
| Spear | L5 | `skewer` | Skewer | 25 | line 5 x 1 m | A long thrust through a 5 m line toward its target: **40 damage** to every enemy unit in the line | 3+ enemy units in that line |
| Sword and Shield | L2 | `riposte` | Riposte | 22 | self | For **4 s** every melee hit it takes (attacker range <= 3 m) deals **10 damage** back to the attacker (credited to it) | 2+ enemy melee units are attacking it |
| Sword and Shield | L3 | `second_wind` | Second Wind | 45 | self | Heals **itself** 20 % of its max HP over 4 s (8 ticks) | HP < 50 % and it was hit in the last 2 s |
| Sword and Shield | L5 | `shield_throw` | Shield Throw | 20 | 8 | Throws its shield: **30 damage** to the target, then bounces to up to 2 more enemy units within 4 m (20, then 10); the shield flies back | An enemy ranged unit or caster within 8 m is hitting an own unit; or its current target is 3-8 m away and out of reach |
| Two-Hand Sword | L2 | `cleave` | Cleave | 10 | melee | Its next attack (within 3 s) also hits every other enemy unit within **2.5 m of the target** for 100 % of that attack's damage | Its current target has 2+ other enemy units within 2.5 m |
| Two-Hand Sword | L3 | `crushing_blow` | Crushing Blow | 20 | melee reach | **30 damage**; an enemy **unit** hit loses 20 `armor` for 6 s (modifier `ability:crush`; buildings take the damage only) | Its current target has armor >= 10, or is a hero or a unit costing >= 200 |
| Two-Hand Sword | L5 | `whirlwind` | Whirlwind | 30 | self, r 3 | Spins for 2 s (keeps moving and attacking): every 0.5 s **12 damage** to every enemy unit within 3 m (48 each) | 3+ enemy units within 3 m |
| Wizard | L2 | `arc_bolt` | Arc Bolt | 10 | 12 | A bolt (28 m/s): **40 damage** to one enemy unit | An enemy unit within 12 m whose HP <= the bolt's damage (highest cost first); else an enemy hero in range; else the enemy attacking the most hurt ally |
| Wizard | L3 | `slipstep` | Slipstep | 22 | self, 8 | Teleports up to 8 m straight away from the nearest melee enemy (closest navmesh point, never onto a cell its team has not explored) | A melee enemy within 3 m targets it and its HP < 70 %; or it is fleeing and a melee enemy is within 4 m |
| Wizard | L5 | `starfall` | Starfall | 35 | 12, r 3.5 | A falling star lands **1.0 s** after the cast (ring shown to both teams): **45 damage** to every enemy unit and building in r 3.5 | An enemy unit in range with 3+ enemy units within 3.5 m of it (itself included): the one with the most |
Growth example: Arc Bolt 43 / 50 / 53 at levels 2 / 4 / 5; Whirlwind 63 per enemy at level 5; Second Wind heals 20 % of
a max HP that already grows (no extra growth on the %). `smoulder` and armor below 0 use the existing rules (`items.md`:
negative armor = damage x `1 - armor / 100`).

### 4.3 Autocast priority (24 ids, one list; each champion only owns its 6)
Escapes, then saves, then control, then area damage, then single damage, then heals, then utility:
`smoke_pouch`, `slipstep`, `snare_line`, `trailblaze`, `lifeline`, `second_wind`, `bulwark_stand`, `oath_of_iron`,
`riposte`, `shield_bash`, `hobbling_javelin`, `crushing_blow`, `whirlwind`, `starfall`, `skewer`, `marked_for_coin`,
`lunge`, `cleave`, `shield_throw`, `arc_bolt`, `cutpurse`, `soothing_circle`, `mending_draught`, `flare_arrow`.
Riposte listens to the champion's own `damage_taken(amount, attacker)` while active. Cutpurse + Cleave on the same swing:
both apply. The "next attack" buffs (Cleave, Cutpurse) also ride a Wizard's bolt (Cleave then hits around the bolt's target).

## 5. Look: the weapon swap (art)
The four models stay; the class swaps what is in their hands. Budgets of ch. 4.6 hold (<= 26 authored meshes, <= 16 draw
instances, 0 lights, <= 5 own materials; the kit weapon materials are shared, read-only).
| Weapon (shared kit, `art/units/champions/weapons/`) | Look (40 m silhouette test: the class must read from the weapon) | Attack style / class skill poses |
|---|---|---|
| Spear | 2.3 m ash shaft, 0.35 m leaf blade, a team-colour tassel under the blade; held mid-shaft, tip forward and up; a back quiver of 3 short javelins | `spear_thrust` (strike 0.12 s); Lunge = low dash-thrust; Hobbling Javelin = overhand throw of a quiver javelin; Skewer = long two-hand thrust with a step |
| Sword and Shield | Arming sword 0.9 m (steel, brass guard) in ArmR; **round shield** r 0.4 (oak, iron rim, team-colour boss) in ArmL. **The Oathwall keeps his door-sized shield** and swaps his hammer for the sword | `sword_slash` (strike 0.12 s); Riposte = shield up, sword cocked (4 s hold); Second Wind = sword lowered, deep breath, shoulders rise; Shield Throw = flat throw, catch 0.6 s later (the Oathwall throws his door shield) |
| Two-Hand Sword | Greatsword: 1.6 m blade, 0.12 m wide, long grip, wide cross-guard; carried on the shoulder while walking | `great_cleave` overhead diagonal (strike 0.16 s); Cleave = wide horizontal sweep; Crushing Blow = two-hand downward chop; Whirlwind = 2 s spin |
| Wizard staff | 1.8 m gnarled staff with a floating crystal, glow `(0.6, 0.75, 1.0)` 1.5 (its one extra glow point) | `staff_bolt`; Arc Bolt = staff thrust; Slipstep = fade 0.1 s, reappear; Starfall = staff raised to the sky |
Per model (what the class hides, what stays, which archetype poses need a version with a class weapon):
| Model | Hidden when a class is chosen | Kept (identity props) | Archetype poses to redo |
|---|---|---|---|
| Wayfinder | Short bow | Wide hat, split coat, **lantern pole** | Signal Flare (flare pulled from the lantern and thrown up), Snare Line (hand throw), Trailblaze (weapon raised) |
| Oathwall | War hammer. Door shield: kept in ArmL for Sword and Shield and Spear; **on his back** for Two-Hand and Wizard, swung off for Shield Bash and Bulwark Stand | Flat helm, square build | Oath of Iron (class weapon raised); Shield Bash / Bulwark Stand from the back for Two-Hand and Wizard |
| Coin-Cutter | Two curved knives | Hood tail, **loot sack**, coin belt | Cutpurse lunge with each weapon (Marked for Coin coin flip and Smoke Pouch unchanged) |
| Mender | Censer staff | **Wicker backpack with jars**, apron | Soothing Circle (a jar thrown to the circle's centre instead of the censer swing); Mending Draught and Lifeline unchanged |
Hooks (kit `CharacterModel`): `set_weapon_class(class_id: StringName)` (default: no-op; `&""` = the archetype weapon),
`attack_style` follows the class; `play_cast(ability_id)` handles the 12 class ids (a generic kit pose when a model has
none) and the archetype ids with the class weapon. The weapon appears with a 0.3 s scale-in during `class_chosen`.

## 6. Brain and bot (ai: `ChampionBrain`, ch. 8)
| Part | Change |
|---|---|
| Stance | From `is_ranged()` (Wizard, or a ranged archetype before level 2): **back line** = today's Mender / Wayfinder rules. Melee classes: no "stay behind" rule; they close in through R4 |
| Target preference (R4) | The archetype rule first where there is one (Coin-Cutter: lowest HP %, workers first; Oathwall: the enemy hitting your building / wizard). Else by class: **Spear** enemy ranged units and casters first; **Sword and Shield** the enemy attacking an ally; **Two-Hand** the enemy with the most enemies within 2.5 m; **Wizard** the enemy attacking the most hurt ally; else the nearest |
| Mender default (R8) | Wizard class or before level 2: 4 m behind the army centre (today). Melee class: 1 m behind the centre and joins fights like the others |
| Wayfinder default | Unchanged (explore); "fears being chased by melee" unchanged whatever the class |
| Flee (R2) | `flee_pct + class delta` (section 3) |
| Power (ch. 8.2, also the bot's strength) | `150 + 50 x level + 20 x unlocked class skills + items / 5` (a level-5 champion with its class: +60) |
| Wish lists (ch. 4.4) | Unchanged (per archetype) |
| Enemy bot (ch. 10) | Hiring rules unchanged (its "crystals >= price + 150" reads the new prices). Its champions draw their class by the same rule; its B1-B4 flags (Guard, Hunt, Explore) nudge them the same way. No cheating, no re-roll |

## 7. UI: what must be shown (layout: ui-designer addendum to `ui-champions.md`, task 11.D2)
| Element | Content |
|---|---|
| Tavern window row | The 3 archetype abilities (as today), then `Chooses a class at level 2 · usually Sword and Shield` (the highest base weight); new prices `225 crystals · 75 essence · 2 pop` etc. Hired: `Hired · Level 3 · Sword and Shield · Guarding`; fallen: `Revive 150` with the new formula |
| Champion bar | A 16 x 16 class icon on the portrait's lower-right corner (none before level 2) |
| Inspect view | Title line `Garran Stoneward, the Oathwall · Sword and Shield` (`· no class yet` before level 2). **6 ability icons in two rows**: archetype row (3) and class row (3), with cooldowns; locked ones grey with `Level 4` / `Level 5`; before level 2 the class row shows three grey `?` with the tooltip `Chooses a class at level 2 · leans Sword and Shield (71 %)` (live weights, bounties included) |
| Tooltips | Class: `Sword and Shield · melee · +10 armor · 12 damage every 1.1 s`. Skills: ch. 9 format, e.g. `Riposte  (class, level 2)` / `22 s cooldown · 4 s` / `Melee attackers take 10 damage per hit.` |
| Messages / barks | Section 2.2 |
| Icons | 4 class icons + 12 class skill icons (task 11.V7); `flare_arrow` keeps its icon under the name Signal Flare |

## 8. Save
- `Champion.get_save_state()` gains `"class": "sword_shield"` (`""` before level 2) and `"bounty_leans": {"guard": 2}`
  (only needed before level 2); `apply_save_state` restores them (class applied without the VFX or message).
- Campaign companion (ch. 11, `campaign_state.gd`): `companion` gains `"class"`. The companion keeps its class when its
  level resets to 1; its class skills unlock again at levels 2 / 3 / 5. Old saves without the key: `""` (it draws at
  level 2 as usual). Campaign `version` stays 1 (an optional key).

## 9. Balance: paying for 6 abilities
### 9.1 What the additions are worth
Each ability is worth roughly +10 % of a champion's fight value. Today a champion has 2 abilities until level 4 and 3
after. With classes it has 3 at level 2, 4 at 3, 5 at 4, 6 at 5: **+1 at level 2, +2 at levels 3-4, +3 at levels 5-6**,
i.e. about +20 % at the levels seen in a normal game. The class weapon is about neutral (9.3). The compensation below
brings the champion's value **at a given match minute** back to today's +-10 %.
### 9.2 Compensation (all numbers; apply together)
| Knob | Old -> new | Effect |
|---|---|---|
| Champion XP table (`champion.gd` `LEVEL_TOTAL_XP`) | `[0, 150, 400, 750, 1200, 1750]` -> **`[0, 190, 500, 940, 1500, 2190]`** (x1.25, rounded to 10) | Each level ~25 % later: level 2 ~6:00 (was ~5:00), level 4 ~15-17 min (was 12-14). In a 9-11 min game a champion sits at level 2-3 with 3-4 abilities |
| Class weapons | Trimmed to Spear **13**, Sword and Shield **12** (no HP bonus), Two-Hand **24**, Wizard **11** damage (section 3) | Weapon DPS near today's archetype DPS (9.3) |
| Class skill cooldowns | Long on purpose: 10-45 s (table 4.2); level-1 amounts modest (25-45) | No class skill fires more than once per 10 s |
| Hire price (`ChampionGuild`, ch. 3.1) | 200+75 / 250+100 / 300+125 -> **225+75 / 275+100 / 325+125** crystals + essence | 75 more crystals for three champions: about one soldier less |
| Revive (ch. 3.3) | `60 + 30 x level` essence -> **`80 + 35 x level`** (L1 115, L4 220, L6 290); time unchanged `15 + 5 x level` s | Losing a class champion costs more |
| Upkeep | Unchanged (1 essence / 10 s) | The next knob if needed (9.5) |
| Champion kill XP / loot | Unchanged (`100 + 25 x level`, loot 25 %) | Wizard and soldier economies untouched |
### 9.3 Numbers at level 4 (growth x1.24, no items)
| Champion -> class | HP / armor | DPS (range) | vs today's level 4 | Abilities at L4 |
|---|---|---|---|---|
| Wayfinder (today 322 / 0, 14.6 at 8 m) -> **Spear** | 322 / 0 | 17.0 (2.4, +0.2 m/s) | +16 % DPS but melee | Flare, Snare, Trailblaze, Lunge, Hobbling Javelin |
| Wayfinder -> Wizard | 296 / 0 | 10.5 (7.5) | -28 % DPS, keeps range | Flare, Snare, Trailblaze, Arc Bolt, Slipstep |
| Oathwall (today 645 / 20, 14.3) -> **Sword and Shield** | 645 / 30 | 13.5 | EHP +8 %, DPS -6 % | Oath, Bash, Bulwark, Riposte, Second Wind |
| Oathwall -> Two-Hand | 645 / 20 | 19.2 | +34 % DPS | Oath, Bash, Bulwark, Cleave, Crushing Blow |
| Coin-Cutter (today 372 / 5, 23.4) -> **Two-Hand** | 372 / 5 | 19.2 + Cleave | -18 % single target, gains area | Cutpurse, Smoke, Marked, Cleave, Crushing Blow |
| Coin-Cutter -> Spear | 372 / 5 | 17.0 | -27 %, 5.8 m/s | Cutpurse, Smoke, Marked, Lunge, Hobbling Javelin |
| Mender (today 347 / 5, 8.0 at 7 m) -> **Wizard** | 319 / 5 | 10.5 (7.5) | +31 % DPS | Draught, Circle, Lifeline, Arc Bolt, Slipstep |
| Mender -> Sword and Shield | 347 / 15 | 13.5 melee | a front-line medic | Draught, Circle, Lifeline, Riposte, Second Wind |
But level 4 now comes ~3 min later: at **12:00** a typical champion is level 3 (4 abilities, class weapon) where today it
is level 3-4 (2-3 abilities). Net at a given minute: **+5-10 % before 10:00** (the class weapon and skill 1 at level 2),
**about equal after** (the archetype's third ability and class skill 3 arrive later), and each champion costs more.
### 9.4 Game length and fight checks
- No burst was added to armies; Sword and Shield / Wizard (the Oathwall and Mender leans) add sustain and escape, which
  lengthen fights; area damage is small and slow (Whirlwind 48 per enemy per 30 s, Starfall 45 per 35 s, Skewer 40 per
  25 s). Slower champion levels and dearer revives delay the champion snowball. Expected: games **not shorter**, likely
  +0:30; the 11.L2 runs check it.
- L3 Two-Hand Coin-Cutter vs 3 clumped Shades (110 HP, 11 dmg): Cleave hits all three for ~28, Crushing Blow on one, Smoke
  Pouch to escape: wins with ~40 % HP (today ~45 % at L3).
- L4 Sword and Shield Oathwall + a spire vs 5 Shades: Riposte returns ~200, Second Wind heals 129, Bash dazes, Oath taunts:
  holds ~25 s (today ~20 s).
- L5 Mender-Wizard: Draught + Circle + Lifeline (today's healing) + Slipstep: harder to catch, not a bigger healer.
### 9.5 Knobs (one at a time, 11.D3)
| Symptom | Knob |
|---|---|
| Games still shorter than the step-10 median | Upkeep 1 -> **2** essence / 10 s per champion; or class unlocks 2 / 3 / 5 -> 2 / 4 / 6 |
| Champions too weak (rarely hired, die a lot) | XP x1.25 -> x1.15; revive back to `60 + 30 x level` |
| One class dominates the logs | Its weapon damage -1 (Two-Hand 24 -> 22) or its level-2 skill cooldown +4 s |
| Wizard class useless in melee brawls | Slipstep cooldown 22 -> 18 |
| Bounty lean too strong / weak | +20 -> +15 / +25 per bounty |

## 10. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 11.L1)
- **ChampionClass** (`scripts/units/champion_class.gd`, Resource, `data/champion_classes/<id>.tres`, ids `spear`,
  `sword_shield`, `two_hand`, `wizard`): `id`, `display_name`, `attack_damage`, `attack_cooldown`, `attack_range`,
  `is_ranged: bool`, `projectile_color`, `projectile_speed`, `stats: Dictionary` (modifier `class:<id>`), `flee_delta`,
  `attack_style: StringName`, `ability_ids: Array[StringName]` (3, unlock order), `unlock_levels: Array[int]` ([2, 3, 5]),
  `bounty_kind: StringName` (explore / guard / hunt / escort), `icon_abbrev`, `tooltip`; `static find(id)`, `static all()`,
  `static weights_for(champion) -> Dictionary` (class id -> weight, section 2.1), `static pick(champion, rng) -> StringName`.
- **ChampionType** gains `class_weights: Dictionary` (class id -> base weight, the table of 2.1). `ability_ids` unchanged (3).
- **Champion** gains `champion_class: ChampionClass` (null before the choice), `class_id() -> StringName` (`&""` = none),
  `set_champion_class(id: StringName)` (weapon numbers, range, projectile, modifier, flee delta, model hook
  `set_weapon_class`; idempotent), `is_ranged() -> bool`, `bounty_leans: Dictionary` (kind -> count, from its team's
  `BountyBoard.bounty_paid` until the choice), signal `class_chosen(champion, class_id)`, save keys of section 8.
  `LEVEL_TOTAL_XP` = `[0, 190, 500, 940, 1500, 2190]`; `power()` of section 6. The draw happens in `add_xp` at level 2.
- **ChampionAbilities**: `ability_ids()` = the 3 archetype ids + the class's 3 (none before the choice); `is_unlocked(id)`:
  archetype per ch. 4.3, class per `unlock_levels`; `cast` reasons unchanged (`"Locked"` for a skill of another class or
  below its level). `ABILITIES` gains the 12 ids of 4.2; `AUTOCAST_ORDER` of 4.3. New modifier `ability:crush` on targets.
- **ChampionGuild**: hire costs 225+75 / 275+100 / 325+125; revive `80 + 35 x level` essence.
- **Model** (`CharacterModel` kit): `set_weapon_class(class_id)`, attack styles `spear_thrust`, `sword_slash`,
  `great_cleave`, `staff_bolt`, `play_cast` for the 12 class ids. **ChampionVfx.play** gains the 12 ids + `class_chosen`.
- **Campaign**: `companion.class` (optional). Keys: none new.

## 11. What changes in other specs (game-designer follow-up in 11.D3)
- `champions.md`: 1 (price and level rows), 3.1 prices, 3.3 revive, 4.3 (Signal Flare name; class skills here), 4.6
  (weapon swap), 5 (XP table, class unlocks), 8.2 power, 9 (tavern / inspect lines), 11 (companion class), 12 (balance
  rows), 13 (contracts above).
- `ui-champions.md`: addendum by 11.D2. `levels.md`, `spells.md`, `items.md`, the wizard: **unchanged**.

## 12. Task list (step 11)
**Phase 0:** 11.L1 lead, 11.D2 ui-designer. **Phase 1 (in parallel, no shared files):** 11.C1, 11.C2, 11.C3, 11.A1,
11.V1, 11.V6, 11.V7. **Phase 1b:** 11.V2-11.V5 (need the 11.V1 weapons), 11.C4 (needs 11.D2). **Phase 2:** 11.L2,
then 11.D3 after the playtest. Phase-1 tests stub the other parts in `tests/test_11_<id>.gd`. Existing step-9 champion
tests whose numbers change (XP table, prices, revive) are updated by the task that owns the file.
| Id | Agent | Task | Files |
|---|---|---|---|
| 11.L1 | lead | Freeze section 10 in `CLAUDE.md` (Champions line: prices, XP, class API), owner rows for `data/champion_classes/`, `art/units/champions/weapons/`; ids in `waves.md` | `CLAUDE.md`, `docs/plan/` |
| 11.D2 | ui-designer | Addendum: class icon on the bar, inspect title + 2 rows of 3 abilities, tavern lines, tooltips (section 7) | `docs/design/ui-champions.md` |
| 11.C1 | gameplay-coder-high [H] | `ChampionClass` + 4 `.tres`, the draw (weights, bounty leans, RNG), `set_champion_class`, XP table, `power()`, save keys, `class_chosen`, `ChampionType.class_weights` + the 4 `.tres` (weights, Signal Flare name, class bark) | `scripts/units/champion_class.gd`, `data/champion_classes/`, `scripts/units/champion.gd`, `champion_type.gd`, `data/champions/*.tres` |
| 11.C2 | gameplay-coder-high [H] | The 12 class skills, unlocks by class and level, `ability:crush`, the 24-id autocast order and triggers of 4.2-4.3 | `scripts/units/champion_abilities.gd` |
| 11.C3 | systems-coder | Hire and revive prices; companion `class` in the campaign save (write, read, old saves) | `scripts/world/champion_guild.gd`, `scripts/campaign/campaign_state.gd` |
| 11.A1 | ai-coder | Brain: stance, target preference, Mender melee default, flee delta (section 6) | `scripts/ai/champion_brain.gd` |
| 11.V1 | tech-artist | Weapon kit (spear + 3-javelin quiver, sword + round shield, greatsword, staff), `set_weapon_class`, the 4 attack styles, generic poses for the 12 class skills | `art/units/champions/weapons/`, `art/units/kit/character_model.gd` |
| 11.V2 | tech-artist | Wayfinder: hide the bow, grips for the 4 weapons, Signal Flare / Snare Line / Trailblaze poses with a class weapon, silhouette check | `art/units/champions/wayfinder/` |
| 11.V3 | tech-artist | Oathwall: hammer / door-shield rules (hand or back), sword with his own shield, Shield Throw with the door shield, Bash / Bulwark from the back, grips, check | `art/units/champions/oathwall/` |
| 11.V4 | tech-artist | Coin-Cutter: hide the knives, grips, Cutpurse with each weapon, check | `art/units/champions/coin_cutter/` |
| 11.V5 | tech-artist | Mender: hide the censer staff, grips, Soothing Circle jar throw, check | `art/units/champions/mender/` |
| 11.V6 | tech-artist (VFX) | 12 class skill effects: Lunge streak, javelin + hobble dust, Skewer line flash, Riposte shimmer + counter sparks, Second Wind rising wisps, Shield Throw arc + bounce sparks, Cleave arc, Crushing Blow crack + armor-break shards, Whirlwind ring, Arc Bolt + hit, Slipstep fade / reappear, Starfall ring + impact; plus the `class_chosen` ring | `art/vfx/champion_vfx.gd`, `art/vfx/champion_class_*` |
| 11.V7 | tech-artist | Icons: 4 classes + 12 class skills, champion icon pipeline | `art/icons/champion_icon_painter.gd`, `render_champion_icons.gd`, `art/icons/champions/` |
| 11.C4 | ui-coder | Tavern lines and prices, bar class icon, inspect title + 6 abilities + lean tooltip, class message | `scripts/ui/tavern_window.gd`, `champion_bar.gd`, `selection_panel.gd` |
| 11.L2 | lead | Integration, smoke / perf, bot-vs-bot runs (the `balance-2.md` harness) logging class picks, champion levels at 5 / 10 / 15 min, casts per ability, champion deaths and revives, match length | `tests/`, `docs/plan/` |
| 11.D3 | game-designer | Balance from the 11.L2 logs and the playtest (knobs of 9.5), `champions.md` updates of section 11 | `docs/design/` |

## Done when
- [ ] 11.L1: section 10 is in `CLAUDE.md`; owner rows; ids in `waves.md`.
- [ ] 11.D2: the `ui-champions.md` addendum gives positions / sizes / looks at 1600 x 900 for every row of section 7.
- [ ] 11.C1: 4 `ChampionClass` files with the numbers of section 3; a champion reaches level 2 at 190 XP and level 6 at 2 190; at level 2 it emits `class_chosen` exactly once and never draws again (death, revive, levels 3-6); 10 000 draws for an Oathwall with no bounties give Sword and Shield 58-62 %, with 2 Guard bounties 69-73 %, and a third Guard bounty adds nothing (cap +40); a Coin-Cutter that takes Two-Hand at level 2 has 25.92 damage, cooldown 1.55, range 2.1; an Oathwall Sword and Shield at level 2 has 561.6 HP and armor 30; a Wizard has range 7.5, shoots bolts and has 10 % less HP; `power()` of a level-5 champion with a class = 150 + 250 + 60; save / load keeps the class and the leans; a dismissed and re-hired archetype has no class.
- [ ] 11.C2: each class skill in a test with its level-1 and level-5 numbers and its trigger (Lunge moves next to a Nightbolt 5 m away, 25 damage, dazed 0.5 s, 0.25 s on a hero; Hobbling Javelin 25 + smoulder 3 s at 10 m; Skewer hits 3 Shades in a 5 m line for 40 each and not a 4th 1.5 m off the line; Riposte returns 10 per melee hit for 4 s and nothing for a ranged hit; Second Wind heals 20 % of max HP over 4 s; Shield Throw 30 / 20 / 10 over 3 targets; Cleave hits 2 other Shades within 2.5 m for the full attack damage; Crushing Blow 30 and -20 armor for 6 s (a Rimeshield then takes 105 from a 100 hit), damage only on a building; Whirlwind 48 over 2 s to each enemy within 3 m; Arc Bolt 40 at 12 m; Slipstep moves 8 m away from a melee attacker; Starfall 45 in r 3.5 after 1.0 s); a Spear Wayfinder at level 5 owns exactly Flare, Snare, Trailblaze, Lunge, Hobbling Javelin, Skewer; a class skill of another class or below its level returns `"Locked"`; one cast per 0.5 s check in the order of 4.3; `PERF OK` with 6 champions and 200 units.
- [ ] 11.C3: hire costs 225+75 / 275+100 / 325+125; revive `80 + 35 x level` essence (level 4 = 220) after `15 + 5 x level` s; a companion saved with a class starts the next mission with it at level 1 (class skills locked until 2 / 3 / 5); an old save without `class` loads and the companion draws at level 2.
- [ ] 11.A1: a headless scene proves each row of section 6 (a melee Mender fights 1 m behind the army centre, a Wizard Mender stays 4 m behind; a Spear Wayfinder picks a Nightbolt over a Shade at equal distance; a Two-Hand picks the target with the most neighbours; a Sword and Shield Oathwall flees at 15 %); decisions use only the team's fog; `PERF OK`.
- [ ] 11.V1-11.V5: each model shows the 4 weapons (and its archetype weapon with `&""`), attack styles, class poses and the redone archetype poses play, budgets held, the class reads from 40 m in a contact sheet `docs/art/screens/champion_classes.png` (16 combos), headless instantiation without errors.
- [ ] 11.V6-11.V7: every new id plays once and stops (pre-built emitters); 16 icons readable at 36 px.
- [ ] 11.C4: tavern, bar and inspect show the class content of section 7 with the new prices; the lean tooltip shows the live weights; the class message; nothing in `scripts/ui/` calls a `_private` function.
- [ ] 11.L2: bot-vs-bot runs keep the median match length **at or above the step-10 value** (no shorter games); every champion that reaches level 2 has a class; champions average level 2-3 at 10:00; CI green.
- [ ] 11.D3: balance notes and knob changes written here from the 11.L2 logs and the playtest; `champions.md` updated.

## Appendix: ideas for the future game (not for Four Wizards; no work planned)
A Silkroad-inspired character system drafted before the re-target, kept as notes:
- **Levels 1-110** earned inside a session on a fast curve (`xp_to_next = 10 + floor(3 x L / 5)`: 80 at ~2 650 XP, 110 at
  ~4 650), caps raised over time (80 -> 90 -> 100 -> 110) by story chapters.
- **SP**: 3 per level; one currency for masteries (1 SP per level, each mastery <= character level) and skill ranks
  (rank r costs r SP). **Total mastery limit** `min(2 x level + 20, 240)`: two masteries maxed + 20 at the cap.
- **Masteries**: weapon (the future game's classes: Spear, Sword and Shield, Two-Hand Sword, Wizard), elements, defence,
  command. Per mastery level a small passive; skills unlocked at mastery thresholds.
- **Skill tiers** (the user's idea): each skill has levels 1 (weak) to 8 (strong); a higher tier of the same skill then
  starts again at level 1 with bigger base numbers, unlocked at a mastery threshold.
- **Skill kinds**: actives, toggled imbues (mana per hit), passives, a capstone per mastery; a 6-slot bar.
- **Builds**: saved presets with an auto-spend "follow build" rule, free respec between sessions, paid respec in a session.
