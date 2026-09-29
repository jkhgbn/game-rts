extends SceneTree
## Task 13b.V1: the Cinderlock Musketeer model (art/units/fire/cinderlock/, tier3-extras.md 4 / 12).
## Run:  $GODOT --headless --path . -s tests/test_13b_v1.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation without errors (2 copies: the kit merge cache); it IS a FireModel / CharacterModel;
## scene exports (musket_volley, windup 0.15, body 1.7); budgets (soldier: <= 26 scene meshes, <= 14 draw instances,
## 0 lights, 1 particle system (the death burn), materials only from the kit palette + this folder); glow points
## (flask row = kit-boosted glow node, the muzzle ember = own_glow, both glow-shader); instance-uniform slot audit
## (KITFIX rules); the solved key poses (shoulder shift per arm small) and the fists on the stock / under the barrel at
## rest, while walking, at the shot and after the kick; hooks: play_attack (release at 0.15 s unloads, the muzzle
## points at the target at the shot, the muzzle climbs on the kick, back to port arms at 0.80 s), play_reload(2.0)
## (butt near the ground, ramrod shown and stroking, loaded at the end, gun back to rest), set_loaded / is_loaded (ember
## level), get_muzzle_point / get_weapon_tip, play_reload before _ready, set_team_color (team cloth only), play_hit,
## play_death (death_finished, rod hidden, ember 0), revive.
## Prints PASS 13b.v1 / FAIL 13b.v1: <reason>.

const TASK_ID := "13b.v1"
const SCENE := "res://art/units/fire/cinderlock/cinderlock.tscn"
const MODEL := "res://art/units/fire/cinderlock/cinderlock_model.gd"
const OWN_DIR := "res://art/units/fire/cinderlock/"
const KIT_DIR := "res://art/units/kit/materials/"
## Faces pass 2026-09-28: the shared FaceKit face material (eyes / brows / lips, 1 draw call) + glow probe.
const FaceProbe := preload("res://tests/face_probe.gd")
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const FIRE := Color(0.85, 0.30, 0.12)

var _fails: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  check failed: ", what)


func _frames(n: int) -> void:
	for _i: int in n:
		await process_frame


static func _surf_mat(gi: GeometryInstance3D, s: int) -> Material:
	if gi.material_override:
		return gi.material_override
	var mi := gi as MeshInstance3D
	if mi == null or mi.mesh == null:
		return null
	var m := mi.get_surface_override_material(s)
	return m if m else mi.mesh.surface_get_material(s)


## World centre of a fist (rest fist point carried by its arm pivot).
func _fist(m: Node3D, arm: String, rest: Vector3, shoulder: Vector3) -> Vector3:
	var a := m.get_node("Root/Chest/" + arm) as Node3D
	return a.global_transform * (rest - shoulder)


## Fist-to-musket errors: [right fist vs the grip / rod point, left fist vs the barrel line or its target].
func _hands(m: Node3D, CL: GDScript) -> Array[float]:
	var mk := m.get_node("Root/Chest/Musket") as Node3D
	var fr := _fist(m, "ArmR", CL.GRIP, CL.SHOULDER_R)
	var fl := _fist(m, "ArmL", CL.fist_l_rest(), CL.SHOULDER_L)
	var lr: Vector3 = mk.global_transform.affine_inverse() * fr
	var ll: Vector3 = mk.global_transform.affine_inverse() * fl
	# right: on the axis (x, y) near the stock wrist / anywhere along it; left: under the barrel (x 0, y -0.05)
	return [Vector2(lr.x, lr.y).length(), Vector2(ll.x, ll.y + 0.05).length(), lr.z, ll.z]


func _run() -> void:
	var CL: GDScript = load(MODEL)
	var ps: PackedScene = load(SCENE)
	_check(ps != null, "scene loads")
	if ps == null:
		_finish()
		return
	var holder := Node3D.new()
	root.add_child(holder)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 8, 10)
	root.add_child(cam)
	cam.look_at(Vector3.ZERO)
	cam.current = true
	var m: Node3D = ps.instantiate()
	holder.add_child(m)
	var m2: Node3D = ps.instantiate()
	m2.position = Vector3(3, 0, 0)
	holder.add_child(m2)
	await _frames(3)
	_check(m is CharacterModel and m is FireModel, "is a FireModel / CharacterModel")
	_check(m.get_script() == CL, "script is cinderlock_model.gd")
	_check(m.get(&"attack_style") == &"musket_volley", "attack_style musket_volley")
	_check(is_equal_approx(float(m.get(&"attack_windup")), 0.15), "attack_windup 0.15 (shoulder)")
	_check(is_equal_approx(float(m.get(&"body_height")), 1.7), "body_height 1.7")
	for h: String in ["play_reload", "set_loaded", "is_loaded", "get_muzzle_point", "get_muzzle_xf", "get_weapon_tip",
			"play_attack", "play_hit", "play_death", "revive", "set_moving", "set_team_color", "set_veterancy",
			"play_level_up", "set_status", "play_cast"]:
		_check(m.has_method(h), "hook " + h)

	# ---- budgets (scene file + runtime)
	var scene_inst: Node = ps.instantiate()
	var scene_meshes: int = scene_inst.find_children("*", "MeshInstance3D", true, false).size()
	scene_inst.free()
	var draw: int = 0
	var lights: int = m.find_children("*", "Light3D", true, false).size()
	var particles: int = 0
	var verts: int = 0
	var mats: Dictionary = {}
	for g: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		draw += 1
		if gi is GPUParticles3D:
			particles += 1
			continue
		var mi := gi as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				verts += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				var mat := _surf_mat(gi, s)
				if mat:
					mats[mat.resource_path] = true
	print("budget: scene meshes %d  draw instances %d  particles %d  lights %d  vertices %d  materials %d" % [
		scene_meshes, draw, particles, lights, verts, mats.size()])
	_check(scene_meshes <= 26, "<= 26 scene meshes (%d)" % scene_meshes)
	_check(draw <= 14, "<= 14 draw instances (%d)" % draw)
	_check(lights == 0, "0 lights")
	_check(particles == 1, "1 particle system (death burn)")
	for p: String in mats:
		_check(p.begins_with(KIT_DIR) or p.begins_with(OWN_DIR) or p == FaceProbe.FACE_MAT,
			"material from the palette or own folder (or the face): " + p)
	print("materials: ", mats.keys())

	# ---- glow points
	var glow_nodes: Array = m.get(&"_glow_nodes")
	var ember := m.get_node("Root/Chest/Musket/MuzzleEmber") as GeometryInstance3D
	var flasks := m.get_node_or_null("Root/Chest/GlowFireGlow") as GeometryInstance3D
	_check(flasks != null and glow_nodes.has(flasks), "flask row is a kit-boosted glow node")
	_check(ember != null and ember.has_meta(&"own_glow") and not glow_nodes.has(ember), "ember is own_glow")
	# The kit also drives glow_boost on the Face node (its shader declares it, faces pass 2026-09-28): not a glow point.
	var glow_parts := glow_nodes.filter(func(g: Node) -> bool: return not (g is FaceRig))
	_check(glow_parts.size() == 1, "one kit glow node (flasks) besides the face (%d)" % glow_parts.size())

	# ---- kit slot audit (KITFIX rules)
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for g: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi == m.get(&"_shadow") or gi is GPUParticles3D:
			continue
		var by_slot: Dictionary = {}
		var names: Array[String] = []
		for mat: Material in m.call(&"_materials_of", gi):
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
			_check((m.get(&"_flash_all_targets") as Array).has(gi), "%s flash target" % m.get_path_to(gi))
	_check(collisions == 0, "no instance-uniform slot collision")
	if collisions == 0:
		print("KITFIX AUDIT OK (cinderlock: slot map, no collision)")

	# ---- solved poses
	var res: PackedFloat32Array = CL.call(&"pose_residuals")
	print("pose shoulder shifts R/L (m): port %.3f/%.3f aim %.3f/%.3f kick %.3f/%.3f hold %.3f/%.3f top %.3f/%.3f" % [
		res[0], res[1], res[2], res[3], res[4], res[5], res[6], res[7], res[8], res[9]])
	_check(res[0] < 0.001 and res[1] < 0.001, "port arms = the rest pose")
	for i: int in res.size():
		_check(res[i] < 0.13, "shoulder shift %d small (%.3f)" % [i, res[i]])

	# ---- rest: hands on the gun, loaded ember, muzzle
	var hr: Array[float] = _hands(m, CL)
	print("rest hands: right %.3f left %.3f" % [hr[0], hr[1]])
	_check(hr[0] < 0.02 and hr[1] < 0.02, "fists on the stock / forestock at rest")
	_check(m.call(&"is_loaded") == true, "spawns loaded")
	_check(absf(float(ember.get_instance_shader_parameter(&"glow_boost")) - 1.0) < 0.05, "loaded ember at 1.0")
	var mz: Vector3 = m.call(&"get_muzzle_point")
	print("rest muzzle ", mz)
	_check(mz.x < -0.55 and mz.y > 1.0, "bell out past the left shoulder at port arms")
	_check(m.call(&"get_weapon_tip") is Vector3, "get_weapon_tip = the muzzle")

	# ---- walk: hands stay on the gun
	m.call(&"set_moving", 4.6)
	var walk_err: float = 0.0
	for i: int in 40:
		await process_frame
		var hw: Array[float] = _hands(m, CL)
		walk_err = maxf(walk_err, maxf(hw[0], hw[1]))
	print("walk hands max err %.3f" % walk_err)
	_check(walk_err < 0.03, "fists stay on the musket while walking")
	m.call(&"set_moving", 0.0)
	await _frames(20)

	# ---- volley
	var mk := m.get_node("Root/Chest/Musket") as Node3D
	m.call(&"play_attack")
	var t: float = 0.0
	var shot_dir := Vector3.ZERO
	var kick_pitch: float = 0.0
	var shot_pitch: float = 0.0
	var loaded_at_shot: bool = true
	var shot_hands: Array[float] = []
	var kick_hands: Array[float] = []
	var took_shot := false
	var took_kick := false
	while t < 0.9:
		await process_frame
		t = float(m.get(&"_action_t")) if m.get(&"_action") == &"attack" else 1.0
		if not took_shot and t >= 0.15:
			took_shot = true
			shot_dir = mk.global_transform.basis.z
			shot_pitch = rad_to_deg(asin(clampf(shot_dir.y, -1.0, 1.0)))
			loaded_at_shot = m.call(&"is_loaded")
			shot_hands = _hands(m, CL)
		if not took_kick and t >= 0.19:
			took_kick = true
			kick_pitch = rad_to_deg(asin(clampf(mk.global_transform.basis.z.y, -1.0, 1.0)))
			kick_hands = _hands(m, CL)
	print("volley: shot dir %s pitch %.1f  kick pitch %.1f  loaded after shot %s  hands shot %s kick %s" % [shot_dir,
		shot_pitch, kick_pitch, loaded_at_shot, shot_hands, kick_hands])
	_check(shot_dir.z > 0.97, "musket points at the target (+Z) at the shot")
	_check(kick_pitch > shot_pitch + 6.0, "the muzzle climbs on the recoil kick")
	_check(not loaded_at_shot, "the shot unloads the musket")
	_check(shot_hands[0] < 0.03 and shot_hands[1] < 0.03, "fists on the gun at the shot")
	_check(kick_hands[0] < 0.05 and kick_hands[1] < 0.05, "fists on the gun at the kick")
	_check(float(ember.get_instance_shader_parameter(&"glow_boost")) < 0.2, "empty ember after the shot")
	await _frames(3)
	var rest_xf: Transform3D = (CL.call(&"poses") as Array)[0][8]
	_check(mk.transform.is_equal_approx(rest_xf), "back to port arms after the volley")

	# ---- reload 2.0 s
	m.call(&"play_reload", 2.0)
	var rod := m.get_node("Root/Chest/Musket/Ramrod") as Node3D
	var rod_seen := false
	var rod_min: float = 9.0
	var rod_max: float = -9.0
	var butt_low: float = 9.0
	var hold_err: float = 0.0
	var el: float = 0.0
	while el < 1.95:
		await process_frame
		el += 1.0 / 60.0
		if rod.visible:
			rod_seen = true
			rod_min = minf(rod_min, rod.position.z)
			rod_max = maxf(rod_max, rod.position.z)
			# the ramrod runs down the bore (musket space x 0, y BORE_Y)
			var fr: Vector3 = mk.global_transform.affine_inverse() * _fist(m, "ArmR", CL.GRIP, CL.SHOULDER_R)
			hold_err = maxf(hold_err, Vector2(fr.x, fr.y - CL.BORE_Y).length())
		var butt: Vector3 = mk.global_transform * Vector3(0, 0, CL.BUTT_S)
		butt_low = minf(butt_low, butt.y)
	print("reload: rod seen %s stroke %.3f  butt lowest %.3f  right fist off the rod axis %.3f  loaded mid %s" % [rod_seen,
		rod_max - rod_min, butt_low, hold_err, m.call(&"is_loaded")])
	_check(rod_seen and rod_max - rod_min > 0.12, "ramrod shown and stroking")
	_check(butt_low < 0.12 and butt_low > -0.05, "butt planted on the ground")
	_check(hold_err < 0.04, "right fist on the ramrod")
	_check(m.call(&"is_loaded") == false, "not loaded during the reload")
	await _frames(12)
	_check(m.call(&"is_loaded") == true, "loaded after play_reload")
	_check(not rod.visible, "ramrod hidden after the reload")
	_check(mk.transform.is_equal_approx(rest_xf), "back to port arms after the reload")
	_check(absf(float(ember.get_instance_shader_parameter(&"glow_boost")) - 1.0) < 0.05, "ember relit")

	# ---- set_loaded
	m.call(&"set_loaded", false)
	_check(float(ember.get_instance_shader_parameter(&"glow_boost")) < 0.2, "set_loaded(false) dims the ember")
	m.call(&"set_loaded", true)
	_check(float(ember.get_instance_shader_parameter(&"glow_boost")) > 0.9, "set_loaded(true) lights it")

	# ---- reload before _ready
	var m3: Node3D = ps.instantiate()
	m3.call(&"play_reload", 1.0)
	m3.position = Vector3(-3, 0, 0)
	holder.add_child(m3)
	await _frames(20)
	_check(m3.get(&"_action") == &"cast" and m3.call(&"is_loaded") == false, "play_reload before _ready is kept")

	# ---- team colour
	m2.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	await process_frame
	var recol := 0
	var bad := 0
	for g: Node in m2.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var ov := mi.get_surface_override_material(s)
			if ov:
				recol += 1
				var base := mi.mesh.surface_get_material(s)
				if base and not (base.resource_path.ends_with("_cloth.tres") or base.resource_path.ends_with("_cloth_dark.tres")):
					bad += 1
	print("team colour: %d surfaces recoloured, %d wrong" % [recol, bad])
	_check(recol >= 2 and bad == 0, "team colour on the cloth only")

	# ---- hit, death, revive
	m.call(&"play_hit")
	await _frames(10)
	m.call(&"play_reload", 3.0)
	await _frames(40)
	var done: Array = [false]
	m.connect(&"death_finished", func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	await _frames(70)
	_check(done[0], "death_finished within 1.2 s")
	_check(not rod.visible, "ramrod hidden on death")
	_check(float(ember.get_instance_shader_parameter(&"glow_boost")) == 0.0, "ember out when dead")
	m.call(&"revive")
	await _frames(5)
	_check(m.call(&"is_loaded") == true and mk.transform.is_equal_approx(rest_xf), "revive: loaded, port arms")
	_check(absf(float(ember.get_instance_shader_parameter(&"glow_boost")) - 1.0) < 0.05, "revive: ember lit")
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()
