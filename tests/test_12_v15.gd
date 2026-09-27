extends SceneTree
## Task 12.V15 (game critter models: red deer + rabbit), headless.
## Run:  $GODOT --headless --path . -s tests/test_12_v15.gd --fixed-fps 60 --quit-after 1200
## Checks: both scenes load and build; triangles <= 1 200 (deer, stag and hind) / 300 (rabbit); exactly 1 material and
## 0 lights per model; the 5 hooks + revive exist and work (calls before _ready are kept); move / flee advance the
## gait; the death hides the model and emits death_finished once, after the 4 s hold + fade (not before 4 s); hooks
## after death are ignored until revive(); not in "units" / "buildings"; rough CPU cost per critter update.

const TASK_ID := "12.V15"
const SCENES: Dictionary = {
	"deer": "res://art/units/neutral/critters/deer.tscn",
	"rabbit": "res://art/units/neutral/critters/rabbit.tscn",
}
const BUDGET: Dictionary = {"deer": 1200, "rabbit": 300}
const HOOKS: Array[String] = ["play_idle", "play_move", "play_flee", "play_hit", "play_death", "revive"]
const DEATH_AT := 200

var _holder: Node3D
var _models: Dictionary = {}
var _finished: Dictionary = {}
var _phase0: Dictionary = {}
var _frame: int = 0
var _fails: Array[String] = []


func _initialize() -> void:
	_holder = Node3D.new()
	root.add_child(_holder)
	var x: float = 0.0
	for kind: String in SCENES:
		if not ResourceLoader.exists(SCENES[kind]):
			_fails.append("%s scene missing" % kind)
			continue
		var m: Node3D = (load(SCENES[kind]) as PackedScene).instantiate()
		m.position = Vector3(x, 0.0, 0.0)
		x += 3.0
		m.call(&"play_move", 3.0 if kind == "deer" else 2.0)   # before _ready: must be kept
		_holder.add_child(m)
		_models[kind] = m
		_finished[kind] = 0
		var k: String = kind
		m.connect(&"death_finished", func() -> void: _finished[k] = int(_finished[k]) + 1)


func _fail(msg: String) -> void:
	_fails.append(msg)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_static_checks()
	elif _frame == 3:
		for kind: String in _models:
			_phase0[kind] = float(_models[kind].call(&"gait_phase"))
			if _models[kind].call(&"state") != &"move":
				_fail("%s: play_move before _ready was lost (state %s)" % [kind, _models[kind].call(&"state")])
	elif _frame == 40:
		for kind: String in _models:
			var ph: float = float(_models[kind].call(&"gait_phase"))
			if absf(ph - float(_phase0[kind])) < 0.05:
				_fail("%s: the walk does not advance the gait phase" % kind)
			_models[kind].call(&"play_flee")
			if _models[kind].call(&"state") != &"flee":
				_fail("%s: play_flee -> state %s" % [kind, _models[kind].call(&"state")])
	elif _frame == 100:
		for kind: String in _models:
			_models[kind].call(&"play_hit")
			_models[kind].call(&"play_idle")
			if _models[kind].call(&"state") != &"idle":
				_fail("%s: play_idle -> state %s" % [kind, _models[kind].call(&"state")])
	elif _frame == DEATH_AT:
		for kind: String in _models:
			_models[kind].call(&"play_death")
			_models[kind].call(&"play_death")      # twice: ignored
			_models[kind].call(&"play_move", 5.0)  # after death: ignored
			if not bool(_models[kind].call(&"is_dead")):
				_fail("%s: play_death -> not dead" % kind)
	elif _frame == DEATH_AT + 60 * 3:
		for kind: String in _models:
			var mesh: MeshInstance3D = _models[kind].get_node(^"Mesh")
			if not mesh.visible or int(_finished[kind]) != 0 or float(_models[kind].call(&"dissolve_amount")) > 0.0:
				_fail("%s: gone before the 4 s hold (visible %s, finished %d)" % [kind, mesh.visible, _finished[kind]])
			if _models[kind].call(&"state") != &"dead":
				_fail("%s: play_move after death changed the state" % kind)
	elif _frame == DEATH_AT + 60 * 4 + 25:
		for kind: String in _models:
			var d: float = float(_models[kind].call(&"dissolve_amount"))
			if d <= 0.0 or d >= 1.0:
				_fail("%s: not dissolving at 4.4 s (%.2f)" % [kind, d])
	elif _frame == DEATH_AT + 60 * 5 + 10:
		for kind: String in _models:
			var mesh: MeshInstance3D = _models[kind].get_node(^"Mesh")
			if mesh.visible:
				_fail("%s: still visible after the fade" % kind)
			if int(_finished[kind]) != 1:
				_fail("%s: death_finished emitted %d times" % [kind, _finished[kind]])
			_models[kind].call(&"revive")
			if not mesh.visible or bool(_models[kind].call(&"is_dead")) or _models[kind].call(&"state") != &"idle":
				_fail("%s: revive did not restore it" % kind)
	elif _frame == DEATH_AT + 60 * 5 + 40:
		for kind: String in _models:
			_models[kind].call(&"play_move", 7.0)
		_cost_check()
		_finish()
		return true
	if _frame > 1100:
		_fail("timed out")
		_finish()
		return true
	return false


func _static_checks() -> void:
	for kind: String in _models:
		var m: Node3D = _models[kind]
		for h: String in HOOKS:
			if not m.has_method(h):
				_fail("%s: hook %s missing" % [kind, h])
		var tris: int = int(m.call(&"triangle_count"))
		print("%s: %d triangles (budget %d)" % [kind, tris, BUDGET[kind]])
		if tris <= 0 or tris > int(BUDGET[kind]):
			_fail("%s: %d triangles, budget %d" % [kind, tris, BUDGET[kind]])
		var mats: Dictionary = {}
		var lights: int = 0
		var geoms: int = 0
		for n: Node in m.find_children("*", "", true, false):
			if n is Light3D:
				lights += 1
			if n is GeometryInstance3D:
				geoms += 1
				var gi := n as GeometryInstance3D
				if gi.material_override:
					mats[gi.material_override] = true
				if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
					var mesh: Mesh = (gi as MeshInstance3D).mesh
					for s: int in mesh.get_surface_count():
						var sm: Material = (gi as MeshInstance3D).get_surface_override_material(s)
						if sm == null:
							sm = mesh.surface_get_material(s)
						if sm:
							mats[sm] = true
		print("%s: %d material(s), %d light(s), %d geometry instance(s)" % [kind, mats.size(), lights, geoms])
		if mats.size() != 1:
			_fail("%s: %d materials (budget 1)" % [kind, mats.size()])
		if lights != 0:
			_fail("%s: %d lights" % [kind, lights])
		if geoms != 1:
			_fail("%s: %d geometry instances (expected the single Mesh)" % [kind, geoms])
		if m.is_in_group(&"units") or m.is_in_group(&"buildings"):
			_fail("%s: in units / buildings" % kind)
	# The antler-less hind variant.
	var hind: ArrayMesh = load("res://art/units/neutral/critters/deer.gd").build_mesh(false)
	var hind_tris: int = (hind.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	print("deer hind (no antlers): %d triangles" % hind_tris)
	if hind_tris <= 0 or hind_tris > 1200:
		_fail("hind: %d triangles" % hind_tris)


## Rough CPU cost of one update (headless: the RenderingServer calls are dummies, so this is the script side only).
func _cost_check() -> void:
	var list: Array = []
	for i: int in 6:
		list.append((load(SCENES["deer"]) as PackedScene).instantiate())
	for i: int in 12:
		list.append((load(SCENES["rabbit"]) as PackedScene).instantiate())
	for i: int in list.size():
		(list[i] as Node3D).position = Vector3(float(i) * 2.0, 0.0, 10.0)
		_holder.add_child(list[i])
		list[i].call(&"play_move", 3.0 if i % 3 == 0 else 0.0)
	var t0: int = Time.get_ticks_usec()
	for f: int in 60:
		for m: Node in list:
			m.call(&"_update", 1.0 / 60.0)
	var us: float = float(Time.get_ticks_usec() - t0) / 60.0
	print("18 critters (6 deer + 12 rabbits): %.1f us per frame (script side)" % us)
	for m: Node in list:
		m.queue_free()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	_holder.queue_free()
