# The 2v2 bots: enemy teams that play together, an ally bot that plays with you

Source of truth for the step-20 AI tasks (20.A1-20.A8). Written 2026-09-26 by the game-designer (task 20.D3), in
parallel with `map-2v2.md` (20.D1, map + rules) and `ui-2v2.md` (20.D2, lobby, 4-player HUD, ally pings).
User request (`waves.md` step 20): the player controls **only their own kingdom**; one **ALLY bot** on the player's team;
two **ENEMY bots**. The ally bot **reuses the existing Commander** with an "ally" layer: it follows the player's attacks
and defends the player's base. Everything here extends `ai.md` (rules 1-13), `rush-balance.md` (styles, rules 1b / 13c /
15), `champions.md` 10, `market-trade.md` 7 and `map-fill.md` 7; nothing there changes for the 1v1.
Metres, seconds, `m:ss` = match time. "Seat" = one kingdom slot (a player, human or bot). "Side" = a team of seats.

**Design rules kept from `ai.md`:** a bot is a **player**: public APIs only, never cheats crystals, sees only through its
side's fog. Hard is faster and more precise, never richer. New in 2v2: the bots of one side **talk to each other** (a
shared plan, like two humans on voice chat), and the ally bot **listens to the human** (pings) and **watches** the human's
army (it is an ally: it sees it without fog).

## 0. Decisions and assumptions (the user's answers go here)
| # | Topic | Assumed now (recommendation) | Owner |
|---|---|---|---|
| A1 | Who owns what | **Seats + sides**: every unit / building has an owner **seat** (0-3) and a **side** (0 = the human's, 1 = the enemy's). Hostility, fog (allied vision), capture points, banks = side. Economy, pop, essence, gold, champions, bounties, orders, build slots = seat. 1v1: seat == side == today's team (0 PLAYER, 1 ENEMY), so the 1v1 does not change | 20.D1 decides the encoding (section 3 lists what the AI needs) |
| A2 | Seats | Seat 0 = the human, seat 2 = the ally bot (side 0); seats 1 and 3 = the enemy bots (side 1) | 20.D1 / 20.D2 lobby |
| A3 | Defeat | A seat is **out** when it has no living building (the 1v1 rule) or concedes; **a side loses when all its seats are out** | 20.D1 confirms |
| A4 | Resources | Separate per seat (waves.md recommendation). No gifting in v1 | 20.D1 |
| A5 | Ally default personality | **Supportive** (Q1) | User |
| A6 | Enemy targeting | **Fair score**, no bias toward the human, no double rush (Q2) | User |
| A7 | A bot gives up while its teammate stands | **Its seat crumbles** (buildings collapse, units vanish), the teammate plays on alone (Q3) | User (+ 20.D1's defeat rule) |

## 1. At a glance
| Part | What | Where |
|---|---|---|
| Seat refactor | Every "the enemy" in the AI becomes "the hostile seats"; every "mine" becomes "my seat"; slot positions come from a seat frame instead of the point mirror | `commander.gd` + helpers (20.A1) |
| Side council | One `AISideCouncil` per side: shared target choice, joint attacks, claims (camps, points, shrines, scouting), help-your-teammate rule | `scripts/ai/ai_council.gd` (new, 20.A3) |
| Enemy bots | Target score (near, weak, teammate focus, revenge, lane); joint pushes synced within 30-45 s; no joint attack on one seat before 5:00; at most one Rusher per side | Council + rule 7 (20.A3) |
| Ally bot | `AIAlly` layer: answers pings (attack / defend / help / retreat), follows the human's pushes, defends the human's base, never steals, shares scouting, 3 personalities, rules for an idle human, a dead human wizard, an eliminated human | `scripts/ai/ai_ally.gd` (new, 20.A4) |
| Champions / trade / map fill | Hostile = other side only; no double bounties with the ally; no raiding allies; allied champions help beast parties; camps / points / shrines split by home seat | `champion_sense.gd`, `champion_brain.gd`, `ai_champions.gd`, `ai_trade.gd`, `ai_mapfill.gd`, `thief_band.gd`, `tracker_contract.gd` (20.A5) |
| Concede + stall fix | The known bot stall (never concedes with a caravan / Bazaar at 0 workers; gold held for wares) fixed for 1v1 **and** 2v2; concede = the seat is out, not the match | `commander.gd`, `ai_trade.gd` (20.A2, can start now) |
| Performance | One shared per-frame unit cache (`AIWorldCache`), staggered think ticks, no full "units" loops in 0.5 s loops | `scripts/ai/ai_world_cache.gd` (new, 20.A6) |
| Tests | 4-bot harness with a scripted "human" (HumanProxy), toggles, fairness and length rounds | `tests/test_20_a7.gd` (20.A7) |

## 2. Inventory: every "exactly one enemy" assumption in the AI today (52)
Read from the code on 2026-09-26. "Fix" = what 20.A1 / 20.A2 / 20.A5 change (details in sections 3-8).
### 2.1 `scripts/ai/commander.gd`
| # | Function | Assumption today | Fix |
|---|---|---|---|
| E1 | `_ready()` | One Commander per **team**: a second bot of the same team frees itself (two bots on one side would delete each other) | One per **seat** |
| E2 | `for_team()` (static) | Finds the Commander by team | `for_seat()` (keep `for_team()` = seat in 1v1) |
| E3 | `_setup()` | `_enemy_team = Skirmish.enemy_team_of(team)`: one int, also handed to `AITrade`, `AIChampions`, `AIMapFill` | `_seat`, `_side`, `_hostile_seats: Array[int]` (living only, refreshed each tick) and a **target seat** from the council |
| E4 | `_side()` + its callers (`_setup` rally / anchor, `_row_base`, `_row_spot` shifts, `_wall_spot`, `_rule_scout`, `_drive_fog_scout`, `_next_scout_point`, `_explore_points`) | Point mirror `p` / `-p` by `team == ENEMY`: exactly two base layouts | `_frame(p)` = `level.seat_frame(seat) * p` (section 3.2) |
| E5 | Consts `ROWS`, `RALLY`, `ANCHOR`, `X2_SPOT`, `SCOUT_PATH`, `WALL_OFFSETS` | Absolute Shadow-side Crown Hollow coordinates | Kept as **Shadow-side 1v1 coordinates**; placed through `_frame()` (seat frame maps them) |
| E6 | `_detect_faction()` | `kingdom_of(team)`; fallback Shadow if ENEMY else Fire | `kingdom_of(seat)` |
| E7 | `_scan()` | Own = `u.team == team` (side encoding: it would **order the human's units** and count them in `own_strength`); enemies = `t == _enemy_team` (seat encoding: the second enemy is invisible); `_enemy_buildings` the same | Own = `u.seat == seat`; allied = same side, other seat (read-only lists); hostile = other side (fog-filtered) |
| E8 | `_scan()` | `wizard_of(team)`, `keep_of(team)`: one wizard, one keep | `wizard_of(seat)`, `keep_of(seat)` |
| E9 | `_update_memory()` / `seen_strength` | One number for "the enemy" (both hostile seats summed) | Memory entries get an owner seat; `seen_strength_of(seat)` (section 4.3) |
| E10 | `_on_building_damaged()` | Attacker `team == _enemy_team` | Attacker on the hostile side |
| E11 | `_rule_defend()`, `_distance_to_base()`, `_home_strength()` | Only own buildings exist; the core is `base_center(team)` | Unchanged for the own base, plus rule 1c (teammate base) and ally rule L1 (the human's base) |
| E12 | `_setup()` node refs, `_best_node()`, `_safe_far_node()`, `_out_of_crystals()` | `node_of(team, "a" / "b" / "mid" / "rich")` = `node_shadow_*` / `node_fire_*`; `base_center(team)` | `node_of(seat, suffix)` |
| E13 | `_row_base()` | `natural_hall_spot(team)`, `market_slot(team)`, `tower_slot(team, id)`: two mirrors | Same calls by seat |
| E14 | `_rule_attack()` | Launch when `own_strength >= attack_ratio x max(seen_strength, 250)`: measured against **both** enemies | Against the **target seat** (+ the other hostile seat's army when it stands near the target, section 4.3) |
| E15 | `_pick_attack_row()`, `_enter_mid()` | The 1v1 lane: crown camp -> "an enemy building near the crown" -> MID (the crown) -> KEEP | Target rows toward the target seat (4.4); the crown row only if the 2v2 map keeps a central crown (20.D1) |
| E16 | `_drive_attack()` Stage.KEEP | `base_center(_enemy_team)` | `base_center(target_seat)` |
| E17 | `_next_hunt()` | Nearest remembered enemy building of any enemy: after one base, the group can wander to the other side of the map | Target seat's buildings first; the other seat's only within 45 m of the group |
| E18 | `_explore_points()` | Enemy keep, `natural_hall_spot(_enemy_team)`, the mirrored own slots | The target seat's keep, natural, rich and framed slots |
| E19 | `_rule_wizard()` | ATTACK goal `base_center(_enemy_team)`; crown rules assume the crown sits between the two keeps | Target seat; crown by 20.D1 |
| E20 | `_cast_check()` | Fog filter `int(u.team) != _enemy_team or visible`: a unit of another hostile seat **skips the fog check** (a map hack in 2v2) | Hostile side + visible |
| E21 | `_vessa_cast_check()` | Foes = `t == _enemy_team` only (a second enemy seat is never shot) | Hostile side |
| E22 | `_check_concede()` | `_level.surrender(team)` ends **the match**; any caravan or Bazaar blocks it forever (the stall) | Section 7 |
| E23 | `_scout_path()` | One fixed loop (`SCOUT_PATH` / `AIMapFill.SCOUT_PATH_RIVER`) | Per-seat loop from 20.D1 (or the fog grid only) |
| E24 | `_camp_alive()`, `_crown_ok()`, `crown_sealed_left()` | `_level.wardens` / `_level.crown`: one crown camp in the middle | Kept if 20.D1 keeps one Crown Isle; claimed by the council |
### 2.2 `scripts/world/skirmish.gd` (the level API the bot calls)
| # | Function | Assumption | Fix (20.D1 systems task) |
|---|---|---|---|
| E25 | `enemy_team_of()` | PLAYER <-> ENEMY | `hostile_seats(seat)`, `side_of(seat)` |
| E26 | `kingdom_of()`, `keep_of()`, `wizard_of()`, `start_position()` | Two fixed teams (`hero` / `shadow_hero`, `keep` / `shadow_keep`) | By seat |
| E27 | `base_center()` / `_mirror()`, `natural_hall_spot()`, `rich_hall_spot()`, `market_slot()`, `tower_slot()` | Point mirror of two sides | By seat (tables of the 2v2 map) |
| E28 | `node_of()` | `node_shadow_*` / `node_fire_*` | `node_<seat>_<suffix>` or a seat table |
| E29 | `bank_of()` | Returns the PLAYER or ENEMY bank | Returns the **side** (two seats share a bank); plus `home_seat_of(pos)` (3.1) |
| E30 | `surrender()` -> `_end_game(team != PLAYER)` | One loser ends the match | `eliminate_seat(seat, message)`; the match ends when a side has no seat left |
| E31 | `stats_of()` | `enemy_team_of(team)` for "killed" | Per seat, kills of any hostile seat |
### 2.3 `scripts/ai/ai_memory.gd`
| # | Function | Assumption | Fix |
|---|---|---|---|
| E32 | `see_unit()`, `see_building()`, `strength()`, `strength_near()`, `nearest_building()`, `soldier_mix()` | Entries have no owner: nothing can be split per hostile seat | Entry field `seat`; `strength_of_seat(seat)`, `nearest_building(..., seat := -1)`, `soldier_mix(seat := -1)` |
### 2.4 `scripts/ai/ai_trade.gd`
| # | Function | Assumption | Fix |
|---|---|---|---|
| E33 | `_init(team, enemy_team)`, `sense()` 10b "behind", `_routes()` far ratio | "Behind" = `seen_strength > 1.5 x own`: in 2v2 `seen_strength` holds both enemies, so every bot is "behind" most of the game (early Bazaar, near routes only) | Compare `own + ally army` with the hostile side's seen strength (4.3) |
| E34 | `exchange_tick()`, `_exchange_keep()`, `exchange_ready()` | Gold is kept for the next ware (+ 50) even at 0 workers: no crystals to rebuild (the stall, lead-status) | Recovery mode (section 7.2) |
### 2.5 `scripts/ai/ai_champions.gd`
| # | Function | Assumption | Fix |
|---|---|---|---|
| E35 | `_raid_target()` (B2) | Hall / workers `team == _enemy_team`, `base_center(_enemy_team)` | Hostile side; distance from **their own** keep (by seat) |
| E36 | `_weak_wizard()` (B3) | One enemy wizard ("Vessa") | Any hostile wizard |
| E37 | `_hall_spots()`, `_unseen_spot()` (B4) | The one enemy's natural + rich hall spots | The target seat's first, then the other hostile seat's |
| E38 | `chosen_tavern()` | `base_center / wizard_of / keep_of(team)` | By seat |
### 2.6 `scripts/ai/ai_mapfill.gd`
| # | Function | Assumption | Fix |
|---|---|---|---|
| E39 | `setup()`, `bank_of()` fallback | One `_enemy_base`; "nearer my base than theirs" | Side bank from the river; `home_seat_of(pos)` |
| E40 | `_camp_allowed()`, `_lair_allowed()` | "Own bank" camps: two allied seats (and the human) creep the **same** camps; the nest "nearer own than enemy base" | Home seat of the camp / lair (5.2 of this doc) + council claims |
| E41 | `sense()`, `point_safe()` | `capture_team == _enemy_team` | Capture side hostile |
| E42 | `attack_shrine()`, `_next_point()`, `_shrine_due()`, `_passing_point()`, `flag_candidates()` B8 | Points and shrines split by bank = own / enemy: both allied bots (and the human) go for the same ones | Council claims; the ally never takes a point the human is standing on |
| E43 | `attack_waypoint()` | The Crown Bridge nearest `_enemy_base`; the side pick by `_enemy_base` | Target seat's base |
| E44 | `SCOUT_PATH_RIVER` | The 1v1 loop over Millstone Bridge | Per-seat loop (20.D1) or fog grid |
### 2.7 Champions, Magpies, trackers
| # | File / function | Assumption | Fix |
|---|---|---|---|
| E45 | `champion_sense.gd` `refresh()` | Every unit not of `team` is an enemy: in seat encoding the **ally's army is hostile**, the ally's towers / keep count as danger and the ally's shops are refused; in side encoding the ally's buildings become "own" (patrol, rest) without anyone deciding it | Hostile = other side; allied units / buildings in their own lists (6.1) |
| E46 | `champion_sense.gd` `bank_of()`, `_refresh_enemy_home()` | `1 - team` and the point-mirror fallback `-home_point`: one enemy home | Hostile seats' homes; `home_seat_of()` |
| E47 | `champion_sense.gd` `for_team()`, `_update_party()` | One sense and one beast party per team; allied champions never count | Per seat; allied help counted (6.3) |
| E48 | `champion_brain.gd` `_camp_to_clear()` | `bank_of(pos) != champion.team`: two seats' Coin-Cutters race for the same T1 camps | Home seat of the camp |
| E49 | `thief_band.gd` `keep_position()`, `_is_home_area()` | The **first** keep of the team; a side with two keeps: the second base's home nodes count as remote and get raided at home | Keep of the victim **seat** |
| E50 | `thief_band.gd` `escort_strength()`, `spot_is_valid()` | Counts only the target team's units | Count the victim's **side** (an ally's army scares Magpies too) |
| E51 | `tracker_contract.gd` `_keep_position()`, `_plan_spots()`, `_caravans_of()` | Per team | Per seat |
### 2.8 `scripts/ai/ai_profile.gd`
| # | Field | Assumption | Fix |
|---|---|---|---|
| E52 | `attack_ratio`, `steal_points_ratio`, `far_route_ratio`, `malrik_join_strength`, B3's "Vessa" | Tuned against one `seen_strength` | Same numbers, measured per target seat / per side (4.3); new team knobs (section 9) |

## 3. What the AI needs from the level (hooks for 20.D1)
### 3.1 Seat API (names are proposals; 20.D1 / the lead freeze them)
| Call | Returns | 1v1 value |
|---|---|---|
| `level.seats() -> Array[int]` | Every seat in the match | `[0, 1]` |
| `level.side_of(seat) -> int` | 0 = the human's side, 1 = the other | seat |
| `level.seats_of_side(side) -> Array[int]` | | `[side]` |
| `level.hostile_seats(seat, alive_only := true) -> Array[int]` | Seats of the other side not yet out | `[1 - seat]` |
| `level.ally_seat(seat) -> int` | The teammate, -1 if none / out | -1 |
| `level.is_human(seat) -> bool` | | seat 0 |
| `level.seat_alive(seat) -> bool` | Not eliminated | |
| `level.eliminate_seat(seat, message := "")` | The seat is out: its buildings collapse, its units leave (A7 / Q3); the match ends when a side has no seat left | = today's `surrender()` |
| `keep_of(seat)`, `wizard_of(seat)`, `kingdom_of(seat)`, `base_center(seat)`, `node_of(seat, suffix)`, `natural_hall_spot(seat)`, `rich_hall_spot(seat)`, `market_slot(seat)`, `tower_slot(seat, id)`, `rush_slot(seat, id)`, `respawn_point(seat)` | As today, by seat | Same |
| `level.seat_frame(seat) -> Transform3D` | Maps a **Shadow-side 1v1 point** (the `ROWS` table) to this seat's world point (rotation + translation, or a reflection, as 20.D1 builds the 4 bases); every slot then passes `BuildGrid.check` as today | Identity (Shadow) / point mirror (Fire) |
| `level.home_seat_of(pos) -> int` | The seat nearest by path to `pos` (a precomputed quarter map, 20 m cells); **-1** in contested zones (the middle, the isle) | The bank's team |
| `level.lane_opponent(seat) -> int` | The hostile seat facing this one across the river | `1 - seat` |
| `level.shared_rally(side) -> Vector3` | A defensive point between the two bases of a side, on the way the enemy comes | - |
| `level.staging_point(seat, target_seat) -> Vector3` | 20-25 m before the target base on the attacker's approach (the crossing that attacker would use) | - |
| `level.scout_path(seat) -> Array[Vector3]` | The seat's fixed scout loop (optional: empty = fog grid only) | Today's loops |
| `Economy / EssenceBank / GoldBank / ChampionGuild / BountyBoard / Market .for_seat(seat)`, `ChampionSense.for_seat(seat)` | Per seat | `for_team` |
| Units / buildings: `seat: int` (owner) and the side (hostility, fog, capture); `Unit.is_enemy_of()` by side | | seat == team |
| `FogOfWar` per **side** (allied vision is free: `is_visible(side, pos)`) | | Today |
| Capture points: `owner_side` (what the ring shows) + `owner_seat` (who gets the income: the seat with the most counters at capture) | | `owner_team` |
| Friendly spells / auras (Wild Bloom, Rallying Cry, Mender, Frost Shell) treat allied units as friendly; damage never hits allies | | |

Until these exist the AI tasks after 20.A2 wait (section 12 order).
### 3.2 Why a seat frame and not new slot tables
The build order (`ROWS`, walls, rush slots H2 / P1 / C1, rally, anchor, scout loop) is tuned and tested on the Crown
Hollow Shadow base. The 2v2 map is "the same but 2x" (reused base pieces). If every 2v2 base is a copy of a 1v1 base
(rotated / moved / reflected), one `Transform3D` per seat keeps the whole build order: `_frame(p) = seat_frame(seat) * p`.
20.D1 gives the 4 frames; a slot a frame breaks (a river, a road) is overridden by an optional
`level.slot_override(seat, row_id) -> Vector3` (INF = none).

## 4. The enemy bots in 2v2
### 4.1 The side council (`AISideCouncil`, one per side, `scripts/ai/ai_council.gd`)
A `RefCounted` owned by a small node `AICouncil<side>` (child of the level, group `"ai_council"`), created by the first
Commander of that side (`AISideCouncil.for_side(level, side)`). Members: the side's seats; a **human** member is
represented by its observed army and its pings (the ally layer, section 5). It thinks **inside** its members' ticks
(no timer of its own): the first member to tick in a second refreshes it.
| Holds | Meaning |
|---|---|
| `plan` | The side's current push `{id, target_seat, members: {seat: stage}, staging: {seat: pos}, launch_by, started, joint}` or `{}` |
| `claims` | Camp / lair / point / shrine / expansion / scout-goal id -> `{seat, until}` (TTL 120 s, refreshed while the job runs) |
| `losses` | Trade roads made unsafe by any member (10d reads both members' losses) |
| `threats` | Per member base: intruder strength, home strength, time (for rule 1c) |
| `target_scores` | Per hostile seat, recomputed each second (4.2) |
| `rushers` | Seats that play the Rusher style this match (max 1 per side, 4.5) |

### 4.2 Target choice (who do we attack?)
Every bot keeps **one target seat**. It is re-picked **only at a launch** (never mid-attack) and whenever the current
target is out. Score for each living hostile seat `s` (all terms 0..1):
| Term | Formula | Weight (easy / normal / hard) |
|---|---|---|
| Near | `1 - clamp(path(own rally, base_center(s)) / 250, 0, 1)` (path length cached every 30 s) | 1.0 / 1.0 / 1.0 |
| Weak | `1 - seen(s) / max(seen(s) + seen(other), 1)`; `seen(x)` = `strength_of_seat(x)` in memory, floor 250 | 0.3 / 0.8 / 1.0 |
| Focus | 1 if the teammate's plan or running attack targets `s` | 0 / **0.8** / 1.5 (`focus_weight`) |
| Revenge | 1 if units of `s` hit own or teammate buildings / workers in the last 90 s | 0.5 / 0.5 / 0.3 |
| Lane | 1 if `s == lane_opponent(seat)` | 0.6 / 0.3 / 0.1 |
| Broken | 1 if `s` has no barracks seen alive and < 4 soldiers seen in 60 s (finish it) | 0 / 0.6 / 1.2 |
| Towers | `-0.1` per seen tower within 25 m of `base_center(s)` (max -0.4) | same |
| Human bias | 1 if `s` is the human (Q2) | **0** (option B: 0.5) |
Hysteresis: the current target is kept unless another scores **>= 1.3 x** (`target_stickiness`). Logged: `TARGET seat 0
(fire) near .78 weak .55 focus 1 -> 2.43 vs seat 2 1.61`. Easy picks the **lane opponent** unless it is out (no council
talk at all: easy bots feel like two separate 1v1 bots).

### 4.3 Threat evaluation (how strong is "the enemy" now)
| Use | 1v1 today | 2v2 |
|---|---|---|
| Rule 7 launch (alone) | `own >= attack_ratio x max(seen, 250)` | `own >= attack_ratio x max(seen(target) + 0.5 x near_other, 250)`; `near_other` = the other hostile seat's army strength seen within 60 m of the target base in the last 60 s |
| Rule 7 launch (joint, 4.4) | - | `0.9 x (own + teammate's group) >= attack_ratio x max(seen(target) + near_other, 250)` (0.9 = coordination loss) |
| Rule 2 retreat | `strength_near(group, 15 m)` | Same (any hostile seat; memory already holds both) |
| Rule 1 intruders | Own buildings | Same, intruders from any hostile seat |
| 10b "behind", 10d far ratio, 12a steal ratio | `seen_strength` vs `own_strength` | Side vs side: `seen(hostile side)` vs `own + teammate army` (the teammate's army is visible without fog; the human's too) |
| Rule 5 mix, rule 1b tells | Everything seen | Everything seen (both hostile seats); tells count per hostile seat |
`seen_strength` (read-only field) stays the sum of the hostile side (tests and logs keep working); new read-only
`seen_by_seat: Dictionary` (seat -> strength) is filled in `_update_memory()` in the same pass.

### 4.4 Joint attacks (the council plan)
| Step | Rule |
|---|---|
| Propose | A bot whose rule 7 would launch **alone**, or whose army reaches `joint_min_share` (0.6) of the alone threshold, with no plan running, posts `plan` = its target, `launch_by = now + sync_window`, staging points `level.staging_point(member, target)` |
| Join | The teammate joins if it is not defending, not already attacking (a running attack of its own is redirected to the plan target only if its group is within 60 m of its staging point), and has >= `min_attack_pop / 2` pop at its rally. Joined: its rally group walks to its staging point (`Stage.STAGE`, never attack-move at first: it arrives together) |
| Launch | When both groups are within 10 m of their staging points, or at `launch_by`: both `Stage.KEEP` toward `base_center(target)` (then HUNT as today). Hard: the two groups use **different crossings** when `staging_point` gives two (a pincer) and launch within 5 s of each other |
| Alone | Nobody joined by `launch_by`: the proposer launches alone **only** if the alone rule holds, else it cancels and waits 30 s |
| Abort | A member's base is intruded (rule 1): that member recalls (as today); the other continues if its own retreat rule allows, else retreats too. Plan over when both groups are home or dead |
| Log | `COUNCIL plan #3 -> seat 0 (fire), joint 12 + 9 units, str 1850 vs 1300, staging (24, 61) / (61, 24)` |
| Knob (easy / normal / hard) | `sync_window` **0 (never joint)** / **30 s** / 45 s; `joint_min_share` - / 0.6 / 0.5 |

### 4.5 Gang-up and fairness rules (so 2 bots against 1 human is still fun)
| Rule | Value |
|---|---|
| No double rush | `rushers` holds at most **1** seat per side: the `Random` style rolls per bot (25 %), and a second Rusher roll on the same side becomes Balanced (logged). A Rusher targets its **lane opponent** only |
| No early dog-pile | No joint plan on the same target before `no_joint_before` (**5:00**; hard 4:00), and never while the target's teammate is out (a 1v2 is already hard) unless the target has an army within 20 % of the joint group |
| Spread when idle | If one hostile seat has had **2 joint plans in a row**, the next plan needs a +0.3 score margin to pick it again (the other hostile seat gets visits too). Off on hard |
| No human bias | `human_bias` 0 (Q2). The enemy bots see the human exactly like the ally bot: through fog |
| Help your teammate (rule 1c) | A teammate's base is intruded, its home strength < **0.8 x** the intruders, the own base is calm, the path is < `help_team_radius` (120 m): send `help_team_share` of the rally army (easy **0**, normal **0.6**, hard **1.0**) attack-moving to the teammate's intruder; the wizard joins when HP >= 50 % and the distance is < 90 m. Ends when the teammate's defence is over or after 60 s. An attack group out is **not** recalled for a teammate (only for the own base) |
| Finishing | Hard: a "broken" seat (4.2) is finished by the nearer member only; the other keeps its target |

### 4.6 Expansions, camps and map fill with 4 players
| Topic | Rule |
|---|---|
| Expansions | Each seat builds **only on its own slots** (X1 natural, X2 rich from `seat_frame` / 20.D1 tables). Contested expansions in the middle (if 20.D1 adds any): council claim, the seat nearer by path first; the other skips it for 180 s |
| Camps and lairs | Each camp / lair has a **home seat** (`home_seat_of(camp)`). Rule 11a / 11e creep: own-home camps; home -1 (contested) only with a council claim; never a camp the teammate's army (or the human's) is within 25 m of, or claimed by the teammate. `creep_hollow` / `beast_far` read "home -1 / hostile home" instead of "the enemy bank" |
| Capture points (12a) | Order: own-home wells, own-home towers, then home -1, then hostile-home points when `steal_points_ratio` holds (side vs side). Council claim per point (one squad per point per side). A point already owned by the side is done (side ownership) |
| Shrines (12c) | A shrine on the own bank: the **council member nearer** it sends its squad; the other never goes. An awake hostile-bank shrine: rule 7's first row for the proposer of a plan only |
| Scouting (rule 6) | Fog is shared, so the side scouts once: **one scout out per side** (council lock); the fog-grid scout picks the nearest unexplored point of the **side** fog not claimed by the teammate's scout; the main scout (rule 13c) looks at the lane opponent first, then the other hostile seat |
| Rush defence (rule 1b) | Tells T1-T6 count per hostile seat; an alert on either member's base makes the council's other member send `help_team_share` to the mine rally of the alerted member (not below normal's 0.6 on an alert) |
| Trade (10d) | A road loss or an enemy group seen on a road by either member makes it unsafe for both (council `losses`); routes stay per seat |

## 5. The ally bot (seat 2: `AIAlly`, `scripts/ai/ai_ally.gd`)
A normal Commander (all rules 1-15 on its own seat) with `ally_of_human = true`; `AIAlly` (RefCounted, owned by the
Commander, like `AITrade`) adds the **L-rules** below. It never orders a human unit, never spends human resources, never
builds on a human slot, never places a bounty on the human's board.
### 5.1 `AllyChannel`: the ping contract (20.D2 designs the UI; this is what the AI reads and writes)
Node `AllyChannel` (child of the level, group `"ally_channel"`; the AI finds it with `get_first_node_in_group`; absent =
the ally layer runs on observed attacks only).
| Member | Contract |
|---|---|
| `ping(kind: StringName, pos: Vector3, from_seat: int, target: Node3D = null) -> String` | `""` or a refusal (`"Too many pings"`: max 3 per 5 s per seat). Kinds from the human: `&"attack"` (attack here / this target), `&"defend"` (defend here), `&"help"` ("Help me": at `pos`, default the human's wizard or army centre), `&"retreat"` (fall back), `&"cancel"` (drop my last ping) |
| Kinds from a bot to its side (shown to the human) | `&"attacking"` (I attack here), `&"need_help"` (my base needs help), `&"enemy_army"` (enemy army seen here), `&"enemy_expand"` (a new enemy hall), `&"on_my_way"` (answer), `&"cant"` (answer) |
| `signal pinged(p: Dictionary)` | `p` = `{id: int, kind, pos, target, from_seat, side, time, expires}` (TTL 60 s; `retreat` / `cancel` 10 s) |
| `active(side) -> Array[Dictionary]` | Living pings of a side, newest first |
| `answer(ping_id: int, from_seat: int, kind: StringName, text: String)` / `signal answered(ping_id, from_seat, kind, text)` | The ally's reply; the UI shows `text` as the ally wizard's line (portrait + subtitle, 3 s) |
| `note_command(seat)` / `last_command_time(seat) -> float` | Input calls `note_command(0)` on every human order (right-click, A-move, build, train, cast); the ally's idle test (L7) reads it |
Answer lines (original, English UI text, `<Name>` = the ally wizard's name): `On my way.` / `Right behind you.` / `Not yet:
my army is too small. Give me 30 seconds.` / `Too strong for us. Gather first.` / `Your base is under attack! Coming.` /
`Falling back.` / `I am attacking <kingdom>. Join me?` / `I need help at my base!` / `Enemy army near your base!`.
### 5.2 The L-rules (evaluated after rule 1 and 1b, before rule 7; at most one new group order per tick)
| # | Trigger | Action |
|---|---|---|
| **L1 Defend the human's base** | An enemy fighter within `ally_defend_radius` (28 m) of a human building, or a human building / worker hit by a hostile unit in the last 3 s (the ally connects to the human's `Building.damaged` like its own) | After `reaction_delay`: if the human's home strength (human soldiers within 25 m of the intruder + human towers + the human keep 150) < **1.0 x** the intruders' strength: `ally_defend_share` of the rally army (Supportive 1.0, Aggressive 0.5, Economic 0.6) + the wizard (HP >= 50 %, path < 90 m) attack-move to the intruder (`Stage.HELP`). Recalls its attack group when the human base is outnumbered **1.5 x** and the human army is not home (like rule 1). Own base intruded at the same time: the bigger intrusion wins (own base on ties). Answer `Your base is under attack! Coming.` |
| **L2 Help ping** | `help` ping (or `defend`) at `pos` | Like L1 at `pos` (also far from any base: the human's army in trouble), share **max(0.6, ally_defend_share)**; path < 160 m. Can't (army out and busy, or rally < 3 soldiers): the wizard alone if within 60 m, and `cant` `Not yet: ...`. Over when `pos` is calm 15 s, or 60 s |
| **L3 Attack ping** | `attack` ping at `pos` / on `target` | An attack group out within 80 m of `pos` with HP >= 60 % of launch: redirect it (`Stage.JOIN`). Else from the rally when pop >= `join_min_pop` (4) and >= 80 % of the army is at the rally; **joint** strength = ally group + human soldiers within 30 m of `pos` or walking toward it; go if joint >= **0.8 x** seen strength within 25 m of `pos` (Aggressive 0.6, Economic 1.0), else answer `Too strong for us. Gather first.` and re-check every 5 s for 45 s. Walks to 12 m **behind** the human's army (on the ally's side of it), then attack-moves `pos` / `target`. Answer `On my way.` within `reaction_delay` + 1 s |
| **L4 Follow the human's push** (no ping needed) | Human push detected: >= max(5, 40 % of the human's soldier pop) human soldiers are > 40 m from every human building **and** (within 40 m of a known enemy building / army, or on the hostile bank) for 6 s | With `follow_chance` (Aggressive 1.0, Supportive 0.9, Economic 0.6, rolled once per push): as L3 with `pos` = the nearest known enemy building ahead of the human group within 60 m, else the group centre + 15 m along its heading. Answer `Right behind you.` |
| **L5 Retreat together** | `retreat` ping, or the human's pushing group turns home (its centre moves 15 m back toward the human base) while the ally is in `Stage.JOIN` | The ally group retreats to its rally (rule 2 machinery); answer `Falling back.` |
| **L6 Share scouting and news** | Always (fog is shared) | Rule 6 scouts the side's unexplored cells (never where a lone human unit is within 30 m of the goal). Bot pings: `enemy_army` when a hostile army >= 500 strength is seen within 60 m of a human building moving closer (max once per 60 s); `enemy_expand` when a new hostile hall is seen; `attacking` at every own launch; `need_help` when its own base is outnumbered 1.5 x |
| **L7 Idle human** | No `note_command(0)` for 120 s, **or** after 8:00 the human has < 3 soldiers and no push for 180 s | The ally leads: its own rule 7 (target from 4.2 with the council), pings `attacking` + `I am attacking <kingdom>. Join me?`; Supportive leaves an `idle_guard` of 3 soldiers at the human's keep while the human has < 4 soldiers home. Ends at the next human command |
| **L8 The human's wizard is dead** | Until it respawns | The ally's wizard stays on the side's half (no crown run, no creep sortie farther than 40 m from a side building); L1 share +0.2; if the human's army is pushing without its wizard, L4 still applies (the army needs help more) |
| **L9 The human is out** | `seat_alive(0)` false | The ally plays 1v2 as a normal bot with the **Survivor** overlay: `attack_ratio` +0.3, S1 / S2 towers at once, trade and Bazaar at `trade_start` - 60 s, joins nothing, concedes by section 7 (then the match ends) |
| L-never | Always | Never: a hall on a human slot or within 20 m of a human building; a capture squad to a point with a human unit within 15 m (or a human ping on it); a creep of a camp whose home seat is 0 or with human units within 25 m in 20 s; the crown while the human wizard is within 40 m of it (the human first); picking up drops within 15 m of the human wizard or human soldiers who fought there; a bounty on a target the human already flagged |
### 5.3 Personalities (lobby choice, 20.D2; an overlay like `style`, applied after the kingdom and difficulty profiles)
| Knob | **Supportive** (default, Q1) | Aggressive | Economic |
|---|---|---|---|
| Feel | "Covers you": holds between both bases, answers everything | "Goes first": pushes, follows every push | "Builds up": expands and trades, arrives late but big |
| Rally | `level.shared_rally(side)` | Own rally | Own rally |
| `ally_defend_share` (L1) | 1.0 | 0.5 | 0.6 |
| `ally_defend_radius` | 34 | 28 | 28 |
| `follow_chance` (L4) | 0.9 | 1.0 | 0.6 |
| L3 joint ratio | 0.8 | 0.6 | 1.0 |
| `join_min_pop` | 4 | 3 | 6 |
| Own attacks (rule 7) | Only when L7 (idle human), or own >= 1.5 x need | As today | Only when capped or own >= 1.3 x need |
| `attack_ratio` / `min_attack_pop` | +0.2 / +0 | -0.1 / -1 | +0.2 / +4 |
| Economy | As the kingdom profile | Workers -1 until 6:00 | `expand_time` -45 s, X2 at 7:30, `trade_start` -60 s, `caravan_target` +1 |
| Champions (`champion_order`) | Oathwall, Mender first | Coin-Cutter first | Wayfinder first |
| `idle_guard` (L7) | 3 | 0 | 2 |
| Random | Picks one of the three at 0:00 (match rng, logged) | | |
Difficulty still sets reaction, precision and economy (an easy Supportive ally answers in 4 s and arrives smaller).

## 6. Champions, trade, beasts and critters with allies
### 6.1 Champions (`champion_sense.gd`, `champion_brain.gd`, `ai_champions.gd`)
| Rule | Value |
|---|---|
| Hostile | Other **side** only. Allied units are never targets, never "danger"; allied towers / keeps never count in `structures` danger |
| Allied lists | `ally_buildings`, `ally_soldiers` (read-only): R4 "join a fight" also fires when an **allied** unit / building within the engage radius is hit (champions help the teammate like a neighbour's army would); Oathwall patrol and home rest stay **own** buildings only; allied shops are usable (items.md 12 m rule, any side shop) |
| Bounties | Boards are per seat. The bot never places a Hunt flag on a target that already carries a flag of its **teammate** (`BountyBoard.for_seat(ally).bounty_on(t)`): no double essence on one kill. Its champions score a flagged target of the ally at **x0** (no pay for them) but still fight it through R4 |
| B2 / B3 / B4 | B2 raid: hostile halls and workers far from **their own** keep; B3: any hostile wizard; B4: the target seat's natural / rich first |
| Coin-Cutter Raid | Hostile workers only (never an ally's), T1 camps of its **home seat** (E48) |
| Beast party (6.3 of `champions.md`) | The party stays per seat (one brain decides), but allied champions already attacking the same beast within 15 m add **50 %** of their power to the start / abort checks (they help, uncoordinated). Kill credit: the killing blow's seat (as today) |
### 6.2 Trade and Magpies
| Rule | Value |
|---|---|
| Caravans | Per seat. Hostility by side: nobody auto-attacks an allied caravan; loot sacks go to the picker's seat |
| "Held post" (4.3 of `market-trade.md`) | Held by the **hostile side** |
| Magpies | Target a **seat's** roads and remote nodes; home area = 30 m from **that seat's** keep (E49); escort strength counts the victim's **side** (E50) |
| Hunters | Contracts per seat; Outriders escort own caravans only; Sweep walks own spots only |
| 10j defend | A bot's own caravan hit near an own building = intrusion (unchanged); near an **allied** building = the ally bot's L1 / the enemy teammate's rule 1c |
### 6.3 Beasts and critters
| Rule | Value |
|---|---|
| Beasts | Unchanged: they fight combatants of any side. Creep 11e by home seat (4.6); the council claim stops both bots of a side sending armies to one beast |
| Hunt flags on beasts (B11) | Not when the teammate already has one on that beast |
| Game critters | Unchanged (normal ignores; hard's returning squad may shoot a deer within 10 m) |
| Drops | Items lie on the ground as today; the ally's wizard leaves drops near the human's wizard / army to the human (L-never) |

## 7. Concede, defeat and the stall fix
### 7.1 The stall (lead-status CI triage 16:45, `test_2_a1` no winner in 1500 s)
1. `commander.gd` `_check_concede()`: returns early while **any caravan or a Bazaar** stands, even at 0 workers and 0
   soldiers, so a broken bot never concedes.
2. `ai_trade.gd` `exchange_tick()` / `_exchange_keep()`: keeps `gold_exchange_above` **and** the next ware's price + 50,
   so at 0 workers the gold waits for wares instead of becoming crystals for workers.
3. Fire at the pop cap (12 workers + 6 caravans) cannot build the army to finish.
4. `_can_spend()`: the 20 s rule lets 2 trainings through in 2 s under the hire reserve (easy hire slips to 10-11 min).
In 2v2 this is worse: a side loses only when **both** seats are out, so one stalled bot keeps a lost side alive forever.
### 7.2 The fix (task 20.A2, safe for the 1v1 now)
| # | Where | Change |
|---|---|---|
| F1 | `AITrade` new `recovering: bool` (set by the Commander each tick) | **Recovery** = 0 workers, or (workers < 3 and crystals < worker cost + 50) while a keep or a barracks stands. While recovering: `_exchange_keep()` returns **0** (no ware reserve, no `gold_exchange_above`), the exchange goes to **crystals** only, `exchange_ready()` ignores `_bought`; `_wares_rule` and Outriders / Sweep pause; `_queue_caravan()` pauses; the keep queues workers first (rule 3 depth 2). Log `RECOVERY: 0 workers, exchanging 300 gold -> crystals` |
| F2 | `_check_concede()` | Trade blocks a concede **only if it can still pay for a comeback**: a completed Bazaar **and** (gold >= 100, or >= 60 gold earned by trips in the last 120 s); `GoldBank.earned_since(t)` (systems hook, else count `trips` in `TradeNetwork`). Plus a **hard stop**: 0 workers, 0 soldiers, 0 units queued for **150 s** -> concede whatever stands |
| F3 | `_check_concede()` target | `level.eliminate_seat(seat, line)` (1v1: = `surrender(team)`); the concede line is shown to all seats |
| F4 | `AITrade.caravan_target()` | Pop-capped: when `pop_used >= pop_cap - 2` and soldier pop < **45 %** of `pop_cap`, the target is `max(2, target - 2)` (no new caravans; living ones are never killed) |
| F5 | `_can_spend()` | The 20 s pass-through is granted once: `_starve_since = _now` is set when the unit is **queued** (`queue_unit` returned `""`), not when `_can_spend` answers true; the champion hire reserve counts in `_pending_cost` for that check |
| F6 | 2v2 only, level rule (20.D1) | A seat with no keep and no barracks for **120 s** is out (sites and houses alone cannot win or build), so a side cannot hide behind a lone house |
Done-when for F1-F5 is in 12 (20.A2): `test_2_a1_bot_vs_bot` ends with a winner in < 1500 s in 10 / 10 runs.
### 7.3 A bot gives up in 2v2 (Q3, recommended "crumble")
`eliminate_seat(seat)`: its buildings collapse (no rubble loot), its units, champions and caravans leave the map
(`leave_map()`), its bounties refund to nobody; message `<Name> has fallen. <Kingdom> is out of the war.` The teammate
switches to **Survivor** knobs (L9 for the ally; enemy bots: `attack_ratio` +0.3, towers now) and the council keeps one
member.

## 8. Performance with 4 seats (the 2x-unit budget)
Today (`ai.md`): one think tick < 0.3 ms at 200 units, 1 Hz on normal; perf quiet 100 units ~6-7 ms, 200 units ~13 ms per
frame. A 2v2 peak is ~2x units (4 seats x 40-60 pop + caravans + champions + creatures ~ **330-400**). The unit
simulation dominates the frame: **20.D1 must decide the 2v2 pop cap** (e.g. 40 per seat) against the perf test; the AI's
own budget is below.
| Item | Rule / budget |
|---|---|
| `AIWorldCache` (new, one per level, group `"ai_world_cache"`) | Refreshed at most **once per physics frame**, lazily on the first ask: one pass over `"units"` and `"buildings"` into per-seat lists (workers, soldiers, champions, caravans, wizard, buildings, barracks) and a **20 m spatial hash of fighters per side**. Every Commander, `AIAlly`, the council (and later `ChampionSense`) read it; nobody else loops the groups |
| `Commander._scan()` | Own lists = the cache's seat lists (O(own)); hostile = the cache's other-side lists filtered by fog (O(hostile)); no second loop |
| `_cast_check()` / `_vessa_cast_check()` (every 0.5 s) | Read the spatial hash around the wizard (12-16 m), not all `"units"` |
| Staggering | Timer offset = `seat x decision_interval / 4` (normal: 0, 0.25, 0.5, 0.75 s): never two Commanders on one frame; cast timers offset by 0.125 s per seat |
| Council | Inside members' ticks, O(seats); path lengths to each hostile base cached **30 s** (<= 2 `map_get_path` per bot per 30 s) |
| Memory | Per-seat strengths summed in the same `_update_memory()` pass; `forget()` unchanged |
| Budgets (quiet machine, 400 units, all systems on) | One Commander tick incl. ally / council **<= 0.45 ms** (median <= 0.25 ms); AI total (3-4 Commanders + 4 senses + brains + council + cache) **<= 0.6 ms / frame** average; no frame with > **1.5 ms** of AI |
| Logs | `tick_usec_max`, `rule_usec` keep working; new keys for the ally (22) and council (23) steps |

## 9. Knobs (new `AIProfile` fields; the difficulty `.tres` files get them, 20.A8)
| Knob | Easy | Normal | Hard | Section |
|---|---|---|---|---|
| `focus_weight` | 0 | **0.8** | 1.5 | 4.2 |
| `weak_weight` / `lane_weight` / `broken_weight` | 0.3 / 0.6 / 0 | **0.8 / 0.3 / 0.6** | 1.0 / 0.1 / 1.2 | 4.2 |
| `human_bias` | 0 | **0** | 0 | 4.2, Q2 |
| `target_stickiness` | 1.3 | **1.3** | 1.3 | 4.2 |
| `sync_window` / `joint_min_share` | 0 / - | **30 / 0.6** | 45 / 0.5 | 4.4 |
| `no_joint_before` | - | **300** | 240 | 4.5 |
| `spread_after` (joint plans on one seat in a row) | - | **2** | off | 4.5 |
| `help_team_share` / `help_team_radius` | 0 / - | **0.6 / 120** | 1.0 / 140 | 4.5 |
| `max_rushers_per_side` | 1 | **1** | 1 | 4.5 |
| `ally_personality` | `&"supportive"` / `&"aggressive"` / `&"economic"` / `&"random"` (lobby) | | | 5.3 |
| `ally_defend_share`, `ally_defend_radius`, `follow_chance`, `join_min_pop`, `join_ratio`, `idle_guard` | From the personality | | | 5.3 |
| `idle_command_time` / `idle_push_time` | 120 / 180 | **120 / 180** | 120 / 180 | L7 |
| `survivor_attack_add` | 0.3 | **0.3** | 0.3 | 7.3 |
`AIProfile.apply_ally_personality(p, personality)` runs after `apply_style()`; the enemy bots never call it.

## 10. Test plan (harness 20.A7 `tests/test_20_a7.gd`; runs by the lead in the CI copy)
All normal unless stated; cap **32:00** (`--fixed-fps 60 --quit-after 118000`), one process per run, up to **4 in parallel**
(4 bots per game). Seat 0 is driven by the harness (never a real human).
### 10.1 Flags
| Flag | Effect |
|---|---|
| `--mode=2v2` | The 2v2 map and rules (20.D1) |
| `--seats=fire,nature:shadow,ice` | Kingdoms: side 0 = seat 0, seat 2; side 1 = seat 1, seat 3 |
| `--human=bot` / `proxy` / `passive` | Seat 0 = a plain council bot (no pings) / **HumanProxy** (a normal bot that also pings like a human: `attack` at each launch target, `help` when its base is outnumbered, `retreat` when it retreats) / does nothing (idle human) |
| `--ally=on` / `off` | Seat 2 runs the ally layer (default on when `--human` is proxy / passive) |
| `--personality=supportive,aggressive,economic,random` | Ally personality |
| `--difficulty=seat1:hard,seat3:easy` / `--style=seat1:rusher` | Per seat (as 16.A3) |
| `--no-trade`, `--no-champions`, `--no-mapfill`, `--no-research`, `--no-rush-defense`, `--no-bell` | As today, for every seat |
| `--no-council` | Each bot plays alone (easy-style targeting, no joint plans, no claims, no rule 1c) |
| `--no-pings` | AllyChannel absent (ally = observed pushes only) |
### 10.2 What each run logs (CSV row + RUN line)
Winner side, end time, per seat: kingdom, difficulty, style, personality, **out time and reason** (buildings / concede /
F6), army pop at 5 / 10 / 15 / 20, crystals gathered at 5 / 10 / 15, workers at 5 / 10; enemy bots: target picks by seat
(counts), joint plans (count, joined, launched alone, aborted), first joint time, human-target share; ally: pings
received per kind, **ping -> first order** and **ping -> arrival** seconds, L1 events (intruders, response time, human
buildings lost during them), L4 follows, L7 minutes; **never-rules counters** (ally halls near human buildings, squads on
human-held circles, creeps of human-home camps, crown with the human near, drops taken near the human: all must be 0);
**stall detector** (seconds any seat spent with 0 workers + 0 soldiers without being out); AI ms (median, max per
Commander, cache).
### 10.3 Rounds
| Round | What | Runs | Pass |
|---|---|---|---|
| 0 Smoke | Everything on, `--human=bot`, the 3 four-kingdom splits x 2 | **6** | 0 script errors; every run ends before 32:00; stall detector 0 |
| A Fairness (symmetric) | `--human=bot --ally=off`: the 3 splits ({F,N} v {S,I}, {F,S} v {N,I}, {F,I} v {S,N}) x both side orders x **8**, plus 2 mirror comps ({F,N} v {F,N}, {S,I} v {S,I}) x 8 | 48 + 16 = **64** | Each split **45-55 %** target (pass band 35-65 % at N = 16); side 0 vs side 1 over all 64: 43-57 %; **median length 18:00-24:00**; <= 10 % no winner at 32:00; no game before 9:00 |
| B Ally layer | `--human=proxy`, each personality x the 3 splits x 4 | **36** | Side 0 wins **45-55 %** overall (the ally layer does not weaken the player's side; band 38-62 %); L3 ping -> first order <= `reaction_delay` + 2 s in >= 90 %; L1 response (intrusion -> first ally order) <= 5 s normal; never-rules counters **0** |
| C Idle human | `--human=passive`, Supportive / Economic x 3 splits x 2 | **12** | Side 0 may lose, but median length >= **14:00**; the ally attacks (L7) in every run; the human's base is defended in >= 80 % of intrusions before 10:00 |
| D Toggles | `--human=bot`: 3 splits x 1 x each of `--no-trade`, `--no-champions`, `--no-mapfill`, `--no-council`, all four off | **15** | No toggle moves a split outside 30-70 %; `--no-council`: the bots still end games (stall 0); median length with everything on >= all-off + 2:00 |
| E Gang-up | Round A logs + 12 runs `--human=proxy` with `--style=seat1:random,seat3:random` | **12** | Human-target share of enemy picks **40-60 %**; no joint plan on one seat before 5:00; never 2 Rushers on one side; the human seat is out before 10:00 in <= 10 % |
| F Difficulty mix | Enemy (hard, easy) vs (normal, normal); enemy (hard, hard) vs `--human=proxy` + Supportive normal | 6 + 6 = **12** | Mixed side 40-60 %; hard-hard beats proxy + normal ally >= 60 % |
| Perf | Perf test 2v2: 4 Commanders, 400 units, river, camps, 8 beasts, trade, 12 champions | 1 | `PERF OK` at 20.D1's 2v2 budget; AI budget of section 8 |
| Stall | 10 runs of `test_2_a1_bot_vs_bot` (1v1) after 20.A2 | 10 | A winner in < 1500 s in 10 / 10 |
Total ~170 runs; ~4-6 min each at 4 in parallel: ~3-4 hours per full pass. Re-runs repeat only the failing round.
Knob ladder when a target fails: side 1 (enemy council) > 55 % in Round B -> `focus_weight` 0.8 -> 0.6, then `sync_window`
30 -> 20, then `help_team_share` 0.6 -> 0.4; side 0 > 55 % -> the reverse; games too long -> `survivor_attack_add` 0.3 ->
0.2 and F6 120 -> 90 s; too short -> `no_joint_before` +60 s.

## 11. Proposed contracts (the lead freezes them in `CLAUDE.md`: 20.L1)
- Phase-1 rule as in steps 9-16: never use another step-20 agent's new `class_name` as a static type; reach it with
  `load()` guarded by `ResourceLoader.exists`, groups, `has_method()`, `get()`.
- **Commander**: `@export var seat := -1` (-1 = `team`, the 1v1 behaviour), `@export var ally_of_human := false`; read-only
  `target_seat`, `seen_by_seat`, `ally_intent: String` (for the ally panel of 20.D2: `"Defending your base"`,
  `"Attacking with you"`, `"Holding"`, `"Expanding"`, `"Attacking <kingdom>"`), `council: AISideCouncil`; `for_seat(level,
  seat)`. New stages `STAGE`, `JOIN`, `HELP`.
- **AISideCouncil** (`scripts/ai/ai_council.gd`): `for_side(level, side)`, `plan`, `claim(id, seat, ttl) -> bool`,
  `claimed_by(id) -> int`, `note_loss(post)`, `target_scores`, `rushers`; group `"ai_council"` on its holder node.
- **AIAlly** (`scripts/ai/ai_ally.gd`), **AIWorldCache** (`scripts/ai/ai_world_cache.gd`, group `"ai_world_cache"`,
  `for_level(level)`, `seat_units(seat, kind)`, `seat_buildings(seat)`, `fighters_near(side, pos, r)`), **HumanProxy**
  (`tests/human_proxy.gd`).
- **AllyChannel** (5.1): UI / systems own the node (20.D2's build task); the AI only calls the listed members.
- **AIMemory**: entries carry `seat`; `strength_of_seat(seat)`, `nearest_building(pos, max, kind, skip, seat := -1)`.
- **Level (20.D1)**: the seat API of 3.1, `eliminate_seat()`, F6, `GoldBank.earned_since(t)` (F2).
- **Ownership**: `scripts/ai/*` (+ `data/ai/*.tres`, `tests/test_20_a7.gd`, `tests/human_proxy.gd`) = ai-coder;
  `skirmish.gd` / level seat API = systems (20.D1's tasks); `AllyChannel` = ui / systems (20.D2's tasks).

## 12. Task list (step 20 AI; build after 20.D1's seat systems task, except 20.A2)
**Order:** 20.A2 now (1v1 fix) -> [20.D1 seat API built] -> 20.A6 -> 20.A1 -> 20.A3 and 20.A5 in parallel (different
files) -> 20.A4 + 20.A8 (after `AllyChannel` exists, or with `--no-pings` first) -> 20.A7 (harness, can start with 20.A3)
-> lead rounds (20.L*), then the game-designer's balance pass (20.D4).
| Id | Agent | Task | Files | Done when |
|---|---|---|---|---|
| 20.A2 | ai-coder | Stall fix F1-F5 (section 7.2), 1v1 first; F3 calls `eliminate_seat` when it exists, else `surrender` | `scripts/ai/commander.gd`, `scripts/ai/ai_trade.gd` | Test: a bot at 0 workers with a Bazaar, 3 caravans and 600 gold exchanges to crystals within 2 ticks and queues a worker; with 0 workers, 0 soldiers and a Bazaar but no trips for 120 s it concedes; 0 workers + 0 soldiers + 0 queued for 150 s concedes whatever stands; the 20 s rule lets exactly one unit through per 20 s under a hire reserve; `test_2_a1_bot_vs_bot` has a winner < 1500 s in 10 / 10 runs; `PERF OK` |
| 20.A6 | ai-coder | `AIWorldCache` (per-frame per-seat lists + side fighter hash), staggered timers, cast checks on the hash | `scripts/ai/ai_world_cache.gd` (new), `commander.gd` | 1v1 unchanged (smoke `victory=true`, `test_2_a1` logs identical decisions for a fixed seed); one cache refresh per frame with 3 Commanders asking (counter); think tick median <= 0.25 ms at 400 units in the 2v2 perf test |
| 20.A1 [H] | ai-coder | Seat refactor: E1-E24 and E32 (seat, side, hostile seats, `seat_frame`, per-seat level calls, memory owner, `seen_by_seat`, threat of 4.3, target seat in stages KEEP / HUNT / explore / wizard, cast fog filter, concede via `eliminate_seat`) | `commander.gd`, `ai_memory.gd`, `ai_profile.gd` | 1v1: all existing AI tests pass unchanged (`test_2_a1*`, 9.C9, 10.A3, 12.A1, 16.A*); 2v2 smoke with 4 plain bots (no council): every seat builds its H1 at its framed slot, no bot orders a unit of another seat (assert), both hostile seats enter memory, a Vessa bot fireballs units of both hostile seats, a seat's concede removes only that seat; 0 script errors |
| 20.A3 [H] | ai-coder | `AISideCouncil`: target score 4.2, threat 4.3, joint plans 4.4, gang-up rules 4.5, rule 1c, claims (camps, points, shrines, expansions, scout lock), rush roll (max 1 per side), shared road losses | `scripts/ai/ai_council.gd` (new), `commander.gd` | Test: two normal enemy bots with a passive side 0: first joint plan after 5:00, both groups at their staging points within 10 s of each other (hard: two crossings), launch logged with joint strength; a target with 3 towers loses to an equal target without towers; rule 1c sends 60 % of the rally to the intruded teammate within `reaction_delay` + 2 s; two bots never creep the same camp or send squads to the same point; one scout per side; with both styles `random` and a forced 25 % roll twice, only one Rusher |
| 20.A5 | ai-coder | Allies in champions / trade / map fill: E33-E51 (hostile = other side, ally lists, no double flags, party help, home-seat camps and points, Magpie home by seat, escort by side, trackers by seat, side-vs-side ratios) | `champion_sense.gd`, `champion_brain.gd`, `ai_champions.gd`, `ai_trade.gd`, `ai_mapfill.gd`, `thief_band.gd`, `tracker_contract.gd` | Test: a champion never attacks or fears an allied unit / tower, joins a fight when an allied building 10 m away is hit, buys at an allied shop; a Hunt flag is never placed on a target the teammate flagged; an allied champion hitting a beast adds 50 % power to the party check; Magpies never raid a node 25 m from the second keep of a side; a caravan with an allied army 8 m away is not struck; 1v1 tests unchanged |
| 20.A4 [H] | ai-coder | `AIAlly` L1-L9 + never-rules, `AllyChannel` reader / answers / bot pings, `ally_intent`, human push detection, shared rally | `scripts/ai/ai_ally.gd` (new), `commander.gd` | Test (HumanProxy seat 0): an `attack` ping with 8 ally soldiers at the rally -> an answer and the first ally order within `reaction_delay` + 1 s, the group stops 12 m behind the human army; `help` ping 100 m away -> 60 %+ of the rally goes (Supportive 100 %); an intrusion at the human base with no human army home -> ally defenders within 5 s; a human push of 6 soldiers crossing the river -> ally follows (Aggressive always); idle 120 s -> the ally pings `attacking` and launches; human wizard dead -> no crown run; human out -> Survivor knobs logged; never-rules counters 0 over 3 full games |
| 20.A8 | ai-coder | Knobs of section 9 in `AIProfile` + every `data/ai/*.tres`; `apply_ally_personality()` + `random`; per-seat difficulty / style from the lobby (20.D2) or harness | `ai_profile.gd`, `data/ai/*.tres` | Loading every profile at each difficulty gives section 9's values; personality overlays change only their knobs (test lists the diff); 1v1 profiles unchanged |
| 20.A7 | ai-coder | Harness: flags 10.1, `HumanProxy`, CSV 10.2, round presets (`--round=A`), summary tables (side / split win rates, medians, target shares, ping response times, never-counters, stall detector) | `tests/test_20_a7.gd` (new), `tests/human_proxy.gd` (new) | `--round=0` runs 6 games and prints the table; a 1-run smoke of every round works headless; the stall detector and never-counters print per run |
| 20.L* | lead | Freeze section 11 (20.L1); run rounds 0-F + perf + stall (10.3); send results to 20.D4 | `CLAUDE.md`, `tests/`, `docs/plan/` | Rounds logged |
| 20.D4 | game-designer | Balance from the logs with the knob ladder (10.3), results table here, `ai.md` rule 1c / L-rules / council summary | `docs/design/` | Section 10.3 passes, or the next knobs are written |
Playtest (user): 2v2 with a Supportive ally on normal: ping an attack, call "Help me" during an enemy push, go idle for 3
minutes, lose your wizard once. Then an Aggressive ally, then hard enemies.

## 13. Hooks this doc needs from the parallel designers
### From 20.D1 (`map-2v2.md`)
1. The seat / side encoding and the seat API of 3.1 (`seat_frame`, `home_seat_of`, `lane_opponent`, `shared_rally`,
   `staging_point`, per-seat slot tables incl. rush slots H2 / P1 / C1 and the mine rally).
2. The defeat rule (A3), `eliminate_seat()` and F6; what happens to a crumbled seat's points (they stay the side's).
3. The 2v2 pop cap vs the perf budget (section 8), and the unit total the perf test uses.
4. Whether the map keeps **one** central Crown Isle (crown camp, crown) and which camps / lairs / points / shrines are
   contested (home seat -1).
5. Capture point income per seat (`owner_seat`) and allied vision = side fog.
6. Allied targeting and spells: nothing auto-attacks allies; friendly spells / auras include allies.
### From 20.D2 (`ui-2v2.md`)
1. The ping UI calling `AllyChannel.ping()` with the 5 human kinds of 5.1 (and the minimap / world markers for the bot
   kinds), `note_command(0)` on every human order.
2. Where the ally's answers show (portrait line), and the ally panel reading `Commander.ally_intent`.
3. Lobby: per-seat kingdom, difficulty, style (Balanced / Rusher / Random) and the ally's personality (Supportive /
   Aggressive / Economic / Random; default Q1).

## 14. Questions for the user
1. **The ally bot's default personality?** (a) **Supportive** (recommended: covers your base, answers every ping, attacks
   with you rather than alone) · (b) Aggressive (pushes first, follows every attack) · (c) Economic (expands and trades,
   arrives late but big) · (d) Random each game. All four stay choosable in the lobby.
2. **Should the two enemy bots gang up on you?** (a) **Fair** (recommended: they choose targets by distance, weakness and
   teamwork, with no preference for the human; no double attack on one player before 5:00; never two rushers) · (b) Human
   focus (they prefer attacking you: harder) · (c) Lanes (each enemy mostly fights the player across from it: calmer).
3. **When a bot gives up in 2v2 while its teammate still fights?** (a) **Its kingdom crumbles** (recommended: buildings
   collapse, units leave, the teammate plays on alone) · (b) Its remaining units and resources go to its teammate ·
   (c) Bots never give up in 2v2 (they fight to the last building; games get longer).

## Done when (step 20 AI)
- [ ] 20.A2: the stall is gone in the 1v1 (`test_2_a1` 10 / 10 with a winner) and no seat stalls in any 2v2 round.
- [ ] 20.A1 / 20.A5: every E1-E52 assumption is replaced; all 1v1 AI tests still pass; no bot ever orders another seat's unit.
- [ ] 20.A3: enemy bots pick targets by score, sync joint pushes, follow the gang-up rules and help each other (Rounds A, E).
- [ ] 20.A4 / 20.A8: the ally answers pings in time, defends the human's base, follows pushes, never steals, and plays the
  idle / dead-wizard / eliminated cases (Rounds B, C); 3 personalities + Random.
- [ ] Rounds A-F pass (sides 45-55 %, median 18:00-24:00, <= 10 % no winner at 32:00); AI budget of section 8 and
  `PERF OK` at the 2v2 budget; 0 script errors.

> **Lead note (2026-09-26):** the team encoding is frozen in map-2v2.md section 4: team = seat (Team enum + ALLY = 3, ENEMY_2 = 4), sides from a static Teams class. This spec's seats 2 / 3 are team values 3 / 4; its for_seat is the existing for_team.
