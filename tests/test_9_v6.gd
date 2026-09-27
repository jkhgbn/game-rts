extends SceneTree
## Task 9.V6: the tavern model and the bounty flag model.
## Run: godot --headless --path . -s tests/test_9_v6.gd --fixed-fps 60 --quit-after 600
## Checks: both scenes instantiate headless; every public method is callable (also before _ready); 0 lights;
## the tavern turned like tavern.gd (yaw_for_spot) stands square on the grid with its door anchor at spot x 0.8;
## its ground floor stays inside the 6 x 6 footprint (+0.3 m) and it is ~6 m tall; the flag has a 1.6 m pole, a
## coin of radius 0.35, 3 draw nodes + the cairn, team colour and kind reach the shaders; 40 flags are cheap.

const TASK_ID := "9.v6"
const TAVERN_PATH := "res://art/buildings/tavern/tavern_model.tscn"
const FLAG_PATH := "res://art/buildings/tavern/bounty_flag.tscn"
const SPOTS: Array[Vector3] = [Vector3(-15, 0, -15), Vector3(15, 0, 15)]

var frame := 0
var _taverns: Array[Node3D] = []
var _flags: Array[Node3D] = []
var _early_flag: Node3D
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	var tavern_scene := load(TAVERN_PATH) as PackedScene
	var flag_scene := load(FLAG_PATH) as PackedScene
	if tavern_scene == null or flag_scene == null:
		_fail("scenes do not load")
		return
	for p: Vector3 in SPOTS:
		var holder := Node3D.new()
		holder.position = p
		holder.rotation.y = TavernModel.yaw_for_spot(p)
		world.add_child(holder)
		var t := tavern_scene.instantiate() as Node3D
		# Hooks before _ready must be safe.
		t.call(&"set_selected", false)
		t.call(&"set_open", true)
		holder.add_child(t)
		_taverns.append(t)
	_early_flag = flag_scene.instantiate() as Node3D
	_early_flag.call(&"set_kind", 2)
	_early_flag.call(&"set_team_color", Color(0.45, 0.75, 0.95))
	_early_flag.call(&"play_raise")
	_early_flag.call(&"set_grounded", false)
	world.add_child(_early_flag)
	for i: int in 40:
		var f := flag_scene.instantiate() as Node3D
		f.position = Vector3(-20.0 + i, 0.0, 30.0)
		world.add_child(f)
		_flags.append(f)


func _process(_delta: float) -> bool:
	if not _errors.is_empty():
		return true
	frame += 1
	if frame == 3:
		_check_static()
		_exercise()
	if frame == 90:
		_check_after_anim()
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _fail(msg: String) -> void:
	_errors.append(msg)
	print("FAIL %s: %s" % [TASK_ID, msg])


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_errors.append(msg)


func _count_lights(n: Node) -> int:
	var c: int = 1 if n is Light3D else 0
	for ch: Node in n.get_children():
		c += _count_lights(ch)
	return c


func _check_static() -> void:
	var tree_lights: int = _count_lights(root)
	_check(tree_lights == 0, "expected 0 lights, found %d" % tree_lights)
	# --- Tavern ---
	for i: int in _taverns.size():
		var t: Node3D = _taverns[i]
		for m: StringName in [&"set_open", &"is_open", &"set_selected", &"play_door_pulse", &"set_team_color",
				&"get_door_point", &"get_door_direction"]:
			_check(t.has_method(m), "tavern lacks %s" % m)
		var door: Vector3 = t.call(&"get_door_point")
		var want: Vector3 = SPOTS[i] * 0.8
		_check(Vector2(door.x - want.x, door.z - want.z).length() < 0.05,
			"tavern %d door point %s, want %s" % [i, door, want])
		var dir: Vector3 = t.call(&"get_door_direction")
		_check(dir.dot(-SPOTS[i].normalized()) > 0.99, "tavern %d door faces %s, not the centre" % [i, dir])
		var body := t.get_node_or_null(^"Body") as Node3D
		_check(body != null, "tavern has no Body")
		if body == null:
			continue
		# Square on the grid: the house's world yaw is a multiple of 90 degrees.
		var yaw: float = body.global_transform.basis.get_euler().y
		var off: float = absf(fposmod(yaw + PI * 0.25, PI * 0.5) - PI * 0.25)
		_check(off < 0.01, "tavern %d house not square on the grid (yaw %.3f)" % [i, yaw])
		var structure := body.get_node_or_null(^"Structure") as MeshInstance3D
		_check(structure != null, "tavern has no merged Structure mesh")
		if structure:
			var box: AABB = structure.get_aabb()
			_check(box.end.y > 5.8 and box.end.y < 8.2, "tavern height %.2f (want ~6 m, chimney < 8.2)" % box.end.y)
			_check(box.position.x > -4.0 and box.end.x < 4.0 and box.position.z > -4.0 and box.end.z < 4.0,
				"tavern overhang beyond 1 m: %s" % box)
		# Everything below 2.5 m (plinth, walls, props) stays within the footprint + 0.3 m: check the ground floor
		# pieces' AABB via a slab of the merged mesh vertices.
		if structure:
			var worst: float = 0.0
			for s: int in structure.mesh.get_surface_count():
				var verts: PackedVector3Array = structure.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
				for v: Vector3 in verts:
					if v.y < 2.45:
						worst = maxf(worst, maxf(absf(v.x), absf(v.z)) - 3.0)
			_check(worst <= 0.3, "tavern ground-level overhang %.2f m > 0.3" % worst)
		_check(t.get_node_or_null(^"Body/SignPivot") != null, "no hanging sign")
		_check(t.get_node_or_null(^"Body/LanternPivot") != null, "no lantern")
	_check(TavernModel.yaw_for_spot(SPOTS[0]) > 0.78 and TavernModel.yaw_for_spot(SPOTS[0]) < 0.79,
		"yaw_for_spot(-15, -15) should be +45 degrees")
	# --- Flags ---
	var f: Node3D = _flags[0]
	for m: StringName in [&"set_team_color", &"set_kind", &"get_kind", &"set_selected", &"play_raise",
			&"set_grounded"]:
		_check(f.has_method(m), "flag lacks %s" % m)
	var geo: Array[Node] = f.find_children("*", "GeometryInstance3D", true, false)
	_check(geo.size() == 4, "flag should have 4 mesh nodes (stand, cairn, pennant, coin), has %d" % geo.size())
	var stand := f.get_node_or_null(^"Stand") as MeshInstance3D
	var coin := f.get_node_or_null(^"Coin") as MeshInstance3D
	var pennant := f.get_node_or_null(^"Pennant") as MeshInstance3D
	_check(stand != null and coin != null and pennant != null, "flag nodes missing")
	if stand and coin and pennant:
		var pole_top: float = stand.get_aabb().end.y
		_check(pole_top > 1.6 and pole_top < 1.9, "pole top %.2f (1.6 m pole + finial)" % pole_top)
		var cb: AABB = coin.get_aabb()
		_check(absf(cb.size.x - 0.7) < 0.02 and absf(cb.size.y - 0.7) < 0.02, "coin radius wrong: %s" % cb.size)
		_check(coin.position.y - 0.35 > 1.6, "coin must float above the pole")
		# Shared meshes and materials between flags (cheap).
		var coin2 := _flags[1].get_node(^"Coin") as MeshInstance3D
		_check(coin2.mesh == coin.mesh and coin2.material_override == coin.material_override,
			"flags must share coin mesh + material")
		var pen2 := _flags[1].get_node(^"Pennant") as MeshInstance3D
		_check(pen2.material_override == pennant.material_override, "flags must share the pennant material")
	# Early calls (before _ready) were kept.
	_check(int(_early_flag.call(&"get_kind")) == 2, "set_kind before _ready lost")
	var cairn := _early_flag.get_node_or_null(^"Cairn") as Node3D
	_check(cairn != null and not cairn.visible, "set_grounded(false) before _ready lost")
	var epen := _early_flag.get_node(^"Pennant") as GeometryInstance3D
	var ec: Variant = epen.get_instance_shader_parameter(&"team_color")
	_check(ec is Color and (ec as Color).is_equal_approx(Color(0.45, 0.75, 0.95)), "team colour not on the pennant")


func _exercise() -> void:
	for t: Node3D in _taverns:
		t.call(&"set_open", false)
		t.call(&"set_selected", true)
		t.call(&"play_door_pulse")
		t.call(&"set_team_color", Color.RED)
		_check(not bool(t.call(&"is_open")), "set_open(false) not kept")
	for i: int in _flags.size():
		var f: Node3D = _flags[i]
		f.call(&"set_team_color", Color.from_hsv(float(i) / 40.0, 0.7, 0.9))
		f.call(&"set_kind", i % 4)
		f.call(&"set_selected", i % 2 == 0)
		f.call(&"play_raise")
	_flags[5].call(&"set_kind", 9)
	_check(int(_flags[5].call(&"get_kind")) == 3, "set_kind must clamp to 0..3")
	var coin := _flags[6].get_node(^"Coin") as GeometryInstance3D
	var k: Variant = coin.get_instance_shader_parameter(&"kind")
	_check(k != null and is_equal_approx(float(k), 2.0), "kind not on the coin (got %s)" % str(k))


func _check_after_anim() -> void:
	# play_raise finished: coin back in place, processing off.
	var f: Node3D = _flags[3]
	var coin := f.get_node(^"Coin") as Node3D
	_check(absf(coin.scale.x - 1.0) < 0.001, "coin did not settle after play_raise")
	_check(not f.is_processing(), "flag should not process when idle")
	for t: Node3D in _taverns:
		t.call(&"set_open", true)
	_check(_count_lights(root) == 0, "lights appeared")
