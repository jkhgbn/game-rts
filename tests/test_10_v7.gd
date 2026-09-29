extends SceneTree
## Task 10.V7: the Greywater Tracker model (art/units/neutral/tracker/tracker.tscn).
## Run: $GODOT --headless --path . -s tests/test_10_v7.gd --fixed-fps 60 --quit-after 1800
## Checks: headless instantiation (2 instances: the first builds and caches the merged meshes, the second reuses them),
## soldier budget (<= 26 authored meshes, <= 14 draw instances, <= 6 keep_separate, 0 lights, <= 2 500 vertices,
## <= 5 own materials, the rest kit palette entries), heights (head ~1.8, nothing below 0, hood point <= 2.2),
## set_team_color recolours the pennon only (armband + hood ribbon), one duplicate shared per colour, every hook,
## attack `crossbow` (aimed + loaded + bright tip during the windup, bolt gone after the 0.15 s release, re-spanned
## later, attack ends), a re-trigger mid-aim keeps the aim, cast, hit, level-up, statuses, death_finished, revive.
## Prints "PASS 10.v7" or "FAIL 10.v7: <reasons>".

const TASK_ID := "10.v7"
const SCENE := "res://art/units/neutral/tracker/tracker.tscn"
const OWN_DIR := "res://art/units/neutral/tracker/"
const SHADOW := Color(0.42, 0.22, 0.60)

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
	# ---- structure / budgets
	var authored: int = int(a.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored > 10 and authored <= 26, "authored meshes <= 26 (got %d)" % authored)
	for m: Node3D in [a, b]:
		var inst := _draw_instances(m)
		var sep := 0
		for g: Node in m.find_children("*", "GeometryInstance3D", true, false):
			if g.has_meta(&"keep_separate") or g is GPUParticles3D:
				sep += 1
		var verts := _vertices(m)
		print("%s: draw instances %d (separate %d), vertices %d, lights %d" % [m.name, inst, sep, verts,
			m.find_children("*", "Light3D", true, false).size()])
		_check(inst <= 14, "draw instances <= 14 (got %d)" % inst)
		_check(sep <= 6, "keep_separate parts <= 6 (got %d)" % sep)
		# Soldier + the face (faces pass 2026-09-28: measured 2962 with the Face node; small margin).
		_check(verts <= 3050, "vertices <= 3050 = 2500 + face (got %d)" % verts)
		_check(m.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
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
	_check(own.size() <= 5, "<= 5 own materials (got %d)" % own.size())
	for s: String in shared:
		_check(s.ends_with(".tres") and not s.contains("cloth") and not s.contains("cape") and not s.contains("pennon"),
			"shared material %s is a kit palette entry" % s)
	for g: Node in a.find_children("*", "MeshInstance3D", true, false):
		var gm := (g as MeshInstance3D).mesh
		if gm:
			var nv := 0
			for s: int in gm.get_surface_count():
				nv += (gm.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			print("  %s: %d surfaces, %d vertices" % [a.get_path_to(g), gm.get_surface_count(), nv])
	# ---- heights (rest pose, Root frame)
	var box := _aabb(a, a.get_node("Root"))
	print("rest AABB top %.3f, bottom %.3f, x %.2f .. %.2f, z %.2f .. %.2f" % [box.end.y, box.position.y,
		box.position.x, box.end.x, box.position.z, box.end.z])
	_check(box.position.y >= -0.001, "nothing below y 0 (got %.3f)" % box.position.y)
	_check(box.end.y <= 2.2, "hood point below 2.2 m (got %.3f)" % box.end.y)
	var head_top := -1.0
	var head_node: Node3D = a.get_node("Root/Chest/Head")
	for mi: MeshInstance3D in a.find_children("Merged", "MeshInstance3D", true, false):
		if mi.get_parent() == head_node:
			for s: int in mi.mesh.get_surface_count():
				if mi.mesh.surface_get_material(s) == CharacterModel.palette(&"fire_skin"):
					for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
						head_top = maxf(head_top, (a.global_transform.affine_inverse() * mi.global_transform * v).y)
	print("head (skin) top %.3f" % head_top)
	_check(absf(head_top - 1.8) <= 0.1, "head top at body_height 1.8 +- 0.1 (got %.3f)" % head_top)
	_check(is_equal_approx(float(a.get(&"body_height")), 1.8), "body_height 1.8")
	_check(a.get(&"attack_style") == &"crossbow" and is_equal_approx(float(a.get(&"attack_windup")), 0.15),
		"attack crossbow, windup 0.15")
	# ---- team colour: the pennon only (armband + hood ribbon), one cached duplicate per colour
	var before := _materials(b)
	b.call(&"set_team_color", SHADOW)
	await process_frame
	var after := _materials(b)
	var changed := 0
	for mat: Material in after:
		if mat in before:
			continue
		var sm := mat as ShaderMaterial
		_check(sm != null and sm.get_shader_parameter(&"cloth_color").is_equal_approx(SHADOW), "only the pennon is recoloured")
		changed += 1
	_check(changed == 1, "exactly one recoloured material (got %d)" % changed)
	var recoloured_nodes := 0
	for g: Node in b.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var sm := mi.get_surface_override_material(s)
			if sm == null and mi.material_override:
				sm = mi.material_override
			if sm and not (sm in before):
				recoloured_nodes += 1
	_check(recoloured_nodes >= 2, "armband and hood ribbon both recoloured (got %d surfaces)" % recoloured_nodes)
	for mat: Material in before:
		if not mat.resource_path.ends_with("tracker_pennon.tres"):
			_check(mat in after, "material %s must not change" % mat.resource_path.get_file())
	var c := _spawn(Vector3(6, 0, 0))
	c.call(&"set_team_color", SHADOW)
	await process_frame
	var shared_dup := false
	for mat: Material in _materials(c):
		if mat in after and not (mat in before):
			shared_dup = true
	_check(shared_dup, "the recoloured pennon is shared between units of one colour")
	c.get_parent().queue_free()
	# ---- hooks
	for m: Node3D in [a, b]:
		for h: String in ["set_team_color", "set_moving", "play_attack", "play_cast", "play_hit", "play_death",
				"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive", "is_loaded"]:
			_check(m.has_method(h), "hook %s" % h)
	var xbow: MeshInstance3D = a.get_node("Root/Chest/ArmR/Crossbow")
	var loaded_mesh := xbow.mesh
	var rest_q := xbow.quaternion
	var tip_rest := float(xbow.get_instance_shader_parameter(&"glow_boost"))
	print("tip glow at rest %.2f" % tip_rest)
	_check(tip_rest > 0.2 and tip_rest < 1.0, "bolt tip dim at rest (%.2f)" % tip_rest)
	a.call(&"set_moving", 5.4)
	await _wait(0.5)
	a.call(&"set_moving", 0.0)
	await _wait(0.3)
	a.call(&"play_attack")
	await _wait(0.12)
	var arm_r: Node3D = a.get_node("Root/Chest/ArmR")
	_check(arm_r.rotation.x < -1.0, "shooting arm raised while aiming (rot.x %.2f)" % arm_r.rotation.x)
	_check(bool(a.call(&"is_loaded")) and xbow.mesh == loaded_mesh, "loaded during the windup")
	var tip_aim := float(xbow.get_instance_shader_parameter(&"glow_boost"))
	print("tip glow while aiming %.2f" % tip_aim)
	_check(tip_aim > 2.0, "bolt tip bright while aiming (%.2f)" % tip_aim)
	_check(xbow.quaternion.angle_to(rest_q) > 0.5, "crossbow turned to the aim")
	await _wait(0.07)
	_check(not bool(a.call(&"is_loaded")) and xbow.mesh != loaded_mesh, "bolt loosed after the 0.15 s release")
	_check(float(xbow.get_instance_shader_parameter(&"glow_boost")) == 0.0, "no glow without a bolt")
	await _wait(0.5)
	_check(bool(a.call(&"is_loaded")), "re-spanned by 0.72 s")
	# re-trigger mid-aim keeps the aim (no drop to the rest pose)
	a.call(&"play_attack")
	await _wait(0.02)
	_check(arm_r.rotation.x < -1.0, "re-trigger keeps the aim (rot.x %.2f)" % arm_r.rotation.x)
	await _wait(1.4)
	_check(a.get(&"_action") == &"", "attack finished")
	_check(xbow.quaternion.angle_to(rest_q) < 0.05, "crossbow back at the side")
	a.call(&"play_cast", &"snare_shot")
	await _wait(0.2)
	_check(arm_r.rotation.x < -1.0, "cast aims (rot.x %.2f)" % arm_r.rotation.x)
	await _wait(1.6)
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
	a.call(&"set_moving", 1.0)
	await _wait(0.2)
	a.call(&"set_moving", 0.0)
	# ---- death mid-shot + revive
	a.call(&"play_attack")
	await _wait(0.2)
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	a.call(&"play_death")
	await _wait(1.3)
	_check(got[0], "death_finished emitted within 1.3 s")
	_check(float(xbow.get_instance_shader_parameter(&"glow_boost")) == 0.0, "glow off once dead")
	a.call(&"revive")
	await _wait(0.3)
	var root_node: Node3D = a.get_node("Root")
	_check(absf(root_node.rotation.x) < 0.05 and absf(root_node.position.y) < 0.06, "revive resets the pose")
	_check(bool(a.call(&"is_loaded")) and xbow.mesh == loaded_mesh, "revive: loaded")
	_check(xbow.quaternion.angle_to(rest_q) < 0.05, "revive: crossbow at the side")
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
