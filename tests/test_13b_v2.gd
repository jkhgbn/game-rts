extends SceneTree
## Task 13b.V2: the Frostrune Rifleman model (art/units/ice/frostrune_rifleman/, tier3-extras.md 5 / 12), built ON the
## Shardcaster (inherited scene + extends shardcaster.gd; the Shardcaster itself is not changed).
## Run:  $GODOT --headless --path . -s tests/test_13b_v2.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation without errors; it IS a Shardcaster / IceModel / CharacterModel (script chain) with its
## own merge cache; soldier budget (<= 26 authored meshes, <= 14 draw instances, 0 lights, only Ice palette + kit
## materials, no runtime materials on meshes); instance-uniform slot audit (kit map, no collision); glow points only on
## the rifle (3 runes + scope lens), the eye slit restyled; the rifle is longer than the body; the left glove stays on
## the forestock (rest, walk, shot, braced, aim); hooks: set_braced (1.0 s kneel: body down, rifle level at the
## shoulder and straight forward, monopod foot on the ground; stands in 0.35 s; moving stands it up), set_status
## (&"braced"), play_aim (scope / runes charge, cancel), attack_style rifle_shot (to the shoulder, release at
## attack_windup, muzzle flare + kick, back to rest), play_cast, play_fidget, play_hit, set_team_color (before / after
## _ready), play_death (death_finished, shatter), revive; a Shardcaster built before and after it is unchanged.
## Prints PASS 13b.v2 / FAIL 13b.v2: <reason>.

const TASK_ID := "13b.v2"
const SCENE := "res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn"
const SHARD := "res://art/units/ice/shardcaster.tscn"
const SHARD_GD := "res://art/units/ice/shardcaster.gd"
const ICE_MATS := "res://art/units/ice/materials/"
const KIT_MATS := "res://art/units/kit/materials/"
const GLOW_MAT := "res://art/units/ice/materials/ice_glow_unit.tres"
## Faces pass 2026-09-28: the shared FaceKit face material (eyes / brows / lips, 1 draw call) + glow probe.
const FaceProbe := preload("res://tests/face_probe.gd")
const KIT_SLOTS := {"ao_bottom": 1, "ao_height": 2, "hit_flash": 3, "flash_color": 4, "glow_boost": 5, "blob_color": 6}
const GRIP_R := Vector3(0.17, 0.99, 0.17)
const HAND_S := 0.34
const RIFLE_YAW := -12.0

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


static func _surf_mat(mi: MeshInstance3D, s: int) -> Material:
	if mi.material_override:
		return mi.material_override
	var m := mi.get_surface_override_material(s)
	return m if m else mi.mesh.surface_get_material(s)


static func _has_glow(mi: MeshInstance3D) -> bool:
	if mi == null or mi.mesh == null:
		return false
	for s: int in mi.mesh.get_surface_count():
		var m := _surf_mat(mi, s)
		if m and m.resource_path == GLOW_MAT:
			return true
	return false


static func _verts(mi: MeshInstance3D) -> int:
	var n := 0
	for s: int in mi.mesh.get_surface_count():
		n += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n


## Distance of the left glove (its rest model point, carried by ArmL) from the rifle's axis (world).
func _glove_err(m: Node3D) -> float:
	var arm_l := m.get_node("Root/Chest/ArmL") as Node3D
	var rifle := m.get_node("Root/Chest/ArmR/Rifle") as Node3D
	var h_model := GRIP_R + Basis(Vector3.UP, deg_to_rad(RIFLE_YAW)) * Vector3(0, 0, HAND_S)
	var rp: PackedVector3Array = m.get(&"_rest_pos")   # ArmL's REST model origin (model_origin() reads the posed nodes)
	var h_local: Vector3 = h_model - (rp[0] + rp[4] + rp[6])
	var hw := arm_l.global_transform * h_local
	var o := rifle.global_position
	var d := (rifle.global_basis * Vector3(0, 0, 1)).normalized()
	var v := hw - o
	return (v - d * v.dot(d)).length()


## The rifle's axis in the model frame (holder yaw removed).
func _rifle_dir(m: Node3D) -> Vector3:
	var rifle := m.get_node("Root/Chest/ArmR/Rifle") as Node3D
	return (m.global_basis.inverse() * (rifle.global_basis * Vector3(0, 0, 1))).normalized()


func _spawn(world: Node3D, ps: PackedScene, at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	world.add_child(holder)
	var m: Node3D = ps.instantiate()
	holder.add_child(m)
	return m


func _run() -> void:
	var ps := load(SCENE) as PackedScene
	var sps := load(SHARD) as PackedScene
	_check(ps != null, "scene loads")
	if ps == null or sps == null:
		_finish()
		return
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 6, 8)
	cam.look_at(Vector3(0, 1, 0))
	cam.make_current()
	# A Shardcaster before, the Rifleman, a Rifleman coloured before _ready, a Shardcaster after.
	var sc_before := _spawn(world, sps, Vector3(-4, 0, 0))
	var m := _spawn(world, ps, Vector3.ZERO)
	var early: Node3D = ps.instantiate()
	early.call(&"set_team_color", Color(0.85, 0.30, 0.12))
	var h2 := Node3D.new()
	h2.position = Vector3(4, 0, 0)
	world.add_child(h2)
	h2.add_child(early)
	var sc_after := _spawn(world, sps, Vector3(-8, 0, 0))
	await _frames(4)

	# ---- script chain, scene inheritance, own merge cache
	var chain: PackedStringArray = PackedStringArray()
	var paths: PackedStringArray = PackedStringArray()
	var scr: Script = m.get_script()
	while scr:
		chain.append(scr.get_global_name())
		paths.append(scr.resource_path)
		scr = scr.get_base_script()
	print("script chain: ", " > ".join(chain), "  (", ", ".join(paths), ")")
	_check(paths.has(SHARD_GD), "extends shardcaster.gd")
	_check(chain.has("IceModel") and chain.has("CharacterModel"), "IceModel / CharacterModel below it")
	_check(String(m.get(&"_type_key")) == SCENE, "own type key (merge cache): %s" % m.get(&"_type_key"))
	for hk: String in ["set_braced", "is_braced", "brace_amount", "play_aim", "is_aiming", "set_status", "get_muzzle_position",
			"get_scope_position", "get_beam_origin", "play_attack", "play_hit", "play_death", "revive", "set_team_color",
			"set_moving", "play_level_up", "set_veterancy", "play_cast", "play_fidget", "authored_mesh_count"]:
		_check(m.has_method(hk), "hook %s" % hk)
	_check(m.has_signal(&"death_finished"), "signal death_finished")
	_check(m.get(&"attack_style") == &"rifle_shot", "attack_style rifle_shot")
	var windup: float = float(m.get(&"attack_windup"))
	_check(windup > 0.0 and windup <= 0.15, "attack_windup in (0, 0.15]: %.2f" % windup)

	# ---- budgets
	var authored: int = int(m.call(&"authored_mesh_count"))
	var geo := m.find_children("*", "GeometryInstance3D", true, false)
	var parts := 0
	var looping := 0
	for n: Node in geo:
		if n is GPUParticles3D:
			parts += 1
			if not (n as GPUParticles3D).one_shot:
				looping += 1
	print("authored meshes (blob included) %d, draw instances %d (particle systems %d, looping %d)" % [authored, geo.size(), parts, looping])
	# + the Face node (faces pass 2026-09-28: one mesh node, 1 draw call).
	_check(authored > 15 and authored <= 27, "authored meshes %d <= 27 (26 + face)" % authored)
	_check(geo.size() <= 15, "draw instances %d <= 15 (14 + face)" % geo.size())
	_check(looping == 0, "no looping particles")
	_check(m.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	var mats := {}
	var verts := 0
	var glow_nodes := PackedStringArray()
	for n: Node in geo:
		if not n is MeshInstance3D:
			continue
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		verts += _verts(mi)
		for s: int in mi.mesh.get_surface_count():
			var mat := _surf_mat(mi, s)
			var p := mat.resource_path if mat else "<none>"
			mats[p] = true
			if p == GLOW_MAT and not glow_nodes.has(String(m.get_path_to(mi))):
				glow_nodes.append(String(m.get_path_to(mi)))
	for p: String in mats:
		_check(p.begins_with(ICE_MATS) or p.begins_with(KIT_MATS) or p == FaceProbe.FACE_MAT,
			"material outside the Ice / kit palette: '%s'" % p)
	print("materials (%d): %s" % [mats.size(), ", ".join(PackedStringArray(mats.keys()).duplicate())])
	print("vertices %d; glow meshes: %s" % [verts, ", ".join(glow_nodes)])
	_check(verts <= 5000, "vertices %d <= 5000" % verts)
	_check(glow_nodes.size() == 1 and glow_nodes[0].ends_with("Rifle"), "the only glow mesh is the rifle (runes + lens)")
	var rifle := m.get_node_or_null("Root/Chest/ArmR/Rifle") as MeshInstance3D
	_check(rifle != null and rifle.has_meta(&"own_glow"), "Rifle node (own glow)")
	_check(m.get_node_or_null("Root/Chest/ArmR/Rifle/Monopod") != null, "Monopod node")
	_check(m.get_node_or_null("Root/Chest/ArmR/Tip") == null and m.get_node_or_null("Root/Chest/ArmR/Orbit") == null,
		"the Shardcaster's rod tip / orbit shards are gone")
	var head_merged := m.get_node_or_null("Root/Chest/Head/Merged") as MeshInstance3D
	_check(head_merged != null and not _has_glow(head_merged), "eye slit restyled (no glow on the head)")
	# glow surfaces count: 3 runes + 1 lens are one surface; count the glow triangles' groups by z along the barrel
	var rifle_len := 0.0
	var glow_z := PackedFloat32Array()
	if rifle:
		var ab := rifle.mesh.get_aabb()
		rifle_len = ab.size.z
		for s: int in rifle.mesh.get_surface_count():
			if _surf_mat(rifle, s).resource_path == GLOW_MAT:
				for v: Vector3 in rifle.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
					var zq: float = snappedf(v.z, 0.1)
					if not glow_z.has(zq):
						glow_z.append(zq)
	var top := 0.0
	for n: Node in geo:
		if n is MeshInstance3D and (n as MeshInstance3D).mesh and n.name != "Shadow" and (n as MeshInstance3D).visible:
			var a := (n as MeshInstance3D).global_transform * (n as MeshInstance3D).mesh.get_aabb()
			top = maxf(top, a.end.y)
	print("rifle length %.2f m, body top %.2f m, glow z groups %s" % [rifle_len, top, glow_z])
	_check(rifle_len > top and rifle_len >= 1.9, "rifle (%.2f) longer than the body (%.2f)" % [rifle_len, top])
	_check(glow_z.size() >= 4, "4 glow points (3 runes + lens): %d" % glow_z.size())

	# ---- instance-uniform slot audit
	var coll := 0
	for n: Node in geo:
		var gi := n as GeometryInstance3D
		var by_slot := {}
		for mat: Material in m.call(&"_materials_of", gi):
			if not mat is ShaderMaterial or (mat as ShaderMaterial).shader == null:
				continue
			for u: Array in _instance_uniforms((mat as ShaderMaterial).shader):
				if KIT_SLOTS.has(u[0]):
					_check(u[1] == KIT_SLOTS[u[0]], "%s on slot %d" % [u[0], u[1]])
				if by_slot.has(u[1]) and by_slot[u[1]] != u[0]:
					coll += 1
				by_slot[u[1]] = u[0]
	_check(coll == 0, "instance uniform slot collisions: %d" % coll)

	# ---- Shardcasters untouched (built before and after the Rifleman)
	for sc: Node3D in [sc_before, sc_after]:
		_check(sc.get_node_or_null("Root/Chest/ArmR/Tip") != null, "Shardcaster keeps its rod tip")
		_check(sc.get_node_or_null("Root/Chest/ArmR/Orbit") != null, "Shardcaster keeps its orbit shards")
		# The eye slit is now the face's glowing ice-cyan irises (faces pass 2026-09-28): the head keeps its glow point.
		var hf := sc.get_node_or_null("Root/Chest/Head/Face") as MeshInstance3D
		_check(hf != null and FaceProbe.glows(hf), "Shardcaster keeps its eye glow (the face's glowing irises)")
	var a1 := sc_before.get_node("Root/Chest/ArmR/Merged") as MeshInstance3D
	var a2 := sc_after.get_node("Root/Chest/ArmR/Merged") as MeshInstance3D
	var c1 := sc_before.get_node("Root/Chest/Merged") as MeshInstance3D
	var c2 := sc_after.get_node("Root/Chest/Merged") as MeshInstance3D
	_check(a1.mesh == a2.mesh and _verts(a1) > 0 and c1.mesh == c2.mesh, "Shardcaster merge cache shared and intact")
	var mc := m.get_node("Root/Chest/Merged") as MeshInstance3D
	_check(mc.mesh != c1.mesh, "the Rifleman's chest is its own merge (mantle)")

	# ---- team colour before / after _ready
	var arm_early := early.get_node("Root/Chest/ArmL/Merged") as MeshInstance3D
	var recol := false
	for s: int in arm_early.mesh.get_surface_count():
		var mt := _surf_mat(arm_early, s)
		if mt and mt.resource_path == "" and mt is ShaderMaterial:
			recol = true
	_check(recol, "set_team_color before _ready recolours the sleeves")
	m.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	m.call(&"set_team_color", Color(0.45, 0.75, 0.95))

	# ---- rest
	var rest_root_y: float = (m.get_node("Root") as Node3D).position.y
	var rest_rifle_y: float = rifle.global_position.y
	var e0 := _glove_err(m)
	var mz: Vector3 = m.call(&"get_muzzle_position")
	print("rest: glove %.3f m off the rifle, muzzle (%.2f, %.2f, %.2f), rifle dir %s" % [e0, mz.x, mz.y, mz.z, _rifle_dir(m)])
	_check(e0 < 0.03, "rest: left glove on the forestock (%.3f)" % e0)
	_check(mz.z > 1.3 and mz.y > 0.8 and mz.y < 1.2, "rest: muzzle far forward at hip height")
	_check(absf(_rifle_dir(m).y) < 0.05, "rest: rifle level")

	# ---- walk
	m.call(&"set_moving", 3.6)
	var we := 0.0
	var wp := 0.0
	for i: int in 40:
		await _frames(1)
		we = maxf(we, _glove_err(m))
		wp = maxf(wp, absf(_rifle_dir(m).y))
	print("walk: glove max %.3f m, rifle pitch max %.3f" % [we, wp])
	_check(we < 0.05, "walk: glove on the forestock (%.3f)" % we)
	m.call(&"set_moving", 0.0)
	await _frames(30)

	# ---- rifle_shot standing
	var flare_before: float = float(m.get(&"_flare"))
	m.call(&"play_attack")
	var rel_frame := -1
	var y_at_rel := 0.0
	var max_pitch := 0.0
	var se := 0.0
	for i: int in 50:
		await _frames(1)
		if rel_frame < 0 and float(m.get(&"_flare")) > 0.9:
			rel_frame = i + 1
			y_at_rel = rifle.global_position.y
		if rel_frame > 0:
			max_pitch = maxf(max_pitch, _rifle_dir(m).y)
		se = maxf(se, _glove_err(m))
	var rel_t := float(rel_frame) / 60.0
	print("shot: release at %.3f s (windup %.2f), rifle up %.2f m at the release, muzzle climb %.1f deg, glove max %.3f" %
		[rel_t, windup, y_at_rel - rest_rifle_y, rad_to_deg(asin(clampf(max_pitch, -1, 1))), se])
	_check(flare_before < 0.5 and rel_frame > 0 and absf(rel_t - windup) <= 0.035, "shot: release at attack_windup")
	_check(y_at_rel - rest_rifle_y > 0.08, "shot: rifle raised to the shoulder")
	_check(rad_to_deg(asin(clampf(max_pitch, -1, 1))) > 5.0, "shot: recoil kick (muzzle climbs)")
	_check(se < 0.06, "shot: glove on the forestock (%.3f)" % se)
	await _frames(30)
	_check(absf(rifle.global_position.y - rest_rifle_y) < 0.03, "shot: rifle back to rest")

	# ---- set_braced: 1.0 s kneel
	m.call(&"set_braced", true)
	await _frames(30)
	var half: float = float(m.call(&"brace_amount"))
	await _frames(34)
	var full: float = float(m.call(&"brace_amount"))
	var root_y: float = (m.get_node("Root") as Node3D).position.y
	var mono := m.get_node("Root/Chest/ArmR/Rifle/Monopod") as Node3D
	var foot: Vector3 = mono.global_transform * Vector3(0, -0.70, 0)
	var bd := _rifle_dir(m)
	var be := _glove_err(m)
	print("braced: 0.5 s -> %.2f, 1.07 s -> %.2f; root drop %.2f m; monopod foot y %.3f; rifle dir %s; glove %.3f; rifle y %.2f" %
		[half, full, rest_root_y - root_y, foot.y, bd, be, rifle.global_position.y])
	_check(half > 0.35 and half < 0.65, "brace: half way at 0.5 s (%.2f)" % half)
	_check(full >= 0.999 and bool(m.call(&"is_braced")), "brace: complete after 1.0 s")
	_check(rest_root_y - root_y > 0.3, "brace: kneels (body drops %.2f m)" % (rest_root_y - root_y))
	_check(absf(foot.y) < 0.07, "brace: monopod foot on the ground (y %.3f)" % foot.y)
	_check(absf(bd.y) < 0.03 and bd.z > 0.97, "brace: rifle level and straight forward")
	_check(be < 0.05, "brace: glove on the forestock (%.3f)" % be)
	# braced shot keeps the kneel, the foot stays near the ground
	m.call(&"play_attack")
	var fmax := 0.0
	for i: int in 45:
		await _frames(1)
		fmax = maxf(fmax, absf((mono.global_transform * Vector3(0, -0.70, 0)).y))
	_check(float(m.call(&"brace_amount")) >= 0.999, "braced shot keeps the kneel")
	_check(fmax < 0.12, "braced shot: monopod foot stays planted (%.3f)" % fmax)

	# ---- play_aim (braced): scope + runes charge, pulse, cancel
	var g0: float = float(m.get(&"_glow_w"))
	m.call(&"play_aim", 1.2)
	_check(bool(m.call(&"is_aiming")), "play_aim: aiming")
	await _frames(66)
	var g1: float = float(m.get(&"_glow_w"))
	var ae := _glove_err(m)
	print("aim: glow %.2f -> %.2f at 1.1 s, glove %.3f" % [g0, g1, ae])
	_check(g1 > g0 * 2.2, "play_aim: the scope / runes flare (%.2f -> %.2f)" % [g0, g1])
	_check(ae < 0.05, "aim: glove on the forestock")
	m.call(&"play_attack")
	await _frames(12)
	m.call(&"play_aim", 1.2)
	await _frames(5)
	m.call(&"play_aim", 0.0)
	_check(not bool(m.call(&"is_aiming")), "play_aim(0) cancels")
	await _frames(40)

	# ---- unbrace (0.35 s), then set_status(&"braced") and moving stands it up
	m.call(&"set_braced", false)
	await _frames(24)
	_check(float(m.call(&"brace_amount")) == 0.0, "unbrace within 0.4 s")
	await _frames(10)
	var ry: float = (m.get_node("Root") as Node3D).position.y
	var ll: float = (m.get_node("Root/Hips/LegL") as Node3D).rotation.x
	_check(absf(ry - rest_root_y) < 0.04 and absf(ll) < 0.02, "standing again (root %.3f, leg %.3f)" % [ry - rest_root_y, ll])
	_check(bool(m.call(&"set_status", &"braced", true)), "set_status(&\"braced\") handled by the model")
	await _frames(62)
	_check(float(m.call(&"brace_amount")) >= 0.999, "set_status braced kneels")
	m.call(&"set_moving", 3.6)
	await _frames(24)
	_check(float(m.call(&"brace_amount")) == 0.0, "moving stands it up")
	m.call(&"set_moving", 0.0)
	m.call(&"set_status", &"braced", false)
	await _frames(30)

	# ---- cast, fidget, hit, level-up
	m.call(&"play_cast", &"rime_lock")
	await _frames(40)
	m.call(&"play_fidget")
	var fy := 0.0
	for i: int in 100:
		await _frames(1)
		fy = maxf(fy, rifle.global_position.y - rest_rifle_y)
	_check(fy > 0.08, "fidget raises the rifle (%.2f)" % fy)
	m.call(&"play_hit")
	m.call(&"play_level_up")
	m.call(&"set_veterancy", 4)
	await _frames(30)

	# ---- death while braced, revive
	m.call(&"set_braced", true)
	await _frames(40)
	var done: Array[int] = [0]
	m.connect(&"death_finished", func() -> void: done[0] += 1)
	m.call(&"play_death")
	await _frames(75)
	_check(done[0] == 1, "death_finished fired")
	_check(not (m.get_node("Root") as Node3D).visible, "shattered (body hidden)")
	m.call(&"revive")
	await _frames(20)
	_check(float(m.call(&"brace_amount")) == 0.0 and not bool(m.call(&"is_braced")), "revive: standing, not braced")
	_check((m.get_node("Root") as Node3D).visible, "revive: body visible")
	_check(_glove_err(m) < 0.03, "revive: glove on the forestock")
	_finish()


## [[name, slot], ...] of a shader, includes resolved. Slots: instance_index(N) or the implicit declaration order.
static func _instance_uniforms(sh: Shader) -> Array:
	var out: Array = []
	var code := _expand(sh.code, 0)
	var re := RegEx.create_from_string("instance\\s+uniform\\s+\\w+\\s+(\\w+)\\s*(:[^=;]*)?[=;]")
	var idx_re := RegEx.create_from_string("instance_index\\s*\\(\\s*(\\d+)\\s*\\)")
	var implicit := 0
	for line: String in code.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("//"):
			continue
		var r := re.search(l)
		if r == null:
			continue
		var ir := idx_re.search(r.get_string(2))
		if ir:
			out.append([r.get_string(1), int(ir.get_string(1))])
		else:
			out.append([r.get_string(1), implicit])
			implicit += 1
	return out


static func _expand(code: String, depth: int) -> String:
	if depth > 4:
		return code
	var re := RegEx.create_from_string("#include\\s+\"([^\"]+)\"")
	var out := code
	for r: RegExMatch in re.search_all(code):
		var inc := load(r.get_string(1)) as ShaderInclude
		if inc:
			out = out.replace(r.get_string(0), _expand(inc.code, depth + 1))
	return out


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()
