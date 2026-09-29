extends SceneTree
## Task 13.V10 (Blaze Rider refresh): art/units/fire/blaze_rider.tscn = the shared 13.V2 Ember Boar + a seated rider.
## Run: $GODOT --headless --path . -s tests/test_13_v10.gd --fixed-fps 60 --quit-after 4000
## Checks: same scene path, the pair (Ember Boar MountModel + a FireModel rider seated with set_seated, hips on the Seat),
## the old unit hooks + play_charge + signals on the root, the unit-facing values unchanged (lance_charge, melee windup 0,
## body_height 1.9, stride_speed, _speed), the cavalry budget of section 10 (<= 20 parts, <= 12 draw instances, 0
## lights, <= 1 particle system of <= 10), kit palette materials only, size (lance raised above the rider), walk vs
## gallop (rider bob, the lance lowers, the pennon streams), the attack (lance couched level at the strike, one
## lance_struck ahead, the boar tosses), the charge (lance level and couched, charge_struck once at 0.10 s, the boar's
## charge + mane flare, the lance head flares, then back to rest), hit flash on both, team colour on cloth / pennon,
## the kit slot audit, veterancy trim, death (rides the boar's fall, burns, death_finished) and revive (seated again),
## hooks before _ready, the Fire builder no longer overwriting the scene.
## Prints "PASS 13.v10" or "FAIL 13.v10: <reasons>".

const TASK_ID := "13.v10"
## Faces pass 2026-09-28: the shared FaceKit face material (eyes / brows / lips, 1 draw call) + glow probe.
const FaceProbe := preload("res://tests/face_probe.gd")
const SCENE := "res://art/units/fire/blaze_rider.tscn"
const BOAR := "res://art/units/mounts/ember_boar/ember_boar.tscn"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const GALLOP := 7.5

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
	_check(ResourceLoader.exists(SCENE), "scene exists at the old path")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(10, 0, 0))
	a.get_node(^"Boar").set(&"fidget_every", 0.0)
	await _wait(0.3)
	var boar: Node3D = a.call(&"mount_model")
	var rider: Node3D = a.call(&"rider_model")
	_check(a is BlazeRiderModel, "root is BlazeRiderModel")
	_check(boar is MountModel and boar.scene_file_path == BOAR, "Boar is the shared 13.V2 Ember Boar scene")
	_check(rider is FireModel and not (rider is MountModel), "Rider is a FireModel (CharacterModel)")
	_check(bool(rider.call(&"is_seated")) and rider.call(&"seat_mount") == boar, "rider seated on the boar (set_seated)")
	_check(bool(a.call(&"is_seated")), "is_seated on the root")
	for hk: String in ["set_moving", "play_attack", "play_hit", "play_death", "set_team_color", "set_status", "revive",
			"play_cast", "play_level_up", "set_veterancy", "set_carrying", "set_barded", "is_barded", "set_seated",
			"is_seated", "play_charge", "play_fidget", "get_lance_tip", "get_weapon_tip", "lance_pitch", "couch_amount",
			"is_charging", "gait_phase", "gallop_blend", "is_galloping", "authored_mesh_count", "rider_model",
			"mount_model"]:
		_check(a.has_method(hk), "hook %s" % hk)
	_check(a.has_signal(&"death_finished") and a.has_signal(&"charge_struck") and a.has_signal(&"lance_struck"),
		"signals death_finished, charge_struck, lance_struck")
	# unit-facing values of the old model
	_check(a.get(&"attack_style") == &"lance_charge" and rider.get(&"attack_style") == &"lance_charge",
		"attack_style lance_charge")
	_check(a.get(&"attack_windup") != null and float(a.get(&"attack_windup")) == 0.0, "melee: attack_windup 0")
	_check(is_equal_approx(float(a.get(&"body_height")), 1.9), "body_height 1.9")
	_check(&"stride_speed" in a and &"_speed" in a, "stride_speed / _speed properties (Unit, test_4_g2)")
	var ut: Resource = load("res://data/units/blaze_rider.tres")
	_check(ut != null and (ut.get(&"model_scene") as PackedScene).resource_path == SCENE, "blaze_rider.tres still uses the scene")
	var src := FileAccess.get_file_as_string("res://art/units/fire/build_fire_units.gd")
	_check(not src.contains("_save(_blaze_rider()"), "the Fire builder no longer overwrites blaze_rider.tscn")
	# ---- hips on the seat
	var seat: Node3D = boar.call(&"seat_node")
	var hips: Node3D = rider.get_node("Root/Hips")
	var hd := hips.global_position.distance_to(seat.global_position)
	print("hips to seat %.3f m" % hd)
	_check(hd < 0.12, "the rider's hips sit on the boar's Seat (%.3f)" % hd)
	# ---- budgets
	var rb: Node3D = b.call(&"rider_model")
	var bb: Node3D = b.call(&"mount_model")
	var parts := int(rb.call(&"authored_mesh_count"))
	var inst := _draw_instances(rb)
	var b_inst := _draw_instances(bb)
	var lights := b.find_children("*", "Light3D", true, false).size()
	var ps: Array = b.find_children("*", "GPUParticles3D", true, false)
	var p_amount := 0
	for p: Node in ps:
		p_amount = maxi(p_amount, (p as GPUParticles3D).amount)
	var verts := _vertices(rb)
	print("rider budget: parts %d, draw instances %d, vertices %d, lights %d, particle systems %d (max %d); boar instances %d" % [
		parts, inst, verts, lights, ps.size(), p_amount, b_inst])
	for g: Node in rb.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh:
			print("  %s: %d surfaces, %d vertices" % [rb.get_path_to(mi), mi.mesh.get_surface_count(), _mesh_verts(mi.mesh)])
	_check(int(rider.call(&"authored_mesh_count")) == parts, "authored count equal for the cached instance")
	_check(parts <= 20, "rider parts %d <= 20" % parts)
	_check(inst <= 12, "rider draw instances %d <= 12" % inst)
	_check(b_inst <= 8, "boar draw instances unchanged (%d <= 8)" % b_inst)
	_check(lights == 0, "0 lights")
	_check(ps.size() <= 1 and p_amount <= 10, "<= 1 particle system of <= 10")
	_check(verts <= 12000, "rider vertices %d <= 12000" % verts)
	# ---- materials: the kit's Fire palette only
	for mat: Material in _materials(rb):
		_check(mat.resource_path.begins_with("res://art/units/kit/materials/") or FaceProbe.is_face_mat(mat),
			"material %s from the kit palette (or the face)" % mat.resource_path)
	# ---- size
	var hb := b.get_parent() as Node3D
	var lance := rb.get_node("Root/Chest/ArmR/Lance") as MeshInstance3D
	var body := _vert_bounds(rb, hb, [lance])
	var tip: Vector3 = hb.to_local(b.call(&"get_lance_tip"))
	print("rider body y %.2f..%.2f, x %.2f..%.2f; lance tip %s" % [body.position.y, body.end.y, body.position.x,
		body.end.x, tip])
	_check(body.end.y >= 2.2 and body.end.y <= 2.8, "rider on top 2.2-2.8 m (%.2f)" % body.end.y)
	_check(body.position.y > 0.45, "rider off the ground (feet at %.2f)" % body.position.y)
	_check(tip.y > body.end.y + 0.4 and tip.z > 1.0, "lance carried raised forward (tip %s)" % tip)
	# ---- walk vs gallop from set_moving
	lance = rider.get_node("Root/Chest/ArmR/Lance") as MeshInstance3D   # a's lance from here on
	var pitch_rest := float(a.call(&"lance_pitch"))
	var pennon := rider.get_node("Root/Chest/ArmR/Lance/Pennon") as Node3D
	var pen_rest := pennon.rotation.x
	a.call(&"set_moving", 1.7)
	await _wait(1.2)
	var g_walk := float(a.call(&"gallop_blend"))
	_check(is_equal_approx(float(a.get(&"_speed")), 1.7), "_speed mirrors set_moving")
	a.call(&"set_moving", GALLOP)
	await _wait(1.0)
	var y_min := 99.0
	var y_max := -99.0
	var pen_max := 0.0
	var p_gal := 0.0
	for i: int in 60:
		await process_frame
		y_min = minf(y_min, hips.global_position.y)
		y_max = maxf(y_max, hips.global_position.y)
		pen_max = maxf(pen_max, pennon.rotation.x)
		p_gal += float(a.call(&"lance_pitch")) / 60.0
	var g_gal := float(a.call(&"gallop_blend"))
	print("gait: walk gallop %.2f, gallop %.2f, rider bob %.3f m, lance pitch rest %.1f -> gallop %.1f, pennon %.1f -> %.1f deg" % [
		g_walk, g_gal, y_max - y_min, pitch_rest, p_gal, rad_to_deg(pen_rest), rad_to_deg(pen_max)])
	_check(g_walk < 0.2, "walks at 1.7 m/s")
	_check(g_gal > 0.8 and bool(a.call(&"is_galloping")), "gallops at 7.5 m/s")
	_check(y_max - y_min > 0.04, "the rider bobs with the gallop")
	_check(pitch_rest < -40.0 and p_gal > pitch_rest + 10.0 and p_gal < -15.0, "the lance lowers at the gallop")
	_check(pen_max > pen_rest + deg_to_rad(20.0), "the pennon streams back at the gallop")
	# ---- attack at the gallop: couch, strike level ahead, the boar tosses
	var struck: Array = []
	a.connect(&"lance_struck", func(at: Vector3) -> void: struck.append(at))
	var holder := a.get_parent() as Node3D
	a.call(&"play_attack")
	await process_frame
	_check(boar.get(&"_action") == &"attack", "the boar tosses with the attack")
	var couch_max := 0.0
	for f: int in 7:   # to ~0.12 s
		await process_frame
		couch_max = maxf(couch_max, float(a.call(&"couch_amount")))
	var ld := _lance_dir(lance, holder)
	print("attack: couch %.2f, lance dir %s, struck %d %s" % [couch_max, ld, struck.size(),
		[holder.to_local(struck[0])] if struck.size() > 0 else []])
	_check(couch_max > 0.9, "lance couched at the strike")
	_check(ld.z > 0.9 and ld.y < 0.1 and ld.y > -0.3, "the lance points level ahead at the strike (%s)" % ld)
	await _wait(0.05)
	_check(struck.size() == 1 and holder.to_local(struck[0]).z > 2.0, "one lance_struck ahead of the boar")
	await _wait(0.8)
	_check(float(a.call(&"couch_amount")) == 0.0 and float(a.call(&"lance_pitch")) < -15.0, "back to the carried lance")
	# ---- the charge at the gallop
	var charged: Array = []
	a.connect(&"charge_struck", func(at: Vector3) -> void: charged.append(at))
	var lance_g0 := float(lance.get_instance_shader_parameter(&"glow_boost"))
	var boar_glow: GeometryInstance3D = null
	for g: GeometryInstance3D in boar.get(&"_glow_nodes"):
		boar_glow = g
		break
	var bg0 := float(boar_glow.get_instance_shader_parameter(&"glow_boost")) if boar_glow else 0.0
	a.call(&"play_charge")
	_check(bool(a.call(&"is_charging")), "is_charging after play_charge")
	await process_frame
	_check(boar.get(&"_action") == &"charge", "the boar charges (MountModel.play_charge)")
	await _wait(0.13)
	var n_hit := charged.size()
	await _wait(0.12)
	var ld2 := _lance_dir(lance, holder)
	var cc := float(a.call(&"couch_amount"))
	var lance_g1 := float(lance.get_instance_shader_parameter(&"glow_boost"))
	var bg1 := float(boar_glow.get_instance_shader_parameter(&"glow_boost")) if boar_glow else 0.0
	var chest_x := rad_to_deg((rider.get_node("Root/Chest") as Node3D).rotation.x)
	print("charge: struck %d at %s, couch %.2f, lance dir %s, lance glow %.2f -> %.2f, mane glow %.2f -> %.2f, chest lean %.1f" % [
		n_hit, [holder.to_local(charged[0])] if n_hit > 0 else [], cc, ld2, lance_g0, lance_g1, bg0, bg1, chest_x])
	_check(n_hit == 1 and holder.to_local(charged[0]).z > 2.0, "charge_struck once at the hit frame, ahead")
	_check(cc > 0.9 and ld2.z > 0.95 and absf(ld2.y) < 0.15, "charge: the lance couched level (%s)" % ld2)
	_check(lance_g1 > lance_g0 * 1.5, "charge: the lance head flares")
	_check(boar_glow != null and bg1 > bg0 * 1.3, "charge: the boar's mane flares")
	_check(chest_x > 12.0, "charge: the rider leans in (%.1f)" % chest_x)
	await _wait(0.8)
	_check(not bool(a.call(&"is_charging")) and float(a.call(&"couch_amount")) == 0.0, "charge over after 0.85 s")
	_check(charged.size() == 1, "one charge_struck per charge")
	a.call(&"set_moving", 0.0)
	await _wait(1.0)
	# ---- hit flash on rider and boar
	a.call(&"play_hit")
	await _wait(0.05)
	var f_r := float((rider.get_node("Root/Chest/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	var f_b := float((boar.get_node("Root/Mount/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	print("hit flash rider %.2f, boar %.2f" % [f_r, f_b])
	_check(f_r > 0.3 and f_b > 0.3, "rider and boar flash on hits")
	await _wait(0.4)
	# ---- team colour: cloth / cape / pennon take it
	var blue := Color(0.45, 0.75, 0.95)
	b.call(&"set_team_color", blue)
	await process_frame
	var cmi := rb.get_node("Root/Chest/Merged") as MeshInstance3D
	var got := false
	var only_team := true
	for s: int in cmi.mesh.get_surface_count():
		var ov := cmi.get_surface_override_material(s) as ShaderMaterial
		if ov:
			var bn := cmi.mesh.surface_get_material(s).resource_path.get_file().get_basename()
			if not (bn.ends_with("_cloth") or bn.ends_with("_cloth_dark") or bn.ends_with("_cape")):
				only_team = false
			if ov.get_shader_parameter(&"base_color") == blue or ov.get_shader_parameter(&"cloth_color") == blue:
				got = true
	var pmi := rb.get_node("Root/Chest/ArmR/Lance/Pennon") as MeshInstance3D
	var pov := pmi.get_surface_override_material(0) as ShaderMaterial
	_check(got and only_team, "the tabard / pauldrons / cape take the team colour (team surfaces only)")
	_check(pov != null and pov.get_shader_parameter(&"cloth_color") == blue, "the pennon takes the team colour")
	# ---- kit slot audit (KITFIX rules) on rider + boar
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for owner: Node3D in [rider, boar]:
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
	# ---- veterancy, statuses, cast, barding
	var vet := rider.get_node("Root/Chest/Head/VetTrim") as Node3D
	_check(not vet.visible, "vet trim hidden below level 4")
	a.call(&"play_level_up")
	a.call(&"set_veterancy", 4)
	_check(vet.visible, "vet trim shown at level 4")
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	a.call(&"play_cast", &"salute")
	a.call(&"set_barded", true)
	await _wait(0.3)
	var p_cast := float(a.call(&"lance_pitch"))
	await _wait(0.6)
	_check(p_cast < -70.0, "cast: the lance raised in salute (%.1f)" % p_cast)
	_check(bool(a.call(&"is_barded")), "barding on the boar")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_barded", false)
	a.call(&"set_carrying", true)
	# ---- death: the rider rides the boar's fall and burns; revive re-seats
	var done: Array = [false]
	a.connect(&"death_finished", func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	a.call(&"set_moving", GALLOP)
	await _wait(0.3)
	var embers := rider.get_node("Root/Chest/BurnEmbers") as GPUParticles3D
	a.call(&"play_death")
	await _wait(0.6)
	var hd2 := hips.global_position.distance_to(seat.global_position)
	var gl_dead := float(lance.get_instance_shader_parameter(&"glow_boost"))
	print("death 0.6 s: hips to seat %.2f, seat y %.2f, lance glow %.2f, embers %s" % [hd2, seat.global_position.y,
		gl_dead, rider.get(&"_burn_fired")])
	_check(hd2 < 0.25, "the rider rides the boar's fall")
	_check(gl_dead == 0.0, "the lance head goes dark")
	_check(bool(rider.get(&"_burn_fired")) and (rider.get(&"_burn_fx") as Array).has(embers), "the burn embers are fired (FireModel burn)")
	await _wait(0.7)
	_check(done[0], "death_finished within 1.3 s")
	a.call(&"revive")
	await _wait(0.4)
	_check(bool(rider.call(&"is_seated")) and hips.global_position.distance_to(seat.global_position) < 0.12,
		"revive: seated again")
	_check(float(a.call(&"lance_pitch")) < -40.0 and float(lance.get_instance_shader_parameter(&"glow_boost")) > 0.5,
		"revive: lance carried, head glowing")
	# ---- hooks before _ready
	var e := _spawn(Vector3(-20, 0, 8), 0.0, func(m: Node3D) -> void:
		m.call(&"set_team_color", Color(0.85, 0.30, 0.12))
		m.call(&"set_moving", GALLOP))
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


## The lance shaft direction (+Z of the Lance node) in the holder's frame.
func _lance_dir(lance: Node3D, holder: Node3D) -> Vector3:
	return (holder.global_transform.basis.inverse() * lance.global_transform.basis.z).normalized()


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


## Exact bounds of every visible vertex in `frame` space, skipping the blob and the `skip` nodes (and their children).
func _vert_bounds(n: Node, frame: Node3D, skip: Array) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow" or not mi.is_visible_in_tree():
			continue
		var skipped := false
		for sk: Node in skip:
			if mi == sk or sk.is_ancestor_of(mi):
				skipped = true
		if skipped:
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := xf * v
				lo = lo.min(w)
				hi = hi.max(w)
	return AABB(lo, hi - lo)
