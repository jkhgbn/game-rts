extends SceneTree
## Task 13b.V3 (Glade Outrider model): art/units/nature/glade_outrider/.
## Run: $GODOT --headless --path . -s tests/test_13b_v3.gd --fixed-fps 60 --quit-after 4000
## Checks: headless instantiation (2 models: build + cache), the pair (Grove Stag MountModel + a CharacterModel rider
## seated with set_seated, hips on the Seat), unit hooks + signals on the scene root, attack_style mounted_bow / windup,
## the cavalry rider budget of tier3-extras.md 12 (<= 20 parts, <= 12 draw instances, 0 lights, 0 particles) and the
## stag's own budget unchanged, materials (own <= 4, the rest Nature / kit palette / the stag's antler), size (rider on
## top ~2.6-3.2 m, bow >= 1 m wide), walk vs gallop from set_moving (rider bob, cloak streaming), the shot at a gallop
## in 4 directions (torso twist within +-90 in the right sense, full draw at the windup, the bow and the released arrow
## along the target line, arrow_released once, reload + re-nock, the aim held then relaxed), the auto-aim from the
## owning unit's attack_target, glows (twig buds, the arrow brighter with the draw), hit flash on both, team colour on
## cloth only, the kit slot audit, death (rides the stag's fall, glows off, death_finished) and revive (seated again),
## hooks before _ready, transparency fade.
## Prints "PASS 13b.v3" or "FAIL 13b.v3: <reasons>".

const TASK_ID := "13b.v3"
const SCENE := "res://art/units/nature/glade_outrider/glade_outrider.tscn"
const OWN_DIR := "res://art/units/nature/glade_outrider/"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const DIRS: Array[Vector3] = [Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)]
const NAMES: Array[String] = ["front", "left", "right", "behind"]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _cam: Camera3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_cam = Camera3D.new()   # tier 0 (close) so the full animation runs
	_cam.position = Vector3(0, 8, 12)
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


func _spawn(at: Vector3, yaw_deg: float = 0.0, pre: Callable = Callable()) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = deg_to_rad(yaw_deg)
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	if pre.is_valid():
		pre.call(m)
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(10, 0, 0))
	await _wait(0.3)
	var stag: Node3D = a.call(&"mount_model")
	var rider: Node3D = a.call(&"rider_model")
	_check(stag is MountModel, "Stag is the Grove Stag MountModel")
	_check(rider is CharacterModel and not (rider is MountModel), "Rider is a CharacterModel")
	_check(stag != null and stag.scene_file_path == "res://art/units/mounts/grove_stag/grove_stag.tscn", "the 13.V5 stag scene")
	_check(bool(rider.call(&"is_seated")) and rider.call(&"seat_mount") == stag, "rider seated on the stag (set_seated)")
	_check(bool(a.call(&"is_seated")), "is_seated on the root")
	for hk: String in ["set_moving", "play_attack", "play_hit", "play_death", "set_team_color", "set_status", "revive",
			"play_cast", "play_level_up", "set_veterancy", "set_barded", "is_barded", "set_seated", "is_seated",
			"set_aim_target", "get_arrow_origin", "aim_twist", "gait_phase", "gallop_blend", "is_galloping",
			"authored_mesh_count", "rider_model", "mount_model"]:
		_check(a.has_method(hk), "hook %s" % hk)
	_check(a.has_signal(&"death_finished") and a.has_signal(&"arrow_released"), "signals death_finished, arrow_released")
	_check(a.get(&"attack_style") == &"mounted_bow" and rider.get(&"attack_style") == &"mounted_bow",
		"attack_style mounted_bow")
	var wu := float(a.get(&"attack_windup"))
	_check(wu > 0.0 and wu <= 0.15, "ranged windup 0-0.15 (%.2f)" % wu)
	_check(&"stride_speed" in a, "stride_speed property (Unit writes it)")
	# ---- hips on the seat
	var seat: Node3D = stag.call(&"seat_node")
	var hips: Node3D = rider.get_node("Root/Hips")
	var hd := hips.global_position.distance_to(seat.global_position)
	print("hips to seat %.3f m" % hd)
	_check(hd < 0.12, "the rider's hips sit on the stag's Seat (%.3f)" % hd)
	# ---- budgets
	var rb: Node3D = b.call(&"rider_model")
	var sb: Node3D = b.call(&"mount_model")
	var parts := int(rb.call(&"authored_mesh_count"))
	var inst := _draw_instances(rb)
	var s_inst := _draw_instances(sb)
	var lights := b.find_children("*", "Light3D", true, false).size()
	var particles := rb.find_children("*", "GPUParticles3D", true, false).size()
	var verts := _vertices(rb)
	print("rider budget: parts %d, draw instances %d, vertices %d, lights %d, particles %d; stag instances %d" % [parts,
		inst, verts, lights, particles, s_inst])
	for g: Node in rb.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh:
			print("  %s: %d surfaces, %d vertices, shadow %s" % [rb.get_path_to(mi), mi.mesh.get_surface_count(),
				_mesh_verts(mi.mesh), mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	_check(int(rider.call(&"authored_mesh_count")) == parts, "authored count equal for the cached instance")
	_check(parts <= 20, "rider parts %d <= 20" % parts)
	_check(inst <= 12, "rider draw instances %d <= 12" % inst)
	_check(s_inst <= 8, "stag draw instances unchanged (%d <= 8)" % s_inst)
	_check(lights == 0, "0 lights")
	_check(particles == 0, "0 particle systems on the rider")
	_check(verts <= 12000, "rider vertices %d <= 12000" % verts)
	# ---- materials
	var own: Array = []
	for mat: Material in _materials(rb):
		var path := mat.resource_path
		if path.begins_with(OWN_DIR):
			if not own.has(path.get_file()):
				own.append(path.get_file())
		else:
			_check(path.begins_with("res://art/units/nature/materials/") or path.begins_with("res://art/units/kit/materials/")
				or path == "res://art/units/mounts/grove_stag/materials/grove_stag_antler.tres",
				"material %s is a Nature / kit palette entry (or the stag's antler)" % path)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	_check(own.size() <= 4, "<= 4 own materials")
	# ---- size
	var hb := b.get_parent() as Node3D
	var rbox := _vert_bounds(rb, hb)
	var bow := rb.get_node("Root/Chest/ArmL/Bow") as MeshInstance3D
	var bowb := bow.mesh.get_aabb()
	print("rider bounds y %.2f..%.2f, x %.2f..%.2f; bow %.2f m wide" % [rbox.position.y, rbox.end.y, rbox.position.x,
		rbox.end.x, bowb.size.x])
	_check(rbox.end.y >= 2.6 and rbox.end.y <= 3.2, "rider on top 2.6-3.2 m (%.2f)" % rbox.end.y)
	_check(rbox.position.y > 0.6, "rider off the ground (feet at %.2f)" % rbox.position.y)
	_check(bowb.size.x >= 1.0 and bowb.size.x <= 1.4, "short bow 1.0-1.4 m (%.2f)" % bowb.size.x)
	# ---- walk vs gallop from set_moving
	a.call(&"set_moving", 1.7)
	await _wait(1.2)
	var g_walk := float(a.call(&"gallop_blend"))
	a.call(&"set_moving", 7.6)
	await _wait(1.0)
	var y_min := 99.0
	var y_max := -99.0
	var cloak := rider.get_node("Root/Chest/Cloak") as Node3D
	var cl_max := 0.0
	for i: int in 60:
		await process_frame
		y_min = minf(y_min, hips.global_position.y)
		y_max = maxf(y_max, hips.global_position.y)
		cl_max = maxf(cl_max, cloak.rotation.x)
	var g_gal := float(a.call(&"gallop_blend"))
	print("gait: walk gallop %.2f, gallop %.2f, rider bob %.3f m, cloak lift %.1f deg" % [g_walk, g_gal, y_max - y_min,
		rad_to_deg(cl_max)])
	_check(g_walk < 0.2, "walks at 1.7 m/s")
	_check(g_gal > 0.8 and bool(a.call(&"is_galloping")), "gallops at 7.6 m/s")
	_check(y_max - y_min > 0.04, "the rider bobs with the gallop")
	_check(cl_max > deg_to_rad(12.0), "the leaf cloak streams back at the gallop")
	# ---- shooting at a gallop in 4 directions
	var released: Array = []
	a.connect(&"arrow_released", func(from: Vector3, dir: Vector3) -> void: released.append([from, dir]))
	var arrow := rider.get_node("Root/Chest/ArmL/Bow/Arrow") as MeshInstance3D
	var abow := rider.get_node("Root/Chest/ArmL/Bow") as MeshInstance3D
	var chest: Node3D = rider.get_node("Root/Chest")
	var tgt := Node3D.new()
	_world.add_child(tgt)
	var holder := a.get_parent() as Node3D
	for i: int in 4:
		tgt.global_position = holder.global_transform * (DIRS[i] * 12.0)
		a.call(&"set_aim_target", tgt)
		a.call(&"play_attack")
		await _wait(0.9)
		released.clear()
		var d_start := float(rider.call(&"draw_amount"))
		a.call(&"play_attack")
		var d_max := 0.0
		var bow_dot := -1.0
		for f: int in 7:   # to ~0.117 s: full draw just before the loose
			await process_frame
			d_max = maxf(d_max, float(rider.call(&"draw_amount")))
		var to_t := (tgt.global_position - abow.global_position) * Vector3(1, 0, 1)
		var bdir := (-abow.global_transform.basis.y) * Vector3(1, 0, 1)
		bow_dot = bdir.normalized().dot(to_t.normalized())
		var tw := float(a.call(&"aim_twist"))
		# chest yaw vs the stag's body (the twist in the saddle)
		var cf := chest.global_transform.basis.z * Vector3(1, 0, 1)
		var sf := holder.global_transform.basis.z * Vector3(1, 0, 1)
		var rel := rad_to_deg(sf.normalized().signed_angle_to(cf.normalized(), Vector3.UP))
		await _wait(0.1)
		var hidden := not arrow.visible
		await _wait(0.4)
		var renocked := arrow.visible
		var rel_dot := -1.0
		if released.size() == 1:
			var rdir: Vector3 = (released[0][1] as Vector3) * Vector3(1, 0, 1)
			var rto: Vector3 = (tgt.global_position - (released[0][0] as Vector3)) * Vector3(1, 0, 1)
			rel_dot = rdir.normalized().dot(rto.normalized())
		print("shot %s: twist %.1f (chest vs body %.1f), draw %.2f -> %.2f, bow on target %.3f, released %d (on target %.3f), arrow hidden %s, re-nocked %s" % [
			NAMES[i], tw, absf(rel), d_start, d_max, bow_dot, released.size(), rel_dot, hidden, renocked])
		_check(absf(tw) <= 90.5 and absf(rel) <= 95.0, "%s: torso twist within 90 deg" % NAMES[i])
		match i:
			0: _check(tw > 40.0, "front: the chest turns right (bow shoulder forward)")
			1: _check(tw < 0.0 and tw > -45.0, "left: small twist (natural side)")
			2: _check(tw > 80.0, "right: full twist to the right")
			3: _check(tw < -80.0, "behind: full twist the other way (parting shot)")
		_check(d_max > 0.8, "%s: full draw at the windup" % NAMES[i])
		_check(bow_dot > 0.9, "%s: the bow points along the target line" % NAMES[i])
		_check(released.size() == 1 and rel_dot > 0.85, "%s: one arrow released toward the target" % NAMES[i])
		_check(hidden and renocked, "%s: arrow loosed, then a new one nocked" % NAMES[i])
	# aim held, then relaxed
	await _wait(0.6)
	var held := float(rider.call(&"aim_blend"))
	await _wait(2.6)
	var relaxed := float(rider.call(&"aim_blend"))
	var tw_rest := float(a.call(&"aim_twist"))
	print("aim held %.2f, relaxed %.2f (twist %.1f)" % [held, relaxed, tw_rest])
	_check(held > 0.9, "the aim is held between shots (fire on the move)")
	_check(relaxed < 0.05 and absf(tw_rest) < 2.0, "the aim relaxes after ~2 s without a shot")
	a.call(&"set_moving", 0.0)
	# ---- glows: twig buds (head) and the arrow
	var head_mi := rider.get_node("Root/Chest/Head/Merged") as MeshInstance3D
	_check(float(head_mi.get_instance_shader_parameter(&"glow_boost")) > 0.5, "twig buds glow")
	var g_rest := float(arrow.get_instance_shader_parameter(&"glow_boost"))
	a.call(&"play_attack")
	await _wait(0.1)
	var g_draw := float(arrow.get_instance_shader_parameter(&"glow_boost"))
	print("arrow glow rest %.2f, drawn %.2f" % [g_rest, g_draw])
	_check(g_rest > 0.5 and g_draw > g_rest * 1.5, "the arrow's seed head glows brighter with the draw")
	await _wait(3.0)
	# ---- auto aim from the owning unit's attack_target
	var us := GDScript.new()
	us.source_code = "extends Node3D\nvar attack_target: Node3D = null\n"
	us.reload()
	var unit := Node3D.new()
	unit.set_script(us)
	unit.position = Vector3(-10, 0, 0)
	_world.add_child(unit)
	var vis := Node3D.new()
	unit.add_child(vis)
	var c: Node3D = (load(SCENE) as PackedScene).instantiate()
	vis.add_child(c)
	var t2 := Node3D.new()
	_world.add_child(t2)
	t2.global_position = Vector3(-10, 0, -12)
	unit.set(&"attack_target", t2)
	await _wait(0.2)
	c.call(&"play_attack")
	await _wait(0.4)
	var tw_auto := float(c.call(&"aim_twist"))
	print("auto aim (target behind): twist %.1f" % tw_auto)
	_check(tw_auto < -60.0, "play_attack aims at the owner's attack_target by itself")
	# ---- hit flash on rider and stag
	a.call(&"play_hit")
	await _wait(0.05)
	var f_r := float((rider.get_node("Root/Chest/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	var f_s := float((stag.get_node("Root/Mount/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	print("hit flash rider %.2f, stag %.2f" % [f_r, f_s])
	_check(f_r > 0.3 and f_s > 0.3, "rider and stag flash on hits")
	await _wait(0.4)
	# ---- team colour: cloth only; restores
	var red := Color(0.85, 0.30, 0.12)
	b.call(&"set_team_color", red)
	await process_frame
	var hmi := rb.get_node("Root/Chest/Head/Merged") as MeshInstance3D
	var got_red := false
	var only_cloth := true
	for s: int in hmi.mesh.get_surface_count():
		var ov := hmi.get_surface_override_material(s) as ShaderMaterial
		if ov:
			var bn := hmi.mesh.surface_get_material(s).resource_path.get_file().get_basename()
			if not (bn.ends_with("_cloth") or bn.ends_with("_cloth_dark")):
				only_cloth = false
			if ov.get_shader_parameter(&"base_color") == red:
				got_red = true
	_check(got_red and only_cloth, "the hood takes the team colour (cloth surfaces only)")
	# (a CharacterModel keeps its last team colour: the kit's set_team_color is a no-op for its own kingdom colour)
	var blue := Color(0.45, 0.75, 0.95)
	b.call(&"set_team_color", blue)
	await process_frame
	var got_blue := false
	for s: int in hmi.mesh.get_surface_count():
		var ov2 := hmi.get_surface_override_material(s) as ShaderMaterial
		if ov2 and ov2.get_shader_parameter(&"base_color") == blue:
			got_blue = true
	_check(got_blue, "a second team colour replaces the first")
	# ---- kit slot audit (KITFIX rules) on rider + stag
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for owner: Node3D in [rider, stag]:
		for g: Node in owner.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if gi == owner.get(&"_shadow") or gi is GPUParticles3D:
				continue
			var by_slot: Dictionary = {}
			var names: Array[String] = []
			for mat: Material in owner.call(&"_materials_of", gi):
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
				_check((owner.get(&"_flash_all_targets") as Array).has(gi), "%s flashed by the kit" % owner.get_path_to(gi))
	print("slot collisions: ", collisions)
	_check(collisions == 0, "no instance-uniform slot collision")
	# ---- misc hooks run
	a.call(&"play_level_up")
	a.call(&"set_veterancy", 4)
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	a.call(&"play_cast", &"parting_shots")
	a.call(&"set_barded", true)
	await _wait(0.8)
	_check(bool(a.call(&"is_barded")), "barding on the stag")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_barded", false)
	# ---- death: the rider rides the stag's fall; revive re-seats
	var done: Array = [false]
	a.connect(&"death_finished", func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	a.call(&"set_moving", 7.6)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(0.6)
	var hd2 := hips.global_position.distance_to(seat.global_position)
	var gl_dead := float(head_mi.get_instance_shader_parameter(&"glow_boost"))
	print("death 0.6 s: hips to seat %.2f, seat y %.2f, glow %.2f" % [hd2, seat.global_position.y, gl_dead])
	_check(hd2 < 0.2, "the rider rides the stag's fall")
	_check(gl_dead == 0.0, "glows die")
	await _wait(0.7)
	_check(done[0], "death_finished within 1.3 s")
	a.call(&"revive")
	await _wait(0.4)
	_check(bool(rider.call(&"is_seated")) and hips.global_position.distance_to(seat.global_position) < 0.12,
		"revive: seated again")
	_check(float(rider.call(&"aim_blend")) == 0.0 and arrow.visible, "revive: bow at rest, arrow nocked")
	# ---- hooks before _ready
	var e := _spawn(Vector3(-20, 0, 8), 0.0, func(m: Node3D) -> void:
		m.call(&"set_team_color", Color(0.85, 0.30, 0.12))
		m.call(&"set_aim_target", Vector3(0, 0, 100))
		m.call(&"set_moving", 7.6))
	await _wait(0.5)
	_check(bool((e.call(&"rider_model") as Node).call(&"is_seated")) and float(e.call(&"gallop_blend")) > 0.5,
		"hooks before _ready are kept")
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


func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s)
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
