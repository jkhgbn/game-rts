extends SceneTree
## Task 13b.V4 (Mossback model): art/units/nature/mossback/.
## Run: $GODOT --headless --path . -s tests/test_13b_v4.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation (2 models: build + cache), class (MountModel), pivots (head, jaw, 4 legs, 3 trees with
## crowns), hooks and signals, the heavy budget of tier3-extras.md 12 (<= 30 meshes, <= 16 draw instances, 0 lights,
## <= 1 looping particle system), materials (own <= 7, the rest Nature / kit palette), size (4 m long, top ~2.9 m,
## the grove above the shell), the slow stomp walk (legs, dips, trees sway, never a gallop, footfall signal),
## shell_bite (the head shoots out, the beak opens and snaps shut, release, back in), set_canopy on / off (crowns
## spread and glow, leaves drift, canopy_changed, folds back), hit flash (body, jaw, grove), team colour on the drapes
## only, the kit slot audit, death (head and legs pull in, the shell drops, crowns wilt, glows die, sinks under the
## ground, death_finished <= 1.65 s) and revive, leaves stop beyond 45 m, set_canopy before _ready, transparency fade.
## Prints "PASS 13b.v4" or "FAIL 13b.v4: <reasons>".

const TASK_ID := "13b.v4"
const SCENE := "res://art/units/nature/mossback/mossback.tscn"
const OWN_DIR := "res://art/units/nature/mossback/"
## Faces pass 2026-09-28: the shared FaceKit face material (eyes / brows / lips, 1 draw call) + glow probe.
const FaceProbe := preload("res://tests/face_probe.gd")
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const TREES: Array[String] = ["Root/Mount/TreeA", "Root/Mount/TreeB", "Root/Mount/TreeC"]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _cam: Camera3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_cam = Camera3D.new()   # tier 0 (close) so the full animation runs
	_cam.position = Vector3(0, 10, 16)
	_world.add_child(_cam)
	_cam.look_at_from_position(_cam.position, Vector3.ZERO)
	_cam.make_current()
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(at: Vector3, canopy_before_ready: bool = false) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	if canopy_before_ready:
		m.call(&"set_canopy", true, true)
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(8, 0, 0))
	await _wait(0.2)
	_check(a is MountModel and a is CharacterModel, "extends MountModel (a CharacterModel)")
	# ---- pivots + hooks
	for p: String in ["Root", "Root/Mount", "Root/Mount/Merged", "Root/Mount/Head", "Root/Mount/Head/Merged",
			"Root/Mount/Head/Jaw", "Root/Mount/Head/Jaw/Merged", "Root/Mount/LegFL", "Root/Mount/LegFR", "Root/Mount/LegBL",
			"Root/Mount/LegBR", "Fx", "Fx/CanopyLeaves", "Shadow"]:
		_check(a.get_node_or_null(p) != null, "node %s" % p)
	for t: String in TREES:
		_check(a.get_node_or_null(t + "/Merged") != null, "tree %s merged" % t)
		_check(a.get_node_or_null(t + "/Crown/Merged") != null, "crown %s merged" % t)
	for hk: String in ["set_moving", "play_attack", "play_hit", "play_death", "set_team_color", "set_status", "revive",
			"play_cast", "play_level_up", "set_veterancy", "play_fidget", "set_canopy", "is_canopy", "canopy_blend",
			"get_bite_point", "get_canopy_points", "gait_phase"]:
		_check(a.has_method(hk), "hook %s" % hk)
	_check(a.has_signal(&"death_finished") and a.has_signal(&"canopy_changed") and a.has_signal(&"footfall"),
		"signals death_finished, canopy_changed, footfall")
	_check(a.get(&"attack_style") == &"shell_bite", "attack_style shell_bite")
	_check(float(a.get(&"attack_windup")) == 0.0, "melee: attack_windup 0")
	# ---- budgets
	var meshes: int = int(b.call(&"authored_mesh_count"))
	var inst := _draw_instances(b)
	var verts := _vertices(b)
	var lights := b.find_children("*", "Light3D", true, false).size()
	var parts := b.find_children("*", "GPUParticles3D", true, false)
	print("budget: meshes %d, draw instances %d, vertices %d, lights %d, particle systems %d" % [meshes, inst, verts, lights,
		parts.size()])
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var mi := gi as MeshInstance3D
			print("  %s: %d surfaces, %d vertices, shadow %s" % [b.get_path_to(mi), mi.mesh.get_surface_count(),
				_mesh_verts(mi.mesh), mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	_check(int(a.call(&"authored_mesh_count")) == meshes, "authored count equal for the cached instance")
	_check(meshes <= 30, "meshes %d <= 30" % meshes)
	_check(inst <= 16, "draw instances %d <= 16" % inst)
	_check(lights == 0, "0 lights")
	_check(parts.size() <= 1, "<= 1 particle system (%d)" % parts.size())
	for p: GPUParticles3D in parts:
		_check(not p.one_shot and not p.local_coords, "leaf fall: looping, world space")
	# 6000 + the face (faces pass 2026-09-28: measured 6070 with the Face node; small margin).
	_check(verts <= 6250, "vertices %d <= 6250 = 6000 + face" % verts)
	# ---- materials
	var own: Array = []
	var shared: Array = []
	for mat: Material in _materials(b):
		var path := mat.resource_path
		if path.begins_with(OWN_DIR):
			own.append(path.get_file())
		else:
			shared.append(path.get_file() if path != "" else "<built-in>")
			_check(path.begins_with("res://art/units/nature/materials/") or path.begins_with("res://art/units/kit/materials/")
				or FaceProbe.is_face_mat(mat), "material %s is a Nature / kit palette entry (or the face)" % path)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	print("palette materials (%d): %s" % [shared.size(), ", ".join(PackedStringArray(shared))])
	_check(own.size() <= 7, "<= 7 own materials")
	# ---- size + the grove read
	var hb := b.get_parent() as Node3D
	var box := _vert_bounds(b, hb)
	print("rest bounds x %.2f..%.2f, y %.2f..%.2f, z %.2f..%.2f" % [box.position.x, box.end.x, box.position.y, box.end.y,
		box.position.z, box.end.z])
	_check(box.position.y >= -0.015, "nothing below the ground at rest (%.3f)" % box.position.y)
	_check(box.size.z >= 3.7 and box.size.z <= 4.4, "length 3.7-4.4 m (%.2f)" % box.size.z)
	_check(box.size.x <= 3.0, "width <= 3.0 m (%.2f)" % box.size.x)
	_check(box.end.y >= 2.6 and box.end.y <= 3.1, "top of the grove 2.6-3.1 m (%.2f)" % box.end.y)
	var shell := _node_bounds(b.get_node("Root/Mount/Merged") as MeshInstance3D, hb)
	print("body (shell + grove ground + stones) y to %.2f, x %.2f..%.2f" % [shell.end.y, shell.position.x, shell.end.x])
	_check(shell.end.y >= 1.9 and shell.end.y <= 2.4, "shell + standing stones 1.9-2.4 m (%.2f)" % shell.end.y)
	var crown_lo := 99.0
	var crown_w0 := _crowns_width(b, hb)
	for t: String in TREES:
		var cb := _node_bounds(b.get_node(t + "/Crown/Merged") as MeshInstance3D, hb)
		crown_lo = minf(crown_lo, cb.position.y)
	print("crowns: lowest leaf %.2f, spread across %.2f m" % [crown_lo, crown_w0])
	_check(crown_lo > 1.85, "the crowns sit above the shell (%.2f)" % crown_lo)
	var st := _stag_height()
	if st > 0.0:
		print("grove stag top %.2f vs mossback %.2f" % [st, box.end.y])
	# ---- walk: legs, dips, trees sway, never gallops, footfall signal
	var leg: Node3D = a.get_node("Root/Mount/LegFL")
	var root_n: Node3D = a.get_node("Root")
	var tree_a: Node3D = a.get_node("Root/Mount/TreeA")
	var feet: Array = []
	a.connect(&"footfall", func(l: int) -> void: feet.append(l))
	a.call(&"set_moving", 2.8)
	await _wait(0.5)
	var max_leg := 0.0
	var ry_min := 99.0
	var ry_max := -99.0
	var tz_min := 99.0
	var tz_max := -99.0
	var max_g := 0.0
	for i: int in 120:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		ry_min = minf(ry_min, root_n.position.y)
		ry_max = maxf(ry_max, root_n.position.y)
		tz_min = minf(tz_min, tree_a.rotation.z)
		tz_max = maxf(tz_max, tree_a.rotation.z)
		max_g = maxf(max_g, float(a.call(&"gallop_blend")))
	print("walk: leg %.1f deg, body bob %.3f m, tree sway %.1f deg, gallop %.2f, footfalls %d" % [rad_to_deg(max_leg),
		ry_max - ry_min, rad_to_deg(tz_max - tz_min), max_g, feet.size()])
	_check(max_leg > deg_to_rad(12.0), "the legs swing in the walk")
	_check(ry_max - ry_min > 0.03, "heavy stomp: the body dips at the footfalls")
	_check(tz_max - tz_min > deg_to_rad(1.5), "the trees sway with the gait")
	_check(max_g < 0.05, "never gallops")
	_check(feet.size() >= 4, "footfall signal (%d)" % feet.size())
	a.call(&"set_moving", 0.0)
	await _wait(0.8)
	# ---- shell_bite
	var head: Node3D = a.get_node("Root/Mount/Head")
	var jaw: Node3D = a.get_node("Root/Mount/Head/Jaw")
	var hz0 := head.position.z
	var bite0: Vector3 = a.call(&"get_bite_point")
	var hz_max := -99.0
	var jaw_max := 0.0
	var jaw_at_hit := 99.0
	var bite_max := 0.0
	a.call(&"play_attack")
	for i: int in 40:
		await process_frame
		hz_max = maxf(hz_max, head.position.z - hz0)
		jaw_max = maxf(jaw_max, jaw.rotation.x)
		var bp: Vector3 = a.call(&"get_bite_point")
		bite_max = maxf(bite_max, bp.z - bite0.z)
		if i == 11:   # 0.2 s: just after the snap
			jaw_at_hit = jaw.rotation.x
	print("bite: neck out %.2f m, beak tip +%.2f m, jaw open %.1f deg, jaw at the snap %.1f deg" % [hz_max, bite_max,
		rad_to_deg(jaw_max), rad_to_deg(jaw_at_hit)])
	_check(hz_max > 0.45, "the head shoots out of the shell")
	_check(bite_max > 0.4, "get_bite_point follows the lunge")
	_check(jaw_max > deg_to_rad(25.0), "the beak opens wide")
	_check(jaw_at_hit < deg_to_rad(8.0), "the beak snaps shut at the strike")
	await _wait(0.6)
	_check(a.get(&"_action") == &"", "bite finished within 1.0 s")
	_check(absf(head.position.z - hz0) < 0.03, "the head is back in place")
	# ---- canopy on / off
	var crown_mi := a.get_node("Root/Mount/TreeA/Crown/Merged") as MeshInstance3D
	var crown: Node3D = a.get_node("Root/Mount/TreeA/Crown")
	var leaves := a.get_node("Fx/CanopyLeaves") as GPUParticles3D
	var changed: Array = []
	a.connect(&"canopy_changed", func(on: bool) -> void: changed.append(on))
	var g_off := float(crown_mi.get_instance_shader_parameter(&"glow_boost"))
	var w_before := _crowns_width(a, a.get_parent() as Node3D)
	a.call(&"set_canopy", true)
	await _wait(0.35)
	var mid_w := float(a.call(&"canopy_blend"))
	await _wait(1.6)
	var g_on := float(crown_mi.get_instance_shader_parameter(&"glow_boost"))
	var w_after := _crowns_width(a, a.get_parent() as Node3D)
	var lean_on := tree_a.rotation
	print("canopy on: blend %.2f at 0.35 s, crown scale %s, glow %.2f -> %.2f, spread %.2f -> %.2f m, leaves %s, changed %s" % [
		mid_w, crown.scale, g_off, g_on, w_before, w_after, leaves.emitting, changed])
	_check(mid_w > 0.4, "the crowns open quickly")
	_check(crown.scale.x > 1.35 and crown.scale.y < 0.9, "the crowns spread wide and flatten")
	_check(w_after > w_before * 1.3, "the grove's canopy is >= 30 % wider")
	_check(g_off < 0.7 and g_on > 2.0, "the crowns glow softly when on")
	_check(leaves.emitting, "glowing leaves drift down")
	_check(changed == [true], "canopy_changed(true) once")
	_check(bool(a.call(&"is_canopy")), "is_canopy")
	_check((a.call(&"get_canopy_points") as PackedVector3Array).size() == 3, "3 canopy points")
	_check(lean_on.length() > deg_to_rad(4.0), "the trees lean outward")
	a.call(&"set_canopy", false)
	await _wait(2.0)
	var g_back := float(crown_mi.get_instance_shader_parameter(&"glow_boost"))
	print("canopy off: crown scale %s, glow %.2f, leaves %s, changed %s" % [crown.scale, g_back, leaves.emitting, changed])
	_check(absf(crown.scale.x - 1.0) < 0.03, "the crowns fold back")
	_check(g_back < 0.7, "the glow fades")
	_check(not leaves.emitting, "the leaves stop")
	_check(changed == [true, false], "canopy_changed(false)")
	# ---- hit flash: body, jaw, trees, crowns
	var body_mi := a.get_node("Root/Mount/Merged") as MeshInstance3D
	var jaw_mi := a.get_node("Root/Mount/Head/Jaw/Merged") as MeshInstance3D
	var tree_mi := a.get_node("Root/Mount/TreeB/Merged") as MeshInstance3D
	a.call(&"play_hit")
	await _wait(0.05)
	var fl: Array[float] = []
	for mi: MeshInstance3D in [body_mi, jaw_mi, tree_mi, crown_mi]:
		fl.append(float(mi.get_instance_shader_parameter(&"hit_flash")))
	print("hit flash: body %.2f, jaw %.2f, tree %.2f, crown %.2f" % fl)
	_check(fl.min() > 0.3, "the whole beast and its grove flash")
	await _wait(0.5)
	# ---- team colour: the drapes only; restores
	var red := Color(0.85, 0.30, 0.12)
	b.call(&"set_team_color", red)
	await process_frame
	var b_body := b.get_node("Root/Mount/Merged") as MeshInstance3D
	_check(red in _cloth_colors(b_body), "the drapes take the team colour")
	var others_ok := true
	for s: int in b_body.mesh.get_surface_count():
		var ov := b_body.get_surface_override_material(s)
		var bn := b_body.mesh.surface_get_material(s).resource_path.get_file().get_basename()
		if ov and not (bn.ends_with("_cloth") or bn.ends_with("_cloth_dark")):
			others_ok = false
	_check(others_ok, "only cloth surfaces are recoloured")
	b.call(&"set_team_color", Color(0.35, 0.7, 0.25))
	await process_frame
	var any_override := false
	for s: int in b_body.mesh.get_surface_count():
		if b_body.get_surface_override_material(s) != null:
			any_override = true
	_check(not any_override, "the kingdom colour restores the drapes")
	# ---- kit slot audit (KITFIX rules) on every geometry
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for g: Node in a.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi == a.get(&"_shadow") or gi is GPUParticles3D:
			continue
		var by_slot: Dictionary = {}
		var names: Array[String] = []
		for mat: Material in a.call(&"_materials_of", gi):
			if not mat is ShaderMaterial:
				continue
			for u: Array in K.call(&"_instance_uniforms", (mat as ShaderMaterial).shader):
				var nm: String = u[0]
				if names.has(nm):
					continue
				names.append(nm)
				if slots.has(nm) and int(u[1]) != int(slots[nm]):
					_check(false, "%s on slot %d (map %d)" % [nm, u[1], slots[nm]])
				if by_slot.has(u[1]):
					collisions += 1
				by_slot[u[1]] = nm
		if names.has("hit_flash"):
			_check((a.get(&"_flash_all_targets") as Array).has(gi), "%s flashed by the kit" % a.get_path_to(gi))
	print("slot collisions: ", collisions)
	_check(collisions == 0, "no instance-uniform slot collision")
	# ---- statuses / misc kit hooks just run
	a.call(&"play_level_up")
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	await _wait(0.5)
	a.call(&"set_status", &"haste", false)
	a.call(&"play_fidget")
	await _wait(3.2)
	_check(a.get(&"_action") == &"", "fidget finished")
	# ---- far away (> 45 m): the leaves stop even with the canopy on; they restart close up
	a.call(&"set_canopy", true)
	await _wait(1.2)
	_cam.position = Vector3(0, 80, 90)
	await _wait(1.2)
	_check(not leaves.emitting, "the leaf fall stops beyond 45 m")
	_cam.position = Vector3(0, 10, 16)
	await _wait(1.2)
	_check(leaves.emitting, "the leaf fall restarts close up")
	# ---- death: pulls in, drops, wilts, sinks; revive
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	var leg_y0 := leg.position.y
	a.call(&"set_moving", 2.8)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(0.5)
	var head_in := head.position.z - hz0
	var leg_up := leg.position.y - leg_y0
	var glow_dead := float(crown_mi.get_instance_shader_parameter(&"glow_boost"))
	var body_glow := float(body_mi.get_instance_shader_parameter(&"glow_boost"))
	var crown_s := crown.scale.x
	print("death 0.5 s: head %.2f m, leg up %.2f m, crown scale %.2f, crown glow %.2f, rune glow %.2f, leaves %s" % [head_in,
		leg_up, crown_s, glow_dead, body_glow, leaves.emitting])
	_check(head_in < -0.5, "the head pulls into the shell")
	_check(leg_up > 0.3, "the legs tuck in")
	_check(crown_s < 1.0, "the crowns wilt")
	_check(glow_dead == 0.0 and body_glow == 0.0, "the glows die")
	_check(not leaves.emitting, "no leaf fall when dead")
	await _wait(1.12)
	var sunk := _vert_bounds(a, a.get_parent() as Node3D)
	print("death end: top %.2f, finished %s" % [sunk.end.y, got[0]])
	_check(got[0], "death_finished within 1.65 s")
	_check(sunk.end.y < 0.05, "sunk under the ground (%.2f)" % sunk.end.y)
	a.set(&"fidget_every", 0.0)   # the random idle fidget (head shoots out) may start right after a revive
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.position.y) < 0.06 and absf(head.position.z - hz0) < 0.05, "revive resets the pose")
	_check(float(crown_mi.get_instance_shader_parameter(&"glow_boost")) > 0.4, "revive: the crowns glow again")
	var rest := _vert_bounds(a, a.get_parent() as Node3D)
	_check(rest.end.y > 2.4, "revive: standing again (%.2f)" % rest.end.y)
	# ---- set_canopy before _ready (spawned with the aura on)
	var c := _spawn(Vector3(-8, 0, 0), true)
	await _wait(0.2)
	var cc: Node3D = c.get_node("Root/Mount/TreeA/Crown")
	_check(cc.scale.x > 1.35 and bool(c.call(&"is_canopy")), "set_canopy(true, true) before _ready spawns spread")
	# ---- transparency (Unit fade) tolerated
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _crowns_width(m: Node3D, frame: Node3D) -> float:
	var lo := INF
	var hi := -INF
	for t: String in TREES:
		var cb := _node_bounds(m.get_node(t + "/Crown/Merged") as MeshInstance3D, frame)
		lo = minf(lo, cb.position.x)
		hi = maxf(hi, cb.end.x)
	return hi - lo


func _stag_height() -> float:
	var p := "res://art/units/mounts/grove_stag/grove_stag.tscn"
	if not ResourceLoader.exists(p):
		return 0.0
	var holder := Node3D.new()
	holder.position = Vector3(-20, 0, 0)
	_world.add_child(holder)
	var r: Node3D = (load(p) as PackedScene).instantiate()
	holder.add_child(r)
	var bx := _vert_bounds(r, holder)
	holder.queue_free()
	return bx.end.y


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


func _mesh_verts(mesh: Mesh) -> int:
	var c := 0
	for s: int in mesh.get_surface_count():
		c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


func _vertices(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		if (g as MeshInstance3D).mesh:
			c += _mesh_verts((g as MeshInstance3D).mesh)
	return c


func _cloth_colors(mi: MeshInstance3D) -> Array:
	var out: Array = []
	for s: int in mi.mesh.get_surface_count():
		var ov := mi.get_surface_override_material(s) as ShaderMaterial
		if ov:
			var col: Variant = ov.get_shader_parameter(&"base_color")
			if col is Color and not (col in out):
				out.append(col)
	return out


func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if mi.material_override and not (mi.material_override in out):
			out.append(mi.material_override)
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out


## Exact bounds of every vertex (the blob skipped) in `frame` space.
func _vert_bounds(n: Node, frame: Node3D) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow" or not mi.is_visible_in_tree():
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := xf * v
				lo = lo.min(w)
				hi = hi.max(w)
	return AABB(lo, hi - lo)


func _node_bounds(mi: MeshInstance3D, frame: Node3D) -> AABB:
	var xf := frame.global_transform.affine_inverse() * mi.global_transform
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for s: int in mi.mesh.get_surface_count():
		for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			var w := xf * v
			lo = lo.min(w)
			hi = hi.max(w)
	return AABB(lo, hi - lo)
