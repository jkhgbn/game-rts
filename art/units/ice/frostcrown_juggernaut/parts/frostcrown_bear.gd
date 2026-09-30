extends MountModel
## Frostcrown war-bear (stables.md 2 slot V, the Ice tier-3 elite): the mount half of frostcrown_juggernaut.tscn.
## A colossal armoured ice bear, ~3.0 m nose to tail, withers ~1.8 m: a deep slate-blue barrel on four pillar legs, a
## towering shoulder hump crowned by a RIDGE OF THREE BIG CYAN ICE CRYSTALS (the 40 m read, echoing the rider's crown),
## a lighter slate ruff over the shoulders and muzzle, a low heavy head with round ears under a steel chanfron and two
## swept-back brow crystals, pale ice-stone claws. Heavy steel pauldrons on both shoulders, steel knee cops.
## TEAM CAPARISON: a big team-dark (ice_cloth_dark) blanket over the whole back and upper flanks behind the hump with a
## light team hem (ice_cloth) = the top-facing team colour, a leather saddle.
## Palette (Ice in-game fix, under_90.md B): steel-blue / slate mid-tones, cyan crystals as the accent, NO near-white
## masses (the pale ice_fur_pale / ice_hair are not used on the bear).
## Glow: the ice-blue eyes (CreatureFaceRig irises, host mode: drawn inside the merged head, no extra node).
## Motion: MountModel's heavy walk / gallop (from 3.2 m/s), a "shoulder roll" fidget (the bear rolls its hump, shakes
## its head, the crystals flare), the generic charge and hit; death: stumbles, rolls onto its side and frosts over.
## Budget (cavalry unit, the rider included: <= 12 draw instances, ~3000 vertices): 7 draw instances (Body, Head,
## 4 legs, blob), one-sided drapes instead of thick shells, 0 lights, 0 particles.

const OWN := "res://art/units/ice/frostcrown_juggernaut/materials/"
const ICE := "res://art/units/ice/materials/"
const BLOB_TINT := Color(0.03, 0.05, 0.11, 0.55)
const FROST := Vector3(0.22, 0.52, 1.0)

## Barrel of revolution along z, centred on BC, vertical squash SY. Profile [z offset, radius].
const BC := Vector3(0, 0.96, -0.10)
const SY := 0.97
const BARREL_Z: Array[float] = [-0.98, -0.90, -0.70, -0.30, 0.18, 0.56, 0.80, 0.90]
const BARREL_R: Array[float] = [0.00, 0.30, 0.49, 0.565, 0.59, 0.555, 0.40, 0.00]
const HUMP_C := Vector3(0, 1.36, 0.40)
const HUMP_R := Vector3(0.52, 0.40, 0.50)
const RUMP_C := Vector3(0, 1.12, -0.66)
const RUMP_R := Vector3(0.47, 0.36, 0.42)
## Head: skull centre and radii (sphere 0.29 scaled), muzzle path.
const SKULL_C := Vector3(0, 1.14, 1.20)
const SKULL_S := Vector3(1.0, 0.86, 1.08)
const SKULL_R := 0.29

var _frost_v: float = 0.0
var _face: CreatureFaceRig


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "frostcrown_bear", face_style())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	ensure_shadow_blob(0.75, BLOB_TINT)
	_shadow.scale = Vector3(2.4, 1.0, 4.0)
	_shadow.position = Vector3(0, 0.02, 0.1)


static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("fj_") else ICE) + name + ".tres")


# ================================================================ mesh helpers (one-sided, cheap)

## One-sided curved drape (saddle-cloth, caparison, plates): a patch of an elliptic cylinder around local +Z, outer side
## only, smooth normals, indexed ((seg_a + 1) x (seg_l + 1) vertices). Angle a (deg) from +Y toward +X, l along Z.
## scale(l) = lerp(1, taper, v) x (1 + bulge sin(pi v)); `sag` pushes the lower rows outward (a hanging hem).
static func drape_mesh(key: String, rx: float, ry: float, a0: float, a1: float, l0: float, l1: float, seg_a: int,
		seg_l: int, taper: float = 1.0, bulge: float = 0.0, sag: float = 0.0) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for il: int in seg_l + 1:
		var v := float(il) / float(seg_l)
		var l := lerpf(l0, l1, v)
		var sc := lerpf(1.0, taper, v) * (1.0 + bulge * sin(PI * v))
		for ia: int in seg_a + 1:
			var a := deg_to_rad(lerpf(a0, a1, float(ia) / float(seg_a)))
			var down := clampf(-cos(a), 0.0, 1.0)
			var k := sc * (1.0 + sag * down)
			st.set_normal(Vector3(sin(a) / rx, cos(a) / ry, 0.0).normalized())
			st.add_vertex(Vector3(rx * sin(a) * k, ry * cos(a) * sc, l))
	var row := seg_a + 1
	for il: int in seg_l:
		for ia: int in seg_a:
			var i0 := il * row + ia
			var i1 := i0 + 1
			var i2 := i0 + row
			var i3 := i2 + 1
			# front faces outward (Godot: clockwise seen from the normal side)
			var o := (a1 - a0) * (l1 - l0)
			if o > 0.0:
				st.add_index(i0); st.add_index(i1); st.add_index(i3)
				st.add_index(i0); st.add_index(i3); st.add_index(i2)
			else:
				st.add_index(i0); st.add_index(i3); st.add_index(i1)
				st.add_index(i0); st.add_index(i2); st.add_index(i3)
	return _cached(key, st.commit())


## A flat-shaded open pyramid (claws, spikes): `sides` faces from a base ring of radius 1 at y 0 to the apex at y 1,
## no base cap (it sits inside another part): 3 x sides vertices. Scale it per use.
static func spike_mesh(sides: int = 3) -> Mesh:
	var key := "t3_spike_%d" % sides
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var apex := Vector3(0, 1, 0)
	for i: int in sides:
		var a0 := TAU * float(i) / float(sides)
		var a1 := TAU * float(i + 1) / float(sides)
		var p0 := Vector3(sin(a0), 0, cos(a0))
		var p1 := Vector3(sin(a1), 0, cos(a1))
		var n := (p1 - p0).cross(apex - p0).normalized()
		if n.dot(p0 + p1) < 0.0:
			n = -n
		# front face (clockwise seen from outside)
		var fn := (p1 - p0).cross(apex - p0)
		var b := p1
		var c := apex
		if fn.dot(n) > 0.0:
			b = apex
			c = p1
		for v: Vector3 in [p0, b, c]:
			st.set_normal(n)
			st.add_vertex(v)
	return _cached(key, st.commit())


## Ellipsoid sphere primitive placed at c with radii r (8 x 4 segments: 45 vertices).
static func _blob(s: Dictionary, mat: Material, c: Vector3, r: Vector3, rot_deg: Vector3 = Vector3.ZERO, seg: int = 8,
		rings: int = 4) -> void:
	sculpt_put(s, sphere(1.0, seg, rings), mat, c, rot_deg, r)


## [point, outward normal] on an ellipsoid at azimuth theta (deg from +z toward +x) and elevation phi (deg).
static func _ell_pt(c: Vector3, r: Vector3, theta_deg: float, phi_deg: float) -> Array:
	var th := deg_to_rad(theta_deg)
	var ph := deg_to_rad(phi_deg)
	var u := Vector3(cos(ph) * sin(th), sin(ph), cos(ph) * cos(th))
	return [c + u * r, (u / r).normalized()]


# ================================================================ body

func _body_sculpt(s: Dictionary) -> void:
	var fur := m("fj_fur")
	var ruff := m("fj_ruff")
	var ice := m("ice_frost_crystal")
	var steel := m("ice_steel")
	var cloth := m("ice_cloth")
	var cdark := m("ice_cloth_dark")
	var leather := m("ice_leather")
	# ---- mass: barrel, shoulder hump, rump
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	sculpt_add(s, lathe_mesh("fj_barrel_v2", prof, 8), Transform3D(Basis(Vector3.RIGHT, PI * 0.5) *
		Basis.from_scale(Vector3(1, 1, SY)), BC), fur)
	_blob(s, fur, HUMP_C, HUMP_R, Vector3.ZERO, 8, 4)
	_blob(s, fur, RUMP_C, RUMP_R)
	# ---- the slate ruff: a shaggy lighter cape over the shoulders and the front of the hump (open behind)
	sculpt_fringe(s, ruff, fringe_mesh("fj_ruff_v2", 0.44, 0.40, 0.60, 0.56, 0.26, -112.0, 112.0, 6, 0.13, 0.03, 0.6),
		HUMP_C + Vector3(0, 0.20, 0.08))
	# ---- the glacier ridge: three big cyan crystals along the hump crest, leaning forward (clear of the rider)
	var top := HUMP_C + Vector3(0, HUMP_R.y - 0.05, 0.0)
	sculpt_crystal(s, ice, top + Vector3(0.0, 0.0, 0.10), Vector3(0.0, 1.0, 0.42), 0.105, 0.62, 0.45, 15.0)
	sculpt_crystal(s, ice, top + Vector3(0.17, -0.07, -0.02), Vector3(0.55, 1.0, 0.25), 0.085, 0.42, 0.45, 5.0)
	sculpt_crystal(s, ice, top + Vector3(-0.17, -0.07, 0.0), Vector3(-0.55, 1.0, 0.30), 0.085, 0.46, 0.45, 25.0)
	# ---- steel pauldrons on both shoulders (domed plates with a light rim), knee-high front
	for sx: float in [-1.0, 1.0]:
		var pc := Vector3(0.43 * sx, 1.25, 0.50)
		_blob(s, steel, pc, Vector3(0.24, 0.20, 0.30), Vector3(0, 0, -30.0 * sx), 6, 3)
	# ---- team caparison over the back and upper flanks (behind the hump), a light team hem, a steel rump plate
	var at := Transform3D(Basis.IDENTITY, BC)
	sculpt_add(s, drape_mesh("fj_capar_v1", 0.63, 0.62, -118.0, 118.0, -0.66, 0.22, 10, 3, 0.94, 0.0, 0.08), at, cdark)
	for sx: float in [-1.0, 1.0]:
		var a0 := 104.0 * sx
		var a1 := 121.0 * sx
		sculpt_add(s, drape_mesh("fj_hem_%s_v1" % sx, 0.645, 0.635, minf(a0, a1), maxf(a0, a1), -0.67, 0.23, 1, 3, 0.94,
			0.0, 0.08), at, cloth)
	sculpt_add(s, drape_mesh("fj_rump_plate_v1", 0.53, 0.46, -58.0, 58.0, -0.84, -0.58, 5, 1, 0.8), Transform3D(Basis.IDENTITY,
		BC + Vector3(0, 0.02, 0)), steel)
	# ---- stubby tail
	_blob(s, ruff, Vector3(0, 1.12, -1.08), Vector3(0.12, 0.11, 0.10), Vector3.ZERO, 5, 2)
	# ---- saddle: a leather cantle (the rider's tabard and cape cover the rest)
	sculpt_put(s, box(Vector3(0.42, 0.16, 0.06)), leather, Vector3(0, 1.64, -0.38), Vector3(-14, 0, 0))


# ================================================================ head (neck, skull, muzzle, chanfron)

func _head_sculpt(s: Dictionary) -> void:
	var fur := m("fj_fur")
	var ruff := m("fj_ruff")
	var ice := m("ice_frost_crystal")
	var steel := m("ice_steel")
	var dark := m("ice_fur")
	# neck: a thick trunk from under the ruff into the skull
	sculpt_add(s, tube_mesh("fj_neck_v1", PackedVector3Array([Vector3(0, 1.28, 0.70), Vector3(0, 1.21, 0.97),
		Vector3(0, 1.14, 1.12)]), PackedFloat32Array([0.36, 0.31, 0.26]), 8, false), Transform3D.IDENTITY, fur)
	# skull (the face canvas), muzzle (lighter), dark nose, a hint of a jaw
	sculpt_put(s, sphere(SKULL_R, 8, 4), fur, SKULL_C, Vector3.ZERO, SKULL_S)
	sculpt_add(s, tube_mesh("fj_muzzle_v1", PackedVector3Array([Vector3(0, 1.08, 1.34), Vector3(0, 1.02, 1.58),
		Vector3(0, 0.99, 1.70)]), PackedFloat32Array([0.19, 0.145, 0.115]), 8, true), Transform3D.IDENTITY, ruff)
	sculpt_put(s, sphere(0.075, 5, 2), dark, Vector3(0, 1.04, 1.71), Vector3.ZERO, Vector3(1.2, 0.8, 1.0))
	# round ears
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, sphere(0.09, 5, 2), fur, Vector3(0.20 * sx, 1.37, 1.07), Vector3(0, 30.0 * sx, 0), Vector3(1.0, 1.0, 0.55))
	# the steel chanfron down the forehead to the muzzle, a light rivet, two swept-back brow crystals
	sculpt_put(s, box(Vector3(0.22, 0.05, 0.36)), steel, Vector3(0, 1.33, 1.30), Vector3(24, 0, 0))
	sculpt_crystal(s, ice, Vector3(0, 1.37, 1.18), Vector3(0.0, 0.85, -0.5), 0.065, 0.34, 0.45, 10.0)


## Eyes (CreatureFaceRig, host mode): small glowing ice-blue eyes under heavy brows on the skull's front sides.
static func face_spec() -> Dictionary:
	var dir := Vector3(0.56, 0.36, 0.76).normalized()
	var eye := SKULL_C + Vector3(dir.x * SKULL_R * SKULL_S.x, dir.y * SKULL_R * SKULL_S.y, dir.z * SKULL_R * SKULL_S.z)
	var out := Vector3(dir.x / SKULL_S.x, dir.y / SKULL_S.y, dir.z / SKULL_S.z).normalized()
	return CreatureFaceRig.side_eye_spec(eye, out, 0.046, Color(0.19, 0.21, 0.28), Color(0.50, 0.86, 1.0), 0.8)


## The face style (face_spec + its lifted canvas) with coarser decal sampling: a mount's eyes are a few pixels at the RTS
## zoom, so the outlines need fewer vertices (budget).
static func face_style() -> Dictionary:
	var spec := face_spec()
	var st := FaceKit.style_from(spec)
	var r: float = spec["radius"]
	st["canvas"] = FaceKit.canvas(spec["center"], r, spec["head_mesh"], spec.get("head_scale", Vector3.ONE), Vector3.INF,
		Basis.IDENTITY, float(spec["lift"]))
	st["density"] = 6.0
	return st


# ================================================================ legs

## A pillar leg rooted at the pivot p (model space): thick fur column, a flat paw; fronts get a steel knee cop and
## three pale claws.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var fur := m("fj_fur")
	var dark := m("ice_fur")
	var steel := m("ice_steel")
	var claw := m("ice_stone")
	var front: bool = p.z > 0.0
	var x := p.x * 1.04
	var z := p.z
	if front:
		sculpt_add(s, tube_mesh("fj_leg_f_v1", PackedVector3Array([Vector3(0, 0.95, 0), Vector3(0, 0.52, 0.03),
			Vector3(0, 0.14, 0.07)]), PackedFloat32Array([0.25, 0.215, 0.19]), 7, false),
			Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), fur)
	else:
		sculpt_add(s, tube_mesh("fj_leg_b_v1", PackedVector3Array([Vector3(0, 0.95, 0.02), Vector3(0, 0.54, -0.08),
			Vector3(0, 0.14, 0.02)]), PackedFloat32Array([0.27, 0.21, 0.18]), 7, false),
			Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), fur)
	sculpt_put(s, sphere(0.22, 7, 2), dark, Vector3(x, 0.08, z + 0.10), Vector3.ZERO, Vector3(1.0, 0.40, 1.25))
	var n_claw: int = 3 if front else 2
	for k: int in n_claw:
		var dx: float = (float(k) - float(n_claw - 1) * 0.5) * 0.10
		sculpt_put(s, spike_mesh(3), claw, Vector3(x + dx, 0.07, z + 0.30 - absf(dx) * 0.4), Vector3(100, 0, 0),
			Vector3(0.04, 0.14, 0.04))
	if front:
		# a steel knee cop and a shaggy lighter fur cuff over the paw
		sculpt_put(s, sphere(0.13, 6, 2), steel, Vector3(x, 0.53, z + 0.18), Vector3(-10, 0, 0), Vector3(1.3, 1.3, 0.55))
		sculpt_fringe(s, m("fj_ruff"), fringe_mesh("fj_cuff_v1", 0.21, 0.23, 0.25, 0.27, 0.10, 0.0, 360.0, 5, 0.06, 0.02, 0.6),
			Vector3(x, 0.30, z + 0.07))


# ================================================================ motion (on top of MountModel)

func _mount_ready() -> void:
	_frost_v = 0.0
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))
		# the right face for the camera distance from the first frame (no neutral -> far pop when it spawns far away)
		_update_tier()
		_face.auto_any(self)


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


## The shoulder roll: the bear rolls its hump side to side (the crystals sway), shakes its head, a snort (eyes flare).
func _pose_fidget(t: float) -> float:
	var env := _k3(t, 0.0, 0.25, 1.1, 1.5, 1.0, 1.0)
	rot(P_MOUNT, Vector3(0, 0, 4.0 * DEG * sin(t * TAU * 1.4) * env))
	pos(P_ROOT, Vector3(0, -0.02 * env, 0))
	var shake := _k3(t, 0.9, 1.05, 1.6, 1.9, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3(8.0 * DEG * shake, 18.0 * DEG * sin((t - 0.9) * TAU * 3.0) * shake, 0))
	if _fidget_prev < 1.5 and t >= 1.5:
		_flare = maxf(_flare, 0.6)
		_on_mount_event(&"fidget_snort")
	return 1.9


## Death: the body frosts over as it goes down (Ice idiom; the bear stays lying there, no shatter).
func _mount_process(_dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if not _dead:
		return
	var v: float = snappedf(0.20 * smoothstep(0.15, 0.85, _death_t), 0.02)
	if v == _frost_v:
		return
	_frost_v = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", FROST)


func _mount_revive() -> void:
	if _face:
		_face.reset()
	_frost_v = 0.0
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", 0.0)
		gi.set_instance_shader_parameter(&"flash_color", WHITE)
