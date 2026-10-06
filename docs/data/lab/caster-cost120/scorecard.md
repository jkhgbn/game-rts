# Data Lab scorecard: caster-cost120

2026-10-05 19:41 · lab v1.1 · 4.38 s · scanned 81 units, 26 buildings, 4 champions, 4 classes, 44 items, 12 spells, 7 ai

## Result: **FAIL** · score **95 / 100**

1 FAIL · 3 WARN · 28 PASS · 2 info checks; findings: 1 FAIL, 13 WARN, 1 info

## Improve next
1. **Internal consistency** (FAIL): data/buildings/fire_watch_keep.tres: keep trains nothing -> fill trains or train_ids (see each finding) _(from F5 176 / 178 clean (1 FAIL, 1 WARN), 1 info)_
2. **Code id lists have data files** (WARN): data/buildings/fire_stables.tres: not in BuildingType.ALL_IDS (never in a build menu, find by name misses it) -> add it to ALL_IDS (systems-coder) (add the file or the id) _(from L3 42 / 47 clean (0 FAIL, 5 WARN))_
3. **Stat outliers vs their group** (WARN): data/units/blaze_rider.tres: max_hp 220 is 3.1x the slot C median 70 -> check the design table; if intended, note it in the spec (check the value against the design table) _(from F6 39 / 41 clean (0 FAIL, 3 WARN))_
4. **Cross-kingdom cost efficiency** (WARN): grave_hound (shadow slot C): DPS per 100 crystals 16.3 vs row median 7.4 (x2.20) -> Balance Lab: check cost or damage (support units may be meant low) (a lead for the Balance Lab, not a bug) _(from B1 16 / 20 clean (0 FAIL, 4 WARN))_

## Fix list by owner (paste into docs/handoff/for-<owner>.md)
### game-designer (7 findings; handoff: docs/handoff/for-game-designer.md)
- **WARN B1**: Balance Lab: check cost or HP -> `ash_hurler (fire slot V)` (EHP per 100 crystals 43 vs row median 187 (x0.23))
- **WARN B1**: Balance Lab: check cost or damage (support units may be meant low) -> `grave_hound (shadow slot C)` (DPS per 100 crystals 16.3 vs row median 7.4 (x2.20)); `rime_seer (ice slot C)` (DPS per 100 crystals 3.3 vs row median 7.4 (x0.45)); `bloomtender (nature slot C)` (DPS per 100 crystals 3.7 vs row median 7.4 (x0.50))
- **WARN F6**: check the design table; if intended, note it in the spec -> `blaze_rider.tres` (max_hp 220 is 3.1x the slot C median 70); `blaze_rider.tres` (attack_damage 18 is 2.6x the slot C median 7); `ash_hurler.tres` (max_hp 60 is 0.1x the slot V median 430)

### items-coder (1 findings; handoff: docs/handoff/for-items-coder.md)
- **WARN F5**: add its numbers to passives -> `stillwater_orb.tres` (passive_id `stillwater` not a key of passives)

### systems-coder (6 findings; handoff: docs/handoff/for-systems-coder.md)
- **FAIL F5**: fill trains or train_ids -> `fire_watch_keep.tres` (keep trains nothing)
- **WARN L3**: add it to ALL_IDS (systems-coder) -> `fire_stables.tres` (not in BuildingType.ALL_IDS (never in a build menu, find by name misses it)); `fire_watch_keep.tres` (not in BuildingType.ALL_IDS (never in a build menu, find by name misses it)); `ice_stables.tres` (not in BuildingType.ALL_IDS (never in a build menu, find by name misses it)); `nature_stables.tres` (not in BuildingType.ALL_IDS (never in a build menu, find by name misses it)); `shadow_stables.tres` (not in BuildingType.ALL_IDS (never in a build menu, find by name misses it))


## Load (every resource loads, ids match files)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| L1 | Every data .tres loads | PASS 100 | 178 / 178 clean | each file under data/ loads as its data script |  |
| L2 | Ids match file names | PASS 100 | 178 / 178 clean | find(id) loads DIR/<id>.tres, so id == file name |  |
| L3 | Code id lists have data files | **WARN** 65 | 42 / 47 clean (0 FAIL, 5 WARN) | BuildingType.ALL_IDS, ChampionType.IDS, ChampionClass.IDS, CreatureAbilities.CREATURES / BEASTS | add the file or the id |

## Fields and bounds
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | Required fields set | PASS 100 | 178 / 178 clean | ids, names, HP, abilities... (Rules.REQUIRED per kind) |  |
| F2 | No NaN / inf | PASS 100 | 178 / 178 clean | every float, array and dictionary number is finite |  |
| F3 | No negative cost / HP / damage / time | PASS 100 | 178 / 178 clean | cost, hp, damage, cooldown, time, range, speed, pop fields >= 0 |  |
| F4 | Stats inside hard bounds | PASS 100 | 178 / 178 clean | Rules.HARD_BOUNDS per kind (broken values only) |  |
| F5 | Internal consistency | **FAIL** 34 | 176 / 178 clean (1 FAIL, 1 WARN), 1 info | rank arrays = max_rank, unlock levels ascending, recipes have parts, towers shoot, trainers train... | see each finding |
| F6 | Stat outliers vs their group | **WARN** 67 | 39 / 41 clean (0 FAIL, 3 WARN) | within x2.5 of the group median (barracks slot Z / X / C / V across kingdoms, workers, creatures, beasts, champions, towers) | check the value against the design table |

## References (files, ids, abilities, items)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | Model files exist | PASS 100 | 111 / 111 clean | model_scene / model_path point at existing scenes |  |
| R2 | model_path without model_scene | PASS 100 | 111 / 111 clean | UnitType never loads model_path: a finished model must be in model_scene (FAIL) |  |
| R3 | Ability ids known | PASS 100 | 93 / 93 clean | creature / beast / champion / class ability ids exist in CreatureAbilities / ChampionAbilities, owners match |  |
| R4 | Item ids known | PASS 100 | 39 / 39 clean | champion wishlists, item actives (ItemActives.ACTIVES / ALIASES) |  |
| R5 | Statuses, stats, kinds known | PASS 100 | 171 / 171 clean | statuses in Unit.STATUSES, stat keys in Unit.STAT_NAMES (+ _pct), factions / kinds / wares valid |  |
| R6 | Spell references | PASS 100 | 13 / 13 clean | wizard default_spell_ids exist, summon ids exist, every spell has a caster |  |
| R7 | Training lists resolve | PASS 100 | 32 / 32 clean | every trains / train_ids entry is a unit file |  |
| R8 | Icons / sounds / research | INFO | no icon or sound paths in data yet (icons are icon_abbrev letters, sounds are generated by name); research.md has no data table in code yet (tech prerequisites checked: requires_kind, spell level_required) |  |  |

## Hotkeys
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| K1 | Training card keys | PASS 100 | 12 / 12 clean | <= 8 units per building (Z X C V B N M , by slot), card_key = the slot letter, unique per card |  |
| K2 | Build menu keys | PASS 100 | 21 / 21 clean | hotkey_label in Z X C V B N, unique per kingdom build menu (trade on = all entries) |  |
| K3 | Spell keys | PASS 100 | 12 / 12 clean | each wizard's default_spell_ids are F, Q, E in order |  |
| K4 | Reserved keys respected | PASS 100 | 81 / 81 clean | no data key on W A S D Q E F (Controls setting Classic / Hero WASD, CLAUDE.md Keys); card_key a slot letter |  |
| CU1 | Casters | PASS 100 | 9 / 9 clean | CasterKit.CASTERS: .tres, tier 2, pop 2, key B, 2 spells (Z / V) + a passive, mana > 0, statuses known |  |

## Text (names, tooltips, width, French readiness)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T5 | Tooltip numbers match the data | PASS 100 | 65 / 65 clean | every number printed in an ability / item / spell text exists in its data (also x100 for shares, products of two values) |  |
| T4 | Display names unique per kind | PASS 100 | 167 / 167 clean | no two units / buildings / items / spells / classes share a name |  |
| T1 | Names and tooltips exist | PASS 100 | 376 / 376 clean | every display name / tooltip / ability text / bark is written |  |
| T2 | No placeholder or broken text | PASS 100 | 376 / 376 clean | no TODO / TBD / xxx / lorem, no mojibake (Â·, Ã©), no double spaces |  |
| T3 | Text fits its UI width | PASS 100 | 376 / 376 clean | names <= 240 px at 18 px; tooltips <= 6 lines at 300 px / 13 px; abbrev <= 3 letters (font: engine fallback font) |  |
| T7 | Hard-coded UI strings (French readiness) | INFO | 297 literal UI strings (287 distinct) in 28 scripts under scripts/ui/, 0 wrapped in tr(); no translation table yet; biggest: selection_panel.gd (61), tavern_window.gd (36), command_card.gd (33) | INFO only. Next step (ui-coder): ui_strings.csv in this folder = key, file, line, text of every literal: load it as a Translation (CSV import) and wrap the literals in tr(KEY), biggest scripts first |  |

## AI profiles (data/ai + built-in presets)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | Every kingdom has easy / normal / hard | PASS 100 | 12 / 12 clean | AIProfile.for_id(id_for_faction(k), 0..2) returns a profile (data/ai .tres or code preset) |  |
| A2 | AI knobs in range | PASS 100 | 13 / 13 clean | Rules.AI_BOUNDS (ai_profile.gd / ai.md ranges) + ordering (floor <= ratio, S2 after S1...) |  |
| A3 | AI references | PASS 100 | 13 / 13 clean | item_build, champion_order, retreat_spell (own kingdom), ware_order, spell_order, build rows, flag rules |  |
| A4 | Army mixes | PASS 100 | 13 / 13 clean | mix_default / vs_ranged / vs_melee: 4 shares >= 0 summing to 1 |  |
| A5 | Difficulty order | PASS 100 | 28 / 28 clean | easy -> normal -> hard moves each knob of Rules.AI_MONOTONIC one way |  |

## Balance (INFO / WARN only)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| B1 | Cross-kingdom cost efficiency | **WARN** 62 | 16 / 20 clean (0 FAIL, 4 WARN) | EHP / DPS per 100 crystals within x1.6 of the slot median (WARN only) | a lead for the Balance Lab, not a bug |

## Findings (FAIL and WARN)
| Sev | Check | Owner | Where | What | Fix |
|---|---|---|---|---|---|
| FAIL | F5 | systems-coder | data/buildings/fire_watch_keep.tres | keep trains nothing | fill trains or train_ids |
| WARN | L3 | systems-coder | data/buildings/fire_stables.tres | not in BuildingType.ALL_IDS (never in a build menu, find by name misses it) | add it to ALL_IDS (systems-coder) |
| WARN | L3 | systems-coder | data/buildings/fire_watch_keep.tres | not in BuildingType.ALL_IDS (never in a build menu, find by name misses it) | add it to ALL_IDS (systems-coder) |
| WARN | L3 | systems-coder | data/buildings/ice_stables.tres | not in BuildingType.ALL_IDS (never in a build menu, find by name misses it) | add it to ALL_IDS (systems-coder) |
| WARN | L3 | systems-coder | data/buildings/nature_stables.tres | not in BuildingType.ALL_IDS (never in a build menu, find by name misses it) | add it to ALL_IDS (systems-coder) |
| WARN | L3 | systems-coder | data/buildings/shadow_stables.tres | not in BuildingType.ALL_IDS (never in a build menu, find by name misses it) | add it to ALL_IDS (systems-coder) |
| WARN | F5 | items-coder | data/items/stillwater_orb.tres | passive_id `stillwater` not a key of passives | add its numbers to passives |
| WARN | F6 | game-designer | data/units/blaze_rider.tres | max_hp 220 is 3.1x the slot C median 70 | check the design table; if intended, note it in the spec |
| WARN | F6 | game-designer | data/units/blaze_rider.tres | attack_damage 18 is 2.6x the slot C median 7 | check the design table; if intended, note it in the spec |
| WARN | F6 | game-designer | data/units/ash_hurler.tres | max_hp 60 is 0.1x the slot V median 430 | check the design table; if intended, note it in the spec |
| WARN | B1 | game-designer | grave_hound (shadow slot C) | DPS per 100 crystals 16.3 vs row median 7.4 (x2.20) | Balance Lab: check cost or damage (support units may be meant low) |
| WARN | B1 | game-designer | rime_seer (ice slot C) | DPS per 100 crystals 3.3 vs row median 7.4 (x0.45) | Balance Lab: check cost or damage (support units may be meant low) |
| WARN | B1 | game-designer | bloomtender (nature slot C) | DPS per 100 crystals 3.7 vs row median 7.4 (x0.50) | Balance Lab: check cost or damage (support units may be meant low) |
| WARN | B1 | game-designer | ash_hurler (fire slot V) | EHP per 100 crystals 43 vs row median 187 (x0.23) | Balance Lab: check cost or HP |

## Stat spread per group (median (min-max))
| Group | n | max_hp | move_speed | attack_damage | attack_cooldown | aggro_range | cost |
|---|---|---|---|---|---|---|---|
| slot Z | 4 | 120 (70-150) | 4.90 (4.20-5.40) | 11 (8-12) | 1 (0.90-1.10) | 8 (8-8) | 85 (60-95) |
| slot X | 4 | 67.50 (50-80) | 5 (4.40-5.20) | 9 (7-10) | 1.25 (1.20-1.40) | 10 (10-10) | 100 (70-110) |
| slot C | 4 | 70 (60-220) | 5.90 (4.20-7.50) | 7 (5-18) | 1.20 (0.70-1.50) | 9 (9-10) | 105 (70-180) |
| slot V | 4 | 430 (60-520) | 4 (3.40-4.60) | 25 (18-28) | 1.60 (1.20-2.20) | 10 (9-12) | 230 (140-290) |
| workers | 4 | 50 (45-60) | 4.60 (4.60-4.60) | 4 (3-4) | 1.20 (1.20-1.20) | 0 (0-0) | 50 (40-50) |
| creatures | 4 | 195 (120-420) | 4.30 (3.20-5) | 10.50 (7-14) | 1.10 (0.90-1.60) | 6 (6-7) | 0 (0-0) |
| beasts | 9 | 1500 (1300-3000) | 5.50 (5-7.50) | 30 (24-42) | 1.50 (1-1.80) | 0 (0-8) | 0 (0-0) |
| champions | 4 | 290 (260-520) | 5.20 (4.30-5.80) | 14 (9-17) | 1.20 (0.90-1.40) | 9 (8-10) | - |
| towers | 4 | 750 (675-900) | - | 13.50 (10-15) | 1.50 (1.20-1.50) | - | 120 (100-130) |


## Hard-coded UI strings per script (T7, INFO)
| Script | Strings | Examples |
|---|---|---|
| scripts/ui/selection_panel.gd | 61 | `Nothing selected`, `%s\nClick: show it  ·  Tab / Shift+Tab: `, `HP  %d / %d` |
| scripts/ui/tavern_window.gd | 36 | `Dismiss\nThe team gets 50 % of its purse`, `Tavern`, `Close  [Y]` |
| scripts/ui/command_card.gd | 33 | `Hired hunters act on their own.`, `: trade & hunters`, `Trading posts open at 4:00` |
| scripts/ui/trade_window.gd | 33 | `No Bazaar`, `Not enough gold`, `No Greywater Lodge` |
| scripts/ui/menus/main_menu.gd | 25 | `Four apprentices. One vanished master. E`, `Four Wizards`, `Prototype build  -  Esc in game: pause` |
| scripts/ui/menus/unit_guide.gd | 16 | `Up / Down: browse    Ctrl+F: search    C`, `Unit Guide`, `Search a unit, role or counter (Ctrl+F)` |
| scripts/ui/post_panel.gd | 15 | `Right-click with your Bazaar selected to`, `Thieves who rob caravans and remote work`, `On the roads from 5:00 · raid remote min` |
| scripts/ui/menus/settings_panel.gd | 14 | `Applies from the next match. Deer and ra`, `Settings`, `Back` |
| scripts/ui/point_panel.gd | 9 | `Capture: stand in the ring with soldiers`, `Right-click with soldiers or your wizard`, `On the enemy bank: capture takes 25 % lo` |
| scripts/ui/champion_bar.gd | 7 | `  (class, level %d)`, `Your bounties before level 2 steer its c`, `Locked` |
| scripts/ui/mapfill_bar.gd | 7 | `Enemy blessing %d s\n+12 %% speed, +1.5 `, `Click: centre the camera`, `Blessing` |
| scripts/ui/bounty_mode.gd | 5 | `No champions`, `Too many bounties`, `Invalid target` |
| scripts/ui/flag_card.gd | 5 | `Z: raise +25  ·  Shift+Z: +100  ·  Delet`, `An enemy bounty: kill or protect its tar`, `Pursuers` |
| scripts/ui/shop_window.gd | 5 | `Keep shop`, `Items not available`, `Exchange 100 crystals -> 40 essence` |
| scripts/ui/str_int_panel.gd | 4 | `Choose your path (locked for the match)`, `%s  %s  ACTIVE %d s`, `%s  %s  %d s` |
| scripts/ui/selection_manager.gd | 3 | `Right-click a trading post to set the ro`, `ZXCVBNM,`, `No upgrade for that unit` |
| scripts/ui/mission/briefing_screen.gd | 3 | `Primary objectives`, `Begin`, `Enter: begin` |
| scripts/ui/top_bar.gd | 2 | `POP`, `%d / %d` |
| scripts/ui/menus/kingdom_card.gd | 2 | `%s kingdom`, `Coming soon` |
| scripts/ui/hud.gd | 2 | `Summary`, `Capture: stand near towers, wells and sh` |
| scripts/ui/menus/pause_menu.gd | 2 | `Paused`, `Every unit: stats, abilities, pros and c` |
| scripts/ui/control_group_bar.gd | 2 | `  %d %s`, `Group %s: %s\nClick: select  ·  Double-c` |
| scripts/ui/next_step_hint.gd | 1 | `(click to hide)` |
| scripts/ui/menus/game_settings.gd | 1 | `settings` |
| scripts/ui/chat_line.gd | 1 | `Type a command (dance 1 / 2 / 3) - Enter` |
| scripts/ui/menus/unit_guide_data.gd | 1 | `Tavern` |
| scripts/ui/mission/dialogue_box.gd | 1 | `Enter / click: next` |
| scripts/ui/mission/objectives_panel.gd | 1 | `Secondary` |


## AI profile sources (A1)
| Kingdom | Easy | Normal | Hard |
|---|---|---|---|
| fire (`shadow_default`) | code (`easy`) | code (`normal`) | code (`hard`) |
| shadow (`shadow_default`) | code (`easy`) | code (`normal`) | code (`hard`) |
| ice (`ice_default`) | data (`ice_easy`) | data (`ice_normal`) | data (`ice_hard`) |
| nature (`nature_default`) | data (`nature_easy`) | data (`nature_normal`) | data (`nature_hard`) |

Fire uses the Shadow bot (`shadow_default`, ai.md), built in code; Ice / Nature read data/ai/*.tres.

## Cross-kingdom balance (B1)
EHP = max_hp x (1 + armor / 100); DPS = attack_damage / attack_cooldown (no splash, statuses or support). Per 100 crystals. Rows = card slot (barracks Z X C V = the same role in every kingdom). **bold** = more than x1.6 from the row median (WARN).

| Slot | fire | shadow | ice | nature | median EHP/100 | median DPS/100 |
|---|---|---|---|---|---|---|
| Worker | Cinder Hand 50c: 100 EHP, 6.7 DPS | Gloom Thrall 50c: 100 EHP, 6.7 DPS | Rime Hauler 50c: 120 EHP, 6.7 DPS | Sprigling 40c: 113 EHP, 6.3 DPS | 106 | 6.7 |
| Z | Flame Guard 90c: 144 EHP, 13.3 DPS | Shade 80c: 138 EHP, 13.8 DPS | Rimeshield 95c: 182 EHP, 10.5 DPS | Thornling 60c: 117 EHP, 14.8 DPS | 141 | 13.5 |
| X | Ember Archer 100c: 70 EHP, 7.5 DPS | Nightbolt 100c: 65 EHP, 7.7 DPS | Shardcaster 110c: 76 EHP, 5.8 DPS | Burr Slinger 70c: 71 EHP, 8.3 DPS | 71 | 7.6 |
| C | Blaze Rider 180c: 122 EHP, 11.1 DPS | Grave Hound 70c: 100 EHP, **16.3** DPS | Rime Seer 120c: 61 EHP, **3.3** DPS | Bloomtender 90c: 67 EHP, **3.7** DPS | 83 | 7.4 |
| V | Ash Hurler 140c: **43** EHP, 7.8 DPS | Shadow Knight 260c: 185 EHP, 7.1 DPS | Rime Colossus 290c: 215 EHP, 5.4 DPS | Bramblehorn 200c: 190 EHP, 7.5 DPS | 187 | 7.3 |


## Info findings (1)
| Check | Where | What |
|---|---|---|
| F5 | data/items/oath_of_embers.tres | campaign reward in a recipe tier with no parts |

## Notes
- Load 4.24 s (every .tres with its model scenes), checks 0.14 s.
