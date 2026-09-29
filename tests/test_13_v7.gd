extends SceneTree
## Task 13.V7 (Gloam Rider model): art/units/shadow/gloam_rider/.
## Run: $GODOT --headless --path . -s tests/test_13_v7.gd --fixed-fps 60 --quit-after 4000
## Checks: headless instantiation (2 models: build + cache), the pair (Dusk Steed MountModel + a ShadowModel rider seated
## with set_seated, hips on the Seat), unit hooks + signals on the scene root, attack_style lance_charge (melee, windup
## 0), the cavalry budget of cavalry-mounts.md 10 (<= 20 parts, <= 12 draw instances, 0 lights, <= 1 particle system)
## and the steed's own budget unchanged, materials (own <= 3, the rest Shadow kit palette / the steed's), size (rider
## top 2.7-3.2 m, lance >= 3.4 m, lance tip the tallest point at rest), walk vs gallop (rider bob, lance lowered, cloak
## and pennon streaming back), the lance_charge attack (couched level forward at the hit frame, the thrust, one
## lance_struck at 0.12 s, back to the carry), play_charge (one charge_struck at 0.10 s, couched, the fuller flares),
## the lance held in the hand, glows (hood eyes, lance fuller), hit flash on both, team colour on cloth only (hood,
## pennon), the kit slot audit, death (rides the steed's fall, lance tips down, glows off, death_finished) and revive
## (seated, visible, lance carried), hooks before _ready, transparency fade.
## Prints "PASS 13.v7" or "FAIL 13.v7: <reasons>".

const TASK_ID := "13.v7"
const SCENE := "res://art/units/shadow/gloam_rider/gloam_rider.tscn"
const OWN_DIR := "res://art/units/shadow/gloam_rider/"
## Faces pass 2026-09-28: the shared FaceKit face material (eyes / brows / lips, 1 draw call) + glow probe.
const FaceProbe := preload("res://tests/face_probe.gd")
const STEED_DIR := "res://art/units/mounts/dusk_steed/"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"

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


## Lance direction and tip in the holder's frame.
func _lance_dir(rider: Node3D, holder: Node3D) -> Vector3:
	var l := rider.get_node("Root/Chest/ArmR/ForearmR/Lance") as Node3D
	return (holder.global_transform.basis.inverse() * l.global_transform.basis.z).normalized()


func _local(p: Vector3, holder: Node3D) -> Vector3:
	return holder.global_transform.affine_inverse() * p


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(10, 0, 0))
	await _wait(0.3)
	var steed: Node3D = a.call(&"mount_model")
	var rider: Node3D = a.call(&"rider_model")
	var holder := a.get_parent() as Node3D
	_check(steed is MountModel, "Steed is the Dusk Steed MountModel")
	_check(rider is ShadowModel and not (rider is MountModel), "Rider is a ShadowModel (CharacterModel)")
	_check(steed != null and steed.scene_file_path == STEED_DIR + "dusk_steed.tscn", "the 13.V3 steed scene")
	_check(bool(rider.call(&"is_seated")) and rider.call(&"seat_mount") == steed, "rider seated on the steed (set_seated)")
	_check(bool(a.call(&"is_seated")), "is_seated on the root")
	for hk: String in ["set_moving", "play_attack", "play_charge", "play_hit", "play_death", "set_team_color", "set_status",
			"revive", "play_cast", "play_level_up", "set_veterancy", "set_barded", "is_barded", "set_seated", "is_seated",
			"set_carrying", "play_fidget", "get_lance_tip", "lance_pitch", "couch_amount", "is_charging", "gait_phase",
			"gallop_blend", "is_galloping", "authored_mesh_count", "rider_model", "mount_model"]:
		_check(a.has_method(hk), "hook %s" % hk)
	_check(a.has_signal(&"death_finished") and a.has_signal(&"charge_struck") and a.has_signal(&"lance_struck"),
		"signals death_finished, charge_struck, lance_struck")
	_check(a.get(&"attack_style") == &"lance_charge" and rider.get(&"attack_style") == &"lance_charge",
		"attack_style lance_charge")
	_check(float(a.get(&"attack_windup")) == 0.0, "melee: attack_windup 0")
	_check(&"stride_speed" in a, "stride_speed property (Unit writes it)")
	# ---- hips on the seat
	var seat: Node3D = steed.call(&"seat_node")
	var hips: Node3D = rider.get_node("Root/Hips")
	var hd := hips.global_position.distance_to(seat.global_position)
	print("hips to seat %.3f m" % hd)
	_check(hd < 0.12, "the rider's hips sit on the steed's Seat (%.3f)" % hd)
	# ---- budgets
	var rb: Node3D = b.call(&"rider_model")
	var sb: Node3D = b.call(&"mount_model")
	var parts := int(rb.call(&"authored_mesh_count"))
	var inst := _draw_instances(rb)
	var s_inst := _draw_instances(sb)
	var lights := b.find_children("*", "Light3D", true, false).size()
	var particles := b.find_children("*", "GPUParticles3D", true, false).size()
	var verts := _vertices(rb)
	print("rider budget: parts %d, draw instances %d, vertices %d, lights %d, particles %d; steed instances %d" % [parts,
		inst, verts, lights, particles, s_inst])
	for g: Node in rb.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh:
			print("  %s: %d surfaces, %d vertices, shadow %s" % [rb.get_path_to(mi), mi.mesh.get_surface_count(),
				_mesh_verts(mi.mesh), mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	_check(int(rider.call(&"authored_mesh_count")) == parts, "authored count equal for the cached instance")
	_check(parts <= 20, "rider parts %d <= 20" % parts)
	_check(inst <= 12, "rider draw instances %d <= 12" % inst)
	_check(inst + s_inst <= 20, "unit draw instances %d <= 20" % (inst + s_inst))
	_check(s_inst <= 8, "steed draw instances unchanged (%d <= 8)" % s_inst)
	_check(lights == 0, "0 lights")
	_check(particles <= 1, "<= 1 particle system (%d)" % particles)
	_check(verts <= 12000, "rider vertices %d <= 12000" % verts)
	# ---- materials
	var own: Array = []
	for mat: Material in _materials(rb):
		var path := mat.resource_path
		if path.begins_with(OWN_DIR):
			if not own.has(path.get_file()):
				own.append(path.get_file())
		else:
			_check(path.begins_with("res://art/units/kit/materials/shadow_") or path == "res://art/units/kit/materials/unit_eye_dark.tres"
				or path.begins_with(STEED_DIR + "materials/") or FaceProbe.is_face_mat(mat),
				"material %s is a Shadow palette entry (or the steed's)" % path)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	_check(own.size() <= 3, "<= 3 own materials")
	# ---- size
	var hb := b.get_parent() as Node3D
	var lance_b := rb.get_node("Root/Chest/ArmR/ForearmR/Lance") as MeshInstance3D
	var body_box := _vert_bounds(rb, hb, lance_b)
	var all_box := _vert_bounds(rb, hb, null)
	var lb := lance_b.mesh.get_aabb()
	print("rider bounds (no lance) y %.2f..%.2f, x %.2f..%.2f; with lance top %.2f; lance %.2f m" % [body_box.position.y,
		body_box.end.y, body_box.position.x, body_box.end.x, all_box.end.y, lb.size.z])
	_check(body_box.end.y >= 2.7 and body_box.end.y <= 3.2, "rider on top 2.7-3.2 m (%.2f)" % body_box.end.y)
	_check(body_box.position.y > 0.6, "rider off the ground (feet at %.2f)" % body_box.position.y)
	_check(lb.size.z >= 3.4, "long lance >= 3.4 m (%.2f)" % lb.size.z)
	_check(all_box.end.y > body_box.end.y + 0.8, "the carried lance is the tallest line (%.2f)" % all_box.end.y)
	var p_rest := float(a.call(&"lance_pitch"))
	var d_rest := _lance_dir(rider, holder)
	# ---- the lance is in the right hand
	var fore := rider.get_node("Root/Chest/ArmR/ForearmR") as Node3D
	var lance := rider.get_node("Root/Chest/ArmR/ForearmR/Lance") as Node3D
	var hand_w: Vector3 = fore.global_transform * Vector3(0, -0.28, 0)   # HAND_R - ELBOW_R
	_check(lance.global_position.distance_to(hand_w) < 0.01, "the lance grip is in the right hand")
	# ---- pennon hangs below the shaft at rest
	var pennon := rider.get_node("Root/Chest/ArmR/ForearmR/Lance/Pennon") as Node3D
	var pen_tail_rest := _local(pennon.global_transform * Vector3(0, -0.15, -0.9), holder) - _local(pennon.global_position, holder)
	# ---- walk vs gallop from set_moving
	a.call(&"set_moving", 1.8)
	await _wait(1.2)
	var g_walk := float(a.call(&"gallop_blend"))
	a.call(&"set_moving", 7.2)
	await _wait(1.2)
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
	var p_gal := float(a.call(&"lance_pitch"))
	var d_gal := _lance_dir(rider, holder)
	var pen_tail_gal := _local(pennon.global_transform * Vector3(0, -0.15, -0.9), holder) - _local(pennon.global_position, holder)
	print("gait: walk gallop %.2f, gallop %.2f, rider bob %.3f m, cloak %.1f deg; lance pitch rest %.1f (dir %s), gallop %.1f (dir %s); pennon tail rest %s, gallop %s" % [
		g_walk, g_gal, y_max - y_min, rad_to_deg(cl_max), p_rest, d_rest, p_gal, d_gal, pen_tail_rest, pen_tail_gal])
	_check(g_walk < 0.2, "walks at 1.8 m/s")
	_check(g_gal > 0.8 and bool(a.call(&"is_galloping")), "gallops at 7.2 m/s")
	_check(y_max - y_min > 0.04, "the rider bobs with the gallop")
	_check(cl_max > deg_to_rad(50.0), "the cloak streams back at the gallop")
	_check(d_rest.y > 0.6 and d_rest.z > 0.3, "carried high and forward at rest")
	_check(d_gal.y > 0.1 and d_gal.y < 0.45 and d_gal.z > 0.85, "lowered forward at the gallop")
	_check(pen_tail_rest.y < -0.3, "the pennon hangs down at rest")
	_check(pen_tail_gal.z < -0.5, "the pennon streams back at the gallop")
	# ---- lance_charge attack (at the gallop)
	var struck: Array = []
	a.connect(&"lance_struck", func(at: Vector3) -> void: struck.append(at))
	a.call(&"play_attack")
	var tip_back := Vector3.ZERO
	var frame_hit := -1
	for f: int in 9:   # to 0.15 s
		await process_frame
		if f == 3:
			tip_back = _local(a.call(&"get_lance_tip"), holder)
		if frame_hit < 0 and struck.size() > 0:
			frame_hit = f
	var tip_hit := _local(a.call(&"get_lance_tip"), holder)
	var d_hit := _lance_dir(rider, holder)
	var couch := float(a.call(&"couch_amount"))
	print("strike: frame %d, couch %.2f, dir %s, tip %s (drawn back %s), struck %d" % [frame_hit, couch, d_hit, tip_hit,
		tip_back, struck.size()])
	_check(struck.size() == 1 and frame_hit >= 5 and frame_hit <= 8, "one lance_struck at ~0.12 s")
	_check(couch > 0.9, "couched at the strike")
	_check(absf(d_hit.y) < 0.25 and d_hit.z > 0.9, "the lance levelled forward at the strike")
	_check(tip_hit.z > 2.6 and tip_hit.y > 1.0 and tip_hit.y < 2.2, "the tip reaches ahead at chest height")
	_check(tip_hit.z - tip_back.z > 0.2, "the thrust drives the tip forward (%.2f)" % (tip_hit.z - tip_back.z))
	await _wait(0.8)
	_check(float(a.call(&"couch_amount")) < 0.05 and float(a.call(&"lance_pitch")) < -10.0, "back to the carry after the strike")
	# ---- play_charge
	var charged: Array = []
	a.connect(&"charge_struck", func(at: Vector3) -> void: charged.append(at))
	var lance_mi := lance as GeometryInstance3D
	var gl_rest := float(lance_mi.get_instance_shader_parameter(&"glow_boost"))
	a.call(&"play_charge")
	var c_frame := -1
	var gl_max := 0.0
	var c_couch := 0.0
	for f: int in 10:
		await process_frame
		gl_max = maxf(gl_max, float(lance_mi.get_instance_shader_parameter(&"glow_boost")))
		if c_frame < 0 and charged.size() > 0:
			c_frame = f
			c_couch = float(a.call(&"couch_amount"))
	var d_chg := _lance_dir(rider, holder)
	print("charge: frame %d, couch %.2f, dir %s, glow %.2f -> %.2f, charging %s" % [c_frame, c_couch, d_chg, gl_rest, gl_max,
		a.call(&"is_charging")])
	_check(charged.size() == 1 and c_frame >= 4 and c_frame <= 7, "one charge_struck at ~0.10 s")
	_check(c_couch > 0.9 and absf(d_chg.y) < 0.25 and d_chg.z > 0.9, "the charge couches the lance level")
	_check(gl_rest > 0.5 and gl_max > gl_rest * 1.5, "the lance fuller glows and flares on the charge")
	await _wait(1.0)
	_check(not bool(a.call(&"is_charging")), "the charge ends")
	a.call(&"set_moving", 0.0)
	# ---- glows: hood eyes
	# The hood eyes are the Face node's glowing eyes since the faces pass 2026-09-28 (were two glow slits in Head/Merged).
	var head_mi := rider.get_node_or_null("Root/Chest/Head/Face") as MeshInstance3D
	_check(head_mi != null and FaceProbe.glows(head_mi), "the hood eyes: a face with glowing eyes")
	_check(FaceProbe.boost(head_mi) > 0.5, "the hood eyes glow")
	# ---- hit flash on rider and steed
	a.call(&"play_hit")
	await _wait(0.05)
	var f_r := float((rider.get_node("Root/Chest/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	var f_s := float((steed.get_node("Root/Mount/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	print("hit flash rider %.2f, steed %.2f" % [f_r, f_s])
	_check(f_r > 0.3 and f_s > 0.3, "rider and steed flash on hits")
	await _wait(0.4)
	# ---- team colour: cloth only (hood, pennon)
	var red := Color(0.85, 0.30, 0.12)
	b.call(&"set_team_color", red)
	await process_frame
	var pen_b := rb.get_node("Root/Chest/ArmR/ForearmR/Lance/Pennon") as MeshInstance3D
	for mi: MeshInstance3D in [rb.get_node("Root/Chest/Head/Merged") as MeshInstance3D, pen_b]:
		var got_red := false
		var only_cloth := true
		for s: int in mi.mesh.get_surface_count():
			var ov := mi.get_surface_override_material(s) as ShaderMaterial
			if ov:
				var bn := mi.mesh.surface_get_material(s).resource_path.get_file().get_basename()
				if not (bn.ends_with("_cloth") or bn.ends_with("_cloth_dark")):
					only_cloth = false
				if ov.get_shader_parameter(&"base_color") == red:
					got_red = true
		_check(got_red and only_cloth, "%s takes the team colour (cloth surfaces only)" % mi.name)
	# the pennon's mesh swaps (flutter) keep the team colour
	b.call(&"set_moving", 7.2)
	await _wait(0.6)
	var red_kept := false
	for s: int in pen_b.mesh.get_surface_count():
		var ov := pen_b.get_surface_override_material(s) as ShaderMaterial
		if ov and ov.get_shader_parameter(&"base_color") == red:
			red_kept = true
	_check(red_kept, "the fluttering pennon keeps the team colour")
	b.call(&"set_moving", 0.0)
	var blue := Color(0.45, 0.75, 0.95)
	b.call(&"set_team_color", blue)
	await process_frame
	var got_blue := false
	var hmi := rb.get_node("Root/Chest/Head/Merged") as MeshInstance3D
	for s: int in hmi.mesh.get_surface_count():
		var ov2 := hmi.get_surface_override_material(s) as ShaderMaterial
		if ov2 and ov2.get_shader_parameter(&"base_color") == blue:
			got_blue = true
	_check(got_blue, "a second team colour replaces the first")
	# ---- kit slot audit (KITFIX rules) on rider + steed
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for owner: Node3D in [rider, steed]:
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
	a.call(&"play_cast", &"soul_siphon")
	a.call(&"set_barded", true)
	a.call(&"play_fidget")
	a.call(&"set_carrying", true)
	await _wait(0.8)
	_check(bool(a.call(&"is_barded")), "barding on the steed")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_barded", false)
	a.call(&"set_veterancy", 0)
	# ---- death: the rider rides the steed's fall; revive re-seats
	var done: Array = [false]
	a.connect(&"death_finished", func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	a.call(&"set_moving", 7.2)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(0.6)
	var hd2 := hips.global_position.distance_to(seat.global_position)
	var gl_dead := FaceProbe.boost(head_mi)
	var gl_lance_dead := float(lance_mi.get_instance_shader_parameter(&"glow_boost"))
	var tip_dead := _local(a.call(&"get_lance_tip"), holder)
	print("death 0.6 s: hips to seat %.2f, seat y %.2f, glow %.2f / lance %.2f, tip y %.2f" % [hd2, seat.global_position.y,
		gl_dead, gl_lance_dead, tip_dead.y])
	_check(hd2 < 0.2, "the rider rides the steed's fall")
	_check(gl_dead == 0.0 and gl_lance_dead == 0.0, "glows die")
	_check(tip_dead.y < 2.5, "the lance tips down")
	await _wait(0.7)
	_check(done[0], "death_finished within 1.3 s")
	a.call(&"revive")
	await _wait(0.4)
	_check(bool(rider.call(&"is_seated")) and hips.global_position.distance_to(seat.global_position) < 0.12,
		"revive: seated again")
	var chest_mi := rider.get_node("Root/Chest/Merged") as GeometryInstance3D
	_check(chest_mi.transparency < 0.01 and float(a.call(&"lance_pitch")) < -30.0, "revive: visible, lance carried")
	# ---- hooks before _ready
	var e := _spawn(Vector3(-20, 0, 8), 0.0, func(m: Node3D) -> void:
		m.call(&"set_team_color", Color(0.85, 0.30, 0.12))
		m.call(&"set_barded", true)
		m.call(&"set_moving", 7.2))
	await _wait(0.6)
	_check(bool((e.call(&"rider_model") as Node).call(&"is_seated")) and float(e.call(&"gallop_blend")) > 0.5
		and bool(e.call(&"is_barded")), "hooks before _ready are kept")
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


## Exact bounds of every vertex (the blob and `skip` with its children skipped) in `frame` space.
func _vert_bounds(n: Node, frame: Node3D, skip: Node) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow" or not mi.is_visible_in_tree():
			continue
		if skip and (mi == skip or skip.is_ancestor_of(mi)):
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := xf * v
				lo = lo.min(w)
				hi = hi.max(w)
	return AABB(lo, hi - lo)
