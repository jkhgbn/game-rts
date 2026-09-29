extends SceneTree
## Task 12.V21: the Mirefang camp creature model (art/units/neutral/mirefang/mirefang.tscn).
## Run: $GODOT --headless --path . -s tests/test_12_v21.gd --fixed-fps 60 --quit-after 1800
## Checks: headless instantiation (2 instances: the first builds and caches the meshes, the second reuses them),
## soldier budget of map-fill.md 10 (<= 18 authored meshes, <= 10 draw instances, 0 lights) and art-units 8
## (<= 2 500 vertices, keep_separate <= 6), materials (own 3-5 painted + the eye glow in the folder, no cloth / cape /
## pennon: no team colour; the eyes are an amber unit_glow with energy >= 2.5), size (low and long: back ~0.45 m,
## nothing below 0, length ~2.35 m, fits the 0.8 m spec height), set_team_color is a no-op, the kit hooks, walk
## (splayed legs swing, the spine undulates, the tail counters), attack `snap_bite` (head up + jaw open + frill flared
## in the windup, jaw snapped shut + lunge at the 0.12 s strike, one strike per attack, ends), the head-bob fidget,
## a cast (rears, jaw open), hit (frill spikes), death (rolls belly up, eyes dark, death_finished within 1.3 s),
## revive resets the pose. Prints "PASS 12.v21" or "FAIL 12.v21: <reasons>".

const TASK_ID := "12.v21"
const SCENE := "res://art/units/neutral/mirefang/mirefang.tscn"
const OWN_DIR := "res://art/units/neutral/mirefang/"

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
	a.set(&"bob_every", 0.0)
	# ---- structure / budgets
	var authored: int = int(a.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored >= 6 and authored <= 18, "authored meshes <= 18 (got %d)" % authored)
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
		_check(inst <= 10, "draw instances <= 10 (got %d)" % inst)
		# 2500 + the face (faces pass 2026-09-28: measured 2776 / 2842 with the Face node; small margin).
		_check(verts <= 2950, "vertices <= 2950 = 2500 + face (got %d)" % verts)
		_check(sep <= 6, "keep_separate <= 6 (got %d)" % sep)
		_check(lights == 0, "0 lights")
	for n: String in ["Root/Mount/Head/Jaw", "Root/Mount/Head/Frill", "Root/Mount/Tail"]:
		_check(a.get_node_or_null(n) != null and b.get_node_or_null(n) != null, "part %s on every instance" % n)
	var mats := _materials(a)
	var own: Array = []
	var shared: Array = []
	var glow: ShaderMaterial = null
	for mat: Material in mats:
		if mat.resource_path.begins_with(OWN_DIR):
			own.append(mat.resource_path.get_file())
			if mat.resource_path.get_file() == "mirefang_eye_glow.tres":
				glow = mat as ShaderMaterial
		else:
			shared.append(mat.resource_path.get_file() if mat.resource_path != "" else "<built-in>")
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	print("shared kit materials (%d): %s" % [shared.size(), ", ".join(PackedStringArray(shared))])
	_check(own.size() >= 4 and own.size() <= 6, "4-6 own materials (got %d)" % own.size())
	for s: String in shared:
		_check(s.ends_with(".tres") and not s.contains("cloth") and not s.contains("cape") and not s.contains("pennon"),
			"shared material %s is a kit palette entry" % s)
	_check(glow != null, "the eyes use mirefang_eye_glow")
	if glow:
		var gc: Color = glow.get_shader_parameter(&"glow_color")
		var en: float = float(glow.get_shader_parameter(&"energy"))
		print("eye glow colour %s energy %.2f shader %s" % [gc, en, glow.shader.resource_path])
		_check(glow.shader.resource_path.ends_with("unit_glow.gdshader"), "eye glow on the kit unit_glow shader")
		_check(en >= 2.5 and gc.r > 0.9 and gc.g > 0.4 and gc.g < 0.75 and gc.b < 0.3, "amber eyes, energy >= 2.5")
	for g: Node in a.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		var nv := 0
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var gm := (gi as MeshInstance3D).mesh
			for s: int in gm.get_surface_count():
				nv += (gm.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("  %s (%s): %d vertices, shadow %d" % [a.get_path_to(g), g.get_class(), nv, gi.cast_shadow])
	# ---- size (rest pose, Root frame)
	var box := _aabb(a, a.get_node("Root"))
	print("rest AABB top %.3f, bottom %.3f, x %.2f .. %.2f, z %.2f .. %.2f" % [box.end.y, box.position.y,
		box.position.x, box.end.x, box.position.z, box.end.z])
	_check(box.position.y >= -0.005, "nothing below y 0 (got %.3f)" % box.position.y)
	_check(box.end.y >= 0.42 and box.end.y <= 0.8, "low: top 0.42-0.8 m (got %.3f)" % box.end.y)
	_check(box.size.z >= 2.1 and box.size.z <= 2.6, "long: ~2.35 m (got %.2f)" % box.size.z)
	_check(box.size.x <= 1.0, "width <= 1.0 m (got %.2f)" % box.size.x)
	_check(box.size.z > box.end.y * 3.5, "a low, long silhouette (length / height > 3.5)")
	_check(a.get(&"attack_style") == &"snap_bite" and float(a.get(&"attack_windup")) == 0.0, "attack snap_bite, melee")
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
				"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive", "play_bob"]:
			_check(m.has_method(h), "hook %s" % h)
		_check(m.has_signal(&"death_finished"), "signal death_finished")
	var head: Node3D = a.get_node("Root/Mount/Head")
	var mount: Node3D = a.get_node("Root/Mount")
	var root_n: Node3D = a.get_node("Root")
	var leg: Node3D = a.get_node("Root/Mount/LegFL")
	var jaw: Node3D = a.get_node("Root/Mount/Head/Jaw")
	var frill: Node3D = a.get_node("Root/Mount/Head/Frill")
	var tail: Node3D = a.get_node("Root/Mount/Tail")
	var frill_rest := frill.scale.x
	# walk: splayed legs swing (yaw), the body undulates, the tail counters
	a.call(&"set_moving", 5.0)
	var max_leg := 0.0
	var max_und := 0.0
	var max_tail := 0.0
	for i: int in 40:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.y))
		max_und = maxf(max_und, absf(mount.rotation.y))
		max_tail = maxf(max_tail, absf(tail.rotation.y))
	var fr_walk := float(a.call(&"frill_flare"))
	a.call(&"set_moving", 0.0)
	print("walk: max fore-leg swing %.1f deg, spine yaw %.1f, tail yaw %.1f, frill %.2f" % [rad_to_deg(max_leg),
		rad_to_deg(max_und), rad_to_deg(max_tail), fr_walk])
	_check(max_leg > deg_to_rad(15.0), "the legs swing in the trot (%.1f deg)" % rad_to_deg(max_leg))
	_check(max_und > deg_to_rad(4.0), "the spine undulates (%.1f deg)" % rad_to_deg(max_und))
	_check(max_tail > deg_to_rad(8.0), "the tail swings (%.1f deg)" % rad_to_deg(max_tail))
	_check(fr_walk < 0.1, "frill folded while walking")
	await _wait(0.5)
	# attack: head up + jaw gaping + frill flaring in the windup; snapped shut + lunge at the strike
	var strikes0: int = int(a.call(&"strike_count"))
	a.call(&"play_attack")
	await _until_t(a, 0.065)
	var hx_wind := head.rotation.x
	var jaw_wind := jaw.rotation.x
	var fr_wind := float(a.call(&"frill_flare"))
	await _until_t(a, 0.125)
	var hx_hit := head.rotation.x
	var jaw_hit := jaw.rotation.x
	var rz_hit := root_n.position.z
	print("bite: head x windup %.1f, strike %.1f deg; jaw windup %.1f, strike %.1f deg; lunge z %.2f; frill %.2f (scale %.2f)"
		% [rad_to_deg(hx_wind), rad_to_deg(hx_hit), rad_to_deg(jaw_wind), rad_to_deg(jaw_hit), rz_hit, fr_wind,
		frill.scale.x])
	_check(hx_wind < deg_to_rad(-15.0), "head up in the windup (%.1f)" % rad_to_deg(hx_wind))
	_check(jaw_wind > deg_to_rad(30.0), "jaw gaping in the windup (%.1f)" % rad_to_deg(jaw_wind))
	_check(hx_hit > deg_to_rad(5.0), "head snaps down at the strike (%.1f)" % rad_to_deg(hx_hit))
	_check(jaw_hit < deg_to_rad(8.0), "jaw snapped shut at the strike (%.1f)" % rad_to_deg(jaw_hit))
	_check(rz_hit > 0.15, "lunge forward at the strike (%.2f)" % rz_hit)
	_check(fr_wind > 0.6 and frill.scale.x > frill_rest + 0.2, "frill flared in the bite")
	_check(int(a.call(&"strike_count")) == strikes0 + 1, "one strike per attack")
	await _wait(0.6)
	_check(a.get(&"_action") == &"", "attack finished")
	await _wait(0.6)
	_check(absf(float(a.call(&"frill_flare")) - 0.12) < 0.1, "frill back to its collar at rest")
	# head-bob fidget
	a.call(&"play_bob")
	await _wait(0.4)
	print("bob: root pitch %.1f deg, frill %.2f" % [rad_to_deg(root_n.rotation.x), float(a.call(&"frill_flare"))])
	_check(a.get(&"_action") == &"bob" and root_n.rotation.x < deg_to_rad(-3.0), "bob: push-up on the fore legs")
	a.call(&"set_moving", 3.0)
	await _wait(0.1)
	_check(a.get(&"_action") == &"", "moving cancels the bob")
	a.call(&"set_moving", 0.0)
	await _wait(0.3)
	# cast (no ability in the spec: any id = the threat display)
	a.call(&"play_cast", &"hiss")
	await _wait(0.3)
	print("cast: root pitch %.1f deg, jaw %.1f deg, frill %.2f" % [rad_to_deg(root_n.rotation.x),
		rad_to_deg(jaw.rotation.x), float(a.call(&"frill_flare"))])
	_check(root_n.rotation.x < deg_to_rad(-8.0), "cast rears up")
	_check(jaw.rotation.x > deg_to_rad(30.0), "cast: jaw wide")
	_check(float(a.call(&"frill_flare")) > 0.8, "cast: frill fanned")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "cast finished")
	await _wait(0.4)
	a.call(&"play_hit")
	await _wait(0.1)
	print("hit: frill %.2f, jaw %.1f" % [float(a.call(&"frill_flare")), rad_to_deg(jaw.rotation.x)])
	_check(float(a.call(&"frill_flare")) > 0.5, "hit: the frill spikes open")
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
	await _wait(0.62)
	print("death 0.62 s: root roll %.1f deg, root y %.2f, glow %.2f" % [rad_to_deg(root_n.rotation.z),
		root_n.position.y, float(a.call(&"glow_level"))])
	_check(absf(root_n.rotation.z) > deg_to_rad(120.0), "rolls onto its back")
	_check(float(a.call(&"glow_level")) == 0.0, "eyes dark once dead")
	var low := _lowest_vertex(a)
	print("death: lowest vertex y %.3f" % low)
	_check(low > -0.06 and low < 0.12, "belly up on the ground, not through it (lowest %.3f)" % low)
	await _wait(0.7)
	_check(got[0], "death_finished emitted within 1.3 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.rotation.x) < 0.05 and absf(root_n.rotation.z) < 0.05 and absf(root_n.position.y) < 0.06,
		"revive resets the pose")
	_check(absf(float(a.call(&"frill_flare")) - 0.12) < 0.05 and jaw.rotation.x < 0.05, "revive: jaw and frill at rest")
	_check(float(a.call(&"glow_level")) > 0.0, "revive: eyes glow again")
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


## Lowest vertex (model space) of every mesh, the blob skipped.
func _lowest_vertex(model: Node3D) -> float:
	var inv := model.global_transform.affine_inverse()
	var low := INF
	for g: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
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
