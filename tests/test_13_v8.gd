extends SceneTree
## Task 13.V8 (Rimehorn Rider model): art/units/ice/rimehorn_rider/.
## Run: $GODOT --headless --path . -s tests/test_13_v8.gd --fixed-fps 60 --quit-after 4000
## Checks: headless instantiation (2 models: build + cache), the pair (the 13.V4 Rimehorn MountModel + an IceModel rider
## seated with set_seated, hips on the Seat behind the hump), unit hooks + signals on the scene root, attack_style
## great_swing (melee), the cavalry budget of cavalry-mounts.md 10 (<= 20 parts, <= 12 draw instances, 0 lights, <= 1
## particle system of <= 10) and the Rimehorn's own budget unchanged, materials (own <= 4, the rest Ice / kit palette),
## size, walk vs gallop from set_moving (rider bob), the great swing (wind-up with the head behind, strike on the right
## front outboard of the hump, axe_struck once at the strike frame, back to rest), the charge (the rhino's charge + the
## rider's shield forward), the axe resting clear above the hump, the glow edge, hit flash on both, team colour on cloth
## only, the kit slot audit, death (frost + shatter, the rider rides the fall, death_finished) and revive (seated
## again), hooks before _ready, transparency fade.
## Prints "PASS 13.v8" or "FAIL 13.v8: <reasons>".

const TASK_ID := "13.v8"
const SCENE := "res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn"
const MOUNT_SCENE := "res://art/units/mounts/rimehorn/rimehorn.tscn"
const OWN_DIR := "res://art/units/ice/rimehorn_rider/"
## Faces pass 2026-09-28: the shared FaceKit face material (eyes / brows / lips, 1 draw call) + glow probe.
const FaceProbe := preload("res://tests/face_probe.gd")
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const SHIELD_C := Vector3(-0.55, 1.03, 0.02)

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
	m.get_node(^"Rimehorn").set(&"fidget_every", 0.0)
	m.get_node(^"Rider").set(&"fidget_every", 0.0)
	if pre.is_valid():
		pre.call(m)
	holder.add_child(m)
	return m


## A point of the rider (model space) in the holder's frame.
func _local(rider: Node3D, pivot: Node3D, model_pos: Vector3, frame: Node3D) -> Vector3:
	var p: Vector3 = pivot.global_transform * (model_pos - (rider.call(&"model_origin", pivot) as Vector3))
	return frame.global_transform.affine_inverse() * p


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(10, 0, 0))
	await _wait(0.3)
	var mount: Node3D = a.call(&"mount_model")
	var rider: Node3D = a.call(&"rider_model")
	var holder := a.get_parent() as Node3D
	_check(mount is MountModel, "Rimehorn is a MountModel")
	_check(mount != null and mount.scene_file_path == MOUNT_SCENE, "the 13.V4 Rimehorn scene (unchanged)")
	_check(rider is IceModel and not (rider is MountModel), "Rider is an IceModel (CharacterModel)")
	_check(bool(rider.call(&"is_seated")) and rider.call(&"seat_mount") == mount, "rider seated on the Rimehorn (set_seated)")
	_check(bool(a.call(&"is_seated")), "is_seated on the root")
	for hk: String in ["set_moving", "play_attack", "play_charge", "play_hit", "play_death", "set_team_color", "set_status",
			"revive", "play_cast", "play_level_up", "set_veterancy", "set_barded", "is_barded", "set_seated", "is_seated",
			"play_fidget", "set_carrying", "get_axe_head", "gait_phase", "gallop_blend", "is_galloping",
			"authored_mesh_count", "rider_model", "mount_model"]:
		_check(a.has_method(hk), "hook %s" % hk)
	_check(a.has_signal(&"death_finished") and a.has_signal(&"axe_struck"), "signals death_finished, axe_struck")
	_check(a.get(&"attack_style") == &"great_swing" and rider.get(&"attack_style") == &"great_swing",
		"attack_style great_swing")
	_check(float(a.get(&"attack_windup")) == 0.0, "melee (attack_windup 0)")
	_check(&"stride_speed" in a, "stride_speed property (Unit writes it)")
	# ---- hips on the seat (behind the hump)
	var seat: Node3D = mount.call(&"seat_node")
	var hips: Node3D = rider.get_node("Root/Hips")
	var hd := hips.global_position.distance_to(seat.global_position)
	print("hips to seat %.3f m (seat_offset %s)" % [hd, rider.get(&"seat_offset")])
	_check(hd < 0.15, "the rider's hips sit on the Rimehorn's Seat (%.3f)" % hd)
	# ---- budgets
	var rb: Node3D = b.call(&"rider_model")
	var mb: Node3D = b.call(&"mount_model")
	var parts := int(rb.call(&"authored_mesh_count"))
	var inst := _draw_instances(rb)
	var m_inst := _draw_instances(mb)
	var lights := b.find_children("*", "Light3D", true, false).size()
	var particles := rb.find_children("*", "GPUParticles3D", true, false)
	var verts := _vertices(rb)
	var p_amount := 0
	for p: Node in particles:
		p_amount = maxi(p_amount, (p as GPUParticles3D).amount)
	print("rider budget: parts %d, draw instances %d, vertices %d, lights %d, particles %d (max amount %d); rhino instances %d, parts %d" % [
		parts, inst, verts, lights, particles.size(), p_amount, m_inst, int(mb.call(&"authored_mesh_count"))])
	for g: Node in rb.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh:
			print("  %s: %d surfaces, %d vertices, shadow %s" % [rb.get_path_to(mi), mi.mesh.get_surface_count(),
				_mesh_verts(mi.mesh), mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	_check(int(rider.call(&"authored_mesh_count")) == parts, "authored count equal for the cached instance")
	_check(parts <= 20, "rider parts %d <= 20" % parts)
	_check(inst <= 12, "rider draw instances %d <= 12" % inst)
	_check(m_inst <= 8, "Rimehorn draw instances unchanged (%d <= 8)" % m_inst)
	_check(lights == 0, "0 lights")
	_check(particles.size() <= 1 and p_amount <= 10, "<= 1 particle system of <= 10 on the rider")
	_check(verts <= 12000, "rider vertices %d <= 12000" % verts)
	# ---- materials
	var own: Array = []
	for mat: Material in _materials(rb):
		var path := mat.resource_path
		if path.begins_with(OWN_DIR):
			if not own.has(path.get_file()):
				own.append(path.get_file())
		else:
			_check(path.begins_with("res://art/units/ice/materials/") or path.begins_with("res://art/units/kit/materials/")
				or FaceProbe.is_face_mat(mat), "material %s is an Ice / kit palette entry (or the face)" % path)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	_check(own.size() <= 4, "<= 4 own materials")
	# ---- size
	var hb := b.get_parent() as Node3D
	var rbox := _vert_bounds(rb, hb)
	var mbox := _vert_bounds(mb, hb)
	print("rider bounds y %.2f..%.2f, x %.2f..%.2f, z %.2f..%.2f; rhino y 0..%.2f, z %.2f..%.2f" % [rbox.position.y,
		rbox.end.y, rbox.position.x, rbox.end.x, rbox.position.z, rbox.end.z, mbox.end.y, mbox.position.z, mbox.end.z])
	_check(rbox.end.y >= 2.6 and rbox.end.y <= 3.4, "rider (axe) on top 2.6-3.4 m (%.2f)" % rbox.end.y)
	_check(rbox.position.y > 0.4, "rider off the ground (feet at %.2f)" % rbox.position.y)
	_check(rbox.size.x >= 1.2, "wide rider (shield + axe) >= 1.2 m (%.2f)" % rbox.size.x)
	# ---- the axe at rest: upright, clear above the hump; the shield out on the left, tilted up
	var r_axe: Node3D = rider.get_node("Root/Chest/ArmR/Axe")
	var head_rest: Vector3 = holder.global_transform.affine_inverse() * (a.call(&"get_axe_head") as Vector3)
	var arm_l: Node3D = rider.get_node("Root/Chest/ArmL")
	var sh_rest := _local(rider, arm_l, SHIELD_C, holder)
	var sh_n: Vector3 = (holder.global_transform.basis.inverse() * arm_l.global_transform.basis * Vector3.LEFT).normalized()
	print("rest: axe angle %.1f, axe head (%.2f, %.2f, %.2f); shield centre (%.2f, %.2f, %.2f), face (%.2f, %.2f, %.2f)" % [
		float(rider.call(&"axe_angle")), head_rest.x, head_rest.y, head_rest.z, sh_rest.x, sh_rest.y, sh_rest.z, sh_n.x,
		sh_n.y, sh_n.z])
	_check(r_axe != null and r_axe.has_meta(&"keep_separate"), "the Axe is its own node")
	_check(absf(float(rider.call(&"axe_angle")) + 8.0) < 12.0, "the axe is carried upright at rest")
	_check(head_rest.y > 2.4, "the axe head rides high, clear of the hump (%.2f)" % head_rest.y)
	_check(sh_rest.x < -0.5 and sh_rest.y > 1.3, "the shield is braced out on the left flank")
	_check(sh_n.x < -0.5 and sh_n.y > 0.3, "the shield faces out-left and up (reads from above)")
	# ---- walk vs gallop from set_moving
	a.call(&"set_moving", 1.2)
	await _wait(1.2)
	var g_walk := float(a.call(&"gallop_blend"))
	a.call(&"set_moving", 6.0)
	await _wait(1.0)
	var y_min := 99.0
	var y_max := -99.0
	for i: int in 60:
		await process_frame
		y_min = minf(y_min, hips.global_position.y)
		y_max = maxf(y_max, hips.global_position.y)
	var g_gal := float(a.call(&"gallop_blend"))
	print("gait: walk gallop %.2f, gallop %.2f, rider bob %.3f m" % [g_walk, g_gal, y_max - y_min])
	_check(g_walk < 0.2, "walks at 1.2 m/s")
	_check(g_gal > 0.8 and bool(a.call(&"is_galloping")), "gallops at the unit's 6.0 m/s")
	_check(y_max - y_min > 0.04, "the rider bobs with the gallop")
	a.call(&"set_moving", 0.0)
	await _wait(1.0)
	# ---- the great swing
	var struck: Array = []
	a.connect(&"axe_struck", func(at: Vector3) -> void: struck.append(at))
	a.call(&"play_attack")
	var psi_min := 999.0
	var psi_max := -999.0
	var t := 0.0
	var t_struck := -1.0
	var strike_local := Vector3.ZERO
	var head_min_y := 99.0
	while t < 0.3:
		await process_frame
		t += 1.0 / 60.0
		var psi := float(rider.call(&"axe_angle"))
		if t <= 0.11:
			psi_min = minf(psi_min, psi)
		psi_max = maxf(psi_max, psi)
		if t_struck < 0.0 and struck.size() > 0:
			t_struck = t
			strike_local = holder.global_transform.affine_inverse() * (struck[0] as Vector3)
		var hl: Vector3 = holder.global_transform.affine_inverse() * (a.call(&"get_axe_head") as Vector3)
		head_min_y = minf(head_min_y, hl.y)
	await _wait(0.8)
	var psi_end := float(rider.call(&"axe_angle"))
	print("swing: wind-up axe angle %.1f, strike angle %.1f, axe_struck x%d at %.3f s, blade at (%.2f, %.2f, %.2f), lowest head y %.2f, after %.1f" % [
		psi_min, psi_max, struck.size(), t_struck, strike_local.x, strike_local.y, strike_local.z, head_min_y, psi_end])
	_check(psi_min < -110.0, "wind-up: the axe head drops behind the back")
	_check(psi_max > 95.0, "strike: the head comes over the top into a forward-down chop")
	_check(struck.size() == 1 and t_struck >= 0.13 and t_struck <= 0.18, "axe_struck once at the strike frame (~0.15 s)")
	_check(strike_local.x > 0.6 and strike_local.z > 0.5, "the chop lands on the right front, outboard of the hump")
	_check(strike_local.y > 0.6 and strike_local.y < 1.9, "the chop is at a foe's height (%.2f)" % strike_local.y)
	_check(absf(psi_end + 8.0) < 12.0 and not (rider.get(&"_action") == &"attack"), "back to the riding rest after the swing")
	# ---- the charge: the rhino's charge + the shield forward
	a.call(&"play_charge")
	await _wait(0.12)
	var m_act: StringName = mount.get(&"_action")
	var sh_ch := _local(rider, arm_l, SHIELD_C, holder)
	var head_ch: Vector3 = holder.global_transform.affine_inverse() * (a.call(&"get_axe_head") as Vector3)
	print("charge 0.12 s: rhino action %s, shield centre (%.2f, %.2f, %.2f), axe head (%.2f, %.2f, %.2f)" % [m_act,
		sh_ch.x, sh_ch.y, sh_ch.z, head_ch.x, head_ch.y, head_ch.z])
	_check(m_act == &"charge", "play_charge plays the Rimehorn's charge")
	_check(sh_ch.z > sh_rest.z + 0.2, "the shield comes forward on the charge")
	_check(head_ch.x > 0.5 and head_ch.y > 2.4, "the axe is raised high out to the right on the charge")
	await _wait(1.0)
	# ---- glows: the axe edge
	var axe_mi := r_axe as MeshInstance3D
	var gl := float(axe_mi.get_instance_shader_parameter(&"glow_boost"))
	print("axe edge glow %.2f" % gl)
	_check(gl > 0.5, "the axe's frost edge glows")
	# ---- hit flash on rider and rhino
	a.call(&"play_hit")
	await _wait(0.05)
	var f_r := float((rider.get_node("Root/Chest/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	var f_m := float((mount.get_node("Root/Mount/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	var f_a := float(axe_mi.get_instance_shader_parameter(&"hit_flash"))
	print("hit flash rider %.2f, rhino %.2f, axe %.2f" % [f_r, f_m, f_a])
	_check(f_r > 0.3 and f_m > 0.3, "rider and rhino flash on hits")
	await _wait(0.4)
	# ---- team colour: cloth only; a second colour replaces the first
	var red := Color(0.85, 0.30, 0.12)
	b.call(&"set_team_color", red)
	await process_frame
	var cmi := rb.get_node("Root/Chest/Merged") as MeshInstance3D
	var got_red := false
	var only_cloth := true
	for s: int in cmi.mesh.get_surface_count():
		var ov := cmi.get_surface_override_material(s) as ShaderMaterial
		if ov:
			var bn := cmi.mesh.surface_get_material(s).resource_path.get_file().get_basename()
			if not (bn.ends_with("_cloth") or bn.ends_with("_cloth_dark") or bn.ends_with("_cape")):
				only_cloth = false
			if ov.get_shader_parameter(&"base_color") == red:
				got_red = true
	_check(got_red and only_cloth, "the surcoat takes the team colour (cloth surfaces only)")
	var lmi := rb.get_node("Root/Chest/ArmL/Merged") as MeshInstance3D
	var shield_red := false
	for s: int in lmi.mesh.get_surface_count():
		var ov2 := lmi.get_surface_override_material(s) as ShaderMaterial
		if ov2 and ov2.get_shader_parameter(&"base_color") == red:
			shield_red = true
	_check(shield_red, "the shield's snowflake takes the team colour")
	var blue := Color(0.30, 0.45, 0.95)
	b.call(&"set_team_color", blue)
	await process_frame
	var got_blue := false
	for s: int in cmi.mesh.get_surface_count():
		var ov3 := cmi.get_surface_override_material(s) as ShaderMaterial
		if ov3 and ov3.get_shader_parameter(&"base_color") == blue:
			got_blue = true
	_check(got_blue, "a second team colour replaces the first")
	# ---- kit slot audit (KITFIX rules) on rider + rhino
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for owner: Node3D in [rider, mount]:
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
	await process_frame
	_check((rider.get_node("Root/Chest/Head/VetTrim") as Node3D).visible, "level 4: the gold helm trim shows")
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	a.call(&"play_cast", &"war_cry")
	a.call(&"set_barded", true)
	a.call(&"play_fidget")
	await _wait(0.8)
	_check(bool(a.call(&"is_barded")), "barding on the Rimehorn")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_barded", false)
	a.call(&"set_veterancy", 0)
	await _wait(1.0)
	# ---- death: the rider freezes and shatters while riding the rhino's roll; revive re-seats
	var done: Array = [false]
	a.connect(&"death_finished", func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	a.call(&"set_moving", 6.0)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(0.4)
	var hd2 := hips.global_position.distance_to(seat.global_position)
	var gl_dead := float(axe_mi.get_instance_shader_parameter(&"glow_boost"))
	var frost := float((rider.get_node("Root/Chest/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	print("death 0.4 s: hips to seat %.2f, glow %.2f, frost %.2f" % [hd2, gl_dead, frost])
	_check(hd2 < 0.25, "the rider rides the rhino's fall")
	_check(gl_dead == 0.0, "glows die")
	_check(frost > 0.2, "the rider frosts over")
	await _wait(0.4)
	var root_vis := (rider.get_node("Root") as Node3D).visible
	print("death 0.8 s: rider root visible %s" % root_vis)
	_check(not root_vis, "the rider has shattered by 0.8 s")
	await _wait(0.5)
	_check(done[0], "death_finished within 1.3 s")
	a.call(&"revive")
	await _wait(0.4)
	_check(bool(rider.call(&"is_seated")) and hips.global_position.distance_to(seat.global_position) < 0.15,
		"revive: seated again")
	_check((rider.get_node("Root") as Node3D).visible and absf(float(rider.call(&"axe_angle")) + 8.0) < 12.0,
		"revive: visible, axe at rest")
	# ---- hooks before _ready
	var e := _spawn(Vector3(-20, 0, 8), 0.0, func(m: Node3D) -> void:
		m.call(&"set_team_color", Color(0.85, 0.30, 0.12))
		m.call(&"set_moving", 6.0))
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
		if g is GPUParticles3D:
			continue
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
		if mi.material_override and not (mi.material_override in out):
			out.append(mi.material_override)
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
