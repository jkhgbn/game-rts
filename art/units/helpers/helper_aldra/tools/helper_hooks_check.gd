extends SceneTree
## Headless hook check of the T3 helper models Aldra + Maelis (t3-helpers.md 10.1): every hook exists and runs (kit hooks,
## the 3 abilities + passive tell, play_arrival / play_fall / play_revive, set_charge, the 5 gestures incl. a held kneel,
## set_expression), death_finished fires, a call before _ready is kept, 0 lights, face mesh swaps per expression.
## Run: tools\godot_run.ps1 --headless --path . -s res://art/units/helpers/helper_aldra/tools/helper_hooks_check.gd --quit-after 3000
## Prints "PASS helper_models" (or FAIL lines).

const MODELS := {
	"aldra": ["res://art/units/helpers/helper_aldra/helper_aldra.tscn", [&"aldra_shatter", &"aldra_aegis", &"aldra_sentinel", &"aldra_ward"]],
	"maelis": ["res://art/units/helpers/helper_maelis/helper_maelis.tscn", [&"thornsnare", &"call_the_pack", &"wild_stampede", &"maelis_opinions"]],
}
const HOOKS: Array[StringName] = [&"set_team_color", &"set_moving", &"play_attack", &"play_cast", &"play_hit", &"play_death",
	&"play_level_up", &"revive", &"play_arrival", &"play_fall", &"play_revive", &"set_charge", &"play_gesture", &"point", &"nod",
	&"kneel", &"stand_up", &"raise_weapon", &"set_expression", &"get_expression", &"is_kneeling"]

var _fails: PackedStringArray = []
var _died: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _wait(sec: float) -> void:
	var n := int(sec * 60.0)
	for i: int in n:
		await process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("FAIL ", what)


func _count_lights(n: Node) -> int:
	var c := 1 if n is Light3D else 0
	for ch: Node in n.get_children():
		c += _count_lights(ch)
	return c


func _run() -> void:
	for id: String in MODELS:
		var path: String = MODELS[id][0]
		var abilities: Array = MODELS[id][1]
		var ps: PackedScene = load(path)
		_check(ps != null, id + " loads")
		if ps == null:
			continue
		# a call before _ready is kept
		var early: Node3D = ps.instantiate()
		early.call(&"play_arrival")
		root.add_child(early)
		await _wait(0.3)
		_check(early.get(&"_action") == &"cast", id + " arrival asked before _ready plays")
		early.queue_free()
		var m: Node3D = ps.instantiate()
		root.add_child(m)
		await _wait(0.2)
		for h: StringName in HOOKS:
			_check(m.has_method(h), id + " has " + String(h))
		_check(_count_lights(m) == 0, id + " has 0 lights")
		m.call(&"set_team_color", Color(0.85, 0.3, 0.12))
		m.call(&"set_moving", 4.0)
		await _wait(0.4)
		m.call(&"set_moving", 0.0)
		m.call(&"play_attack")
		await _wait(0.6)
		for a: StringName in abilities:
			m.call(&"play_cast", a)
			await _wait(0.2)
			_check(m.get(&"_action") == &"cast", id + " casts " + String(a))
			await _wait(1.5)
			_check(m.get(&"_action") == &"", id + " ends " + String(a))
		for e: StringName in [&"smile", &"fierce", &"neutral"]:
			m.call(&"set_expression", e)
			_check(m.call(&"get_expression") == e, id + " expression " + String(e))
		var face: MeshInstance3D = m.get(&"_face")
		_check(face != null and face.mesh != null, id + " has a painted face")
		m.call(&"set_expression", &"smile")
		var smile_mesh: Mesh = face.mesh if face else null
		m.call(&"set_expression", &"fierce")
		_check(face != null and face.mesh != smile_mesh, id + " face swaps per expression")
		m.call(&"set_expression", &"neutral")
		m.call(&"set_charge", 1.0)
		await _wait(0.2)
		m.call(&"set_charge", 0.0)
		for g: StringName in [&"point", &"nod", &"raise_weapon"]:
			m.call(&"play_gesture", g)
			await _wait(1.8)
		m.call(&"kneel")
		await _wait(1.5)
		_check(m.call(&"is_kneeling") and m.get(&"_action") == &"cast", id + " kneel holds")
		m.call(&"play_hit")
		await _wait(0.3)
		_check(m.get(&"_action") == &"cast", id + " still kneeling after a hit")
		m.call(&"stand_up")
		await _wait(1.0)
		_check(not m.call(&"is_kneeling") and m.get(&"_action") == &"", id + " stands up")
		m.call(&"play_arrival")
		await _wait(3.7)
		_check(m.get(&"_action") == &"", id + " arrival ends")
		_died = false
		m.connect(&"death_finished", func() -> void: _died = true)
		m.call(&"play_fall")
		await _wait(1.3)
		_check(_died, id + " death_finished after play_fall")
		m.call(&"play_revive")
		await _wait(0.2)
		_check(m.get(&"_dead") == false and m.get(&"_action") == &"cast", id + " revives (rise pose)")
		await _wait(1.3)
		_check(_count_lights(m) == 0, id + " still 0 lights")
		print("HELPER HOOKS ", id, " done")
		m.queue_free()
	if _fails.is_empty():
		print("PASS helper_models")
	else:
		print("FAIL helper_models (", _fails.size(), ")")
	quit()
