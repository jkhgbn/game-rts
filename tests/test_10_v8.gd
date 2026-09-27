extends SceneTree
## Task 10.V8: the Magpie Den model (docs/design/market-trade.md sections 2.3, 9, 12).
## Run: godot --headless --path . -s tests/test_10_v8.gd --fixed-fps 60 --quit-after 600
## Checks: the scene instantiates headless at the spec path; hooks exist and are safe before _ready; 0 lights;
## yaw_for_door turns the door toward the spec's door points (-51, -45) / (51, 45) and the house stays square on the
## grid; footprint 6 x 6 (nothing below 2.45 m more than 0.3 m out, eaves / crane within 1.2 m), ridge ~6 m and the
## magpie vane is the highest point (~8 m); merged meshes shared by both Dens, materials per instance; budget (draw
## nodes, surfaces, particles); four stolen banner colours + the Magpie flag in the one cloth mesh; set_open,
## set_selected and play_band_out (also before _ready) animate the door / rim / glow as documented.

const TASK_ID := "10.v8"
const DEN_PATH := "res://art/buildings/guilds/magpie_den/magpie_den.tscn"
const SPOTS: Array[Vector3] = [Vector3(-55, 0, -45), Vector3(55, 0, 45)]
const DOORS: Array[Vector3] = [Vector3(-51, 0, -45), Vector3(51, 0, 45)]

var frame := 0
var _dens: Array[Node3D] = []
var _early: Node3D
var _vane_basis0: Basis
var _house: Node3D   # a GuildHouse (10.C1) when it exists: it must pick up this model and forward the hooks
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	if not ResourceLoader.exists(DEN_PATH):
		_fail("scene missing at %s" % DEN_PATH)
		return
	var scene := load(DEN_PATH) as PackedScene
	if scene == null:
		_fail("scene does not load")
		return
	for i: int in SPOTS.size():
		var d := scene.instantiate() as Node3D
		d.position = SPOTS[i]
		d.rotation.y = MagpieDenModel.yaw_for_door(SPOTS[i], DOORS[i])
		# Hooks before _ready must be safe.
		d.call(&"set_selected", false)
		d.call(&"set_open", true)
		d.call(&"set_team_color", Color.RED)
		world.add_child(d)
		_dens.append(d)
	_early = scene.instantiate() as Node3D
	_early.position = Vector3(0, 0, 30)
	_early.call(&"play_band_out")
	world.add_child(_early)
	const GH_PATH := "res://scripts/world/guild_house.gd"
	if ResourceLoader.exists(GH_PATH):
		var gh_script := load(GH_PATH) as Script
		_house = gh_script.new() as Node3D
		if _house:
			_house.set(&"kind", &"den")
			_house.position = Vector3(55, 0, -20)
			_house.rotation.y = -PI * 0.5
			world.add_child(_house)


func _process(_delta: float) -> bool:
	if not _errors.is_empty():
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	frame += 1
	if frame == 3:
		_check_static()
		_check_budget()
		_check_cloth()
		_dens[0].call(&"set_selected", true)
		_dens[1].call(&"set_open", false)
		_vane_basis0 = (_dens[0].get_node(^"Body/VanePivot") as Node3D).basis
		_check_guild_house()
	if frame == 20:
		var ed := _early.get_node(^"Body/DoorPivot") as Node3D
		_check(ed.rotation.y < -1.6, "play_band_out before _ready lost (door %.2f)" % ed.rotation.y)
	if frame == 70:
		_check_selected_and_closed()
		_dens[1].call(&"set_open", true)
		_dens[0].call(&"play_band_out")
		var dust := _dens[0].get_node(^"Body/DoorDust") as GPUParticles3D
		_check(dust != null and dust.emitting and dust.one_shot, "band-out dust not emitting")
	if frame == 100:
		var dp := _dens[0].get_node(^"Body/DoorPivot") as Node3D
		_check(absf(dp.rotation.y + deg_to_rad(112.0)) < 0.05, "band-out door not flung wide (%.2f)" % dp.rotation.y)
	if frame == 220:
		_check_after_anim()
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _fail(msg: String) -> void:
	_errors.append(msg)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_errors.append(msg)


func _count_lights(n: Node) -> int:
	var c: int = 1 if n is Light3D else 0
	for ch: Node in n.get_children():
		c += _count_lights(ch)
	return c


## World-space AABB of all vertices of `mi` (optionally only those with local y below / above `split`).
func _vertex_extent(mi: MeshInstance3D, below: float, above: float) -> Vector2:
	# Returns (max |x| or |z| offset from the den centre, in the den's frame) for vertices with y in [above, below).
	var worst: float = 0.0
	var den: Node3D = mi.get_parent().get_parent() as Node3D
	var to_den: Transform3D = den.global_transform.affine_inverse() * mi.global_transform
	for s: int in mi.mesh.get_surface_count():
		var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
		for v: Vector3 in verts:
			var p: Vector3 = to_den * v
			if p.y >= above and p.y < below:
				worst = maxf(worst, maxf(absf(p.x), absf(p.z)))
	return Vector2(worst, 0.0)


func _check_static() -> void:
	var lights: int = _count_lights(root)
	_check(lights == 0, "expected 0 lights, found %d" % lights)
	var y0: float = MagpieDenModel.yaw_for_door(SPOTS[0], DOORS[0])
	var y1: float = MagpieDenModel.yaw_for_door(SPOTS[1], DOORS[1])
	_check(absf(y0 - PI * 0.5) < 0.001, "yaw_for_door NW should be +PI/2, got %.3f" % y0)
	_check(absf(y1 + PI * 0.5) < 0.001, "yaw_for_door SE should be -PI/2, got %.3f" % y1)
	for i: int in _dens.size():
		var d: Node3D = _dens[i]
		for m: StringName in [&"set_open", &"is_open", &"set_selected", &"is_selected", &"play_band_out",
				&"set_team_color", &"get_door_point", &"get_door_direction"]:
			_check(d.has_method(m), "den lacks %s" % m)
		var door: Vector3 = d.call(&"get_door_point")
		_check(Vector2(door.x - DOORS[i].x, door.z - DOORS[i].z).length() < 0.05,
			"den %d door point %s, want %s" % [i, door, DOORS[i]])
		var dir: Vector3 = d.call(&"get_door_direction")
		_check(dir.dot((DOORS[i] - SPOTS[i]).normalized()) > 0.99, "den %d door faces %s" % [i, dir])
		var body := d.get_node_or_null(^"Body") as Node3D
		_check(body != null, "den has no Body")
		if body == null:
			continue
		# Square on the grid: the house axes are world axes (the Body may be mirrored along X, see _update_facing).
		var gb: Basis = body.global_transform.basis
		for axis: Vector3 in [gb.x.normalized(), gb.z.normalized()]:
			_check(maxf(absf(axis.x), absf(axis.z)) > 0.9999, "den %d not square on the grid (%s)" % [i, axis])
		_check(absf(body.transform.basis.x.x) > 0.999 and body.transform.basis.y.is_equal_approx(Vector3.UP)
			and body.transform.basis.z.is_equal_approx(Vector3.BACK), "Body may only be mirrored along X")
		# The mast / vane stand on the far side from the default RTS camera (world -Z), for both Dens.
		var vp := d.get_node_or_null(^"Body/VanePivot") as Node3D
		if vp:
			_check(vp.global_position.z < SPOTS[i].z - 1.5,
				"den %d: the vane must stand on the far gable (z %.2f, den %.2f)" % [i, vp.global_position.z, SPOTS[i].z])
		for p: NodePath in [^"Body/Structure", ^"Body/Cloth", ^"Body/DoorPivot", ^"Body/DoorGlow",
				^"Body/LanternPivot", ^"Body/VanePivot", ^"Body/SackPivot", ^"Body/ContactDecal", ^"Body/Rubble",
				^"Body/DoorDust"]:
			_check(d.get_node_or_null(p) != null, "den lacks %s" % p)
		var structure := d.get_node_or_null(^"Body/Structure") as MeshInstance3D
		if structure == null:
			continue
		var box: AABB = structure.get_aabb()
		_check(box.end.y > 6.8 and box.end.y < 8.2, "structure top (mast + nest) %.2f, want ~7.5" % box.end.y)
		# Ground level: within the 6 x 6 footprint + 0.3 m. Upper parts (eaves, crane): within 1.2 m.
		var cloth := d.get_node(^"Body/Cloth") as MeshInstance3D
		for mi: MeshInstance3D in [structure, cloth]:
			var low: float = _vertex_extent(mi, 2.45, -1.0).x
			var high: float = _vertex_extent(mi, 100.0, 2.45).x
			_check(low <= 3.3, "%s ground-level overhang: %.2f m from the centre (max 3.3)" % [mi.name, low])
			_check(high <= 4.2, "%s upper overhang: %.2f m from the centre (max 4.2)" % [mi.name, high])
		# The magpie vane is the highest point (dominant vertical), ~8 m.
		var vane := d.get_node(^"Body/VanePivot/Vane") as MeshInstance3D
		_check(vane != null, "no vane mesh")
		if vane:
			var vb: AABB = vane.global_transform * vane.get_aabb()
			_check(vb.end.y > box.end.y + 0.3, "vane (%.2f) must top the structure (%.2f)" % [vb.end.y, box.end.y])
			_check(vb.end.y > 7.4 and vb.end.y < 9.0, "vane top %.2f, want ~8.5" % vb.end.y)
			_check(vb.size.x > 1.0 or vb.size.z > 1.0, "vane bird too small to read (%s)" % vb.size)
	# Shared merged meshes, per-instance materials.
	var s0 := _dens[0].get_node(^"Body/Structure") as MeshInstance3D
	var s1 := _dens[1].get_node(^"Body/Structure") as MeshInstance3D
	_check(s0.mesh == s1.mesh, "the two Dens must share the merged structure mesh")
	_check(s0.get_surface_override_material(0) != s1.get_surface_override_material(0),
		"materials must be per instance (selection rim)")
	_check(s0.mesh is ArrayMesh and s0.mesh.get_surface_count() >= 8,
		"structure should be one merged ArrayMesh with one surface per material")


func _check_budget() -> void:
	var d: Node3D = _dens[0]
	var geo: Array[Node] = d.find_children("*", "GeometryInstance3D", true, false)
	_check(geo.size() <= 14, "too many draw nodes: %d (tavern budget ~12-14)" % geo.size())
	var surfaces: int = 0
	var particles: int = 0
	for n: Node in geo:
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			surfaces += mi.mesh.get_surface_count() if mi.mesh else 0
		elif n is MultiMeshInstance3D:
			surfaces += 1
		elif n is GPUParticles3D:
			surfaces += 1
			particles += (n as GPUParticles3D).amount
		var gi := n as GeometryInstance3D
		if n.name != "Structure" and n.name != "Rubble" and n.name != "DoorLeaf":
			_check(gi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or String(n.name) in ["Vane", "Sack", "DoorLeaf"],
				"%s should not cast shadows" % n.name)
	_check(surfaces <= 34, "too many surfaces (draw calls): %d" % surfaces)
	_check(particles <= 30, "too many particles: %d" % particles)


func _check_cloth() -> void:
	var cloth := _dens[0].get_node(^"Body/Cloth") as MeshInstance3D
	_check(cloth.mesh.get_surface_count() == 1, "cloth must be one surface (one draw call)")
	var cols: PackedColorArray = cloth.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var banners: Array[Color] = []
	var flag: int = 0
	for c: Color in cols:
		if c.a > 0.5:
			var known: bool = false
			for b: Color in banners:
				if b.is_equal_approx(c):
					known = true
					break
			if not known:
				banners.append(c)
		else:
			flag += 1
	_check(banners.size() == 4, "want 4 stolen banner colours, found %d" % banners.size())
	_check(flag > 0, "the Magpie flag is missing from the cloth mesh")
	var want: Array[Color] = [Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.45, 0.75, 0.95),
		Color(0.35, 0.70, 0.25)]
	for w: Color in want:
		var lin: Color = w.srgb_to_linear()
		var found: bool = false
		for b: Color in banners:
			if absf(b.r - lin.r) < 0.01 and absf(b.g - lin.g) < 0.01 and absf(b.b - lin.b) < 0.01:
				found = true
		_check(found, "kingdom banner colour %s missing" % w)


func _check_guild_house() -> void:
	if _house == null:
		print("note: GuildHouse missing, integration check skipped")
		return
	var m: Variant = _house.call(&"model")
	_check(m is Node3D and (m as Node3D).get_script() == _dens[0].get_script(),
		"GuildHouse did not instance the Magpie Den model")
	if not (m is Node3D):
		return
	var model := m as Node3D
	_check(not bool(model.call(&"is_open")), "GuildHouse starts closed and should forward set_open(false)")
	_house.call(&"set_open", true)
	_house.call(&"set_selected", true)
	_house.call(&"play_band_out")
	_check(bool(model.call(&"is_open")) and bool(model.call(&"is_selected")), "GuildHouse hooks not forwarded")
	var a: Vector3 = _house.call(&"door_point")
	var b: Vector3 = model.call(&"get_door_point")
	_check(Vector2(a.x - b.x, a.z - b.z).length() < 0.05, "GuildHouse door %s != model door %s" % [a, b])
	var vp := model.get_node(^"Body/VanePivot") as Node3D
	_check(vp.global_position.z < _house.global_position.z - 1.5, "vane not on the far side inside a GuildHouse")


func _rim(d: Node3D) -> float:
	var s := d.get_node(^"Body/Structure") as MeshInstance3D
	var m := s.get_surface_override_material(0) as ShaderMaterial
	return float(m.get_shader_parameter(&"rim_strength"))


func _check_selected_and_closed() -> void:
	_check(_rim(_dens[0]) > 0.7, "selected rim too weak (%.2f)" % _rim(_dens[0]))
	_check(_rim(_dens[1]) < 0.3, "unselected rim should stay idle (%.2f)" % _rim(_dens[1]))
	_check(bool(_dens[0].call(&"is_selected")), "is_selected false after set_selected(true)")
	_check(not bool(_dens[1].call(&"is_open")), "set_open(false) not kept")
	var dp := _dens[1].get_node(^"Body/DoorPivot") as Node3D
	_check(absf(dp.rotation.y) < 0.01, "closed door should be shut (%.2f)" % dp.rotation.y)
	var pool := _dens[1].get_node(^"Body/LightPool") as GeometryInstance3D
	_check(pool != null and not pool.visible, "light pool should hide when closed")


func _check_after_anim() -> void:
	var ajar: float = -deg_to_rad(42.0)
	for i: int in _dens.size():
		var dp := _dens[i].get_node(^"Body/DoorPivot") as Node3D
		_check(absf(dp.rotation.y - ajar) < 0.03, "den %d door should be ajar when open (%.2f)" % [i, dp.rotation.y])
	var vb := (_dens[0].get_node(^"Body/VanePivot") as Node3D).basis
	_check(not vb.is_equal_approx(_vane_basis0), "the vane should turn over time")
	_dens[0].call(&"set_selected", false)
	_check(_count_lights(root) == 0, "lights appeared")
