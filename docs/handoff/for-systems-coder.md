# For systems-coder (from gameplay-coder, wave 2 session A, task 2.G1)

- **Please change `Worker.command_attack(target: Unit)` to `command_attack(target)` (untyped) or
  `command_attack(target: Node3D)`** in `scripts/economy/worker.gd`. `Unit.command_attack(target)` is now
  untyped so it can take a building. It is untyped rather than `Node3D` only because a typed `Node3D` base
  would make your `target: Unit` override a parse error. Until you change it, a worker right-clicked on an
  enemy building gets a script error. Once Worker is widened, the lead can type the base `Node3D`.
- Towers can reuse the unit code: `Projectile.launch_at_target(tower, from, target, dmg, color, size)`
  (the shooter can be any node with a `team`), and `Unit.take_damage(amount, attacker: Node3D)` accepts a
  building as attacker. A unit hit by a tower answers it only when no enemy unit is within its `aggro_range`.
- Units use `target_radius()` on buildings for melee reach, arrow aim and fireball splash; without it they
  assume 2.5 m (`Unit.DEFAULT_TARGET_RADIUS`). Buildings must leave group `"buildings"` or return
  `is_alive() == false` when destroyed (the keep already does).

# Wave 2 session B (task 2.G3, from gameplay-coder)
- `Unit.Team.NEUTRAL` (= 2). Wardens: `make_unit("ruin_warden")`, `team = Unit.Team.NEUTRAL`, place, then
  `command_stop()` (as `_spawn` does): that spot is its home. Leash = `leash_radius()` (2 x aggro = 14 m) around
  `home_position()`. Don't give neutral units orders.
- Dead wizards stay in the tree, hidden (`is_alive() == false`, not in `"units"`). `Wizard.respawn(at: Vector3)`
  revives her there with full HP / mana, spells ready, and emits `respawned(wizard)`. `artifacts` are kept.
- Crown: `wizard.add_bonus_stats(100.0, 50.0)` on pickup (also heals +100 / +50), `remove_bonus_stats(100.0, 50.0)`
  when the wearer dies (works on a dead wizard). `heal()` does nothing on a dead unit.
- `main.gd` KEY_SPACE uses `hero.global_position`; while she is dead that is her death spot (spec: centre on keep).

# Wave 2 session B (task 2.A1, from ai-coder)
- **Bug: `Skirmish.node_of()` (so `home_nodes()` / `natural_node()`) errors once a node is depleted.**
  `var n: CrystalNode = crystal_nodes.get(id)` assigns the freed node to a typed variable: "Trying to
  assign invalid previously freed instance" on every call after a node runs out (~2:30-5:00 in a match).
  Fix: `var n: Variant = crystal_nodes.get(id)`, then `if n == null or not is_instance_valid(n)` before
  casting (or erase the id when the node sends `depleted`). The bot works around it (keeps its own refs).
- `Skirmish.wardens` (`Array[Unit]`) keeps freed wardens: `for u in level.wardens` with a typed loop
  variable would error. The bot reads it by index into a Variant; pruning dead ones would be safer.
- FYI the Hovel slot V1 of ai.md, `(50, -46)` (Fire mirror `(-50, 46)`), is refused as "Not on walkable
  ground" on the 1v1 map; the bot uses its fallback `(50, -42)`. Fine unless the designer wants the slot moved.

# Step 7 (task 7.I1, from items-coder)
- `scripts/buildings/shop_stock.gd`: add `&"frostglass_shard"` to the base shop stock (kingdom-ice.md 6: Ice items
  are sold at every base shop, any wizard may buy). Either append it to `BASE_COMPONENTS` (it then also joins the
  Lost Cache "random base component" pool) or append it in `base()` only. Buying already works (the Inventory reads
  `ItemType.sold_at`); this only makes it show up in the shop list. Rimebound Bracers, Glacier Heart and Winterwall
  Aegis are recipes, so every shop combines them already.

# Step 7 (task M7.U1, from ui-coder): what the mission UI reads from the mission node
- Create it once `hud` exists: `mission_hud = MissionHud.attach(self, mission_node, hud)` (mission_node = the node
  with the methods below; defaults to the level). Connect `mission_hud.begun` to start E1 (lines emitted earlier
  just wait in the dialogue queue: the briefing pauses the tree).
- `briefing() -> Dictionary`: `{title: String, paragraphs: Array[String], objectives: Array[String]}` (objectives
  optional: missing = the primary rows of `objectives()` that are not `"hidden"`).
- `objectives() -> Array[Dictionary]` (polled 4x/s + on `Events.objective_changed`): `{id, text, primary: bool (or
  type: "secondary"), state: "hidden"/"active"/"done"/"failed", progress: int, goal: int, time_left: float}`.
  `goal` appends " (1 / 3)"; `time_left` rewrites a trailing "(2:00)" as a countdown. Use `"hidden"` for
  `obj_crown` / `obj_hold` until they appear. Dialogue: just emit `Events.dialogue(&"vessa", text)`.

- (7.G1, gameplay) `worker.gd`: frozen workers stand still (base Unit), but the gather / build timers in `Worker._physics_process` keep running. Suggest `if not can_act(): return` right after `super(delta)` so mining and building pause while `frozen`.

## From ai-coder (7.A1 / M7.A1): mission 1 and the bot's Commander
- Put a `Commander` (team ENEMY) under the mission level with `profile_id = &"mission_01"` (set before it enters
  the tree). The Commander reads the level through the `Skirmish` API (`keep_of`, `wizard_of`, `node_of`,
  `match_time`, `match_started`, `game_over`, `build_grid`, `crown`, `wardens`...), so the mission level must
  extend `Skirmish` (or offer the same members).
- Pre-placed Gloom Hall / Night Spire / Hovel within 4 m of the ai.md slots H1 / S1 / V1 are adopted as those
  slots; once one falls the mission_01 profile never rebuilds it.
- Guards and waves: `unit.add_to_group(&"scripted")` (or `set_meta(&"scripted", true)`): the Commander never
  orders or counts them. Tag Malrik the same way if the mission wants to drive him itself.
- Final wave: `Commander.for_team(level, Unit.Team.ENEMY).follow_units(final_wave_units)`: Malrik leaves his
  anchor and attack-moves behind their centre (he still retreats below 35 % HP). Until then he stays home.

# From gameplay-coder (step 8, task 8.G1)
- `Wizard.level_cap: int` now exists (0 = no cap). At the cap `add_xp` does nothing, `xp` stays 0 and
  `xp_to_next()` returns 0 (the HUD's max display). `Wizard.max_level()` gives the effective cap. Mission 1 can set
  `hero.level_cap = 5` and drop its `xp_changed` workaround.
- Skirmish KINGDOMS entry for Nature: wizard script `res://scripts/units/nature_wizard.gd` (Ysolde), worker `sprigling`.

# Step 8 (task 8.I1, from items-coder)
- `scripts/buildings/shop_stock.gd`: the kingdom components are still missing from the base shop list. Add
  `&"frostglass_shard"` (Ice, still missing from 7.I1) and `&"verdant_seed"` (Nature) to `BASE_COMPONENTS` (they then
  also join the Lost Cache pool; if the pool must stay the 10 items.md ones, append them in `base()` instead):
  `[..., &"cinder_ring", &"gloom_ink", &"frostglass_shard", &"verdant_seed"]`. Thornweave Vest, Bloomcaller Staff and
  Heart of the Grove are recipes: every shop combines them already.

# Step 8 (task 8.U2, from ui-coder)
- Minimap objective ring: `objectives()` rows need a world position. The minimap pulses a ring on the first
  **active primary** row that has `"position": Vector3` or `"positions": Array[Vector3]` (read at 2 Hz). Suggested:
  `obj_braziers` -> `"positions"` = the unlit braziers' positions; `obj_crown` -> the crown (ground or wearer);
  `obj_hold` -> none; secondaries may carry them too (`sec_peddler` PELL_POS, `sec_outpost` GLOOM_HALL_POS) but the
  ring only shows primaries.
- `mission_brazier.gd`: at gameplay zoom a lit brazier barely reads as lit (grey bowl, a few small sparks). A bigger
  flame (taller particles / an emissive flame mesh) would help the "1 / 3" moment.

# Step 9 (task 9.D3, from ui-designer): two small reads the tavern window needs from `ChampionGuild` (9.C3)
- `next_name(id: StringName) -> String`: the display name the **player** would get on hiring that archetype now
  (`names[0]` if no team has hired it yet, else `names[1]`, per champions.md 1 / 3.1). The tavern rows print it
  (`docs/design/ui-champions.md` 5.2); without it the UI shows `names[0]`.
- `next_hire_cost() -> Dictionary {crystals, essence}` or simply `hire_cost(id)` already returning the n-th price
  for the current roster size (the spec's signature: fine as is, just confirming the UI reads that one).
- `Tavern`: a `held_by_enemy() -> bool` (or the guild's `can_hire` answering `"Enemies hold both taverns"`) so the
  window can print that line in its title bar; and a tavern click must be catchable by the selection manager
  (layer 2, group `"taverns"`, `set_selected` may be a no-op).
# Step 9 (task 9.C4, systems-coder note for 9.C3 / skirmish.gd)
- `LostCache.opened(cache, opener, loot)` can now come from a champion: `loot["given"] == "purse"` for essence. The
  skirmish's `_on_cache_opened` only prints for the hero; a champion line (`Sable Quint found 80 essence`) is optional.
- `BountyBoard.for_team(team)` creates the board on demand under the current scene: nothing to add to the skirmish.
# Step 9 (task 9.C1, from gameplay-coder): Champion API for ChampionGuild (9.C3) and the campaign companion
- Create: `var t = load("res://scripts/units/champion_type.gd").find(id)` (or `ChampionType.find(id)` once it exists),
  `var ch = t.create_champion(variant)` (0 = name A, 1 = B) **before** it enters the tree; then `ch.team = team`,
  `parent.add_child(ch)`, `ch.global_position = door`, `ch.command_stop()` (home spot, like `main._spawn`). Starts level 1,
  full HP, purse 50 (`START_PURSE`), intent `Idle`. `ch.set_variant(v)` also works later (renames `display_name`).
- Death: `Champion.die()` already moves 30 % of the purse to the killer champion's purse or the killer team's bank
  (neutral / unknown killers take nothing), sets intent `Fallen`, emits `died(unit)` and `Events.unit_died`. A fallen
  champion stays in the tree, hidden, in group `"champions"` (not in `"units"`), `is_alive() == false`.
- Revive: `ch.respawn(at: Vector3)`: full HP, same level / XP / items / purse, orders cleared, ability cooldowns reset,
  intent `Idle`, signal `respawned(ch)`. The timer and the essence price stay in the guild (use `ch.level`).
- Unpaid: set `ch.is_unpaid = true / false` (plain bool, the brain reads it).
- Dismiss value: `ch.purse`, `ch.inventory.total_item_value()`. Removing it: `queue_free()` after your fade.
- Companion save: `ch.get_save_state() -> Dictionary` (JSON-safe: `id`, `variant`, `level`, `xp`, `total_xp`, `purse`,
  `hp_ratio`, `alive`, `items` [{id, count, slot}]) and `ch.apply_save_state(d)` (works before or after add_child;
  a champion built with `Champion.new()` gets its type from `d.id`). For the companion (level reset to 1, purse 50 %
  cap 300) just edit the dictionary before applying it: `d.level = 1; d.xp = 0; d.total_xp = 0; d.purse = ...`.
- Rest: `ch.is_at_rest_spot()` (own completed keep / barracks within 15 m, tavern door within 8 m; door =
  `tavern.door_position()` if the Tavern has it, else its position x 0.8). The 2 %/s heal runs inside Champion.

# Step 9 (from ui-coder 9.C8, for 9.C4)
- The UI (`scripts/vfx/champion_barks.gd`, 2 Hz) rewrites the text / modulate of each flag's `Stake` Label3D for the
  timers of ui-champions.md 8: Guard / Escort `150 · 1:20`, a lost Hunt target `150 · 42 s` in WARN, else `150` gold.
  Your `_update_label` writing `str(stake)` on changes is fine (corrected within 0.5 s); please keep the node name
  `Stake` (or tell me if it changes). Visibility of the label stays yours.
- The UI reads `is_visible_to(team)`, `active_pursuers()`, `refund_preview()`, `time_left()`, `unseen_time`, `ended`,
  `changed`, and the board's `kind_for`, `min_stake`, `place`, `raise`, `remove`, `bounty_on`, `hunts_on`, `bounties`.

# Step 9 (from tech-artist 9.V6: tavern model + bounty flag model)
## For 9.C3 (`scripts/world/tavern.gd`)
- `res://art/buildings/tavern/tavern_model.tscn` (`TavernModel`) follows your convention: its front / door is local +Z
  and the door anchor is local (0, 0, 4.2426) (= your `DOOR_DISTANCE`, so `door_point()` needs no change). Inside, the
  house ("Body") is turned -45 degrees: with your `rotation.y = atan2(-p.x, -p.z)` (+45 / -135 degrees) the house stands
  **square on the grid** in world (door on its chamfered corner, facing the centre). `TavernModel.yaw_for_spot(p)` returns
  the same yaw.
- **Please turn the collider back by -45 degrees** so the 6 x 6 box is square in world like the art (today it is a diamond:
  the corners of the house stick out of it and its tips block cells beside the house):
  `col.rotation.y = -PI / 4` (after `col.position = ...` in `_ready`). `footprint_rect()` then matches exactly.
- Optional hooks on the `Art` node (all safe before `_ready`): `set_open(bool)` (door shut + windows dim before 2:00; call
  `art.set_open(is_open())` at spawn and `true` on `opened`; default is open), `play_door_pulse()` (0.6 s warm flash from
  the door, nice when a hired champion walks out), `set_selected(bool)` (amber rim), `get_door_point()`.
- The model has no collision and **0 lights**; `_build_placeholder()` is no longer used when the scene exists.

## For 9.C4 (`scripts/world/bounty.gd`)
- `res://art/buildings/tavern/bounty_flag.tscn` (`BountyFlagModel`): `set_team_color(c)`, `set_kind(kind)` (0-3 as yours)
  are what you already call. It spins its own coin (shader), so your `_spin` / `COIN_SPIN` code is only needed for the
  placeholder. Extra hooks, all safe before `_ready`, guard with `has_method`:
  - `set_grounded(on)`: hides the little cairn at the pole foot. Call `set_grounded(not _lifted())` in `_apply_mode()`
    (a flag riding above a unit or building should not carry stones).
  - `play_raise()`: the coin hops (0.55 s). Call it in `raise()`.
  - `set_selected(on)`: brighter coin rim + pennant (the flag card's selection).
- Height: the coin centre is at 2.07 m (top ~2.46 m while it bobs). With `LABEL_Y = 2.55` the stake text touches the coin;
  **2.8** leaves a clean gap. `CLICK_SIZE` (0.9 x 2.4 x 0.9) covers the whole flag already.

# Step 9 (task 9.C9, from ai-coder): refund while the scene is being freed
- `BountyBoard._on_target_exiting` -> `_refund` -> `EssenceBank.for_team` while the level is being freed: the bank is
  already gone, so for_team creates a new one under a parent that is busy -> `ERROR: Parent node is busy setting up
  children, add_child() failed` (twice at the end of each part of `tests/test_9_c9.gd`). Suggest skipping refunds
  (or the bank creation) when the board / scene `is_queued_for_deletion()` or not `is_inside_tree()`.

# Task A2.7 (tech-artist): neutral art (Ruin Peddler, Lost Cache)
- `res://art/environment/ruin_peddler.tscn` is a new stall (root script `art/environment/neutral/peddler_stall_art.gd`,
  `PeddlerStallArt`). It has **0 lights** now: the comment in `ruin_peddler.gd` ("it has the one lantern light") is stale.
  Everything fits your collider (3.2 x 1.8 x 1.8 at (0.4, 0.9, 0)) and Pell's cage (4.2 x 2.6 x 3.0, top 2.53 m).
- Facing: the counter / merchant side is local **+Z**. `skirmish.gd` sets `rotation.y = atan2(p.x, p.z)`, which turns
  +Z **away** from the map centre (the comment says "faces the map centre"). If you want the counters to face the
  centre, use `atan2(-p.x, -p.z)`. Either way one of the two stalls shows its back to the camera; the art reads from
  both sides (awning, lanterns, back shelf), so this is only about intent.
- `res://art/environment/lost_cache.tscn` (root script `art/environment/neutral/lost_cache_model.gd`, `LostCacheModel`):
  same hooks as before, `set_open(true)` = the looting burst (lid shakes then bursts open, coins, light shaft; all
  within 0.35 s, before your shrink at 0.6 s), `set_open(false)` = the chest pops up out of the ground (your
  `_reset_look` already calls it on (re)appear), `is_open()`. New: `set_opened(opened: bool)` snaps to either state with
  no animation (if you ever keep a looted chest visible until it respawns, call `set_opened(true)` instead of hiding it).
# Task A2.8 (tech-artist): trees / rocks / ruin pillars second pass (optional EnvProps change)
Nothing is required: `art/environment/meshes/<name>.res` keep their names, footprints and collider sizes, and every
tree / rock / pillar mesh now holds **3 shape variants** that `nature_painted.gdshader` picks from the instance's world
position (the other two collapse to a point). Two optional, cheap improvements in `scripts/world/env_props.gd`:
1. **Pick the variant yourself** (no collapsed triangles: -30 % in the primitive counter on forest close-ups, e.g.
   618 k -> 420 k; measured GPU time is the same within noise since the meshes are indexed, so this is low priority).
   Single-variant meshes exist next to the combined ones: `<name>_v0.res`, `_v1.res`, `_v2.res` for tree_pine,
   tree_fir, tree_broadleaf, tree_birch, tree_gold, rock_boulder, rock_slab, rock_shards, rock_spire, ruin_pillar.
   In `add_tree` / `add_rock` / `add_pillar` append the suffix, e.g.
   `_add("%s_v%d" % [TREES[int(h * 997.0) % TREES.size()], int(h * 7919.0) % 3], xf)` (pillar: `PILLAR + "_v%d"`).
   The MultiMesh names stay "TreePineV1"... (MapDressingArt still sorts them by the "Tree" / "Rock" prefix).
2. **More tree kinds**: `tree_birch` (pale trunk, light crown) and `tree_gold` (autumn accent) fit the same collider
   (r 0.45 s) and were only used in the border forest. Suggested pick: add them once each to `TREES` after the 3
   others, weighted low (e.g. `["tree_pine", "tree_broadleaf", "tree_fir", "tree_pine", "tree_broadleaf", "tree_fir",
   "tree_birch", "tree_gold"]`). Keep `rock_spire` out of `ROCKS` (2.5-3 m needle on a 1.2 m collider).

# Step 10 (task 10.C4, from systems-coder): ThievesGuild glue for 10.C1 (`skirmish.gd`)
- Create it only when `trade_enabled`: `var g = load("res://scripts/world/thieves_guild.gd").new()` (guarded by
  `ResourceLoader.exists`), `g.name = "ThievesGuild"`, `g.match_time_source = match_time`, `add_child(g)` (the level is
  its parent: Magpies are added to the level), then `g.message.connect(func(t, s): hud.show_message(t, s))` (without a
  connection it calls the parent's `hud.show_message` itself). Optional: `g.rng.seed = <map seed>`.
- It reads from the TradeNetwork (group `"trade_network"`): signal `delivered(team, caravan, amount, post)` (its own
  per-route ledger: trips in 120 s, gold in 180 s), `ambush_spots(team, post)`, `worker_spot(node)`,
  `remote_nodes(team)` and `mined_recently(node, seconds)` (both have fallbacks: nodes > 30 m from
  `level.base_center(team)`, own 10 s samples of `crystals_left`). Dens: group `"guilds"`, `kind == &"den"`,
  `door_point()`; it calls `play_band_out()` on the Den if the GuildHouse has it (forward it to the model, 10.C9).

# Step 10 (task 10.C5): HuntersGuild glue for 10.C1 (`scripts/world/skirmish.gd`)
- Create it only when `trade_enabled`, through the load guard (`res://scripts/world/hunters_guild.gd`), as a child of
  the level: `name = "HuntersGuild"`, `local_team = Unit.Team.PLAYER`, `match_time_source = match_time` (without it
  the guild reads the parent's `match_time()`, else its own age), then `add_child`. Connect its
  `message(text: String, seconds: float)` to `hud.show_message` (hire lines + the summed Lodge reward line).
- It finds Lodges in group `"guilds"` with `kind == &"lodge"` (`door_point()`; `play_contract()` is called if the
  GuildHouse has it); without them it uses the doors `(-45, -51)` / `(45, 51)`. Gold goes through group `"gold_banks"`
  (`team`, `can_afford`, `spend`, `add(n, &"reward")`). The end screen can read `magpies_slain(team)` /
  `rewards_paid(team)`.
# Task 10.C2 (systems): Market for 10.C3 / 10.C11 / 10.C9
- `Market.for_team` does not exist (GDScript: Building already has `static for_team(team) -> Array[Building]`, and
  `load(market.gd).call(&"for_team", t)` silently returns that Array). Use **`Market.of_team(team)`** (completed + alive
  or null) or the group **`"markets"`**. 10.C11: the GoldBank "No Bazaar" refusal must use one of these.
- New caravans: `Market._spawn` sets `home_market = self` (if the property exists) before `add_child`, then calls
  `command_trade(market)` (fallback: walk to the rally point). `route_post` is a property with a getter (default = the
  near post with the highest value), so `market.get(&"route_post")` works. Without a TradeNetwork the length is the
  straight distance to the post door.
- 10.C9: `BuildingType.model_path` = `res://art/buildings/market/<kingdom>/market_<kingdom>.tscn` is already in the 4
  `.tres`; `Market._ready` loads it (via `get_model_scene()`) once the file exists, so setting `model_scene` is optional.
# Step 10 (task 10.A2, from ai-coder): TrackerContract for HuntersGuild (10.C5)
- `res://scripts/ai/tracker_contract.gd` (`class_name TrackerContract extends Node`, group `"tracker_contracts"`). Load-guard
  it, then: spawn the trackers (team = hirer, placed at the Lodge door, in the tree), `var k = script.new()`,
  `k.setup(self, team, &"outriders" | &"sweep", trackers, 180.0 | 120.0)`, `add_child(k)` (order of setup / add_child
  does not matter). Connect `k.ended(contract)` to start the 30 s cooldown; `k.time_left()` for `contract_time_left`.
- The contract ends itself at the end of its duration, **and early when all its trackers are dead**; it then calls
  `leave_map()` on the living trackers, emits `ended` once and `queue_free()`s itself (check `is_instance_valid`).
- Lodge choice: `script.first_destination(get_tree(), team, kind) -> Vector3` (static; `Vector3.INF` when unknown):
  Outriders = the caravan they will escort first, Sweep = the first spot. Pick the Lodge door nearer that point.
- Each tracker gets `set_meta(&"contract", contract)` and joins group `"trackers"`; UI inspect text:
  `contract.display_name()`, `contract.time_left()`, `contract.status_text(tracker)`.
- The contract reads: group `"caravans"` (`team`, `is_loaded()` or `cargo`, `home_market`, `route_post`, `velocity`),
  group `"magpies"`, group `"trade_network"` (`remote_nodes`, `workers_at`, `worker_spot`, `posts`, `ambush_spots`,
  `trips(team, post, 180.0)`, `route_length(market, post)`), group `"buildings"` (the Market by `building_type.kind ==
  &"market"`, its `route_post`; the Keep).

## From 10.C3 (Caravan) to 10.C1 (TradeNetwork) / 10.C9 (plugging)
- `Caravan.steal()` emits `caravan_robbed(team, caravan, amount, thief)` **on the TradeNetwork itself** (when it has
  that signal): don't re-emit it from `Caravan.robbed`. Deliveries call `record_delivery(team, amount, post, caravan)`
  (the network emits `delivered`). The network must count `caravans_lost(team)` itself (Events.unit_died + group
  `"caravans"`); the caravan does not report its death.
- `route_points(market, post)`: the caravan drops leading points within 3 m of the Bazaar spawn point / 4 m of its
  centre, trailing points inside the post, and appends `post.door_point()` if the last point is not the door. So
  returning `[first road node, ..., door]` is ideal; a list with or without the Bazaar / door also works.
- Held posts: the caravan asks `post.is_held_by_enemy_of(team)` (else `route_reason == "Held by the enemy"`); open:
  `is_open()`; value: `route_value(market, post)` locked at the end of the 2 s trade.
- VFX: the caravan plays `TradeVfx.play(&"post_trade", door, caravan)` when a trade ends and
  `play(&"delivery", bazaar_spawn_point, caravan)` on delivery. 10.C9: don't play these twice; the Bazaar model's
  `play_delivery()` can hang on `Caravan.delivered` / `TradeNetwork.delivered`.
- Dead loaded caravan: `LootSack.spawn(current_scene, pos, floor(cargo * 0.5))` via `load("res://scripts/world/loot_sack.gd")`.
# Step 11 (task 11.C1, from gameplay-coder): bounty leans and the companion class
- `BountyBoard._pay` calls `_give` (purse + `add_xp(share / 2)`) BEFORE `bounty_paid.emit`. When that XP takes a
  champion to level 2, its class is drawn before it hears the payment, so that bounty does not lean the draw
  (skills-rework.md 2.1: "bounties you paid it before level 2"). Please emit `bounty_paid` first, then `_give`
  (or give the XP after the emit). Champions listen to their team's existing board (group `"bounty_boards"`, never
  created by them) and count each bounty once per kind (`Champion.bounty_leans`).
- 11.C3 companion: `Champion.get_save_state()` has `"class"` (`""` before level 2) and `"bounty_leans"`;
  `apply_save_state` restores them silently. For a companion that restarts at level 1 with its class, call
  `ch.set_champion_class(StringName(data.class))` after spawning (works at level 1, before or in the tree; no
  `class_chosen`, the level-2 draw is then skipped). `""` / missing = draws at level 2 as usual.
  Signature: `set_champion_class(id: StringName, announce: bool = false) -> void`: **quiet by default** (no
  `class_chosen`, VFX, bark or message), which is what `add_companion` needs; `announce = true` is for the draw only.
  test_11_c3 passes against the real Champion.

## From 10.V11 (tech-artist, TradeVfx + loot sack art) to 10.C1 / 10.C9 (loot_sack.gd, market.gd)
- `res://art/vfx/trade_loot_sack.tscn` (root `TradeLootSackModel`) exists. It **bobs its own sack** (the coin spill
  stays on the ground) and answers `bobs_itself() -> true`: in `LootSack._process`, please skip the `_visual` bob when
  the art has `bobs_itself()` (today both bob: small double bob, harmless but not intended).
- The art needs no calls: it finds its LootSack (nearest ancestor with `time_left()`), reads `amount` (sack size),
  blinks in the last 8 s of `time_left()`, and fades itself out (0.25 s) as soon as `is_available()` turns false, in
  parallel with your scale tween. Optional hooks: `set_amount(gold)`, `play_pickup()`, `fade_out(s)`, `play_drop()`.
- Market (10.C9): on `GoldBank.ware_bought(id)` of its team, play
  `get_tree().get_first_node_in_group(&"trade_vfx").play(&"ware_bought", market.global_position, market)`
  (ring size from `target_radius()`, flash height from `building_type.height`).

## From 10.V1 (tech-artist, Ember Bazaar model) to 10.C2 / 10.C9 (market.gd, data/buildings/fire_market.tres)
- Model: `res://art/buildings/market/fire/market_fire.tscn` (root script `FireMarketModel extends FireHallModel`), for
  `fire_market.tres` `model_scene`. Gate = local -Z like every building: `Building._gate_yaw()` already turns it
  (M1 (-45, 27) -> -90 deg). No collision in the scene, 6 x 6 footprint, 0 real lights.
- Same hooks as the halls (Building already calls them): `set_team_color`, `set_construction_progress` (skip the
  `_visual` scale / fade), `set_health_ratio`, `set_selected`, `play_training_pulse` (caravan trained: the gold
  glints), `play_destroyed` + signal `destroyed_finished` (3.0 s, the mast topples, then the wreck).
- New hook: `play_delivery()` (the scale tips toward the gold pan and rocks back 1.8 s, coins sparkle). Please call it
  on the Market's model when one of its caravans delivers (`Caravan.delivered` / `TradeNetwork.delivered` for this
  Bazaar), e.g. `var m := model(); if m and m.has_method(&"play_delivery"): m.call(&"play_delivery")`. Safe on a
  site / wreck (ignored). `get_scale_tilt() -> float` is read-only (tests).

## From 10.V2 (tech-artist, Gloom Bazaar model) to 10.C2 / 10.C9 (market.gd, data/buildings/shadow_market.tres)
- Model: `res://art/buildings/market/shadow/market_shadow.tscn` (root script `GloomBazaarModel extends ShadowHallModel`),
  already named by `shadow_market.tres` `model_path`. Gate = local -Z (caravans roll out down the front-left steps,
  local (-1.35, 0, -3.1)); `Building._gate_yaw()` turns it. No collision, 6 x 6 footprint, 0 real lights, ~9.3 m tall
  (mast + coin), 16 mesh nodes.
- Same hooks as the halls (Building / TrainingBuilding already call them): `set_team_color`, `set_construction_progress`,
  `set_health_ratio`, `set_selected`, `play_training_pulse` (caravan trained: lanterns and tent mouth flash, gate
  sparks), `play_destroyed` + signal `destroyed_finished` (3.0 s, the mast topples, then the wreck).
- New hook (same name as the Ember Bazaar): `play_delivery()` (the scale tips toward the gold pan and swings back ~3 s,
  gold glints, the coin emblem flares and spins). Call it on the Market's model when one of its caravans delivers,
  e.g. `var m := model(); if m and m.has_method(&"play_delivery"): m.call(&"play_delivery")`. Ignored on a site /
  wreck. `is_delivery_playing() -> bool` is read-only (tests).

## From 10.V3 (tech-artist, Frost Bazaar model) to 10.C2 / 10.C9 (market.gd, data/buildings/ice_market.tres)
- Model: `res://art/buildings/market/ice/market_ice.tscn` (root script `FrostBazaarModel extends FireHallModel`),
  already named by `ice_market.tres` `model_path`. Gate = local -Z (caravans leave from the front step, local
  (0.3, 0, -3.0)); `Building._gate_yaw()` turns it. No collision, 6 x 6 footprint (eaves overhang <= 0.6 m), 0 real
  lights, ~9.1 m tall (crystal mast + scale + gem), 14 mesh nodes when built.
- Same hooks as the halls (Building / TrainingBuilding already call them): `set_team_color`, `set_construction_progress`,
  `set_health_ratio`, `set_selected`, `play_training_pulse` (caravan trained: windows flash, gate sparks),
  `play_destroyed` + signal `destroyed_finished` (3.0 s, the mast topples, then the wreck).
- New hook (same name as the other Bazaars): `play_delivery()` (the scale tips toward the gold pan and swings back to
  balance in ~2 s, the coin emblem and the gold pan glint). Call it on the Market's model when one of its caravans
  delivers, e.g. `var m := model(); if m and m.has_method(&"play_delivery"): m.call(&"play_delivery")`. Ignored on a
  site / wreck; retriggering adds to the swing (safe with several caravans).
## From 10.V8 (tech-artist, Magpie Den model) to 10.C1 / 10.C9 (guild_house.gd)
- Model: `res://art/buildings/guilds/magpie_den/magpie_den.tscn` (root script `MagpieDenModel`). `GuildHouse` already
  instances it as child "Art" and forwards the hooks: nothing to glue (checked in `tests/test_10_v8.gd`).
- Front (door) = local +Z, door anchor local (0, 0, 4) = `GuildHouse.door_point()`; 6 x 6 footprint, no collision,
  0 real lights. Hooks: `set_open(bool)` (closed = door shut, lamps dim; GuildHouse starts closed, good),
  `set_selected(bool)`, `play_band_out()` (door flung open ~1.7 s, dust puff, lamp flash, the hoist sack jolts: please
  call `GuildHouse.play_band_out()` from ThievesGuild when a band leaves AND when a Magpie reaches the door to leave the
  map, if cheap), `set_team_color(c)` (ignored), `get_door_point()`, `get_door_direction()`,
  `static yaw_for_door(center, door) -> float`.
- Heads-up: the model mirrors its inner "Body" along local X (from its global rotation, re-checked on transform
  change) so the mast / crow's nest / magpie vane always stand at the gable away from the default RTS camera and break
  the roof outline. Door, footprint and hooks do not change. Ridge ~6.2 m, vane top ~8.7 m.

## From 10.V10 (tech-artist, trading post + roads + waystones) to 10.C1 / 10.C9 (skirmish.gd, trade_post.gd)
- Model: `res://art/buildings/trade_post/trade_post.tscn` (root script `TradePostModel`). `TradePost` already instances
  it as "Art" and forwards `set_sign` / `set_open` / `set_held` / `set_selected`: nothing else to glue. Front = local +Z,
  door anchor local (0, 0, 4) (= `TradePost.door_point()`), 6 x 6, no collision, 0 lights, roof ~4.4 m, mast ~6.1 m.
  Extra hooks: `play_trade()` (sign swings, lantern flares ~0.9 s: please call it on the model when a caravan trades
  at the post), `set_team_color(c)` (ignored), `get_door_point()`, `static yaw_for_door(center, door)`,
  `static sign_for_post(post_id) -> int`, `sign_index` property (= `set_sign`). Like the Magpie Den it may mirror its
  inner "Body" along local X (mast on the far side from the default camera) and keeps the sign board facing world +Z.
- Roads: the ground shader uses exactly `uniform vec4 road_segs[16]` (x0, z0, x1, z1), `uniform int road_count`
  (default 0 = map unchanged), `uniform float road_width` (default 3.0) -> `EnvProps.set_roads` works as written.
  `art/environment/map_dressing_art.gd` now reads them too (no grass / flowers on the roads).
- Waystones (please add, draw-only, one MultiMesh, no collider / navmesh effect), e.g. at the end of
  `_add_trade_map()` in skirmish.gd:
      const WAYSTONE_ROW_PATH := "res://art/environment/meshes/waystone_row.gd"
      if ResourceLoader.exists(WAYSTONE_ROW_PATH):
          var clear := PackedVector3Array([PLAYER_START, SHADOW_START])   # base hubs
          var radii := PackedFloat32Array([14.0, 14.0])
          for spot: Dictionary in POST_SPOTS:            # + the 4 guild houses (DEN_SPOTS / LODGE_SPOTS), 7 m each
              clear.append(spot["center"]); radii.append(7.0)
          var row: Script = load(WAYSTONE_ROW_PATH)
          var stones: MultiMeshInstance3D = row.call(&"build", road_param(), 10.0, 2.2, 5.0, clear, radii, 6.0)
          if stones:
              add_child(stones)
  (32 stones on the ring: every ~10 m, 2.2 m beside the centre line, none within 5 m of a segment end.)
## From 10.V9 (tech-artist, Greywater Lodge model) to 10.C1 / 10.C9 (guild_house.gd)
- Model: `res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn` (root script `GreywaterLodgeModel`).
  `GuildHouse` already instances it as "Art" and forwards `set_open` / `set_selected` / `play_contract`: nothing else to
  glue. Front (door) = local +Z, door anchor local (0, 0, 4) = `GuildHouse.door_point()`; 6 x 6 centred on the origin,
  no collision, 0 lights. Ridge ~4.1 m, chimney cap 6.6 m, antler-crowned pennant pole ~6.5 m.
- Hooks: `set_open(bool)` (closed = door shut, windows dim, brazier cold, no chimney smoke; the lantern stays lit as a
  landmark; GuildHouse starting closed is right), `set_selected(bool)` (pale green rim + glow boost), `play_contract()`
  (amber horn flag hoisted ~0.9 s, flies 5 s, lowered 1.4 s; lantern + brazier flare; retrigger keeps it up),
  `is_contract_flag_up()`, `set_team_color(c)` (ignored), `get_door_point()`, `get_door_direction()`,
  `static yaw_for_spot(spot)` (0 for (-45, -55), PI for (45, 55)), `static yaw_for_door(center, door)` (snapped to 90).
- The pennants always fly toward world +X (same drift as the chimney smoke), whatever the house's yaw.

## 10.V4 Grove Bazaar model (tech-artist, 2026-09-26) -> for 10.C9
- Scene: `res://art/buildings/market/nature/market_nature.tscn` (`NatureMarketModel extends FireHallModel`), set it as
  `model_scene` of `data/buildings/nature_market.tres`. Footprint 3 x 3 (6 x 6 m), gate = local -Z (Building's `_gate_yaw`).
- Hooks as every hall (Building already calls them): `set_team_color`, `set_construction_progress`, `set_health_ratio`,
  `play_training_pulse` (a caravan leaves), `play_destroyed` + signal `destroyed_finished`, `set_selected`.
- New: `play_delivery()` -> call it from Market / Caravan on each delivery (via `model()` + `has_method`). Ignored while
  building or destroyed; safe before `_ready`.
- 0 lights, 34 mesh surfaces + 2 ambient particle systems (Grove Hall: 34 + 3). Meshes baked in
  `art/buildings/market/nature/baked/` (rerun `market_nature_bake.gd` windowed after geometry changes).

# Step 10 (task 10.C7, from ui-coder)
- **Caravan (10.C3)**: a new caravan has `route_post == null` until its first departure (it follows its Bazaar's route
  then). The UI shows `Empty · No route: right-click a post` and no route ribbon for it (ui-trade.md 6.2 / 7.1 read
  `route_post`). Suggestion: set `route_post` to the Bazaar's route whenever `_own_route` is false (at spawn and on
  `Market.route_changed`), so the panel / ribbon show the route it will really take.
- **market.gd:299** `if p is Node3D and is_instance_valid(p)`: swap to `is_instance_valid(p) and p is Node3D` (step-10
  rule 3: a freed post errors on `is`).

# Step 12 (task 12.V7, from tech-artist / Riverbank set): the willow for 12.C1 (skirmish.gd, env_props.gd)
- Mesh `res://art/environment/meshes/tree_willow.res` (3 variants picked by the shader from the position, like every
  tree; one-variant copies `tree_willow_v0/_v1/_v2.res`; far stand-in `tree_willow_far.res`). Same material, origin,
  scale convention and **collider as every tree: cylinder r 0.45 s, height 2, centre y 1** at the mesh origin.
  `EnvProps.add_tree_kind("tree_willow", pos, s)` can simply `_add("tree_willow", xf)` (the mesh name is the key).
- Size: crown radius ~2.3 s, top 5.05 s, curtain hem 0.9-1.6 m over the ground (units walk under it, like other crowns).
- Placement suggestion (`riverbank_set.gd` WILLOW): s 0.95-1.2, trunk foot 1.5-4 m from the water edge, >= 3 m from
  crossings. **Optional yaw**: local +X is the lean / overhang side (variant V1 leans ~1 m toward +X and trails its
  curtain deeper there): yaw so +X points at the nearest water (`Basis(Vector3.UP, atan2(-dir.z, dir.x))` with `dir`
  = horizontal direction to the water). A random yaw also works. Mirror rule: the twin at `-p` gets yaw + PI.
- Fireflies "under willows" (12.V16): crown centres per variant in `riverbank_set.gd` WILLOW.crown_centre (x s).
## From 12.V18 (tech-artist, Wayshrine model) to 12.C8 (capture_point.gd, skirmish.gd)
- Scene: `res://art/buildings/capture/wayshrine/wayshrine.tscn` (root `WayshrineModel`, `wayshrine.gd`). Instance it as a child of
  the shrine `CapturePoint` at its centre (origin = the point on the ground, front +Z, no rotation needed). Draw-only: no
  collider, no light, nothing in `"units"` / `"buildings"`; units walk through it. Load-guard it (`ResourceLoader.exists`).
- Hooks (all safe before `_ready`, typed loosely so a `null` colour works):
  - `set_state(&"awake")` when the shrine wakes, `set_state(&"asleep")` when it is captured / sleeps (other values are
    ignored, so passing `CapturePoint.state` straight through is harmless but only these two change the look).
  - `set_owner_color(team_color)` after a capture (the model shows it while asleep), `set_owner_color(null)` when it wakes
    and becomes neutral again (spec 4.4). While awake the model always shows gold anyway.
  - `set_capture(team_color, progress)` on every `progress_changed` (ratio 0-1 of the capturing team); `set_capture(null, 0.0)`
    when nobody is capturing (decayed to 0 or captured). Contested = keep the last call (the arc freezes with the progress).
  - `play_blessing(team_color)` when the blessing is granted (burst to the 6 m radius + column flash, 1.8 s).
  - `set_selected(bool)` from `CapturePoint.set_selected` (warm rim).
- Typical capture order: `play_blessing(c)`, `set_capture(null, 0.0)`, `set_state(&"asleep")`, `set_owner_color(c)` (any order works).
- The model already has its own light column when awake: the 12.V25 `shrine_awaken` VFX can stay a short one-shot flash.

# Step 12, task 12.V1 (river water, from tech-artist) - for 12.C1 / 12.C8
Files in `art/environment/water/`: `water_mat.tres` (deep water), `water_ford_mat.tres` (ford / Crown Steps film,
same shader with `shallow = 1`), `riverbed_mat.tres` (trench walls + bed), `wade_ripple_tex.res` + `wade_ripple_mat.tres`
(for 12.V25), and `water_meshes.gd` (`class_name WaterMeshes`, static builders; reach it with `load()`).
- **Mesh convention the water shader needs** (WaterMeshes builds it; copy it if you build your own):
  `UV.x` = metres along the flow (downstream), `UV.y` = 0 one bank -> 1 other bank, `COLOR.r` = bank weight
  (1 real bank, 0 an open edge: the moat's outer rim across a river mouth), `COLOR.g` = piece width / 5 m (0.7 on the moat).
  A mesh without colours reads white (1, 1) = a 5 m channel with foam on both banks.
- Builders (all world x/z, one indexed surface, material already set; turn `cast_shadow` off on the instances):
  `WaterMeshes.arc_path(center: Vector2, radius: float, a0_deg: float, a1_deg: float, step_m := 0.6) -> PackedVector2Array`,
  `channel_surface(path, half_width, y := -0.35, s0 := 0.0, max_step := 1.0, bank_foam: Callable, flip_across := false, end_dirs := PackedVector2Array()) -> ArrayMesh`,
  `ford_film(path, half_width, ford_center: Vector2, ford_radius: float, y := 0.02, s0 := 0.0) -> ArrayMesh`,
  `channel_walls(path, half_width, skip: Callable, bottom_y := -0.6, max_step := 0.8, seed_value := 0, with_bed := false) -> ArrayMesh`,
  `ford_end_walls(path, half_width, ford_center, ford_radius, bottom_y := -0.6) -> ArrayMesh`,
  `distance_to_path(path, p: Vector2) -> float`. `art/environment/water/water_test_strip.gd` is a worked example
  (north river N0-N5, Reed Ford, whole moat with both Crown Steps): copy its calls.
- **Moat**: build it as two halves leaving the north mouth (258.69 deg) and meeting at the south mouth (78.69 deg), each
  flowing downstream (`arc_path(c, 12.75, 258.69, 78.69)` and `arc_path(c, 12.75, 258.69, 438.69)`), the west one with
  `flip_across = true`, both with `end_dirs = [first point, last point]` (radial): the two halves then share their seams
  exactly. `s0` = the river length so the flow continues. Moat walls: one full ring `arc_path(c, 12.75, 0, 360)`.
- **Mouths**: the river surface overlaps the moat at the mouths: put the river 4 mm lower (`y = -0.354`) so the moat wins;
  `bank_foam` on the moat = 0 where the outer rim is inside the river channel; skip moat-wall pieces inside the river
  channel and river-wall pieces inside `r < 14.5`. **Only count the river where `r > 12.75`**: its round end at N5/S5
  otherwise reaches r 10.25, into the isle (I told 12.V2 the same for the ground cut).
- **Shared material data** (set once on the loaded `.tres`, both water materials): `fords` (PackedVector4Array
  `(cx, cz, r, 0)`, same as the ground's) + `ford_count`; `foam_rocks` (PackedVector4Array `(x, z, radius, 0)`, <= 16:
  road-bridge piers in the water, the Drowned Barge `(-6.2, -24.5)` and mirror, big ford stones) + `foam_rock_count`.
- **Map detail Low**: `set_shader_parameter(&"detail", 0.0)` on `water_mat.tres` and `water_ford_mat.tres` (1.0 = high).
- Budget: the whole map (both rivers, moat halves, 4 films + end walls, walls) is ~4 700 triangles (`tests/test_12_v1.gd`
  prints it), 3 materials, no lights; the shader costs nothing measurable at zoom 55 on the GTX 1660.
# Step 12, task 12.V3 (Crown Bridges) -> 12.C1 / 12.C8 (RiverSystem placing the models)
- Scene `res://art/environment/bridges/lane_bridge.tscn` (root `LaneBridgeArt`, `lane_bridge_art.gd`), used for both
  `bridge_crown_w` (-9.02, 9.02) and `bridge_crown_e` (9.02, -9.02). Draw-only: no collider, no obstacle, 0 lights, 1 mesh
  (3 surfaces). Keep the deck rectangle out of the carve as the spec says; nothing else is needed for pathing.
- **Place it with** `bridge.place_on_moat(center: Vector3, isle_center := Vector3.ZERO)` after `add_child` (or
  `transform = Transform3D(LaneBridgeArt.basis_for(center, isle_center), center)`). Local +Z must point AWAY from the isle:
  the moat's curvature is baked into the arches / piers / bank walls, so do not orient it from the crossing's `dir` alone
  (a 180 deg turn bends the arches the wrong way). Deck = local 8 m (X) x 6.5 m (Z), top y 0.0-0.03.
- Water foam (12.V1 `foam_rocks`): `LaneBridgeArt.foam_rocks(center, isle_center) -> PackedVector4Array` gives the world
  `(x, z, radius, 0)` of the two cutwaters and a fallen stone per bridge (3 each, point-mirrored); append both bridges'.
- Load-guard as usual (`ResourceLoader.exists`); the static helpers work through `load(path).call(&"basis_for", ...)`.

# Step 12, task 12.V4 (road bridges, fords, Crown Steps) -> 12.C1 / 12.C8 (RiverSystem placing the models)
- Scenes `res://art/environment/bridges/road_bridge.tscn`, `ford_stones.tscn`, `crown_steps.tscn`. Root script
  `crossing_art.gd` (`CrossingArt`, `@export var kind` = `&"bridge_road"` / `&"ford"` / `&"steps"`, the crossing kinds).
  Draw-only: no collider, no obstacle, 0 lights; children `Body` (painted + lantern glow) and `Foam` (transparent white
  water). Keep the bridge deck rectangles / ford and steps circles out of the carve as the spec says; nothing else needed.
- **Place with** `model.place_crossing(center: Vector3, dir: Vector3, isle_center := Vector3.ZERO)` after `add_child`
  (or `transform = Transform3D(CrossingArt.basis_for(kind, center, dir, isle_center), center)`; static helper also works
  through `load(path).call(&"basis_for", ...)`):
  - `bridge_road`: `dir` = the road direction (either way round: +Z is forced east). **Millstone Bridge takes the same yaw
    as Saltgate, not a 180 deg turn**: both sites have the same road / river axes and the river flows south under both;
    the piers are baked skewed 12.8 deg to the river and the pier wakes trail south.
  - `ford`: `dir` = the DOWNSTREAM flow direction (N2 -> N3 at Reed Ford, S3 -> S2 at Willow Ford: `(1, 0, 8)` for both,
    so both fords get the same yaw). The cascade / churn foam sit on the downstream rim.
  - `steps`: `dir` ignored; +Z points away from `isle_center` (like `LaneBridgeArt`), moat curvature baked in.
- Heights: bridge deck top y 0.03-0.05 (5.2 m of planks + curbs to +-2.8 m, 9 m long), ford stepping stones <= 0.155,
  Crown Steps treads <= 0.055 (film at 0.02). The pier foam is in the model: no need to add the piers to 12.V1 `foam_rocks`.
- The waystone row must skip the bridge decks (spec 2.3: 7 m around each road bridge); the bridge's abutments reach
  0.7 m past the water edge under the ground only.

# Step 12, task 12.V19 (Essence well) -> 12.C2 / 12.C8 (CapturePoint showing the model)
- Scene `res://art/buildings/capture/essence_well/essence_well.tscn` (root `EssenceWellModel`, `essence_well.gd`).
  Draw-only: no collider, no obstacle, 0 lights. Add it as a child of the well's CapturePoint at its origin and **keep
  yaw 0** (front +Z = the default camera side: the roof gable and its rune medallion face the camera). Body r 1.56 +
  winch posts inside the 3 x 3 footprint (+0.3 m; roof eaves up to 0.6 m out above 2.5 m); flat apron, rubble and
  fallen boards out to r ~3.1 (clearing 3.5). Height ~4.3 m (roof ridge).
- Hooks (all safe before `_ready`):
  - `set_owner_color(c: Variant)`: the owner's kingdom colour (`Unit.KINGDOM_COLORS[...]`; any Color works, the four
    kingdom colours map to their art-keep glow colour) or `null` = neutral. Call on `owner_changed` (a short flare plays).
  - `set_capture(color: Variant, ratio: float)`: on `progress_changed(point, team, ratio)` pass the capturing team's
    colour and ratio 0-1 (also while neutralising); `set_capture(null, 0.0)` when nobody captures / it decayed to 0.
    The rune ring and a ground arc fill clockwise from -Z (seen from above), like the Wayshrine.
  - `play_pulse()`: each income tick (+2 essence every 5 s from 2:30). This is the model's own violet ring; the 12.V25
    `well_pulse` VFX is not needed on top of it (or use one of the two).
  - `set_selected(on: bool)`: warm rim (forward CapturePoint.set_selected if you want).
- Getters: `get_owner_color() -> Variant`, `get_capture_ratio() -> float`, `is_pulse_playing() -> bool`,
  static `glow_of(c: Color) -> Color`. The model stops processing when idle.

# Step 12, task 12.V13 (Landmarks A: Fallen Colossus, Giant's Stump) -> 12.C1 / 12.C8 (placing the landmarks)
- Scenes `res://art/environment/landmarks/colossus.tscn` (`lm_colossus`) and `giant_stump.tscn` (`lm_stump`). Plain
  scenes (no script): root Node3D in group `"landmarks"`, metadata `landmark_id` and `decor_clear_radius` (4.2 / 3.8 m,
  for `MapDressingArt._blocked` / 12.V6), child `Model` (one MeshInstance3D, shared nature materials, 0 lights) and
  `Collision` (StaticBody3D, layer 1, mask 0) with the map-fill.md 3.2 colliders already in it:
  colossus `Head` cylinder r 2.2 at local (1.0, 0.8, -0.7) + `Hand` box 1.5 x 1.8 x 3.0 at (-1.045, 0.7, 1.587) turned
  -33.4 deg (all within 3.48 m of the origin); stump `Trunk` cylinder r 2.0 at the origin. Collider tops are 1.8 / 1.6 m:
  keep them under the nav agent height (2.0), a taller hollow shape bakes a walkable island inside itself.
- Placement: instance the scene under `nav_region` BEFORE the first bake (the colliders then cut the navmesh like
  terrain; no extra obstacle needed, so drop any placeholder collider for these two). Player side at `(-57, 0, -16)` /
  `(-30, 0, 20)` with `rotation.y = 0`; the mirror at `(57, 0, 16)` / `(30, 0, -20)` with `rotation.y = PI` (point mirror:
  identical colliders, `tests/test_12_v13.gd` checks it). The yaw-0 copy faces the default camera (the head looks up at
  the camera and at its open hand; the stump's burrow and bracket fungus are on its sunlit front-right).
- Fog: `FogOfWar.reveal(team, pos, 5)` at each landmark origin as spec 3.1 / 4 says (nothing in the scene does it).

# Step 12, task 12.V14 (Landmarks B: Old Aqueduct, Drowned Barge, Standing Stones) -> 12.C1 / 12.C8
- Scenes `res://art/environment/landmarks/aqueduct.tscn` (`lm_aqueduct`), `barge.tscn` (`lm_barge`),
  `standing_stones.tscn` (`lm_stones`). Same layout as Landmarks A above (plain scenes, no script): root Node3D in group
  `"landmarks"`, metadata `landmark_id`, `decor_clear_radius` (aqueduct 5.8, barge 3.6, stones 4.3 m) and `foam_rocks`;
  child `Model` (one MeshInstance3D: shared nature_mat + nature_contact_mat, the stones also `stones_rune_mat.tres`;
  0 lights) and, where 3.2 asks for colliders, `Collision` (StaticBody3D, layer 1, mask 0), cylinders 1.8 m tall
  (under the 2.0 nav agent height):
  aqueduct `PierWest` / `PierEast` r 0.9 at local (-4.1, 0) / (4.1, 0) (arches, middle pier in the river, rubble:
  draw-only); stones `Stone0`..`Stone5` r 0.5 on the ring r 3 (the fallen one, `Stone3`, lies across the west point and
  is sunk to < 0.45 m: units walk over its ends); barge: no collider (deep water).
- Placement: under `nav_region` BEFORE the first bake, player side `rotation.y = 0`, mirror at `-p` with
  `rotation.y = PI` (point mirror, identical colliders; `tests/test_12_v14.gd` checks it and bakes a navmesh):
  aqueduct origin `(-13.4, 0, -55)` = the midpoint of the piers (-17.5, -55) / (-9.3, -55) (mirror `(13.4, 0, 55)`);
  barge `(-6.2, 0, -24.5)` (already turned along the flow; mirror `(6.2, 0, 24.5)`); stones `(-54, 0, 20)` (mirror
  `(54, 0, -20)`). Drop any placeholder colliders for these three.
- Water foam (12.V1 `water.gdshader` `foam_rocks`): each scene's `foam_rocks` metadata is a PackedVector3Array of LOCAL
  `(x, z, radius)`; add `Vector4(w.x, w.z, radius, 0)` with `w = landmark.global_transform * Vector3(x, 0, z)` for both
  copies (aqueduct 3 circles: middle pier + the fallen bay's stones; barge 5 circles along what pokes out of the water;
  stones none). The shader fills each circle white, so the circles stay inside the solid parts.
- Parts below the trench bed (y -1.0: the middle pier's footing, the barge's sunk stern) are meant to be hidden by the bed.
- Fog: `FogOfWar.reveal(team, pos, 5)` at each landmark origin as for Landmarks A.

# Step 12, task 12.V17 (Watchtower model) -> 12.C8 (CapturePoint, kind &"watchtower")
- Scene `res://art/buildings/capture/watchtower/watchtower.tscn` (root Node3D, script `WatchtowerModel`; reach it with
  `load()` + `has_method()`, no static type needed). Draw only: no collider, no group, 0 lights. Instance it as a child of
  the CapturePoint at the point's origin (= footprint centre on the ground). Footprint 4 x 4 (the stone body stays within
  r 1.9; rubble decor reaches r 3.5, inside the r 4 clearing); the crown / banner stick out above 5 m only.
- Rotation: leave it at yaw 0 or rotate it freely: the model keeps its front (door, banner pole, cresset) toward world +Z
  (`face_camera`, default true), so the enemy-bank mirror towers read like the player's.
- Hooks (all safe before `_ready`, the state is then applied with no transition):
  `set_owner_color(c: Variant)` on `owner_changed` (the new owner's kingdom colour, `null` when neutral / neutralised);
  `set_capture(color: Variant, ratio: float)` on `progress_changed` / each 1 Hz pass (the capturing or neutralising
  team's colour and `progress`; `null` or 0 when nobody captures / after decay); `play_captured()` right after a capture
  (order with `set_owner_color` does not matter); `set_selected(on)` from `CapturePoint.set_selected`.
  The display chases each `set_capture` value at constant speed over ~1 s, so 1 Hz calls look continuous.
- Colours: pass the owning team's kingdom colour (`Unit.KINGDOM_COLORS` / art-keep 0.2 / `UIStyle.KINGDOM_COLORS` all map
  to the kingdom glow of the cresset); any other colour works (the fire takes its bright hue).
- VFX anchors: `get_beacon_point()` (the cresset fire, world) and `get_banner_point()` (banner centre, world), e.g. for
  `MapFillVfx.play(&"capture_done", ...)`.
- The model's own progress ring is small (r 2.75-3.1 m at the tower foot, fills from the front); the UI ring at the
  capture radius 7 (12.C6) is separate and still needed.
# Task UX.1 (control scheme, from ui-coder)
- `scripts/campaign/mission_01.gd` `HINT_START` says "Walk Vessa with W A S D." In the new default **Classic** control
  scheme (`GameSettings.control_scheme`, Settings > Controls) W A S D no longer walk her: right click moves her. Please
  build the line with `GameHUD.walk_hint("Vessa") + ". Light the brazier to the north-east."` (Classic: "Right-click the
  ground to move Vessa"; Hero WASD: "Walk Vessa with W A S D", keyboard letters as printed on the player's keys).
  `GameSettings.hero_wasd()` tells the scheme if another line needs it.
- Optional, same file: `HINT_FIRST_LIT` "(Z / X)" names physical keys by their QWERTY letter; an AZERTY player sees
  "W" on that key. `KeyLabels.of(KEY_Z)` returns the letter printed on the player's keyboard.

# Step 12, task 12.V2 (ground: river cut, wet banks, biome tints) -> 12.C1 (RiverSystem.shader_params, EnvProps.set_river)
Shader `res://art/environment/ground.gdshader`. Its defaults = no river, no biomes: missions, the plateau and the menu diorama
look exactly as before, and `ground_material.tres` is unchanged. Only the skirmish's main ground (the 120 m PlaneMesh,
`material_override` from `EnvProps.ground_material`, i.e. the per-map duplicate, never the saved .tres) gets the values.
- **River uniforms** (exact names / types; the dictionary keys = the uniform names):
  `river_segs` vec4[16] = PackedVector4Array, 16 slots, one segment per slot `(a.x, a.z, b.x, b.z)` in world x/z;
  `river_count` int = used slots (Crown Hollow: 10 = N0-N5 + the point mirror; 0 = no river);
  `river_half_width` float (2.5); `moat` vec4 `(centre x, centre z, centre-line radius, half width)` = (0, 0, 12.75, 1.75)
  (radius 0 = no moat); `fords` vec4[4] = PackedVector4Array `(x, z, r, 0)`: the uncut circles, Reed Ford (-8.5, -34, 3.5),
  Willow Ford (8.5, 34, 3.5), NW Crown Steps (-9.02, -9.02, 3.0), SE Crown Steps (9.02, 9.02, 3.0). The river counts only
  outside the moat's centre line (its round ends at N5 / S5 never bite into the isle). Bridges ARE cut (their decks cover
  the trench). `bank_width` (2.5) is look only. `river_box` vec4 `(min x, min z, max x, max z)` is perf only (the segment
  loop is skipped outside it; `gp.river()` computes it: (-28, -75, 28, 75) on Crown Hollow; Vector4.ZERO = no box).
- **Biome uniforms**: `biome_amount` float (0 off, 1 on); `biome_tints` vec3[4] source_color = PackedColorArray (sRGB) in
  the order meadow, heath, old wood, riverbank (the biome sets' `GROUND_TINT`); `biome_hubs` vec4 (-36, 36, 36, -36),
  `biome_hub_radius` 22, `biome_woods` vec4 (-50, -50, 50, 50), `biome_wood_radius` 28, `biome_heath_edge` 44,
  `biome_bank_reach` 6, `biome_blend` 4, `biome_ruins` vec4[8] `(x, z, r, 0)` + `biome_ruin_count` int (the isle r 11 and
  3 m around the colossus / stump / standing stones, both sides = 7). The zones are analytic (no `biome_mask` texture:
  test_map_p1 keeps the ground at one sampler).
- **How** (all values come from `art/environment/ground_params.gd`, reached with `load()`):
  ```
  const GP := "res://art/environment/ground_params.gd"
  if ResourceLoader.exists(GP):
      var gp: GDScript = load(GP)
      var params: Dictionary = gp.river([RIVER_POLYLINE_N, mirrored_s], RIVER_HALF_WIDTH, MOAT, circles)  # circles: Array of Vector4(x, z, r, 0)
      gp.apply(ground_mat, params)                 # false + no change when the shader lacks river_segs
      gp.apply(ground_mat, gp.skirmish_biomes())   # biomes (tints read from the biome set files)
  ```
  `gp.skirmish_river()` returns the map-fill.md 2.1 / 2.2 values directly. `RiverSystem.shader_params()` can simply return
  `gp.river(...)` (it also carries `ford_count` for the 12.V1 water materials, which read the same `fords`). `apply()` skips
  keys the shader does not declare, so one dictionary can go to the ground and the water. Any time is fine (visual only);
  more polyline points (12.V5 mouths under the cliffs) just work up to 16 segments in total.
- **CPU mirror** (tests, decor clearing): `gp.is_cut(params, Vector2) -> bool`, `gp.water_distance(params, Vector2) -> float`
  (signed, < 0 in water, fords not subtracted), `gp.in_ford(params, Vector2) -> bool` = exactly what the shader draws.
  `tests/test_12_v2.gd` also checks the live skirmish ground once you set it (must equal `skirmish_river()`).
- **Perf** (important): any `discard` would make the ground plane run its fragment shader in all 4 sun shadow cascades
  (+1.3 ms on the GTX 1660, measured). The shader now leaves the plane out of the sun's shadow pass itself
  (`skip_sun_shadow`, default true: orthographic pass looking from `sun_dir`). Recommended anyway: set the ground
  `MeshInstance3D.cast_shadow = SHADOW_CASTING_SETTING_OFF` in `main.gd _build_ground` (it shadows nothing: it is the lowest
  surface), which makes this independent of the light direction.
- Missions: keep `biome_amount` 0 unless the mission passes its own zones (the hubs / woods above are Crown Hollow's).
## 12.C4 creatures (gameplay-coder, 2026-09-26), for 12.C3 CampManager / 12.C11 EpicBeasts
- `CreatureAbilities.attach(unit)` adds the "CreatureAbilities" child once with the type's default ids (Elder `spore_burst`, Stag
  `antler_sweep`, the others none; beasts as 12.C11 passes them) and returns it; it also puts the 5 creature kinds in group
  `"creatures"` and Mirefangs in `"amphibious"`. Safe to call on every creature. Autocast is on (camps have no brain).
- Fight strength: `CreatureAbilities.strength_of_type(type_id)` (100 / 110 / 220 / 50 / 700; beasts 900 / 1080, 800, 700 / 780,
  1300 / 1500). Ability damage scales with `attack_damage / UnitType.attack_damage`, so the camp-level modifier
  (`attack_damage_pct` +10 % per level) also raises Spore Burst / Antler Sweep.
- Hollow Stag and the beasts have `model_scene` empty and `model_path` set (placeholder capsule until 12.C9 plugs the models).
# Step 12 (task 12.C1 -> 12.C2 / 12.C5 / 12.C10, from systems-coder)
- RiverSystem API (`scripts/world/river_system.gd`, group "river"): contract of map-fill.md 13 plus
  `distance_to_water(pos, max_distance := INF)` (INF beyond `max_distance`: a cheap "water within x m" test),
  `distance_to_crossing(pos) -> float` (0 inside a ford / steps circle or on a bridge deck), `crossing(id)["radius"]` on
  fords / steps, `add_foam_rocks(rocks)`, `polylines()`, `half_width()`, `moat()`, `unit_pass()` (the 5 Hz pass, public
  for tests), `player_bank_point`. BuildGrid (12.C5): "within 1.0 m of deep water, ford or bridge" =
  `distance_to_water(p, 1.0) < 1.0 or distance_to_crossing(p) < 1.0`; "within 8 m of a crossing centre" = loop
  `crossings()` (`center`).
- 12.C2: the 1.8 m watchtower bodies still get a navmesh island on their roof (`map_get_closest_point` of the tower
  centre returns `(-24, 2.25, -41)`): unreachable, harmless for pathing, but a move click on a tower snaps there.
  Taverns also enclose an unreachable pocket (older).
- Skirmish shapes passed to the services: `CapturePoints.setup(POINT_SPOTS)` `{id, name, kind, pos}`;
  `CampManager.setup(CAMP_SPOTS)`; `EpicBeasts.setup(LAIR_SPOTS)` (patrol = Array of Vector3);
  `CritterHerds.setup(DEER_HERDS, RABBIT_HOMES)`: herds `{id, name, count: 3, respawn: 120.0, spots: Array of Vector3
  (6 graze spots)}`, homes `Array[Vector3]` (12, player half first). End screen: `CampManager.cleared_count(team)`,
  `CapturePoints.held_by(team)` / `points()` / signal `blessing_started`, `CritterHerds.hunted_count(team)`.

## 12.V24 camp sites (tech-artist, 2026-09-26), for 12.C8 (NeutralCamp / CampManager glue)
- Scenes `res://art/environment/camps/<kind>_site.tscn` for `&"bristleback"`, `&"mirefang"`, `&"gloomcap"`, `&"hollow_stag"`;
  root script `art/environment/camps/camp_site.gd` (`class_name CampSite extends Node3D`, group `"camp_sites"`). Draw-only:
  no collider, no light, no click; add it anywhere (map root or the NeutralCamp) BEFORE or AFTER the navmesh bake.
- Placement: `site.place_at(spot_pos, dir := Vector3.ZERO)` once. Origin = the camp spot (y 0). bristleback / gloomcap /
  hollow_stag: local -Z faces the map centre (point mirror automatic). mirefang: pass the ford crossing's `dir` (the flow,
  skirmish CROSSINGS ford_n / ford_s `Vector3(1, 0, 8)`; default the same), so it lines up with ford_stones.tscn. Static
  helpers `CampSite.scene_path(kind)`, `CampSite.basis_for(kind, pos, dir)`.
- State hook: `set_cleared(cleared: bool, instant := false)` (+ `is_cleared()`). Call it on the first spawn / `respawned`
  (false) and on `cleared` (true); camps whose first spawn is later (hollow 2:30, stag 3:30) can start cleared
  (`set_cleared(true, true)` right after adding, or the export `start_cleared`). Cleared = glow fades 1.4 s (eggs, fairy
  ring, altar), the wallow dries in 6 s, flattened reeds / smashed eggs / the snapped Mother Cap swap in.
- `clear_radius()` / root metadata `decor_clear_radius` (3.6-4.7 m): keep map decor (flowers, tufts) out of that circle
  (today glade flowers grow up to ~3 m from the Stag Glade spot); CAMP_CLEARING 3.5 already clears trees / rocks.

## 12.V32 lairs (tech-artist, 2026-09-26), for 12.C8 (EpicBeasts glue)
- Scenes `res://art/environment/lairs/heath_wallow.tscn` (tusker), `crag_nest.tscn` (roc), `greymane_hollow.tscn` (direwolf),
  `old_wood_den.tscn` (grizzlemaw); root script `art/environment/lairs/lair_art.gd` (`class_name LairArt extends Node3D`,
  group `"lairs"`). Draw-only: no collider, no light, no click; add under the level root, before or after the bake.
- Placement: `position = lair["center"]`, `rotation.y = LairArt.yaw_for(id)` (0 west bank, PI east bank = the point
  mirror, like the landmarks); the nest then sits on the Fallen Colossus head and the den by the aqueduct pier on both
  banks. Path: `LairArt.scene_path_for(id, kind)` (lair id first, kind fallback for mission lairs; "" when unknown).
- Hook: `set_occupied(occupied: bool)` (+ `is_occupied()`). Starts empty. `true` on `beast_spawned(beast, lair_id, variant)`,
  `false` when that beast dies or leaves (`beast_slain`, or the beast's `tree_exiting`). Occupied = fresh signs (wet mud and
  puddles, whole eggs, fur and a fresh kill, bear prints); empty = dried / abandoned signs (cracked crust, broken shells,
  toadstools and leaves, a cobweb over the den mouth).
- Decor: `decor_clear_circles() -> PackedVector3Array` = world (x, z, radius) circles; call
  `MapDressingArt.clear_area(Vector3(x, 0, z), radius)` for each once the dressing has populated (heather / tufts otherwise
  grow in the wallow). Metadata: `lair_kind`, `beast_rest` (local spot where the beast looks at home), `decor_clear` (local).
- Optional (lead's call, it moves seeded trees): add the lair circles to `Skirmish._mapfill_clearings()`. Today a willow at
  (-19.1, -54) stands between the den and the pier, so the den boulder sits 4 m west of the pier, clear of it.

## 13.V25 Dragon Roost (tech-artist, 2026-09-26), for 13.C8 (plug the Lair models) and the 13c Crucible glue
- Scene `res://art/buildings/lair/fire/dragon_roost.tscn`, script `dragon_roost.gd` (`class_name DragonRoostModel extends
  FireHallModel`): set it as `fire_lair.tres` `model_scene`. Same building hooks as every Fire building (art-keep.md 8.8):
  `set_team_color`, `set_construction_progress`, `set_health_ratio`, `play_training_pulse`, `play_destroyed` (+ signal
  `destroyed_finished` after 3 s), `set_selected`; gate = local -Z (Building's `_gate_yaw` as usual). 0 lights, no collider.
- `play_raise()`: call it when a Cinder Dragon is trained at the Roost (instead of, or after, `play_training_pulse`): 2.6 s
  lava flare + fire column out of the nest. Ignored on a site / wreck.
- Ember Crucible (titans-2.md 6, 13c): the Roost owns the annex. `install_upgrade(&"ember_crucible")` -> `model.set_crucible(true)`;
  a Guard forged -> `model.play_forge()` (signal `crucible_poured(at: Vector3)` = the moment the pour hits the mould, for the
  clang / Guard exit sync); save restore of a lit Roost -> `set_crucible(true, true)`. The model shows the annex on its forge
  terrace (front corner, ROOST_ANCHOR), hides it on a site, and on `play_destroyed` puts it out at once and hides it with
  the collapse: nothing else to call on death. A dead Roost ignores `set_crucible`. Reach the hooks with `has_method`.
- Collider: the model carries none. `Building` today builds a 6 x `height` x 6 box (`fire_lair.height` 9 -> 9 m tall). If the
  runtime navmesh bake must not see a 9 m block (the step-12 "colliders <= 1.8 m" rule), a 6 x 1.8 x 6 box is enough for
  clicks / build grid / pathing of this footprint; the click on the tall nest would then need a taller pick shape on layer 2
  only. Your call (scripts/buildings/ is yours).

## From the cine agent (tools wave, tool 2), 2026-09-27
- **Facing convention mismatch (please check).** `cinematic_player.gd` turns movers / `face` with `atan2(-dir.x, -dir.z)`
  (models face -Z), but the game turns unit models with `atan2(dir.x, dir.z)` (`scripts/units/unit.gd` ~1910: models
  face +Z), and the stills of `tools/cine` confirm the kit models (Vessa, Shade) show their face on +Z at yaw 0. A
  `move` in the runtime will likely make puppets walk backwards. cine uses +Z (the game's) in its evaluator and preview.
- Cross-check already green: `cine build watch_keep` plays the baked `data/cinematics/watch_keep.tres` in your
  `CinematicPlayer`, `seek`s to the middle of every shot and compares `debug_state().camera.pos` with cine's
  evaluator: worst 0.000 m. Thanks for `seek` / `debug_state`.
- `data/cinematics/<id>.tres` from cine leaves `stage_scene` empty unless `missions/cinematics/tool_demo/<id>.tscn`
  exists; the stage is built in code by `tools/cine/cine_stage.gd` (`CineStage`, has `cinematic_actor(tag)`).

# Replay Lab determinism (lab review 2026-09-27, group B; details: docs/plan/replay-lab.md 'Determinism audit')
- **Step 2**: gameplay in `_process` -> `_physics_process`: `world/bounty.gd:125`, `world/loot_sack.gd:105`,
  `campaign/ember_crown.gd:98`, `campaign/artifact.gd:93`; timers in `building.gd:664-666`, `game_critter.gd:453`,
  `caravan.gd:835` -> `create_timer(t, false, true)`. `training_building.gd:224` drops a dead gather rally only while
  selected: drop it regardless of selection. `neutral_camp.gd:468`: seed the fallback `RandomNumberGenerator`.
- Bot Lab next step 5: the report's new "Start-up" section measures the first navmesh bake per match (test batch: 8.9 s
  of an 18 s start-up, under load). If a real batch shows it >= 3 % of a match, a lab-only main.gd hook caching the
  first navmesh would speed every Bot / Balance Lab batch.- (cine, fix round) Facing fix verified: `cine check` row RT2 compares the runtime-posed puppets with cine at every shot middle: 0.0 deg / 0.000 m on watch_keep.

# Voice Forge: voiced cinematic lines (Voice Forge agent, 2026-09-27; tools/voice_forge/README.md)
- `data/voice/manifest.json` has a Kokoro WAV for every `line` cue of `data/cinematics/src/*.cine` (watch_keep,
  two_wizards) and for the Ep3 / Ep4 opening monologues (`data/voice/lines/ep3_opening.json` / `ep4_opening.json`,
  read from docs/design/episode3-4-opening.md section 3). Entry: `{speaker, text, path, duration, ...}`; match on
  speaker + text with `VoicePlayer.norm_text(text)` (subtitle `|` -> space). When the runtime shows a line, it can
  play `path` on the `Cinematic` bus (or reuse `scripts/ui/voice_player.gd`: `play_line(speaker, text) -> bool`).
  `run_voice_forge.ps1 check` lists lines whose voice is longer than their slot (next line / shot end).
  I did not edit scripts/cinematics or tools/cine.

# Face / model prewarm at level load (tech-artist, 2026-10-02, review-art-faces.md M3)
- The first unit of each type that spawns mid-match builds its face meshes (5 expressions + FAR) and the kit's merged
  pivot meshes on its spawn frame. Measured headless 2026-10-02: 100-450 ms per type cold (face part alone 40-110 ms,
  mean ~80 ms), 2-3 ms for any later instance. Per kingdom 1.7-2.6 s in total, neutral creatures 2.2 s, champions 0.7 s.
- Art side is ready: `FacePrewarm.warm(parent, kingdoms: Array, champions := false) -> Dictionary` (sync) and
  `await FacePrewarm.warm_async(parent, kingdoms, champions, ms_per_frame := 50.0)` (spread over frames; a type is
  never split). `art/units/kit/face/face_prewarm.gd`. Each scene is warmed once per process.
- Request: call it while a skirmish / mission loads (before the first frame the player sees, or under the load
  screen), e.g. in `Skirmish._ready` after the kingdoms are known:
  `FacePrewarm.warm(self, [player_kingdom, enemy_kingdom, &"neutral"], true)` (true = champions; missions: their kingdoms only).
  Sync costs ~5-6 s for two kingdoms + neutral, so prefer the async form at the match start or under a load screen.

# Fix batch F1 (save framework, 2026-10-12): R4-5 seat switch economy hooks
`MissionBase.switch_seat_side` now calls, when they exist (has_method), for every node that changes team:
- `Economy.move_unit(unit: Unit, to: Economy) -> void` on the OLD team's Economy: stop counting `unit`'s pop here
  (`_unit_pop` / `_living_pop`, its `died` / `tree_exiting` hooks) and make `to` count it (same hooks there).
- `refresh_economy() -> void` on the node (Building and Worker): drop the cached `_economy`; a Building with its pop bonus
  applied moves it (old Economy `add_pop_bonus(-n)`, new `+n`), a Worker credits its next crystals to the new team.
Called right after `node.team = new_team`. Until they exist, a switched seat keeps counting on its old Economy.

# F2 gameplay (gameplay-coder, 2026-10-12)
- `Unit.set_down(pos: Vector3)` exists (navmesh-snapped, quiet, orders kept): `build_grid.gd` TODO(set_down) can use it.
- `HelperRoster.stub_for_save(id)` / `Stables16.stub_for_save(id)` exist (instance methods, as `_stub_from_save` expects);
  the roster's queued / reviving state comes back through its saved_state row (`helper_roster:<team>`).

## SC2 console HUD (ui-coder, 2026-10-13)
- `scripts/world/wave_strike/wave_strike_level.gd` start text "Buy cards (Z X C V)": still right (cards 5-10 have no key
  in the M1 panel until WS2.U1). For WS2.U1 the GameHUD now offers `hud.console.zone_rect(&"muster")` (x 244 -> right
  edge - 12, y 692-892) and `hud.set_skirmish_console_visible(false)` (hides the selection block, portrait window,
  command card and group tabs; minimap, hero tile and champion slots stay).

## WS2.U1 Muster panel (ui-coder, 2026-10-13)
- `scripts/world/wave_strike/wave_strike_level.gd` start message "Buy cards (Z X C V): ..." is now wrong: the cards are
  the whole bottom row Z X C V B N M , . / (slots 1-10), Coffer = G, next tier = U, enemy roster = I (ui-wave-strike.md 5).
  Suggested: "Buy cards (bottom row keys or click): they march at every horn. First horn at 0:30." (a new msgid: run the
  i18n merge + French after the change). KeyLabels.letter() can print the AZERTY letters if you build it in code.
- `MenuFlow`'s restart hook re-applies `MenuFlow.ws_kingdom` to any WaveStrikeLevel entering the tree once installed, so a
  test / lab that loads two WS levels in one run must set `MenuFlow.ws_kingdom` too (tests/test_ws_ui_lab.gd does). FYI only.

## WS3.C2 note (systems-coder, 2026-10-13)
- WaveFormation <-> LaneMarch interface agreed through for-gameplay-coder.md "WS3.C2 / WS4.C2 formation interface".

## WS3.G1 / WS4.G1 LaneMarch formation side (gameplay-coder, 2026-10-13)
Built to the interface in `wave_formation.gd` (checked with the real class in `tests/test_ws_formation_march.gd` phase E):
- `LaneMarch.hold(formation)`: command_stop, auto-aggro on, no march; watches `Unit.damage_taken` + `attack_target`.
- `LaneMarch.march(speed, release_after := -1.0)`: first waypoint ahead of the unit (15.3 step 5); speed > 0 = locked
  (`ws_lock`, corrected for move_speed_pct); speed <= 0 = lock off: the unit takes `formation.release_effects_of(unit)`
  and applies them at ITS OWN first contact (per unit, 16.2). `release_after` < 0 reads `formation.release_after`.
- `LaneMarch.release(effects := [])`: idempotent; removes `ws_lock`, applies the effects once (`apply_status(id, s, true)`
  / `add_shield`), a held unit starts marching. After a lock-off march it does nothing (so your 45 s `tick` timeout does
  not fire the effects early on lock-off waves).
- Triggers (target / hit, and the unit's own `release_after` timer on the 0.25 s think) call `formation.release(reason)`
  with `"contact"` / `"timeout"`; please keep that one-argument signature. Also on LaneMarch: `set_release_effects(list)`,
  `is_held()`, `is_locked()`, `is_released()`, `effects_applied`, static `march_speed(units, floor)`.
- A hold never followed by `march` / `release` ends on its own after 30 s (`HOLD_MAX`) so a lost formation never parks units.
- Save load (15.3 step 4): units re-made by `save_spawn_unit` are never held, so they march free as before; nothing to do.

## B13 Cause 3 (ai-coder helper, 2026-10-14): PaceSwitch needs NO change
- The diagnosis (docs/balance/b13_2026-10-13/diagnosis.md, Cause 3 b) asked you to make `PaceSwitch` skip Ice's
  `BLITZ.ai_kingdom` knobs because `data/ai/ice_normal.tres` would carry them. It does not: `ice_normal.tres` is unchanged.
  The normal-pace knobs live in `AIProfile.NORMAL_PACE_KNOBS` and are laid on only when no PaceSwitch is applied
  (`AIProfile.for_faction(faction, difficulty, PaceSwitch.is_applied())` in `Commander._setup`). Under Fast / Blitz the
  bot gets the old base profile and your patches exactly as before (tests/test_bal_cause3.gd checks all 4 kingdoms live).
- So please do NOT skip / remove `BLITZ.ai_kingdom.ice` (that WOULD change Blitz Ice: ratio 0.936 -> 1.17, reserve 2).
  Optional hardening only: writing the Ice block as absolute numbers (`attack_ratio 0.936`, `attack_ratio_floor 0.576`,
  `min_attack_pop 6`, `attack_reserve 1`) gives the same values and no longer depends on the base.

## MU14 music hooks (from ui-coder, 2026-10-14, docs/design/music.md 4 + 5)
MusicDirector (`scripts/audio/music_director.gd`, `MusicDirector.ensure(get_tree())`, a /root child) is in. Please add, in
MissionBase / scripts/campaign (ui-coder does not edit there):
1. Boss: when a boss bar shows (or a mission wants it), `MusicDirector.ensure(get_tree()).set_music_context(&"boss")`;
   when it ends, `set_music_context(&"match")` (no kingdoms = back to the match's own pool, no reset of the override).
2. `MissionConfig.music_tracks: Array[StringName]` (optional, empty = default pool). The director already reads
   `level.config.music_tracks` when a level enters the tree (duck typed); a mission that changes it mid-run calls
   `set_track_pool(ids)` (empty = back to the context pool). Missing files are skipped, never an error.
3. Missions by episode (music.md 4): the match pool's "own kingdom" is the level's `player_kingdom` (first track). If a
   mission's `player_kingdom` is not the episode's kingdom from that table, set it or pass `music_tracks`.
4. Mission scenes (`missions/*.tscn`) have no GameAudio node: their music works (the director watches scene changes),
   but no SFX and no combat intensity / drive stem. Adding a `GameAudio` node (script `scripts/audio/game_audio.gd`)
   to MissionBase or the mission scenes, like skirmish.tscn, turns both on.
