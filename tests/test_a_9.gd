extends SceneTree
## Task A.9 test: every Fire / Shadow hall, house and tower model (and the Ice / Nature models built on the same
## base classes) instantiates, takes every hook (construction 0 -> 1, HP 40 % / 20 % / 100 %, selection, team
## colour, training pulse / shot, destroy) and emits destroyed_finished; the A.9 models stay merged (few nodes).
## Run: godot --headless --path . -s tests/test_a_9.gd --fixed-fps 60 --quit-after 900

const SCENES: Array[String] = [
	"res://art/buildings/fire_hall.tscn", "res://art/buildings/shadow_hall.tscn",
	"res://art/buildings/hearth.tscn", "res://art/buildings/hovel.tscn",
	"res://art/buildings/fire_tower.tscn", "res://art/buildings/shadow_tower.tscn",
	"res://art/buildings/ice_hall.tscn", "res://art/buildings/ice_lodge.tscn", "res://art/buildings/ice_spire.tscn",
	"res://art/buildings/ice_wall.tscn", "res://art/buildings/nature_hall.tscn", "res://art/buildings/nature_hollow.tscn",
	"res://art/buildings/nature_spire.tscn",
]
const MAX_MESHES := {"fire_hall": 14, "shadow_hall": 16, "hearth": 8, "hovel": 9, "fire_tower": 8, "shadow_tower": 10}

var _models: Array[Node3D] = []
var _finished: int = 0
var _frame: int = 0
var _fail: bool = false


func _initialize() -> void:
	for i: int in SCENES.size():
		var ps := load(SCENES[i]) as PackedScene
		if ps == null:
			_expect(false, "cannot load " + SCENES[i])
			continue
		var m := ps.instantiate() as Node3D
		m.call(&"set_construction_progress", 0.0)   # before _ready: cached
		m.position = Vector3(i * 8.0, 0, 0)
		root.add_child(m)
		m.connect(&"destroyed_finished", func() -> void: _finished += 1)
		_models.append(m)


func _process(_delta: float) -> bool:
	_frame += 1
	var p: float = clampf(_frame / 60.0, 0.0, 1.0)
	if _frame <= 61:
		for m: Node3D in _models:
			m.call(&"set_construction_progress", p)
	if _frame == 70:
		for m: Node3D in _models:
			var nm: String = m.scene_file_path.get_file().get_basename()
			if MAX_MESHES.has(nm):
				var c: int = _count(m)
				_expect(c <= MAX_MESHES[nm], "%s has %d visible mesh nodes (max %d)" % [nm, c, MAX_MESHES[nm]])
			for n: String in ["Scaffold"]:
				var s := m.get_node_or_null(n) as Node3D
				if s:
					_expect(not s.visible, "%s scaffold still visible when built" % nm)
			m.call(&"set_health_ratio", 0.4)
			m.call(&"set_selected", true)
			m.call(&"set_team_color", Color(0.2, 0.45, 0.95))
			if m.has_method(&"play_training_pulse"):
				m.call(&"play_training_pulse")
			if m.has_method(&"play_shot"):
				m.call(&"play_shot")
	if _frame == 90:
		for m: Node3D in _models:
			m.call(&"set_health_ratio", 0.2)
	if _frame == 110:
		for m: Node3D in _models:
			m.call(&"set_health_ratio", 1.0)
			m.call(&"set_selected", false)
	if _frame == 130:
		for m: Node3D in _models:
			m.call(&"play_destroyed")
	if _frame == 130 + 60 * 4:
		for m: Node3D in _models:
			var w := m.get_node_or_null("Wreck") as Node3D
			if w:
				_expect(w.visible, "%s wreck hidden after the collapse" % m.name)
		_expect(_finished == _models.size(), "destroyed_finished %d / %d" % [_finished, _models.size()])
		print("%s A.9 building models: art hooks" % ("FAIL" if _fail else "PASS"))
		return true
	return false


func _count(n: Node) -> int:
	var c: int = 1 if n is MeshInstance3D and (n as MeshInstance3D).visible else 0
	for ch: Node in n.get_children():
		if ch is Node3D and not (ch as Node3D).visible:
			continue
		c += _count(ch)
	return c


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_fail = true
		print("FAIL: ", msg)
