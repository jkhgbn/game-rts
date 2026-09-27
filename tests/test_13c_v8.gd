extends SceneTree
## Task 13c.V8: the Frost Wyrm model (art/units/neutral/beasts/frost_wyrm/, titans-2.md 7 / 11), the neutral epic beast
## over the river, built on the FlyerModel rig (flyer_model.gd) with a skinned serpent body.
## Run:  $GODOT --headless --path . -s tests/test_13c_v8.gd --fixed-fps 60 --quit-after 6000
## Checks: headless instantiation (A, a B whose set_variant came before _ready); it IS a FlyerModel (the kit hooks) +
## the beast hooks (set_variant / get_variant, set_grounded / is_grounded, play_cast of the 3 casts, enrage); the
## TITAN budget (<= 36 meshes, <= 20 draw instances, 0 lights, <= 2 particle systems, own materials + the kit blob,
## vertices / triangles printed); instance-uniform slot audit (KITFIX); the skinned body (25 bones, 25 binds, bone
## weights); the airborne read (a long serpent: body at 4 m, spine 12.5 m, length >> width, the S-wave moves), wingless
## and longer than the Frost Dragon (unchanged: its own materials); grounded = coiled (low, round, about one turn,
## centred, head raised low) in 0.8 s and back; Rime Breath (breath_released 0.35 s, jaw, flare); Glacial Dive
## (dive_landed at 1.0 s with the head at the ground, ends grounded, the 6 s fallback take-off, explicit set_grounded
## keeps it down); Tail Lash (tail_struck 0.35 s, a wide sweep); Blizzard (blizzard_released 0.75 s, rears up, roar);
## hit; variant B (x1.15, crystal horns, B materials, motes) and back; enrage (hook + the unit's `beast:enrage`
## modifier polled); frozen stops the writhe; death airborne and grounded (crash, glow out, death_finished < 2.0 s),
## revive. Prints PASS 13c.v8 / FAIL 13c.v8: <reason>.

const TASK_ID := "13c.v8"
const SCENE := "res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn"
const DRAGON := "res://art/units/titans/frost_dragon/frost_dragon.tscn"
const OWN_DIR := "res://art/units/neutral/beasts/frost_wyrm/"
const DRAGON_DIR := "res://art/units/titans/frost_dragon/"
const BLOB_MAT := "res://art/units/kit/materials/unit_shadow_blob.tres"
const KIT_SLOTS := {"ao_bottom": 1, "ao_height": 2, "hit_flash": 3, "flash_color": 4, "glow_boost": 5, "blob_color": 6}
const FAKE_UNIT_SRC := "extends Node3D\nvar enraged := false\nfunc has_modifier(id: StringName) -> bool:\n\treturn enraged and id == &\"beast:enrage\"\n"
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


static func _surf_mat(mi: MeshInstance3D, s: int) -> Material:
	if mi.material_override:
		return mi.material_override
	var m := mi.get_surface_override_material(s)
	return m if m else mi.mesh.surface_get_material(s)


static func _names(m: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		for s: int in mi.mesh.get_surface_count():
			var p := _surf_mat(mi, s).resource_path.get_file()
			if not out.has(p):
				out.append(p)
	out.sort()
	return out


## Spine points in the model's local space.
static func _spine(m: Node3D) -> PackedVector3Array:
	return m.call(&"spine_points")


static func _extent(pts: PackedVector3Array) -> AABB:
	var a := AABB(pts[0], Vector3.ZERO)
	for p: Vector3 in pts:
		a = a.expand(p)
	return a


func _run() -> void:
	var ps := load(SCENE) as PackedScene
	_check(ps != null, "scene loads")
	if ps == null:
		_finish()
		return
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 30, 25)
	world.add_child(cam)
	cam.make_current()
	var holder := Node3D.new()
	world.add_child(holder)
	var m: Node3D = ps.instantiate()
	holder.add_child(m)
	var early: Node3D = ps.instantiate()
	early.call(&"set_variant", 1)       # before _ready: kept and applied
	var h2 := Node3D.new()
	h2.position = Vector3(18, 0, 0)
	world.add_child(h2)
	h2.add_child(early)
	var dragon: Node3D = (load(DRAGON) as PackedScene).instantiate()
	var h3 := Node3D.new()
	h3.position = Vector3(-18, 0, 0)
	world.add_child(h3)
	h3.add_child(dragon)
	await _frames(3)

	# ---- rig + hooks
	var scr: Script = m.get_script()
	var chain: PackedStringArray = PackedStringArray()
	while scr:
		chain.append(scr.get_global_name())
		scr = scr.get_base_script()
	print("script chain: ", " > ".join(chain))
	_check(chain.has("FlyerModel"), "built on FlyerModel")
	for hk: String in ["set_moving", "set_turning", "play_attack", "play_hit", "play_death", "set_team_color",
			"set_status", "revive", "get_breath_origin", "play_level_up", "set_veterancy", "play_cast", "set_carrying",
			"play_mine", "set_variant", "get_variant", "set_grounded", "is_grounded", "grounded_ratio", "set_enraged",
			"is_enraged", "get_tail_tip", "get_head_point"]:
		_check(m.has_method(hk), "hook %s" % hk)
	for sg: String in ["death_finished", "breath_released", "crashed", "dive_landed", "tail_struck", "blizzard_released"]:
		_check(m.has_signal(sg), "signal %s" % sg)
	_check(float(m.get(&"attack_windup")) <= 0.15, "attack_windup <= 0.15")
	_check(m.find_children("Wing*", "", true, false).is_empty(), "wingless: no wing pivots / meshes")
	_check(dragon.find_children("Wing*", "", true, false).size() >= 4, "the Frost Dragon has its wings")

	# ---- budgets (titan: titans-2.md 11)
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
	_check(meshes == int(m.call(&"authored_mesh_count")), "authored_mesh_count matches")
	_check(geo.size() <= 20, "draw instances %d <= 20" % geo.size())
	_check(parts <= 2, "particle systems %d <= 2" % parts)
	_check(m.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	var mats := {}
	var verts := 0
	var tris := 0
	var casters := PackedStringArray()
	for n: Node in geo:
		if n is GPUParticles3D:
			continue
		var gi := n as GeometryInstance3D
		if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			casters.append(gi.name)
		var mi := gi as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				var mat := _surf_mat(mi, s)
				mats[mat.resource_path if mat else "<none>"] = true
				var arr := mi.mesh.surface_get_arrays(s)
				verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	var own := 0
	for p: String in mats:
		if p.begins_with(OWN_DIR):
			own += 1
		else:
			_check(p == BLOB_MAT, "material outside the frost wyrm folder: '%s'" % p)
	print("materials (A): %d own + %d shared (%s)" % [own, mats.size() - own, ", ".join(PackedStringArray(mats.keys()))])
	print("triangles %d, vertices %d, shadow casters %s" % [tris, verts, ", ".join(casters)])
	_check(own <= 6, "materials per variant %d <= 6" % own)
	_check(verts <= 16000, "vertices %d <= 16000" % verts)
	_check(tris <= 20000, "triangles %d <= 20000" % tris)

	# ---- instance-uniform slot audit
	var collisions := 0
	for n: Node in geo:
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
		print("KITFIX AUDIT OK (frost wyrm: slot map, no collision)")

	# ---- the skinned body
	var skel := m.find_child("Spine", true, false) as Skeleton3D
	var body_mi := m.find_child("BodyMesh", true, false) as MeshInstance3D
	_check(skel != null and skel.get_bone_count() == 25, "Skeleton3D Spine with 25 bones")
	_check(body_mi != null and body_mi.skin != null and body_mi.skin.get_bind_count() == 25, "body skin: 25 binds")
	if body_mi:
		var arr0 := body_mi.mesh.surface_get_arrays(0)
		_check(arr0[Mesh.ARRAY_BONES] != null and (arr0[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array).size() > 0,
			"body mesh has bone weights")
		_check(body_mi.get_node_or_null(body_mi.skeleton) == skel, "body mesh bound to the skeleton")

	# ---- airborne read: a long serpent flying at 4 m
	m.call(&"set_moving", 0.0)
	await _frames(40)
	var sp := _spine(m)
	var ext := _extent(sp)
	var spine_len := 0.0
	for i: int in range(1, sp.size()):
		spine_len += sp[i].distance_to(sp[i - 1])
	print("air: chest y %.2f, head joint y %.2f, lowest %.2f, extent x %.2f z %.2f, spine %.2f m" % [sp[5].y, sp[0].y,
		ext.position.y, ext.size.x, ext.size.z, spine_len])
	_check(absf(sp[5].y - 4.0) < 0.35, "the chest flies at ~4 m (%.2f)" % sp[5].y)
	_check(sp[0].y > sp[5].y, "hover: the neck is raised")
	_check(ext.position.y > 1.8, "airborne: nothing low (%.2f)" % ext.position.y)
	_check(absf(spine_len - 12.5) < 0.05, "spine length stays 12.5 m (%.2f)" % spine_len)
	_check(ext.size.z > 8.0 and ext.size.z > 2.2 * ext.size.x, "a long serpent (z %.2f, x %.2f)" % [ext.size.z, ext.size.x])
	# the dragon beside it: compact, and shorter
	var d_len := _mesh_extent(dragon).size.z
	print("frost dragon rest length %.2f m vs the wyrm's %.2f m" % [d_len, ext.size.z])
	_check(ext.size.z > d_len + 2.0, "the wyrm is much longer than the Frost Dragon")
	var d_leg := dragon.get_node("Root/Body/LegFL/LegFLMesh") as MeshInstance3D
	_check(_surf_mat(d_leg, 0).resource_path.begins_with(DRAGON_DIR), "Frost Dragon keeps its own materials")
	# the S-wave travels: the tail swings
	var tx: PackedFloat32Array = PackedFloat32Array()
	for i: int in 150:
		await process_frame
		tx.append(_spine(m)[24].x)
	print("hover: tail tip swing %.2f m over 2.5 s" % _range(tx))
	_check(_range(tx) > 0.8, "the body writhes (tail swing %.2f)" % _range(tx))
	m.call(&"set_moving", 5.5)
	await _frames(80)
	var sp_m := _spine(m)
	print("moving: head joint y %.2f (hover %.2f)" % [sp_m[0].y, sp[0].y])
	_check(sp_m[0].y < sp[0].y, "moving: the neck lowers (streamlined)")
	# bank from set_turning
	for i: int in 60:
		m.call(&"set_turning", 90.0)
		await process_frame
	var hp_turn := _spine(m)[0]
	print("turning toward +X: head joint x %.2f" % hp_turn.x)
	_check(hp_turn.x > 0.3, "the body curves into the turn")
	m.call(&"set_moving", 0.0)
	await _frames(60)

	# ---- grounded: coiled
	var t0 := Time.get_ticks_msec()
	m.call(&"set_grounded", true)
	await _frames(24)
	var mid_r := float(m.call(&"grounded_ratio"))
	await _frames(30)
	var gr := float(m.call(&"grounded_ratio"))
	var sg := _spine(m)
	var low := 0
	var max_r := 0.0
	var c := Vector2.ZERO
	for i: int in range(9, 25):
		if sg[i].y < 0.6:
			low += 1
	for i: int in range(5, 25):
		max_r = maxf(max_r, Vector2(sg[i].x, sg[i].z).length())
		c += Vector2(sg[i].x, sg[i].z)
	c /= 20.0
	var turn := 0.0
	for i: int in range(6, 24):
		var a := Vector2(sg[i].x - sg[i - 1].x, sg[i].z - sg[i - 1].z)
		var b := Vector2(sg[i + 1].x - sg[i].x, sg[i + 1].z - sg[i].z)
		turn += a.angle_to(b)
	print("coil: ratio %.2f at 0.4 s, %.2f at 0.9 s; body bones on the ground %d / 16, radius %.2f m, centroid (%.2f, %.2f), wound %.0f deg, chest y %.2f, head joint (%.2f, %.2f, %.2f)"
		% [mid_r, gr, low, max_r, c.x, c.y, rad_to_deg(absf(turn)), sg[5].y, sg[0].x, sg[0].y, sg[0].z])
	_check(mid_r > 0.2 and mid_r < 0.8, "the landing is a 0.8 s blend (%.2f at 0.4 s)" % mid_r)
	_check(gr >= 0.999 and bool(m.call(&"is_grounded")), "grounded after 0.8 s")
	_check(low >= 15, "the body lies on the ground (%d / 16)" % low)
	_check(max_r < 3.4, "a tight coil (r %.2f < 3.4)" % max_r)
	_check(c.length() < 1.0, "coil centred on the unit (%.2f)" % c.length())
	_check(absf(turn) > deg_to_rad(300.0), "about one turn of coil (%.0f deg)" % rad_to_deg(absf(turn)))
	_check(sg[0].y > 1.2 and sg[0].y < 2.4, "the head is raised but low (%.2f)" % sg[0].y)
	var ll := m.get_node("Root/Body/LegFL") as Node3D
	var claw_y := (m.get_node("Root/Body/LegFL/LegFLMesh") as Node3D).global_transform * Vector3(-0.47, 3.0, 1.45)
	print("coil: foreleg claw y %.2f" % claw_y.y)
	_check(absf(claw_y.y) < 0.35 and ll != null, "forelegs planted (claw y %.2f)" % claw_y.y)
	# take off
	m.call(&"set_grounded", false)
	await _frames(54)
	var sa := _spine(m)
	_check(float(m.call(&"grounded_ratio")) <= 0.001 and absf(sa[5].y - 4.0) < 0.4, "takes off in 0.8 s (chest %.2f)" % sa[5].y)
	await _frames(30)

	# ---- Rime Breath
	var got_rel := [-1.0]
	var tt := [0.0]
	m.connect(&"breath_released", func() -> void: got_rel[0] = tt[0], CONNECT_ONE_SHOT)
	var jaw := m.get_node("Root/Body/Neck1/Neck2/Head/Jaw") as Node3D
	var head_mesh := m.get_node("Root/Body/Neck1/Neck2/Head/HeadMesh") as GeometryInstance3D
	m.call(&"play_attack")
	var max_jaw := 0.0
	var max_flare := 0.0
	for i: int in 84:
		await process_frame
		tt[0] = float(i + 1) * DT
		max_jaw = maxf(max_jaw, jaw.rotation.x)
		max_flare = maxf(max_flare, float(head_mesh.get_instance_shader_parameter(&"glow_boost")))
	print("breath: released at %.2f s, jaw max %.0f deg, throat glow %.2f" % [got_rel[0], rad_to_deg(max_jaw), max_flare])
	_check(absf(got_rel[0] - 0.35) < 0.05, "breath_released at 0.35 s (%.2f)" % got_rel[0])
	_check(max_jaw > deg_to_rad(32.0), "jaw opens wide")
	_check(max_flare > 1.8, "the cold glow flares (%.2f)" % max_flare)
	var bo: Transform3D = m.call(&"get_breath_origin")
	var hj: Vector3 = m.call(&"get_head_point")
	_check(bo.origin.distance_to(hj) > 1.0 and bo.origin.distance_to(hj) < 1.8, "breath origin at the snout")
	await _frames(30)
	_check(StringName(m.get(&"_action")) == &"", "breath ends")

	# ---- Glacial Dive (no set_grounded from gameplay: the fallback take-off after 6 s)
	var dive_t := [-1.0]
	var dive_at := [Vector3.ZERO]
	var ft := [0.0]
	m.connect(&"dive_landed", func(at: Vector3) -> void:
		dive_t[0] = ft[0]
		dive_at[0] = at, CONNECT_ONE_SHOT)
	m.call(&"play_cast", &"glacial_dive")
	var max_y := 0.0
	var head_at_impact := 99.0
	for i: int in 96:
		await process_frame
		ft[0] = float(i + 1) * DT
		var s2 := _spine(m)
		max_y = maxf(max_y, s2[5].y)
		if dive_t[0] > 0.0 and head_at_impact > 90.0:
			head_at_impact = s2[0].y
	print("dive: climbs to %.2f, lands at %.2f s (head joint y %.2f, at %s), ratio after %.2f" % [max_y, dive_t[0],
		head_at_impact, dive_at[0], float(m.call(&"grounded_ratio"))])
	_check(max_y > 4.8, "the dive climbs first (%.2f)" % max_y)
	_check(absf(dive_t[0] - 1.0) < 0.05, "dive_landed at 1.0 s (%.2f)" % dive_t[0])
	_check(head_at_impact < 1.3, "the head hits the ground (%.2f)" % head_at_impact)
	_check(bool(m.call(&"is_grounded")) and float(m.call(&"grounded_ratio")) > 0.99, "the dive ends coiled")
	_check(int(m.call(&"burst_count")) >= 1, "ice burst at the impact")

	# ---- Tail Lash (grounded)
	var lash_t := [-1.0]
	var lt := [0.0]
	m.connect(&"tail_struck", func(_at: Vector3) -> void: lash_t[0] = lt[0], CONNECT_ONE_SHOT)
	var tip0 := _spine(m)[24]
	m.call(&"play_cast", &"tail_lash")
	var sweep := 0.0
	var lift := 0.0
	for i: int in 56:
		await process_frame
		lt[0] = float(i + 1) * DT
		var tp := _spine(m)[24]
		sweep = maxf(sweep, Vector2(tp.x - tip0.x, tp.z - tip0.z).length())
		lift = maxf(lift, tp.y - tip0.y)
	print("tail lash: strike at %.2f s, tail tip sweep %.2f m, lift %.2f m" % [lash_t[0], sweep, lift])
	_check(absf(lash_t[0] - 0.35) < 0.05, "tail_struck at 0.35 s (%.2f)" % lash_t[0])
	_check(sweep > 2.0, "a wide tail sweep (%.2f m)" % sweep)
	_check(lift > 0.15, "the tail lifts off the ground")

	# ---- the fallback take-off: 6 s after the dive without any set_grounded call
	var waited: float = (96.0 - float(dive_t[0]) * 60.0 + 56.0) * DT     # frames since the impact (dive loop + lash loop)
	var took_off_at := -1.0
	for i: int in 300:
		await process_frame
		if not bool(m.call(&"is_grounded")):
			took_off_at = waited + float(i + 1) * DT
			break
	print("dive fallback: takes off %.2f s after the impact" % took_off_at)
	_check(absf(took_off_at - 6.0) < 0.2, "takes off by itself 6 s after a dive (%.2f)" % took_off_at)
	await _frames(60)
	_check(absf(_spine(m)[5].y - 4.0) < 0.5, "airborne again after the fallback")

	# ---- explicit grounding keeps it down after a dive
	m.call(&"play_cast", &"glacial_dive")
	await _frames(10)
	m.call(&"set_grounded", true)
	await _frames(60 * 7)
	_check(bool(m.call(&"is_grounded")), "set_grounded(true) keeps it coiled past 6 s")

	# ---- Blizzard (from the ground)
	var bl_t := [-1.0]
	var bt := [0.0]
	m.connect(&"blizzard_released", func(_at: Vector3) -> void: bl_t[0] = bt[0], CONNECT_ONE_SHOT)
	var hy0 := _spine(m)[0].y
	var max_hy := 0.0
	max_jaw = 0.0
	m.call(&"play_cast", &"blizzard")
	for i: int in 110:
		await process_frame
		bt[0] = float(i + 1) * DT
		max_hy = maxf(max_hy, _spine(m)[0].y)
		max_jaw = maxf(max_jaw, jaw.rotation.x)
	print("blizzard: released at %.2f s, head joint rises %.2f -> %.2f, jaw %.0f deg" % [bl_t[0], hy0, max_hy,
		rad_to_deg(max_jaw)])
	_check(absf(bl_t[0] - 0.75) < 0.05, "blizzard_released at 0.75 s (%.2f)" % bl_t[0])
	_check(max_hy > hy0 + 0.6, "rears up for the Blizzard")
	_check(max_jaw > deg_to_rad(38.0), "roars (jaw wide)")
	m.call(&"set_grounded", false)
	await _frames(60)

	# ---- hit
	var flashed := false
	var body := m.get_node("Root/Body") as Node3D
	var z0 := body.position.z
	var jolt := 0.0
	m.call(&"play_hit")
	for i: int in 6:
		await process_frame
		if float(head_mesh.get_instance_shader_parameter(&"hit_flash")) > 0.5:
			flashed = true
		jolt = minf(jolt, body.position.z - z0)
	_check(flashed, "play_hit flashes white")
	_check(jolt < -0.05, "play_hit jolts the body back (%.2f)" % jolt)
	await _frames(30)

	# ---- neutral: no team colour; statuses
	m.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	_check(_names(m).has("wyrm_scale_a.tres"), "set_team_color is a no-op")
	_check(bool(m.call(&"set_status", &"haste", true)), "set_status haste -> true")
	m.call(&"set_status", &"haste", false)
	m.call(&"set_status", &"frozen", true)
	await _frames(4)
	var fz := _spine(m)[24]
	await _frames(40)
	_check(_spine(m)[24].distance_to(fz) < 0.25, "frozen stops the writhe")
	m.call(&"set_status", &"frozen", false)

	# ---- variants
	var root_b := early.get_node("Root") as Node3D
	_check(int(early.call(&"get_variant")) == 1, "set_variant before _ready kept")
	_check(root_b.scale.is_equal_approx(Vector3.ONE * 1.15), "B is x1.15")
	var nb := _names(early)
	print("B materials: ", ", ".join(nb))
	_check(nb.has("wyrm_scale_b.tres") and nb.has("wyrm_fin_b.tres") and nb.has("wyrm_ice_b.tres")
		and nb.has("wyrm_eye_b.tres") and not nb.has("wyrm_scale_a.tres"), "B uses the B materials")
	var hb := early.get_node("Root/Body/Neck1/Neck2/Head/HeadMesh") as MeshInstance3D
	var ha := m.get_node("Root/Body/Neck1/Neck2/Head/HeadMesh") as MeshInstance3D
	_check(hb.mesh != ha.mesh, "B has its own head (crystal horns)")
	var hb_top := _mesh_extent_of(hb.mesh).end.y
	var ha_top := _mesh_extent_of(ha.mesh).end.y
	print("head top A %.2f, B %.2f (horns)" % [ha_top, hb_top])
	_check(hb_top > ha_top + 0.1, "B's horns rise above the crest")
	var motes := early.find_child("Motes", true, false) as GPUParticles3D
	var motes_a := m.find_child("Motes", true, false) as GPUParticles3D
	_check(motes != null and motes.visible and motes.emitting, "B sheds frost motes (< 45 m)")
	_check(motes_a != null and not motes_a.visible and not motes_a.emitting, "A has no motes")
	var sb := _spine(early)
	print("B airborne chest y %.2f" % sb[5].y)
	_check(absf(sb[5].y - 4.0) < 0.4, "B also flies at ~4 m")
	_check(absf(float(early.get(&"body_height")) - 6.9) < 0.01, "B HP bar higher (6.9)")
	early.call(&"set_variant", 0)
	_check(_names(early).has("wyrm_scale_a.tres") and root_b.scale.is_equal_approx(Vector3.ONE)
		and hb.mesh == ha.mesh and not motes.visible, "set_variant(0) restores A")
	early.call(&"set_variant", 1)

	# ---- enrage: hook + the owning unit's modifier (polled)
	m.call(&"set_enraged", true)
	await _frames(3)
	_check(bool(m.call(&"is_enraged")), "set_enraged")
	m.call(&"set_enraged", false)
	var fake := Node3D.new()
	var fs := GDScript.new()
	fs.source_code = FAKE_UNIT_SRC
	fs.reload()
	fake.set_script(fs)
	fake.position = Vector3(0, 0, 40)
	world.add_child(fake)
	var u: Node3D = ps.instantiate()
	fake.add_child(u)
	await _frames(5)
	fake.set(&"enraged", true)
	await _frames(40)
	_check(bool(u.call(&"is_enraged")), "unit modifier beast:enrage -> enraged (polled)")
	fake.set(&"enraged", false)
	await _frames(40)
	_check(not bool(u.call(&"is_enraged")), "modifier gone -> calm")

	# ---- death airborne
	var got := [false]
	var crash_t := [-1.0]
	var df := [0]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.connect(&"crashed", func(_at: Vector3) -> void: crash_t[0] = float(df[0]) * DT, CONNECT_ONE_SHOT)
	var body_mesh := m.get_node("Root/Spine/BodyMesh") as GeometryInstance3D
	m.call(&"set_moving", 5.0)
	await _frames(20)
	m.call(&"play_death")
	var end_frame := -1
	var chest_at_crash := 99.0
	for i: int in 150:
		await process_frame
		df[0] = i + 1
		if crash_t[0] >= 0.0 and chest_at_crash > 90.0:
			chest_at_crash = _spine(m)[5].y
		if got[0]:
			end_frame = i + 1
			break
	print("death (air): crashed at %.2f s, chest y at crash %.2f, finished after %.2f s" % [crash_t[0], chest_at_crash,
		float(end_frame) * DT])
	_check(got[0], "death_finished emitted")
	_check(end_frame > 0 and float(end_frame) * DT < 1.97, "death < 2.0 s")
	_check(crash_t[0] > 0.8 and crash_t[0] < 1.1, "crash at ~0.95 s")
	_check(chest_at_crash < 1.0, "the body hits the ground")
	_check(float(body_mesh.get_instance_shader_parameter(&"glow_boost")) <= 0.01, "the glow goes out")
	m.call(&"revive")
	await _frames(4)
	_check(absf(_spine(m)[5].y - 4.0) < 0.5, "revive: flying again")
	_check(float(body_mesh.get_instance_shader_parameter(&"glow_boost")) > 0.9, "revive: glow back")
	_check(m.is_processing(), "revived model processes")

	# ---- death grounded
	m.call(&"set_grounded", true)
	await _frames(60)
	got[0] = false
	crash_t[0] = -1.0
	df[0] = 0
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.connect(&"crashed", func(_at: Vector3) -> void: crash_t[0] = float(df[0]) * DT, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	end_frame = -1
	for i: int in 150:
		await process_frame
		df[0] = i + 1
		if got[0]:
			end_frame = i + 1
			break
	print("death (coiled): crashed at %.2f s, finished after %.2f s" % [crash_t[0], float(end_frame) * DT])
	_check(got[0] and float(end_frame) * DT < 1.97, "grounded death < 2.0 s")
	_check(crash_t[0] > 0.4 and crash_t[0] < 0.75, "grounded crash at ~0.55 s")
	m.call(&"revive")
	await _frames(4)

	# ---- cost: 2 wyrms (the map has 2) + 2 more, flying / coiled (tier 0: within 45 m of the camera)
	var extra: Array[Node3D] = []
	for i: int in 4:
		var w: Node3D = ps.instantiate()
		w.position = Vector3(-12.0 + float(i) * 8.0, 0, -10.0)
		world.add_child(w)
		extra.append(w)
		if i % 2 == 0:
			w.call(&"set_moving", 5.0)
		else:
			w.call(&"set_grounded", true)
	await _frames(10)
	var us := Time.get_ticks_usec()
	for i: int in 60:
		for w: Node3D in extra:
			w.call(&"_animate", DT)
	print("wyrm pose + skeleton write: %.3f ms per wyrm per frame" % (float(Time.get_ticks_usec() - us) / 240.0 / 1000.0))
	print("test wall time %.1f s" % (float(Time.get_ticks_msec() - t0) / 1000.0))
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


## Model-space extent of every mesh (rest vertices, the node offsets applied) under m, the blob excluded.
static func _mesh_extent(m: Node3D) -> AABB:
	var a := AABB()
	var first := true
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var xf := m.global_transform.affine_inverse() * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var p := xf * v
				if first:
					a = AABB(p, Vector3.ZERO)
					first = false
				else:
					a = a.expand(p)
	return a


static func _mesh_extent_of(mesh: Mesh) -> AABB:
	var a := AABB()
	var first := true
	for s: int in mesh.get_surface_count():
		for v: Vector3 in (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			if first:
				a = AABB(v, Vector3.ZERO)
				first = false
			else:
				a = a.expand(v)
	return a


static func _instance_uniforms(sh: Shader) -> Array:
	var out: Array = []
	if sh == null:
		return out
	var code := sh.code
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
