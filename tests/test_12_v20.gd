extends SceneTree
## Task 12.V20: the Bristleback camp creature model (art/units/neutral/bristleback/bristleback.tscn).
## Run: $GODOT --headless --path . -s tests/test_12_v20.gd --fixed-fps 60 --quit-after 1800
## Checks: headless instantiation (2 instances: the first builds and caches the meshes, the second reuses them),
## soldier budget of map-fill.md 10 (<= 18 authored meshes, <= 10 draw instances incl. emitters, 0 lights, <= 2 500
## vertices), materials (own <= 5 in the folder + kit palette entries, no cloth / cape / pennon: no team colour),
## size (top of the quills ~1.1 m, nothing below 0, length ~1.9 m, stays smaller than 1.3 m), set_team_color is a
## no-op, the kit hooks, attack `tusk_gore` (nose down in the windup, head tossed up + lunge at the 0.12 s strike, one
## strike per attack, quills raised, ends), the dig fidget, a cast (rears), hit, level-up, statuses, walk (legs swing),
## death_finished within 1.3 s, revive resets the pose. Prints "PASS 12.v20" or "FAIL 12.v20: <reasons>".

const TASK_ID := "12.v20"
const SCENE := "res://art/units/neutral/bristleback/bristleback.tscn"
const OWN_DIR := "res://art/units/neutral/bristleback/"

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	var n := int(ceil(sec * 60.0))
	for i: int in n:
		await process_frame


func _spawn(at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(3, 0, 0))
	await _wait(0.2)
	_check(a is CharacterModel, "extends CharacterModel")
	# ---- structure / budgets
	var authored: int = int(a.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored >= 6 and authored <= 18, "authored meshes <= 18 (got %d)" % authored)
	for m: Node3D in [a, b]:
		var inst := _draw_instances(m)
		var verts := _vertices(m)
		var lights := m.find_children("*", "Light3D", true, false).size()
		print("%s: draw instances %d, vertices %d, lights %d" % [m.name, inst, verts, lights])
		_check(inst <= 10, "draw instances <= 10 (got %d)" % inst)
		# 2500 + the face (faces pass 2026-09-28: measured 2550 with the Face node; small margin).
		_check(verts <= 2650, "vertices <= 2650 = 2500 + face (got %d)" % verts)
		_check(lights == 0, "0 lights")
	var mats := _materials(a)
	var own: Array = []
	var shared: Array = []
	for mat: Material in mats:
		if mat.resource_path.begins_with(OWN_DIR):
			own.append(mat.resource_path.get_file())
		else:
			shared.append(mat.resource_path.get_file() if mat.resource_path != "" else "<built-in>")
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	print("shared kit materials (%d): %s" % [shared.size(), ", ".join(PackedStringArray(shared))])
	_check(own.size() >= 3 and own.size() <= 5, "3-5 own materials (got %d)" % own.size())
	for s: String in shared:
		_check(s.ends_with(".tres") and not s.contains("cloth") and not s.contains("cape") and not s.contains("pennon"),
			"shared material %s is a kit palette entry" % s)
	for g: Node in a.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		var nv := 0
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var gm := (gi as MeshInstance3D).mesh
			for s: int in gm.get_surface_count():
				nv += (gm.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("  %s (%s): %d vertices" % [a.get_path_to(g), g.get_class(), nv])
	# ---- size (rest pose, Root frame)
	var box := _aabb(a, a.get_node("Root"))
	print("rest AABB top %.3f, bottom %.3f, x %.2f .. %.2f, z %.2f .. %.2f" % [box.end.y, box.position.y,
		box.position.x, box.end.x, box.position.z, box.end.z])
	_check(box.position.y >= -0.005, "nothing below y 0 (got %.3f)" % box.position.y)
	_check(box.end.y >= 1.0 and box.end.y <= 1.28, "top of the quills 1.0-1.28 m (got %.3f)" % box.end.y)
	_check(box.size.z >= 1.6 and box.size.z <= 2.2, "length ~1.9 m (got %.2f)" % box.size.z)
	_check(box.size.x <= 1.0, "width <= 1.0 m (got %.2f)" % box.size.x)
	_check(is_equal_approx(float(a.get(&"body_height")), 1.1), "body_height 1.1")
	_check(a.get(&"attack_style") == &"tusk_gore" and float(a.get(&"attack_windup")) == 0.0, "attack tusk_gore, melee")
	_check(bool(a.get(&"is_quadruped")), "quadruped")
	# ---- team colour: none (neutral)
	var before := _materials(b)
	b.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	await process_frame
	var after := _materials(b)
	_check(before.size() == after.size(), "set_team_color keeps the materials")
	for mat: Material in after:
		_check(mat in before, "set_team_color must not recolour %s" % mat.resource_path.get_file())
	# ---- hooks
	for m: Node3D in [a, b]:
		for h: String in ["set_team_color", "set_moving", "play_attack", "play_cast", "play_hit", "play_death",
				"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive", "play_dig"]:
			_check(m.has_method(h), "hook %s" % h)
	var head: Node3D = a.get_node("Root/Mount/Head")
	var root_n: Node3D = a.get_node("Root")
	var leg: Node3D = a.get_node("Root/Mount/LegFL")
	var quills: Node3D = a.get_node("Root/Mount/Quills")
	var quill_rest_y := quills.scale.y
	# walk: the legs swing
	a.call(&"set_moving", 4.6)
	var max_leg := 0.0
	for i: int in 30:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
	a.call(&"set_moving", 0.0)
	print("walk: max fore-leg swing %.1f deg" % rad_to_deg(max_leg))
	_check(max_leg > deg_to_rad(15.0), "the legs swing in the trot (%.1f deg)" % rad_to_deg(max_leg))
	await _wait(0.4)
	# attack: nose down in the windup, tossed up at the strike with the lunge
	var strikes0: int = int(a.call(&"strike_count"))
	a.call(&"play_attack")
	await _wait(0.07)
	var hx_wind := head.rotation.x
	await _wait(0.07)
	var hx_hit := head.rotation.x
	var rz_hit := root_n.position.z
	var qr := float(a.call(&"quill_raise"))
	print("gore: head x windup %.1f, strike %.1f deg, lunge z %.2f, quills %.2f (scale y %.2f)" % [rad_to_deg(hx_wind),
		rad_to_deg(hx_hit), rz_hit, qr, quills.scale.y])
	_check(hx_wind > deg_to_rad(15.0), "nose down in the windup (%.1f)" % rad_to_deg(hx_wind))
	_check(hx_hit < deg_to_rad(-15.0), "head tossed up at the strike (%.1f)" % rad_to_deg(hx_hit))
	_check(rz_hit > 0.15, "lunge forward at the strike (%.2f)" % rz_hit)
	_check(qr > 0.5 and quills.scale.y > quill_rest_y + 0.1, "quills raised in the fight")
	_check(int(a.call(&"strike_count")) == strikes0 + 1, "one strike per attack")
	await _wait(0.6)
	_check(a.get(&"_action") == &"", "attack finished")
	# dig fidget
	a.call(&"play_dig")
	await _wait(0.3)
	print("dig: head x %.1f deg" % rad_to_deg(head.rotation.x))
	_check(a.get(&"_action") == &"dig" and head.rotation.x > deg_to_rad(20.0), "dig: snout down")
	a.call(&"set_moving", 3.0)
	await _wait(0.1)
	_check(a.get(&"_action") == &"", "moving cancels the dig")
	a.call(&"set_moving", 0.0)
	await _wait(0.3)
	# cast (no ability in the spec: any id rears)
	a.call(&"play_cast", &"bristle_rage")
	await _wait(0.22)
	print("cast: root pitch %.1f deg, root y %.2f" % [rad_to_deg(root_n.rotation.x), root_n.position.y])
	_check(root_n.rotation.x < deg_to_rad(-8.0), "cast rears up")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "cast finished")
	a.call(&"play_hit")
	a.call(&"play_level_up")
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	_check(not bool(a.call(&"set_status", &"rooted", true)), "set_status rooted left to the placeholder")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_veterancy", 2)
	a.call(&"set_carrying", true)
	a.call(&"play_mine")
	await _wait(0.5)
	a.call(&"set_carrying", false)
	# ---- death mid-attack + revive
	a.call(&"play_attack")
	await _wait(0.1)
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	a.call(&"play_death")
	await _wait(0.6)
	print("death 0.6 s: root roll %.1f deg" % rad_to_deg(root_n.rotation.z))
	_check(absf(root_n.rotation.z) > deg_to_rad(50.0), "topples onto its side")
	await _wait(0.7)
	_check(got[0], "death_finished emitted within 1.3 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.rotation.x) < 0.05 and absf(root_n.rotation.z) < 0.05 and absf(root_n.position.y) < 0.06,
		"revive resets the pose")
	_check(absf(quills.scale.y - quill_rest_y) < 0.1, "revive: quills at rest")
	# ---- transparency (Unit.leave_map fade / shroud) is tolerated on every part
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


func _vertices(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (g as MeshInstance3D).mesh
		if mesh:
			for s: int in mesh.get_surface_count():
				c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


## Unique materials on the model's meshes (surface overrides > material_override > mesh surfaces); the blob skipped.
func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if mi.material_override:
			if not (mi.material_override in out):
				out.append(mi.material_override)
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out


func _aabb(n: Node, model: Node3D) -> AABB:
	var inv := model.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var bx := (inv * mi.global_transform) * mi.mesh.get_aabb()
		box = bx if first else box.merge(bx)
		first = false
	return box
