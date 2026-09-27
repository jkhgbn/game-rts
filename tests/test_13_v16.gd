extends SceneTree
## Tasks 13.V16 (War Mammoth body) + 13.V17 (howdah + frost archer): art/units/titans/war_mammoth/.
## Run: $GODOT --headless --path . -s tests/test_13_v16.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation (2 mammoths: build + cache, and a standalone howdah), class, pivots (trunk x2, Seat,
## howdah child scene with its archer pivots and frame), hooks, the titan budget of cavalry-mounts.md 10 (<= 36 meshes,
## <= 20 draw instances, 0 lights, <= 2 particle systems), materials (own <= 6, the rest Ice / kit palette), size and the
## tusk read (tips far ahead and wide), frost mist (looping, world space, stops beyond 45 m and on death), the heavy
## walk (legs, trunk swing, never a gallop, the howdah rides the back), play_trample (leg lift, tusk sweep alternating,
## trample_stomped once at 0.2 s), tusk gore attack (rear then drive, release), hit flash (beast + howdah), the howdah
## shot (turns to a target, pitches up at a flyer, draws the string, shot_released once at 0.12 s, the arrow leaves and
## is re-nocked), team colour (blanket, banner, archer; restores), the kit slot audit, death (rolls on its side, lies on
## the ground, frosts, the archer slumps, death_finished) and revive, transparency fade.
## Prints "PASS 13.v16" or "FAIL 13.v16: <reasons>".

const TASK_ID := "13.v16"
const SCENE := "res://art/units/titans/war_mammoth/war_mammoth.tscn"
const HOWDAH := "res://art/units/titans/war_mammoth/howdah.tscn"
const OWN_DIR := "res://art/units/titans/war_mammoth/"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"

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


func _spawn(at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	_check(ResourceLoader.exists(HOWDAH), "howdah scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(8, 0, 0))
	await _wait(0.2)
	_check(a is MountModel and a is CharacterModel, "extends MountModel (a CharacterModel)")
	var h: Node3D = a.call(&"get_howdah")
	_check(h != null and h is CharacterModel, "howdah child scene (a CharacterModel)")
	if h == null:
		_finish()
		return
	# ---- pivots + hooks
	for p: String in ["Root", "Root/Mount", "Root/Mount/Head", "Root/Mount/Head/Trunk", "Root/Mount/Head/Trunk/Trunk2",
			"Root/Mount/LegFL", "Root/Mount/LegFR", "Root/Mount/LegBL", "Root/Mount/LegBR", "Root/Mount/Tail",
			"Root/Mount/Seat", "Root/Mount/Seat/Howdah", "Root/Mount/Seat/Howdah/Frame", "Root/Mount/Seat/Howdah/Root/Chest",
			"Root/Mount/Seat/Howdah/Root/Chest/Head", "Root/Mount/Seat/Howdah/Root/Chest/ArmL",
			"Root/Mount/Seat/Howdah/Root/Chest/ArmR", "Fx", "Fx/FrostMist", "Shadow"]:
		_check(a.get_node_or_null(p) != null, "node %s" % p)
	_check(a.get_node_or_null("Root/Mount/Head/Trunk/Merged") != null and a.get_node_or_null("Root/Mount/Head/Trunk/Trunk2/Merged") != null,
		"trunk segments merged into their own nodes")
	for hk: String in ["set_moving", "play_attack", "play_hit", "play_death", "set_team_color", "set_status", "revive",
			"play_trample", "play_howdah_shot", "get_howdah", "get_howdah_muzzle", "play_cast", "play_level_up", "set_veterancy",
			"seat_node", "set_barded"]:
		_check(a.has_method(hk), "hook %s" % hk)
	_check(a.has_signal(&"death_finished") and a.has_signal(&"trample_stomped"), "signals death_finished, trample_stomped")
	for hk: String in ["play_howdah_shot", "get_muzzle", "has_arrow", "set_team_color", "play_hit", "play_death", "revive"]:
		_check(h.has_method(hk), "howdah hook %s" % hk)
	_check(h.has_signal(&"shot_released"), "howdah signal shot_released")
	_check(float(a.get(&"attack_windup")) <= 0.15, "attack_windup <= 0.15")
	# ---- budgets (the whole titan: mammoth + howdah)
	var hb: Node3D = b.call(&"get_howdah")
	var meshes: int = int(b.call(&"authored_mesh_count")) + _authored_howdah(hb)
	var inst := _draw_instances(b)
	var verts := _vertices(b)
	var lights := b.find_children("*", "Light3D", true, false).size()
	var parts := b.find_children("*", "GPUParticles3D", true, false).size()
	print("budget: meshes %d, draw instances %d, vertices %d, lights %d, particle systems %d" % [meshes, inst, verts, lights, parts])
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var mi := gi as MeshInstance3D
			print("  %s: %d surfaces, %d vertices, shadow %s" % [b.get_path_to(mi), mi.mesh.get_surface_count(),
				_mesh_verts(mi.mesh), mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	_check(int(a.call(&"authored_mesh_count")) == int(b.call(&"authored_mesh_count")), "authored count equal for the cached instance")
	_check(meshes <= 36, "meshes %d <= 36" % meshes)
	_check(inst <= 20, "draw instances %d <= 20" % inst)
	_check(lights == 0, "0 lights")
	_check(parts >= 1 and parts <= 2, "particle systems 1-2 (%d)" % parts)
	_check(verts <= 18000, "vertices %d <= 18000" % verts)
	# ---- materials: own <= 6 (this folder), the rest Ice / kit palette
	var own: Array = []
	var shared: Array = []
	for mat: Material in _materials(b):
		var path := mat.resource_path
		if path.begins_with(OWN_DIR):
			own.append(path.get_file())
		else:
			shared.append(path.get_file() if path != "" else "<built-in>")
			_check(path.begins_with("res://art/units/ice/materials/") or path.begins_with("res://art/units/kit/materials/"),
				"material %s is an Ice / kit palette entry" % path)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	print("palette materials (%d): %s" % [shared.size(), ", ".join(PackedStringArray(shared))])
	_check(own.size() <= 6, "<= 6 own materials")
	# ---- size + the tusk read
	var box := _vert_bounds(b, b.get_parent() as Node3D, true)
	print("rest bounds x %.2f..%.2f, y %.2f..%.2f, z %.2f..%.2f" % [box.position.x, box.end.x, box.position.y, box.end.y,
		box.position.z, box.end.z])
	_check(box.position.y >= -0.015, "nothing below the ground at rest (%.3f)" % box.position.y)
	_check(box.size.z >= 5.2 and box.size.z <= 6.8, "length 5.2-6.8 m incl. tusks (%.2f)" % box.size.z)
	_check(box.end.y >= 4.4 and box.end.y <= 5.4, "top (howdah banner) 4.4-5.4 m (%.2f)" % box.end.y)
	_check(box.size.x <= 3.0, "width <= 3.0 m (%.2f)" % box.size.x)
	var beast := _vert_bounds(b, b.get_parent() as Node3D, false)
	_check(beast.end.y >= 3.3 and beast.end.y <= 3.9, "the beast itself (no howdah) 3.3-3.9 m tall (%.2f)" % beast.end.y)
	var head_box := _node_bounds(b.get_node("Root/Mount/Head/Merged") as MeshInstance3D, b.get_parent() as Node3D)
	print("head + tusks: x %.2f..%.2f, z to %.2f" % [head_box.position.x, head_box.end.x, head_box.end.z])
	_check(head_box.end.z >= 4.2, "the tusks reach far ahead (z %.2f)" % head_box.end.z)
	_check(head_box.size.x >= 1.8, "the tusks spread wide (%.2f m)" % head_box.size.x)
	var rh := _rimehorn_length()
	if rh > 0.0:
		print("rimehorn length %.2f vs mammoth %.2f" % [rh, box.size.z])
		_check(box.size.z > rh * 1.4, "far bigger than the Rimehorn")
	# ---- frost mist
	var mist := a.get_node("Fx/FrostMist") as GPUParticles3D
	_check(mist != null and not mist.one_shot and not mist.local_coords, "frost mist: looping, world space")
	_check(mist != null and mist.emitting, "frost mist emitting close up")
	# ---- walk: legs, trunk swing, no gallop, the howdah rides the back
	var leg: Node3D = a.get_node("Root/Mount/LegFL")
	var trunk: Node3D = a.get_node("Root/Mount/Head/Trunk")
	var trunk2: Node3D = a.get_node("Root/Mount/Head/Trunk/Trunk2")
	var seat: Node3D = a.get_node("Root/Mount/Seat")
	a.call(&"set_moving", 3.4)
	await _wait(0.5)
	var max_leg := 0.0
	var tz_min := 99.0
	var tz_max := -99.0
	var t2x_min := 99.0
	var t2x_max := -99.0
	var sy_min := 99.0
	var sy_max := -99.0
	var max_g := 0.0
	for i: int in 90:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		tz_min = minf(tz_min, trunk.rotation.z)
		tz_max = maxf(tz_max, trunk.rotation.z)
		t2x_min = minf(t2x_min, trunk2.rotation.x)
		t2x_max = maxf(t2x_max, trunk2.rotation.x)
		var sp := (a.get_parent() as Node3D).global_transform.affine_inverse() * seat.global_position
		sy_min = minf(sy_min, sp.y)
		sy_max = maxf(sy_max, sp.y)
		max_g = maxf(max_g, float(a.call(&"gallop_blend")))
	print("walk: leg %.1f deg, trunk sway %.1f deg, trunk2 swing %.1f deg, howdah bob %.3f m, gallop %.2f" % [rad_to_deg(max_leg),
		rad_to_deg(tz_max - tz_min), rad_to_deg(t2x_max - t2x_min), sy_max - sy_min, max_g])
	_check(max_leg > deg_to_rad(12.0), "the legs swing in the walk")
	_check(tz_max - tz_min > deg_to_rad(5.0), "the trunk swings side to side with the gait")
	_check(t2x_max - t2x_min > deg_to_rad(8.0), "the trunk tip swings with the gait")
	_check(sy_max - sy_min > 0.02, "the howdah rides the walking back")
	_check(max_g < 0.05, "a mammoth never gallops at its speed")
	a.call(&"set_moving", 7.0)
	await _wait(0.6)
	_check(float(a.call(&"gallop_blend")) < 0.05, "never gallops, even fast")
	# ---- trample (while walking): leg lift, tusk sweep, stomp signal once at ~0.2 s, sides alternate
	a.call(&"set_moving", 3.4)
	await _wait(0.3)
	var stomps: Array = []
	a.connect(&"trample_stomped", func(at: Vector3) -> void: stomps.append(at))
	var head: Node3D = a.get_node("Root/Mount/Head")
	var yaw_min := 99.0
	var yaw_max := -99.0
	a.call(&"play_trample")
	var t0 := 0
	for i: int in 50:
		await process_frame
		yaw_min = minf(yaw_min, head.rotation.y)
		yaw_max = maxf(yaw_max, head.rotation.y)
		if stomps.size() == 1 and t0 == 0:
			t0 = i + 1
	print("trample: head sweep %.1f deg, stomps %d at frame %d, point %s" % [rad_to_deg(yaw_max - yaw_min), stomps.size(), t0,
		stomps[0] if stomps.size() > 0 else "-"])
	_check(yaw_max - yaw_min > deg_to_rad(18.0), "the tusks sweep aside on the trample")
	_check(stomps.size() == 1, "trample_stomped once per trample")
	_check(t0 >= 10 and t0 <= 15, "stomp at ~0.2 s (frame %d)" % t0)
	if stomps.size() > 0:
		var sp: Vector3 = stomps[0]
		_check(Vector2(sp.x, sp.z).distance_to(Vector2(a.global_position.x, a.global_position.z)) < 2.2 and absf(sp.y) < 0.1,
			"the stomp point is under a front foot")
	var side1 := float(a.get(&"_tr_side"))
	a.call(&"play_trample")
	_check(float(a.get(&"_tr_side")) == -side1, "the trample side alternates")
	await _wait(0.9)
	a.call(&"set_moving", 0.0)
	await _wait(1.2)
	# trample while standing (fast path must not swallow it)
	var lf0 := leg.rotation.x
	var rf: Node3D = a.get_node("Root/Mount/LegFR")
	a.call(&"play_trample")
	var lifted := 0.0
	for i: int in 12:
		await process_frame
		lifted = maxf(lifted, maxf(absf(leg.rotation.x - lf0), absf(rf.rotation.x)))
	_check(lifted > deg_to_rad(10.0), "trample while standing lifts a foot (%.1f deg)" % rad_to_deg(lifted))
	await _wait(1.0)
	_check(a.get(&"_action") == &"", "trample action finished")
	# ---- tusk gore attack
	var releases: Array = [0]
	var hx_min := 99.0
	var hx_max := -99.0
	a.call(&"play_attack")
	for i: int in 30:
		await process_frame
		hx_min = minf(hx_min, head.rotation.x)
		hx_max = maxf(hx_max, head.rotation.x)
	print("gore: head %.1f .. %.1f deg" % [rad_to_deg(hx_min), rad_to_deg(hx_max)])
	_check(hx_min < deg_to_rad(-6.0) and hx_max > deg_to_rad(15.0), "gore: the head rears then drives the tusks down")
	await _wait(0.6)
	_check(a.get(&"_action") == &"", "gore finished within 0.95 s")
	# ---- hit: the beast (body + trunk) and the howdah flash
	var body_mi := a.get_node("Root/Mount/Merged") as MeshInstance3D
	var trunk_mi := a.get_node("Root/Mount/Head/Trunk/Merged") as MeshInstance3D
	var archer_mi := h.get_node("Root/Chest/Merged") as MeshInstance3D
	var frame_mi := h.get_node("Frame") as MeshInstance3D
	a.call(&"play_hit")
	await _wait(0.05)
	var f_body := float(body_mi.get_instance_shader_parameter(&"hit_flash"))
	var f_trunk := float(trunk_mi.get_instance_shader_parameter(&"hit_flash"))
	var f_arch := float(archer_mi.get_instance_shader_parameter(&"hit_flash"))
	var f_frame := float(frame_mi.get_instance_shader_parameter(&"hit_flash"))
	print("hit flash: body %.2f, trunk %.2f, archer %.2f, frame %.2f" % [f_body, f_trunk, f_arch, f_frame])
	_check(f_body > 0.3 and f_trunk > 0.3, "the whole beast flashes (body, trunk)")
	_check(f_arch > 0.3 and f_frame > 0.3, "the howdah flashes with it")
	await _wait(0.5)
	# ---- howdah shot: turn to a target on the right, draw, release once, arrow re-nocked
	var released: Array = []
	h.connect(&"shot_released", func(at: Vector3) -> void: released.append(at))
	var hroot: Node3D = h.get_node("Root")
	var armr: Node3D = h.get_node("Root/Chest/ArmR")
	var s_u: Node3D = h.get_node("Root/Chest/ArmL/StringU")
	var su0 := s_u.position
	var armr_z0 := armr.position.z
	var target := a.global_transform * Vector3(12.0, 1.0, 1.0)
	var muzzle: Vector3 = a.call(&"get_howdah_muzzle")
	print("muzzle at rest ", muzzle)
	_check(muzzle.y > 3.8 and muzzle.y < 5.0, "the muzzle is up in the howdah (%.2f)" % muzzle.y)
	a.call(&"play_howdah_shot", target)
	await _wait(0.09)
	var drawn_z := armr.position.z
	var string_moved := s_u.position.distance_to(su0)
	await _wait(0.06)
	var arrow_after := bool(h.call(&"has_arrow"))
	await _wait(0.25)
	var yaw := hroot.rotation.y
	await _wait(0.8)
	var arrow_end := bool(h.call(&"has_arrow"))
	print("shot: draw %.2f m, string nock moved %.2f m, released %d, arrow after release %s, yaw %.1f deg, arrow at end %s" % [
		armr_z0 - drawn_z, string_moved, released.size(), arrow_after, rad_to_deg(yaw), arrow_end])
	_check(armr_z0 - drawn_z > 0.15, "the draw hand pulls back")
	_check(string_moved > 0.1, "the bow string follows the draw hand")
	_check(released.size() == 1, "shot_released once")
	_check(not arrow_after, "the arrow leaves at the release")
	_check(arrow_end, "a new arrow is nocked by the end")
	_check(yaw > deg_to_rad(40.0), "the archer turns toward a target on the right (%.1f deg)" % rad_to_deg(yaw))
	# a flyer overhead in front: the archer leans back to aim up
	var chest: Node3D = h.get_node("Root/Chest")
	a.call(&"play_howdah_shot", a.global_transform * Vector3(0.0, 12.0, 8.0))
	var pitch := 0.0
	for i: int in 30:
		await process_frame
		pitch = minf(pitch, chest.rotation.x)
	print("aim up: chest pitch %.1f deg" % rad_to_deg(pitch))
	_check(pitch < deg_to_rad(-12.0), "the archer aims up at a flyer")
	await _wait(3.0)
	_check(absf(hroot.rotation.y) < 0.05, "the archer turns back to face forward")
	# ---- team colour: the blanket (body), the banner and valance (frame), the archer's hood; restores
	var red := Color(0.85, 0.30, 0.12)
	b.call(&"set_team_color", red)
	await process_frame
	var b_body := b.get_node("Root/Mount/Merged") as MeshInstance3D
	var b_frame := hb.get_node("Frame") as MeshInstance3D
	var b_head := hb.get_node("Root/Chest/Head/Merged") as MeshInstance3D
	_check(red in _cloth_colors(b_body, &"base_color"), "the blanket takes the team colour")
	_check(red in _cloth_colors(b_frame, &"base_color"), "the howdah valance takes the team colour")
	_check(red in _cloth_colors(b_frame, &"cloth_color"), "the banner takes the team colour")
	_check(red in _cloth_colors(b_head, &"base_color"), "the archer's hood takes the team colour")
	var others_ok := true
	for mi: MeshInstance3D in [b_body, b_frame]:
		for s: int in mi.mesh.get_surface_count():
			var ov := mi.get_surface_override_material(s)
			var base := mi.mesh.surface_get_material(s)
			var bn := base.resource_path.get_file().get_basename()
			if ov and not (bn.ends_with("_cloth") or bn.ends_with("_cloth_dark") or bn.ends_with("_cape")):
				others_ok = false
	_check(others_ok, "only cloth / banner surfaces are recoloured")
	b.call(&"set_team_color", Color(0.45, 0.75, 0.95))
	await process_frame
	var any_override := false
	for s: int in b_body.mesh.get_surface_count():
		if b_body.get_surface_override_material(s) != null:
			any_override = true
	_check(not any_override, "the kingdom colour restores the blanket")
	# ---- kit slot audit (KITFIX rules) on every geometry
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for mm: Node3D in [a, h]:
		for g: Node in mm.find_children("*", "GeometryInstance3D", true, false):
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
	# ---- death: rolls onto its side, lies on the ground, frosts, the archer slumps, mist stops; revive
	var got: Array = [false]
	a.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	var root_n: Node3D = a.get_node("Root")
	a.call(&"set_moving", 3.4)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(1.05)
	var roll := root_n.rotation.z
	var lying := _vert_bounds(a, a.get_parent() as Node3D, true)
	var frost := float(body_mi.get_instance_shader_parameter(&"hit_flash"))
	var slump := chest.rotation.x
	print("death: roll %.1f deg, lying y %.2f..%.2f, frost %.2f, archer slump %.1f deg, mist %s, finished %s" % [rad_to_deg(roll),
		lying.position.y, lying.end.y, frost, rad_to_deg(slump), mist.emitting, got[0]])
	_check(absf(roll) > deg_to_rad(75.0), "falls onto its side")
	_check(lying.position.y > -0.35, "lies on the ground, not sunk (%.2f)" % lying.position.y)
	if lying.position.y <= -0.35:
		for g: Node in a.find_children("*", "MeshInstance3D", true, false):
			var mi := g as MeshInstance3D
			if mi.mesh and mi.name != "Shadow":
				print("    lowest of %s: %.2f" % [a.get_path_to(mi), _node_bounds(mi, a.get_parent() as Node3D).position.y])
	_check(lying.end.y < 3.8, "lying low (%.2f)" % lying.end.y)
	_check(frost > 0.2, "the body frosts over")
	_check(slump > deg_to_rad(20.0), "the archer slumps over the rail")
	_check(not mist.emitting, "the frost mist stops on death")
	_check(got[0], "death_finished within 1.05 s")
	a.call(&"revive")
	await _wait(0.3)
	_check(absf(root_n.rotation.z) < 0.03 and absf(root_n.position.y) < 0.05, "revive resets the pose")
	_check(float(body_mi.get_instance_shader_parameter(&"hit_flash")) < 0.05, "revive clears the frost")
	_check(absf(chest.rotation.x) < 0.1, "revive: the archer kneels up again")
	_check(bool(h.call(&"has_arrow")), "revive: arrow nocked")
	# ---- statuses / misc kit hooks just run
	a.call(&"play_level_up")
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	await _wait(0.3)
	a.call(&"set_status", &"haste", false)
	# ---- far away (> 45 m): the mist stops
	_cam.position = Vector3(0, 80, 90)
	await _wait(1.2)
	_check(not mist.emitting, "the frost mist stops beyond 45 m")
	_cam.position = Vector3(0, 10, 16)
	await _wait(1.2)
	_check(mist.emitting, "the frost mist restarts close up")
	# ---- a standalone howdah (preview / future use) instantiates and shoots
	var solo: Node3D = (load(HOWDAH) as PackedScene).instantiate()
	_world.add_child(solo)
	solo.position = Vector3(-8, 0, 0)
	await _wait(0.1)
	solo.call(&"play_howdah_shot", null)
	await _wait(0.3)
	_check(not bool(solo.call(&"has_arrow")), "standalone howdah shoots")
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


func _authored_howdah(h: Node) -> int:
	# Frame + one sculpt per archer pivot that has a merged mesh
	var n := 1
	for p: String in ["Root/Chest", "Root/Chest/Head", "Root/Chest/ArmL", "Root/Chest/ArmR"]:
		if h.get_node_or_null(p + "/Merged") != null:
			n += 1
	return n


func _rimehorn_length() -> float:
	var p := "res://art/units/mounts/rimehorn/rimehorn.tscn"
	if not ResourceLoader.exists(p):
		return 0.0
	var holder := Node3D.new()
	holder.position = Vector3(-20, 0, 0)
	_world.add_child(holder)
	var r: Node3D = (load(p) as PackedScene).instantiate()
	holder.add_child(r)
	var bx := _vert_bounds(r, holder, true)
	holder.queue_free()
	return bx.size.z


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


## Team-recoloured values of a shader parameter on a node's surface overrides.
func _cloth_colors(mi: MeshInstance3D, param: StringName) -> Array:
	var out: Array = []
	for s: int in mi.mesh.get_surface_count():
		var ov := mi.get_surface_override_material(s) as ShaderMaterial
		if ov:
			var col: Variant = ov.get_shader_parameter(param)
			if col is Color and not (col in out):
				out.append(col)
			elif col is Vector3:
				var c3 := Color((col as Vector3).x, (col as Vector3).y, (col as Vector3).z)
				if not (c3 in out):
					out.append(c3)
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


## Exact bounds of every vertex (the blob skipped; the howdah optional) in `frame` space.
func _vert_bounds(n: Node, frame: Node3D, with_howdah: bool) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if not with_howdah and String(n.get_path_to(mi)).contains("Howdah"):
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
