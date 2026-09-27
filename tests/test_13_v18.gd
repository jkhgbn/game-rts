extends SceneTree
## Task 13.V18: the Elder Treant, both forms (art/units/titans/elder_treant/, cavalry-mounts.md 5 / 10).
## Run:  $GODOT --headless --path . -s tests/test_13_v18.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation; pivots match the rig tables; budgets (titan: <= 36 meshes, <= 20 draw instances,
## 0 lights, <= 2 particle systems, materials only from the treant folder + the kit blob, vertices printed);
## instance-uniform slot audit (includes resolved); size of both forms (walking ~4 m; rooted wider and a canopy up
## high, pods above the ground, roots on the ground); hooks: set_moving (walk), play_attack (slam, alternating arms),
## set_rooted (3 s morph, root_changed, sink, arms up, canopy grown, ground roots shown; uproot back; instant),
## play_volley (volley_released at 0.15 s, pods flare; play_attack routes to it when rooted, is ignored while
## morphing), heal glow (rooted full, set_regen half, motes), play_hit (flash), set_team_color (garland tint, also
## before _ready), set_status, play_death (topple, glows out, death_finished before Unit's 2.0 s fallback), revive.
## Prints PASS 13.v18 / FAIL 13.v18: <reason>.

const TASK_ID := "13.v18"
const SCENE := "res://art/units/titans/elder_treant/elder_treant.tscn"
const OWN_DIR := "res://art/units/titans/elder_treant/"
const BLOB_MAT := "res://art/units/kit/materials/unit_shadow_blob.tres"
const TM := preload("res://art/units/titans/elder_treant/treant_mesh.gd")
const SHADOW := Color(0.42, 0.22, 0.60)
const KIT_SLOTS := {"ao_bottom": 1, "ao_height": 2, "hit_flash": 3, "flash_color": 4, "glow_boost": 5, "blob_color": 6}
const DT := 1.0 / 60.0

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


func _run() -> void:
	var t_build := Time.get_ticks_usec()
	var ps := load(SCENE) as PackedScene
	_check(ps != null, "scene loads")
	if ps == null:
		_finish()
		return
	var world := Node3D.new()
	root.add_child(world)
	var holder := Node3D.new()
	world.add_child(holder)
	var early: Node3D = ps.instantiate()
	early.call(&"set_team_color", SHADOW)    # before _ready: cached
	var m: Node3D = ps.instantiate()
	holder.add_child(m)
	print("first build (meshes of the type): %.0f ms" % (float(Time.get_ticks_usec() - t_build) / 1000.0))
	var h2 := Node3D.new()
	h2.position = Vector3(20, 0, 0)
	world.add_child(h2)
	h2.add_child(early)
	await _frames(3)

	# ---- hooks
	for hk: String in ["set_moving", "play_attack", "play_cast", "play_hit", "play_death", "set_team_color",
			"set_status", "revive", "play_level_up", "set_veterancy", "set_carrying", "play_mine", "glow_level",
			"set_rooted", "is_rooted", "root_progress", "is_morphing", "play_volley", "get_volley_origins", "set_regen"]:
		_check(m.has_method(hk), "hook %s" % hk)
	for sg: String in ["death_finished", "root_changed", "volley_released"]:
		_check(m.has_signal(sg), "signal %s" % sg)
	_check(float(m.get(&"attack_windup")) <= 0.15, "attack_windup <= 0.15")
	_check(&"stride_speed" in m and &"body_height" in m, "stride_speed / body_height exports")

	# ---- pivots = rig tables
	for i: int in TM.NP:
		var n := m.get_node_or_null(TM.PIVOT_PATHS[i]) as Node3D
		_check(n != null, "pivot %s" % TM.PIVOT_PATHS[i])
		if n and i != TM.P_ROOT:
			_check(n.position.is_equal_approx(TM.REST_LOCAL[i]) or (n.position - TM.REST_LOCAL[i]).length() < 0.001,
				"pivot %s rest position matches treant_mesh.gd" % TM.PIVOT_PATHS[i])

	# ---- budgets
	var geo := m.find_children("*", "GeometryInstance3D", true, false)
	var meshes := 0
	var parts := 0
	for n: Node in geo:
		if n is GPUParticles3D:
			parts += 1
		elif n is MeshInstance3D or n is MultiMeshInstance3D:
			meshes += 1
	print("authored meshes (blob included) %d, particle systems %d, draw instances %d" % [meshes, parts, geo.size()])
	_check(meshes <= 36, "meshes %d <= 36" % meshes)
	_check(geo.size() <= 20, "draw instances %d <= 20" % geo.size())
	_check(parts <= 2, "particle systems %d <= 2" % parts)
	_check(m.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	var mats := {}
	var verts := 0
	var shadow_casters := 0
	for n: Node in geo:
		if n is GPUParticles3D:
			continue
		var gi := n as GeometryInstance3D
		if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			shadow_casters += 1
		if gi.material_override:
			mats[gi.material_override.resource_path] = true
		var mi := gi as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				if gi.material_override == null:
					var mat := mi.mesh.surface_get_material(s)
					mats[mat.resource_path if mat else "<none>"] = true
				verts += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var own := 0
	for p: String in mats:
		if p.begins_with(OWN_DIR):
			own += 1
		else:
			_check(p == BLOB_MAT, "material outside the treant folder: '%s'" % p)
	print("materials: %d own + %d shared (%s); vertices %d; shadow casters %d" % [own, mats.size() - own,
		", ".join(PackedStringArray(mats.keys())), verts, shadow_casters])
	_check(own <= 6, "materials %d <= 6" % own)
	_check(verts <= 30000, "vertices %d <= 30000" % verts)

	# ---- instance-uniform slot audit (every shader, includes resolved)
	var collisions := 0
	for n: Node in geo:
		if n is GPUParticles3D:
			continue
		var gi := n as MeshInstance3D
		if gi == null or gi.mesh == null:
			continue
		var by_slot := {}
		var mats_gi: Array = []
		if gi.material_override:
			mats_gi.append(gi.material_override)
		else:
			for s: int in gi.mesh.get_surface_count():
				mats_gi.append(gi.mesh.surface_get_material(s))
		var seen := {}
		for mat: Variant in mats_gi:
			if not mat is ShaderMaterial:
				continue
			for u: Array in _instance_uniforms((mat as ShaderMaterial).shader.code):
				if seen.has(u[0]):
					continue
				seen[u[0]] = true
				if KIT_SLOTS.has(u[0]) and int(u[1]) != int(KIT_SLOTS[u[0]]):
					_check(false, "%s on slot %d (map %d)" % [u[0], u[1], KIT_SLOTS[u[0]]])
				if by_slot.has(u[1]):
					collisions += 1
					print("  COLLISION %s slot %d: %s / %s" % [gi.name, u[1], by_slot[u[1]], u[0]])
				by_slot[u[1]] = u[0]
		if gi.name == "HeadMesh":
			print("head instance uniforms: ", seen.keys())
	_check(collisions == 0, "instance uniform slot collisions %d" % collisions)

	# ---- size, walking form (static vertices only) and the rooted form (everything, rendered pose)
	var ext_w := _extent(m, false)
	print("walking form: x %.2f..%.2f, y %.2f..%.2f, z %.2f..%.2f" % [ext_w[0].x, ext_w[1].x, ext_w[0].y, ext_w[1].y,
		ext_w[0].z, ext_w[1].z])
	_check(ext_w[1].y > 3.9 and ext_w[1].y < 4.6, "walking height ~4 m (%.2f)" % ext_w[1].y)
	_check(ext_w[0].y > -0.25, "walking form stands on the ground (%.2f)" % ext_w[0].y)
	var spread := m.get_node("Spread") as Node3D
	_check(not spread.visible, "ground roots hidden while walking")
	for gp: String in ["Root/Chest/Head/HeadGrowth", "Root/Chest/ArmL/ForeL/ForeLGrowth", "Root/Chest/ArmR/ForeR/ForeRGrowth"]:
		var gn := m.get_node_or_null(gp) as Node3D
		_check(gn != null and not gn.visible, "canopy node %s exists, hidden while walking" % gp)
	# overlay safety (Ice chill tint = a material_overlay without the growth code): no visible walking mesh may
	# carry rooted-only vertices
	var stray := 0
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		for s: int in mi.mesh.get_surface_count():
			var cu: Variant = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_CUSTOM0]
			if cu == null:
				continue
			var ca: PackedFloat32Array = cu
			for k: int in range(3, ca.size(), 4):
				if ca[k] != 0.0:
					stray += 1
	_check(stray == 0, "walking: no visible mesh carries rooted-only vertices (%d)" % stray)
	var blob := m.get_node_or_null("Shadow") as Node3D
	_check(blob != null and absf(blob.position.y - 0.02) < 0.01, "ground blob")

	# ---- walk
	m.call(&"set_moving", 3.8)
	var leg_l := m.get_node("Root/Hips/LegL") as Node3D
	var rootp := m.get_node("Root") as Node3D
	var lo := 99.0
	var hi := -99.0
	var ylo := 99.0
	var yhi := -99.0
	for i: int in 90:
		await process_frame
		lo = minf(lo, leg_l.rotation.x)
		hi = maxf(hi, leg_l.rotation.x)
		ylo = minf(ylo, rootp.position.y)
		yhi = maxf(yhi, rootp.position.y)
	print("walk: thigh swing %.0f deg, body bob %.2f m" % [rad_to_deg(hi - lo), yhi - ylo])
	_check(rad_to_deg(hi - lo) > 40.0, "legs swing in the walk")
	_check(yhi - ylo > 0.05, "the body bobs in the walk")
	m.call(&"set_moving", 0.0)
	await _frames(40)

	# ---- slam (alternating arms)
	# elbow heights (rest ~1.94 m; overhead > 3 m)
	var elb_r := m.get_node("Root/Chest/ArmR/ForeR") as Node3D
	var elb_l := m.get_node("Root/Chest/ArmL/ForeL") as Node3D
	var max_r := 0.0
	var max_l := 0.0
	var min_r_after := 99.0
	m.call(&"play_attack")
	for i: int in 60:
		await process_frame
		max_r = maxf(max_r, elb_r.global_position.y)
		max_l = maxf(max_l, elb_l.global_position.y)
		if i > 8 and i < 20:
			min_r_after = minf(min_r_after, minf(elb_r.global_position.y, elb_l.global_position.y))
	m.call(&"play_attack")
	var max_l2 := 0.0
	var max_r2 := 0.0
	for i: int in 60:
		await process_frame
		max_l2 = maxf(max_l2, elb_l.global_position.y)
		max_r2 = maxf(max_r2, elb_r.global_position.y)
	print("slam 1: elbows up to %.2f / %.2f m; slam 2: %.2f / %.2f; lowest after the strike %.2f" % [max_l, max_r,
		max_l2, max_r2, min_r_after])
	_check((max_l > 3.0) != (max_r > 3.0), "one arm raised overhead per slam")
	_check((max_l2 > 3.0) != (max_l > 3.0), "the slams alternate arms")
	await _frames(10)

	# ---- take root: 3 s morph
	var got_root := [0, false, -1.0]   # count, value, time
	var t_ref := [0.0]
	m.connect(&"root_changed", func(r: bool) -> void:
		got_root[0] = int(got_root[0]) + 1
		got_root[1] = r
		got_root[2] = t_ref[0])
	m.call(&"set_rooted", true)
	var head_mesh := m.get_node("Root/Chest/Head/HeadMesh") as GeometryInstance3D
	var fore_mesh := m.get_node("Root/Chest/ArmR/ForeR/ForeRGrowth") as GeometryInstance3D
	var mono := true
	var last_k := 0.0
	var atk_during := false
	for i: int in 200:
		await process_frame
		t_ref[0] = float(i + 1) * DT
		var k := float(m.call(&"root_progress"))
		if k < last_k - 1e-6:
			mono = false
		last_k = k
		if i == 60:
			_check(bool(m.call(&"is_morphing")), "is_morphing during the morph")
			m.call(&"play_attack")
			await process_frame
			atk_during = StringName(m.get(&"_action")) != &""
		if int(got_root[0]) > 0:
			break
	print("root: root_changed(%s) after %.2f s; progress monotonic %s" % [str(got_root[1]), float(got_root[2]), str(mono)])
	_check(int(got_root[0]) == 1 and bool(got_root[1]), "root_changed(true) once")
	_check(absf(float(got_root[2]) - 3.0) < 0.12, "the morph lasts 3 s (%.2f)" % float(got_root[2]))
	_check(mono, "morph progress is monotonic")
	_check(not atk_during, "attacks ignored while morphing")
	_check(bool(m.call(&"is_rooted")), "is_rooted() after the morph")
	await _frames(3)
	_check(absf(rootp.position.y - TM.ROOTED_POS[TM.P_ROOT].y) < 0.03, "the body sinks %.2f m (%.2f)" %
		[-TM.ROOTED_POS[TM.P_ROOT].y, rootp.position.y])
	_check(spread.visible, "ground roots shown when rooted")
	_check((m.get_node("Root/Chest/Head/HeadGrowth") as Node3D).visible, "crown canopy shown when rooted")
	_check(absf(_f(fore_mesh.get_instance_shader_parameter(&"root_morph")) - 1.0) < 0.001, "root_morph 1 on the canopy")
	var ext_r := _extent(m, true)
	print("rooted form: x %.2f..%.2f, y %.2f..%.2f, z %.2f..%.2f" % [ext_r[0].x, ext_r[1].x, ext_r[0].y, ext_r[1].y,
		ext_r[0].z, ext_r[1].z])
	_check(ext_r[1].x - ext_r[0].x > 4.4, "rooted form is wide (%.2f m)" % (ext_r[1].x - ext_r[0].x))
	_check(ext_r[1].y > 4.0 and ext_r[1].y < 5.2, "rooted canopy top 4-5.2 m (%.2f)" % ext_r[1].y)
	var vo: PackedVector3Array = m.call(&"get_volley_origins")
	print("volley origins (rooted): ", vo)
	_check(vo.size() == 3, "3 volley origins")
	if vo.size() == 3:
		_check(vo[0].x < -1.3 and vo[1].x > 1.3 and vo[0].y > 3.0 and vo[1].y > 3.0, "canopies up and out on both sides")
	var pods := _glow_extent(fore_mesh)
	print("right canopy pods (rendered): y %.2f..%.2f" % [pods[0].y, pods[1].y])
	_check(pods[0].y > 1.8, "seed pods hang well above the ground (%.2f)" % pods[0].y)
	var sp_ext := _mesh_extent(m.get_node("Spread/SpreadMesh") as MeshInstance3D, true)
	print("ground roots: x %.2f..%.2f, y %.2f..%.2f" % [sp_ext[0].x, sp_ext[1].x, sp_ext[0].y, sp_ext[1].y])
	_check(sp_ext[1].x - sp_ext[0].x > 3.5 and sp_ext[1].y < 0.7, "ground roots spread wide and low")

	# ---- heal glow
	var hg := _f(head_mesh.get_instance_shader_parameter(&"heal_glow"))
	var motes := m.get_node("Root/Chest/HealMotes") as GPUParticles3D
	print("rooted heal_glow %.2f, motes emitting %s" % [hg, str(motes.emitting)])
	_check(hg > 0.95, "rooted: full heal glow")
	_check(motes.emitting, "rooted: heal motes on")

	# ---- rooted: set_moving ignored, volley
	var leg_rest := leg_l.rotation
	m.call(&"set_moving", 3.8)
	await _frames(30)
	_check(leg_l.rotation.is_equal_approx(leg_rest) or (leg_l.rotation - leg_rest).length() < 0.02, "no walk while rooted")
	m.call(&"set_moving", 0.0)
	var got_v := [-1.0]
	var tv := [0.0]
	m.connect(&"volley_released", func() -> void: got_v[0] = tv[0], CONNECT_ONE_SHOT)
	m.call(&"play_attack")    # routed to the volley
	var max_flare := 0.0
	for i: int in 70:
		await process_frame
		tv[0] = float(i + 1) * DT
		max_flare = maxf(max_flare, _f(fore_mesh.get_instance_shader_parameter(&"glow_boost")))
	print("volley: released at %.2f s, pod glow peak %.2f" % [got_v[0], max_flare])
	_check(absf(got_v[0] - 0.15) < 0.04, "volley_released at 0.15 s (%.2f)" % got_v[0])
	_check(max_flare > 1.8, "the pods flare in the volley (%.2f)" % max_flare)
	await _frames(5)
	_check(StringName(m.get(&"_action")) == &"", "volley ends")

	# ---- hit while rooted
	var flashed := false
	m.call(&"play_hit")
	for i: int in 6:
		await process_frame
		if _f(head_mesh.get_instance_shader_parameter(&"hit_flash")) > 0.5:
			flashed = true
	_check(flashed, "play_hit flashes white")
	await _frames(30)
	_check(_f(head_mesh.get_instance_shader_parameter(&"hit_flash")) == 0.0, "flash ends")

	# ---- uproot
	got_root[0] = 0
	m.call(&"set_rooted", false)
	for i: int in 200:
		await process_frame
		t_ref[0] = float(i + 1) * DT
		if int(got_root[0]) > 0:
			break
	await _frames(3)
	print("uproot: root_changed(%s) after %.2f s, root y %.2f" % [str(got_root[1]), float(got_root[2]), rootp.position.y])
	_check(int(got_root[0]) == 1 and not bool(got_root[1]), "root_changed(false)")
	_check(absf(float(got_root[2]) - 3.0) < 0.12, "uproot lasts 3 s")
	_check(absf(rootp.position.y) < 0.06, "standing again")
	_check(not spread.visible, "ground roots hidden again")
	_check(_f(head_mesh.get_instance_shader_parameter(&"heal_glow")) < 0.01, "walking: no heal glow")
	m.call(&"set_regen", true)
	await _frames(4)
	var hg2 := _f(head_mesh.get_instance_shader_parameter(&"heal_glow"))
	_check(hg2 > 0.4 and hg2 < 0.7, "set_regen: half heal glow (%.2f)" % hg2)
	m.call(&"set_regen", false)
	# instant
	m.call(&"set_rooted", true, true)
	await _frames(2)
	_check(bool(m.call(&"is_rooted")) and absf(rootp.position.y - TM.ROOTED_POS[TM.P_ROOT].y) < 0.03, "set_rooted(true, true)")
	m.call(&"set_rooted", false, true)
	await _frames(2)

	# ---- team colour: garland tint (and before _ready)
	var hips := m.get_node("Root/Hips/HipsMesh") as GeometryInstance3D
	m.call(&"set_team_color", SHADOW)
	var sv := Vector3(SHADOW.r, SHADOW.g, SHADOW.b)
	var t1: Variant = hips.get_instance_shader_parameter(&"team_tint")
	var t2: Variant = (early.get_node("Root/Hips/HipsMesh") as GeometryInstance3D).get_instance_shader_parameter(&"team_tint")
	_check(t1 is Vector3 and (t1 as Vector3).is_equal_approx(sv), "set_team_color tints the garland")
	_check(t2 is Vector3 and (t2 as Vector3).is_equal_approx(sv), "set_team_color before _ready applied")

	# ---- statuses
	_check(bool(m.call(&"set_status", &"haste", true)), "set_status haste -> true")
	m.call(&"set_status", &"haste", false)
	_check(not bool(m.call(&"set_status", &"burn", true)), "set_status burn -> false")

	# ---- death (from the rooted form: the worst case) + revive
	m.call(&"set_rooted", true, true)
	await _frames(3)
	var got := [false]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	var max_tilt := 0.0
	var end_frame := -1
	for i: int in 150:
		await process_frame
		max_tilt = maxf(max_tilt, rootp.rotation.x)
		if got[0]:
			end_frame = i + 1
			break
	print("death: topple %.0f deg, finished after %.2f s, eye glow %.2f" % [rad_to_deg(max_tilt), float(end_frame) * DT,
		_f(head_mesh.get_instance_shader_parameter(&"glow_boost"))])
	_check(got[0], "death_finished emitted")
	_check(end_frame > 0 and float(end_frame) * DT > 1.6 and float(end_frame) * DT < 1.97, "death lasts 1.6-1.97 s")
	_check(max_tilt > deg_to_rad(70.0), "topples forward like a felled tree")
	_check(_f(head_mesh.get_instance_shader_parameter(&"glow_boost")) <= 0.01, "the glows go out")
	m.call(&"revive")
	await _frames(4)
	_check(absf(rootp.position.y) < 0.06 and absf(rootp.rotation.x) < 0.05, "revive: standing, walking form")
	_check(_f(head_mesh.get_instance_shader_parameter(&"glow_boost")) > 0.9, "revive: eyes lit")
	_check(m.is_processing(), "revived model processes")

	# ---- cost: 6 treants (3 walking, 3 rooted)
	for i: int in 6:
		var c: Node3D = ps.instantiate()
		c.position = Vector3(float(i) * 7.0, 0, 30.0)
		world.add_child(c)
		if i % 2 == 0:
			c.call(&"set_moving", 3.8)
		else:
			c.call(&"set_rooted", true, true)
	await _frames(10)
	var tt := Time.get_ticks_usec()
	await _frames(60)
	print("7 treants: %.3f ms per frame (whole headless frame)" % (float(Time.get_ticks_usec() - tt) / 60.0 / 1000.0))
	world.queue_free()
	await _frames(2)
	_finish()


## Model-space extent of the rendered model. rooted = include growth vertices (at root_morph 1 they sit where authored);
## otherwise static vertices only. Uses the pivots' current transforms.
func _extent(m: Node3D, rooted: bool) -> Array:
	var lo := Vector3(99, 99, 99)
	var hi := Vector3(-99, -99, -99)
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.name == "Shadow" or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var e := _mesh_extent(mi, rooted, m)
		lo = lo.min(e[0])
		hi = hi.max(e[1])
	return [lo, hi]


func _mesh_extent(mi: MeshInstance3D, rooted: bool, m: Node3D = null) -> Array:
	var lo := Vector3(99, 99, 99)
	var hi := Vector3(-99, -99, -99)
	var xf := mi.global_transform if m == null else m.global_transform.affine_inverse() * mi.global_transform
	for s: int in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var cu: PackedFloat32Array = arr[Mesh.ARRAY_CUSTOM0] if arr[Mesh.ARRAY_CUSTOM0] != null else PackedFloat32Array()
		for k: int in vs.size():
			var grown := cu.size() > k * 4 + 3 and cu[k * 4 + 3] != 0.0
			if grown and not rooted:
				continue
			var p := xf * vs[k]
			lo = lo.min(p)
			hi = hi.max(p)
	return [lo, hi]


## World extent of the glow surface (seed pods) of a forearm mesh.
func _glow_extent(mi: GeometryInstance3D) -> Array:
	var lo := Vector3(99, 99, 99)
	var hi := Vector3(-99, -99, -99)
	var mm := mi as MeshInstance3D
	for s: int in mm.mesh.get_surface_count():
		if not mm.mesh.surface_get_material(s).resource_path.ends_with("treant_glow.tres"):
			continue
		for v: Vector3 in (mm.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			var p := mm.global_transform * v
			lo = lo.min(p)
			hi = hi.max(p)
	return [lo, hi]


## [name, slot] of every instance uniform in the shader code (#include files resolved).
static func _instance_uniforms(code: String, depth: int = 0) -> Array:
	var out: Array = []
	var re := RegEx.create_from_string("instance\\s+uniform\\s+\\w+\\s+(\\w+)\\s*(:[^=;]*)?[=;]")
	var idx_re := RegEx.create_from_string("instance_index\\s*\\(\\s*(\\d+)\\s*\\)")
	var implicit := 0
	for line: String in code.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("//"):
			continue
		if l.begins_with("#include") and depth < 4:
			var q := l.split("\"")
			if q.size() >= 2:
				var inc := load(q[1]) as ShaderInclude
				if inc:
					out.append_array(_instance_uniforms(inc.code, depth + 1))
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


static func _f(v: Variant) -> float:
	return float(v) if v != null else 0.0


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()
