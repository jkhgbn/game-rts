class_name Stables16
extends Node
## The Stables: 4 mounted units per kingdom, 16 in all (docs/design/stables.md; JS 2026-09-27 "ajoute une ecurie ou all 4
## wiz have 4 unit each: 1 T1 with upgrade to T3, T2 with upgrade to T3, and a true T3 unit").
## Card (StablesBuilding): Z = tier-1 rider (has a rank-3 upgrade), X = tier-1 harrier (ranged), C = tier-2 heavy
## (has a rank-3 upgrade), V = tier-3 elite, B / N = the two rank-3 upgrades (Citadel), then Set Rally.
## Static side: roster, rank-up stub types, descriptions, apply_rank, the bot. Instance side: one node per team (group
## "stables16", like UnitUpgrades) holding the rank research (pay on start, one at a time per Stables, permanent, Stables
## destroyed = 75 % refund). The whole feature hangs on ENABLED.

signal rank_started(unit_id: StringName)
signal rank_completed(unit_id: StringName)
signal rank_cancelled(unit_id: StringName, refund: int)

## THE switch: false = no Stables in the build menu, no rank-ups, bots never build one.
const ENABLED := true

const STABLES_IDS := {
	&"fire": &"fire_stables", &"shadow": &"shadow_stables", &"ice": &"ice_stables", &"nature": &"nature_stables",
}
## Card order Z X C V per kingdom (stables.md 2).
const ROSTER := {
	&"fire": [&"blaze_rider", &"emberdart_harrier", &"pyrehoof_lancer", &"sunforge_cataphract"],
	&"shadow": [&"gloam_rider", &"duskbolt_harrier", &"barrow_knight", &"veilborn_dreadrider"],
	&"ice": [&"snowdrift_rider", &"rime_harrier", &"rimehorn_rider", &"frostcrown_juggernaut"],
	&"nature": [&"stagrunner", &"bramble_harrier", &"thornback_charger", &"glade_outrider"],
}
## Rank-3 upgrades (stables.md 3): unit id -> the name its riders carry once ranked.
const RANK_NAMES := {
	&"blaze_rider": "Blaze Captain", &"pyrehoof_lancer": "Pyrehoof Warlord",
	&"gloam_rider": "Gloam Marauder", &"barrow_knight": "Barrow Dreadlord",
	&"snowdrift_rider": "Snowdrift Captain", &"rimehorn_rider": "Rimehorn Warden",
	&"stagrunner": "Elder Stagrunner", &"thornback_charger": "Thornback Warden",
}
const RANK := 3
const RANK_TIER := 3
const RANK_MODIFIER := &"rank3"
const RANK_STATS := {&"max_hp_pct": 0.25, &"attack_damage_pct": 0.20, &"armor": 10.0, &"move_speed": 0.3}
## Price / time by the unit's own tier (1 or 2).
const RANK_PRICE := {1: 175, 2: 225}
const RANK_TIME := {1: 45.0, 2: 60.0}
const DESTROYED_REFUND := 0.75
const STUB_PREFIX := "rank3_"

const DESCRIPTIONS := {
	&"blaze_rider": "Tier 1 shock cavalry. Beats archers and casters, loses to spears and guards. Rank 3: Blaze Captain.",
	&"emberdart_harrier": "Tier 1 mounted javelins. Hit and run; fragile up close.",
	&"pyrehoof_lancer": "Tier 2 heavy boar lancer. Breaks lines. Rank 3: Pyrehoof Warlord.",
	&"sunforge_cataphract": "Tier 3 elite cataphract. Armored, hits very hard.",
	&"gloam_rider": "Tier 1 lancer. Fast raider. Rank 3: Gloam Marauder.",
	&"duskbolt_harrier": "Tier 1 mounted crossbow. Hit and run; fragile up close.",
	&"barrow_knight": "Tier 2 grave knight. Heavy hitter. Rank 3: Barrow Dreadlord.",
	&"veilborn_dreadrider": "Tier 3 elite dread rider. The hardest hitter of the Stables.",
	&"snowdrift_rider": "Tier 1 armored scout; every hit chills. Rank 3: Snowdrift Captain.",
	&"rime_harrier": "Tier 1 mounted frost javelins; every hit chills.",
	&"rimehorn_rider": "Tier 2 armored breaker; hits chill 2 s. Rank 3: Rimehorn Warden.",
	&"frostcrown_juggernaut": "Tier 3 elite. The toughest rider; hits chill 2 s.",
	&"stagrunner": "Tier 1 fast skirmisher; regenerates. Rank 3: Elder Stagrunner.",
	&"bramble_harrier": "Tier 1 mounted thorn darts; regenerates.",
	&"thornback_charger": "Tier 2 heavy stag charger; regenerates. Rank 3: Thornback Warden.",
	&"glade_outrider": "Tier 3 horse archer. Long range, fast; regenerates.",
}

## Bot (stables.md 6): match time (s) from which the bot builds its Stables, by difficulty 0 easy / 1 normal / 2 hard.
const BOT_BUILD_AT := {0: 600.0, 1: 420.0, 2: 330.0}
const BOT_RESERVE := 100          ## crystals kept after placing / training
const BOT_TRAIN_EVERY := 8.0      ## seconds between two Stables queue checks
const BOT_QUEUE := 2
## Target share of the Stables units the bot keeps (Z X C V).
const BOT_MIX: Array[float] = [0.35, 0.25, 0.25, 0.15]
const BOT_SAVE := 30.0            ## seconds the bot saves crystals for the Stables before playing on
const BOT_SAVE_PAUSE := 20.0
const BOT_RANK_MIN_UNITS := 2
const BOT_RANK_RESERVE := 200

const SKIRMISH_SCRIPT := "res://scripts/world/skirmish.gd"

## Tests may set this true (the build menu lists the Stables only in a real skirmish otherwise).
static var force_enabled := false
static var _stubs: Dictionary = {}       # unit id -> stub UnitType (rank-up button)
static var _bot_next: Dictionary = {}    # team -> next bot check (match s)
static var _bot_saving: Dictionary = {}  # team -> match s the bot started saving for its Stables
static var _bot_train_saving: Dictionary = {}   # team -> match s the bot started saving for its next Stables rider

var team := 0
var researched: Array[StringName] = []   ## Unit ids ranked up (read only).
var _work: Array[Dictionary] = []        # {id, stables, left, paid}


# ---------------------------------------------------------------- static: roster

## True when the current game has the Stables: the plain skirmish (missions extend it: off) or force_enabled.
static func enabled_here() -> bool:
	if not ENABLED:
		return false
	if force_enabled:
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return false
	if tree.current_scene.has_method(&"define_objectives"):   # a mission: its cavalry_enabled knob (e2m3)
		return &"cavalry_enabled" in tree.current_scene and bool(tree.current_scene.get(&"cavalry_enabled"))
	var s: Variant = tree.current_scene.get_script()
	return s is Script and (s as Script).resource_path == SKIRMISH_SCRIPT


static func is_stables_unit(type_id: StringName) -> bool:
	if not ENABLED:
		return false
	for f: StringName in ROSTER:
		if (ROSTER[f] as Array).has(type_id):
			return true
	return false


static func all_unit_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for f: StringName in ROSTER:
		for id: StringName in ROSTER[f]:
			out.append(id)
	return out


static func stables_type(faction: StringName) -> BuildingType:
	var id: Variant = STABLES_IDS.get(faction)
	return BuildingType.find(String(id)) if id != null else null


## The 4 unit types of a kingdom's Stables, card order Z X C V.
static func roster_types(faction: StringName) -> Array[UnitType]:
	var out: Array[UnitType] = []
	for uid: StringName in ROSTER.get(faction, []):
		var t := UnitType.find(String(uid))
		if t:
			out.append(t)
	return out


## The unit ids of a kingdom with a rank-3 upgrade (Z then C).
static func rank_ids(faction: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for uid: StringName in ROSTER.get(faction, []):
		if RANK_NAMES.has(uid):
			out.append(uid)
	return out


static func has_rank_up(unit_id: StringName) -> bool:
	return ENABLED and RANK_NAMES.has(unit_id)


static func rank_name(unit_id: StringName) -> String:
	return String(RANK_NAMES.get(unit_id, ""))


static func description(type_id: StringName) -> String:
	return String(DESCRIPTIONS.get(type_id, "")) if ENABLED else ""


static func rank_price(unit_id: StringName) -> int:
	var t := UnitType.find(String(unit_id))
	return int(RANK_PRICE.get(t.requires_tier if t else 1, 175))


static func rank_time(unit_id: StringName) -> float:
	var t := UnitType.find(String(unit_id))
	return float(RANK_TIME.get(t.requires_tier if t else 1, 45.0))


## The rank-up button of `unit_id`: a stub UnitType (never trained; StablesBuilding.queue_unit starts the research).
static func rank_stub(unit_id: StringName) -> UnitType:
	if _stubs.has(unit_id):
		return _stubs[unit_id]
	var base := UnitType.find(String(unit_id))
	var s := UnitType.new()
	s.id = StringName(STUB_PREFIX + String(unit_id))
	s.display_name = rank_name(unit_id)
	s.faction = base.faction if base else &""
	s.cost = rank_price(unit_id)
	s.pop = 0
	s.train_time = rank_time(unit_id)
	s.requires_tier = RANK_TIER
	s.set_meta(&"rank_of", unit_id)
	s.set_meta(&"card_text", "Rank 3 for every %s (living and future): +25 %% HP, +20 %% damage, +10 armor, +0.3 speed. Needs a Citadel." % [base.display_name if base else String(unit_id)])
	_stubs[unit_id] = s
	return s


static func is_rank_stub(type: UnitType) -> bool:
	return type != null and type.has_meta(&"rank_of")


static func rank_stubs(faction: StringName) -> Array[UnitType]:
	var out: Array[UnitType] = []
	for uid in rank_ids(faction):
		out.append(rank_stub(uid))
	return out


# ---------------------------------------------------------------- static: rank on units

## The team's rank node (created under the current scene when missing and `create`).
static func for_team(for_team_id: int, create: bool = true) -> Stables16:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(&"stables16"):
		var b := n as Stables16
		if b and b.team == for_team_id and not b.is_queued_for_deletion():
			return b
	if not create or tree.current_scene == null or not ENABLED:
		return null
	var node := Stables16.new()
	node.name = "Stables16_%d" % for_team_id
	node.team = for_team_id
	node.add_to_group(&"stables16")
	tree.current_scene.add_child(node)
	return node


static func team_has_rank(for_team_id: int, unit_id: StringName) -> bool:
	var b := for_team(for_team_id, false)
	return b != null and b.researched.has(unit_id)


## Applies rank 3 to `unit` if its team researched it (idempotent): modifier `rank3`, metas `rank` / `rank_name`, the
## model hook set_rank(3). StablesBuilding calls it for every unit it trains.
static func apply_rank(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit) or unit.unit_type == null:
		return
	if not has_rank_up(unit.unit_type.id) or not team_has_rank(int(unit.team), unit.unit_type.id):
		return
	unit.add_modifier(RANK_MODIFIER, RANK_STATS)
	unit.set_meta(&"rank", RANK)
	unit.set_meta(&"rank_name", rank_name(unit.unit_type.id))
	if unit.is_inside_tree() and unit.model_has(&"set_rank"):
		unit.model_call(&"set_rank", [RANK])


# ---------------------------------------------------------------- instance: research

func is_working(id: StringName) -> bool:
	for w in _work:
		if w["id"] == id:
			return true
	return false


func progress(id: StringName) -> float:
	for w in _work:
		if w["id"] == id:
			return clampf(1.0 - float(w["left"]) / rank_time(id), 0.0, 1.0)
	return 0.0


## "" when the rank-3 of `id` can start at `stables` now, else the reason.
func can_rank(id: StringName, stables: Node) -> String:
	if not has_rank_up(id):
		return "No rank-up for that unit"
	if researched.has(id):
		return "Already researched"
	if is_working(id):
		return "Already in progress"
	if stables == null or not is_instance_valid(stables) or int(stables.get(&"team")) != team \
			or not bool(stables.call(&"is_alive")) or not bool(stables.call(&"is_constructed")):
		return "Needs completed Stables"
	var bt: Variant = stables.get(&"building_type")
	if not bt is BuildingType or not (ROSTER.get((bt as BuildingType).faction, []) as Array).has(id):
		return "Needs completed Stables"
	var gate := TierSystem.gate_reason(RANK_TIER, team)
	if gate != "":
		return gate
	for w in _work:
		if w["stables"] == stables:
			return "The Stables is busy"
	var eco := Economy.for_team(team)
	if eco == null or not eco.can_afford(rank_price(id)):
		return TrainingBuilding.REASON_NO_CRYSTALS
	return ""


func rank_up(id: StringName, stables: Node) -> String:
	var reason := can_rank(id, stables)
	var eco := Economy.for_team(team)
	if reason == TrainingBuilding.REASON_NO_CRYSTALS and eco:
		eco.spend(rank_price(id))   # fails on purpose: spend_failed (top bar flash)
	if reason != "":
		return reason
	var price := rank_price(id)
	eco.spend(price)
	_work.append({"id": id, "stables": stables, "left": rank_time(id), "paid": price})
	rank_started.emit(id)
	return ""


## Stops the rank research of `id`: full refund.
func cancel(id: StringName) -> void:
	for i in range(_work.size() - 1, -1, -1):
		if _work[i]["id"] == id:
			var paid := int(_work[i]["paid"])
			var eco := Economy.for_team(team)
			if eco:
				eco.add(paid)
			_work.remove_at(i)
			rank_cancelled.emit(id, paid)
			return


## Tests / cheats / campaign: finishes `id` now without paying.
func grant(id: StringName) -> void:
	if not has_rank_up(id) or researched.has(id):
		return
	for i in range(_work.size() - 1, -1, -1):
		if _work[i]["id"] == id:
			_work.remove_at(i)
	_complete(id)


func _physics_process(delta: float) -> void:
	for i in range(_work.size() - 1, -1, -1):
		var w: Dictionary = _work[i]
		var st: Variant = w["stables"]
		if not is_instance_valid(st) or not bool((st as Node).call(&"is_alive")):
			_work.remove_at(i)
			var refund := floori(int(w["paid"]) * DESTROYED_REFUND)
			var eco := Economy.for_team(team)
			if eco:
				eco.add(refund)
			rank_cancelled.emit(w["id"], refund)
			continue
		w["left"] = float(w["left"]) - delta
		if float(w["left"]) <= 0.0:
			_work.remove_at(i)
			_complete(w["id"])


func _complete(id: StringName) -> void:
	researched.append(id)
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == team and u.is_alive() and u.unit_type and u.unit_type.id == id:
			apply_rank(u)
	rank_completed.emit(id)


# ---------------------------------------------------------------- bot (commander rule 5 hook)

## Commander._rule_train calls it (stables.md 6). Builds the Stables from BOT_BUILD_AT, then keeps BOT_QUEUE units queued
## in the BOT_MIX, then (Citadel) the rank-3 of the Stables unit it has most of. `workers`: the bot's workers;
## `rally`: its army rally point. True when it spent crystals this tick (the Commander then skips its Hall this tick).
## `build_only`: only the Stables' own construction (a build, which comes before a due champion hire, champions.md
## 10); no rider, no rank-3 (the Commander passes it while a champion hire waits for crystals).
static func bot_step(for_team_id: int, faction: StringName, eco: Economy, now: float, grid: BuildGrid, workers: Array,
		keep: Node3D, rally: Vector3, difficulty: int, build_only: bool = false) -> bool:
	if not ENABLED or not enabled_here() or eco == null or grid == null:
		return false
	var next := float(_bot_next.get(for_team_id, 0.0))
	if next - now > BOT_TRAIN_EVERY * 2.0:   # a new match in the same process
		next = 0.0
	if now < next:   # between checks: keep saving if the last check started a save (build or rider)
		return _saving_now(_bot_saving, for_team_id, now) or _saving_now(_bot_train_saving, for_team_id, now)
	var saving := _bot_saving.has(for_team_id) or _bot_train_saving.has(for_team_id)
	_bot_next[for_team_id] = now + (2.0 if saving else BOT_TRAIN_EVERY)
	var type := stables_type(faction)
	if type == null:
		return false
	var st: StablesBuilding = null
	for b in Building.for_team(for_team_id):
		if b is StablesBuilding and b.is_alive():
			st = b as StablesBuilding
	if st == null:
		return _bot_build(for_team_id, type, eco, now, grid, workers, keep, difficulty)
	_bot_saving.erase(for_team_id)
	if not st.is_constructed():
		return false
	if build_only:
		_bot_train_saving.erase(for_team_id)
		return false
	if rally != Vector3.INF and Vector2(st.rally_point().x - rally.x, st.rally_point().z - rally.z).length() > 1.0:
		st.set_rally_point(rally)
	if _bot_rank(for_team_id, st, eco):
		return true
	return _bot_train(for_team_id, st, eco, now)


## True while `table` (team -> save start) holds a save of this team that is still inside its BOT_SAVE window.
static func _saving_now(table: Dictionary, for_team_id: int, now: float) -> bool:
	var since := float(table.get(for_team_id, -1.0))
	return since >= 0.0 and since <= now and now - since <= BOT_SAVE


static func _bot_build(for_team_id: int, type: BuildingType, eco: Economy, now: float, grid: BuildGrid, workers: Array,
		keep: Node3D, difficulty: int) -> bool:
	if now < float(BOT_BUILD_AT.get(clampi(difficulty, 0, 2), 420.0)):
		return false
	if keep == null or not is_instance_valid(keep) or BuildGrid.prerequisite_reason(type, for_team_id) != "":
		return false
	if eco.crystals < type.cost + BOT_RESERVE:
		# Short: save (the Hall trains nothing) for up to BOT_SAVE s, then play on for BOT_SAVE_PAUSE s and retry.
		var since := float(_bot_saving.get(for_team_id, -1.0))
		if since < 0.0 or since > now:
			since = now
			_bot_saving[for_team_id] = now
		if now - since > BOT_SAVE:
			if now - since > BOT_SAVE + BOT_SAVE_PAUSE:
				_bot_saving[for_team_id] = now
			return false
		return true
	_bot_saving.erase(for_team_id)
	var toward := Vector3(-keep.global_position.x, 0.0, -keep.global_position.z).normalized()
	var spot := grid.find_spot(type, keep.global_position + toward * 14.0 + Vector3(toward.z, 0, -toward.x) * 8.0,
			for_team_id, 8)
	if spot == Vector3.INF:
		return false
	var best: Node3D = null
	for w: Variant in workers:
		if not is_instance_valid(w) or not (w as Node).has_method(&"command_build"):
			continue
		if (w as Node).has_method(&"is_building") and bool((w as Node).call(&"is_building")):
			continue
		var wn := w as Node3D
		if best == null or wn.global_position.distance_to(spot) < best.global_position.distance_to(spot):
			best = wn
	if best == null:
		return false
	return grid.place(type, spot, for_team_id, [best]) != null


## Keeps BOT_QUEUE riders queued in the BOT_MIX. Short of crystals for the rider it wants, it SAVES like the build
## (true = the Hall trains nothing) for up to BOT_SAVE s; after that the bare price is enough (the 100 kept are waived)
## while it plays on for BOT_SAVE_PAUSE s, then it saves again: without it
## the Halls, which train every think tick, spent every crystal before this 8 s check saw cost + BOT_RESERVE, and a
## hard bot with its Stables up had no rider by 9:00 (test_stables, 2026-09-30).
static func _bot_train(for_team_id: int, st: StablesBuilding, eco: Economy, now: float) -> bool:
	if st.queue.size() >= BOT_QUEUE:
		_bot_train_saving.erase(for_team_id)
		return false
	var types := roster_types(st.building_type.faction)
	var pops: Array[int] = [0, 0, 0, 0]
	var total := 0
	var tree := st.get_tree()
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == for_team_id and u.is_alive() and u.unit_type:
			for i in types.size():
				if types[i].id == u.unit_type.id:
					pops[i] += types[i].pop
					total += types[i].pop
	for t in st.queue:
		for i in types.size():
			if types[i].id == t.id:
				pops[i] += t.pop
				total += t.pop
	var best := -1
	var best_gap := -INF
	for i in types.size():
		var reason := st.can_queue(types[i])
		if reason != "" and reason != TrainingBuilding.REASON_NO_CRYSTALS:
			continue   # tier gate, pop cap, queue full...: not a rider to save for
		var gap := BOT_MIX[i] - float(pops[i]) / float(maxi(total, 1))
		if gap > best_gap:
			best_gap = gap
			best = i
	if best < 0:
		_bot_train_saving.erase(for_team_id)
		return false
	if eco.crystals < types[best].cost + BOT_RESERVE:
		var since := float(_bot_train_saving.get(for_team_id, -1.0))
		if since < 0.0 or since > now:
			since = now
			_bot_train_saving[for_team_id] = now
		if now - since > BOT_SAVE:
			# After the save: the bare price is enough (the 100 kept are waived), else play on and retry.
			if eco.crystals >= types[best].cost:
				_bot_train_saving.erase(for_team_id)
				return st.queue_unit(types[best]) == ""
			if now - since > BOT_SAVE + BOT_SAVE_PAUSE:
				_bot_train_saving[for_team_id] = now
			return false
		return true
	_bot_train_saving.erase(for_team_id)
	return st.queue_unit(types[best]) == ""


static func _bot_rank(for_team_id: int, st: StablesBuilding, eco: Economy) -> bool:
	if TierSystem.tier_of(for_team_id) < RANK_TIER:
		return false
	var bank := for_team(for_team_id)
	if bank == null:
		return false
	var counts := {}
	for n in st.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == for_team_id and u.is_alive() and u.unit_type and has_rank_up(u.unit_type.id):
			counts[u.unit_type.id] = int(counts.get(u.unit_type.id, 0)) + 1
	var pick: StringName = &""
	for id: StringName in counts:
		if int(counts[id]) >= BOT_RANK_MIN_UNITS and not bank.researched.has(id) \
				and (pick == &"" or int(counts[id]) > int(counts[pick])):
			pick = id
	if pick == &"" or eco.crystals < rank_price(pick) + BOT_RANK_RESERVE:
		return false
	return bank.can_rank(pick, st) == "" and bank.rank_up(pick, st) == ""
