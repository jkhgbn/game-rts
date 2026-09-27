extends SceneTree
## Task 10.V9: the Greywater Lodge model (art/buildings/guilds/greywater_lodge/greywater_lodge.tscn).
## Run: godot --headless --path . -s tests/test_10_v9.gd --fixed-fps 60 --quit-after 900
## Checks: the scene instantiates headless; every hook is callable before _ready; 0 lights; both Lodges turned by
## yaw_for_spot stand square on the grid with their door anchor at market-trade.md 2.3's doors (-45, -51) / (45, 51);
## ~6 m tall; nothing below 2.45 m sticks out of the 6 x 6 footprint by more than 0.3 m (top parts < 1.1 m);
## merged meshes (one shared Structure mesh, <= 16 surfaces, few draw nodes, materials per instance); set_open
## closes the door and puts the brazier out; play_contract raises the horn flag and lowers it again; set_selected
## drives the rim; the flags fly toward world +X on both Lodges.

const TASK_ID := "10.v9"
const LODGE_PATH := "res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn"
const SPOTS: Array[Vector3] = [Vector3(-45, 0, -55), Vector3(45, 0, 55)]
const DOORS: Array[Vector3] = [Vector3(-45, 0, -51), Vector3(45, 0, 51)]

var frame := 0
var _lodges: Array[Node3D] = []
var _early: Node3D
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	var scene := load(LODGE_PATH) as PackedScene
	if scene == null:
		_fail("scene does not load")
		return
	for p: Vector3 in SPOTS:
		var l := scene.instantiate() as Node3D
		# Hooks before _ready must be safe.
		l.call(&"set_selected", false)
		l.call(&"set_open", true)
		l.call(&"set_team_color", Color.RED)
		l.position = p
		l.rotation.y = GreywaterLodgeModel.yaw_for_spot(p)
		world.add_child(l)
		_lodges.append(l)
	# A third one gets its calls before _ready (kept, applied at _ready).
	_early = scene.instantiate() as Node3D
	_early.call(&"set_open", false)
	_early.call(&"set_selected", true)
	_early.call(&"play_contract")
	_early.position = Vector3(0, 0, 20)
	world.add_child(_early)


func _process(_delta: float) -> bool:
	if not _errors.is_empty():
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	frame += 1
	if frame == 3:
		_check_static()
		_lodges[0].call(&"set_open", false)
		_lodges[0].call(&"set_selected", true)
		_lodges[1].call(&"play_contract")
	if frame == 90:
		_check_closed_and_raised()
		_lodges[0].call(&"set_open", true)
		_lodges[0].call(&"set_selected", false)
		_lodges[1].call(&"play_contract")   # retrigger while up: stays up
	if frame == 160:
		_check_reopened()
	if frame == 700:
		_check_lowered()
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


func _painted_rim(l: Node3D) -> float:
	var s := l.get_node(^"Structure") as MeshInstance3D
	for i: int in s.mesh.get_surface_count():
		var m := s.get_surface_override_material(i) as ShaderMaterial
		if m and m.shader and m.shader.resource_path.ends_with("greywater_lodge_painted.gdshader"):
			return float(m.get_shader_parameter(&"rim_strength"))
	return -1.0


func _check_static() -> void:
	var lights: int = _count_lights(root)
	_check(lights == 0, "expected 0 lights, found %d" % lights)
	_check(is_equal_approx(GreywaterLodgeModel.yaw_for_spot(SPOTS[0]), 0.0), "yaw_for_spot(NW) should be 0")
	_check(is_equal_approx(GreywaterLodgeModel.yaw_for_spot(SPOTS[1]), PI), "yaw_for_spot(SE) should be PI")
	_check(is_equal_approx(GreywaterLodgeModel.yaw_for_door(SPOTS[1], DOORS[1]), PI) \
		or is_equal_approx(GreywaterLodgeModel.yaw_for_door(SPOTS[1], DOORS[1]), -PI), "yaw_for_door(SE) should be PI")
	var shared_mesh: Mesh = null
	var first_mats: Array[Material] = []
	for i: int in _lodges.size():
		var l: Node3D = _lodges[i]
		for m: StringName in [&"set_open", &"is_open", &"set_selected", &"play_contract", &"is_contract_flag_up",
				&"set_team_color", &"get_door_point", &"get_door_direction"]:
			_check(l.has_method(m), "lodge lacks %s" % m)
		var door: Vector3 = l.call(&"get_door_point")
		_check(Vector2(door.x - DOORS[i].x, door.z - DOORS[i].z).length() < 0.05,
			"lodge %d door point %s, want %s" % [i, door, DOORS[i]])
		var dir: Vector3 = l.call(&"get_door_direction")
		var want_dir: Vector3 = (DOORS[i] - SPOTS[i]).normalized()
		_check(dir.dot(want_dir) > 0.99, "lodge %d door faces %s, not the road" % [i, dir])
		var yaw: float = l.global_transform.basis.get_euler().y
		var off: float = absf(fposmod(yaw + PI * 0.25, PI * 0.5) - PI * 0.25)
		_check(off < 0.01, "lodge %d not square on the grid (yaw %.3f)" % [i, yaw])
		var structure := l.get_node_or_null(^"Structure") as MeshInstance3D
		_check(structure != null, "no merged Structure mesh")
		if structure == null:
			continue
		var box: AABB = structure.get_aabb()
		_check(box.end.y > 5.8 and box.end.y < 7.0, "height %.2f (want ~6 m, < 7)" % box.end.y)
		_check(box.position.x > -4.1 and box.end.x < 4.1 and box.position.z > -4.1 and box.end.z < 4.1,
			"overhang beyond 1.1 m: %s" % box)
		var worst: float = 0.0
		var worst_v := Vector3.ZERO
		var verts_total: int = 0
		for s: int in structure.mesh.get_surface_count():
			var verts: PackedVector3Array = structure.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			verts_total += verts.size()
			for v: Vector3 in verts:
				if v.y < 2.45:
					var o: float = maxf(absf(v.x), absf(v.z)) - 3.0
					if o > worst:
						worst = o
						worst_v = v
		_check(worst <= 0.3, "ground-level overhang %.2f m > 0.3 at %s" % [worst, worst_v])
		_check(structure.mesh.get_surface_count() <= 16, "Structure has %d surfaces (> 16)" % structure.mesh.get_surface_count())
		if i == 0:
			shared_mesh = structure.mesh
			for s: int in structure.mesh.get_surface_count():
				first_mats.append(structure.get_surface_override_material(s))
			print("lodge structure: %d surfaces, %d vertices" % [structure.mesh.get_surface_count(), verts_total])
		else:
			_check(structure.mesh == shared_mesh, "both Lodges must share the baked Structure mesh")
			_check(structure.get_surface_override_material(0) != first_mats[0], "materials must be per instance")
		var geo: Array[Node] = l.find_children("*", "GeometryInstance3D", true, false)
		_check(geo.size() <= 20, "too many draw nodes: %d" % geo.size())
		for path: NodePath in [^"DoorPivot", ^"DoorGlow", ^"LanternPivot", ^"FlagPivot/Pennant",
				^"FlagPivot/HornFlagPivot/HornFlag", ^"Hound", ^"BrazierFire", ^"ChimneySmoke", ^"ContactDecal", ^"Rubble"]:
			_check(l.get_node_or_null(path) != null, "missing node %s" % path)
		# Flags fly toward world +X on both Lodges (same wind as the smoke).
		var pivot := l.get_node(^"FlagPivot") as Node3D
		_check(pivot.global_basis.x.normalized().dot(Vector3.RIGHT) > 0.9, "lodge %d flags do not fly toward +X" % i)
		if i == 0:
			print("lodge draw nodes: %d" % geo.size())
	# Early calls kept.
	_check(not bool(_early.call(&"is_open")), "set_open(false) before _ready lost")
	_check(bool(_early.call(&"is_contract_flag_up")), "play_contract before _ready lost")


func _check_closed_and_raised() -> void:
	var l0: Node3D = _lodges[0]
	var door := l0.get_node(^"DoorPivot") as Node3D
	_check(absf(door.rotation.y) < 0.02, "closed door still open (%.2f)" % door.rotation.y)
	_check(not (l0.get_node(^"BrazierFire") as GPUParticles3D).emitting, "closed: brazier still burning")
	_check(not (l0.get_node(^"ChimneySmoke") as GPUParticles3D).emitting, "closed: chimney still smoking")
	_check(not bool(l0.call(&"is_open")), "is_open() after set_open(false)")
	_check(_painted_rim(l0) > 0.7, "selected rim too weak (%.2f)" % _painted_rim(l0))
	var flag := _lodges[1].get_node(^"FlagPivot/HornFlagPivot") as Node3D
	_check(absf(flag.position.y - GreywaterLodgeModel.FLAG_HIGH) < 0.02, "horn flag not raised (y %.2f)" % flag.position.y)
	_check(flag.scale.x > 0.99, "horn flag not unfurled (%.2f)" % flag.scale.x)
	_check(bool(_lodges[1].call(&"is_contract_flag_up")), "is_contract_flag_up() false while raised")


func _check_reopened() -> void:
	var l0: Node3D = _lodges[0]
	var door := l0.get_node(^"DoorPivot") as Node3D
	_check(door.rotation.y < -1.5, "door did not swing open (%.2f)" % door.rotation.y)
	_check((l0.get_node(^"BrazierFire") as GPUParticles3D).emitting, "open: brazier not burning")
	_check(_painted_rim(l0) < 0.3, "rim still on after deselect (%.2f)" % _painted_rim(l0))
	var flag := _lodges[1].get_node(^"FlagPivot/HornFlagPivot") as Node3D
	_check(absf(flag.position.y - GreywaterLodgeModel.FLAG_HIGH) < 0.02, "retriggered horn flag came down early")


func _check_lowered() -> void:
	var flag := _lodges[1].get_node(^"FlagPivot/HornFlagPivot") as Node3D
	_check(absf(flag.position.y - GreywaterLodgeModel.FLAG_LOW) < 0.02, "horn flag not lowered (y %.2f)" % flag.position.y)
	_check(flag.scale.x < 0.2, "horn flag not furled (%.2f)" % flag.scale.x)
	_check(not bool(_lodges[1].call(&"is_contract_flag_up")), "is_contract_flag_up() still true")
	_check(_count_lights(root) == 0, "lights appeared")
