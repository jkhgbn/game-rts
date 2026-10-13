# For ui-coder (from systems-coder, wave 1 session B)

## Please change
- `scripts/ui/hud.gd` line ~46: the help text still says "R: restart". Restart is now **F9** (`main.gd`).

## Contract details not spelled out in CLAUDE.md (tasks 1.U1, 1.U2, 1.U5)
- `main.economy` = the player's Economy, `main.keep` = the player's Keep, `main.crystal_nodes` = id -> CrystalNode.
  Or `Economy.for_team(Unit.Team.PLAYER)` / `Keep.nearest(team, pos)`.
- `Economy.changed` fires on every crystal or pop change; `spend_failed` fires when a queue is refused for
  crystals (Keep.queue_unit calls spend so the top bar can flash).
- `Keep.cancel(slot)` is **0-based**: `cancel(0)` = slot 1 (the one training, loses its progress).
- `Keep.can_queue(type)` reasons, in check order: "Queue is full", "Not enough crystals",
  "Population cap reached" (also "The keep is destroyed", "Can't train that here").
- `Keep.trainable_types()` is in card order Q W E R T (`UnitType.card_key` has the letter).
- `Keep.queue_changed` fires on queue, cancel and spawn; poll `train_progress()` each frame for the bar.
- `Keep.rally_point() -> Vector3` gives the current rally spot (for a gather rally: the node's spot).
  The flag shows/hides by itself in `set_selected`.
- The keep's collider is on layers 1 + 2. `SelectionManager.unit_at` (mask 2) can now hit the keep first;
  it then falls back to the 28 px search, so units in front of the keep still select. For keep clicks, check
  `hit.collider is Keep`.
- Crystal nodes are StaticBody3D on layer 1: a mask-1 raycast returns the CrystalNode itself
  (`hit.collider is CrystalNode`). Right-click a node with workers selected -> `command_gather(node)`; with the
  keep selected -> `keep.set_rally_node(node)`; ground with the keep selected -> `keep.set_rally_point(p)`.
- Worker extras for the panel: `carried: int`, `is_gathering() -> bool`, `gather_node`.

# Wave 2 session A (task 2.S1), for 2.U1

## Behaviour change that breaks two wave 1 UI tests
- The keep now trains **only workers** (`trainable_types()` = `[cinder_hand]`). `tests/test_1_u2.gd` (expects
  6 keep slots incl. Flame Guard, W queues a guard) and `tests/test_1_u5.gd` (queues a Flame Guard and an
  Ember Archer at the keep) fail for that reason only. Soldiers train at the Ember Hall.

## Building API details (beyond CLAUDE.md)
- Classes: `Building` (hearth / hovel), `TrainingBuilding extends Building` (barracks), `Keep extends
  TrainingBuilding`, `Tower extends Building`. Trainers: test `has_method("queue_unit")`. Name to show:
  `building.building_type.display_name` (the keep's is "Keep" / "Dusk Keep").
- Training reasons (`can_queue`): "The building is destroyed", "Under construction", "Can't train that here",
  "Queue is full", "Not enough crystals", "Population cap reached". Barracks `trainable_types()` order =
  slots 1-4 (Z X C V per the new Keys line).
- Site: `is_constructed() == false`, `construction_progress()` 0-1, `hp`/`max_hp` (rises from 10 %),
  `cancel_construction()` (Delete key). Right-click an own unfinished site with workers selected ->
  `worker.command_build(site)` (resumes a paused site). `build_speed()` / `builder_count()` for the panel.
- `destroyed(building)` fires on destruction **and** on cancel (`building.cancelled` tells which). The node is
  freed 5 s later: deselect on `destroyed` or check `is_instance_valid` (`_building_alive` already does).
- Build menu: `BuildingType.buildable_for(&"fire")` -> [Hearth, Ember Hall, Ember Spire] (`hotkey_label` Z X C),
  `type.cost`, `type.build_time`, `type.max_hp`, `type.footprint` (cells of 2 m), `type.size_m()`.
- Ghost: `main.build_grid.snap(mouse_world_pos, type.footprint)` -> centre; `check(type, centre, team)` -> "" or
  the message; confirm with `place(type, centre, team, selected_workers)` (returns the site or null, reason in
  `build_grid.last_reason`; on "Not enough crystals" it fires `Economy.spend_failed` like the keep).
  `check` is cheap enough to call every frame for the ghost. Rule order: Outside the map, Blocked (building),
  Too close to a crystal node, Not on walkable ground, Blocked (enemy unit), Not enough crystals,
  Population limit reached. "Unexplored" is not checked until fog exists.
- Worker extras: `is_building() -> bool`, `build_site`.
- Start hint: `main.gd` shows "Click your Keep (bottom-left) to train workers — select workers and press B to
  build" for 10 s with `hud.show_message`.

# Wave 2 session B (task 2.G3, from gameplay-coder)

## Dead wizards now stay in the tree (hidden) and can respawn
- `Wizard.die()` no longer frees her: after the 0.35 s death tween she is `visible = false`, `is_alive() == false`,
  out of group `"units"` (still in `"heroes"` / `"enemy_heroes"`), collision layer 0, physics off, hp 0.
  `is_instance_valid(hero)` stays true: always test `hero.is_alive()`.
- `Wizard.respawn(at)` brings her back (full HP / mana) and emits `respawned(wizard)`.
- Please handle:
  - `selection_panel.gd` `_update_hero()`: the dead branch greys `hero_name` (`modulate`, `disabled = true`)
    but the alive branch never restores them. Reset both when she is alive again (or on `respawned`).
  - Spec: select her automatically on respawn (player side), e.g. `hero.respawned.connect(...)` ->
    `selection.select_units([hero])` (or systems does it in `main.gd`; agree with systems-coder).
  - Hero column countdown "Vessa returns in 24 s" (the timer lives in `main.gd`, systems).
  - F1 / Space while dead should centre on the keep, not on `hero.global_position` (her death spot).

## Team.NEUTRAL (Ruin Wardens)
- `Unit.Team.NEUTRAL` (= 2). `minimap.gd` draws neutral units with `ENEMY_COLOR` and would draw a neutral building
  with the player colour. Suggested: `Unit.team_color(team)` (green / red / grey-gold `Color(0.9, 0.78, 0.42)`).
- Selection: neutral units are not the player's; right-click on them already orders an attack
  (`target.team != PLAYER`).

## Skirmish (2.S3, from systems-coder)
The 1v1 scene is `scenes/skirmish.tscn` (`Skirmish`, `scripts/world/skirmish.gd`, extends `main.gd`). The level is
`get_tree().current_scene`; check `has_method(...)` so `main.tscn` (mission 1) keeps working.
- Respawn select: **done by systems** (`selection.select_units([hero])` on respawn). Space while dead centres on
  the keep: done in `main.gd`. F1 while dead (spec: centre on the keep) is yours: `level.keep`.
- Hero column countdown: `level.respawn_time_left(team) -> float` (0 = alive), text `Vessa returns in %d s`
  (`ceili`). Signals `wizard_fell(wizard, respawn_in)`, `wizard_respawned(wizard)`.
- Top bar match timer: `level.match_time_text()` -> `"m:ss"` (`match_time() -> float`, starts at the navmesh bake).
- End screen: on `match_ended(winner_team)` systems calls `hud.show_banner("VICTORY"/"DEFEAT", colour)` and puts
  `level.end_screen_text()` (4 lines: time, 4 stats, crystals, "F9: play again") in `show_message` for good. A
  nicer block (3.U2) can read `level.stats_of(team)` -> `{trained, lost, killed, buildings_destroyed, gathered}`.
- Surrender: F10 is handled by `skirmish.gd` (`_unhandled_input`); please don't bind F10.
- The crown: `level.crown` (`EmberCrown`, also `level.artifact` for the minimap: it follows its wearer).

## From systems-coder, task 5.S1 (fog of war core)
`main.fog` (`FogOfWar`, group "fog", `FogOfWar.find()`): `state_at(team, pos) -> int` (0/1/2), `is_visible(team, pos)`,
`is_explored(team, pos)`, `get_state(pos)` (local team), `enabled`, signal `updated` (5 Hz), `grid_image(team) -> Image`
(60 x 60 R8, 0 / 140 / 255, pixel (i, j) = world x in [2(i-30), +2), z in [2(j-30), +2); cached per update, don't modify).
Needed in scripts/ui/:
- Minimap: draw `grid_image(Unit.Team.PLAYER)` (as an ImageTexture updated on `updated`) under the icons; skip enemy /
  neutral units and buildings with `visible == false`; draw nodes in group "fog_ghosts" (Node3D, global_position) as
  6 x 6 (0.55, 0.55, 0.6); crystal nodes / artifact only when `visible`.
- Selection (click, box, double-click, right-click attack target): ignore enemy units / buildings whose
  `is_visible_in_tree()` is false (they keep their collision). Deselect them if they go hidden while selected.
- Build placement: refuse `Unexplored` when `not fog.is_explored(team, cell_center)` (BuildGrid.check doesn't check the fog yet: it would block the bot's expansions, lead to decide).

## 6.B2 (systems, balance-1) - crown seal timer
- `level.crown_unseal_time_left() -> float` (seconds, 0 once claimable; also on `level.crown`) for a
  "Crown unseals in m:ss" timer. The level already shows "The Ember Crown stirs..." (5:30), "The Ember Crown
  awakens" (6:00) and "The Ember Crown is sealed until 6:00" (Vessa on the pedestal) via hud.show_message.
- Keep tooltip / panel: keeps now have attack_damage 12 / range 10 / cooldown 1.5 in their BuildingType.

# Step 7 (M7.S1, from systems-coder): minimap flame lines of mission 1
- Braziers are in group `"braziers"` (`MissionBrazier`, `scripts/campaign/mission_brazier.gd`). `minimap_flame_line() -> Array[Vector3]` returns `[from, to]` (brazier -> crown) once lit, else `[]`. Please draw it in `minimap.gd` as an orange `(1.0, 0.5, 0.15)` line (spec: each lit brazier draws a flame line toward the crown). `progress` (0-1) and `lit` are readable too.


# Step 8 (8.S1, from systems-coder): pop cap 50 for Nature
- The top bar's pop maximum: `economy.max_pop_cap` (50 for a Nature team, else 40); `pop_cap` stays the current cap.
- Nature `BuildingType`s: `nature_keep` Heartwood, `nature_barracks` Grove Hall, `nature_hollow` Seed Hollow (max 3),
  `nature_tower` Bramble Spire. New fields a tooltip may show: `idle_regen_pct` (1.0 = 1 % HP/s after 10 s without
  damage, `Building.IDLE_REGEN_DELAY`), `aura_radius` 8 / `aura_stats` `{hp_regen: 2}` (friendly non-worker units).
- `Building.active_builder_count()`: builders not frozen (`builder_count()` still counts every registered one).

# Step 8 (8.S2, from systems-coder): any kingdom on either side
- `Skirmish.player_kingdom` exists now (`&"fire"` default; `&"shadow"`, `&"ice"`, `&"nature"`), next to `enemy_kingdom`.
  Please set it from the menu like `MenuFlow.apply_enemy_kingdom` (before the level enters the tree, also on F9 reload).
  `Skirmish.kingdom_available(k)` (static) says if a kingdom can start; `kingdom_of(team)` gives the one really played
  (an unavailable one falls back to Fire / Shadow as a whole). `Skirmish.KINGDOMS[k]` has "name" and "hero".
- The skirmish calls `UIStyle.set_kingdom(player_kingdom)` in `_ready`; `GameHUD.setup` then re-derives it from the
  wizard's `kingdom` (works for all 4 if `UIStyle.SKINS` has the key).
- Seen in every skirmish run of tests/test_8_s2.gd: `ERROR: Invalid polygon data, triangulation failed` from
  `UIStyle.draw_emblem` (ui_style.gd:576) via `selection_panel._draw_emblem` (a non-Fire emblem polygon).
- Texts still saying "Vessa" for the player's wizard: hud.gd help lines (80-83), inventory_bar / shop comments.

# Step 9 (task 9.C4, from systems-coder): bounty flags for 9.C7 / 9.C8
- `BountyBoard.for_team(team)`: `kind_for(target) -> int` (0 HUNT, 1 EXPLORE, 2 GUARD, 3 ESCORT, **-1 = nothing can be
  placed**: own champion, tavern, neutral building; null / props = EXPLORE), `min_stake(kind)`, `place(kind, target, pos)`,
  `raise(bounty, amount)` (`"Max bounty"`...), `remove(bounty) -> int`, `bounty_on(target)` (for the "Raise +25" cursor).
  Placing on an already flagged target (or within 8 m of an Explore flag) raises it by 25.
- **Messages:** the board already shows its own lines on `current_scene.hud.show_message` for the local team
  (`Bounty paid...`, `Bounty refunded: 75`, `A bounty of 150 is on Vessa!`, `Sable Quint took your bounty on the Gloom
  Hall`). If you prefer to route them yourself set `board.show_on_hud = false` and use the `message(text)` signal.
- **Clicks:** each flag has a child `StaticBody3D` "ClickBody" on layer 2 (its parent is the `Bounty`, also
  `collider.get_meta(&"bounty")`); its layer is 0 while the local team cannot see the flag.
- **Visibility (world + minimap):** `bounty.is_visible_to(team)` (own flags always, else the team's fog), `is_shown()`
  for the local view. The Bounty root stays `visible`; only its look is hidden.
- **Flag card:** `kind_name()`, `target_name()`, `stake`, `paid`, `unpaid()`, `active_pursuers()`, `time_left()`
  (-1 = no timer), `refund_preview()` (what Delete gives back now), signal `changed`.
# Step 9 (task 9.C3, from systems-coder): taverns and ChampionGuild for 9.C7 / 9.C8
- **Guild:** `ChampionGuild.for_team(team)` (null on maps without taverns, e.g. main.tscn / mission 1). Also
  `level.guild_of(team)` on the skirmish. Read: `champions: Array` (spawned: alive / reviving / fallen, oldest first),
  `roster_size()` (+ hires on their way), `is_open()`, `hire_cost(id)` / `next_hire_cost()` = price of the n-th hire
  (roster size + 1) `{crystals, essence}`, `next_name(id) -> String` (A or B for this team), `can_hire(id) -> String`,
  `has_archetype(id)`, `champion_of(id)`, `is_hiring(id)` / `hire_time_left(id)` (3 s walk-out), `archetype_of(ch)`,
  `is_fallen(ch)`, `is_reviving(ch)`, `revive_cost(ch)`, `revive_duration(ch)`, `revive_time_left(ch)`,
  `can_revive(ch) -> String` (`"Not fallen"`, `"Already reviving"`, `"No home"`, `"Not enough essence"`),
  `dismiss_value(ch)`, `held_taverns() -> Array`, `is_tavern_held(tavern) -> bool`, `unpaid`, `living_count()`,
  `upkeep_time_left()`. Act: `hire(id) -> String`, `revive(ch) -> String`, `dismiss(ch) -> int` (the double-click
  within 3 s is yours). Signals: `roster_changed`, `champion_hired(ch)`, `champion_fallen(ch)`, `champion_revived(ch)`,
  `champion_dismissed(ch, refund)`, `upkeep_ticked(paid, amount)`, `unpaid_changed(unpaid)`.
- **Messages** (`joins you`, `has fallen`, `returns in 30 s`, `leaves your service`, unpaid, the visible enemy hire) are
  already on the HUD: the skirmish connects each guild's `message(text, seconds)` to `hud.show_message`. The 2:00 line
  `The taverns open their doors` + `Y: hire champions` is shown by the skirmish too.
- **Tavern** (`scripts/world/tavern.gd`, `class_name Tavern`, group `"taverns"`, StaticBody3D on layers 1 + 2, not in
  `"units"` / `"buildings"`): `is_open()`, `time_until_open()`, `Tavern.MSG_CLOSED` (`The tavern opens at 2:00`),
  `held_by_enemy(team := 0)`, `door_point()`, `footprint_rect()` (minimap square, 6 x 6), `set_selected()` no-op,
  `is_tavern()`. A click lands on the tavern body itself (`_in_group_upwards(hit.collider, "taverns")`).

# Step 9 (from ui-coder 9.C8, for 9.C7)
- `selection.inspected: Unit` = the champion clicked in the world (own, or an enemy one in sight); `selection.selected`
  stays **empty** while inspecting (nothing can order it). Kept while fallen; cleared by any other selection, Esc, when
  freed, or (enemy) when the fog hides it. `selection.is_inspecting()`, `selection.inspect_unit(u)`.
- `selection.selected_bounty: Node3D` = the selected flag (own or visible enemy); `is_own_bounty_selected()`,
  `raise_selected_bounty(amount) -> String`, `remove_selected_bounty() -> int`, `flag_at(screen_pos)`,
  `orderable_units()` (the selection minus anything with `is_commandable() == false`).
- `CommandCard.inspect_text()` returns the two lines of the inspect block (`Champions act on their own.\nBounty  [R]`,
  enemy `Hunt it with a bounty  [R]`), "" while hidden: for `tests/test_9_c7.gd`.
- `BountyMode` has `is_active()` (your tavern-click check) and is in group `"bounty_mode"`.

# Step 9 (task 9.C9, from ai-coder): freed intent target in champion_barks.gd
- `scripts/vfx/champion_barks.gd:310` `_intent_target`: `t is Object and is_instance_valid(t)` raises
  "Left operand of 'is' is a previously freed instance" when a champion's `intent_target` (e.g. a hunted worker) was
  freed. Check `is_instance_valid(t)` first: `return (t as Object).get_instance_id() if is_instance_valid(t) and t is Object else 0`.
  Seen 3 times in `tests/test_9_c9.gd --only=hard` (the test frees the workers a Hunt flag was on).

# Step 10 (task 10.C5, from systems-coder): HuntersGuild API for the Lodge tab (10.C8)
- `HuntersGuild.instance(get_tree())` (null when trade is off; reach it via the group `"hunters_guild"` or a load
  guard). Kinds `&"outriders"`, `&"sweep"`. Per row: `contract_cost(kind)`, `contract_trackers(kind)`,
  `contract_duration(kind)`, `can_hire(team, kind) -> String` (reason for the disabled button), `hire(team, kind)`,
  `is_running(team, kind)`, `contract_time_left(team, kind)`, `cooldown_left(team, kind)`, `time_until_open()`.
  Signals `contract_started(team, kind, contract)` (horn sound), `contract_ended(team, kind)`,
  `reward_paid(team, amount)`, `message(text, seconds)` (the level connects it to the HUD).
- Tracker inspect: trackers carry metas `&"tracker_kind"` (kind) and `&"tracker_contract"` (the contract node:
  `time_left()`; TrackerContract also sets meta `&"contract"`).
# Task 10.C2 (systems): Bazaar API for 10.C7 / 10.C8
- Build menu: `BuildingType.buildable_for(faction)` now ends with the kingdom's Bazaar (`<kingdom>_market`, kind
  `&"market"`, `hotkey_label` "B") **only while `BuildingType.trade_active()`**. `command_card.gd`'s
  `BUILD_KEY_SLOTS` has no "B" yet (it lands in the first free slot); spec slot r2c2 = index 5. `selection_manager`
  `_type_for_key` maps "B" fine, but B also opens the build menu: in the open menu B must place the Bazaar.
- Disabled-button reasons (position-free), in this order: `BuildGrid.prerequisite_reason(type, team)`
  ("Needs a completed Hall"), crystals, then `BuildGrid.at_limit(type, team)` -> `BuildGrid.limit_message(type)`
  ("Only one Bazaar"; the Hearth / Wall messages unchanged). `selection_manager.build_reason` still returns
  `MSG_LIMIT` for every limit: switch it to `limit_message`. The ghost's per-cell reason comes from `BuildGrid.check`
  (adds "Needs a completed Hall", then "Must be within 20 m of your keep", before the crystals).
- Market (`scripts/buildings/market.gd`, reach it without the class name: group `"markets"`):
  `Market.of_team(team)` (NOT `for_team`: that is Building's and returns an Array), `route_post` (get = the chosen
  post or the default near post; set = `set_route`), `set_route(post) -> String` ("", "Not a trading post",
  "Route too short"), `route_value() -> int`, `route_value_to(post) -> int`, `route_length_to(post) -> float`,
  `is_far_post(post) -> bool`, `default_route()`, `has_explicit_route()`, `caravans() -> Array`,
  `queued_caravans() -> int`, `Market.caravan_count(team, include_queued := true)` (for `Caravans 4 / 6 (1 queued)`),
  `CARAVAN_LIMIT` 6, signal `route_changed(market, post)`. Training: the TrainingBuilding queue API
  (`trainable_types()` = [caravan], `can_queue` adds "Caravan limit reached"). The Bazaar has **no rally flag**:
  right-click should set the route (the inherited `set_rally_point` still exists but shows nothing).
## From 10.C3 (Caravan, `scripts/economy/caravan.gd`; reach it through group `"caravans"` / has_method)
- Card / panel: `command_trade(target) -> String` ("" / "Not a trading post" / "No Bazaar" / "Route too short"):
  a post = this caravan's route from now on (loaded: delivers first); the own Bazaar = go home, deliver, follow the
  Bazaar's route. `cargo: int`, `is_loaded()`, `route_post`, `home_market`, `trade_state`, `state_text()`
  ("To Saltgate", "Loading", "Trading", "Returning with 119", "Waiting: Saltgate is held",
  "Waiting: posts open at 4:00", "Waiting: no Bazaar", "Idle"), `step_time_left() -> float` (load / trade / held wait).
- Signals: `cargo_changed(caravan, amount)`, `delivered(caravan, amount)` (use it, or `TradeNetwork.delivered`, for
  the floating `+28`), `robbed(caravan, amount, thief)`.
- The caravan itself already shows (PLAYER only, `current_scene.hud.show_message`, throttled as section 8 says):
  `Your caravan was robbed: -N gold` (summed per 10 s), `Your caravan was destroyed` / `N of your caravans were
  destroyed` (summed per 10 s), `<Post> is held by the enemy: your caravans wait` (max once per 30 s).
  **Do not show these three again** from hud.gd / trade_popups.gd.

# Step 10 (task 10.C1, from systems-coder): trade map for 10.C7 / 10.C8
- Posts: group `"trade_posts"` (`TradePost`, a StaticBody3D on layers 1 + 2, so a layer-2 click ray hits it directly):
  `post_id`, `display_name`, `sign_index`, `door_point()`, `is_open()`, `holder_team()` (-1 / 0 / 1),
  `is_held_by_enemy_of(team)`, `footprint_rect()` (6 x 6), `set_selected(bool)`. Guild houses: group `"guilds"`
  (`GuildHouse`): `kind` (`&"den"` / `&"lodge"`), `display_name` ("Magpie Den" / "Greywater Lodge"), `guild_name`
  ("Thieves' Guild" / "Hunters' Guild"), `door_point()`, `is_open()` (5:00), `footprint_rect()`, `set_selected(bool)`.
- `TradeNetwork.instance(get_tree())` (null with trade off): `posts()`, `post_by_id(id)`, `road_segments()` (10 x
  [a, b], y 0: the minimap road layer), `route_points(market, post)` (waypoints after the Bazaar, door last: prepend
  the Bazaar for the route line), `route_value(market, post)`, `route_length(...)`, `route_reason(...)`
  ("" / "Trading posts open at 4:00" / "Route too short" / "Held by the enemy"), `is_far(team, post)`,
  `time_until_open()`, `trade_income(team, 180)`, `traded_total(team)`. Signals: `posts_opened`,
  `post_held_changed(post, holder_team)`, `delivered(team, caravan, amount, post)`, `loot_picked(team, amount, sack)`
  (team 2 = a Magpie took it: use it for `Picked up a loot sack: 60 gold`, own team only).
- The skirmish already shows `The trading posts open their gates` + the Bazaar hint at 4:00 (do not repeat it).
  The end-screen gold line is in `Skirmish.end_screen_text()`; `Skirmish.trade_stats_of(team)` has the numbers.
- Loot sacks (group `"loot_sacks"`, `LootSack`: `amount`, `time_left()`) hide themselves in fogged cells.
# Step 11 (task 11.C1, from gameplay-coder): class data for 11.C4
- The level-2 draw emits `Champion.class_chosen(champion, class_id)` (before `level_changed`); show the message
  `<name> takes up the <ChampionClass.find(id).display_name>` from it (own champions; enemy ones when visible).
  The champion itself already plays `ChampionVfx.play(&"class_chosen", ch, ch)` and calls
  `ChampionBarks.bark(ch, &"class_chosen")` (group `"champion_barks"`, 100 %, cooldown / visibility rules), whose
  cooldown swallows the level-up bark at level 2: do not bark it again.
- Class data: `ChampionClass.find(id)` / `all()` (`display_name`, `tooltip`, `icon_abbrev`, `is_ranged`,
  `ability_ids`, `unlock_levels`), `ChampionClass.chances_for(champion)` (class id -> 0..1, live leans: the inspect
  `leans Sword and Shield (71 %)` tooltip), `ChampionClass.usual_for(champion_type)` (tavern "usually ...").
- Names: `ChampionType.ability_name(id, fallback)` / `ability_text(id, fallback)`: the Wayfinder's `flare_arrow` is
  **Signal Flare** (+ new text). `champion_bar.gd` has its own "Flare Arrow" copy: read the type's name instead.
- XP bars: `Champion.LEVEL_TOTAL_XP` is now `[0, 190, 500, 940, 1500, 2190]` (`xp_to_next()` already follows).

# Step 10 (task 10.V12, from tech-artist): trade icons are in
- All at the paths of ui-trade.md 15 (128 x 128, transparent, no baked frame), found by `IconLibrary.icon_for(kind, id)`
  / `HudSkin.icon(kind, id)`: `units/caravan|magpie|greywater_tracker`, `buildings/<fire|shadow|ice|nature>_market`,
  `buildings/magpie_den|greywater_lodge`, `posts/<post_id>`, `wares/<ware_id>`, `contracts/outriders|sweep`,
  `orders/trade|route|wares` (the ids `command_card.gd` already asks for). Singular kinds `post` / `ware` / `contract`
  are accepted too. Nothing to change for these: the fallbacks switch off by themselves.
- Optional glyphs (15 last row, "may replace later"), same size, drawn to read at 16 / 12 / 10 px:
  `ui/gold_coin` (the 16.2 coin look), `ui/exchange_crystals` (coin -> crystal), `ui/exchange_essence`
  (coin -> essence flame), `ui/crest_bazaar` (teal shield, gold balance scale), `ui/crest_lodge` (grey-green
  shield, bone horn). Use them with `texture_filter = LINEAR_WITH_MIPMAPS` if you want them; the code-drawn coin
  stays fine. Contact sheet with every icon at its UI sizes: `docs/art/screens/trade_icons.png`.

# Step 12 (task 12.V16, from tech-artist): Map detail for the cosmetic critters
- `CritterSystem` (`art/environment/critters/critter_system.gd`) reads `GameSettings.map_detail` at its build (match
  start) through `load("res://scripts/ui/menus/game_settings.gd")`: it calls `ensure_read()` if present, then
  `get(&"map_detail")`. Please add it as a **static var** (like `control_scheme`), `StringName` (or String)
  `&"high"` / `&"low"`, default `&"high"`, saved with the other settings. `&"low"` = no cosmetic critters (the deer /
  rabbits of 12.C10 stay). While the field is missing the critters use "high".
- (12.V6) `MapDressingArt` (`art/environment/map_dressing_art.gd`) reads the same `GameSettings.map_detail` the same
  way when the map loads: `&"low"` halves every decor count (biome sets, undergrowth, cliff-foot clumps). The setting
  applies at the next match, as ui-mapfill / map-fill.md 12.C7 say ("at the next match").

# Step 12 (task 12.C10, from systems-coder): game critters (deer / rabbits) for 12.C6 / 12.C7
- `GameCritter` (`scripts/world/game_critter.gd`, group `"game_critters"`, NOT in `"units"`): child `"ClickArea"`
  (Area3D, layer 2, mask 0; its layer is 0 while hidden or dead). The selection ray needs `collide_with_areas = true`
  on layer 2; walk up from the area to the node with `is_game_critter()`. `visible` = local fog (+ hidden when far
  outside the camera view), so the existing `_is_hidden()` check already skips fogged critters.
- Right-click / A-click with units selected = `command_attack(critter)` **only** for units where
  `not u.is_non_combatant()` and `not u.has_method(&"command_gather")` (workers: `Worker.command_attack(target: Unit)`
  is typed and would error on a critter), no caravans, no trackers. Bounty flags on a critter: `"Invalid target"`.
- Card (read only): `display_name` ("Red deer" / "Rabbit"), `hp` / `max_hp`, `reward` (`{&"essence": 5}` / `{&"essence": 1}`),
  `kind`; venison numbers `CritterHerds.VENISON_HEAL` (40) / `VENISON_AREA_HEAL` (20).
- Floating text: `CritterHerds.critter_hunted(critter, team: int, reward: Dictionary)` (find the node with
  `get_first_node_in_group(&"critter_herds")`); show `+5` / `+40` (deer) or `+1` only when `team` is the local team
  and the critter is visible. End screen: `Skirmish.mapfill_stats_of(team)["game_hunted"]` (= `hunted_count(team)`).
## From lab group C (Audio Lab / Data Lab review, 2026-09-27)
Audio Lab v1.1 (`docs/audio/lab/review_after/scorecard.md`, set `res://assets/audio`, 98 / 100, 0 FAIL):
- **building_hit takes differ by 5.1 dB** (`building_hit`, `building_hit_1`, `building_hit_2` at their in-game level):
  a random pick jumps out. Re-render the takes (`assets/audio/takes_sfx_generator.gd`) at the parent's loudness, target <= 2 dB spread.
- **ability_cast is 3 dB too quiet for a spell cue** (-23.4 LUFS in game vs spell -22..-9): raise `VOLUMES[&"ability_cast"]`
  in `scripts/ui/game_audio.gd` from -8 to about -5 dB (or re-render louder).
- **building_collapse / fireball_explode / spell_ember_step peak at -0.3..-0.7 dBTP**: the source .wav files themselves peak
  there (the QOA import adds < 1 dB, measured), so normalise the files to -1 dBTP in their generator.
Data Lab v1.1 (`docs/data/lab/review-after/`): **T7 = 244 hard-coded UI strings (235 distinct), 0 through tr()**.
`ui_strings.csv` in that folder lists key, file, line, text for every literal (suggested keys `UI_...`): import it as a
CSV Translation and wrap the literals in `tr(KEY)`, biggest scripts first (selection_panel.gd 57, trade_window.gd 33,
tavern_window.gd 31). Only when the French pass is scheduled.

## From lab group A (UI Lab v2 review, 2026-09-27)
UI Lab v2 (`docs/ui/lab/scorecard.md`, laptop 1600x900 + 1920x1080, FAIL 96). New checks measured 3 of the v1 "seen" items:
- **Skirmish setup panel 4 px from the bottom edge at 1600x900** (`MainMenu > PanelContainer`, WARN edge): shrink it or keep >= 8 px (the lab accepts flush 0 px too).
- **Settings "Fullscreen" switch invisible when off** (`SettingsPanel > CheckButton`, WARN icons): only 16 % of its icon area is drawn (the knob dot; the track does not show on the dark panel). Give the unchecked icon a visible track / outline (>= 3:1 on the panel).
- **End screen lets the selection text show through** (`SelectionPanel > Label "4 selected ..."` and 4 more under the end panel, WARN bleed): `UIStyle.frame_style` texture centre alpha is 0.92. Make the end panel centre opaque, add a dimmer behind it, or hide the selection panel while `end_panel` is visible.
- Still open from v1: champion slot text contrast FAIL (2.6-3.0 : 1, rule 4.5), F5-F7 badges 10 px, help lists G twice.
- The HUD-at-3440 gap (bottom bar keeps 1600 px) is now a FAIL check (`gaps`) but only runs on a >= 3440x1440 screen (desktop).

# Replay Lab determinism (lab review 2026-09-27, group B; details: docs/plan/replay-lab.md 'Determinism audit')
- **Step 1**: one `_REPLAY.note(&"call", [node, &"method", args...], selection)` right before the gameplay call in
  bounty_mode (flag placement), tavern_window / champion_bar (hire / revive / dismiss), trade_window (wares, exchange,
  Lodge contracts), shop_window / inventory_bar (buy / sell / swap / drop), command_card (queue `cancel(slot)`) and
  concede. The node must be an entity (rid) or have a deterministic path from the level.
- **Step 4**: settings toggle "Record replays (F8 bug reports)" (sets `ReplayHooks.auto_record`, saved in settings.cfg,
  ON on the laptop for playtests) + pause-menu button "Save bug report" (`ReplayHooks.session.save_bug_report()`).
- `selection_manager.gd` `_process` -> `_update_pickup` / `_take_pickup`: hero pickup walking lives in the UI; prefer a
  `Wizard.command_pickup` (with gameplay-coder) so replays don't depend on the SelectionManager processing.
# Voice Forge hookup (Voice Forge agent, 2026-09-27; tools/voice_forge/README.md)
- **New file `scripts/ui/voice_player.gd`** (`VoicePlayer extends AudioStreamPlayer`) + **2 load-guarded lines in
  `mission_hud.gd`** right after `root.add_child(dialogue_box)`: the player is a child of the DialogueBox, follows its
  `line_started(speaker, text)` and plays `data/voice/manifest.json`'s WAV for that line (Kokoro voices, JS request).
  No manifest / no WAV for a line = silent, no connection, nothing changes. Bus `Voice` if it exists, else `SFX`, else
  `Master`; volume -2 dB; ducks nothing. Pausing the tree pauses the voice (process mode inherited).
- **Please (small, when you can):** hold a line as long as its voice. DialogueBox shows every line `LINE_SECONDS` (5 s);
  a few voiced lines run 5-6.5 s and get cut when the next queued line starts. In `_next()`:
  `var vp := get_node_or_null(^"VoicePlayer"); _time_left = maxf(LINE_SECONDS, vp.line_duration(_speaker, text) + 0.4) if vp else LINE_SECONDS`
  (and use the same value in `_draw_timer`). Optional: a "Voices" volume slider (`Voice` bus) / "Voices off"
  (`VoicePlayer.enabled = false`) in Settings. You own both files; move / restyle the player freely, keep
  `play_line(speaker, text) -> bool`, `has_line`, `line_duration`, signal `voice_started` (tests/test_tool_voice_forge.gd uses them).

## From gameplay-coder (bowmen, 2026-09-27): Hall upgrade buttons (docs/design/bowmen.md 4 / 7)
- Each skirmish Hall now lists its kingdom bowman as slot 5 (key B): Frostbow / Scorchbow / Bleakbow / Wildwood Archer.
  Please add `TRAIN_DESCRIPTIONS` lines (bowmen.md 3) and icons `art/icons/units/<id>.png` when made.
- Upgrades bought at that Hall: rows from `BowmanUpgrades.options_for(hall) -> Array[Dictionary]` (`id, name, text,
  crystals, time, state` &"ready" / &"working" / &"done" / &"locked", `progress` 0-1, `reason` "" = can buy). Click ->
  `BowmanUpgrades.for_team(hall.team).buy(id, hall)` (returns "" or the refusal). Signals on that node:
  `upgrade_started(id)`, `upgrade_completed(id)`, `upgrade_cancelled(id, refund)`. Suggested: row 2 of the Hall card
  after Set Rally, keys N / M (+ one more for the Grove Hall's 3 rows), tooltip = `text` + price + time.

- 2026-09-27 (gameplay-coder, new-units-12.md): FYI I edited your files for the 8-slot Hall: `selection_manager.gd` SLOT_KEYS / SLOT_LETTERS now Z X C V B N M , and `command_card.gd` `_building_slots` shows up to 8 training buttons + rally (tooltip falls back to `NewUnits12.description`). Please review; AZERTY labels for N M , still print QWERTY letters.

- 2026-09-27 (systems-coder, tiers wave, docs/design/tiers.md): FYI I edited `command_card.gd`: (1) a train type's
  tooltip falls back to `type.get_meta("card_text")` (the keep's Stronghold / Citadel stub button, slot 2 X);
  (2) Hall r3c4 **+** opens a "+" upgrades page (`plus_hall`, `_plus_slots`: `UnitUpgrades.options_for(hall)` ->
  `buy(id, hall)`, Back at r3c4), click only. Wanted: hotkeys on that page (they still train while it is open), a
  progress ring for `working` rows, a panel chip `Stronghold 35 % · 39 s` on the keep (`Keep.upgrade_progress()` /
  `upgrade_time_left()`), and the Bowman upgrades (above) could live on the same page.

# Fix batch F3b (systems, 2026-10-12): U2-4 keep side
- The keep's tier stub (`Keep.TIER_STUB_ID`) now carries meta `Keep.CARD_NO_COST_META` (`&"_card_no_cost"`): true while
  the upgrade runs (the "Cancel Stronghold / Citadel" button, cost 0, pop 0). Wanted in `command_card.gd` (~line 914):
  when `type.get_meta(&"_card_no_cost", false)` is true, build the tooltip head without the "Cost %d crystals · Pop %d"
  line (its `card_text` already says the progress, time left and the refund). The stub's `display_name` is now already
  translated (`Loc.t("Cancel %s") % Loc.t(tier name)`), so a `Loc.sink` on it is harmless.

# Fix batch F3a (systems, 2026-10-12): meta rename `tracker_contract` -> `_tracker_contract`
`HuntersGuild` now tags a Greywater Tracker with meta `&"_tracker_contract"` (runtime marker, `_` = never saved; review
RC hygiene). `selection_panel.gd` `tracker_contract_text` (~line 1277) still looks up `&"tracker_contract"` then
`&"contract"`, then falls back to the group `"tracker_contracts"`, so it keeps working; please add `&"_tracker_contract"`
to its key list (first) and drop `&"tracker_contract"`. `NeutralCamp.CAMP_META` is now `&"_neutral_camp"` (UI reads it
through the constant / `CampManager.camp_of`, nothing to change).

# Fix batch F1 (save framework, 2026-10-12): V1-1 load refusal text
`SaveGame.load_slot` now refuses a load while a film plays: `SaveGame.REASON_FILM_LOAD := "Can't load during a film"`
(logic text, shown like the other SaveGame reasons). Please add it to `PauseMenu.SAVE_TEXTS` (pause_menu.gd ~line 323;
`tests/test_save_load.gd` fails until it is listed), then `tools/i18n/extract_strings.gd '--' merge` and the French line.
