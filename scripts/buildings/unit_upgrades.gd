class_name UnitUpgrades
extends Node
## "+" upgrades (docs/design/tiers.md 5, tiers-wave.md): one research per tier-1 / tier-2 soldier of the 4 kingdoms
## (+ the bowmen), bought at a Hall that trains the unit, from tier 2 (the Stronghold). `<unit>+` = a modest stat
## modifier `plus` on every living and future unit of that type of the team, plus the model hook `set_plus(true)`
## when the model has it (art adds a detail later).
## Shape as BowmanUpgrades: one node per team (group "unit_upgrades"), pay when started, one at a time per Hall,
## permanent, Hall destroyed = 75 % refund. UI: CommandCard's Hall "Upgrades" page (options_for / buy).
## The whole feature hangs on ENABLED.

signal upgrade_started(unit_id: StringName)
signal upgrade_completed(unit_id: StringName)
signal upgrade_cancelled(unit_id: StringName, refund: int)

## THE switch: false = no "+" research anywhere, bots never buy one.
const ENABLED := true
const MODIFIER := &"plus"
const TIER_NEEDED := 2
const DESTROYED_REFUND := 0.75
## Every unit that has a "+" (kingdom order: the 4 Hall units, the bowman, the 3 new units).
const UNITS: Array[StringName] = [
	&"flame_guard", &"ember_archer", &"blaze_rider", &"ash_hurler", &"scorchbow",
	&"scorchling", &"pyre_adept", &"cinder_arbalest",
	&"shade", &"nightbolt", &"grave_hound", &"shadow_knight", &"bleakbow",
	&"barrow_ghoul", &"hexweaver", &"hollow_oathsworn",
	&"rimeshield", &"shardcaster", &"rime_seer", &"rime_colossus", &"frostbow",
	&"rimeling", &"hoarlight_magebow", &"frost_mortar",
	&"thornling", &"burr_slinger", &"bloomtender", &"bramblehorn", &"wildwood_archer",
	&"thistle_darter", &"vinelasher", &"greenheart_oathkeeper",
]
## The default "+" (tiers.md 5): +10 % max HP and +10 % attack damage.
const STATS := {&"max_hp_pct": 0.10, &"attack_damage_pct": 0.10}
## Per-unit overrides of STATS (none yet; balance knob).
const STATS_OVERRIDE := {}
## Price: 50 + half the unit's cost, rounded to 5, within 75-200 crystals. Time: 30 s + cost / 10, within 30-60 s.
const PRICE_BASE := 50
const PRICE_MIN := 75
const PRICE_MAX := 200

const REASON_UNKNOWN := "No upgrade for that unit"
const REASON_DONE := "Already researched"
const REASON_QUEUED := "Already in progress"
const REASON_BUSY := "The Hall is busy with another upgrade"
const REASON_HALL := "Needs a completed Hall that trains it"
const REASON_NO_CRYSTALS := "Not enough crystals"

const BOT_INTERVAL := 6.0
const BOT_MIN_UNITS := 3
const BOT_RESERVE := 200

var team := 0
var researched: Array[StringName] = []   ## Unit ids with their "+" done (read only).

var _work: Array[Dictionary] = []        # {id, hall, left, paid}

static var _done_by_team: Dictionary = {}   # team -> {unit_id: true}
static var _bot_next: Dictionary = {}


# ---------------------------------------------------------------- static

## The team's node (created under the current scene when missing and `create`).
static func for_team(for_team_id: int, create: bool = true) -> UnitUpgrades:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(&"unit_upgrades"):
		var b := n as UnitUpgrades
		if b and b.team == for_team_id and not b.is_queued_for_deletion():
			return b
	if not create or tree.current_scene == null or not ENABLED:
		return null
	var node := UnitUpgrades.new()
	node.name = "UnitUpgrades%d" % for_team_id
	node.team = for_team_id
	node.add_to_group(&"unit_upgrades")
	tree.current_scene.add_child(node)
	return node


static func has_plus(unit_id: StringName) -> bool:
	return ENABLED and UNITS.has(unit_id)


static func team_has(for_team_id: int, unit_id: StringName) -> bool:
	var d: Variant = _done_by_team.get(for_team_id)
	return d != null and (d as Dictionary).has(unit_id)


static func stats_of(unit_id: StringName) -> Dictionary:
	return STATS_OVERRIDE.get(unit_id, STATS)


static func price_of(unit_id: StringName) -> int:
	var t := UnitType.find(String(unit_id))
	var c := t.cost if t else 100
	return clampi(roundi((PRICE_BASE + c * 0.5) / 5.0) * 5, PRICE_MIN, PRICE_MAX)


static func time_of(unit_id: StringName) -> float:
	var t := UnitType.find(String(unit_id))
	var c := t.cost if t else 100
	return clampf(roundf(30.0 + c / 10.0), 30.0, 60.0)


static func display_name(unit_id: StringName) -> String:
	var t := UnitType.find(String(unit_id))
	return (t.display_name if t else String(unit_id).capitalize()) + "+"


## "+10 % HP, +10 % damage".
static func stats_text(unit_id: StringName) -> String:
	var parts: PackedStringArray = []
	var s := stats_of(unit_id)
	var labels := {&"max_hp_pct": "HP", &"attack_damage_pct": "damage", &"move_speed_pct": "speed", &"armor": "armor"}
	for k: StringName in s:
		var v := float(s[k])
		var label: String = labels.get(k, String(k))
		parts.append(("+%d %% %s" % [roundi(v * 100.0), label]) if String(k).ends_with("_pct") else ("+%s %s" % [v, label]))
	return ", ".join(parts)


## Applies the team's "+" to `unit` if researched (idempotent). TrainingBuilding calls it for every unit it trains.
static func apply_to(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit) or unit.unit_type == null:
		return
	if not team_has(int(unit.team), unit.unit_type.id):
		return
	unit.add_modifier(MODIFIER, stats_of(unit.unit_type.id))
	unit.set_meta(&"plus", true)
	if unit.is_inside_tree() and unit.model_has(&"set_plus"):
		unit.model_call(&"set_plus", [true])


## The "+" ids (unit ids) a Hall offers, in its card order: its trainable soldiers that have a "+".
static func ids_for_hall(hall: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	if not ENABLED or hall == null or not hall.has_method(&"trainable_types"):
		return out
	var bt: Variant = hall.get(&"building_type")
	if not bt is BuildingType or (bt as BuildingType).kind != &"barracks":
		return out
	for t: UnitType in hall.call(&"trainable_types"):
		if t and not t.is_worker and has_plus(t.id) and not out.has(t.id):
			out.append(t.id)
	return out


## UI rows for a Hall: [{id, name, text, crystals, time, state (&"ready" / &"working" / &"done" / &"locked"),
## progress 0-1, reason ("" = can buy)}].
static func options_for(hall: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids := ids_for_hall(hall)
	if ids.is_empty():
		return out
	var hall_team := int(hall.get(&"team"))
	var bank := for_team(hall_team, false)
	for id in ids:
		var reason := bank.can_buy(id, hall) if bank else _static_reason(id, hall)
		var state := &"ready"
		var progress := 0.0
		if team_has(hall_team, id):
			state = &"done"
		elif bank and bank.is_working(id):
			state = &"working"
			progress = bank.progress(id)
		elif reason != "" and reason != REASON_NO_CRYSTALS:
			state = &"locked"
		out.append({"id": id, "name": display_name(id), "text": stats_text(id), "crystals": price_of(id),
				"time": time_of(id), "state": state, "progress": progress, "reason": reason})
	return out


## Bots (commander rule 5): every BOT_INTERVAL s at tier 2+, the "+" of the unit the team has most of (>= 3 living),
## when crystals >= price + BOT_RESERVE. True when one was bought.
static func bot_try_buy(for_team_id: int, halls: Array, eco: Economy, now: float) -> bool:
	if not ENABLED or eco == null or halls.is_empty() or TierSystem.tier_of(for_team_id) < TIER_NEEDED:
		return false
	var next := float(_bot_next.get(for_team_id, 0.0))
	if next - now > BOT_INTERVAL:   # a new match in the same process: the clock restarted
		next = 0.0
	if now < next:
		return false
	_bot_next[for_team_id] = now + BOT_INTERVAL
	var counts := {}
	var tree := Engine.get_main_loop() as SceneTree
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == for_team_id and u.unit_type and u.is_alive() and has_plus(u.unit_type.id) \
				and not team_has(for_team_id, u.unit_type.id):
			counts[u.unit_type.id] = int(counts.get(u.unit_type.id, 0)) + 1
	var best: StringName = &""
	for id: StringName in counts:
		if int(counts[id]) >= BOT_MIN_UNITS and (best == &"" or int(counts[id]) > int(counts[best])):
			best = id
	if best == &"" or eco.crystals < price_of(best) + BOT_RESERVE:
		return false
	var bank := for_team(for_team_id)
	if bank == null:
		return false
	for h in halls:
		if bank.can_buy(best, h as Node) == "":
			return bank.buy(best, h as Node) == ""
	return false


static func _static_reason(id: StringName, hall: Node) -> String:
	var tmp := UnitUpgrades.new()
	tmp.team = int(hall.get(&"team"))
	var r := tmp.can_buy(id, hall)
	tmp.free()
	return r


# ---------------------------------------------------------------- per team

func _enter_tree() -> void:
	var d := {}
	for id in researched:
		d[id] = true
	_done_by_team[team] = d


func _exit_tree() -> void:
	if _done_by_team.has(team):
		_done_by_team.erase(team)


func is_researched(id: StringName) -> bool:
	return researched.has(id)


func is_working(id: StringName) -> bool:
	for w in _work:
		if w["id"] == id:
			return true
	return false


func progress(id: StringName) -> float:
	for w in _work:
		if w["id"] == id:
			return clampf(1.0 - float(w["left"]) / time_of(id), 0.0, 1.0)
	return 0.0


## "" when the "+" of `id` can be bought at `hall` now, else the reason (unknown, done, in progress, Hall, tier,
## Hall busy, crystals).
func can_buy(id: StringName, hall: Node) -> String:
	if not has_plus(id):
		return REASON_UNKNOWN
	if researched.has(id):
		return REASON_DONE
	if is_working(id):
		return REASON_QUEUED
	if hall == null or not is_instance_valid(hall) or int(hall.get(&"team")) != team \
			or not bool(hall.call(&"is_alive")) or not bool(hall.call(&"is_constructed")) \
			or not ids_for_hall(hall).has(id):
		return REASON_HALL
	var gate := TierSystem.gate_reason(TIER_NEEDED, team)
	if gate != "":
		return gate
	for w in _work:
		if w["hall"] == hall:
			return REASON_BUSY
	var eco := Economy.for_team(team)
	if eco == null or not eco.can_afford(price_of(id)):
		return REASON_NO_CRYSTALS
	return ""


## Pays and starts the "+" of `id` at `hall`. "" or the reason (a crystal refusal flashes the top bar).
func buy(id: StringName, hall: Node) -> String:
	var reason := can_buy(id, hall)
	var eco := Economy.for_team(team)
	if reason == REASON_NO_CRYSTALS and eco:
		eco.spend(price_of(id))   # fails on purpose: spend_failed
	if reason != "":
		return reason
	var price := price_of(id)
	eco.spend(price)
	_work.append({"id": id, "hall": hall, "left": time_of(id), "paid": price})
	upgrade_started.emit(id)
	return ""


## Stops the "+" of `id`: full refund.
func cancel(id: StringName) -> void:
	for i in range(_work.size() - 1, -1, -1):
		if _work[i]["id"] == id:
			var paid := int(_work[i]["paid"])
			var eco := Economy.for_team(team)
			if eco:
				eco.add(paid)
			_work.remove_at(i)
			upgrade_cancelled.emit(id, paid)
			return


## Tests / cheats / campaign: finishes `id` now without paying.
func grant(id: StringName) -> void:
	if not has_plus(id) or researched.has(id):
		return
	for i in range(_work.size() - 1, -1, -1):
		if _work[i]["id"] == id:
			_work.remove_at(i)
	_complete(id)


func _physics_process(delta: float) -> void:
	for i in range(_work.size() - 1, -1, -1):
		var w: Dictionary = _work[i]
		var hall: Variant = w["hall"]
		if not is_instance_valid(hall) or not bool((hall as Node).call(&"is_alive")):
			_work.remove_at(i)
			var refund := floori(int(w["paid"]) * DESTROYED_REFUND)
			var eco := Economy.for_team(team)
			if eco:
				eco.add(refund)
			upgrade_cancelled.emit(w["id"], refund)
			continue
		w["left"] = float(w["left"]) - delta
		if float(w["left"]) <= 0.0:
			_work.remove_at(i)
			_complete(w["id"])


func _complete(id: StringName) -> void:
	researched.append(id)
	if not _done_by_team.has(team):
		_done_by_team[team] = {}
	(_done_by_team[team] as Dictionary)[id] = true
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == team and u.is_alive() and u.unit_type and u.unit_type.id == id:
			apply_to(u)
	upgrade_completed.emit(id)
