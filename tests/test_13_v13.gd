extends SceneTree
## Task 13.V13: the Cinder Dragon body + flight rig (art/units/titans/cinder_dragon/, cavalry-mounts.md 5 / 10).
## Run:  $GODOT --headless --path . -s tests/test_13_v13.gd --fixed-fps 60 --quit-after 4000
## Checks: headless instantiation without errors; budgets (titan: <= 36 authored meshes, <= 20 draw instances,
## 0 lights, <= 2 particle systems, materials only from the dragon folder + the kit blob, vertices printed);
## instance-uniform slot audit (kit map, no collision on any geometry instance); size (span 7 m, body at fly_height
## 4 m, origin on the ground); hooks: set_moving (hover beat 1.2 s, forward flight, glide when straight),
## set_turning (bank sign / size, also measured from the visual's own yaw), play_attack (breath_released at 0.35 s,
## jaw open ~0.6 s, lava flare), play_hit (flash, jolt), set_team_color (membrane tint, also before _ready),
## set_status (haste true, frozen holds the wings), play_death (spiral fall, crashed near the ground, lava cools,
## death_finished before Unit's 2.0 s fallback), revive. Prints PASS 13.v13 / FAIL 13.v13: <reason>.

const TASK_ID := "13.v13"
const SCENE := "res://art/units/titans/cinder_dragon/cinder_dragon.tscn"
const OWN_DIR := "res://art/units/titans/cinder_dragon/"
const BLOB_MAT := "res://art/units/kit/materials/unit_shadow_blob.tres"
const SHADOW := Color(0.42, 0.22, 0.60)
const FINGER_1 := Vector3(3.52, 5.02, -0.44)
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


func _tip(m: Node3D, side: String = "R") -> Vector3:
	var mi := m.get_node("Root/Body/Wing%s/Wing%s2/Wing%s2Mesh" % [side, side, side]) as Node3D
	var p := FINGER_1
	if side == "L":
		p.x = -p.x
	return m.global_transform.affine_inverse() * (mi.global_transform * p)


func _run() -> void:
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
	var h2 := Node3D.new()
	h2.position = Vector3(20, 0, 0)
	world.add_child(h2)
	h2.add_child(early)
	await _frames(3)

	# ---- hooks present
	for hk: String in ["set_moving", "set_turning", "play_attack", "play_hit", "play_death", "set_team_color",
			"set_status", "revive", "get_breath_origin", "play_level_up", "set_veterancy"]:
		_check(m.has_method(hk), "hook %s" % hk)
	for sg: String in ["death_finished", "breath_released", "crashed"]:
		_check(m.has_signal(sg), "signal %s" % sg)
	_check(float(m.get(&"attack_windup")) <= 0.15, "attack_windup <= 0.15")

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
			_check(p == BLOB_MAT, "material outside the dragon folder: '%s'" % p)
	print("materials: %d own + %d shared (%s); vertices %d; shadow casters %d" % [own, mats.size() - own,
		", ".join(PackedStringArray(mats.keys())), verts, shadow_casters])
	_check(own <= 6, "materials %d <= 6" % own)
	_check(verts <= 16000, "vertices %d <= 16000" % verts)

	# ---- instance-uniform slot audit (every shader of every geometry instance)
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
			for u: Array in _instance_uniforms((mat as ShaderMaterial).shader):
				if seen.has(u[0]):
					continue
				seen[u[0]] = true
				if KIT_SLOTS.has(u[0]) and int(u[1]) != int(KIT_SLOTS[u[0]]):
					_check(false, "%s on slot %d (map %d)" % [u[0], u[1], KIT_SLOTS[u[0]]])
				if by_slot.has(u[1]):
					collisions += 1
					print("  COLLISION %s slot %d: %s / %s" % [gi.name, u[1], by_slot[u[1]], u[0]])
				by_slot[u[1]] = u[0]
	_check(collisions == 0, "instance uniform slot collisions %d" % collisions)

	# ---- size (rest pose = the authored model-space vertices, at BAKE_HEIGHT 4.0)
	var body := m.get_node("Root/Body") as Node3D
	var min_p := Vector3(99, 99, 99)
	var max_p := Vector3(-99, -99, -99)
	var wing_min_x := 99.0
	var wing_max_x := -99.0
	for n: Node in geo:
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null or mi.name == "Shadow":
			continue
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				min_p = min_p.min(v)
				max_p = max_p.max(v)
				if String(mi.name).begins_with("Wing") and mi.mesh.surface_get_material(s).resource_path.ends_with("membrane.tres"):
					wing_min_x = minf(wing_min_x, v.x)
					wing_max_x = maxf(wing_max_x, v.x)
	print("rest extent: span %.2f (membranes %.2f), length %.2f, y %.2f .. %.2f" % [max_p.x - min_p.x,
		wing_max_x - wing_min_x, max_p.z - min_p.z, min_p.y, max_p.y])
	_check(absf(wing_max_x - wing_min_x - 7.0) < 0.15, "wing span 7 m (%.2f)" % (wing_max_x - wing_min_x))
	_check(max_p.x - min_p.x < 7.8, "span with claws < 7.8 m")
	_check(min_p.y > 3.0 and max_p.y < 6.2, "the rest pose flies (y %.2f .. %.2f)" % [min_p.y, max_p.y])
	var blob := m.get_node_or_null("Shadow") as Node3D
	_check(blob != null and absf(blob.position.y - 0.02) < 0.01, "ground blob at the origin")

	# ---- hover: beat period ~1.2 s, big amplitude, the body bobs
	m.call(&"set_moving", 0.0)
	await _frames(30)
	var ys: PackedFloat32Array = PackedFloat32Array()
	var by: PackedFloat32Array = PackedFloat32Array()
	for i: int in 180:
		await process_frame
		ys.append(_tip(m).y)
		by.append(body.global_position.y)
	var amp := _range(ys)
	var period := _period(ys)
	print("hover: tip swing %.2f m, beat period %.2f s, body bob %.2f m, span now %.2f" % [amp, period, _range(by),
		_tip(m).x - _tip(m, "L").x])
	_check(amp > 2.0, "hover beat swings the wing tip > 2 m (%.2f)" % amp)
	_check(absf(period - 1.2) < 0.1, "beat period 1.2 s (%.2f)" % period)
	_check(_range(by) > 0.15, "hover bob")
	_check(absf(float(m.get(&"fly_height")) - 4.0) < 0.001, "fly_height 4.0")
	var avg_y := 0.0
	for v: float in by:
		avg_y += v
	avg_y /= float(by.size())
	_check(absf(avg_y - 4.0) < 0.3, "body flies at ~4 m (%.2f)" % avg_y)

	# ---- forward flight straight: glides happen (a long stretch with the wings still)
	m.call(&"set_moving", 5.5)
	var still_run := 0
	var best_still := 0
	var glide_tips := PackedFloat32Array()
	var best_tips := PackedFloat32Array()
	var fwd_tips := PackedFloat32Array()
	for i: int in 600:
		await process_frame
		var ty := _tip(m).y
		fwd_tips.append(ty)
		if float(m.get(&"_flap_amp_w")) < 0.02:
			still_run += 1
			glide_tips.append(ty)
			if still_run > best_still:
				best_still = still_run
				best_tips = glide_tips.duplicate()
		else:
			still_run = 0
			glide_tips.clear()
	print("forward flight: tip range %.2f m; longest glide %.2f s (tip range in it %.2f m)" % [_range(fwd_tips),
		float(best_still) / 60.0, _range(best_tips)])
	_check(best_still >= 90, "glides while flying straight (%.2f s)" % (float(best_still) / 60.0))
	_check(_range(best_tips) < 0.5, "the wings hold still in the glide (%.2f)" % _range(best_tips))

	# ---- bank: explicit set_turning, then measured from the visual's own yaw
	for i: int in 90:
		m.call(&"set_turning", 120.0)
		await process_frame
	var tip_r := _tip(m).y
	var tip_l := _tip(m, "L").y
	var roll_r := body.global_transform.basis.x.y
	print("set_turning(120): +X wing tip %.2f, -X wing tip %.2f, body x axis y %.2f" % [tip_r, tip_l, roll_r])
	_check(roll_r < -0.35, "turning toward +X banks the +X side down (%.2f)" % roll_r)
	for i: int in 120:
		await process_frame
	var level := body.global_transform.basis.x.y
	_check(absf(level) < 0.12, "levels out when the turn stops (%.2f)" % level)
	for i: int in 90:
		holder.rotation.y -= deg_to_rad(120.0) * DT
		await process_frame
	var roll_auto := body.global_transform.basis.x.y
	print("measured turn (yaw -120 deg/s, no set_turning): body x axis y %.2f" % roll_auto)
	_check(roll_auto > 0.35, "banks from its own measured yaw rate (%.2f)" % roll_auto)
	for i: int in 120:
		await process_frame

	# ---- breath
	m.call(&"set_moving", 0.0)
	await _frames(60)
	var got_rel := [-1.0]
	var t0 := [0.0]
	m.connect(&"breath_released", func() -> void: got_rel[0] = t0[0], CONNECT_ONE_SHOT)
	var jaw := m.get_node("Root/Body/Neck1/Neck2/Head/Jaw") as Node3D
	var head_mesh := m.get_node("Root/Body/Neck1/Neck2/Head/HeadMesh") as GeometryInstance3D
	m.call(&"play_attack")
	var open_frames := 0
	var max_jaw := 0.0
	var max_flare := 0.0
	var head_pitch_max := 0.0
	for i: int in 84:
		await process_frame
		t0[0] = float(i + 1) * DT
		var ja := jaw.rotation.x
		max_jaw = maxf(max_jaw, ja)
		if ja > deg_to_rad(24.0):
			open_frames += 1
		max_flare = maxf(max_flare, float(head_mesh.get_instance_shader_parameter(&"glow_boost")))
		var hf := (m.get_node("Root/Body/Neck1/Neck2/Head") as Node3D).global_transform.basis.z
		head_pitch_max = maxf(head_pitch_max, rad_to_deg(asin(clampf(-hf.y, -1.0, 1.0))))
	print("breath: released at %.2f s, jaw max %.0f deg, open (> 24 deg) %.2f s, head flare %.2f, head down %.0f deg"
		% [got_rel[0], rad_to_deg(max_jaw), float(open_frames) * DT, max_flare, head_pitch_max])
	_check(absf(got_rel[0] - 0.35) < 0.05, "breath_released at 0.35 s (%.2f)" % got_rel[0])
	_check(max_jaw > deg_to_rad(32.0), "jaw opens wide (%.0f deg)" % rad_to_deg(max_jaw))
	_check(absf(float(open_frames) * DT - 0.6) < 0.12, "jaw open ~0.6 s (%.2f)" % (float(open_frames) * DT))
	_check(max_flare > 1.8, "the lava flares in the breath (%.2f)" % max_flare)
	_check(head_pitch_max > 30.0, "the head aims down at the ground (%.0f deg)" % head_pitch_max)
	var bo: Transform3D = m.call(&"get_breath_origin")
	print("breath origin at rest: ", bo.origin, " forward ", bo.basis.z)
	await _frames(20)
	_check(StringName(m.get(&"_action")) == &"", "breath ends")

	# ---- hit
	var flashed := false
	var jolt := 0.0
	var z0 := body.position.z
	m.call(&"play_hit")
	for i: int in 6:
		await process_frame
		if float(head_mesh.get_instance_shader_parameter(&"hit_flash")) > 0.5:
			flashed = true
		jolt = minf(jolt, body.position.z - z0)
	_check(flashed, "play_hit flashes white")
	_check(jolt < -0.08, "play_hit jolts the body back (%.2f)" % jolt)
	await _frames(30)
	_check(float(head_mesh.get_instance_shader_parameter(&"hit_flash")) == 0.0, "flash ends")

	# ---- team colour: membrane tint (and before _ready)
	var wing_nodes := ["Root/Body/WingL/WingLMesh", "Root/Body/WingL/WingL2/WingL2Mesh", "Root/Body/WingR/WingRMesh",
		"Root/Body/WingR/WingR2/WingR2Mesh"]
	m.call(&"set_team_color", SHADOW)
	var tinted := 0
	var tinted_early := 0
	for p: String in wing_nodes:
		var t1: Variant = (m.get_node(p) as GeometryInstance3D).get_instance_shader_parameter(&"membrane_tint")
		if t1 is Vector3 and (t1 as Vector3).is_equal_approx(Vector3(SHADOW.r, SHADOW.g, SHADOW.b)):
			tinted += 1
		var t2: Variant = (early.get_node(p) as GeometryInstance3D).get_instance_shader_parameter(&"membrane_tint")
		if t2 is Vector3 and (t2 as Vector3).is_equal_approx(Vector3(SHADOW.r, SHADOW.g, SHADOW.b)):
			tinted_early += 1
	_check(tinted == 4, "set_team_color tints the 4 membranes (%d)" % tinted)
	_check(tinted_early == 4, "set_team_color before _ready applied (%d)" % tinted_early)
	var body_mesh := m.get_node("Root/Body/BodyMesh") as GeometryInstance3D
	_check(body_mesh.get_instance_shader_parameter(&"membrane_tint") == null, "no tint outside the membranes")

	# ---- statuses
	_check(bool(m.call(&"set_status", &"haste", true)), "set_status haste -> true")
	m.call(&"set_status", &"haste", false)
	_check(not bool(m.call(&"set_status", &"burn", true)), "set_status burn -> false")
	m.call(&"set_status", &"frozen", true)
	await _frames(4)
	var fz := _tip(m).y
	await _frames(40)
	_check(absf(_tip(m).y - fz) < 0.25, "frozen holds the wings (%.2f)" % absf(_tip(m).y - fz))
	m.call(&"set_status", &"frozen", false)
	await _frames(10)

	# ---- death: spiral fall + crash + death_finished before 2.0 s
	var got := [false]
	var crash_at := [Vector3(99, 99, 99)]
	var crash_t := [-1.0]
	var death_frames := [0]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.connect(&"crashed", func(at: Vector3) -> void:
		crash_at[0] = at
		crash_t[0] = float(death_frames[0]) * DT, CONNECT_ONE_SHOT)
	m.call(&"set_moving", 5.5)
	await _frames(20)
	var root3 := m.get_node("Root") as Node3D
	m.call(&"play_death")
	var min_body_y := 99.0
	var max_spin := 0.0
	var end_frame := -1
	var body_y_at_crash := 99.0
	for i: int in 150:
		await process_frame
		death_frames[0] = i + 1
		min_body_y = minf(min_body_y, body.global_position.y)
		max_spin = maxf(max_spin, absf(root3.rotation.y))
		if crash_t[0] >= 0.0 and body_y_at_crash > 90.0:
			body_y_at_crash = body.global_position.y
		if i + 1 == 84:   # 1.4 s: lying on the ground, before the sink
			var tr := m.global_transform * _tip(m)
			var tl := m.global_transform * _tip(m, "L")
			print("  on the ground (1.4 s): wing tips y %.2f / %.2f, body y %.2f" % [tr.y, tl.y, body.global_position.y])
			_check(tr.y > -0.25 and tl.y > -0.25 and tr.y < 1.6 and tl.y < 1.6, "both wings lie on the ground")
		if got[0]:
			end_frame = i + 1
			break
	print("death: crashed at %.2f s (%.2f, %.2f, %.2f), body y at crash %.2f, spin %.0f deg, finished after %.2f s"
		% [crash_t[0], crash_at[0].x, crash_at[0].y, crash_at[0].z, body_y_at_crash, rad_to_deg(max_spin),
		float(end_frame) * DT])
	_check(got[0], "death_finished emitted")
	_check(end_frame > 0 and float(end_frame) * DT < 1.97 and float(end_frame) * DT > 1.6,
		"death lasts 1.6-1.97 s (Unit fallback 2.0 s)")
	_check(crash_t[0] > 0.9 and crash_t[0] < 1.3, "crash at ~1.1 s")
	_check(body_y_at_crash < 1.2, "the body hits the ground (%.2f)" % body_y_at_crash)
	_check(max_spin > deg_to_rad(120.0), "spiral spin (%.0f deg)" % rad_to_deg(max_spin))
	_check(float(body_mesh.get_instance_shader_parameter(&"glow_boost")) <= 0.01, "the lava cools to 0")
	m.call(&"revive")
	await _frames(4)
	_check(absf(body.global_position.y - 4.0) < 0.4, "revive: flying again (%.2f)" % body.global_position.y)
	_check(float(body_mesh.get_instance_shader_parameter(&"glow_boost")) > 0.9, "revive: lava hot")
	_check(m.is_processing(), "revived model processes")

	# ---- cost: 6 dragons flying (headless = tier 1)
	var crowd: Array = []
	for i: int in 6:
		var c: Node3D = ps.instantiate()
		c.position = Vector3(float(i) * 9.0, 0, 30.0)
		world.add_child(c)
		c.call(&"set_moving", 5.5 if i % 2 == 0 else 0.0)
		crowd.append(c)
	await _frames(10)
	var tt := Time.get_ticks_usec()
	await _frames(60)
	print("6 dragons: %.3f ms per frame (whole headless frame)" % (float(Time.get_ticks_usec() - tt) / 60.0 / 1000.0))
	world.queue_free()
	await _frames(2)
	_finish()


func _range(a: PackedFloat32Array) -> float:
	var lo := 1e9
	var hi := -1e9
	for v: float in a:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	return hi - lo


## Mean period (s) from upward crossings of the mean.
func _period(a: PackedFloat32Array) -> float:
	var mean := 0.0
	for v: float in a:
		mean += v
	mean /= float(a.size())
	var ups: Array[int] = []
	for i: int in range(1, a.size()):
		if a[i - 1] < mean and a[i] >= mean:
			ups.append(i)
	if ups.size() < 2:
		return 0.0
	return float(ups[ups.size() - 1] - ups[0]) / float(ups.size() - 1) * DT


static func _instance_uniforms(sh: Shader) -> Array:
	var out: Array = []
	if sh == null:
		return out
	var re := RegEx.create_from_string("instance\\s+uniform\\s+\\w+\\s+(\\w+)\\s*(:[^=;]*)?[=;]")
	var idx_re := RegEx.create_from_string("instance_index\\s*\\(\\s*(\\d+)\\s*\\)")
	var implicit := 0
	for line: String in sh.code.split("\n"):
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


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()
