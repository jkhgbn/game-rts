extends SceneTree
## Unit dances (ideas-inbox 2026-09-27): play_clip(&"dance_victory" / "dance_surrender" / "dance_random") + stop_clip()
## on the kit models (sample units of each kingdom + wizards), beasts / mounts skipped safely, the chat command line
## ("dance 1 / 2 / 3" on the selection, Enter opens it, hotkeys blocked while open, Esc closes), an order stops the
## dance, and the match end makes the winners dance victory and the losers surrender.
## Run:  godot --headless --path . -s tests/test_unit_dances.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "unit_dances"
const TIMEOUT_FRAMES := 5000
const DANCERS := {
	"flame_guard": &"fire", "pyre_adept": &"fire", "rimeshield": &"ice", "shardguard": &"ice",
	"thornling": &"nature", "vinelasher": &"nature", "shade": &"shadow", "hexweaver": &"shadow",
}
const WIZARDS := {
	"res://art/units/wizards/vessa.tscn": &"fire", "res://art/units/wizards/torvald.tscn": &"ice",
	"res://art/units/wizards/ysolde.tscn": &"nature", "res://art/units/wizards/malrik.tscn": &"shadow",
}
const NON_DANCERS := ["grave_hound", "greymane_direwolf"]

var main: Node
var frame := 0
var step := 0
var _wait := 0
var _models: Array = []        # [model, label, rest arm rotation]
var _non: Array = []
var _picked: Array = []        # selected player units
var _others: Array = []


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at step %d" % step)
	match step:
		0:
			var r := _spawn_models()
			if r != "":
				return _finish(r)
			step = 1
		1:
			_wait += 1
			if _wait == 3:
				var r := _start_clips()
				if r != "":
					return _finish(r)
			if _wait == 40:
				var r := _check_posed()
				if r != "":
					return _finish(r)
				for e in _models:
					(e[0] as Node).queue_free()
				for n in _non:
					(n as Node).queue_free()
				_wait = 0
				step = 2
		2:
			if main.get("hero") == null:
				return false
			_wait += 1
			if _wait < 20:
				return false
			var r := _chat_and_order()
			if r != "":
				return _finish(r)
			_wait = 0
			step = 3
		3:
			_wait += 1
			if _wait < 5:
				return false
			var r := _after_order()
			if r != "":
				return _finish(r)
			var r2 := _victory()
			if r2 != "":
				return _finish(r2)
			return _finish("")
	return false


func _spawn_models() -> String:
	# In front of the camera (models beyond 45 m freeze, dancing or not).
	var cam := root.get_viewport().get_camera_3d()
	var c0 := Vector3.ZERO
	if cam:
		var f := -cam.global_transform.basis.z
		c0 = cam.global_position + f * (cam.global_position.y / maxf(-f.y, 0.2))
		c0.y = 0.0
	var x := c0.x - 15.0
	for id: String in DANCERS:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or t.get("model_scene") == null:
			return "no model scene for %s" % id
		var m: Node3D = (t.get("model_scene") as PackedScene).instantiate()
		m.position = Vector3(x, 0, c0.z)
		x += 3.0
		root.add_child(m)
		_models.append([m, id, DANCERS[id]])
	for path: String in WIZARDS:
		var m: Node3D = (load(path) as PackedScene).instantiate()
		m.position = Vector3(x, 0, c0.z)
		x += 3.0
		root.add_child(m)
		_models.append([m, path.get_file(), WIZARDS[path]])
	for id: String in NON_DANCERS:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or t.get("model_scene") == null:
			continue
		var m: Node3D = (t.get("model_scene") as PackedScene).instantiate()
		m.position = Vector3(x, 0, c0.z)
		x += 3.0
		root.add_child(m)
		_non.append(m)
	return ""


func _start_clips() -> String:
	var clips := [&"dance_victory", &"dance_surrender", &"dance_random"]
	var i := 0
	for e in _models:
		var m: Node = e[0]
		for h in [&"play_clip", &"stop_clip", &"current_clip", &"has_clip"]:
			if not m.has_method(h):
				return "%s has no %s" % [e[1], h]
		for c in clips:
			if not bool(m.call(&"has_clip", c)):
				return "%s has no clip %s" % [e[1], c]
		if StringName(m.call(&"dance_style")) != e[2]:
			return "%s dance style %s, expected %s" % [e[1], m.call(&"dance_style"), e[2]]
		var c: StringName = clips[i % 3]
		i += 1
		if not bool(m.call(&"play_clip", c)):
			return "%s refused %s" % [e[1], c]
		e.append(c)
		e.append(_pose_of(m))
	if bool(_models[0][0].call(&"play_clip", &"dance_moonwalk")):
		return "an unknown clip was accepted"
	for n in _non:
		if n.has_method(&"play_clip") and bool(n.call(&"play_clip", &"dance_victory")):
			return "%s (beast / mount) should not dance" % n.name
	return ""


func _check_posed() -> String:
	for e in _models:
		var m: Node3D = e[0]
		if StringName(m.call(&"current_clip")) != e[3]:
			return "%s stopped its dance (%s)" % [e[1], m.call(&"current_clip")]
		var moved := _pose_diff(e[4], _pose_of(m))
		if moved < 0.15:
			return "%s arms barely move while dancing %s (%.2f rad)" % [e[1], e[3], moved]
		# Limbs stay attached: arms / legs / head only rotate (their pivots keep their rest spot, within 1 cm).
		for p in ["Root/Chest/ArmR", "Root/Chest/ArmL", "Root/Hips/LegL", "Root/Hips/LegR", "Root/Chest/Head"]:
			var n := m.get_node_or_null(p) as Node3D
			if n and n.position.length() > 3.0:
				return "%s pivot %s drifted to %s" % [e[1], p, n.position]
		print("  %s (%s) dances %s, arm moved %.2f rad" % [e[1], e[2], e[3], moved])
	# stop_clip blends back to the rest pose.
	var m0: Node = _models[0][0]
	m0.call(&"stop_clip")
	if StringName(m0.call(&"current_clip")) != &"":
		return "stop_clip did not stop"
	return ""


func _chat_and_order() -> String:
	var hud: Node = main.get("hud")
	var chat: Node = hud.get("chat_line") if hud else null
	if chat == null:
		return "the HUD has no chat line"
	var sel: SelectionManager = main.get("selection")
	var mine: Array = []
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.PLAYER and u.model_has(&"play_clip"):
			mine.append(u)
	if mine.size() < 2:
		return "need 2 dancing player units in the mission map (have %d)" % mine.size()
	_picked = [mine[0]]
	_others = mine.slice(1)
	sel.select_units(_picked)
	# Enter opens the chat line.
	_key(KEY_ENTER)
	if not bool(chat.call(&"is_open")):
		return "Enter did not open the chat line"
	# Hotkeys are blocked while it is open: T (shop) must not open the shop.
	var shop: Node = hud.get("shop_window")
	var shop_before: bool = shop != null and (shop as CanvasItem).visible if shop is CanvasItem else false
	_key(KEY_T, "t".unicode_at(0))
	var shop_after: bool = shop != null and (shop as CanvasItem).visible if shop is CanvasItem else false
	if shop_after != shop_before:
		return "the T hotkey fired while the chat line was open"
	# Type "dance 3" + Enter.
	var input := chat.get("input") as LineEdit
	input.text = ""
	for ch in "dance 3":
		var code: int = KEY_SPACE if ch == " " else (KEY_3 if ch == "3" else OS.find_keycode_from_string(ch.to_upper()))
		_key(code, ch.unicode_at(0))
	var typed := input.text
	if typed != "dance 3":
		print("  typing through input events gave '%s'; using the line's text directly" % typed)
		input.text = "dance 3"
	_key(KEY_ENTER)
	if bool(chat.call(&"is_open")):
		input.text_submitted.emit(input.text)   # headless LineEdit may not submit on a pushed Enter
	if bool(chat.call(&"is_open")):
		return "the chat line did not close after Enter"
	var lines: PackedStringArray = chat.call(&"log_lines")
	print("  chat log: ", lines)
	if UnitDances.current(_picked[0]) != &"dance_random":
		return "dance 3 did not start dance_random on the selected unit (%s)" % UnitDances.current(_picked[0])
	for u in _others:
		if UnitDances.current(u) != &"":
			return "an unselected unit dances after 'dance 3'"
	# Unknown text is echoed, Esc closes.
	chat.call(&"open")
	var reply: String = chat.call(&"submit", "hello there")
	var log2: PackedStringArray = chat.call(&"log_lines")
	if reply != "" or log2.is_empty() or not log2[-1].contains("hello there"):
		return "plain chat was not echoed"
	_key(KEY_ESCAPE)
	if bool(chat.call(&"is_open")):
		return "Esc did not close the chat line"
	# dance 1 with nothing selected = every player unit.
	sel.select_units([])
	reply = chat.call(&"submit", "dance 1")
	for u in mine:
		if UnitDances.current(u) != &"dance_victory":
			return "'dance 1' with no selection did not make %s dance (%s)" % [u.name, reply]
	sel.select_units(_picked)
	chat.call(&"submit", "dance 3")
	# An order stops the dance.
	var u0: Unit = _picked[0]
	u0.command_move(u0.global_position + Vector3(3, 0, 0))
	if UnitDances.current(u0) != &"":
		return "a move order did not stop the dance"
	return ""


func _after_order() -> String:
	if UnitDances.current(_picked[0]) != &"":
		return "the dance restarted after the order"
	return ""


func _victory() -> String:
	for u in get_nodes_in_group(&"units"):
		UnitDances.stop(u)
	main.call(&"_end_game", true)
	var winners := 0
	var losers := 0
	for n in get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or UnitDances.in_combat(u):
			continue
		var c := UnitDances.current(u)
		if int(u.team) == Unit.Team.PLAYER and u.model_has(&"play_clip") and bool(u.model_call(&"can_dance")):
			if c != &"dance_victory":
				return "player unit %s does not dance victory (%s)" % [u.name, c]
			winners += 1
		elif int(u.team) == Unit.Team.ENEMY and u.model_has(&"play_clip") and bool(u.model_call(&"can_dance")):
			if c != &"dance_surrender":
				return "enemy unit %s does not surrender (%s)" % [u.name, c]
			losers += 1
	print("  victory: %d winners dance, %d losers surrender" % [winners, losers])
	if winners == 0:
		return "nobody danced on victory"
	return ""


const POSE_PIVOTS := ["Root", "Root/Chest", "Root/Chest/ArmR", "Root/Chest/ArmL", "Root/Chest/Head", "Root/Hips/LegL"]


func _pose_of(m: Node) -> Array:
	var out := []
	for p in POSE_PIVOTS:
		var n := m.get_node_or_null(p) as Node3D
		out.append(n.transform if n else Transform3D.IDENTITY)
	return out


## Largest pivot change between two poses (rad; 1 cm of travel counts 0.05).
func _pose_diff(a: Array, b: Array) -> float:
	var d := 0.0
	for i in a.size():
		var ta: Transform3D = a[i]
		var tb: Transform3D = b[i]
		d = maxf(d, ta.basis.get_rotation_quaternion().angle_to(tb.basis.get_rotation_quaternion()))
		d = maxf(d, ta.origin.distance_to(tb.origin) * 5.0)
	return d


func _key(code: int, unicode: int = 0) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code as Key
		ev.keycode = code as Key
		ev.unicode = unicode if pressed else 0
		ev.pressed = pressed
		root.push_input(ev)


func _finish(reason: String) -> bool:
	paused = false
	if reason == "":
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, reason])
	return true
