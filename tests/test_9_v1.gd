extends SceneTree
## Task 9.V1: the Wayfinder champion model (art/units/champions/wayfinder/wayfinder.tscn), variants A / B.
## Run: $GODOT --headless --path . -s tests/test_9_v1.gd --fixed-fps 60 --quit-after 1800
## Checks: headless instantiation (2 instances: the first builds and caches the merged meshes, the second reuses them),
## budgets (<= 26 authored meshes, <= 16 draw instances, 0 lights, <= 5 own materials), heights (lantern pole top 2.6,
## head top ~1.8), set_team_color on sash + pennant only (cached per colour), variant = one toggled node, every hook
## callable (attack `bow` with the drawn string until the 0.15 s release, 3 casts + an unknown id, hit, level-up,
## statuses, death_finished, revive), looping particles stop beyond 45 m.
## Prints "PASS 9.v1" or "FAIL 9.v1: <reasons>".

const TASK_ID := "9.v1"
const SCENE := "res://art/units/champions/wayfinder/wayfinder.tscn"
const OWN_DIR := "res://art/units/champions/wayfinder/"
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


func _spawn(at: Vector3, variant: int) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	m.call(&"set_variant", variant)       # before _ready: cached and applied
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0), 0)
	var b := _spawn(Vector3(3, 0, 0), 1)
	await _wait(0.2)
	# ---- structure / budgets
	var authored: int = int(a.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored > 10 and authored <= 26, "authored meshes <= 26 (got %d)" % authored)
	for m: Node3D in [a, b]:
		var inst := _draw_instances(m)
		print("%s variant %d: draw instances %d, vertices %d, lights %d" % [m.name, int(m.get(&"variant")), inst,
			_vertices(m), m.find_children("*", "Light3D", true, false).size()])
		_check(inst <= 16, "draw instances <= 16 (got %d)" % inst)
		_check(m.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
		_check(m.find_children("Variant", "MeshInstance3D", true, false).size() == 1, "one Variant node")
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
		_check(s.ends_with(".tres") and not s.contains("cloth") and not s.contains("cape"), "shared material %s is a kit palette entry" % s)
	var disk := DirAccess.get_files_at(OWN_DIR + "materials")
	var tres := 0
	for f: String in disk:
		if f.ends_with(".tres"):
			tres += 1
	_check(tres <= 5, "<= 5 material files in the folder (got %d)" % tres)
	for g: Node in a.find_children("*", "MeshInstance3D", true, false):
		var gm := (g as MeshInstance3D).mesh
		if gm:
			var nv := 0
			for s: int in gm.get_surface_count():
				nv += (gm.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			print("  %s: %d surfaces, %d vertices" % [a.get_path_to(g), gm.get_surface_count(), nv])
	# ---- heights (rest pose, in the Root frame: the kit's idle breath bobs Root by +-0.02)
	var box := _aabb(a, a.get_node("Root"))
	print("rest AABB top %.3f, bottom %.3f, half-width x %.2f .. %.2f, z %.2f .. %.2f" % [box.end.y, box.position.y,
		box.position.x, box.end.x, box.position.z, box.end.z])
	_check(absf(box.end.y - 2.6) <= 0.06, "lantern pole top at 2.6 m (got %.3f)" % box.end.y)
	_check(box.position.y >= -0.001, "nothing below y 0 (got %.3f)" % box.position.y)
	var face: Array = a.find_children("Merged", "MeshInstance3D", true, false)
	var head_node: Node3D = a.get_node("Root/Chest/Head")
	var head_top := -1.0
	for mi: MeshInstance3D in face:
		if mi.get_parent() == head_node:
			# the skin is a ChampionPalette entry since the B8 merge (2026-09-30): read it back per vertex
			for v: Vector3 in ChampionPalette.vertices_of(mi.mesh, "fire_skin"):
				head_top = maxf(head_top, (a.global_transform.affine_inverse() * mi.global_transform * v).y)
	print("head (skin) top %.3f" % head_top)
	_check(absf(head_top - 1.8) <= 0.1, "head top at body_height 1.8 +- 0.1 (got %.3f)" % head_top)
	_check(is_equal_approx(float(a.get(&"body_height")), 1.8), "body_height 1.8")
	_check(a.get(&"attack_style") == &"bow" and is_equal_approx(float(a.get(&"attack_windup")), 0.15), "attack bow, windup 0.15")
	# ---- variant: one node, mesh swapped, toggles both ways
	var va: MeshInstance3D = a.get_node("Root/Chest/Head/Variant")
	var vb: MeshInstance3D = b.get_node("Root/Chest/Head/Variant")
	_check(va.mesh != vb.mesh, "variant A and B pieces differ")
	var mesh_a := va.mesh
	a.call(&"set_variant", 1)
	_check(va.mesh == vb.mesh and int(a.get(&"variant")) == 1, "set_variant(1) swaps the piece")
	a.call(&"set_variant", 0)
	_check(va.mesh == mesh_a, "set_variant(0) swaps it back")
	# ---- team colour: sash + pennant only, one cached duplicate per colour
	var before := _materials(b)
	b.call(&"set_team_color", SHADOW)
	await process_frame
	var after := _materials(b)
	var pennons := 0
	for mat: Material in after:
		if mat in before:
			continue
		var sm := mat as ShaderMaterial
		_check(sm != null and sm.get_shader_parameter(&"cloth_color").is_equal_approx(SHADOW), "only the pennon is recoloured")
		pennons += 1
	_check(pennons == 1, "exactly one recoloured material (got %d)" % pennons)
	for mat: Material in before:
		if mat.resource_path.ends_with("wayfinder_pennon.tres"):
			_check(not (mat in after), "the default pennon is replaced on b")
		elif not (mat in after):
			_check(false, "material %s must not change" % mat.resource_path.get_file())
	var c := _spawn(Vector3(6, 0, 0), 0)
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
				"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive", "set_variant"]:
			_check(m.has_method(h), "hook %s" % h)
	var bow: MeshInstance3D = a.get_node("Root/Chest/ArmR/Bow")
	var rest_mesh := bow.mesh
	a.call(&"set_moving", 5.8)
	await _wait(0.5)
	a.call(&"set_moving", 0.0)
	a.call(&"play_attack")
	await _wait(0.1)
	_check(bow.mesh != rest_mesh, "bow drawn during the windup")
	var arm_r: Node3D = a.get_node("Root/Chest/ArmR")
	_check(arm_r.rotation.x < -0.8, "bow arm raised while drawing (rot.x %.2f)" % arm_r.rotation.x)
	await _wait(0.15)
	_check(bow.mesh == rest_mesh, "string loosed after the 0.15 s release")
	await _wait(0.5)
	for id: StringName in [&"flare_arrow", &"snare_line", &"trailblaze", &"no_such_ability"]:
		a.call(&"play_cast", id)
		await _wait(0.25)
		_check(arm_r.rotation.x < -1.2, "cast %s raises the bow high (rot.x %.2f)" % [id, arm_r.rotation.x])
		await _wait(1.0)
		_check(a.get(&"_action") == &"", "cast %s finished" % id)
	var mot: GPUParticles3D = a.get_node("Root/Chest/Lantern/LanternMotes")
	a.call(&"play_hit")
	a.call(&"play_level_up")
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	_check(not bool(a.call(&"set_status", &"burn", true)), "set_status burn left to the placeholder")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_veterancy", 2)
	await _wait(0.5)
	# ---- distance tiers: looping particles only < 45 m
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 40, 45)
	cam.make_current()
	await _wait(1.1)
	_check(not mot.emitting, "lantern motes stop beyond 45 m")
	cam.position = Vector3(0, 10, 10)
	await _wait(1.1)
	_check(mot.emitting, "lantern motes run near the camera")
	cam.queue_free()
	# ---- death + revive
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	a.call(&"play_death")
	await _wait(1.3)
	_check(got[0], "death_finished emitted within 1.3 s")
	a.call(&"revive")
	await _wait(0.3)
	var root_node: Node3D = a.get_node("Root")
	_check(absf(root_node.rotation.x) < 0.05 and absf(root_node.position.y) < 0.06, "revive resets the pose")
	_check(bow.mesh == rest_mesh, "revive: bow at rest")
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
## The ChampionPalette material (B8 merge, 2026-09-30) is unfolded into the source materials it draws.
func _materials(n: Node) -> Array:
	return ChampionPalette.unfold(_drawn_materials(n))


func _drawn_materials(n: Node) -> Array:
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
