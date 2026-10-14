# For ai-coder (from systems-coder, wave 2 session B, task 2.S3)

The 1v1 is `scenes/skirmish.tscn`; its root is `Skirmish` (`scripts/world/skirmish.gd`, extends `main.gd`).
The bot plays `Unit.Team.ENEMY` (Shadow) with public calls only. Reach the level as `get_tree().current_scene`
(or pass it in). Everything below works for either team, so the same bot can play Fire later.

## Map facts (`skirmish-1v1.md`)
- `level.SHADOW_START` `(36, -36)`, `level.PLAYER_START` `(-36, 36)`, crown / camp centre `level.ARTIFACT_POS` =
  `level.MID_CAMP` = `(0, 0)`. `Skirmish.enemy_team_of(team)`.
- `level.start_position(team)`, `level.base_center(team)` (keep spot `(43, -43)` for Shadow, also after it falls).
- `level.keep_of(team) -> Keep` (living or null), `level.shadow_keep`, `level.keep`.
- `level.home_nodes(team) -> Array[CrystalNode]` (a, b; only those with crystals left),
  `level.natural_node(team)` (`node_shadow_mid` at `(16, -6)`), `level.node_of(team, "a" | "b" | "mid")`,
  `level.crystal_nodes[&"node_shadow_a"]`...
- `level.natural_hall_spot(team)`: `(23, -9)` for Shadow, where the spec's forward Gloom Hall goes.
- `level.wizard_of(team) -> Wizard` (Malrik = `level.shadow_hero`; dead wizards stay in the tree: test `is_alive()`).
- `level.workers_of(team) -> Array[Unit]` (living; they have `command_gather` / `command_build`).
- `level.wardens` (4 neutral Ruin Wardens), `level.crown` (`EmberCrown`: `is_available()`, `is_worn()`, `wearer`,
  `global_position` = where it lies or who wears it; signals `claimed`, `lost`, `dropped`).

## Economy and building
- `Economy.for_team(team)`: `crystals`, `pop_used`, `pop_cap`, `can_afford`, `gathered_total`.
- `level.build_grid.find_spot(type, near, team, max_rings = 12) -> Vector3` (INF if none; ignores only the crystal
  rule), then `level.build_grid.place(type, spot, team, workers) -> Building` (null: `build_grid.last_reason`).
  Types: `BuildingType.find("shadow_barracks")` / `"shadow_hovel"` / `"shadow_tower"`, or
  `BuildingType.buildable_for(&"shadow")`. `Building.count_of(type_id, team)`, `Building.for_team(team)`.
- Training: keep / barracks `queue_unit(UnitType.find("gloom_thrall"))`, `can_queue`, `queue`, `set_rally_node(node)`.
  A barracks signals `unit_trained(unit)` for every unit it (or the keep) trains.
- Drop-off: workers deliver to the nearest **completed** keep or barracks (`Building.nearest_drop_off(team, pos)`,
  `is_drop_off()`), so a finished hall next to `natural_node` makes that node efficient.

## Match state
- `level.match_started`, `level.game_over` (stop giving orders when true), `level.winner_team`, signal
  `match_ended(winner_team)`, `level.match_time()`.
- Wizard respawn: `level.respawn_time_left(team)` (0 = alive), `level.next_respawn_delay(team)`,
  `level.respawn_point(team)`; signals `wizard_fell(wizard, respawn_in)`, `wizard_respawned(wizard)`.
  Wizards heal 1 % max HP / s within 15 m of their own keep (done by the level).
- Concede: `level.surrender(Unit.Team.ENEMY, Skirmish.MALRIK_CONCEDES)` (the spec's rule: no barracks, no workers,
  < 100 crystals, no soldiers).
- Stats: `level.stats_of(team)`.

## 6.B2 (systems, balance-1) - new Skirmish helpers
- `rich_node(team) -> CrystalNode` (node_<side>_rich, contested, 2500 crystals; Fire (-40, -40), Shadow (40, 40)),
  `rich_hall_spot(team) -> Vector3` (X2 slot: Fire (-33, -33), Shadow (33, 33); passes build_grid.check).
  `node_of(team, "rich")` also works; `Skirmish.node_amount(suffix)`.
- Crown seal: `crown_unseal_time_left() -> float` on the level **and** on `crown` (0 = claimable);
  `crown.is_sealed()`, `crown.can_be_claimed()`. `crown.is_available()` stays true while sealed (it lies there).
- Keeps now shoot (12 dmg, range 10 from the walls, 1.5 s, units first): `keep.attack_target`.

# From systems-coder (step 7, task 7.S2)
- `Skirmish.enemy_kingdom` (`&"shadow"` default, `&"ice"`) picks the ENEMY side: `keep_of(ENEMY)` is then the Rime
  Keep (`ice_keep`), `wizard_of(ENEMY)` Torvald (`IceWizard`, has `ai_auto_cast`), workers `rime_hauler`. The var
  names `shadow_keep` / `shadow_hero` stay (they mean "the enemy's"). Read `enemy_kingdom` to pick the Ice profile.
- Ice build list: `BuildingType.buildable_for(&"ice")` = `ice_lodge`, `ice_barracks`, `ice_tower`, `ice_wall` (Z X C V).
  A 17th wall: `BuildGrid.check` returns `BuildGrid.MSG_WALL_LIMIT` ("Wall limit reached").
- `MALRIK_CONCEDES` is Malrik's line; for Ice pass your own (e.g. `Torvald: "..."`).
- Defeat ignores walls: `Building.defeat_relevant(team)` (buildings whose type has `counts_for_defeat`).

# Step 7 (M7.S1/S2, from systems-coder): mission 1 bot
- `Mission01 extends Skirmish` creates the Commander in code (name `ShadowBot`, team ENEMY). It sets `profile_id = &"mission_01"` if that property exists; otherwise it sets `profile` to `AIProfile.mission_01()` if that static exists, else `easy()` with `min_attack_pop` 99, workers 4, no second expansion, `malrik_joins` NEVER.
- **Scripted units**: group `"scripted"` (+ meta `scripted` = true): guards G1-G3, the Westwatch Night Spire at (-39, -25), all wave units. Please skip them in scans/orders. **Malrik joins `scripted` when the Final wave starts**: the mission then orders him (attack-move to Vessa every 3 s); leave him alone from then on.
- `node_of(team, suffix)`: Shadow has only `a` / `b` (`node_shadow_a` (46,-34), `node_shadow_b` (34,-46), 1 500 each); `mid` / `rich` return null. `wardens` is empty (crown wardens are scripted).


# Step 8 (8.S1, from systems-coder): Nature buildings and the pop cap 50
- **Pop cap per kingdom:** `Economy.MAX_POP_CAP` (40) is only the default now; the property is `economy.max_pop_cap`
  (50 for a Nature team, else 40). Your probe in `commander.gd` (~1696) already finds it: make sure every cap
  comparison goes through it. `Economy.pop_cap_limit_for(faction)` gives it statically. The team's keep sets it (`Economy.set_kingdom`, called when the keep's pop bonus applies).
- Nature build list: `BuildingType.buildable_for(&"nature")` = `nature_hollow` (Seed Hollow, max 3), `nature_barracks`
  (Grove Hall), `nature_tower` (Bramble Spire) (Z X C). Keep = `nature_keep` (Heartwood, trains `sprigling`).
- Frozen workers pause their mining timer and a site counts only builders that `can_act()`; rooted workers keep working.

# Step 8 (8.S2, from systems-coder): any kingdom on either side
- The bot's side can be any kingdom (`enemy_kingdom`: fire / shadow / ice / nature, mirror allowed); the player's too
  (`player_kingdom`). New `Skirmish.kingdom_of(team) -> StringName` gives the kingdom a team really plays (after the
  availability fallback). `Commander._detect_faction` reads a `faction` property the wizards don't have (they have
  `kingdom`), so it currently works through the keep's faction; `_level.kingdom_of(team)` would be the direct source.
- `AIProfile.id_for_faction` returns `shadow_default` for fire and nature (a Fire bot builds Fire buildings but with the
  Shadow profile) — for 8.A1.
- Wizard groups are set by the skirmish after spawn: the ENEMY wizard is in "enemy_heroes" only, the PLAYER's in
  "heroes" only with `ai_auto_cast = false`, whatever its class.

# Step 9 (task 9.C4, from systems-coder): bounty board API for ChampionBrain (9.C5) and the bot (9.C9)
- `BountyBoard.for_team(team)` (created on demand, group `"bounty_boards"`); `board.bounties` = active `Bounty` nodes
  (also group `"bounties"`). Kinds are ints: 0 HUNT, 1 EXPLORE, 2 GUARD, 3 ESCORT (`Bounty.kind`).
- Brain: `bounty.add_pursuer(champion)` when it takes a flag, `remove_pursuer(champion)` when it drops it. Pursuers
  within 12 m of a Hunt target when it dies are paid; pursuers share the 50 % walk fee on removal. Re-plan on the board
  signals `bounty_placed(b)`, `bounty_raised(b, amount)`, `bounty_ended(b, reason)`. Read `stake`, `paid`, `unpaid()`,
  `target`, `global_position` (flag spot: a Hunt flag waits on the last seen spot while its target is unseen:
  `is_tracking()` false, `last_seen_pos`), `is_valid()`, `time_left()`, `active_pursuers()`.
  Explore pays the first champion within 4 m of `global_position`; Guard 14 m / Escort 10 m around `target`.
- Bot: `place(kind, target, pos, stake := 0)` takes an optional 4th stake (Hunt 100 / 150 of champions.md 10; clamped to
  [min, 500]). Returns `""` or the reason. The warning to the victim goes through `for_team(victim).message`.
  `board.hunts_on(team)` = that board's hunts on `team`'s things; `BountyBoard.all_hunts_on(team)` = every board's.
# Step 9 (task 9.C1, from gameplay-coder): Champion API for ChampionBrain (9.C5) and the bot (9.C9)
- The champion creates its child `"Brain"` from `res://scripts/ai/champion_brain.gd` in `_ready` (after `"Inventory"` and
  `"ChampionAbilities"`) and then calls `brain.setup(champion)` if `setup` exists with at most 1 required argument
  (`setup()` without arguments is called too). `champion.brain` / `champion.abilities` point at them.
- Read: `champion_type` (`traits`, `affinity`, `flee_pct`, `bounty_threshold`, `wishlist`, `ability_ids`; helpers
  `get_trait(name, fallback)`, `affinity_for(kind)` accept String or StringName keys), `level`, `hp_ratio()`, `purse`,
  `is_unpaid`, `inventory`, `sight_radius`, `flee_pct`, `is_at_rest_spot()`, `Champion.tavern_door(tavern)`.
  Extra trait keys in the .tres (use them or ignore them): wayfinder `fear_structure_radius` 12,
  `fear_structures_until_level` 4; oathwall `engage_around_buildings` 1, `home_leash` 35, `home_leash_mult` 0.3,
  `chase_leash` 25; coin_cutter `hunt_priority_mult` 1.3, `wizard_fear_hp` 0.5, `wizard_fear_mult` 2; mender
  `escort_wizard_mult` 1.2, `keep_behind` 4.
- Write: `set_intent(id: StringName, target: Node3D = null)` (emits `intent_changed` only on change); intents are the
  UI texts (`&"Fighting"`, `&"Fleeing"`, `&"Resting"`, `&"Hunting bounty"`...). Death sets `&"Fallen"`, respawn `&"Idle"`.
  Move it with the normal `command_move` / `command_attack` / `command_attack_move` / `command_stop`.
- `power(with_hp := false) -> float` = 150 + 50 x level + items / 5 (x HP ratio when `with_hp`), for danger and strengths.
- Home rest (2 %/s near an own keep / barracks or a tavern door) is passive inside Champion: R2 only has to walk there.
- **Commander (9.C9)**: champions are units of the bot's team in group `"units"`; every army / group / retreat / attack
  gather must skip units whose `is_commandable()` is false (the brain owns them). Count `power()` in strengths instead.

# Step 9 (task 9.C3, from systems-coder): taverns and ChampionGuild for 9.C5 / 9.C9
- Taverns: `Tavern.all()` (group `"taverns"`), `door_point()` (= `door_position()`, spot x 0.8), `is_open()`,
  `is_held_by_enemy_of(team) -> bool` (an enemy soldier / wizard / champion within 12 m of the door and none of
  `team`'s; workers and neutral units never count; cached 0.25 s). Rest at a door is done by Champion itself.
- Bot (9.C9): `ChampionGuild.for_team(Unit.Team.ENEMY)`: `can_hire(id)` / `hire(id)` (refusal strings of champions.md
  3.1, same order), `hire_cost(id)` (n-th price), `held_taverns()`, `champions`, `is_fallen(ch)`, `can_revive(ch)` /
  `revive(ch)`, `revive_cost(ch)`, `roster_size()`, `has_archetype(id)`. `ChampionGuild.ARCHETYPES` lists the ids.
  The guild pays upkeep itself; `unpaid` / `is_unpaid` on each champion follow the 3-failed-ticks rule.

# Step 10 (task 10.C4, from systems-coder): ThievesGuild -> ThiefBand (10.A1)
- The guild spawns the Magpies at the Den door nearer the spot (team NEUTRAL, group `"magpies"`, meta `&"loot"` = 0,
  `command_stop()` done, `den:veteran` modifier applied), then `band = load("res://scripts/ai/thief_band.gd").new()`,
  **`guild.add_child(band)` first, then `band.setup(guild, thieves, target)` in the same frame**. It connects
  `finished(band)` (one arg) and then `queue_free`s the band (deferred): emit `finished` once, when the band is done.
- `target` = a `targets()` entry plus two keys: `{kind: &"road" / &"workers", team, post (road) or node (workers),
  spot (the chosen valid spot), spots (every spot of that route, post end first; workers: [W spot]), weight, den}`.
- Helpers on the guild for the brain: `is_spot_valid(team, spot) -> bool` (18 m units / 20 m towers / 25 m keep of
  that team), `valid_spot(target) -> Vector3` (first valid of `spots`, `Vector3.INF` if none; for "move once to the
  next valid spot" pass a copy without the used spot), `nearest_den(pos) -> Node3D`, `nearest_den_door(pos) -> Vector3`
  (flee target), `match_time()`, `veteran_bonus()`, `magpies_alive()`.
- The guild never orders Magpies after spawning them; it only counts them (group `"magpies"`, alive, still in
  `"units"`) against the cap of 6. A band waiting for a valid spot is kept inside the guild (not spawned).

# Task 10.C2 (systems): the Bazaar for 10.A3
- `commander.gd` `_adopt_buildings` (line ~511) puts every completed non-keep `TrainingBuilding` into `_barracks`: a
  Bazaar (`Market extends TrainingBuilding`, kind `&"market"`) would then be used for soldiers (`_pick_soldier` would
  queue caravans). Filter on `building_type.kind == &"barracks"`.
- `_setup` fills `_types` from `BuildingType.buildable_for(faction)`, which lists the Bazaar only while
  `BuildingType.trade_active()`; use `BuildingType.find("%s_market" % faction)` directly for rule 10a.
- Placement: `BuildGrid.check` refuses with "Needs a completed Hall", then "Must be within 20 m of your keep", then
  crystals, then "Only one Bazaar"; `BuildGrid.prerequisite_reason(type, team)` / `at_limit(type, team)` are static.
- Market API: `Market.of_team(team)` (not `for_team`), group `"markets"`, `set_route(post) -> String`,
  `route_post`, `route_value_to(post)`, `is_far_post(post)`, `default_route()`, `Market.caravan_count(team)`,
  `queue_unit(caravan_type)` (refuses "Caravan limit reached" at 6 alive + queued).

# Step 10 (task 10.V6, from tech-artist): Magpie model hooks for ThiefBand (10.A1)
- The model is `thief._model` (reach it guarded: `var m = thief.get("_model")` is private, so prefer a public Unit
  wrapper if 10.C10 adds one; otherwise ask gameplay). Hooks, all `has_method`-guarded: `play_snatch()` at the start of
  the 1.5 s Snatch channel, `cancel_snatch()` when it is broken (>= 20 damage), `set_carrying(bool)` after
  `Caravan.steal` / a sack pickup (10.C10 may do this from the loot meta). The flee needs nothing: `apply_status(&"shroud", 2.0)`
  already plays the smoke puff and the flee sprint on the model.
# Step 10 (task 10.C1, from systems-coder): TradeNetwork helpers for 10.A1-10.A3
- Besides the contract (`ambush_spots`, `worker_spot`, `remote_nodes`, `workers_at`, `mined_recently`, `strength_near`,
  `trips`, `trade_income`...): `spot_valid(team, spot) -> bool` (5.2: no fighter of `team` within 18 m, tower 20 m,
  keep 25 m; 1 Hz cache), `route_income(team, post, seconds := 180.0)`, `holder_of(post)`, `raids_on(team)`,
  `static unit_strength(u)` (caravan / worker 0, tracker 150, Magpie 80, else AIMemory), `static is_caravan(u)`,
  `refresh()` (rebuild the cache now, for tests). `remote_nodes(team)` = nodes > 30 m from the team's keep and not
  nearer the other keep (own natural + both rich; the enemy's natural is not remote for you).
- Slots: `Skirmish.market_slot(team)` (M1), `tower_slot(team, &"S3" | &"natural" | &"S4" | &"rich")`.
- ThiefBand already calls `record_workers_raided(team, node)`: thanks, it feeds `workers_raided` and `raids_on`.
# Step 11 (task 11.C1, from gameplay-coder): champion class API for 11.A1
- `Champion.flee_pct` already includes the class delta (`ChampionType.flee_pct + ChampionClass.flee_delta`, set by
  `set_champion_class`; a Sword and Shield Oathwall reads 0.15). The brain reads `champion_type.flee_pct` today
  (`champion_brain.gd` ~line 325): read `champion.flee_pct` instead and do NOT add `champion_class.flee_delta` again.
- `Champion.is_ranged()` = the class's `is_ranged`, or before the class `champion_type.attack_range > 3`.
- `Champion.class_id()` (`&""` before level 2), `champion.champion_class` (ChampionClass or null), signal
  `class_chosen(champion, class_id)` (the draw only; a save restore sets the class silently).
- `power()` now adds `20 x class_skills_unlocked()`; `Champion.LEVEL_TOTAL_XP` = `[0, 190, 500, 940, 1500, 2190]`.
# Step 10 (task 10.C10, from gameplay-coder): Magpie model hooks for `thief_band.gd`
Models are plugged (`data/units/magpie.tres` / `greywater_tracker.tres` / `caravan.tres` have `model_scene`). New public
Unit wrappers (use them instead of `get_model()` + `has_method`): `set_loot(amount: int)` (meta `&"loot"`, never < 0,
+ model `set_carrying(amount > 0)`), `get_loot() -> int`, `play_snatch()`, `cancel_snatch()`, `is_snatching() -> bool`,
`model_call(method: StringName, args: Array = []) -> Variant`, `model_has(method) -> bool`.
1. **Needed (visual bug):** when a snatch breaks on >= 20 damage the Magpie keeps playing the 1.5 s channel pose. In
   `_on_thief_damaged` (~line 1161):
   ```
   		if _snatch_damage >= SNATCH_BREAK_DAMAGE:
   			_snatcher = null   # the snatch is broken; another try on the next think
   			thief.cancel_snatch()
   ```
   (Fleeing needs nothing: `shroud` replaces the pose; moving / attacking also end it on the model.)
2. Optional tidy-up (same behaviour as today): `_set_loot(u, n)` body -> `u.set_loot(n)`; `_try_start_snatch` ->
   `best.play_snatch()` in place of the `get_model()` block; `_leave` / `_on_thief_died` / `_adopt` may keep
   `set_meta(&"loot", 0)` (the model hides the sack itself on death and fades on leave_map).

## 12.C4 CreatureAbilities (gameplay-coder, 2026-09-26), for 12.A3 BeastBrain
- `scripts/units/creature_abilities.gd` (`class_name CreatureAbilities`, child "CreatureAbilities" of the beast; EpicBeasts adds it).
  Reach it with `beast.get_node_or_null("CreatureAbilities")` + `has_method` (step-12 rule), or `CreatureAbilities.of(beast)`.
- `cast(id, target = null) -> String`: null target = the ability picks its own by the 5.5 rule (Gore Charge 6-14 m, Pounce 5-10 m
  ranged first, Gale Swoop / Shrieking Dive the biggest cluster within 12 m, Maul the current target in reach, Updraft = the
  lair centre from `EpicBeasts.lair_of(beast)["center"]`, it calls `command_move(nest)` itself). Refusals: "Dead", "Cannot act",
  "Locked", "Passive", "Busy" (mid dash / leap), "Cannot move", "On cooldown", "Not ready", "Invalid target".
  `ready(id) -> bool` (all but the target check), `find_target(id) -> Variant`, `is_busy()`, `updraft_used()`, `variant()`.
- **Autocast is ON by default** (`autocast_enabled`): while fighting (a living attack_target or damaged in the last 3 s) it casts
  on the 5.5 triggers by itself; Updraft fires at 40 % even out of combat. Set `autocast_enabled = false` if the brain wants
  to drive every cast. Passives (`bristle_hide`, `hamstring`, `enrage`) always run.
- Patrol pace: `set_patrolling(true / false)` (modifier `beast:patrol`: the .tres `move_speed` is the fight speed; patrol speeds
  and the brain aggro live in `CreatureAbilities.BEASTS[type_id]` / `beast_info(type_id)`: `aggro`, `patrol_speed`, `strength`).
- Dashes / leaps move the beast for up to ~1.2 s (modifier `beast:motion`, move speed 0): do not re-order it while `is_busy()`.
  They stop before water / off the navmesh; a leap that cannot land beside its target is refused.
## 12.C10 game critters (systems-coder, 2026-09-26) for 12.A1 (11d) / 12.A2 (R9 idle hunt)
- Find them in group `"game_critters"` (never in `"units"`), or `CritterHerds.instance(tree).critters(&"deer")` (living only).
- Fog truth for a team: `critter.is_visible_to(team) -> bool`. Do NOT read `critter.visible` (local view only, also hidden
  when far outside the camera view). `is_alive()`, `is_fleeing()`, `kind`, `target_radius()`; hunt with `unit.command_attack(critter)`.
# Replay Lab determinism (lab review 2026-09-27, group B; details: docs/plan/replay-lab.md 'Determinism audit')
- **Step 3**: reset static counters at match start (`reset_statics()`: `champion_brain.gd _slots`,
  `tracker_contract.gd _slots`, `thief_band.gd _serial`, `beast_brain.gd _serial`, `commander.gd _snapshot / _kinds`,
  `champion_sense.gd _by_team`) and seed champion / beast brains from a match seed passed in. Confirm no dictionary keyed
  by `get_instance_id()` is iterated for a decision. Timers / trickles that tick before `_start_match` belong after it.
## Caravans cost no supply (lead, 2026-09-27, user request)
caravan.tres pop 1 -> 0. commander.gd ~2631 still keeps CARAVAN_POP_FREE free pop before training one, and ai_trade.gd F4 cuts the caravan target at the pop cap; both are now moot for caravans. Remove / relax them and re-run test_10_a3 + a Bot Lab batch.


- 2026-09-27 (gameplay-coder, new-units-12.md): FYI `commander._pick_soldier` now skips slots whose `can_queue` starts with "Requires" (tier-gated) and gives Hall slots past the mix `BowmanKit.bot_share + NewUnits12.bot_share` (T1 0.06, T2 0.05). Please review.

- 2026-09-27 (systems-coder, tiers wave, docs/design/tiers.md 4-5): FYI I added two hooks at the top of
  `commander._rule_train` (before the bowman one): `TierSystem.bot_try_upgrade(team, _keep, _eco, difficulty)` (keep
  Stronghold / Citadel on the per-difficulty timeline `TierSystem.BOT_START`; returns true while saving for it, max 45 s)
  and `UnitUpgrades.bot_try_buy(team, _barracks, _eco, _now)` ("+" upgrades). Feel free to move them into your own rule /
  AIProfile knobs (e.g. `rush_t3` profile times from t3-helpers.md 9).

- 2026-10-05 (Unit Lab caster pass, `docs/balance/unit_lab/caster_ab.md`): **the bot's retreat Umbral Passage carries 0
  units.** `AICasters._deacon` aims the Passage at `_densest(group)` = where the retreating group stands at cast time; the
  group keeps walking home (~4.8 m/s) during the 2.5 s channel and is 10-12 m past the 4 m pick circle when it lands
  (`CasterAbility.passage_candidates` at the END of the channel). Unit Lab C7 (`tools/unit_lab/presets/c7_passage_retreat.json`,
  the result now records `passage_units`): Passage cast 20 / 20, `passage_units` 0. Suggested fix: aim at the group's
  predicted position (densest point + the group's mean velocity x the channel time, clamped to the Passage range), or
  have the commander hold the retreating group for the channel when no enemy is within ~4 m. Re-check with
  `tools\unit_lab\run_unit_lab.ps1 c7_passage_retreat -Seeds 1-20` (band >= 8 Shades alive).

## WS2.C1 (systems-coder, 2026-10-13): Wave Strike card sets for WS2.A1
`data/wave_strike/card_prices.tres` now holds the 14.1 sets (Fire 9, the others 10 cards, T1 / T2 / T3). The WaveBot
still runs (cards missing from `MIX` weigh 1.0; T3 needs the Citadel; `can_buy` refuses past `max_copies`), but WS2.A1
should put the 14.3 MIX in. New API: `roster.table.max_copies_of(id)` (0 = no limit; casters 4, support 6, T3 3),
refusals `"Max N copies"` and `"Requires Citadel"`. Caps 36 / 60 / 84 (JS x1.5, not 32 / 52 / 72), start 600, income 120.

## UR.S1 done (systems-coder, 2026-10-14): UnitResearch for UR.A1
`UnitResearch.for_team(team)` (null when the game has no research) -> `can_buy(id, building) -> String`,
`buy(id, building) -> String`; static `rows_for_unit(unit_id)` (table order = the "next open row" order),
`row(id)` (`tier`, `price`, `units`), `team_has(team, id)`, `building_busy(b)` (the "+" counts), `lab_off`.
ForgeKit.bot_step no longer researches unit lines (the Forge card is Z X C; `BOT_UNIT_MIN` removed).
