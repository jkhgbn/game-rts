extends SceneTree
## Task 13.V5: the Grove Stag, Nature hero mount (art/units/mounts/grove_stag/grove_stag.tscn) on the MountModel kit.
## Run: $GODOT --headless --path . -s tests/test_13_v5.gd --fixed-fps 60 --quit-after 3000
## Checks: instantiation (2 instances: build + cache), class, pivots (Neck, no Tail) + Seat, hooks, section 10 mount budget
## (<= 12 authored meshes incl. the blob, <= 8 draw instances plain AND barded, 0 lights, 0 particles), vertices,
## materials (own <= 3, the rest Nature / kit palette), THE READ (wide low rack >= 2.2 m, 3 glowing blossoms: left palm,
## brow, right palm), size, seat, walk vs gallop, the neck carrying the head, hit flash, charge (rack levelled, lunge,
## toss, blossom flare), fidget, barding (woven bark on Body / Neck / Head, no extra draw instance, before _ready too),
## team colour (cloth only, survives the swap, restores), kit slot audit, death (side roll, head propped: nothing sunk,
## withers, death_finished), revive, and the difference from the Hollow Stag / red deer (colour, rack shape, size).
## Prints "PASS 13.v5" or "FAIL 13.v5: <reasons>".

const TASK_ID := "13.v5"
const SCENE := "res://art/units/mounts/grove_stag/grove_stag.tscn"
const OWN_DIR := "res://art/units/mounts/grove_stag/"
## Faces pass 2026-09-28: the shared FaceKit face material (eyes / brows / lips, 1 draw call) + glow probe.
const FaceProbe := preload("res://tests/face_probe.gd")
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const HOLLOW := "res://art/units/neutral/hollow_stag/hollow_stag.tscn"
const DEER := "res://art/units/neutral/critters/deer.tscn"

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()   # tier 0 (close) so the full animation runs
	cam.position = Vector3(0, 6, 10)
	_world.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(at: Vector3, barded_before_ready: bool = false, path: String = SCENE) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(path) as PackedScene).instantiate()
	if barded_before_ready:
		m.call(&"set_barded", true)
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(5, 0, 0))
	await _wait(0.2)
	_check(a is MountModel and a is CharacterModel, "extends MountModel (a CharacterModel)")
	# ---- pivots + hooks
	for p: String in ["Root", "Root/Mount", "Root/Mount/Neck", "Root/Mount/Head", "Root/Mount/LegFL", "Root/Mount/LegFR",
			"Root/Mount/LegBL", "Root/Mount/LegBR", "Root/Mount/Seat", "Fx", "Shadow"]:
		_check(a.get_node_or_null(p) != null, "node %s" % p)
	for h: String in ["set_moving", "play_hit", "play_death", "set_team_color", "set_barded", "is_barded", "play_charge",
			"seat_transform", "seat_node", "gait_phase", "gallop_blend", "is_galloping", "play_fidget", "authored_mesh_count",
			"play_attack", "play_cast", "play_level_up", "set_veterancy", "set_status", "revive"]:
		_check(a.has_method(h), "hook %s" % h)
	_check(a.has_signal(&"death_finished"), "signal death_finished")
	# ---- budgets
	var authored_a: int = int(a.call(&"authored_mesh_count"))
	var authored_b: int = int(b.call(&"authored_mesh_count"))
	print("authored meshes: %d / %d" % [authored_a, authored_b])
	_check(authored_a == authored_b, "authored count is the same for the cached instance")
	_check(authored_a >= 6 and authored_a <= 12, "authored meshes <= 12 (got %d)" % authored_a)
	var plain_inst := _draw_instances(b)
	var plain_verts := _vertices(b)
	var surfaces := 0
	print("plain: draw instances %d, vertices %d, lights %d, particles %d" % [plain_inst, plain_verts,
		b.find_children("*", "Light3D", true, false).size(), b.find_children("*", "GPUParticles3D", true, false).size()])
	_check(plain_inst <= 8, "draw instances <= 8 (got %d)" % plain_inst)
	# 7000 + the face (faces pass 2026-09-28: measured 7057 with the face in the head; small margin).
	_check(plain_verts <= 7250, "vertices <= 7250 = 7000 + face (got %d)" % plain_verts)
	_check(b.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	_check(b.find_children("*", "GPUParticles3D", true, false).is_empty(), "0 particle systems")
	for g: Node in b.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh:
			surfaces += mi.mesh.get_surface_count()
			print("  %s: %d surfaces, %d vertices, shadow %s" % [b.get_path_to(mi), mi.mesh.get_surface_count(),
				_mesh_verts(mi.mesh), mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	print("surfaces: ", surfaces)
	# ---- materials: own <= 3, the rest from the Nature / kit palettes
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
	_check(own.size() <= 3, "<= 3 own materials")
	# ---- size (rest) and the read
	var box := _vert_bounds(b, b.get_parent() as Node3D)
	var body_box := _vert_bounds(b.get_node("Root/Mount/Merged"), b.get_parent() as Node3D)
	var head_box := _vert_bounds(b.get_node("Root/Mount/Head/Merged"), b.get_parent() as Node3D)
	print("rest bounds y %.2f..%.2f, x %.2f..%.2f, z %.2f..%.2f; body top %.2f; rack x %.2f..%.2f" % [box.position.y,
		box.end.y, box.position.x, box.end.x, box.position.z, box.end.z, body_box.end.y, head_box.position.x, head_box.end.x])
	_check(box.position.y >= -0.01, "nothing below the ground at rest (%.3f)" % box.position.y)
	_check(box.end.y >= 2.5 and box.end.y <= 3.05, "rack top 2.5-3.05 m (%.2f)" % box.end.y)
	_check(box.size.z >= 2.4 and box.size.z <= 3.4, "length 2.4-3.4 m (%.2f)" % box.size.z)
	_check(body_box.end.y >= 1.55 and body_box.end.y <= 1.95, "withers / saddle 1.55-1.95 m (%.2f)" % body_box.end.y)
	_check(head_box.size.x >= 2.2 and head_box.size.x <= 2.8, "WIDE rack 2.2-2.8 m across (%.2f)" % head_box.size.x)
	_check(head_box.size.x > (box.end.y - 2.0) * 2.0, "the rack is wider than it is tall (low and wide, not a tree)")
	# three glowing blossoms: left palm, brow, right palm
	var head_mi := b.get_node("Root/Mount/Head/Merged") as MeshInstance3D
	var bloom_x: Array = [0, 0, 0]
	var glow_surfaces := 0
	for s: int in head_mi.mesh.get_surface_count():
		var mt := head_mi.mesh.surface_get_material(s)
		if mt and mt.resource_path.ends_with("grove_stag_bloom.tres"):
			glow_surfaces += 1
			for v: Vector3 in (head_mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w: Vector3 = head_mi.transform * v
				bloom_x[0 if w.x < -0.45 else (2 if w.x > 0.45 else 1)] += 1
	print("blossom petals: glow surfaces %d, vertices left / centre / right %s" % [glow_surfaces, bloom_x])
	_check(glow_surfaces == 1, "one blossom glow surface on the head")
	_check(bloom_x[0] > 50 and bloom_x[1] > 50 and bloom_x[2] > 50, "3 blossoms: left palm, brow, right palm")
	_check(absf(float(bloom_x[0]) - float(bloom_x[2])) < 5.0, "palm blossoms symmetric")
	var body_mi := b.get_node("Root/Mount/Merged") as MeshInstance3D
	var glow_elsewhere := 0
	for mi: MeshInstance3D in [body_mi, b.get_node("Root/Mount/Neck/Merged") as MeshInstance3D]:
		for s: int in mi.mesh.get_surface_count():
			var sh := (mi.mesh.surface_get_material(s) as ShaderMaterial).shader
			if sh.resource_path.ends_with("unit_glow.gdshader"):
				glow_elsewhere += 1
	_check(glow_elsewhere == 0, "glow only in the blossoms (1-2 glow points at 40 m)")
	# ---- apart from the Hollow Stag and the red deer
	await _compare_neighbours(b, box, head_box)
	# ---- seat
	var seat: Transform3D = b.call(&"seat_transform")
	var seat_node: Node3D = b.call(&"seat_node")
	var rel := b.global_transform.affine_inverse() * seat_node.global_transform
	print("seat (model space) ", seat.origin)
	_check(seat.origin.is_equal_approx(rel.origin), "seat_transform = the Seat marker in model space")
	_check(absf(seat.origin.x) < 0.01 and seat.origin.y > 1.5 and seat.origin.y < 1.8 and absf(seat.origin.z) < 0.4,
		"seat on the back (%s)" % seat.origin)
	_check(seat.basis.z.dot(Vector3.BACK) > 0.95, "seat faces +Z")
	# ---- walk vs gallop
	var leg: Node3D = a.get_node("Root/Mount/LegFL")
	var root_n: Node3D = a.get_node("Root")
	var head: Node3D = a.get_node("Root/Mount/Head")
	var neck: Node3D = a.get_node("Root/Mount/Neck")
	a.call(&"set_moving", 1.8)
	var max_leg := 0.0
	var max_g := 0.0
	for i: int in 60:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		max_g = maxf(max_g, float(a.call(&"gallop_blend")))
	print("walk: leg swing %.1f deg, gallop blend %.2f" % [rad_to_deg(max_leg), max_g])
	_check(max_leg > deg_to_rad(12.0), "the legs swing in the walk")
	_check(max_g < 0.3, "no gallop at walking speed")
	a.call(&"set_moving", 6.5)
	await _wait(0.8)
	var ymin := 99.0
	var ymax := -99.0
	var seat_min := 99.0
	var seat_max := -99.0
	var neck_rot := 0.0
	var head_hp0 := head.position
	var head_move := 0.0
	max_leg = 0.0
	var wraps := 0
	var last_p := float(a.call(&"gait_phase"))
	for i: int in 60:
		await process_frame
		ymin = minf(ymin, root_n.position.y)
		ymax = maxf(ymax, root_n.position.y)
		var st: Transform3D = a.call(&"seat_transform")
		seat_min = minf(seat_min, st.origin.y)
		seat_max = maxf(seat_max, st.origin.y)
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		neck_rot = maxf(neck_rot, absf(neck.rotation.x))
		head_move = maxf(head_move, head.position.distance_to(head_hp0))
		var p := float(a.call(&"gait_phase"))
		if p < last_p:
			wraps += 1
		last_p = p
	print("gallop: blend %.2f, bounce %.3f, seat bob %.3f, leg swing %.1f deg, strides/s %d, neck %.1f deg, head carried %.3f m" % [
		float(a.call(&"gallop_blend")), ymax - ymin, seat_max - seat_min, rad_to_deg(max_leg), wraps, rad_to_deg(neck_rot),
		head_move])
	_check(bool(a.call(&"is_galloping")), "gallops at 6.5 m/s")
	_check(ymax - ymin > 0.04, "gallop bounce")
	_check(seat_max - seat_min > 0.04, "the seat bobs with the gallop (rider sync)")
	_check(max_leg > deg_to_rad(25.0), "gallop leg swing > 25 deg")
	_check(wraps >= 1 and wraps <= 3, "1-3 strides per second (%d)" % wraps)
	_check(neck_rot > deg_to_rad(1.0) and head_move > 0.005, "the head rides on the swinging neck")
	a.call(&"set_moving", 0.0)
	await _wait(0.8)
	_check(absf(leg.rotation.x) < deg_to_rad(3.0), "legs back at rest after stopping")
	_check(float(a.call(&"gallop_blend")) < 0.2, "gallop blend falls when stopped")
	# ---- hit
	var a_body := a.get_node("Root/Mount/Merged") as MeshInstance3D
	var a_head := a.get_node("Root/Mount/Head/Merged") as MeshInstance3D
	a.call(&"play_hit")
	await _wait(0.05)
	var flash := float(a_body.get_instance_shader_parameter(&"hit_flash"))
	var leg_flash := float((a.get_node("Root/Mount/LegFL/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	var neck_flash := float((a.get_node("Root/Mount/Neck/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	print("hit: body flash %.2f, leg %.2f, neck %.2f, root z %.3f" % [flash, leg_flash, neck_flash, root_n.position.z])
	_check(flash > 0.15 and leg_flash > 0.15 and neck_flash > 0.15, "the whole beast flashes on a hit")   # mounts flash at <= 0.4 since G-F review 3 (MountModel.MOUNT_FLASH_MAX)
	_check(root_n.position.z < -0.03, "hit flinch pushes back")
	await _wait(0.5)
	# ---- charge
	var glow0 := float(a_head.get_instance_shader_parameter(&"glow_boost"))
	a.call(&"play_charge")
	await _wait(0.10)
	var hx := head.rotation.x
	var glow1 := float(a_head.get_instance_shader_parameter(&"glow_boost"))
	await _wait(0.05)
	var rz := root_n.position.z
	await _wait(0.15)
	var hx_toss := head.rotation.x
	print("charge: head %.1f deg (rack levelled), lunge z %.2f, toss %.1f deg, blossom glow %.2f -> %.2f" % [rad_to_deg(hx),
		rz, rad_to_deg(hx_toss), glow0, glow1])
	_check(a.get(&"_action") == &"charge", "charge action running")
	_check(hx > deg_to_rad(15.0), "the head drops to level the rack")
	_check(rz > 0.2, "the charge lunges forward")
	_check(hx_toss < deg_to_rad(-10.0), "toss after the strike")
	_check(glow1 > glow0 + 0.3, "the blossoms flare on the charge")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "charge finished")
	a.call(&"play_attack")
	await _wait(0.6)
	_check(a.get(&"_action") == &"", "mount_toss attack finished")
	a.call(&"play_cast", &"fireball")
	await _wait(0.7)
	# ---- fidget (graze and toss)
	var nx0 := neck.rotation.x
	a.call(&"play_fidget")
	await _wait(0.7)
	var nx_graze := neck.rotation.x
	print("fidget: neck %.1f -> %.1f deg (grazing)" % [rad_to_deg(nx0), rad_to_deg(nx_graze)])
	_check(a.get(&"_action") == &"fidget", "fidget runs")
	_check(nx_graze > nx0 + deg_to_rad(20.0), "the fidget lowers the neck to graze")
	await _wait(1.0)
	var flare_fid := float(a_head.get_instance_shader_parameter(&"glow_boost"))
	_check(flare_fid > glow0 + 0.2, "the toss snort flares the blossoms (%.2f)" % flare_fid)
	a.call(&"set_moving", 2.0)
	await _wait(0.1)
	_check(a.get(&"_action") == &"", "moving cancels the fidget")
	a.call(&"set_moving", 0.0)
	await _wait(0.6)
	# ---- barding
	var plain_body: Mesh = body_mi.mesh
	var plain_neck: Mesh = (b.get_node("Root/Mount/Neck/Merged") as MeshInstance3D).mesh
	var plain_head: Mesh = head_mi.mesh
	var plain_leg: Mesh = (b.get_node("Root/Mount/LegFL/Merged") as MeshInstance3D).mesh
	b.call(&"set_barded", true)
	await process_frame
	var barded_inst := _draw_instances(b)
	var barded_verts := _vertices(b)
	print("barded: draw instances %d, vertices %d, body surfaces %d -> %d" % [barded_inst, barded_verts,
		plain_body.get_surface_count(), body_mi.mesh.get_surface_count()])
	_check(bool(b.call(&"is_barded")), "is_barded")
	_check(body_mi.mesh != plain_body and _mesh_verts(body_mi.mesh) > _mesh_verts(plain_body), "barded body (woven plates)")
	_check((b.get_node("Root/Mount/Neck/Merged") as MeshInstance3D).mesh != plain_neck, "barded neck (crinet)")
	_check(head_mi.mesh != plain_head, "barded head (chanfron)")
	_check((b.get_node("Root/Mount/LegFL/Merged") as MeshInstance3D).mesh == plain_leg, "legs unchanged")
	_check(barded_inst == plain_inst, "barding adds no draw instance")
	_check(barded_verts <= 10000, "barded vertices <= 10000 (got %d)" % barded_verts)
	var bark_n := 0
	for s: int in body_mi.mesh.get_surface_count():
		var mt := body_mi.mesh.surface_get_material(s)
		if mt and (mt.resource_path.ends_with("nature_bark.tres") or mt.resource_path.ends_with("nature_bark_dark.tres")):
			bark_n += _surf_verts(body_mi.mesh, s)
	var bark_plain := 0
	for s: int in plain_body.get_surface_count():
		var mt := plain_body.surface_get_material(s)
		if mt and (mt.resource_path.ends_with("nature_bark.tres") or mt.resource_path.ends_with("nature_bark_dark.tres")):
			bark_plain += _surf_verts(plain_body, s)
	_check(bark_n > bark_plain + 500, "barding = woven bark (bark / dark bark) plates")
	var head_glow_barded := false
	for s: int in head_mi.mesh.get_surface_count():
		var mt := head_mi.mesh.surface_get_material(s)
		if mt and mt.resource_path.ends_with("grove_stag_bloom.tres"):
			head_glow_barded = true
	_check(head_glow_barded and (b.get(&"_glow_nodes") as Array).has(head_mi), "blossoms still glow when barded")
	var c := _spawn(Vector3(10, 0, 0), true)
	await _wait(0.1)
	_check((c.get_node("Root/Mount/Merged") as MeshInstance3D).mesh == body_mi.mesh, "set_barded before _ready applies (cached variant)")
	# ---- team colour: cloth only, survives the barding swap, restores
	var red := Color(0.85, 0.30, 0.12)
	b.call(&"set_team_color", red)
	await process_frame
	var cloth_red := _cloth_colors(body_mi)
	print("team colour on the barded body: ", cloth_red)
	_check(cloth_red.size() == 2, "cloth + cloth_dark recoloured")
	_check(red in cloth_red, "saddle-cloth takes the team colour")
	b.call(&"set_barded", false)
	await process_frame
	_check(body_mi.mesh == plain_body, "unbarded: back to the plain mesh")
	_check(red in _cloth_colors(body_mi), "team colour survives the barding swap")
	var others_ok := true
	for mi: MeshInstance3D in [body_mi, head_mi, b.get_node("Root/Mount/Neck/Merged") as MeshInstance3D]:
		for s: int in mi.mesh.get_surface_count():
			var ov := mi.get_surface_override_material(s)
			var base := mi.mesh.surface_get_material(s)
			if ov and not (base.resource_path.ends_with("_cloth.tres") or base.resource_path.ends_with("_cloth_dark.tres")):
				others_ok = false
	_check(others_ok, "only cloth surfaces are recoloured")
	b.call(&"set_team_color", Color(0.35, 0.70, 0.25))
	await process_frame
	var any_override := false
	for s: int in body_mi.mesh.get_surface_count():
		if body_mi.get_surface_override_material(s) != null:
			any_override = true
	_check(not any_override, "the kingdom colour restores the scene's own cloth")
	# ---- kit slot audit (KITFIX rules) on every geometry of a plain and a barded stag
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for mm: Node3D in [a, c]:
		for g: Node in mm.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if gi == mm.get(&"_shadow"):
				continue
			var by_slot: Dictionary = {}
			var names: Array[String] = []
			for mat: Material in mm.call(&"_materials_of", gi):
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
				_check((mm.get(&"_flash_all_targets") as Array).has(gi), "%s flashed by the kit" % mm.get_path_to(gi))
			if names.has("glow_boost"):
				_check((mm.get(&"_glow_nodes") as Array).has(gi), "%s glow driven by the kit" % mm.get_path_to(gi))
	print("slot collisions: ", collisions)
	_check(collisions == 0, "no instance-uniform slot collision")
	# ---- death: rolls onto its side, head propped (nothing sunk), withers, death_finished; revive
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	a.call(&"set_moving", 6.0)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(0.4)
	var roll_mid := root_n.rotation.z
	await _wait(0.65)
	var roll_end := root_n.rotation.z
	var lying := _vert_bounds(a, a.get_parent() as Node3D)
	var wither := float(a_body.get_instance_shader_parameter(&"hit_flash"))
	var bloom_boost := float(a_head.get_instance_shader_parameter(&"glow_boost"))
	print("death: roll %.1f -> %.1f deg, lying bounds y %.2f..%.2f, wither %.2f, blossoms %.2f, finished %s" % [
		rad_to_deg(roll_mid), rad_to_deg(roll_end), lying.position.y, lying.end.y, wither, bloom_boost, got[0]])
	_check(absf(roll_end) > deg_to_rad(75.0), "falls onto its side")
	_check(lying.position.y > -0.2, "lies on the ground, the rack not buried (%.2f)" % lying.position.y)
	_check(lying.end.y < 2.0, "lying low (%.2f)" % lying.end.y)
	_check(wither > 0.08, "the moss withers")
	_check(bloom_boost < 0.05, "the blossoms go out")
	_check(got[0], "death_finished within 1.05 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.rotation.z) < 0.03 and absf(root_n.position.y) < 0.05, "revive resets the pose")
	_check(absf(head.rotation.z) < 0.05, "revive resets the head")
	_check(float(a_body.get_instance_shader_parameter(&"hit_flash")) < 0.05, "revive clears the wither")
	a.call(&"play_level_up")
	a.call(&"set_veterancy", 3)
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	await _wait(0.3)
	a.call(&"set_status", &"haste", false)
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## The Grove Stag vs the Hollow Stag (pale, tall branch antlers) and the red deer (small, red-brown): coat value,
## rack proportions, size.
func _compare_neighbours(stag: Node3D, box: AABB, rack: AABB) -> void:
	var hide_col: Color = (load(OWN_DIR + "materials/grove_stag_hide.tres") as ShaderMaterial).get_shader_parameter(&"base_color")
	if ResourceLoader.exists(HOLLOW):
		var h := _spawn(Vector3(-6, 0, 0), false, HOLLOW)
		await _wait(0.1)
		var hb := _vert_bounds(h, h.get_parent() as Node3D)
		print("hollow stag bounds: top %.2f, width %.2f, length %.2f (grove: top %.2f, rack %.2f, length %.2f)" % [hb.end.y,
			hb.size.x, hb.size.z, box.end.y, rack.size.x, box.size.z])
		_check(box.end.y < hb.end.y - 0.2, "rack lower than the Hollow Stag's tree antlers")
		_check(rack.size.x / (box.end.y - 1.9) > hb.size.x / (hb.end.y - 1.9), "rack flatter / wider than the Hollow Stag's")
		_check(hide_col.get_luminance() < 0.4, "dark mossy coat (the Hollow Stag is pale)")
		h.get_parent().queue_free()
	if ResourceLoader.exists(DEER):
		var d := _spawn(Vector3(-10, 0, 0), false, DEER)
		await _wait(0.1)
		var db := _vert_bounds(d, d.get_parent() as Node3D)
		print("red deer bounds: top %.2f, width %.2f, length %.2f" % [db.end.y, db.size.x, db.size.z])
		_check(rack.size.x > db.size.x * 1.8, "rack much wider than the deer's")
		_check(box.size.z > db.size.z * 1.1, "bigger than the red deer")
		_check(absf(hide_col.h - 0.05) > 0.03 or hide_col.s < 0.4, "not the deer's red-brown")
		d.get_parent().queue_free()


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


func _surf_verts(mesh: Mesh, s: int) -> int:
	return (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()


func _mesh_verts(mesh: Mesh) -> int:
	var c := 0
	for s: int in mesh.get_surface_count():
		c += _surf_verts(mesh, s)
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
			var col: Color = ov.get_shader_parameter(&"base_color")
			if not (col in out):
				out.append(col)
	return out


func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out


## Exact bounds of every vertex (blob skipped) of n and its children, in `frame` space.
func _vert_bounds(n: Node, frame: Node3D) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	var list: Array = n.find_children("*", "MeshInstance3D", true, false)
	if n is MeshInstance3D:
		list.append(n)
	for g: Node in list:
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
