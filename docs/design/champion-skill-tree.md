# Champion skill tree: class at hire, levels 1-9, a pick at every level, ranks I-III

Task 11b.D1, written 2026-09-26, **revised the same day with the user's answers** (section 0). Source of truth for
step 11b (tasks in section 15).
User request: **more skills for every level**: champions (the 4 classes Spear, Sword and Shield, Two-Hand Sword, Wizard)
get **a new choice at every level from 1 to 9**, and **every skill can be raised to rank III (+3 max)**. The champion
chooses by itself (autonomous, by personality and class); the player sees the choices in the inspect view. **The
player's wizard is unchanged** (F / Q / E, levels 1-8).
Builds on `skills-rework.md` (step 11, built: quoted "sr. 4.2" etc.), `champions.md` ("ch."), `cavalry-mounts.md`
(titans, Roan Courser, damage kinds), `rush-balance.md` (rushes land 3:00-3:30), `research.md` (champions take no
research), `balance-2.md`, and the code `scripts/units/champion.gd`, `champion_class.gd`, `champion_abilities.gd`,
`scripts/ai/champion_brain.gd`, `scripts/world/champion_guild.gd`, `scripts/ui/*`. Every name, skill and number here is
our own. Metres, seconds, `m:ss` since the navmesh was ready.

## 0. Decisions for the user (answered 2026-09-26)
| # | Question | User's answer |
|---|---|---|
| Q1 | When is the class chosen (the level-1 point needs a class)? | **At hire**, weighted by the archetype only (bounties no longer lean the class). The level-1 point is spent at once. This changes step 11 (built): section 3 lists every code, test and UI change. Designer's call on the tavern: **the class is shown before hiring** (3.2) |
| Q2 | How free is the pick? | **A draft of 3 offers; it takes its favourite** (section 6) |
| Q3 | Pace | **Level 9 at 15-20 min**, and unique NPCs (champions, and later the step-13b Shadow Mage Archer) **level fast early**: the first levels within a few minutes of the hire, relevant against the 3:00-3:30 rushes (section 2) |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Class | **Drawn when the team's guild is created** (match start), one per archetype, from `ChampionType.class_weights` only; **shown in the tavern before hiring**; applied at hire; a dismissed archetype draws a new class for its next hire | The player knows what he buys; one class per hero, never re-rolled |
| Levels | **1-9**, fast early: level 2 ~0:30 after the hire, level 4 ~2:15, level 9 ~14:30 after the hire (**~17:30 for a 3:00 hire**) | Q3 |
| XP | New table (2.1) + **field drill: +1 XP per second** while alive (unique NPCs only) on top of the step-9 sources | Early levels even for a champion that scouts or guards; predictable timing |
| Growth | **+2 % per level** (was +8 %, then 4 %): level 9 = x1.16 | Nine fast levels must not mean nine big stat jumps: the power comes from the picks |
| Points | **1 skill point per level, 9 in all**, spent at once; the level-1 point at hire | Every level-up is a visible decision |
| Tree | Per class **9 skills**: the 3 step-11 class skills + 3 passives + 1 new active + 2 signatures. Tiers T1 (level 1), T2 (3), T3 (5), **Signature (7)** | "~8-10 skills per class" |
| Ranks | **I, II, III** for every tree skill. **Rank I is a taste (~75 % of the step-11 number), rank II = the step-11 number, rank III = ~125 % + an extra**. A rank needs the one before and a level gate (4.3) | "+3 max"; early picks come fast, so each one must be small; the power is in the ranks |
| Prerequisites | T3 skills need one of two parents; one signature only | Paths read as builds |
| Milestones | **Level 7 = the signature pick** (the only 2 offers); at levels 8 and 9 the next signature rank is always offered; **rank III has a capstone effect** | Signature ranks I / II / III at 7 / 8 / 9 |
| Archetype abilities | Outside the tree, unranked; the third one now unlocks at **level 6** (~8:40 for a 3:00 hire) | Keeps it near its old minute relative to the new curve |
| Who picks | The champion: score = weight x archetype taste x situation x rank factors; a seeded draft of 3; takes the best | Q2 |
| Your lever | Bounties: skills matching the kind of bounties paid to it lately score x1.25 | The bounty lean moves from the class to the skills |
| Cast budget | One cast per 0.5 s check + a **1.0 s global cooldown** (escapes and saves exempt) + a **team signature spacing of 2 s** | Up to 8 actives |
| Paying for it | Growth 2 %, rank I at 75 %, signatures weaker than the first draft, archetype ability 3 at level 6, revive / victim XP / `power()` refitted per minute (2.2). Champions are **stronger early** (by design, vs rushes), **about equal mid-game**, **weaker after ~17 min** (capped at level 9) | Games must not get shorter (15-20 min) |
| Permanent | Picks kept through death and revive; dismiss = start over; the campaign companion keeps its class and replays its skill path (9) | As step 11 |

## 2. Levels 1-9 (fast early; the shared "unique NPC" curve)
### 2.1 XP table, drill and growth (`Champion.LEVEL_TOTAL_XP`, `MAX_LEVEL = 9`)
| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 (max) |
|---|---|---|---|---|---|---|---|---|---|
| Total XP | 0 | **60** | **150** | **270** | **450** | **710** | **1 060** | **1 500** | **2 050** |
| XP bar (`xp_to_next`) | 60 | 90 | 120 | 180 | 260 | 350 | 440 | 550 | 0 (`MAX`) |
| HP / damage / ability amounts x | 1.00 | 1.02 | 1.04 | 1.06 | 1.08 | 1.10 | 1.12 | 1.14 | 1.16 |
| Time after the hire (median) | 0:00 | ~0:30 | ~1:15 | ~2:15 | ~3:40 | ~5:40 | ~8:10 | ~11:00 | ~14:20 |
| Game time, hired at 3:00 | 3:00 | 3:30 | 4:15 | 5:15 | 6:40 | 8:40 | 11:10 | 14:00 | **17:20** |
| What opens | class + pick (T1) | pick (T1) | T2, T1 rank II | pick | T3, T1 rank III, T2 rank II | **archetype ability 3** | **Signature** (1 of 2), T2 rank III, T3 rank II | Signature rank II | T3 rank III, **Signature rank III** |
- **Field drill** (`Champion.DRILL_XP_PER_SECOND = 1.0`): +1 XP per second while alive (not fallen or reviving), before
  any other source. 60 XP / min is about half of the early income; it guarantees level 2 within ~1 min and level 4 within
  ~4 min of the hire even for a Wayfinder that only scouts.
- Other sources unchanged (ch. 5: killing blow 100 %, team kill within 12 m 25 %, half of each bounty paid).
- Income model used for the times: `115 t + 2 t^2` XP after `t` minutes alive (drill 60 t + fights / bounties `55 t + 2 t^2`,
  from sr. 9.2). Deaths pause the drill: a champion that dies twice reaches level 9 ~1:30 later. Hire at 2:00 (the
  earliest) -> level 3 at 3:15, level 9 ~16:20; hire at 5:00 -> level 9 ~19:20. **Level 9 lands at 15-20 min.**
- **Fitting rule** (11b.L2 logs): scale the table by one factor so that the median level-9 time is 17:00-18:30; the drill
  is the second knob (10.5).
- **Unique NPC curve**: this table + drill is the shared curve for unique autonomous NPCs; the step-13b Shadow Mage
  Archer spec should reuse `LEVEL_TOTAL_XP` and the drill (its own skills are its spec's business).
- A champion gaining several levels at once resolves them in order, one pick per level with that level's gates.

### 2.2 Level-driven numbers refitted by minute (so a level is worth what the old level was at the same minute)
| Rule | Step 11 | Step 11b | Check (same minute) |
|---|---|---|---|
| Victim XP value of a champion (`wizard.gd xp_value_of`) | `100 + 25 x level` | **`110 + 10 x level`** (L1 120, L6 170, L9 200) | 15:00: old L4 200, new L8 190 |
| Revive cost (`ChampionGuild`) | `80 + 35 x level` essence | **`100 + 15 x level`** (L1 115, L6 190, L9 235) | 15:00: old 220, new 220 |
| Revive time | `15 + 5 x level` s | **`20 + 2 x level`** s (L1 22, L9 38) | 15:00: old 35 s, new 36 s |
| `power()` (brain danger, bot strength) | `150 + 50 x level + 20 x class skills + items / 5` | **`170 + 20 x level + 10 x skill ranks + items / 5`** (L1 with 1 rank 200, L6 350, L9 440) | Follows the value index of 10.1 |
| Roan Courser (`cavalry-mounts.md` 6.3) | level 3 (~10:10) | **level 7** (~11:10) | A mid-game purchase |
| Archetype ability 3 | level 4 | **level 6** (~8:40) | |
| Hire prices, upkeep | 225+75 / 275+100 / 325+125, 1 / 10 s | unchanged | |

## 3. The class at hire (changes step 11)
### 3.1 Rules
- Each team's `ChampionGuild` draws **one class per archetype** when it is created (match start), with its own
  `class_rng` (randomized; tests seed it): `ChampionClass.pick_for_type(type, rng)` with the base weights of sr. 2.1
  (Oathwall: Spear 15, Sword and Shield **60**, Two-Hand 20, Wizard 5). No bounty leans any more.
- `hire(id)` builds the champion with that class (applied before it enters the tree, weapon and modifier included),
  then, once it is in the tree, announces it: `class_chosen` (VFX ring at the tavern door, the class bark), then the
  level-1 pick (`skill_learned`). One message line: `Garran Stoneward joins you · Sword and Shield · learns Riposte I`.
- `dismiss(ch)` draws a new class for that archetype (the next one hired is a new champion). Death and revive keep it.
- The campaign companion keeps its saved class (no draw). A save without a class (step-9 saves) draws it quietly on load.
- The bot's guild draws the same way; the bot's hire order is unchanged (it does not shop for classes).
### 3.2 Tavern: shown before hiring (designer's decision)
The tavern row shows the class the champion **will** have: class glyph + `Sword and Shield` + the class tooltip (sr. 7)
and its tree (hover, 11b.D2), plus the price. **Why shown, not revealed on hire:** the player cannot order champions, so
knowing what he pays 225-325 crystals for is the one informed choice he gets (a Spear Wayfinder vs a Wizard Wayfinder is
a different purchase); a surprise would feel random, and there is no re-roll to abuse (dismissing costs the champion,
its levels and a new hire price). The enemy tavern rows are never shown (each team sees only its own guild); an enemy
champion's class is seen when it is visible. Alternative (one line in `tavern_window.gd`): show `Class: ?` until hired.
### 3.3 Exact changes to the built step-11 code and tests (who does what: section 15)
| File (owner, task) | Change |
|---|---|
| `scripts/units/champion.gd` (gameplay, 11b.C1) | `add_xp` no longer draws (remove `CLASS_DRAW_LEVEL` use and the `_draw_class(true)` call); remove `bounty_leans`, `_lean_bounties`, `_bounty_board`, `_connect_bounty_board()`, `_disconnect_bounty_board()`, `_on_bounty_paid()`, the reconnect in `_physics_process` and the disconnect in `set_champion_class`; `get_save_state` stops writing `bounty_leans` (`apply_save_state` ignores the key); `apply_save_state` draws quietly at **any** level when the class is missing; add `announce_class()` public (the guild calls it after `add_child`); `class_chosen` doc: "emitted once, at hire". `is_ranged()` keeps its no-class fallback (tests, tools) |
| `scripts/units/champion_class.gd` (gameplay, 11b.C1) | `weights_for(champion)` / `weights_from(type, leans)` return the base weights only (the `leans` argument is accepted and ignored for old callers); remove `BOUNTY_LEAN_WEIGHT`, `BOUNTY_LEAN_CAP` from the draw; add `static pick_for_type(type: Resource, rng: RandomNumberGenerator = null) -> StringName` and `chances_for_type(type) -> Dictionary`. `bounty_kind` stays (the skill picker uses the bounty kind names) |
| `scripts/world/champion_guild.gd` (systems, 11b.C5) | `class_rng`; `offered_class(archetype_id) -> StringName` (drawn at `_ready` for the 4 archetypes, redrawn on dismiss); `hire()` calls `set_champion_class(offered)` before `add_child`, `announce_class()` after; save / load of `offered` classes where the guild saves; revive `100 + 15 x level` after `20 + 2 x level` s |
| `scripts/world/bounty_board.gd` (systems, 11b.C5) | Only the stale comment at line 528 ("counts it as a class lean"); no behaviour change |
| `scripts/ai/champion_brain.gd` (ai, 11b.A1) | Branches "ranged archetype before its class" become fallbacks only (no change needed); the Mender default reads the class; the doc comments say "class from hire" |
| `scripts/ui/champion_bar.gd`, `selection_panel.gd`, `tavern_window.gd` (ui, 11b.C6) | Remove the lean math and texts (`LEAN_WEIGHT`, `LEAN_CAP`, `class_weights_for` bounty part, `lean_tooltip`, `lean_text` use, `BOUNTY_HINT`), the `· no class yet` title, the `Class at level 2` caption, the three `?` slots and their `L2` badges, `Autocast · next at level 2`; tavern line 4 = the offered class (glyph + name + tooltip) for unhired rows; the bar class badge from the hire. (The tree UI of section 8 replaces the class row anyway) |
| `art/vfx/champion_vfx.gd` (tech-artist) | Nothing: `class_chosen` still plays (at the tavern door) |
| Tests | `tests/test_11_c1.gd`: replace the level-2 draw, the lean draws (69-73 %, cap +40), `class_chosen` at level 2, the lean save keys by: the class applied at hire, `class_chosen` once at hire, 10 000 `pick_for_type` draws for an Oathwall give Sword and Shield 58-62 % with or without paid bounties, no `bounty_leans` in the save, an old save without a class draws quietly. `tests/test_11_c3.gd`: "a hired champion has no class" -> it has its guild's offered class; the companion keeps its class; the old save draws on load. `tests/test_11_c4.gd`: lean tooltips, `?` slots, `no class yet`, `Class · leans (71 %)` -> the offered class line and badge from the hire. `tests/test_11_a1.gd`: drop or re-seed the "before level 2" stance cases. `tests/test_11_c2.gd`: unlocks 2 / 3 / 5 -> tree ranks (11b.C2). `tests/test_9_c1.gd`, `test_9_c2.gd`, `test_9_c3.gd`: XP table, growth, revive numbers. Each task updates the tests of the files it owns |
| Specs | `skills-rework.md` 2 (draw at hire, no leans), 7 (UI), 8 (save); `ui-champions.md` 15.x (11b.D2); `CLAUDE.md` Champion classes line (11b.L1) |

## 4. Tree rules
### 4.1 Shape (tree order = the order below; used for ties and the UI)
| Tier | Opens at | Skills |
|---|---|---|
| T1 | level 1 | 3: the class's first step-11 skill + 2 new passives |
| T2 | level 3 | 2: the step-11 second skill + 1 new |
| T3 | level 5 | 2: the step-11 third skill + 1 new; **each needs one of its 2 parents** (any rank) |
| Signature | level 7 | 2 new ultimates; **only one per champion**; rank III adds a capstone |
### 4.2 Points
+1 point at hire (level 1) and at each level-up; always spent at once. 9 points for 27 ranks (24 reachable): a level-9
champion typically owns 5-6 skills, 2-3 of them at rank II-III.
### 4.3 Rank gates (minimum champion level)
| Tier | Rank I | Rank II | Rank III |
|---|---|---|---|
| T1 | 1 | 3 | 5 |
| T2 | 3 | 5 | 7 |
| T3 | 5 | 7 | 9 |
| Signature | 7 | 8 | 9 |
Rank n needs rank n-1. At levels 1 and 2 the two picks are two different T1 skills at rank I. At least 2 moves are
eligible at every level (fuzz-tested in 11b.C1).
### 4.4 `learn` refusal reasons (in order)
`"No class"`, `"No points"`, `"Not in tree"`, `"Max rank"`, `"Needs level n"`, `"Needs Lunge or Long Reach"` (the two
parents), `"Signature taken"`. A **move** = (skill, its next rank) with `learn` = `""`.

## 5. The four trees
Conventions: rank I / II / III. Flat damage, heals and shields grow x `(1 + 0.02 x (level - 1))` x `(1 + spell_power /
100)` (spell power cap 60, CDR cap 40 %, unchanged); percentages, armor changes, flat blocks and durations do not grow.
Crowd control lasts half on heroes and titans, and x `(1 - tenacity / 100)` (new stat, 13). **Ground areas never hit the
flying Cinder Dragon**; targeted projectiles and bolts can. All ability damage is kind `&"spell"`, attacker = the
champion. **Rule kept from sr. 4.2**: no tree skill repeats an archetype effect (no taunt, `rooted`, `haste`, `braced`,
`marked`, smoke, shield or heal on others). Statuses used: `dazed`, `smoulder`, new `steadfast` (13). "A" active, "P"
passive, "S" signature; tags in brackets (6.2); "max n" areas hit the n nearest. The step-11 skills keep their triggers.

### 5.1 Spear (reach, pursuit, anti-ranged; keeps the step-13 anti-mount +50 %)
| Tier | id | Name | Kind [tags] | Cooldown | Rank I | Rank II | Rank III | Autocast when / hook |
|---|---|---|---|---|---|---|---|---|
| T1 | `lunge` | Lunge | A [hunt, mobility] | 14 / 13 / 12 | Dash (6 m) + **19** + `dazed` 0.4 s | **25**, dazed 0.5 s | **31**, dazed 0.6 s, 7 m, its next attack ready at once | sr. 4.2 |
| T1 | `long_reach` | Long Reach | P [hunt, burst] | | `attack_range` **+0.2** m; **+6 %** damage to ranged units, casters, wizards, ranged champions | +0.4 m, +10 % | +0.6 m (3.0, still melee), +14 % | modifier `skill:long_reach` + outgoing filter |
| T1 | `sure_footing` | Sure Footing | P [mobility, sustain] | | `move_speed` **+0.15**, `tenacity` **+10** | +0.3, +20 | +0.45, +30 | modifier |
| T2 | `hobbling_javelin` | Hobbling Javelin | A [control, hunt] | 16 / 15 / 14 | Javelin (10 m): **19** + `smoulder` 2.5 s | **25** + 3 s | **31** + 3.5 s, 11 m, pierces to 1 more enemy unit within 3 m behind (50 % + smoulder) | sr. 4.2 |
| T2 | `harrier` | Harrier | P [hunt, control] | | **+8 %** damage to units under `smoulder`, `dazed`, `rooted`, `chill` or `frozen` | +13 % | +18 % | outgoing filter |
| T3 | `skewer` | Skewer (needs Lunge or Long Reach) | A [area, burst] | 25 / 23 / 21 | Line 5 x 1 m: **30** to each enemy unit | **40** | **50**, 6 m | 3+ enemy units in the line; III: 2+ if one is a hero or titan |
| T3 | `pole_vault` | Pole Vault (needs Sure Footing or Hobbling Javelin) | A [mobility] | 20 / 17 / 14 | Vaults up to **6 m** (explored navmesh point, walkable straight line, never over a wall); lands **15** to enemy units within 2 m | 7 m, **20** | 8 m, **25** | Fleeing and a melee enemy within 4 m targets it (vaults toward its rest spot); or its fight / Hunt target is 5-8 m away and moving away; never lands within 11 m of a known enemy tower / keep |
| S | `skyfall_javelin` | Skyfall Javelin | S [burst, area] | 60 / 52 / 45 | Point within 14 m, lands **1.2 s** later (ring shown to both teams): **75** within 1.2 m, **35** within 3 m (max 8), all `dazed` 0.5 s | **100** / **45** | **125** / **55**. **Capstone:** the javelin stands 5 s; enemy units within 3 m get `smoulder` (refreshed) | An enemy hero, titan or unit costing >= 200 within 14 m; or 4+ enemy units within 3 m of one of them |
| S | `hunters_oath` | Hunter's Oath | S [hunt, burst] | 50 / 45 / 40 | Swears on one enemy within 12 m for **10 s**: its damage to it **+20 %**, `move_speed` +1.0 while moving toward it; a red line shows the pair to both teams | 12 s, +28 % | 14 s, +36 %. **Capstone:** if the target dies during the oath, Lunge, Hobbling Javelin and Pole Vault are ready at once and it heals 10 % max HP | An enemy hero or titan within 12 m; or its Hunt bounty target within 12 m; or, fighting, a unit costing >= 200 |

### 5.2 Sword and Shield (guard, sustain, counter-play)
| Tier | id | Name | Kind [tags] | Cooldown | Rank I | Rank II | Rank III | Autocast when / hook |
|---|---|---|---|---|---|---|---|---|
| T1 | `riposte` | Riposte | A [guard, sustain] | 22 / 20 / 18 | **3 s**: each melee hit it takes returns **8** | 4 s, **10** | 5 s, **13**; ranged attackers within 8 m take half | sr. 4.2 |
| T1 | `hold_fast` | Hold Fast | P [guard, sustain] | | `armor` **+3**, `tenacity` **+10** | +6, +20 | +9, +30 | modifier |
| T1 | `shield_block` | Shield Block | P [guard] | | Unit projectiles and tower shots on it deal **-4** (before armor, min 1) | -7 | -10 | pre-armor filter |
| T2 | `second_wind` | Second Wind | A [sustain] | 45 / 40 / 35 | Heals itself **15 %** max HP over 4 s | **20 %** | **25 %** | sr. 4.2 |
| T2 | `war_cry` | War Cry | A [support, area] | 30 / 27 / 24 | Own non-worker units (wizard, champions) within **6 m**: `attack_damage` **+8 %** for 6 s (`ability:war_cry`, refreshed, no stacking) | 7 m, +12 % | 8 m, +16 % | Fighting, 4+ own units and 3+ visible enemy units within 8 m |
| T3 | `shield_throw` | Shield Throw (needs Riposte or Shield Block) | A [hunt, control] | 20 / 18 / 16 | **23 / 15 / 8** over 3 enemy units (bounces within 4 m) | **30 / 20 / 10** | **38 / 25 / 13**, each hit `dazed` 0.3 s | sr. 4.2 |
| T3 | `last_stand` | Last Stand (needs Hold Fast or Second Wind) | P [sustain, guard] | recharge 120 / 100 / 80 | A hit that would kill it leaves it at **1 HP**; then damage taken **-50 %** for 3 s | 100 s | 80 s; also heals 10 % max HP when it triggers | post-armor filter; a small shield mark on the bar while ready |
| S | `shield_rush` | Shield Rush | S [control, area] | 40 / 35 / 30 | Rushes up to **8 m** (1.5 m wide, navmesh): each enemy unit in the path **35** + `dazed` 0.8 s (max 6); stops at the first titan (dazes it) or building | **45** | 10 m, **60**, dazed 1.2 s. **Capstone:** if it owns Riposte, Riposte starts for free at the end | 3+ enemy units in the 8 m path; or an enemy attacking its Guard / Escort target or the wizard is 4-8 m away with 1+ other enemy in the path |
| S | `unbreakable` | Unbreakable | S [guard, sustain] | 60 / 55 / 50 | **6 s**: damage taken **-30 %**, status `steadfast` (no `dazed`, `frozen`, `rooted`, `chill`, `smoulder`, `taunted`; current ones end) | 7 s, -35 % | 8 s, -40 %. **Capstone:** melee attackers take **8** per hit while it lasts | HP < 60 % and 3+ enemies target it; or a titan targets it |

### 5.3 Two-Hand Sword (burst, cleave, titan-breaker)
| Tier | id | Name | Kind [tags] | Cooldown | Rank I | Rank II | Rank III | Autocast when / hook |
|---|---|---|---|---|---|---|---|---|
| T1 | `cleave` | Cleave | A [area] | 10 / 9 / 8 | Next attack (3 s) also hits every other enemy unit within **2.5 m** of the target for **75 %** | 100 % | 100 %, r 3.0 | sr. 4.2 |
| T1 | `giant_slayer` | Giant Slayer | P [burst, hunt] | | **+8 %** damage to heroes, titans, units with max HP >= 400 | +14 % | +20 % | outgoing filter |
| T1 | `battle_fury` | Battle Fury | P [burst] | | Each attack that lands: a stack of **+3 %** attack speed (`attack_cooldown_pct` -0.03), max **3**, all dropped 4 s after its last hit | max 4 | max 5 | `attack_landed`, modifier `skill:battle_fury` |
| T2 | `crushing_blow` | Crushing Blow | A [burst, control] | 20 / 18 / 16 | **23**; a unit loses **15** armor for 6 s (`ability:crush`) | **30**, -20 | **38**, -25 for 8 s | sr. 4.2 |
| T2 | `leap_strike` | Leap Strike | A [mobility, area] | 18 / 16 / 14 | Leaps to a point **4-7 m** away (walkable line): **23** to enemy units within 2.5 m + `dazed` 0.4 s | **30**, 0.5 s | **38**, 0.5 s | Fighting and its target is 4-7 m away (not a building); or 3+ enemy units within 2.5 m of a point 4-7 m away; never within 11 m of a known enemy tower / keep |
| T3 | `whirlwind` | Whirlwind (needs Cleave or Battle Fury) | A [area] | 30 / 27 / 24 | 2 s spin: **9** every 0.5 s to enemy units within 3 m (36) | **12** (48) | 2.5 s, **15** (75) | sr. 4.2 |
| T3 | `blood_price` | Blood Price (needs Giant Slayer or Crushing Blow) | P [sustain] | | Heals itself **6 %** of the damage it deals (after armor) | 9 % | 12 % | `attack_landed` + `skill_hit` |
| S | `earthsplitter` | Earthsplitter | S [area, control] | 45 / 40 / 35 | 1.0 s windup (line shown to both teams), crack **8 x 2 m**: **60** to enemy units (max 6), 40 % to buildings, `dazed` 0.8 s | **75** | **90**. **Capstone:** the crack stays 4 s, enemy units on it get `smoulder` | 4+ enemy units in the line; or a titan / hero in it with 2+ other enemy units |
| S | `titanbreaker` | Titanbreaker | S [burst, hunt] | 40 / 36 / 32 | Next **3 attacks** within 6 s: **+50 %**, each removes **6** armor from a unit for 8 s (stacks to 3; **x2 on titans**) | +65 %, 7 | +80 %, 8. **Capstone:** the third hit `dazed` 0.6 s | Its target is a titan or hero, or has armor >= 20 or max HP >= 600 |

### 5.4 Wizard (bolts, control, escape)
| Tier | id | Name | Kind [tags] | Cooldown | Rank I | Rank II | Rank III | Autocast when / hook |
|---|---|---|---|---|---|---|---|---|
| T1 | `arc_bolt` | Arc Bolt | A [burst, hunt] | 10 / 9 / 8 | Bolt (12 m): **30** | **40** | **50**, 13 m, bounces once to another enemy unit within 5 m (50 %) | sr. 4.2 |
| T1 | `focus` | Focus | P [burst, support] | | `spell_power` **+5** (all its abilities, archetype heals too) | +8 | +12 | modifier |
| T1 | `ward` | Ward | P [sustain, guard] | | A **25** shield on itself (`add_shield`), back **20 s** after it breaks | **35**, 16 s | **50**, 12 s | self shield |
| T2 | `slipstep` | Slipstep | A [mobility, sustain] | 22 / 19 / 16 | Teleport up to **7 m** away from the nearest melee enemy | 8 m | 10 m; next bolt within 3 s +50 % | sr. 4.2 |
| T2 | `kindled_staff` | Kindled Staff | P [area] | | Every **4th** auto-attack bolt that lands jumps to a second enemy unit within 5 m for **40 %** | every 3rd, 50 % | every 3rd, 70 % | `attack_landed` |
| T3 | `starfall` | Starfall (needs Arc Bolt or Kindled Staff) | A [area] | 35 / 32 / 29 | Star lands 1.0 s after the cast: **34** in r 3.5 | **45** | **56**, r 4.0 | sr. 4.2 |
| T3 | `gravity_well` | Gravity Well (needs Ward or Slipstep) | A [control, support] | 28 / 25 / 22 | A well within 10 m, r 3.5, **3 s**: enemy units inside get `smoulder` (refreshed) and **5** every 0.5 s (30); at the end `dazed` 0.4 s | **7** (42), 0.5 s | **10** (60), 0.6 s | 3+ enemy units within 3.5 m of one of them in range; or 2+ enemy melee units within 3 m of an own hero within 10 m |
| S | `comet_rain` | Comet Rain | S [area] | 55 / 50 / 45 | A point within 14 m, r 5 (ring shown to both teams): **5 comets** over 2.5 s at seeded spots, each **20** in r 1.8 (buildings 25 %) | 6 comets, **25** | 7 comets, **30**. **Capstone:** a last comet at the centre, **50** in r 3 + `dazed` 0.5 s | 4+ enemy units within 5 m of a point in range |
| S | `astral_form` | Astral Form | S [burst, mobility] | 60 / 55 / 50 | **8 s**: bolt and Arc Bolt damage **+30 %**, `attack_range` +1.5 m, Slipstep recovers 3x faster | 9 s, +45 % | 10 s, +60 %. **Capstone:** each bolt also hits one more enemy unit within 3 m for 50 % | HP > 40 % and (an enemy hero or titan within 12 m, or 4+ enemy units within 10 m) |

### 5.5 Summary per class
| Class | T1 | T2 | T3 (parents) | Signatures |
|---|---|---|---|---|
| Spear | Lunge, Long Reach (P), Sure Footing (P) | Hobbling Javelin, Harrier (P) | Skewer (Lunge / Long Reach), Pole Vault (Sure Footing / Hobbling Javelin) | Skyfall Javelin, Hunter's Oath |
| Sword and Shield | Riposte, Hold Fast (P), Shield Block (P) | Second Wind, War Cry | Shield Throw (Riposte / Shield Block), Last Stand (P) (Hold Fast / Second Wind) | Shield Rush, Unbreakable |
| Two-Hand Sword | Cleave, Giant Slayer (P), Battle Fury (P) | Crushing Blow, Leap Strike | Whirlwind (Cleave / Battle Fury), Blood Price (P) (Giant Slayer / Crushing Blow) | Earthsplitter, Titanbreaker |
| Wizard | Arc Bolt, Focus (P), Ward (P) | Slipstep, Kindled Staff (P) | Starfall (Arc Bolt / Kindled Staff), Gravity Well (Ward / Slipstep) | Comet Rain, Astral Form |
Per class 6 actives + 3 passives; a champion owns at most **8 actives** (3 archetype + up to 5 tree, one signature).

## 6. How a champion picks (autonomous, seeded, readable)
### 6.1 The rule (ai: `ChampionSkillPicker`, called by the tree at each point)
1. **Moves**: every eligible (skill, next rank) (4.4), in tree order.
2. **Score**: `weight x taste x situation x move factors`, rounded to 0.1 (6.2-6.4).
3. **Offers**: at **level 7** exactly the 2 signatures. At **levels 8 and 9** the next signature rank (when eligible)
   is always one offer. Otherwise draw up to **3 distinct** moves, weighted by score, without replacement, with the
   champion's `skill_rng`; fewer than 4 moves: all are offered.
4. **Choose** the offer with the highest score (tie: tree order, then the lower rank).
5. **Log** `{level, id, rank, score, reason, offers}` and learn it (`skill_learned`).
Same seed + same situation = same picks. `skill_rng` is randomized at creation and saved with its `state`. The level-1
pick at hire has no situation yet (taste and weights only). The bot's champions use the same rule.
### 6.2 Weight and taste
- **Weight** 12 for the 3 step-11 class skills, 10 for the others (`tree` row `weight`).
- **Taste** = mean of the archetype's affinity for the skill's tags (`ChampionType.skill_affinity`):
| Archetype | burst | area | control | guard | sustain | mobility | hunt | support |
|---|---|---|---|---|---|---|---|---|
| Wayfinder | 1.0 | 0.9 | 1.3 | 0.7 | 1.0 | **1.6** | 1.3 | 1.0 |
| Oathwall | 0.8 | 1.0 | 1.3 | **1.7** | 1.4 | 0.7 | 0.8 | 1.3 |
| Coin-Cutter | **1.6** | 1.0 | 0.9 | 0.6 | 1.0 | 1.3 | **1.6** | 0.7 |
| Mender | 0.8 | 1.1 | 1.1 | 1.2 | 1.4 | 1.2 | 0.7 | **1.7** |
### 6.3 Situation (the brain's `pick_context()`, last 180 s unless said; a boost applies **once** to a move whose skill has at least one listed tag; product capped at x2.0)
| Signal (reason text) | Condition | Boost |
|---|---|---|
| `keeps dying` | Died in the last 300 s, or fled 2+ times in the last 300 s | sustain, guard, mobility **x1.4** |
| `fights crowds` | 3+ crowd moments (an autocast check with 3+ visible enemy units within 5 m; at most one per 5 s) | area **x1.4** |
| `hunts big game` | It hit or was hit by an enemy wizard, champion or titan | burst, hunt **x1.3** |
| `out-ranged` | >= 50 % of the damage it took came from attackers with range > 3 m or towers, and >= 100 in all | mobility, control **x1.3** |
| `your Guard bounties` (etc.) | Kind of the last bounty paid to it in the last 180 s, else of its current flag | Hunt: hunt, Explore: mobility, Guard: guard, Escort: support **x1.25** |
### 6.4 Move factors
| Factor (reason text) | When | x |
|---|---|---|
| `builds its kit` | A new skill (rank I) at level <= 4 | 1.2 |
| `deepens its craft` | A rank-up at level >= 7 | 1.2 |
| `trusts what works` | Rank-up of an active cast 3+ times in the last 180 s | 1.2 |
| (no text) | Rank-up of an active owned >= 180 s and never cast in the last 180 s | 0.7 |
| `masters its signature` | A signature rank-up | 1.3 |
| `remembers its path` | Campaign companion: the next entry of its saved path (9); always offered when eligible | 3.0 |
**Reason** shown: the largest factor above 1.0 among taste (`likes guard`: its best tag), situation and move factors;
none: `fits its class`.
### 6.5 Worked example (Garran Stoneward, Oathwall, hired 3:00 as Sword and Shield; offers are one seeded draw)
| Level (time) | Moves (score) | Offers | Takes | Reason |
|---|---|---|---|---|
| 1 (3:00, hire) | Riposte I 22.3, Hold Fast I 18.6, Shield Block I 20.4 | all 3 | **Riposte I** | likes guard |
| 2 (3:30) | Hold Fast I 18.6, Shield Block I 20.4 | both | **Shield Block I** | likes guard |
| 3 (4:15) | Hold Fast I 18.6, Riposte II 18.6, Shield Block II 17.0, Second Wind I 20.2, War Cry I 13.8 | Riposte II, Second Wind I, War Cry I | **Second Wind I** | likes sustain |
| 4 (5:15; it died at 4:50) | Hold Fast I 26.0, Riposte II 26.0, Shield Block II 23.8, War Cry I 13.8 | Hold Fast I, Shield Block II, War Cry I | **Hold Fast I** | keeps dying |
| 5 (6:40) | Last Stand I 21.7, Shield Throw I 12.6, Second Wind II 23.5, War Cry I 11.5, ... | Last Stand I, Shield Throw I, War Cry I | **Last Stand I** | keeps dying |
| 6 (8:40, death still < 300 s ago) | Riposte II 26.0, Hold Fast II 21.7, Second Wind II 23.5, Shield Throw I 12.6, ... | Riposte II, Hold Fast II, Shield Throw I | **Riposte II** | likes guard |
| 7 (11:10) | Shield Rush I 11.5, Unbreakable I 15.5 | both (milestone) | **Unbreakable I** | likes guard |
| 8-9 (14:00, 17:20) | Unbreakable II / III 24.2 always offered | | Unbreakable II, III | masters its signature |
Messages: `Garran Stoneward joins you · Sword and Shield · learns Riposte I`, then `Garran Stoneward learns Shield Block I`...

## 7. Autocast and brain
### 7.1 ChampionAbilities (gameplay)
| Part | Change |
|---|---|
| Ability list | `ability_ids()` = archetype 3 + owned tree actives in tree order; `passive_ids()`; `is_unlocked(id)`: archetype 1 / 1 / **6**, tree skills rank >= 1 |
| Ranks | `ABILITIES` rows carry per-rank arrays (`"amount": [19, 25, 31]`, `"cooldown"`, `"duration"`, `"radius"`, `"range"`); rank-III extras as flags; the 24 new ids |
| Passives | Child `"ChampionPassives"` (`scripts/units/champion_passives.gd`): modifiers `skill:<id>`, Unit damage filters, `attack_landed`, `skill_hit`; `refresh()` on `skill_learned` and on revive |
| Signatures | `scripts/units/champion_signatures.gd`: triggers, telegraphs, zones (one live zone per champion per id) |
| Cast budget | One cast per 0.5 s check + **1.0 s global cooldown** after any cast; exempt: `smoke_pouch`, `slipstep`, `pole_vault`, `snare_line`, `trailblaze`, `lifeline`, `second_wind`, `unbreakable`. **Team signature spacing 2 s** |
| Autocast order (36 actives) | `smoke_pouch`, `slipstep`, `pole_vault`, `snare_line`, `trailblaze`, `lifeline`, `second_wind`, `unbreakable`, `bulwark_stand`, `oath_of_iron`, `riposte`, `shield_rush`, `earthsplitter`, `skyfall_javelin`, `comet_rain`, `hunters_oath`, `titanbreaker`, `astral_form`, `shield_bash`, `hobbling_javelin`, `crushing_blow`, `gravity_well`, `whirlwind`, `starfall`, `skewer`, `leap_strike`, `war_cry`, `marked_for_coin`, `lunge`, `cleave`, `shield_throw`, `arc_bolt`, `cutpurse`, `soothing_circle`, `mending_draught`, `flare_arrow` |
| Mounts | Any cast dismounts first (unchanged) |
### 7.2 ChampionBrain (ai)
| Part | Change |
|---|---|
| `pick_context()` | The 6.3 signals + `casts` (id -> casts in 180 s, from `ability_cast`) + `owned_for`; timestamp rings fed by events it already sees; one crowd check in its 0.5 s tick |
| Power | The new `power()` (2.2) everywhere |
| R4 target preference | Unchanged, plus: owners of Giant Slayer, Titanbreaker or Hunter's Oath rank titans and heroes first in the class rule; Harrier ranks slowed / dazed enemies first |
| Flee | With **Last Stand ready**: flee threshold -0.05 |
| Early game | Champions now matter from ~3:30: R4's engage radius and the Oathwall's home patrol already make it defend a rush at home; no new rule |
| Bot | Hiring, reviving, flags unchanged (new prices / power read automatically); its champions pick by the same rule |

## 8. UI: what must be shown (layout: ui-designer, `ui-champions.md` section 16, task 11b.D2)
| Element | Content |
|---|---|
| Tavern row (unhired) | The **offered class** (glyph + name + class tooltip) and, on hover, its 9-skill tree (read-only); price; `Picks a skill at every level` |
| Tavern row (hired) | `Hired · Level 7 · Sword and Shield · Unbreakable · Guarding` (the signature once owned) |
| Inspect: title / level | `GARRAN STONEWARD · the Oathwall · Sword and Shield` from the hire (no `no class yet` state any more); `Level 9 · MAX` |
| Inspect: ability rows | Row 1 archetype (3, third badge `L6`); row 2 **owned tree actives** (0-5) with cooldowns and **rank pips**; signature slot gold-framed |
| Inspect: tree | 9 nodes in 4 tiers (3 / 2 / 2 / 2), parent lines into T3; states **owned** (pips + `L5` learned-at badge), **can take next** (gold outline), **locked** (`Level 5` / `Needs Lunge or Long Reach`), **closed** (the other signature: dark, slashed); passives in round frames. Compact grid or hover pop-out: ui-designer's call; read-only |
| Node tooltip | `Riposte II  (Sword and Shield · T1 · active)` / `20 s cooldown · 4 s` / `I: 8 · II: 10 · III: 13 + ranged` (owned rank bright) / `Learned at level 6 over Hold Fast II, Shield Throw I · likes guard` |
| Pick history | One line per level: `L5  Last Stand I   over Shield Throw I, War Cry I   keeps dying` (own and visible enemy champions) |
| Leaning line (own) | `Leans: guard (likes) · sustain (keeps dying) · your Guard bounties` |
| Messages | Hire: `Garran Stoneward joins you · Sword and Shield · learns Riposte I`; then `... learns Riposte III`, `... learns Unbreakable (signature)`; own champions only, merged within 2 s per champion |
| Bark (signature pick, 100 %) | Wayfinder `Found a new trick. Keeping it.` · Oathwall `Let them come. All of them.` · Coin-Cutter `Premium service. Premium price.` · Mender `I have learned to hit back.` |
| Champion bar | Class badge from the hire; a gold pip 3 s after each pick; tooltip `Skills: Riposte II · Shield Block I · ...`; Last Stand mark while ready |
| Removed (step-11 UI) | Lean tooltips, `?` class slots, `Class at level 2`, `· no class yet`, `Autocast · next at level 2` (3.3) |

## 9. Save and campaign
- `Champion.get_save_state()` gains `"skills"` (id -> rank), `"skill_log"` (`[{"level", "id", "rank", "reason",
  "offers": [[id, rank], ...]}]`), `"skill_rng_state"`; drops `"bounty_leans"`. `apply_save_state` restores quietly and
  re-applies passives.
- `ChampionGuild` save (where it saves): `"offered_classes": {"oathwall": "sword_shield", ...}`.
- **Old saves** (step 9 / 11): keep `total_xp`, re-level on the new table, draw a missing class quietly, replay the
  picks quietly with the rule (fresh seed).
- **Campaign companion**: gains `"skill_path"` (ordered ids, one entry per rank). Level resets to 1, class kept; the
  path entries are replayed first (`remembers its path`, x3.0, always offered); an entry that can no longer be taken is
  skipped. Old saves without the key: the normal rule. Campaign `version` stays 1.

## 10. Balance
### 10.1 Champion fight value by minute (index = growth^2 x (1 + 0.1 per ability-equivalent))
Equivalents: tree active rank I 0.6, passive rank I 0.35, a rank-up 0.25, signature rank I 0.8, signature rank-up 0.3,
archetype ability 1.0. Build: the 6.5 Oathwall hired at 3:00. Step 11: L1 until 6:05, L2 until 10:10, L3 until 15:00,
L4 until 19:55, L5 after.
| Minute | 3:00 | 3:30 | 4:15 | 5:15 | 6:05 | 6:40 | 8:40 | 10:10 | 11:10 | 14:00 | 15:00 | 17:20 | 20:00 | 25:00 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Step 11 | 1.20 | 1.20 | 1.20 | 1.20 | 1.52 | 1.52 | 1.52 | 1.88 | 1.88 | 1.88 | 2.31 | 2.31 | 2.79 | 2.79 |
| Step 11b (level) | 1.26 (1) | 1.35 (2) | 1.47 (3) | 1.56 (4) | 1.56 | 1.66 (5) | 1.88 (6) | 1.88 | 2.05 (7) | 2.16 (8) | 2.16 | 2.27 (9) | 2.27 | 2.27 |
| Ratio | 1.05 | 1.12 | 1.22 | 1.30 | 1.03 | 1.09 | 1.23 | 1.00 | 1.09 | 1.15 | 0.93 | 0.98 | **0.81** | **0.81** |
- **3:30-5:30: +10-30 % on purpose** (the user's "relevant vs rushes"). In absolute terms that is ~0.3 of an index point
  on a level-1 champion (~200-280 crystals of soldiers): about **one extra soldier's worth**. Enough to help hold (Oathwall
  guarding home) or join (Coin-Cutter) a 3:00-3:30 rush, never enough to decide one: a Fire rush of ~10 soldiers is
  ~5-6 index points.
- **6:00-17:00: within about +-15 %**, average +8 %.
- **After ~17:30 the champion is capped** (level 9, growth only from items): **-19 % vs step 11 at 20:00-25:00**. Late
  fights, where games end, belong to armies, titans and wizards.
### 10.2 Numbers at level 9 (no items)
| Champion (build) | HP / armor | Notes |
|---|---|---|
| Oathwall Sword and Shield (6.5) | 603 / 39 (x0.72 damage) | 12 x 1.16 / 1.1 = 12.7 DPS; Last Stand every 120 s, Unbreakable -40 % 8 s every 50 s |
| Coin-Cutter Two-Hand (Giant Slayer III, Titanbreaker III, Blood Price) | 348 / 5 | 24 x 1.16 / 1.55 = 18.0 DPS, x1.2 on big targets; Titanbreaker +~70 per 32 s |
| Mender Wizard (Focus III, Ward II, Gravity Well, Comet Rain III) | 297 / 5 | Heals +12 %; 41 shield every 16 s; Comet Rain III ~30 expected per enemy in the ring, ~90 at the centre |
| Wayfinder Spear (Sure Footing III, Pole Vault II, Hunter's Oath) | 302 / 0 | 6.45 m/s, tenacity 30 |
### 10.3 Fight checks (estimates; 11b.L2 decides)
- **Early (vs rushes).** A level-3 Oathwall Sword and Shield (Riposte I, Shield Block I, Second Wind I) at 4:15 beside
  the keep takes ~20 % less damage from ranged rushers than a step-11 level-1 Oathwall and returns ~8 per melee hit for
  3 s: it holds a doorway ~6 s longer. A level-2 Coin-Cutter joining a rush adds Cutpurse + one T1 skill: ~+15 % over
  step 11.
- **Mid.** L6 Sword and Shield Oathwall + a spire vs 5 Shades: holds ~25 s (step 11 at the same minute, L2: ~20 s).
- **Late.** L9 Earthsplitter III (90 x 1.16 = 104) leaves a Shade line at ~6 HP (no one-shot wipe); Comet Rain III ~30
  per enemy. Signatures are telegraphed, capped at 6-8 units, 25-40 % on buildings, never on the flying dragon.
- **Wizard.** A level-8 itemised wizard ~1 000 crystals of value; the best level-9 champion ~500-600. **No champion
  outclasses the wizard.**
- **Titans.** A L9 Two-Hand Oathwall (Giant Slayer III, Titanbreaker III) vs a **Nightmare Knight** (650 HP): ~even
  (the Knight wins ~55 %); vs the **War Mammoth** or **Elder Treant**: loses clearly. Melee champions touch the **Cinder
  Dragon** only with thrown skills. Three champions with an army kill a titan ~20 % faster than the army alone.
### 10.4 Game length (15-20 min, do not shorten)
- The early bump is symmetric (both sides hire from 2:00) and mostly defensive in effect (champions near home when a rush
  lands). Mid-game about equal; late weaker than step 11. Most new skills are sustain or control. Expected: **no
  shorter games** (0:00 to +0:45 median).
### 10.5 Knobs (one at a time, 11b.D3)
| Symptom (11b.L2 logs / playtest) | Knob |
|---|---|
| Games shorter than the step-11 median | Drill 1.0 -> 0.75 XP / s; then XP table x1.1; then signature area damage -20 % |
| Early champions decide rushes (the rusher wins more with a champion) | Rank I 75 % -> 60 %; drill starts 60 s after the hire |
| Level 9 median later than 19:00 / earlier than 16:00 | XP table x0.9 / x1.1 (fitting rule 2.1) |
| Champions irrelevant after 17:00 | Growth 2 % -> 3 %, or items / 4 in `power()` |
| Too tanky (Last Stand + Unbreakable + Riposte) | Last Stand recharge 120 -> 150 s; Unbreakable -30 / -35 / -40 % -> -25 / -30 / -35 % |
| One skill picked > 60 % in its tier / < 5 % | Weight 10 -> 8 / 10 -> 13 |
| Bounty lean invisible / too strong | x1.25 -> x1.4 / x1.15 |
| Too many casts, visual noise | Global cooldown 1.0 -> 1.5 s |
| Titans melted | Titanbreaker x2 on titans -> x1; Giant Slayer excludes titans |
| One class dominates at hire (tavern shows it: players dismiss-hunt) | Nothing to tune in weights; if dismiss-hunting shows up, the redraw after a dismiss waits 120 s |

## 11. Performance (budget unchanged: champion code < 0.1 ms / frame on average, 6 champions + 200 units; `PERF OK`)
- Picks: <= 9 per champion per game, ~24 moves each. The drill is one add per physics tick in `Champion` (no signal
  unless a level is reached; `xp_changed` at most once per second).
- Autocast: <= 8 actives per 0.5 s check on the cached lists; no group scans in triggers.
- Passives: modifiers once per `refresh()`; hooks O(1) per hit; <= 4 damage filters per champion.
- Zones: one Node3D each, 0.5 s ticks, one per champion per id. Counters: timestamp rings <= 16 entries.
- VFX pooled one-shots, particles only < 45 m, passive procs <= 1 per 0.3 s per champion.

## 12. Art: icons, VFX, poses (new skills only)
### 12.1 Icons (one art task per class; `art/icons/abilities/<id>.png`, readable at 36 px; passives round-framed, signatures gold-rimmed)
| Class (task) | 6 new icons |
|---|---|
| Spear (11b.V1) | Long Reach (spear tip past a ruler line), Sure Footing (planted boot + dust), Harrier (spear tip over a limping foot), Pole Vault (figure arcing on a pole), Skyfall Javelin (javelin falling from a starlit sky), Hunter's Oath (spear crossed over a red eye) |
| Sword and Shield (11b.V2) | Hold Fast (shield with a rooted base), Shield Block (arrow snapping on a shield), War Cry (sound rings over a raised sword), Last Stand (cracked shield still standing), Shield Rush (shield with speed lines), Unbreakable (steel-bound figure) |
| Two-Hand (11b.V3) | Giant Slayer (greatsword vs a giant silhouette), Battle Fury (blade with 3 ember notches), Leap Strike (figure leaping, blade down), Blood Price (red drops drawn up the blade), Earthsplitter (ground cracked by a blade), Titanbreaker (armor plate shattering) |
| Wizard (11b.V4) | Focus (eye in the staff crystal), Ward (hexagon bubble), Kindled Staff (bolt splitting in two), Gravity Well (spiral pulling dots), Comet Rain (falling comets), Astral Form (star-outlined figure) |
### 12.2 VFX families (ids = skill ids; class tints: Spear `(0.85, 0.75, 0.55)`, Sword and Shield `(0.7, 0.85, 1.0)`, Two-Hand `(1.0, 0.5, 0.25)`, Wizard `(0.6, 0.75, 1.0)`)
| Family (task) | Ids | Look |
|---|---|---|
| F1 Dash and leap (11b.V5) | `pole_vault`, `leap_strike`, `shield_rush` | Trail streak + landing dust ring; a wedge of shield light for the rush |
| F2 Telegraphed strikes (11b.V5) | `skyfall_javelin`, `earthsplitter`, `comet_rain` | Ground ring / line seen by both teams, filling over the delay, then the impact; 5-7 comet streaks + puffs, capstone big comet |
| F3 Auras and stances (11b.V6) | `war_cry`, `hunters_oath`, `titanbreaker`, `astral_form`, `unbreakable` | Pulse ring + ally glints; red tether + target mark; 3 ember charges on the blade; star-outline glow + staff halo; steel shell shimmer |
| F4 Zones (11b.V6) | `gravity_well`, Skyfall III javelin, Earthsplitter III crack | Ground decals / meshes <= 5 s |
| F5 Passive procs (11b.V6) | `shield_block`, `last_stand`, `ward`, `blood_price`, `battle_fury`, bounce arcs (Kindled Staff, Arc Bolt III, Astral III), hit sparks (Long Reach, Harrier, Giant Slayer) | Tiny pooled one-shots, rate-limited |
| F6 Learned (11b.V6) | `skill_learned` | A rising glyph with 1-3 pips over the head (1 s); signature: a gold burst |
### 12.3 Poses (11b.V7, kit `play_cast` + per-model check)
`pole_vault` (spear plant + arc), `leap_strike` (leap, blade down), `shield_rush` (shield-first charge), `war_cry` (sword
up, shout), `gravity_well` (staff swirl down), `skyfall_javelin` (overhand throw to the sky), `hunters_oath` (spear
pointed), `earthsplitter` (overhead chop into the ground), `titanbreaker` (blade raised, charged), `comet_rain` (staff
raised, both hands), `astral_form` (arms open, glow), `unbreakable` (shield braced, low stance); door-shield versions for
the Oathwall. Passives need no pose.

## 13. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 11b.L1)
- **Champion classes line** (replaces "At level 2 a champion draws a class ... + bounty leans"): each team's
  `ChampionGuild` draws one class per archetype at creation (`ChampionClass.pick_for_type(type, rng)`, base
  `class_weights` only), shows it in the tavern (`offered_class(archetype_id)`), applies it at hire
  (`set_champion_class` before the tree, `announce_class()` after: `class_chosen` once, at hire); redraw after a dismiss.
  No `bounty_leans`.
- **Champion**: `MAX_LEVEL = 9`, `LEVEL_TOTAL_XP = [0, 60, 150, 270, 450, 710, 1060, 1500, 2050]`,
  `DRILL_XP_PER_SECOND = 1.0` (alive only); `growth_pct` 0.02 in the `.tres`; child **`"SkillTree"`**
  (`skill_tree: ChampionSkillTree`); `skill_rank(id) -> int`; signal **`skill_learned(champion, skill_id: StringName,
  rank: int, entry: Dictionary)`** (after `class_chosen` at hire; before `level_changed` at level-ups); `announce_class()`;
  `power()` = `170 + 20 x level + 10 x ranks spent + items / 5`; save keys of section 9. Archetype ability 3 at level 6.
- **ChampionSkillTree** (`scripts/units/champion_skill_tree.gd`, Node): `setup(champion)`, `RANK_LEVELS = {1: [1, 3, 5],
  2: [3, 5, 7], 3: [5, 7, 9], 4: [7, 8, 9]}`, `MILESTONE_LEVEL = 7`, `ranks`, `points`, `log`, `rng`, `path_hint`,
  `rank_of(id)`, `owned_ids()`, `ranks_spent()`, `signature_id()`, `can_learn(id) -> String` (4.4), `eligible_moves()`,
  `learn(id, entry := {}) -> String`, `on_point(level)` (called at hire for level 1 and at each level-up; picks through
  `ChampionSkillPicker` if the script exists, else the first eligible move in tree order), `reset()`, save / load,
  signal `skill_learned(id, rank, entry)`.
- **ChampionClass** gains `tree: Array[Dictionary]` (9 rows: `id`, `tier` 1-4, `kind`, `tags`, `parents`, `weight`),
  `tree_ids()`, `tree_row(id)`, `tier_of(id)`, `signature_ids()`, `static pick_for_type(type, rng)`,
  `static chances_for_type(type)`; `weights_for` / `weights_from` ignore leans. **ChampionType** gains
  `skill_affinity: Dictionary`.
- **ChampionAbilities**: as 7.1 (`ability_ids`, `passive_ids`, `rank_of`, `is_unlocked` 1 / 1 / 6 + ranks, per-rank
  `amount_of`, 24 new ids, `AUTOCAST_ORDER`, `GLOBAL_COOLDOWN = 1.0`, `GCD_EXEMPT`, `SIGNATURE_SPACING = 2.0`); helpers
  `ChampionPassives` (`setup`, `refresh()`, `last_stand_ready()`) and `ChampionSignatures` (`can_trigger(id)`,
  `execute(id, target)`).
- **Unit**: stat **`tenacity`** (cap 60, CC x `(1 - tenacity / 100)` after `hero_mult`); status **`steadfast`**;
  **damage filters** `add_damage_filter(id, stage, f: Callable)` / `remove_damage_filter(id)`, stages `&"outgoing"`
  (`f(amount, target, kind) -> float`), `&"pre_armor"`, `&"post_armor"` (`f(amount, attacker, kind) -> float`).
- **ChampionSkillPicker** (ai, static): `score(move, ctx)`, `offers(moves, ctx, rng, level)`, `pick(moves, ctx, rng,
  level)`. **ChampionBrain** `pick_context()`.
- **ChampionGuild**: `offered_class(id)`, `class_rng`, revive `100 + 15 x level` essence after `20 + 2 x level` s.
  **Wizard** `xp_value_of` champion `110 + 10 x level`. **MountRider** champion courser at level 7.
- **ChampionVfx.play**: 12 new active ids, passive proc ids, `skill_learned`. **Model** `play_cast` for the 12 new
  actives. **Campaign** `companion.skill_path`.

## 14. What changes in other specs (11b.D3)
- `skills-rework.md`: 2 (draw at hire, no leans), 4.1 / 4.3 (tree and order), 6 (power), 7 (UI), 8 (save), 9
  (superseded by 10 here), 10 (contracts); a pointer to this file at the top.
- `champions.md`: 1 and 5 (levels 1-9, drill, growth 2 %), 3.3 revive, 4.3 (third ability at level 6), 8.2 power, 12.
- `levels.md`: champion victim `110 + 10 x level`. `cavalry-mounts.md` 6.3: courser at level 7.
- `ui-champions.md`: section 16 (11b.D2) and the removals of 3.3. Step 13b spec: reuse the unique NPC curve (2.1).
- The wizard, `spells.md`, `items.md`, `research.md`: unchanged.

## 15. Task list (step 11b; build after step 11 is integrated and green)
**Phase 0:** 11b.L1, 11b.D2. **Phase 1 (parallel, no shared files):** 11b.C1, 11b.C2, 11b.C3, 11b.C4, 11b.A1, 11b.C5,
11b.V1-V4, 11b.V5, 11b.V6. **Phase 1b:** 11b.V7 (after the step-13 kit edits), 11b.C6 (needs 11b.D2 + 11b.C1).
**Phase 2:** 11b.L2, then 11b.D3. Tests stub the other parts in `tests/test_11b_<id>.gd`; each task updates the step-9 /
11 tests of the files it owns (list in 3.3).
| Id | Agent | Task | Files | Done when |
|---|---|---|---|---|
| 11b.L1 | lead | Freeze section 13 in `CLAUDE.md` (Champions + Champion classes lines, Stats `tenacity`, Unit filters / `steadfast`), `step11b-agent-rules.md`, ids in `waves.md` | `CLAUDE.md`, `docs/plan/` | Section 13 is in `CLAUDE.md` |
| 11b.D2 | ui-designer | `ui-champions.md` section 16: tavern offered class + tree hover, inspect (title from hire, level 9, row 2 with pips, the 9-node tree or pop-out, states, tooltips, history, leaning line), bar pip / Last Stand mark, message merge, removal list of 3.3 | `docs/design/ui-champions.md` | Every row of section 8 has position, size, look at 1600 x 900 |
| 11b.C1 | gameplay-coder-high [H] | Class-at-hire changes of 3.3 in `champion.gd` / `champion_class.gd`; levels 1-9 (table, drill, growth 0.02 in the 4 `.tres`); `ChampionSkillTree`; `skill_learned`; `power()`; archetype ability 3 at 6 (data); `ChampionClass.tree` + 4 `.tres`; `ChampionType.skill_affinity`; Unit `tenacity` / `steadfast` / filters; `xp_value_of`; update `test_11_c1.gd`, `test_9_c1.gd` | `scripts/units/champion.gd`, `champion_skill_tree.gd` (new), `champion_class.gd`, `champion_type.gd`, `unit.gd`, `wizard.gd`, `data/champion_classes/`, `data/champions/`, the tests named | Levels at 60 / 150 / ... / 2 050 XP then `MAX`; the drill gives 60 XP per minute alive and none while fallen; a Coin-Cutter L9 has 348 HP; `set_champion_class` + `announce_class()` emit `class_chosen` once, then the level-1 `skill_learned`; nothing is drawn at level 2; 10 000 `pick_for_type` Oathwall draws give Sword and Shield 58-62 % (paid bounties change nothing); no `bounty_leans` in the save; fuzz 1 000 seeds x 16 pairs: gates of 4.3 / 4.4 never broken, level 7 always a signature, 9 ranks at L9, >= 2 moves at every level; `learn` reasons in order; save / load keeps ranks, log, rng state (next pick identical); step-9 / 11 saves re-level, draw and replay; `power()` L6 with 6 ranks = 350; `tenacity` 30 turns a 1.0 s daze on a hero into 0.35 s; `steadfast` clears and blocks `dazed`; each filter stage works; a re-hired archetype has no skills |
| 11b.C2 | gameplay-coder-high [H] | `ChampionAbilities`: per-rank arrays for the 12 step-11 skills (rank I 75 %) + rank III extras, lists / unlocks from the tree (archetype 3 at 6), the 4 new tree actives, GCD, signature spacing, order, helper creation; update `test_11_c2.gd`, `test_9_c2.gd` | `scripts/units/champion_abilities.gd`, the tests named | Each step-11 skill I / II / III in a test (Lunge 19 / 25 / 31 + the III attack reset...); Pole Vault 6 m never over a wall; War Cry +8 % within 6 m for 6 s; Leap Strike 23 in r 2.5 + daze; Gravity Well 30 over 3 s + daze 0.4; one cast per check, none within 1.0 s except the exempt ids; two own signatures never within 2 s; `PERF OK` |
| 11b.C3 | gameplay-coder-high [H] | The 12 passives + proc VFX calls | `scripts/units/champion_passives.gd` (new) | Each passive per rank in a test (Long Reach 3.0 m at III and +14 % on an archer; Shield Block -10 on a projectile, not on a melee hit, min 1; Last Stand once per 120 s, -50 % 3 s; Battle Fury 5 stacks dropped 4 s after the last hit; Blood Price 12 %; Ward 50 back 12 s after breaking; Kindled Staff every 3rd bolt 70 %; Focus +12); `refresh()` after learn and revive applies exactly once |
| 11b.C4 | gameplay-coder-high [H] | The 8 signatures (telegraphs, capstones, zones, caps, flyer rule) | `scripts/units/champion_signatures.gd` (new) | Each signature per rank + capstone in a test (Skyfall 75 / 35 after 1.2 s, the III javelin 5 s; Oath +20 % and the III reset; Shield Rush 8 m, max 6, stops at a titan; Unbreakable -30 % + `steadfast`; Earthsplitter 60, 40 % on a building, III crack; Titanbreaker +50 % and -6 armor, x2 on a titan; Comet Rain seeded 5 x 20 in r 1.8; Astral +30 % and +1.5 m); ground areas never hit a flyer; one zone per champion per id |
| 11b.A1 | ai-coder | `ChampionSkillPicker`; brain `pick_context()`, power use, R4 tweaks, Last Stand flee shift, no-class branches as fallbacks; update `test_11_a1.gd` | `scripts/ai/champion_skill_picker.gd` (new), `champion_brain.gd`, the test named | The 6.5 scores exactly (22.3 / 18.6 / 20.4 at level 1...); each 6.3 signal from a scripted history; 10 000 drafts match the weights +-2 %; same seed = same offers; level 7 offers only the 2 signatures; levels 8 / 9 always offer the next signature rank; reasons per 6.4; fog-only decisions; `PERF OK` |
| 11b.C5 | systems-coder | `ChampionGuild`: `class_rng`, `offered_class`, draw at creation, redraw after dismiss, class applied at hire + `announce_class()`, save of offered classes, revive `100 + 15 x level` after `20 + 2 x level` s; companion `skill_path`; courser at level 7 (the rule it owns); the stale comment in `bounty_board.gd`; update `test_11_c3.gd`, `test_9_c3.gd` | `scripts/world/champion_guild.gd`, `bounty_board.gd` (comment), `scripts/campaign/campaign_state.gd`, the tests named | A hired champion has the class its tavern row showed; a dismiss changes the offered class of that archetype only; the enemy guild's offers are its own; revive L6 = 190 essence after 32 s; a companion re-takes its saved path in order; old saves load |
| 11b.C6 | ui-coder | Section 8 per 11b.D2 and the removals of 3.3; update `test_11_c4.gd` | `scripts/ui/selection_panel.gd`, `champion_bar.gd`, `tavern_window.gd` (+ `champion_tree_panel.gd` if 11b.D2 asks), the test named | Tavern rows show the offered class and tree before hiring; no lean texts or `?` slots remain; the inspect tree, history (with offers and reasons), pips and messages per 16.x; enemy champions show tree and history, no leaning line; no `_private` calls |
| 11b.V1-V4 | tech-artist (one per class) | 6 new icons each (12.1) | `art/icons/abilities/`, the icon painter / render scripts (V1 the pipeline; V2-V4 add entries) | 24 icons readable at 36 px; contact sheet `docs/art/screens/champion_tree_icons.png` |
| 11b.V5 | tech-artist (VFX) | F1 + F2 | `art/vfx/champion_vfx.gd`, `art/vfx/champion_tree_*` | Each id plays once and stops; telegraphs match the gameplay size and delay; no runtime materials |
| 11b.V6 | tech-artist (VFX) | F3-F6 | `art/vfx/champion_tree_*` (registers ids after 11b.V5) | As 11b.V5; procs rate-limited |
| 11b.V7 | tech-artist | Kit poses for the 12 new actives + per-model check | `art/units/kit/character_model.gd`, `art/units/champions/*/` | Every new id poses on the 4 models with each class weapon; ch. 4.6 budgets held |
| 11b.L2 | lead | Integration, smoke / perf, bot-vs-bot runs logging class offers / hires, picks per skill per archetype x class, levels at 3 / 5 / 10 / 15 / 20 min, level-9 time, casts / damage per skill, deaths, match length, rush outcomes with and without an early champion | `tests/`, `docs/plan/` | Median match length >= the step-11 value and in 15:00-22:00; median level 3-4 at 5:00 and level 9 at 16:00-19:30; every champion has a class from its hire; CI green |
| 11b.D3 | game-designer | Balance from 11b.L2 + playtest (knobs 10.5), follow-ups of section 14 | `docs/design/` | Knob changes written here; the listed specs updated |

## Done when (step 11b)
- [ ] 11b.L1 contracts frozen; 11b.D2 layout written.
- [ ] 11b.C1-C6, 11b.A1 pass their tests; the updated step-9 / 11 tests pass; smoke `victory=true`; `PERF OK`.
- [ ] 11b.V1-V7 art in place (24 icons, 6 VFX families, 12 poses).
- [ ] 11b.L2 green (no shorter games, level 9 at 15-20 min); the user playtests: the tavern shows each champion's class,
  a champion levels within the first minutes after hire, the inspect view shows its tree, its picks, the offers and the
  reasons, and `learns ...` messages appear.
