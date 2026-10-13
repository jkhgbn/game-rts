class_name BowmanUpgrades
extends Node
## Bowman upgrades (docs/design/bowmen.md 4), bought at the Hall that trains the bowman. One node per team (group
## "bowman_upgrades"), created on first use under the current scene. The shape follows research.md 2.3 (pay when
## queued, one at a time per Hall, permanent, applies to living and future units, Hall destroyed = 75 % refund)
## so the entries can move to ResearchType / ResearchBank once step 14 exists.
## UI glue (lead / ui-coder): a selected Hall shows `options_for(hall)` as buttons -> `buy(id, hall)`.

signal upgrade_started(id: StringName)
signal upgrade_completed(id: StringName)
signal upgrade_cancelled(id: StringName, refund: int)

const DESTROYED_REFUND := 0.75
const SAVE_KEY_PREFIX := "bowman_upgrades"
const SCAN_INTERVAL := 1.0      # Hunting Party: new Halls are hooked this often
const TWIN_OFFSET := Vector3(0.9, 0.0, 0.6)

## id -> {name, unit, crystals, time, needs, stats (Stats-contract modifier on the unit, "" = none), text, bot}
const UPGRADES := {
	&"frostbow_rimed_shafts": {"name": "Rimed Shafts", "unit": &"frostbow", "crystals": 100, "time": 40.0,
			"needs": &"", "stats": {},
			"text": "Frostbow arrows chill for 2.5 s (was 1.5); Hamstring Shot every 8 s (was 12)."},
	&"scorchbow_heavy_draw": {"name": "Heavy Draw", "unit": &"scorchbow", "crystals": 100, "time": 35.0,
			"needs": &"", "stats": {&"attack_damage": 3.0},
			"text": "Scorchbows +3 arrow damage (17)."},
	&"scorchbow_pitch_arrows": {"name": "Pitch Arrows", "unit": &"scorchbow", "crystals": 125, "time": 45.0,
			"needs": &"scorchbow_heavy_draw", "stats": {},
			"text": "Scorchbow burn: 3.5 damage per second for 4 s (was 2 for 3 s). Needs Heavy Draw."},
	&"bleakbow_serrated_barbs": {"name": "Serrated Barbs", "unit": &"bleakbow", "crystals": 100, "time": 40.0,
			"needs": &"", "stats": {},
			"text": "Bleed stacks up to 5 times (was 3): 7.5 damage per second at full stacks."},
	&"wildwood_keen_eye": {"name": "Keen Eye", "unit": &"wildwood_archer", "crystals": 75, "time": 30.0,
			"needs": &"", "stats": {},
			"text": "Wildwood Archers: 15 % of arrows crit for double damage."},
	&"wildwood_heartseeker": {"name": "Heartseeker Points", "unit": &"wildwood_archer", "crystals": 100,
			"time": 40.0, "needs": &"wildwood_keen_eye", "stats": {},
			"text": "Crits: 20 % of arrows, x2.75 damage. Needs Keen Eye."},
	&"wildwood_hunting_party": {"name": "Hunting Party", "unit": &"wildwood_archer", "crystals": 200,
			"time": 60.0, "needs": &"wildwood_heartseeker", "stats": {},
			"text": "Every Wildwood Archer trained brings a second one for free (needs 1 free pop). Needs Heartseeker Points."},
}
## Card order per bowman.
const ORDER: Array[StringName] = [&"frostbow_rimed_shafts", &"scorchbow_heavy_draw", &"scorchbow_pitch_arrows",
		&"bleakbow_serrated_barbs", &"wildwood_keen_eye", &"wildwood_heartseeker", &"wildwood_hunting_party"]

const REASON_UNKNOWN := "Unknown upgrade"
const REASON_DONE := "Already researched"
const REASON_QUEUED := "Already in progress"
const REASON_BUSY := "The Hall is busy with another upgrade"
const REASON_HALL := "Needs a completed Hall of your kingdom"
const REASON_NO_CRYSTALS := "Not enough crystals"

var team := 0
## Finished upgrade ids (read only).
var researched: Array[StringName] = []

var _work: Array[Dictionary] = []     # {id, hall, left}
var _scan_left := 0.0
var _hooked: Array[int] = []          # Hall instance ids whose unit_trained is connected

## team -> {id: true}: team_has() is O(1) and false while no node exists.
static var _done_by_team: Dictionary = {}
static var _bot_next: Dictionary = {}   # team -> commander time of the next bot check

const BOT_INTERVAL := 5.0
const BOT_MIN_UNITS := 3
const BOT_RESERVE := 250


## The team's node (created under the current scene when missing; null only without a running scene).
static func for_team(for_team_id: int, create: bool = true) -> BowmanUpgrades:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(&"bowman_upgrades"):
		var b := n as BowmanUpgrades
		if b and b.team == for_team_id and not b.is_queued_for_deletion():
			return b
	if not create or tree.current_scene == null:
		return null
	var node := BowmanUpgrades.new()
	node.name = "BowmanUpgrades%d" % for_team_id
	node.team = for_team_id
	node.add_to_group(&"bowman_upgrades")
	tree.current_scene.add_child(node)
	return node


## SaveWorld (saved_state): the team's node when the rebuilt level has not made it yet (made on first use).
static func create_for_save(level: Node, key: String) -> Node:
	var parts := key.split(":")
	if parts.size() != 2 or parts[0] != SAVE_KEY_PREFIX or not parts[1].is_valid_int():
		return null
	for n in level.get_tree().get_nodes_in_group(&"bowman_upgrades"):   # already made (first use during the rebuild)
		if n is BowmanUpgrades and (n as BowmanUpgrades).team == int(parts[1]) and not n.is_queued_for_deletion():
			return n
	var node := BowmanUpgrades.new()
	node.team = int(parts[1])
	node.name = "BowmanUpgrades%d" % node.team
	node.add_to_group(&"bowman_upgrades")
	level.add_child(node)
	return node


# ---------------------------------------------------------------- save / load (saved_state, review R3-3)

func save_key() -> String:
	return "%s:%d" % [SAVE_KEY_PREFIX, team]


func save_state() -> Dictionary:
	if researched.is_empty() and _work.is_empty():
		return {}
	var work: Array = []
	for w in _work:
		work.append({"id": String(w["id"]), "hall": w["hall"] if is_instance_valid(w["hall"]) else null,
				"left": float(w["left"])})
	var done: Array = []
	for id in researched:
		done.append(String(id))
	return {"team": team, "researched": done, "work": work}


## Upgrades back (already paid), their modifiers on living units (no heal: the saved HP is right), the Hunting Party
## hooks on the next scan. A research whose Hall is gone is refunded 75 % by the next tick, as in play.
func load_state(d: Dictionary, _nodes: Dictionary) -> void:
	researched.clear()
	var done := {}
	for id: Variant in d.get("researched", []):
		var sid := StringName(str(id))
		if UPGRADES.has(sid) and not done.has(sid):
			researched.append(sid)
			done[sid] = true
	_done_by_team[team] = done
	_work.clear()
	for row: Variant in d.get("work", []):
		if not row is Dictionary or not UPGRADES.has(StringName(str((row as Dictionary).get("id", "")))):
			continue
		var r := row as Dictionary
		_work.append({"id": StringName(str(r["id"])), "hall": r.get("hall"), "left": float(r.get("left", 0.0))})
	_scan_left = 0.0
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == team and u.is_alive():
			apply_to(u, false)


static func team_has(for_team_id: int, id: StringName) -> bool:
	var d: Variant = _done_by_team.get(for_team_id)
	return d != null and (d as Dictionary).has(id)


## Stat modifiers of the team's finished upgrades on `unit` (idempotent; modifier ids "bowman:<id>").
static func apply_to(unit: Unit, heal_gain: bool = true) -> void:
	if unit == null or unit.unit_type == null:
		return
	var d: Variant = _done_by_team.get(int(unit.team))
	if d == null:
		return
	for id: StringName in (d as Dictionary):
		var u: Dictionary = UPGRADES[id]
		if u["unit"] == unit.unit_type.id and not (u["stats"] as Dictionary).is_empty():
			unit.add_modifier(StringName("bowman:" + String(id)), u["stats"], heal_gain)


## The upgrade ids a Hall offers (empty when bowmen are off or the Hall has no bowman), card order.
static func ids_for_hall(hall: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	var bt: Variant = hall.get(&"building_type") if hall else null
	var bow: UnitType = BowmanKit.hall_bowman(bt as Resource) if bt is Resource else null
	if bow == null:
		return out
	for id in ORDER:
		if UPGRADES[id]["unit"] == bow.id:
			out.append(id)
	return out


## UI rows for a Hall: [{id, name, text, crystals, time, state (&"ready" / &"working" / &"done" / &"locked"),
## progress 0-1, reason ("" = can buy)}].
static func options_for(hall: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids := ids_for_hall(hall)
	if ids.is_empty():
		return out
	var bank := for_team(int(hall.get(&"team")), false)
	for id in ids:
		var u: Dictionary = UPGRADES[id]
		var reason := bank.can_buy(id, hall) if bank else _static_reason(id, hall)
		var state := &"ready"
		var progress := 0.0
		if team_has(int(hall.get(&"team")), id):
			state = &"done"
		elif bank and bank.is_working(id):
			state = &"working"
			progress = bank.progress(id)
		elif reason != "" and reason != REASON_NO_CRYSTALS:
			state = &"locked"
		out.append({"id": id, "name": u["name"], "text": u["text"], "crystals": u["crystals"], "time": u["time"],
				"state": state, "progress": progress, "reason": reason})
	return out


## Bots (commander rule 5, bowmen.md 6): every BOT_INTERVAL s, with >= BOT_MIN_UNITS living bowmen of a Hall's kind
## and crystals >= price + BOT_RESERVE, buy that bowman's next upgrade. True when one was bought.
static func bot_try_buy(for_team_id: int, halls: Array, eco: Economy, now: float) -> bool:
	var next := float(_bot_next.get(for_team_id, 0.0))
	if next - now > BOT_INTERVAL:   # a new match in the same process (labs): the clock restarted
		next = 0.0
	if eco == null or halls.is_empty() or now < next:
		return false
	_bot_next[for_team_id] = now + BOT_INTERVAL
	var ids := ids_for_hall(halls[0] as Node)
	if ids.is_empty():
		return false
	var unit_id: StringName = UPGRADES[ids[0]]["unit"]
	var count := 0
	var tree := Engine.get_main_loop() as SceneTree
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == for_team_id and u.unit_type and u.unit_type.id == unit_id and u.is_alive():
			count += 1
	if count < BOT_MIN_UNITS:
		return false
	var bank := for_team(for_team_id)
	for id in ids:
		if eco.crystals < int(UPGRADES[id]["crystals"]) + BOT_RESERVE:
			return false
		for h in halls:
			if bank.can_buy(id, h as Node) == "":
				return bank.buy(id, h as Node) == ""
	return false


static func _static_reason(id: StringName, hall: Node) -> String:
	var tmp := BowmanUpgrades.new()
	tmp.team = int(hall.get(&"team"))
	var r := tmp.can_buy(id, hall)
	tmp.free()
	return r


# ---------------------------------------------------------------- per team

func _enter_tree() -> void:
	add_to_group(&"saved_state")
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


## 0-1 progress of `id` (0 when not in progress).
func progress(id: StringName) -> float:
	for w in _work:
		if w["id"] == id:
			return clampf(1.0 - float(w["left"]) / float(UPGRADES[id]["time"]), 0.0, 1.0)
	return 0.0


## "" when `id` can be bought at `hall` now, else the reason (order: unknown, done, in progress, Hall, needs,
## Hall busy, crystals).
func can_buy(id: StringName, hall: Node) -> String:
	if not BowmanKit.BOWMEN_ENABLED or not UPGRADES.has(id):
		return REASON_UNKNOWN
	if researched.has(id):
		return REASON_DONE
	if is_working(id):
		return REASON_QUEUED
	if hall == null or not is_instance_valid(hall) or int(hall.get(&"team")) != team \
			or not bool(hall.call(&"is_alive")) or not bool(hall.call(&"is_constructed")) \
			or not ids_for_hall(hall).has(id):
		return REASON_HALL
	var needs: StringName = UPGRADES[id]["needs"]
	if needs != &"" and not researched.has(needs):
		return "Needs " + String(UPGRADES[needs]["name"])
	for w in _work:
		if w["hall"] == hall:
			return REASON_BUSY
	var eco := Economy.for_team(team)
	if eco == null or not eco.can_afford(int(UPGRADES[id]["crystals"])):
		return REASON_NO_CRYSTALS
	return ""


## Pays and starts `id` at `hall`. Returns "" or the reason (a crystal refusal also flashes the top bar).
func buy(id: StringName, hall: Node) -> String:
	var reason := can_buy(id, hall)
	var eco := Economy.for_team(team)
	if reason == REASON_NO_CRYSTALS and eco:
		eco.spend(int(UPGRADES[id]["crystals"]))   # fails on purpose: spend_failed
	if reason != "":
		return reason
	eco.spend(int(UPGRADES[id]["crystals"]))
	_work.append({"id": id, "hall": hall, "left": float(UPGRADES[id]["time"])})
	upgrade_started.emit(id)
	return ""


## Tests / cheats / campaign: finishes `id` now without paying.
func grant(id: StringName) -> void:
	if not UPGRADES.has(id) or researched.has(id):
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
			var refund := floori(int(UPGRADES[w["id"]]["crystals"]) * DESTROYED_REFUND)
			var eco := Economy.for_team(team)
			if eco:
				eco.add(refund)
			upgrade_cancelled.emit(w["id"], refund)
			continue
		w["left"] = float(w["left"]) - delta
		if float(w["left"]) <= 0.0:
			_work.remove_at(i)
			_complete(w["id"])
	if researched.has(&"wildwood_hunting_party"):
		_scan_left -= delta
		if _scan_left <= 0.0:
			_scan_left = SCAN_INTERVAL
			_hook_halls()


func _complete(id: StringName) -> void:
	researched.append(id)
	if not _done_by_team.has(team):
		_done_by_team[team] = {}
	(_done_by_team[team] as Dictionary)[id] = true
	var unit_id: StringName = UPGRADES[id]["unit"]
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == team and u.is_alive() and u.unit_type and u.unit_type.id == unit_id:
			apply_to(u)
	if id == &"wildwood_hunting_party":
		_hook_halls()
	upgrade_completed.emit(id)


# Hunting Party: every own Hall's unit_trained brings the twin.
func _hook_halls() -> void:
	for n in get_tree().get_nodes_in_group(&"buildings"):
		var tb := n as TrainingBuilding
		if tb == null or int(tb.team) != team or _hooked.has(tb.get_instance_id()):
			continue
		_hooked.append(tb.get_instance_id())
		tb.unit_trained.connect(_on_unit_trained.bind(tb))


func _on_unit_trained(unit: Unit, hall: TrainingBuilding) -> void:
	if unit == null or unit.unit_type == null or unit.unit_type.id != &"wildwood_archer" \
			or unit.has_meta(&"bowman_twin") or not is_instance_valid(hall):
		return
	var eco := Economy.for_team(team)
	if eco == null or not eco.has_pop_for(unit.unit_type.pop):
		return
	var twin := Worker.make_unit(unit.unit_type)
	twin.team = unit.team
	twin.set_meta(&"bowman_twin", true)
	var parent := unit.get_parent()
	parent.add_child(twin)
	twin.global_position = unit.global_position + TWIN_OFFSET
	twin.command_stop()
	twin.command_move(hall.rally_point() + TWIN_OFFSET)
	hall.unit_trained.emit(twin)
