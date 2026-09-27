extends SceneTree
## Task 12.V23: the Hollow Stag camp creature model (art/units/neutral/hollow_stag/hollow_stag.tscn).
## Run: $GODOT --headless --path . -s tests/test_12_v23.gd --fixed-fps 60 --quit-after 2400
## Checks: headless instantiation (2 instances: the first builds and caches the meshes, the second reuses them), hero
## budget of map-fill.md 10 (<= 26 authored meshes, <= 16 draw instances, 0 lights; keep_separate <= 6, vertices
## <= 4 000), materials (own painted + exactly 2 green unit_glow materials = the 2 glow points, energy >= 2.5; no
## cloth / cape: no team colour), the pale coat, size (huge: antlers ~3.7 m, span >= 2.2 m, head ~2.6 m; nothing
## below 0) and clearly bigger / wider / paler than the huntable red deer (critters/deer.tscn), set_team_color is a
## no-op, the kit hooks, walk (legs swing, shins fold), attack `antler_gore` (head down in the windup, lunge at the
## 0.12 s strike, one strike per attack, ends), cast `antler_sweep` (turns right then sweeps left, leaf burst, glow
## flare, ends), the fidget, hit, the heart beats, death (topples, glows off, body not through the ground,
## death_finished within 1.3 s), revive resets. Prints "PASS 12.v23" or "FAIL 12.v23: <reasons>".

const TASK_ID := "12.v23"
const SCENE := "res://art/units/neutral/hollow_stag/hollow_stag.tscn"
const DEER := "res://art/units/neutral/critters/deer.tscn"
const OWN_DIR := "res://art/units/neutral/hollow_stag/"

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


func _spawn(path: String, at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(path) as PackedScene).instantiate()
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(SCENE, Vector3(0, 0, 0))
	var b := _spawn(SCENE, Vector3(6, 0, 0))
	await _wait(0.2)
	_check(a is CharacterModel, "extends CharacterModel")
	a.set(&"fidget_every", 0.0)
	b.set(&"fidget_every", 0.0)
	# ---- structure / budgets
	var authored: int = int(a.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored >= 8 and authored <= 26, "authored meshes <= 26 (got %d)" % authored)
	for m: Node3D in [a, b]:
		var inst := _draw_instances(m)
		var verts := _vertices(m)
		var tris := _triangles(m)
		var lights := m.find_children("*", "Light3D", true, false).size()
		var sep := 0
		for g: Node in m.find_children("*", "MeshInstance3D", true, false):
			if g.has_meta(&"keep_separate"):
				sep += 1
		print("%s: draw instances %d, vertices %d, triangles %d, keep_separate %d, lights %d" % [m.name, inst, verts,
			tris, sep, lights])
		_check(inst <= 16, "draw instances <= 16 (got %d)" % inst)
		_check(verts <= 4500, "vertices <= 4500 (got %d)" % verts)
		_check(sep <= 6, "keep_separate <= 6 (got %d)" % sep)
		_check(lights == 0, "0 lights")
	for n: String in ["Root/Mount/Head/Crown/Skull", "Root/Mount/LegFL/Lower/Shin", "Root/Mount/LegBR/Lower/Shin",
			"Root/Mount/Head/Crown/Leaves", "Fx/Shed"]:
		_check(a.get_node_or_null(n) != null and b.get_node_or_null(n) != null, "part %s on every instance" % n)
	var mats := _materials(a)
	var own: Array = []
	var shared: Array = []
	var glows: Array = []
	for mat: Material in mats:
		if mat.resource_path.begins_with(OWN_DIR):
			own.append(mat.resource_path.get_file())
		else:
			shared.append(mat.resource_path.get_file() if mat.resource_path != "" else "<built-in>")
		var sm := mat as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path.ends_with("unit_glow.gdshader"):
			glows.append(sm)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	print("shared materials (%d): %s" % [shared.size(), ", ".join(PackedStringArray(shared))])
	_check(own.size() >= 5 and own.size() <= 8, "5-8 own materials (got %d)" % own.size())
	_check(shared.is_empty(), "no shared / built-in materials on the meshes")
	_check(glows.size() == 2, "exactly 2 glow materials = the 2 glow points (got %d)" % glows.size())
	for gm: ShaderMaterial in glows:
		var gc: Color = gm.get_shader_parameter(&"glow_color")
		var en: float = float(gm.get_shader_parameter(&"energy"))
		print("glow %s colour %s energy %.2f" % [gm.resource_path.get_file(), gc, en])
		_check(en >= 2.5 and gc.g > 0.9 and gc.g > gc.r + 0.2 and gc.g > gc.b + 0.3, "green glow, energy >= 2.5 (%s)"
			% gm.resource_path.get_file())
	var hide: ShaderMaterial = load(OWN_DIR + "materials/hollow_stag_hide.tres")
	var hc: Color = hide.get_shader_parameter(&"base_color")
	print("hide colour %s (v %.2f, s %.2f)" % [hc, hc.v, hc.s])
	_check(hc.v > 0.7 and hc.s < 0.2, "pale coat (value > 0.7, saturation < 0.2)")
	for g: Node in a.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		var nv := 0
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var gm := (gi as MeshInstance3D).mesh
			for s: int in gm.get_surface_count():
				nv += (gm.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("  %s (%s): %d vertices, shadow %d" % [a.get_path_to(g), g.get_class(), nv, gi.cast_shadow])
	# ---- size (rest pose, Root frame) and the deer comparison
	var box := _aabb(a, a.get_node("Root"))
	print("rest AABB top %.3f, bottom %.3f, x %.2f .. %.2f, z %.2f .. %.2f" % [box.end.y, box.position.y,
		box.position.x, box.end.x, box.position.z, box.end.z])
	_check(box.position.y >= -0.005, "nothing below y 0 (got %.3f)" % box.position.y)
	_check(box.end.y >= 3.2 and box.end.y <= 4.0, "antler tips 3.2-4.0 m (got %.2f)" % box.end.y)
	_check(box.size.x >= 2.2 and box.size.x <= 3.4, "antler span 2.2-3.4 m (got %.2f)" % box.size.x)
	_check(box.size.z >= 2.7 and box.size.z <= 3.6, "length ~3.1 m (got %.2f)" % box.size.z)
	var skull_box := _aabb_of(a.get_node("Root/Mount/Head/Crown/Skull") as MeshInstance3D, a.get_node("Root"), true)
	print("body (no antlers) top %.2f" % skull_box)
	_check(skull_box >= 2.45 and skull_box <= 2.8, "head top ~2.6 m = spec height 2.6 (got %.2f)" % skull_box)
	var deer: Node3D = null
	if ResourceLoader.exists(DEER):
		deer = _spawn(DEER, Vector3(-6, 0, 0))
		await _wait(0.1)
		var dbox := _aabb(deer, deer)
		print("deer AABB %s (w %.2f, h %.2f, l %.2f)" % [dbox, dbox.size.x, dbox.size.y, dbox.size.z])
		_check(box.size.y > dbox.size.y * 1.15, "taller than the deer")
		_check(box.size.x > dbox.size.x * 1.8, "far wider than the deer (antler spread)")
		_check(box.size.z > dbox.size.z * 1.2, "longer than the deer")
	_check(a.get(&"attack_style") == &"antler_gore" and float(a.get(&"attack_windup")) == 0.0, "attack antler_gore, melee")
	_check(bool(a.get(&"is_quadruped")), "quadruped")
	_check(absf(float(a.get(&"body_height")) - 2.6) < 0.01, "body_height 2.6 (spec height)")
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
				"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive", "play_fidget"]:
			_check(m.has_method(h), "hook %s" % h)
		_check(m.has_signal(&"death_finished"), "signal death_finished")
	var root_n: Node3D = a.get_node("Root")
	var head: Node3D = a.get_node("Root/Mount/Head")
	var crown: Node3D = a.get_node("Root/Mount/Head/Crown")
	var leg: Node3D = a.get_node("Root/Mount/LegFL")
	var shin: Node3D = a.get_node("Root/Mount/LegFL/Lower")
	# heart beats
	var hmin := INF
	var hmax := -INF
	for i: int in 100:
		await process_frame
		hmin = minf(hmin, float(a.call(&"heart_glow")))
		hmax = maxf(hmax, float(a.call(&"heart_glow")))
	print("heart glow %.2f .. %.2f, leaves %.2f" % [hmin, hmax, float(a.call(&"leaf_glow"))])
	_check(hmin > 0.5 and hmax > hmin + 0.2, "the heart glows and beats")
	_check(float(a.call(&"leaf_glow")) > 0.8, "the leaves glow")
	# walk: legs swing, shins fold
	a.call(&"set_moving", 5.0)
	var max_leg := 0.0
	var max_fold := 0.0
	for i: int in 50:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		max_fold = maxf(max_fold, shin.rotation.x)
	a.call(&"set_moving", 0.0)
	print("walk: max fore-leg swing %.1f deg, shin fold %.1f deg" % [rad_to_deg(max_leg), rad_to_deg(max_fold)])
	_check(max_leg > deg_to_rad(15.0), "the legs swing in the trot (%.1f deg)" % rad_to_deg(max_leg))
	_check(max_fold > deg_to_rad(35.0), "the shins fold the hooves back (%.1f deg)" % rad_to_deg(max_fold))
	await _wait(0.5)
	# attack: head down in the windup, lunge at the strike
	var strikes0: int = int(a.call(&"strike_count"))
	a.call(&"play_attack")
	await _until_t(a, 0.065)
	var hx_wind := head.rotation.x
	var cx_wind := crown.rotation.x
	await _until_t(a, 0.125)
	var rz_hit := root_n.position.z
	await _until_t(a, 0.25)
	var hx_toss := head.rotation.x
	print("gore: neck windup %.1f, crown %.1f, lunge z %.2f, neck toss %.1f" % [rad_to_deg(hx_wind),
		rad_to_deg(cx_wind), rz_hit, rad_to_deg(hx_toss)])
	_check(hx_wind > deg_to_rad(15.0) and cx_wind > deg_to_rad(10.0), "antlers lowered in the windup")
	_check(rz_hit > 0.2, "lunge forward at the strike (%.2f)" % rz_hit)
	_check(hx_toss < deg_to_rad(-5.0), "head hooks up after the strike (%.1f)" % rad_to_deg(hx_toss))
	_check(int(a.call(&"strike_count")) == strikes0 + 1, "one strike per attack")
	await _wait(0.7)
	_check(a.get(&"_action") == &"", "attack finished")
	await _wait(0.3)
	# cast antler_sweep: turns right, sweeps left, sheds leaves, flares
	var sheds0: int = int(a.call(&"shed_count"))
	a.call(&"play_cast", &"antler_sweep")
	await _until_t(a, 0.4)
	var yaw_r := root_n.rotation.y
	var hy_r := head.rotation.y
	await _until_t(a, 0.6)
	var flare := float(a.call(&"glow_flare"))
	await _until_t(a, 0.72)
	var yaw_l := root_n.rotation.y
	var hy_l := head.rotation.y
	print("sweep: root yaw %.1f -> %.1f, neck yaw %.1f -> %.1f, flare %.2f, sheds %d -> %d" % [rad_to_deg(yaw_r),
		rad_to_deg(yaw_l), rad_to_deg(hy_r), rad_to_deg(hy_l), flare, sheds0, int(a.call(&"shed_count"))])
	_check(yaw_r < deg_to_rad(-15.0) and hy_r < deg_to_rad(-25.0), "sweep windup: turned right")
	_check(yaw_l > deg_to_rad(15.0) and hy_l > deg_to_rad(25.0), "sweep: across to the left")
	_check(flare > 0.7, "sweep: heart / leaves flare (%.2f)" % flare)
	_check(int(a.call(&"shed_count")) == sheds0 + 1 and int(a.call(&"sweep_count")) == 1, "sweep: one leaf burst")
	await _wait(0.9)
	_check(a.get(&"_action") == &"", "cast finished")
	await _wait(0.3)
	# fidget
	a.call(&"play_fidget")
	await _wait(0.5)
	_check(a.get(&"_action") == &"fidget", "fidget plays")
	a.call(&"set_moving", 3.0)
	await _wait(0.1)
	_check(a.get(&"_action") == &"", "moving cancels the fidget")
	a.call(&"set_moving", 0.0)
	await _wait(0.4)
	# hit
	a.call(&"play_hit")
	await _wait(0.1)
	print("hit: crown roll %.1f, neck %.1f" % [rad_to_deg(crown.rotation.z), rad_to_deg(head.rotation.x)])
	_check(crown.rotation.z > deg_to_rad(3.0), "hit: the antlers twist")
	a.call(&"play_level_up")
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	_check(not bool(a.call(&"set_status", &"rooted", true)), "set_status rooted left to the placeholder")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_veterancy", 2)
	a.call(&"set_carrying", true)
	a.call(&"play_mine")
	await _wait(0.5)
	a.call(&"set_carrying", false)
	a.call(&"set_veterancy", 0)
	await _wait(0.3)
	# ---- death mid-attack + revive
	a.call(&"play_attack")
	await _wait(0.1)
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	var sheds1: int = int(a.call(&"shed_count"))
	a.call(&"play_death")
	await _until_death(a, 0.76)
	var low_body := _lowest_vertex(a, ["Merged", "Shin"], ["Root/Mount/Head/Crown"])
	var low_all := _lowest_vertex(a, [], [])
	print("death 0.76 s: root roll %.1f deg, root y %.2f, heart %.2f, leaves %.2f, lowest body %.3f, lowest all %.3f"
		% [rad_to_deg(root_n.rotation.z), root_n.position.y, float(a.call(&"heart_glow")),
		float(a.call(&"leaf_glow")), low_body, low_all])
	_check(absf(root_n.rotation.z) > deg_to_rad(55.0), "topples onto its side")
	_check(float(a.call(&"heart_glow")) == 0.0 and float(a.call(&"leaf_glow")) == 0.0, "heart and leaves dark once dead")
	_check(int(a.call(&"shed_count")) > sheds1, "the leaves fall at death")
	_check(low_body > -0.12 and low_body < 0.25, "lying on the ground, not through it (lowest body %.3f)" % low_body)
	_check(low_all > -0.35, "antlers do not dig deep into the ground (%.3f)" % low_all)
	await _wait(0.6)
	_check(got[0], "death_finished emitted within 1.3 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.rotation.x) < 0.05 and absf(root_n.rotation.z) < 0.05 and absf(root_n.position.y) < 0.06,
		"revive resets the pose")
	_check(crown.rotation.length() < 0.05 and shin.rotation.length() < 0.05, "revive: crown and shins at rest")
	_check(float(a.call(&"heart_glow")) > 0.3 and float(a.call(&"leaf_glow")) > 0.5, "revive: glows back")
	# ---- transparency (Unit.leave_map fade / shroud) is tolerated on every part
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## Waits (max 1 s) until the model's action clock reaches t (the headless run has no camera: tier 1, half rate).
func _until_t(m: Node, t: float) -> void:
	for i: int in 60:
		if float(m.get(&"_action_t")) >= t:
			return
		await process_frame


func _until_death(m: Node, t: float) -> void:
	for i: int in 90:
		if float(m.get(&"_death_t")) >= t:
			return
		await process_frame


## Lowest vertex (model space) of the meshes whose node name is in `names` (empty = all), skipping the blob and any
## mesh under a path in `skip`.
func _lowest_vertex(model: Node3D, names: Array, skip: Array) -> float:
	var inv := model.global_transform.affine_inverse()
	var low := INF
	for g: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if not names.is_empty() and not (String(mi.name) in names):
			continue
		var path := String(model.get_path_to(mi))
		var skipped := false
		for s: String in skip:
			if path.begins_with(s):
				skipped = true
		if skipped:
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				low = minf(low, (xf * v).y)
	return low


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


func _triangles(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (g as MeshInstance3D).mesh
		if mesh:
			for s: int in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				if arr[Mesh.ARRAY_INDEX] != null and (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0:
					c += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
				else:
					c += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
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


## Top (model y) of the skull mesh's non-antler surfaces (hide + shade: the skull and ears), in `model` space.
func _aabb_of(mi: MeshInstance3D, model: Node3D, _skull_only: bool) -> float:
	var xf := model.global_transform.affine_inverse() * mi.global_transform
	var top := -INF
	for s: int in mi.mesh.get_surface_count():
		var mp := mi.mesh.surface_get_material(s).resource_path
		if not (mp.ends_with("hollow_stag_hide.tres") or mp.ends_with("hollow_stag_shade.tres")):
			continue
		for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			top = maxf(top, (xf * v).y)
	return top
