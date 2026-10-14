class_name UnitVoice
extends Node
## Unit voice barks (JS 2026-09-27: "add sound and voice for all unit"). Added by GameAudio (load-guarded, switch
## ENABLED). Lines: data/voice/lines/unit_barks.json ({unit, event, speaker, text}), voiced by Voice Forge
## (tools/voice_forge, cast.json speakers unit_<id>) -> WAV paths from data/voice/manifest.json.
## Events: select (SelectionManager.selection_changed: the first selected unit, or an inspected own helper),
## move / attack (a right click / attack-move click while own units are selected: read one frame later, attack when
## the first unit got a new enemy target or it was an attack-move), death (Events.unit_died, own unit near the camera).
## Only the player's units. At most one bark every MIN_GAP seconds (a bark never cuts another). Bus "Voice"
## (GameSettings.BUS_VOICE, sent to SFX), else SFX. No lines / no manifest / no WAV = silent, never an error.
## Four bot-favourite units speak another language by default (cast.json notes): flame_guard Italian, rimeshield
## Spanish, nightblood_reaver Mandarin, thornling American English.

const ENABLED := true
const LINES_PATH := "res://data/voice/lines/unit_barks.json"
const MANIFEST_PATH := "res://data/voice/manifest.json"
const MIN_GAP := 1.5             ## Seconds between two barks (any unit, any event).
const DEATH_HEAR_DISTANCE := 45.0 ## A death shout plays only when the unit is this close to the camera.
const ORDER_DELAY := 0.05        ## Seconds after an order click before its kind is read.
const VOLUME_DB := -3.0
const EVENTS: Array[StringName] = [&"select", &"move", &"attack", &"death"]

var enabled := true              ## False = silent (a future "unit voices off" setting).
var played: Array[Dictionary] = []   ## Read only (tests / debug): {unit, event, path} of each bark, oldest first.

var _bank: Dictionary = {}       # StringName unit id -> {StringName event -> Array[String] wav paths}
var _last_idx: Dictionary = {}   # "unit/event" -> last line index (no immediate repeat)
var _player: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()   # own RNG: the global one belongs to gameplay / seeded replays
var _now := 0.0
var _next_ok := -1000.0
var _sm: Node = null
var _sm_look_left := 0.0
var _last_primary_id := 0
var _order_at := -1.0            # _now when an order click was seen, < 0 = none
var _order_unit: Node = null
var _order_target_before: Node = null
var _order_attack_move := false


func _ready() -> void:
	_rng.randomize()
	name = "UnitVoice"
	load_bank()
	_player = AudioStreamPlayer.new()
	_player.volume_db = VOLUME_DB
	GameSettings.ensure_buses()
	_player.bus = _pick_bus()
	add_child(_player)
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"unit_died"):
		events.connect(&"unit_died", _on_unit_died)


func _process(delta: float) -> void:
	tick(delta)


func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or _sm == null or not is_instance_valid(_sm):
		return
	var pending: Variant = _sm.call(&"get_pending_order") if _sm.has_method(&"get_pending_order") else &""
	var is_order := mb.button_index == MOUSE_BUTTON_RIGHT
	var am := false
	if mb.button_index == MOUSE_BUTTON_LEFT and (pending == &"attack_move" or pending == &"move"):
		is_order = true
		am = pending == &"attack_move"
	if not is_order or _over_hud():
		return
	var u := _primary()
	if u == null:
		return
	_order_at = _now
	_order_unit = u
	var t: Variant = u.get(&"attack_target")
	_order_target_before = t as Node if t is Node and is_instance_valid(t) else null
	_order_attack_move = am


# ---------------------------------------------------------------- public

## Advances the clock (called by _process; tests call it directly).
func tick(delta: float) -> void:
	_now += delta
	_sm_look_left -= delta
	if (_sm == null or not is_instance_valid(_sm)) and _sm_look_left <= 0.0:
		_sm_look_left = 1.0
		_find_selection_manager()
	if _order_at >= 0.0 and _now - _order_at >= ORDER_DELAY:
		_resolve_order()


## Plays one of `unit`'s lines for `event` (select / move / attack / death). Returns false when skipped: disabled,
## not the player's unit, no line, throttled (MIN_GAP), or a bark still playing (death barks cut nothing either).
func bark(unit: Node, event: StringName) -> bool:
	if not enabled or not is_instance_valid(unit) or int(unit.get(&"team") if unit.get(&"team") != null else -1) != 0:
		return false
	var id := GameAudio.unit_type_id(unit)
	var paths := lines_for(id, event)
	if paths.is_empty() or _now < _next_ok:
		return false
	if _player and _player.playing:
		return false
	var key := "%s/%s" % [id, event]
	var i := _rng.randi() % paths.size()
	if paths.size() > 1 and i == int(_last_idx.get(key, -1)):
		i = (i + 1) % paths.size()
	_last_idx[key] = i
	var path: String = paths[i]
	if not ResourceLoader.exists(path):
		return false
	var s := load(path) as AudioStream
	if s == null:
		return false
	_next_ok = _now + MIN_GAP
	if _player:
		_player.stop()
		_player.stream = s
		_player.play()
	played.append({"unit": id, "event": event, "path": path})
	return true


## WAV paths of a unit type's lines for one event (empty = none voiced).
func lines_for(unit_id: StringName, event: StringName) -> Array:
	return (_bank.get(unit_id, {}) as Dictionary).get(event, [])


## Unit type ids that have at least one voiced line.
func voiced_units() -> Array:
	return _bank.keys()


## Number of voiced lines in the bank.
func line_count() -> int:
	var n := 0
	for u: StringName in _bank:
		for e: StringName in _bank[u]:
			n += (_bank[u][e] as Array).size()
	return n


## (Re)reads the line list + manifest. Lines without a rendered WAV are left out.
func load_bank() -> void:
	_bank.clear()
	if not FileAccess.file_exists(LINES_PATH) or not FileAccess.file_exists(MANIFEST_PATH):
		return
	var lines_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(LINES_PATH))
	var man_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not lines_v is Dictionary or not man_v is Dictionary or not (man_v as Dictionary).get("lines") is Dictionary:
		return
	var by_line := {}
	var man_lines: Dictionary = man_v["lines"]
	for mid: String in man_lines:
		var e: Variant = man_lines[mid]
		if e is Dictionary:
			by_line[str(e.get("speaker", "")).to_lower() + "\n" + _norm(str(e.get("text", "")))] = str(e.get("path", ""))
	var arr: Variant = (lines_v as Dictionary).get("lines", [])
	if not arr is Array:
		return
	for x: Variant in arr:
		if not x is Dictionary:
			continue
		var unit := StringName(str(x.get("unit", "")))
		var ev := StringName(str(x.get("event", "")))
		var path: String = by_line.get(str(x.get("speaker", "")).to_lower() + "\n" + _norm(str(x.get("text", ""))), "")
		if unit == &"" or not EVENTS.has(ev) or path == "":
			continue
		if not _bank.has(unit):
			_bank[unit] = {}
		if not (_bank[unit] as Dictionary).has(ev):
			_bank[unit][ev] = []
		(_bank[unit][ev] as Array).append(path)


# ---------------------------------------------------------------- internals

func _find_selection_manager() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for root: Node in [tree.current_scene, get_parent().get_parent() if get_parent() else null]:
		if root == null:
			continue
		var s: Variant = root.get(&"selection")
		if s is Node and (s as Node).has_signal(&"selection_changed"):
			_sm = s
			break
		for c in root.get_children():
			if c.has_signal(&"selection_changed") and c.has_method(&"select_units"):
				_sm = c
				break
		if _sm:
			break
	if _sm and not _sm.is_connected(&"selection_changed", _on_selection_changed):
		_sm.connect(&"selection_changed", _on_selection_changed)


## The first selected own unit, or the inspected own unit (a helper), or null.
func _primary() -> Node:
	if _sm == null or not is_instance_valid(_sm):
		return null
	var sel: Variant = _sm.get(&"selected")
	if sel is Array:
		for u: Variant in sel:
			if u is Node and is_instance_valid(u):
				return u
	var ins: Variant = _sm.get(&"inspected")
	if ins is Node and is_instance_valid(ins) and int((ins as Node).get(&"team")) == 0:
		return ins
	return null


func _on_selection_changed() -> void:
	var u := _primary()
	if u == null:
		_last_primary_id = 0
		return
	var uid := u.get_instance_id()
	if uid == _last_primary_id:
		return   # same first unit (a dead unit dropped from the group, a group add): no new "yes?"
	_last_primary_id = uid
	bark(u, &"select")


func _resolve_order() -> void:
	var u := _order_unit
	_order_at = -1.0
	_order_unit = null
	if not is_instance_valid(u):
		return
	var t: Variant = u.get(&"attack_target")
	var new_target: bool = t is Node and is_instance_valid(t) and t != _order_target_before
	bark(u, &"attack" if _order_attack_move or new_target else &"move")


func _on_unit_died(unit: Variant) -> void:
	if not is_instance_valid(unit) or not (unit is Node3D):
		return
	var u := unit as Node3D
	if int(u.get(&"team") if u.get(&"team") != null else -1) != 0:
		return
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam and cam.global_position.distance_to(u.global_position) > DEATH_HEAR_DISTANCE:
		return
	bark(u, &"death")


## The mouse is over a HUD button / panel (a right click there is not an order).
func _over_hud() -> bool:
	var c := get_viewport().gui_get_hovered_control() if is_inside_tree() else null
	return c is BaseButton or c is Panel or c is PanelContainer


static func _norm(text: String) -> String:
	var parts := text.replace("|", " ").replace("\n", " ").split(" ", false)
	return " ".join(parts).strip_edges()


static func _pick_bus() -> StringName:
	for b: StringName in [&"Voice", &"SFX"]:
		if AudioServer.get_bus_index(b) != -1:
			return b
	return &"Master"
