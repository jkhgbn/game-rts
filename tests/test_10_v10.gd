extends SceneTree
## Task 10.V10: trading post model, waystones, road paint in the ground shader.
## Run: godot --headless --path . -s tests/test_10_v10.gd --fixed-fps 60 --quit-after 900
## Checks:
## - trade_post.tscn instantiates headless; hooks exist and are safe before _ready; 0 lights anywhere;
## - turned with yaw_for_door the four posts stand square on the grid, the door point lands on the spec door (4 m);
## - everything below 2.5 m stays inside the 6 x 6 footprint (+0.3 m), roof ~4.1-4.8 m, mast ~6 m;
## - set_sign / sign_index show exactly one of the 4 emblems (clamped), sign_for_post maps the 4 post ids;
##   the sign head's board faces world +Z (the camera) for every post rotation;
## - set_held(Color) raises the pennant with that colour, set_held(null) lowers it; set_open(false) closes (shutter,
##   awning, flames), play_trade / set_selected / set_team_color are callable; meshes are shared between posts;
## - ground shader: has road_segs (vec4[16]) / road_count / road_width, road_count defaults to 0 (map unchanged),
##   EnvProps' material accepts the 10 ring segments; the map dressing keeps decor off the roads;
## - waystone mesh: one surface, env material, ~1 m tall; WaystoneRow spaces ~10 m, respects end / clear radii, one
##   MultiMesh.

const TASK_ID := "10.v10"
const POST_PATH := "res://art/buildings/trade_post/trade_post.tscn"
const WAYSTONE_PATH := "res://art/environment/meshes/waystone.res"
const ROW_PATH := "res://art/environment/meshes/waystone_row.gd"
const GROUND_MAT := "res://art/environment/ground_material.tres"
const POSTS: Array = [
	[&"heron_ford", Vector3(-53, 0, 1), Vector3(-49, 0, 1)],
	[&"millstone_cross", Vector3(-1, 0, 53), Vector3(-1, 0, 49)],
	[&"lantern_wharf", Vector3(53, 0, -1), Vector3(49, 0, -1)],
	[&"saltgate", Vector3(1, 0, -53), Vector3(1, 0, -49)],
]

var frame := 0
var _posts: Array[Node3D] = []
var _early: Node3D
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	var scene := load(POST_PATH) as PackedScene
	if scene == null:
		_fail("trade_post.tscn does not load")
		return
	var script: Script = load("res://art/buildings/trade_post/trade_post_model.gd")
	for p: Array in POSTS:
		var holder := Node3D.new()
		holder.position = p[1]
		holder.rotation.y = float(script.call(&"yaw_for_door", p[1], p[2]))
		world.add_child(holder)
		var m := scene.instantiate() as Node3D
		m.call(&"set_sign", int(script.call(&"sign_for_post", p[0])))
		m.call(&"set_open", true)
		m.call(&"set_selected", false)
		holder.add_child(m)
		_posts.append(m)
	# Hooks before _ready are kept.
	_early = scene.instantiate() as Node3D
	_early.call(&"set_sign", 9)
	_early.call(&"set_open", false)
	_early.call(&"set_held", Color(0.42, 0.22, 0.60))
	_early.call(&"play_trade")
	_early.position = Vector3(0, 0, 20)
	world.add_child(_early)


func _process(_delta: float) -> bool:
	if not _errors.is_empty() and frame == 0:
		return true
	frame += 1
	if frame == 3:
		_check_static()
		_check_ground()
		_check_waystones()
		_exercise()
	if frame == 150:
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
	_check(_count_lights(root) == 0, "expected 0 lights, found %d" % _count_lights(root))
	var script: Script = load("res://art/buildings/trade_post/trade_post_model.gd")
	for i: int in 4:
		_check(int(script.call(&"sign_for_post", POSTS[i][0])) == i, "sign_for_post(%s) != %d" % [POSTS[i][0], i])
	for i: int in _posts.size():
		var t: Node3D = _posts[i]
		for m: StringName in [&"set_sign", &"get_sign", &"set_open", &"is_open", &"set_held", &"is_held", &"set_selected",
				&"play_trade", &"set_team_color", &"get_door_point", &"get_door_direction"]:
			_check(t.has_method(m), "post lacks %s" % m)
		_check("sign_index" in t, "post lacks sign_index")
		var door: Vector3 = t.call(&"get_door_point")
		var want: Vector3 = POSTS[i][2]
		_check(Vector2(door.x - want.x, door.z - want.z).length() < 0.05, "post %d door %s, want %s" % [i, door, want])
		var body := t.get_node_or_null(^"Body") as Node3D
		_check(body != null, "post has no Body")
		if body == null:
			continue
		var yaw: float = t.global_transform.basis.get_euler().y
		var off: float = absf(fposmod(yaw + PI * 0.25, PI * 0.5) - PI * 0.25)
		_check(off < 0.01, "post %d not square on the grid (yaw %.3f)" % [i, yaw])
		# The body is mirrored along X only when that moves the mast away from the default camera (Lantern Wharf).
		var want_mirror: float = -1.0 if i == 2 else 1.0
		_check(is_equal_approx(body.scale.x, want_mirror), "post %d body mirror %.1f, want %.1f" % [i, body.scale.x, want_mirror])
		var mast_w: Vector3 = (body.get_node(^"SignHead") as Node3D).global_position - t.global_position
		_check(mast_w.z < 0.0 or i == 3, "post %d mast on the camera side (%s)" % [i, mast_w])
		var structure := body.get_node_or_null(^"Structure") as MeshInstance3D
		_check(structure != null, "no merged Structure mesh")
		if structure:
			var box: AABB = structure.get_aabb()
			_check(box.end.y > 5.8 and box.end.y < 6.6, "mast top %.2f (want ~6.1)" % box.end.y)
			var worst: float = 0.0
			var roof_top: float = 0.0
			for s: int in structure.mesh.get_surface_count():
				var verts: PackedVector3Array = structure.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
				for v: Vector3 in verts:
					if v.y < 2.45:
						worst = maxf(worst, maxf(absf(v.x), absf(v.z)) - 3.0)
					if absf(v.x - 2.5) > 0.4 or absf(v.z - 2.45) > 0.4:
						roof_top = maxf(roof_top, v.y)
			_check(worst <= 0.3, "ground-level overhang %.2f m > 0.3" % worst)
			_check(roof_top > 4.1 and roof_top < 4.8, "roof top %.2f (want ~4.4)" % roof_top)
			_check(structure.mesh.get_surface_count() <= 12, "structure has %d surfaces (draw calls)" % structure.mesh.get_surface_count())
		for nm: String in ["SignHead", "SignHead/SignPivot", "SignHead/Pennant", "LanternPivot", "ShutterPivot",
				"AwningPivot", "Flames", "Coals", "ContactDecal", "Rubble"]:
			_check(body.get_node_or_null(NodePath(nm)) != null, "post lacks Body/%s" % nm)
		# One emblem visible, the right one.
		var shown: Array[int] = []
		for k: int in 4:
			var s2 := body.get_node_or_null(NodePath("SignHead/SignPivot/Sign%d" % k)) as MeshInstance3D
			if s2 and s2.visible:
				shown.append(k)
		_check(shown == [i], "post %d shows emblems %s" % [i, shown])
		# The board faces world +Z (or -Z: double-sided) with the arm pointing away from the building.
		var head := body.get_node_or_null(^"SignHead") as Node3D
		if head:
			var hb: Basis = head.global_transform.basis
			_check(absf(absf(hb.z.normalized().z) - 1.0) < 0.01, "post %d sign faces %s, not the camera" % [i, hb.z])
			var arm_dir: Vector3 = hb.x.normalized()
			var out: Vector3 = head.global_position - t.global_position
			_check(arm_dir.dot(Vector3(out.x, 0, out.z)) > 0.0, "post %d sign arm points into the building" % i)
	# Shared meshes between posts.
	var a := _posts[0].get_node(^"Body/Structure") as MeshInstance3D
	var b := _posts[1].get_node(^"Body/Structure") as MeshInstance3D
	_check(a.mesh == b.mesh, "posts must share the merged structure mesh")
	# Early hooks.
	_check(int(_early.call(&"get_sign")) == 3, "set_sign(9) before _ready must clamp to 3")
	_check(not bool(_early.call(&"is_open")), "set_open(false) before _ready lost")
	_check(bool(_early.call(&"is_held")), "set_held before _ready lost")
	var pen := _early.get_node(^"Body/SignHead/Pennant") as GeometryInstance3D
	var pc: Variant = pen.get_instance_shader_parameter(&"team_color")
	_check(pc is Color and (pc as Color).is_equal_approx(Color(0.42, 0.22, 0.60)), "held colour not on the pennant")


func _check_ground() -> void:
	var sm := load(GROUND_MAT) as ShaderMaterial
	_check(sm != null, "ground_material.tres missing")
	if sm == null:
		return
	var names: Dictionary = {}
	for u: Dictionary in sm.shader.get_shader_uniform_list():
		names[String(u["name"])] = u
	for n: String in ["road_segs", "road_count", "road_width", "road_meander", "road_cobble"]:
		_check(names.has(n), "ground shader lacks uniform %s" % n)
	# (The headless renderer has no shader defaults: read the declarations.)
	_check(sm.shader.code.contains("uniform int road_count = 0;"), "road_count must default to 0")
	_check(sm.shader.code.contains("uniform vec4 road_segs[16];"), "road_segs must be vec4[16]")
	var cur: Variant = sm.get_shader_parameter(&"road_count")
	_check(cur == null or int(cur) == 0, "ground_material.tres must not set roads (road_count %s)" % str(cur))
	# The 10 ring segments set on a copy (what EnvProps.ground_material does) read back unchanged.
	var mat := sm.duplicate() as ShaderMaterial
	var roads := PackedVector4Array()
	for i: int in 10:
		roads.append(Vector4(i, -i, i + 5, -i - 5))
	mat.set_shader_parameter(&"road_segs", roads)
	mat.set_shader_parameter(&"road_count", roads.size())
	var back: Variant = mat.get_shader_parameter(&"road_segs")
	_check(back is PackedVector4Array and (back as PackedVector4Array).size() == 10, "road_segs did not stick")
	# The map dressing reads them and keeps decor off the road.
	var dressing_script: Script = load("res://art/environment/map_dressing_art.gd")
	var d: Node3D = dressing_script.new() as Node3D
	d.set(&"decor_enabled", false)
	d.call(&"_read_roads", mat)
	_check(bool(d.call(&"_blocked", 7.5, -7.5, 0.0)), "decor allowed on a road")
	_check(not bool(d.call(&"_blocked", 20.0, 20.0, 0.0)), "decor blocked far from roads")
	d.free()


func _check_waystones() -> void:
	var mesh := load(WAYSTONE_PATH) as ArrayMesh
	_check(mesh != null, "waystone.res missing")
	if mesh:
		_check(mesh.get_surface_count() == 1, "waystone must be one surface")
		var box: AABB = mesh.get_aabb()
		_check(box.end.y > 0.9 and box.end.y < 1.2, "waystone height %.2f" % box.end.y)
		_check(mesh.surface_get_material(0) != null and mesh.surface_get_material(0).resource_path.ends_with("env_painted_mat.tres"),
			"waystone must use env_painted_mat.tres")
		var tris: int = mesh.surface_get_array_index_len(0) / 3
		_check(tris < 400, "waystone has %d triangles" % tris)
	var row: Script = load(ROW_PATH)
	var roads := PackedVector4Array([Vector4(0, 0, 50, 0), Vector4(50, 0, 50, 3)])
	var xfs: Array = row.call(&"transforms", roads, 10.0, 2.2, 5.0)
	_check(xfs.size() == 5, "a 50 m road should get 5 stones (40 m usable, every 10 m), got %d" % xfs.size())
	for xf: Transform3D in xfs:
		var p: Vector3 = xf.origin
		_check(absf(absf(p.z) - 2.2) < 0.01, "stone not 2.2 m from the road: %s" % p)
		_check(p.x >= 4.99 and p.x <= 45.01, "stone within 5 m of a road end: %s" % p)
	var cleared: Array = row.call(&"transforms", roads, 10.0, 2.2, 5.0, PackedVector3Array([Vector3(25, 0, 0)]),
		PackedFloat32Array([6.0]))
	_check(cleared.size() == 4, "clear point should remove the middle stone (got %d)" % cleared.size())
	var mmi: MultiMeshInstance3D = row.call(&"build", roads, 10.0, 2.2, 5.0)
	_check(mmi != null and mmi.multimesh.instance_count == 5 and mmi.name == &"Waystones", "WaystoneRow.build failed")
	if mmi:
		mmi.free()


func _exercise() -> void:
	for t: Node3D in _posts:
		t.call(&"set_open", false)
		t.call(&"set_selected", true)
		t.call(&"play_trade")
		t.call(&"set_team_color", Color.RED)
		t.call(&"set_held", Color(0.85, 0.30, 0.12))
	_posts[2].set(&"sign_index", -4)
	_check(int(_posts[2].call(&"get_sign")) == 0, "sign_index must clamp to 0..3")
	_posts[3].call(&"set_held", null)


func _check_after_anim() -> void:
	for i: int in _posts.size():
		var t: Node3D = _posts[i]
		var body := t.get_node(^"Body") as Node3D
		_check(not bool(t.call(&"is_open")), "set_open(false) not kept")
		var sh := body.get_node(^"ShutterPivot") as Node3D
		_check(absf(sh.rotation.x) < 0.01, "post %d shutter not closed (%.2f)" % [i, sh.rotation.x])
		var fl := body.get_node(^"Flames") as GPUParticles3D
		_check(not fl.emitting, "post %d brazier still burning when closed" % i)
		var pen := body.get_node(^"SignHead/Pennant") as GeometryInstance3D
		if i == 3:
			_check(not pen.visible, "set_held(null) must lower the pennant")
		else:
			_check(pen.visible and absf(pen.scale.x - 1.0) < 0.02, "post %d pennant not raised" % i)
	_check(int(_posts[2].call(&"get_sign")) == 0, "sign kept")
	var s0 := _posts[2].get_node(^"Body/SignHead/SignPivot/Sign0") as Node3D
	_check(s0.visible, "sign_index 0 not shown")
	for t2: Node3D in _posts:
		t2.call(&"set_open", true)
	_check(_count_lights(root) == 0, "lights appeared")
