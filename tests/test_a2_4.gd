extends SceneTree
## Task A2.4 (Ice buildings epic pass): the Frost Hall, Snow Lodge, Rime Spire and Ice Wall models
## - instantiate headless and take every hook (construction 0 -> 1, HP 40 / 20 / 100 %, selection, team colour,
##   training pulse / shot, destroy -> destroyed_finished);
## - have no active light and stay merged (few visible MeshInstance3D nodes);
## - Ice Walls tile: a wall joins a finished wall on the next cell (2 m along world X / Z) and a finished Rime Spire,
##   whatever yaw the Building gave it (its Body is world-aligned); a site, another team's wall or a destroyed
##   neighbour doesn't join.
## Run:  godot --headless --path . -s tests/test_a2_4.gd --fixed-fps 60 --quit-after 900

const TASK_ID := "A2.4"
const MODELS: Array[String] = ["res://art/buildings/ice_hall.tscn", "res://art/buildings/ice_lodge.tscn",
	"res://art/buildings/ice_spire.tscn", "res://art/buildings/ice_wall.tscn"]
const MAX_MESHES := {"ice_hall": 16, "ice_lodge": 9, "ice_spire": 9, "ice_wall": 3}
const WALL := "res://art/buildings/ice_wall.tscn"
const SPIRE := "res://art/buildings/ice_spire.tscn"

var _models: Array[Node3D] = []
var _walls: Array[Node3D] = []   # a row at x 41 / 43 / 45 (z 1), a spire at 47, a wall at 45 z 3, a red wall at 41 z 3
var _finished: int = 0
var _frame: int = 0
var _errors: Array[String] = []


func _initialize() -> void:
	for i: int in MODELS.size():
		var m := (load(MODELS[i]) as PackedScene).instantiate() as Node3D
		m.call(&"set_construction_progress", 0.0)   # before _ready: cached
		m.position = Vector3(i * 9.0, 0, -20)
		root.add_child(m)
		m.connect(&"destroyed_finished", func() -> void: _finished += 1)
		_models.append(m)
	var ws := load(WALL) as PackedScene
	for p: Vector3 in [Vector3(41, 0, 1), Vector3(43, 0, 1), Vector3(45, 0, 1), Vector3(45, 0, 3), Vector3(41, 0, 3)]:
		var w := ws.instantiate() as Node3D
		w.position = p
		w.rotation.y = [0.0, PI * 0.5, PI, -PI * 0.5][_walls.size() % 4]
		if p == Vector3(41, 0, 3):
			w.call(&"set_team_color", Color(0.85, 0.2, 0.2))
		root.add_child(w)
		_walls.append(w)
	var sp := (load(SPIRE) as PackedScene).instantiate() as Node3D
	sp.position = Vector3(47, 0, 1)
	sp.call(&"set_construction_progress", 0.0)
	root.add_child(sp)
	_walls.append(sp)


func _process(_delta: float) -> bool:
	_frame += 1
	var p: float = clampf(_frame / 60.0, 0.0, 1.0)
	if _frame <= 61:
		for m: Node3D in _models:
			m.call(&"set_construction_progress", p)
	if _frame == 2:
		# Spire still a site: the wall next to it must not join it yet.
		_expect_codes(2, [0, 1, 1, 0], "row end next to a spire site")
		_walls[5].call(&"set_construction_progress", 1.0)
	if _frame == 3:
		_expect_codes(0, [1, 0, 0, 0], "row start (red wall at +Z is another team)")
		_expect_codes(1, [1, 1, 0, 0], "row middle")
		_expect_codes(2, [2, 1, 1, 0], "row end: spire at +X, wall at -X, wall at +Z")
		_expect_codes(3, [0, 0, 0, 1], "corner wall")
		_expect_codes(4, [0, 0, 0, 0], "red wall")
		for i: int in 5:
			var body := _walls[i].get_node_or_null(^"Body") as Node3D
			if body == null or not body.global_basis.is_equal_approx(Basis.IDENTITY):
				_errors.append("wall %d Body is not world-aligned (yaw %.2f)" % [i, _walls[i].rotation.y])
	if _frame == 4:
		_walls[1].call(&"play_destroyed")   # the middle wall falls: its neighbours lose their curtains toward it
	if _frame == 5:
		_expect_codes(0, [0, 0, 0, 0], "row start after the middle fell")
		_expect_codes(2, [2, 0, 1, 0], "row end after the middle fell")
		_expect_codes(1, [1, 1, 0, 0], "the falling wall keeps its curtains (they sink with it)")
		_walls[5].call(&"play_destroyed")
	if _frame == 6:
		_expect_codes(2, [0, 0, 1, 0], "row end after the spire fell")
	if _frame == 70:
		for m: Node3D in _models:
			var nm: String = m.scene_file_path.get_file().get_basename()
			var c: Vector2i = _count(m)
			if c.x > MAX_MESHES[nm]:
				_errors.append("%s has %d visible mesh nodes (max %d)" % [nm, c.x, MAX_MESHES[nm]])
			if c.y > 0:
				_errors.append("%s has %d visible lights (want 0)" % [nm, c.y])
			var s := m.get_node_or_null(^"Scaffold") as Node3D
			if s and s.visible:
				_errors.append("%s scaffold still visible when built" % nm)
			m.call(&"set_health_ratio", 0.4)
			m.call(&"set_selected", true)
			m.call(&"set_team_color", Color(0.85, 0.25, 0.25))
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
		if _finished != _models.size():
			_errors.append("destroyed_finished %d / %d" % [_finished, _models.size()])
		for m: Node3D in _models:
			var w := m.get_node_or_null(^"Wreck") as Node3D
			if w and not w.visible:
				_errors.append("%s wreck hidden after the collapse" % m.name)
		# Freeing a wall must not break its neighbours.
		_walls[3].queue_free()
	if _frame == 130 + 60 * 4 + 2:
		_expect_codes(2, [0, 0, 0, 0], "row end after the corner wall was freed")
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			for e: String in _errors:
				print("  ", e)
			print("FAIL %s: %s" % [TASK_ID, _errors[0]])
		return true
	return false


func _expect_codes(i: int, want: Array, what: String) -> void:
	var got: PackedInt32Array = _walls[i].get(&"_codes")
	if Array(got) != want:
		_errors.append("%s: neighbour codes %s, want %s" % [what, Array(got), want])


## (visible MeshInstance3D nodes, visible lights), recursive through visible nodes.
func _count(n: Node) -> Vector2i:
	var c := Vector2i.ZERO
	if n is MeshInstance3D and (n as MeshInstance3D).visible:
		c.x += 1
	if n is Light3D and (n as Light3D).visible:
		c.y += 1
	for ch: Node in n.get_children():
		if ch is Node3D and not (ch as Node3D).visible:
			continue
		c += _count(ch)
	return c
