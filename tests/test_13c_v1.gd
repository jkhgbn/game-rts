extends SceneTree
## Task 13c.V1: the Frost Dragon model (art/units/titans/frost_dragon/, titans-2.md 3 / 11), built on the Cinder
## Dragon (FlyerModel rig + CinderDragonModel mesh helpers and legs).
## Run:  $GODOT --headless --path . -s tests/test_13c_v1.gd --fixed-fps 60 --quit-after 4000
## Checks: headless instantiation without errors; it IS a FlyerModel (hooks from the rig); budgets (titan: <= 36
## authored meshes, <= 20 draw instances, 0 lights, <= 2 particle systems, materials only from the frost folder + the
## kit blob, triangles / vertices printed); instance-uniform slot audit (kit map, no collision); glow points (emission
## parts); size (membrane span 7.5 m, body at 4 m, origin on the ground, horns the highest point, longer than wide);
## hooks: set_moving (hover beat 1.3 s, forward flight, glides), set_turning (bank, also measured), play_attack
## (breath_released at 0.35 s, jaw open ~0.6 s, the cold glow flares), play_hit (flash, jolt), set_team_color (membrane
## tint, also before _ready), set_status, play_death (spiral, crash, glow out, death_finished < 2.0 s), revive; and the
## Cinder Dragon beside it is untouched (its own materials on its legs, its span 7.0 m).
## Prints PASS 13c.v1 / FAIL 13c.v1: <reason>.

const TASK_ID := "13c.v1"
const SCENE := "res://art/units/titans/frost_dragon/frost_dragon.tscn"
const CINDER := "res://art/units/titans/cinder_dragon/cinder_dragon.tscn"
const OWN_DIR := "res://art/units/titans/frost_dragon/"
const CINDER_DIR := "res://art/units/titans/cinder_dragon/"
const BLOB_MAT := "res://art/units/kit/materials/unit_shadow_blob.tres"
const SHADOW := Color(0.42, 0.22, 0.60)
const FINGER_1 := Vector3(3.75, 5.06, -0.46)
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


## An instance uniform the model never set reads back null (the flyer skips every other frame with no camera
## near, so the frame right after play_hit may not have written hit_flash yet): read it as its default 0.0.
func _iu(gi: GeometryInstance3D, name: StringName) -> float:
	var v: Variant = gi.get_instance_shader_parameter(name)
	return 0.0 if v == null else float(v)


func _tip(m: Node3D, side: String = "R") -> Vector3:
	var mi := m.get_node("Root/Body/Wing%s/Wing%s2/Wing%s2Mesh" % [side, side, side]) as Node3D
	var p := FINGER_1
	if side == "L":
		p.x = -p.x
	return m.global_transform.affine_inverse() * (mi.global_transform * p)


## The material of surface s as rendered (override first).
static func _surf_mat(mi: MeshInstance3D, s: int) -> Material:
	if mi.material_override:
		return mi.material_override
	var m := mi.get_surface_override_material(s)
	return m if m else mi.mesh.surface_get_material(s)


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
	# a Cinder Dragon in the same world (shared static caches, shared leg meshes)
	var cinder: Node3D = (load(CINDER) as PackedScene).instantiate()
	var h3 := Node3D.new()
	h3.position = Vector3(-20, 0, 0)
	world.add_child(h3)
	h3.add_child(cinder)
	await _frames(3)

	# ---- rig + hooks present
	var scr: Script = m.get_script()
	var chain: PackedStringArray = PackedStringArray()
	while scr:
		chain.append(scr.get_global_name())
		scr = scr.get_base_script()
	print("script chain: ", " > ".join(chain))
	_check(chain.has("FlyerModel") and chain.has("CinderDragonModel"), "built on FlyerModel / CinderDragonModel")
	for hk: String in ["set_moving", "set_turning", "play_attack", "play_hit", "play_death", "set_team_color",
			"set_status", "revive", "get_breath_origin", "play_level_up", "set_veterancy", "play_cast"]:
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
	var tris := 0
	var shadow_casters := 0
	var glow_parts := PackedStringArray()
	for n: Node in geo:
		if n is GPUParticles3D:
			continue
		var gi := n as GeometryInstance3D
		if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			shadow_casters += 1
		var mi := gi as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				var mat := _surf_mat(mi, s)
				var path := mat.resource_path if mat else "<none>"
				mats[path] = true
				var arr := mi.mesh.surface_get_arrays(s)
				verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				tris += (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
				if path.ends_with("frost_glow.tres") or path.ends_with("frost_ice.tres"):
					glow_parts.append("%s/%s" % [mi.name, path.get_file().get_basename()])
	var own := 0
	for p: String in mats:
		if p.begins_with(OWN_DIR):
			own += 1
		else:
			_check(p == BLOB_MAT, "material outside the frost dragon folder: '%s'" % p)
	print("materials: %d own + %d shared (%s)" % [own, mats.size() - own, ", ".join(PackedStringArray(mats.keys()))])
	print("triangles %d, vertices %d, shadow casters %d" % [tris, verts, shadow_casters])
	print("glow parts (cold glow / glowing ice): %s" % ", ".join(glow_parts))
	_check(own <= 6, "materials %d <= 6" % own)
	_check(verts <= 16000, "vertices %d <= 16000" % verts)
	_check(tris <= 20000, "triangles %d <= 20000" % tris)

	# ---- the Cinder Dragon is untouched: its legs keep its own materials (the frost overrides are per instance)
	var c_leg := cinder.get_node("Root/Body/LegFL/LegFLMesh") as MeshInstance3D
	var f_leg := m.get_node("Root/Body/LegFL/LegFLMesh") as MeshInstance3D
	_check(c_leg.mesh == f_leg.mesh, "the legs are the Cinder Dragon's meshes (shared)")
	_check(_surf_mat(c_leg, 0).resource_path.begins_with(CINDER_DIR), "cinder legs keep cinder materials")
	_check(_surf_mat(f_leg, 0).resource_path.begins_with(OWN_DIR), "frost legs use frost materials")
	var c_body := cinder.get_node("Root/Body/BodyMesh") as MeshInstance3D
	_check(c_body.mesh != (m.get_node("Root/Body/BodyMesh") as MeshInstance3D).mesh, "own body mesh")
	_check(_surf_mat(c_body, 0).resource_path.begins_with(CINDER_DIR), "cinder body keeps cinder materials")

	# ---- instance-uniform slot audit (every shader of every geometry instance)
	var collisions := 0
	for n: Node in geo:
		if n is GPUParticles3D:
			continue
		var gi := n as MeshInstance3D
		if gi == null or gi.mesh == null:
			continue
		var by_slot := {}
		var seen := {}
		for s: int in gi.mesh.get_surface_count():
			var mat := _surf_mat(gi, s)
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
	if collisions == 0:
		print("KITFIX AUDIT OK (frost dragon: slot map, no collision)")

	# ---- size (rest pose = the authored model-space vertices, at BAKE_HEIGHT 4.0)
	var body := m.get_node("Root/Body") as Node3D
	var min_p := Vector3(99, 99, 99)
	var max_p := Vector3(-99, -99, -99)
	var wing_min_x := 99.0
	var wing_max_x := -99.0
	var top_name := ""
	for n: Node in geo:
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null or mi.name == "Shadow":
			continue
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				min_p = min_p.min(v)
				if v.y > max_p.y:
					top_name = "%s/%s" % [mi.name, _surf_mat(mi, s).resource_path.get_file()]
				max_p = max_p.max(v)
				if String(mi.name).begins_with("Wing") and _surf_mat(mi, s).resource_path.ends_with("membrane.tres"):
					wing_min_x = minf(wing_min_x, v.x)
					wing_max_x = maxf(wing_max_x, v.x)
	print("rest extent: span %.2f (membranes %.2f), length %.2f, y %.2f .. %.2f (top: %s)" % [max_p.x - min_p.x,
		wing_max_x - wing_min_x, max_p.z - min_p.z, min_p.y, max_p.y, top_name])
	_check(absf(wing_max_x - wing_min_x - 7.5) < 0.15, "wing span 7.5 m (%.2f)" % (wing_max_x - wing_min_x))
	_check(max_p.x - min_p.x < 8.3, "span with claws < 8.3 m")
	_check(min_p.y > 3.0 and max_p.y < 6.4, "the rest pose flies (y %.2f .. %.2f)" % [min_p.y, max_p.y])
	_check(top_name.begins_with("HeadMesh/frost_ice"), "the ice horns are the highest point (%s)" % top_name)
	_check(max_p.z - min_p.z < 8.6, "compact: length < 8.6 m (%.2f)" % (max_p.z - min_p.z))
	var blob := m.get_node_or_null("Shadow") as Node3D
	_check(blob != null and absf(blob.position.y - 0.02) < 0.01, "ground blob at the origin")

	# ---- hover: beat period ~1.3 s, big amplitude, the body bobs
	m.call(&"set_moving", 0.0)
	await _frames(30)
	var ys: PackedFloat32Array = PackedFloat32Array()
	var by: PackedFloat32Array = PackedFloat32Array()
	for i: int in 200:
		await process_frame
		ys.append(_tip(m).y)
		by.append(body.global_position.y)
	var amp := _range(ys)
	var period := _period(ys)
	print("hover: tip swing %.2f m, beat period %.2f s, body bob %.2f m" % [amp, period, _range(by)])
	_check(amp > 2.0, "hover beat swings the wing tip > 2 m (%.2f)" % amp)
	_check(absf(period - 1.3) < 0.1, "beat period 1.3 s (%.2f)" % period)
	_check(_range(by) > 0.15, "hover bob")
	var avg_y := 0.0
	for v: float in by:
		avg_y += v
	avg_y /= float(by.size())
	_check(absf(avg_y - 4.0) < 0.3, "body flies at ~4 m (%.2f)" % avg_y)

	# ---- forward flight straight: glides happen
	m.call(&"set_moving", 5.0)
	var still_run := 0
	var best_still := 0
	for i: int in 600:
		await process_frame
		if float(m.get(&"_flap_amp_w")) < 0.02:
			still_run += 1
			best_still = maxi(best_still, still_run)
		else:
			still_run = 0
	print("forward flight: longest glide %.2f s" % (float(best_still) / 60.0))
	_check(best_still >= 90, "glides while flying straight (%.2f s)" % (float(best_still) / 60.0))

	# ---- bank: explicit set_turning, then measured from the visual's own yaw
	for i: int in 90:
		m.call(&"set_turning", 110.0)
		await process_frame
	var roll_r := body.global_transform.basis.x.y
	print("set_turning(110): body x axis y %.2f" % roll_r)
	_check(roll_r < -0.35, "turning toward +X banks the +X side down (%.2f)" % roll_r)
	for i: int in 120:
		await process_frame
	_check(absf(body.global_transform.basis.x.y) < 0.12, "levels out when the turn stops")
	for i: int in 90:
		holder.rotation.y -= deg_to_rad(110.0) * DT
		await process_frame
	var roll_auto := body.global_transform.basis.x.y
	_check(roll_auto > 0.35, "banks from its own measured yaw rate (%.2f)" % roll_auto)
	for i: int in 120:
		await process_frame

	# ---- breath (Rime Breath: 0.4 s windup in gameplay; the model releases at FlyerModel.BREATH_RELEASE)
	m.call(&"set_moving", 0.0)
	await _frames(60)
	var got_rel := [-1.0]
	var t0 := [0.0]
	m.connect(&"breath_released", func() -> void: got_rel[0] = t0[0], CONNECT_ONE_SHOT)
	var jaw := m.get_node("Root/Body/Neck1/Neck2/Head/Jaw") as Node3D
	var head_mesh := m.get_node("Root/Body/Neck1/Neck2/Head/HeadMesh") as GeometryInstance3D
	var spine_mesh := m.get_node("Root/Body/Neck1/Neck1Mesh") as GeometryInstance3D
	m.call(&"play_attack")
	var open_frames := 0
	var max_jaw := 0.0
	var max_flare := 0.0
	var max_spine := 0.0
	for i: int in 84:
		await process_frame
		t0[0] = float(i + 1) * DT
		var ja := jaw.rotation.x
		max_jaw = maxf(max_jaw, ja)
		if ja > deg_to_rad(24.0):
			open_frames += 1
		max_flare = maxf(max_flare, float(head_mesh.get_instance_shader_parameter(&"glow_boost")))
		max_spine = maxf(max_spine, float(spine_mesh.get_instance_shader_parameter(&"glow_boost")))
	print("breath: released at %.2f s, jaw max %.0f deg, open %.2f s, throat glow %.2f, neck spines %.2f"
		% [got_rel[0], rad_to_deg(max_jaw), float(open_frames) * DT, max_flare, max_spine])
	_check(absf(got_rel[0] - 0.35) < 0.05, "breath_released at 0.35 s (%.2f)" % got_rel[0])
	_check(max_jaw > deg_to_rad(32.0), "jaw opens wide")
	_check(absf(float(open_frames) * DT - 0.6) < 0.12, "jaw open ~0.6 s")
	_check(max_flare > 1.8, "the cold glow flares in the throat (%.2f)" % max_flare)
	_check(max_spine > 1.5, "the neck spines flare (%.2f)" % max_spine)
	var bo: Transform3D = m.call(&"get_breath_origin")
	var head_tip := (m.get_node("Root/Body/Neck1/Neck2/Head") as Node3D).global_position
	print("breath origin at rest: ", bo.origin, " forward ", bo.basis.z)
	var mouth_d := bo.origin.distance_to(head_tip)
	_check(mouth_d > 0.8 and mouth_d < 1.5 and bo.origin.y > 3.5, "breath origin at the snout (%.2f m)" % mouth_d)
	await _frames(20)
	_check(StringName(m.get(&"_action")) == &"", "breath ends")

	# ---- hit
	var flashed := false
	var jolt := 0.0
	var z0 := body.position.z
	m.call(&"play_hit")
	for i: int in 6:
		await process_frame
		if _iu(head_mesh, &"hit_flash") > 0.5:
			flashed = true
		jolt = minf(jolt, body.position.z - z0)
	_check(flashed, "play_hit flashes white")
	_check(jolt < -0.08, "play_hit jolts the body back (%.2f)" % jolt)
	await _frames(30)
	_check(_iu(head_mesh, &"hit_flash") == 0.0, "flash ends")

	# ---- team colour: membrane tint (and before _ready); default = the spec's Ice membrane colour
	var wing_nodes := ["Root/Body/WingL/WingLMesh", "Root/Body/WingL/WingL2/WingL2Mesh", "Root/Body/WingR/WingRMesh",
		"Root/Body/WingR/WingR2/WingR2Mesh"]
	var t_def: Variant = (m.get_node(wing_nodes[0]) as GeometryInstance3D).get_instance_shader_parameter(&"membrane_tint")
	_check(t_def is Vector3 and (t_def as Vector3).is_equal_approx(Vector3(0.55, 0.80, 0.95)), "default tint (0.55, 0.80, 0.95)")
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
	m.call(&"set_status", &"frozen", true)
	await _frames(4)
	var fz := _tip(m).y
	await _frames(40)
	_check(absf(_tip(m).y - fz) < 0.25, "frozen holds the wings")
	m.call(&"set_status", &"frozen", false)
	await _frames(10)

	# ---- death
	var got := [false]
	var crash_t := [-1.0]
	var death_frames := [0]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.connect(&"crashed", func(_at: Vector3) -> void: crash_t[0] = float(death_frames[0]) * DT, CONNECT_ONE_SHOT)
	var tip_fx := m.find_child("TailFrost", true, false) as GPUParticles3D
	m.call(&"set_moving", 5.0)
	await _frames(20)
	var root3 := m.get_node("Root") as Node3D
	m.call(&"play_death")
	var max_spin := 0.0
	var end_frame := -1
	var body_y_at_crash := 99.0
	for i: int in 150:
		await process_frame
		death_frames[0] = i + 1
		max_spin = maxf(max_spin, absf(root3.rotation.y))
		if crash_t[0] >= 0.0 and body_y_at_crash > 90.0:
			body_y_at_crash = body.global_position.y
		if i + 1 == 84:
			var tr := m.global_transform * _tip(m)
			var tl := m.global_transform * _tip(m, "L")
			print("  on the ground (1.4 s): wing tips y %.2f / %.2f" % [tr.y, tl.y])
			_check(tr.y > -0.3 and tl.y > -0.3 and tr.y < 1.7 and tl.y < 1.7, "both wings lie on the ground")
		if got[0]:
			end_frame = i + 1
			break
	print("death: crashed at %.2f s, body y at crash %.2f, spin %.0f deg, finished after %.2f s" % [crash_t[0],
		body_y_at_crash, rad_to_deg(max_spin), float(end_frame) * DT])
	_check(got[0], "death_finished emitted")
	_check(end_frame > 0 and float(end_frame) * DT < 1.97, "death < 2.0 s")
	_check(crash_t[0] > 0.9 and crash_t[0] < 1.3, "crash at ~1.1 s")
	_check(body_y_at_crash < 1.2, "the body hits the ground")
	_check(float(body_mesh.get_instance_shader_parameter(&"glow_boost")) <= 0.01, "the cold glow goes out")
	_check(tip_fx != null and not tip_fx.emitting, "tail frost stops at the crash")
	m.call(&"revive")
	await _frames(4)
	_check(absf(body.global_position.y - 4.0) < 0.4, "revive: flying again")
	_check(float(body_mesh.get_instance_shader_parameter(&"glow_boost")) > 0.9, "revive: glow back")
	_check(m.is_processing(), "revived model processes")

	# ---- cost: 6 frost dragons flying (headless = tier 1)
	for i: int in 6:
		var c: Node3D = ps.instantiate()
		c.position = Vector3(float(i) * 9.0, 0, 30.0)
		world.add_child(c)
		c.call(&"set_moving", 5.0 if i % 2 == 0 else 0.0)
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
	var code := sh.code
	# follow #include lines (the frost ice shader includes the Ice army crystal body)
	for line: String in sh.code.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("#include"):
			var q := l.split("\"")
			if q.size() >= 2:
				var inc := load(q[1]) as ShaderInclude
				if inc:
					code += "\n" + inc.code
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


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()
