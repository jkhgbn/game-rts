class_name BowmanUpgrades
extends Node
## Bowman upgrades (docs/design/bowmen.md 4) = a facade over UnitResearch (unit-upgrades.md 7-15, task UR.G5).
## The 7 rows live in UnitResearch.ROWS (`"bowman": true`, same ids, prices, times, needs, texts); buying, the one
## research slot per building, refunds, save / load and Heavy Draw's +3 damage (modifier "research:scorchbow_heavy_draw")
## all go through UnitResearch. This node keeps the old public API (for_team, can_buy, buy, grant, options_for,
## team_has, bot_try_buy until UR.A1), maps old saves (key "bowman_upgrades:<team>": done ids -> granted rows, work ->
## research in progress, old "bowman:" modifiers dropped so nothing doubles) and runs Hunting Party (the twin archer).
## The kit effects (chill, burn, bleed cap, crits) stay in BowmanKit, which reads UnitResearch.team_has.

signal upgrade_started(id: StringName)
signal upgrade_completed(id: StringName)
signal upgrade_cancelled(id: StringName, refund: int)

const DESTROYED_REFUND := 0.75
const SAVE_KEY_PREFIX := "bowman_upgrades"
## Modifier prefix of the pre-UR.G5 Heavy Draw (kept by old saves through Unit.SAVE_MODIFIER_PREFIXES): dropped on load.
const OLD_MODIFIER_PREFIX := "bowman:"
const SCAN_INTERVAL := 1.0      # Hunting Party: new Halls are hooked this often
const TWIN_OFFSET := Vector3(0.9, 0.0, 0.6)
const HUNTING_PARTY := &"wildwood_hunting_party"

## id -> {name, unit, crystals, time, needs, text}: mirror of the UnitResearch bowman rows (tests/test_unit_research.gd
## checks they agree). Effects come from UnitResearch.ROWS (mods) and BowmanKit (kit numbers).
const UPGRADES := {
	&"frostbow_rimed_shafts": {"name": "Rimed Shafts", "unit": &"frostbow", "crystals": 100, "time": 40.0,
			"needs": &"",
			"text": "Frostbow arrows chill for 2.5 s (was 1.5); Hamstring Shot every 8 s (was 12)."},
	&"scorchbow_heavy_draw": {"name": "Heavy Draw", "unit": &"scorchbow", "crystals": 100, "time": 35.0,
			"needs": &"",
			"text": "Scorchbows +3 arrow damage (17)."},
	&"scorchbow_pitch_arrows": {"name": "Pitch Arrows", "unit": &"scorchbow", "crystals": 125, "time": 45.0,
			"needs": &"scorchbow_heavy_draw",
			"text": "Scorchbow burn: 3.5 damage per second for 4 s (was 2 for 3 s). Needs Heavy Draw."},
	&"bleakbow_serrated_barbs": {"name": "Serrated Barbs", "unit": &"bleakbow", "crystals": 100, "time": 40.0,
			"needs": &"",
			"text": "Bleed stacks up to 5 times (was 3): 7.5 damage per second at full stacks."},
	&"wildwood_keen_eye": {"name": "Keen Eye", "unit": &"wildwood_archer", "crystals": 75, "time": 30.0,
			"needs": &"",
			"text": "Wildwood Archers: 15 % of arrows crit for double damage."},
	&"wildwood_heartseeker": {"name": "Heartseeker Points", "unit": &"wildwood_archer", "crystals": 100,
			"time": 40.0, "needs": &"wildwood_keen_eye",
			"text": "Crits: 20 % of arrows, x2.75 damage. Needs Keen Eye."},
	&"wildwood_hunting_party": {"name": "Hunting Party", "unit": &"wildwood_archer", "crystals": 200,
			"time": 60.0, "needs": &"wildwood_heartseeker",
			"text": "Every Wildwood Archer trained brings a second one for free (needs 1 free pop). Needs Heartseeker Points."},
}
## Card order per bowman.
const ORDER: Array[StringName] = [&"frostbow_rimed_shafts", &"scorchbow_heavy_draw", &"scorchbow_pitch_arrows",
		&"bleakbow_serrated_barbs", &"wildwood_keen_eye", &"wildwood_heartseeker", &"wildwood_hunting_party"]

## Refusals: UnitResearch's texts (unit-upgrades.md 8).
const REASON_UNKNOWN := UnitResearch.REASON_UNKNOWN
const REASON_DONE := UnitResearch.REASON_DONE
const REASON_QUEUED := UnitResearch.REASON_WORKING
const REASON_BUSY := UnitResearch.REASON_BUSY
const REASON_HALL := UnitResearch.REASON_BUILDING
const REASON_NO_CRYSTALS := UnitResearch.REASON_NO_CRYSTALS

const BOT_INTERVAL := 5.0
const BOT_MIN_UNITS := 3
const BOT_RESERVE := 250

var team := 0
## Finished bowman upgrade ids of the team (read only; UnitResearch holds them).
var researched: Array[StringName]:
	get:
		var out: Array[StringName] = []
		for id in ORDER:
			if team_has(team, id):
				out.append(id)
		return out

var _scan_left := 0.0
var _hooked: Array[int] = []          # Hall instance ids whose unit_trained is connected
var _old_state: Dictionary = {}       # an old save's row, merged into UnitResearch (load_state)
var _old_nodes: Dictionary = {}

static var _bot_next: Dictionary = {}   # team -> commander time of the next bot check


## The team's node (created when missing: under the team's UnitResearch node when it exists, else under the current
## scene; null only without a running scene).
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
	var parent: Node = UnitResearch.for_team(for_team_id, false)
	if parent == null:
		parent = tree.current_scene
	var node := BowmanUpgrades.new()
	node.name = "BowmanUpgrades%d" % for_team_id
	node.team = for_team_id
	parent.add_child(node)
	return node


## SaveWorld (saved_state): an old save's row (made before UR.G5); load_state maps it into UnitResearch.
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
	level.add_child(node)
	return node


# ---------------------------------------------------------------- static reads

static func team_has(for_team_id: int, id: StringName) -> bool:
	return not UnitResearch.lab_off and UnitResearch.team_has(for_team_id, id)


## The team's done rows on `unit` (UnitResearch.apply_to) after dropping an old save's "bowman:" modifiers.
static func apply_to(unit: Unit, heal_gain: bool = true) -> void:
	if unit == null or unit.unit_type == null:
		return
	drop_old_modifiers(unit)
	UnitResearch.apply_to(unit, heal_gain)


## Removes the pre-UR.G5 "bowman:<id>" modifiers (their bonus now comes from "research:<id>").
static func drop_old_modifiers(unit: Unit) -> void:
	for id: StringName in UPGRADES:
		var mod := StringName(OLD_MODIFIER_PREFIX + String(id))
		if unit.has_modifier(mod):
			unit.remove_modifier(mod)


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


## UI rows for a Hall: UnitResearch.options_for_unit of its bowman, bowman rows only ([{id, name, text, crystals,
## time, state, progress, reason}]).
static func options_for(hall: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids := ids_for_hall(hall)
	if ids.is_empty():
		return out
	for o: Dictionary in UnitResearch.options_for_unit(hall, UPGRADES[ids[0]]["unit"]):
		if ids.has(StringName(o["id"])):
			out.append(o)
	return out


## Bots (commander rule 5, bowmen.md 6; replaced by UR.A1): every BOT_INTERVAL s, with >= BOT_MIN_UNITS living bowmen
## of a Hall's kind and crystals >= price + BOT_RESERVE, buy that bowman's next upgrade. True when one was bought.
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
	var bank := UnitResearch.for_team(for_team_id)
	if bank == null:
		return false
	for id in ids:
		if bank.is_done(id):
			continue
		if eco.crystals < int(UPGRADES[id]["crystals"]) + BOT_RESERVE:
			return false
		for h in halls:
			if bank.can_buy(id, h as Node) == "":
				return bank.buy(id, h as Node) == ""
	return false


# ---------------------------------------------------------------- per team

func _enter_tree() -> void:
	add_to_group(&"bowman_upgrades")
	add_to_group(&"saved_state")
	var b := UnitResearch.for_team(team, false)
	if b:
		_connect(b)   # forwards the bowman rows' signals


func is_researched(id: StringName) -> bool:
	return team_has(team, id)


func is_working(id: StringName) -> bool:
	var b := UnitResearch.for_team(team, false)
	return b != null and b.is_working(id)


## 0-1 progress of `id` (0 when not in progress).
func progress(id: StringName) -> float:
	var b := UnitResearch.for_team(team, false)
	return b.progress(id) if b else 0.0


## "" when `id` can be bought at `hall` now, else UnitResearch's reason.
func can_buy(id: StringName, hall: Node) -> String:
	if not BowmanKit.BOWMEN_ENABLED or not UPGRADES.has(id):
		return REASON_UNKNOWN
	var b := _research(false)
	return b.can_buy(id, hall) if b else REASON_UNKNOWN


## Pays and starts `id` at `hall` (UnitResearch.buy). Returns "" or the reason.
func buy(id: StringName, hall: Node) -> String:
	if not BowmanKit.BOWMEN_ENABLED or not UPGRADES.has(id):
		return REASON_UNKNOWN
	var b := _research(false)
	return b.buy(id, hall) if b else REASON_UNKNOWN


## Tests / cheats / campaign / the Unit Lab: finishes `id` now without paying (also where research is off).
func grant(id: StringName) -> void:
	if not UPGRADES.has(id):
		return
	var b := _research(true)
	if b:
		b.grant(id)


## The team's UnitResearch (made when research is on here). `force`: where research is off (Unit Lab, tests on
## main.tscn) a private one under this node, so grants still apply.
func _research(force: bool) -> UnitResearch:
	var b := UnitResearch.for_team(team, true)
	if b == null and force:
		b = UnitResearch.new()
		b.team = team
		b.name = "UnitResearch%d" % team
		add_child(b)
	if b:
		_connect(b)
	return b


func _connect(b: UnitResearch) -> void:
	if not b.research_completed.is_connected(_on_completed):
		b.research_started.connect(_on_started)
		b.research_completed.connect(_on_completed)
		b.research_cancelled.connect(_on_cancelled)


func _on_started(id: StringName) -> void:
	if UPGRADES.has(id):
		upgrade_started.emit(id)


func _on_completed(id: StringName) -> void:
	if not UPGRADES.has(id):
		return
	if id == HUNTING_PARTY and is_inside_tree():
		hook_halls()
	upgrade_completed.emit(id)


func _on_cancelled(id: StringName, refund: int) -> void:
	if UPGRADES.has(id):
		upgrade_cancelled.emit(id, refund)


# ---------------------------------------------------------------- save / load (old saves only)

func save_key() -> String:
	return "%s:%d" % [SAVE_KEY_PREFIX, team]


## Nothing: UnitResearch saves the rows ("unit_research_<team>").
func save_state() -> Dictionary:
	return {}


## An old save's row ({team, researched: [ids], work: [{id, hall, left}]}): the ids become granted UnitResearch rows,
## the work a research in progress (paid), and the units' saved "bowman:" modifiers are dropped. Merged again one
## frame later in case UnitResearch's own saved row loads after this one (its load_state replaces the done list).
func load_state(d: Dictionary, nodes: Dictionary) -> void:
	_old_state = d
	_old_nodes = nodes
	_merge_old()
	_merge_old.call_deferred()


func _merge_old() -> void:
	if _old_state.is_empty():
		return
	var b := _research(true)
	if b == null:
		return
	var cur := b.save_state()
	var done: Array = cur["done"]
	var work: Array = cur["work"]
	var changed := false
	for v: Variant in _old_state.get("researched", []):
		var id := StringName(str(v))
		if UPGRADES.has(id) and not done.has(String(id)):
			done.append(String(id))
			changed = true
	for v: Variant in _old_state.get("work", []):
		if not v is Dictionary:
			continue
		var w := v as Dictionary
		var id := StringName(str(w.get("id", "")))
		if not UPGRADES.has(id) or done.has(String(id)) or b.is_working(id):
			continue
		var hall: Variant = w.get("hall")
		if hall is int:
			hall = _old_nodes.get(hall)
		work.append({"id": String(id), "building": hall, "left": float(w.get("left", 0.0)),
				"paid": int(UPGRADES[id]["crystals"])})
		changed = true
	if changed:
		b.load_state({"done": done, "work": work}, _old_nodes)
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == team and u.is_alive():
			apply_to(u, false)


# ---------------------------------------------------------------- Hunting Party

func _physics_process(delta: float) -> void:
	if not team_has(team, HUNTING_PARTY):
		return
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = SCAN_INTERVAL
		hook_halls()


## Connects every own training building's unit_trained to the twin (idempotent). BowmanKit calls it when a Wildwood
## Archer of a team with Hunting Party spawns, so the very first one after the research gets its twin.
func hook_halls() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(&"buildings"):
		var tb := n as TrainingBuilding
		if tb == null or int(tb.team) != team or _hooked.has(tb.get_instance_id()):
			continue
		_hooked.append(tb.get_instance_id())
		tb.unit_trained.connect(_on_unit_trained.bind(tb))


func _on_unit_trained(unit: Unit, hall: TrainingBuilding) -> void:
	if unit == null or unit.unit_type == null or unit.unit_type.id != &"wildwood_archer" \
			or unit.has_meta(&"bowman_twin") or not is_instance_valid(hall) or not team_has(team, HUNTING_PARTY):
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
