extends SceneTree
## Task A2.5: the reworked Heartwood (Nature keep) instantiates headless and every art hook runs without errors
## (hooks before _ready, construction, selection, training pulse, damage states and heal, destroy, early free),
## keeps its contract (root script hooks, signal, 2 unshadowed lights, per-instance materials, footprint), and the
## BuildingType still points at it.
## Run: Godot --headless --path . -s tests/test_a2_5.gd --fixed-fps 60 --quit-after 900

const TASK_ID := "a2.5"
const SCENE := "res://art/buildings/nature_keep.tscn"
const HOOKS: Array[StringName] = [&"set_team_color", &"set_construction_progress", &"set_health_ratio",
	&"play_training_pulse", &"play_destroyed", &"set_selected"]
const NODES: Array[String] = ["Model", "Model/Plinth", "Model/Rampart", "Model/TrunkLow", "Model/TrunkHigh",
	"Model/Canopy", "Model/CanopyLost", "Model/Bloom", "Model/Lanterns", "Model/Stump", "Model/Rubble2",
	"ContactDecal", "Rubble", "Outline", "CrownLight", "GateLight", "Pollen", "Leaves", "Petals"]

var _keeps: Array = []
var _frame: int = 0
var _finished: int = 0
var _ok: bool = true


func _initialize() -> void:
	var ps: PackedScene = load(SCENE)
	if ps == null:
		_fail("scene does not load")
		return
	for i: int in 2:
		var k: Node3D = ps.instantiate() as Node3D
		for h: StringName in HOOKS:
			if not k.has_method(h):
				_fail("lacks hook %s" % h)
		if not k.has_signal(&"destroyed_finished"):
			_fail("lacks signal destroyed_finished")
		for n: String in NODES:
			if k.get_node_or_null(n) == null:
				_fail("lacks node %s" % n)
		# Hooks before _ready must be cached (the second keep stays in the kingdom colour).
		if i == 0:
			k.call(&"set_team_color", Color(0.9, 0.2, 0.2))
		k.call(&"set_construction_progress", 0.0)
		k.position = Vector3(20.0 * i, 0, 0)
		root.add_child(k)
		k.connect(&"destroyed_finished", func() -> void: _finished += 1)
		_keeps.append(k)
	_check_contract()
	var bt: Resource = load("res://data/buildings/nature_keep.tres")
	if bt == null or bt.get(&"model_scene") == null or (bt.get(&"model_scene") as PackedScene).resource_path != SCENE:
		_fail("data/buildings/nature_keep.tres does not point at %s" % SCENE)


func _check_contract() -> void:
	var k: Node3D = _keeps[0]
	var lights: Array[Node] = k.find_children("*", "Light3D", true, false)
	if lights.size() != 2:
		_fail("expected 2 lights, found %d" % lights.size())
	for l: Node in lights:
		if (l as Light3D).shadow_enabled:
			_fail("light %s casts shadows" % l.name)
	# Ground-level footprint: nothing below 2.5 m reaches past 3.9 m from the centre on an axis (roots / stairs
	# may overhang a little, like the Fire Keep's stairs), nothing above past 4.4 m.
	for path: String in ["Model/Plinth", "Model/Rampart"]:
		var mi := k.get_node(path) as MeshInstance3D
		var box: AABB = mi.get_aabb()
		if box.position.x < -3.9 or box.end.x > 3.9 or box.position.z < -3.9 or box.end.z > 3.9:
			_fail("%s is wider than the footprint: %s" % [path, box])
	for path: String in ["Model/Canopy", "Model/CanopyLost"]:
		var mi := k.get_node(path) as MeshInstance3D
		var box: AABB = mi.transform * mi.get_aabb()
		if box.position.x < -4.6 or box.end.x > 4.6 or box.position.z < -4.6 or box.end.z > 4.6 or box.end.y > 18.0:
			_fail("%s exceeds the keep volume: %s" % [path, box])


func _process(_delta: float) -> bool:
	_frame += 1
	if _keeps.is_empty():
		print("FAIL %s: nothing instantiated" % TASK_ID)
		return true
	if _frame == 5:
		# Extra instances freed mid-collapse must not error.
		for i: int in 2:
			var early: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
			early.name = "Early%d" % i
			root.add_child(early)
	if _frame == 8:
		var n: int = 0
		for c: Node in root.get_children():
			if c is Node3D and c.name.begins_with("Early"):
				c.call(&"play_destroyed")
				create_timer(0.7 + 0.4 * n).timeout.connect(c.queue_free)
				n += 1
	for k: Node3D in _keeps:
		match _frame:
			10: k.call(&"set_construction_progress", 0.5)
			40: k.call(&"set_construction_progress", 1.0)
			60: k.call(&"set_selected", true)
			80: k.call(&"set_selected", false)
			90: k.call(&"play_training_pulse")
			95: k.call(&"play_training_pulse")
			120: k.call(&"set_health_ratio", 0.4)
			150: k.call(&"set_health_ratio", 0.2)
			180: k.call(&"set_health_ratio", 1.0)
			200: k.call(&"set_health_ratio", 0.1)
			220: k.call(&"play_destroyed")
	if _frame == 45:
		_check_team_colours()
	if _frame == 130:
		var k: Node3D = _keeps[0]
		if (k.get_node("Model/CanopyLost") as Node3D).visible or not (k.get_node("Model/Rubble2") as Node3D).visible:
			_fail("40 % HP: the lost canopy should be gone and the torn limb shown")
		if not (k.get_node("Smoke1") as GPUParticles3D).emitting:
			_fail("40 % HP: no smoke")
	if _frame == 190:
		var k: Node3D = _keeps[0]
		if not (k.get_node("Model/CanopyLost") as Node3D).visible or (k.get_node("Model/Rubble2") as Node3D).visible:
			_fail("healed: the damage looks did not revert")
		var idle: int = 0
		for p: Node in k.find_children("*", "GPUParticles3D", true, false):
			var g := p as GPUParticles3D
			if g.emitting and not g.one_shot:
				idle += g.amount
		if idle > 90:
			_fail("idle particles %d > 90" % idle)
	if _frame == 300:
		var k: Node3D = _keeps[0]
		if not (k.get_node("Model/Stump") as Node3D).visible:
			_fail("destroyed: no stump")
	if _frame == 500:
		if _finished != _keeps.size():
			_fail("destroyed_finished emitted %d / %d" % [_finished, _keeps.size()])
		print("%s %s" % ["PASS" if _ok else "FAIL", TASK_ID])
		return true
	return false


## Keep 0 was recoloured red before _ready; keep 1 must still be in the kingdom colour (materials per instance).
## In-game grade pass 2026-09-30: the canopy body is sage in every team; the team colour is on the leaf cards.
func _check_team_colours() -> void:
	var a: ShaderMaterial = _keeps[0].get(&"leafcard_material")
	var b: ShaderMaterial = _keeps[1].get(&"leafcard_material")
	if a == null or b == null or a == b:
		_fail("leaf card material is shared between keeps")
		return
	var ca: Color = a.get_shader_parameter(&"base_color")
	var cb: Color = b.get_shader_parameter(&"base_color")
	if not ca.is_equal_approx(Color(0.9, 0.2, 0.2)) or cb.is_equal_approx(ca):
		_fail("team colour not applied per keep (%s / %s)" % [ca, cb])


func _fail(msg: String) -> void:
	printerr("A2.5 FAIL: ", msg)
	_ok = false
