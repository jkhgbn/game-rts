extends MountModel
## Rime ram (stables.md 2 slot X, the Ice mounted skirmisher): the mount half of rime_harrier.tscn. A lean, long-legged
## mountain ram, ~2.2 m nose to tail, withers ~1.35 m: a deep slate-blue wool coat with a SHAGGY BELLY FRINGE, a dark
## slate face and legs, a goat beard, and the 40 m read: two BIG CURLED HORNS (pale steel-blue, spiralling back, out and
## forward round the ears) ending in CYAN ICE CRYSTAL TIPS. Team saddle blanket (ice_cloth_dark, light team hem) over
## the back. Apart from the Rimehorn (a low rhino, one forward horn) and the Frostcrown bear (a hump of crystals) by the
## tall slim legs, the high head and the two curls.
## Palette (Ice in-game fix, under_90.md B): slate / steel-blue mid-tones, cyan crystal tips, no near-white masses.
## Glow: the ice-blue eyes (CreatureFaceRig irises, host mode inside the merged head, no extra node).
## Motion: MountModel's light walk and a BOUNDING gallop from 3.0 m/s (big bounce, the head high), a "horn toss"
## fidget (it stamps a front hoof and tosses its horns, the eyes flare), the generic charge (horns lowered) and hit;
## death: stumbles, rolls onto its side and frosts over.
## Budget (with the rider: <= 12 draw instances, ~3000 vertices): 7 draw instances (Body, Head, 4 legs, blob),
## one-sided drapes, 0 lights, 0 particles.

const OWN := "res://art/units/ice/rime_harrier/materials/"
const ICE := "res://art/units/ice/materials/"
const BLOB_TINT := Color(0.03, 0.05, 0.11, 0.55)
const FROST := Vector3(0.22, 0.52, 1.0)

## Barrel of revolution along z, centred on BC, vertical stretch SY (deeper than wide).
const BC := Vector3(0, 1.00, -0.06)
const SY := 1.12
const BARREL_Z: Array[float] = [-0.72, -0.64, -0.46, -0.12, 0.22, 0.48, 0.62, 0.68]
const BARREL_R: Array[float] = [0.00, 0.22, 0.33, 0.37, 0.38, 0.34, 0.22, 0.00]
const CHEST_C := Vector3(0, 1.06, 0.40)
const CHEST_R := Vector3(0.30, 0.38, 0.30)
const RUMP_C := Vector3(0, 1.08, -0.50)
const RUMP_R := Vector3(0.31, 0.32, 0.28)
## Skull centre / radii and the right horn curl (x mirrored for the left); the last point carries the crystal tip.
const SKULL_C := Vector3(0, 1.74, 0.90)
const SKULL_S := Vector3(0.88, 0.95, 1.15)
const SKULL_R := 0.155
const HORN: Array[Vector3] = [Vector3(0.07, 1.84, 0.86), Vector3(0.15, 1.95, 0.80), Vector3(0.27, 1.99, 0.69),
	Vector3(0.37, 1.90, 0.61), Vector3(0.40, 1.73, 0.65), Vector3(0.35, 1.61, 0.78), Vector3(0.30, 1.60, 0.90)]
const HORN_R: Array[float] = [0.080, 0.078, 0.070, 0.060, 0.050, 0.040, 0.032]

var _frost_v: float = 0.0
var _face: CreatureFaceRig


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "rime_ram", face_style())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	ensure_shadow_blob(0.6, BLOB_TINT)
	_shadow.scale = Vector3(1.9, 1.0, 3.4)
	_shadow.position = Vector3(0, 0.02, 0.05)


static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("rh_") else ICE) + name + ".tres")


# ================================================================ mesh helpers (one-sided, cheap)

## One-sided curved drape: a patch of an elliptic cylinder around local +Z, outer side only, smooth normals, indexed
## ((seg_a + 1) x (seg_l + 1) vertices). Angle a (deg) from +Y toward +X, l along Z; `sag` flares the lower rows out.
static func drape_mesh(key: String, rx: float, ry: float, a0: float, a1: float, l0: float, l1: float, seg_a: int,
		seg_l: int, taper: float = 1.0, sag: float = 0.0) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for il: int in seg_l + 1:
		var v := float(il) / float(seg_l)
		var sc := lerpf(1.0, taper, v)
		for ia: int in seg_a + 1:
			var a := deg_to_rad(lerpf(a0, a1, float(ia) / float(seg_a)))
			var k := sc * (1.0 + sag * clampf(-cos(a), 0.0, 1.0))
			st.set_normal(Vector3(sin(a) / rx, cos(a) / ry, 0.0).normalized())
			st.add_vertex(Vector3(rx * sin(a) * k, ry * cos(a) * sc, lerpf(l0, l1, v)))
	var row := seg_a + 1
	var flip: bool = (a1 - a0) * (l1 - l0) < 0.0
	for il: int in seg_l:
		for ia: int in seg_a:
			var i0 := il * row + ia
			var i1 := i0 + 1
			var i2 := i0 + row
			var i3 := i2 + 1
			if not flip:
				st.add_index(i0); st.add_index(i1); st.add_index(i3)
				st.add_index(i0); st.add_index(i3); st.add_index(i2)
			else:
				st.add_index(i0); st.add_index(i3); st.add_index(i1)
				st.add_index(i0); st.add_index(i2); st.add_index(i3)
	return _cached(key, st.commit())


## A flat-shaded open pyramid (claws, spikes, hoof tips): `sides` faces from a base ring of radius 1 at y 0 to the apex
## at y 1, no base cap: 3 x sides vertices. Scale it per use.
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
		var b := p1
		var c := apex
		if (p1 - p0).cross(apex - p0).dot(n) > 0.0:
			b = apex
			c = p1
		for v: Vector3 in [p0, b, c]:
			st.set_normal(n)
			st.add_vertex(v)
	return _cached(key, st.commit())


static func _blob(s: Dictionary, mat: Material, c: Vector3, r: Vector3, seg: int = 8, rings: int = 4,
		rot_deg: Vector3 = Vector3.ZERO) -> void:
	sculpt_put(s, sphere(1.0, seg, rings), mat, c, rot_deg, r)


# ================================================================ body

func _body_sculpt(s: Dictionary) -> void:
	var wool := m("rh_wool")
	var dark := m("rh_hide")
	var cloth := m("ice_cloth")
	var cdark := m("ice_cloth_dark")
	var leather := m("ice_leather")
	var steel := m("ice_steel")
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	sculpt_add(s, lathe_mesh("rh_barrel_v1", prof, 8), Transform3D(Basis(Vector3.RIGHT, PI * 0.5) *
		Basis.from_scale(Vector3(1, 1, SY)), BC), wool)
	_blob(s, wool, CHEST_C, CHEST_R)
	_blob(s, wool, RUMP_C, RUMP_R, 7, 3)
	# the shaggy wool fringe hanging under the belly and the chest (the ram's silhouette: a ragged lower edge)
	sculpt_fringe(s, wool, fringe_mesh("rh_fringe_v1", 0.36, 0.60, 0.40, 0.66, 0.14, 0.0, 360.0, 9, 0.12, 0.03, 0.7),
		Vector3(0, 0.88, -0.04))
	# team saddle blanket over the back, a light team hem each side, a leather saddle with a steel-capped pommel
	var at := Transform3D(Basis.IDENTITY, BC)
	sculpt_add(s, drape_mesh("rh_blanket_v1", 0.41, 0.46, -108.0, 108.0, -0.44, 0.18, 8, 2, 1.0, 0.1), at, cdark)
	for sx: float in [-1.0, 1.0]:
		var a0 := 98.0 * sx
		var a1 := 112.0 * sx
		sculpt_add(s, drape_mesh("rh_hem_%s_v1" % sx, 0.415, 0.465, minf(a0, a1), maxf(a0, a1), -0.45, 0.19, 1, 2, 1.0,
			0.1), at, cloth)
	sculpt_put(s, box(Vector3(0.30, 0.10, 0.20)), leather, Vector3(0, 1.49, -0.34), Vector3(-12, 0, 0))
	sculpt_put(s, box(Vector3(0.16, 0.12, 0.07)), steel, Vector3(0, 1.52, 0.10), Vector3(14, 0, 0))
	# a short tail tuft
	sculpt_put(s, spike_mesh(4), dark, Vector3(0, 1.20, -0.74), Vector3(-120, 0, 0), Vector3(0.07, 0.20, 0.07))


# ================================================================ head (neck, skull, horns)

func _head_sculpt(s: Dictionary) -> void:
	var wool := m("rh_wool")
	var dark := m("rh_hide")
	var horn := m("rh_horn")
	var ice := m("ice_frost_crystal")
	# neck: up and forward from the chest, a wool ruff over it
	sculpt_add(s, tube_mesh("rh_neck_v1", PackedVector3Array([Vector3(0, 1.22, 0.48), Vector3(0, 1.46, 0.66),
		Vector3(0, 1.66, 0.84)]), PackedFloat32Array([0.19, 0.155, 0.12]), 7, false), Transform3D.IDENTITY, wool)
	# a shaggy wool mane down the top of the neck and a chest tuft
	for i: int in 4:
		var f: float = float(i) / 3.0
		var root := Vector3(0, lerpf(1.62, 1.30, f), lerpf(0.80, 0.52, f))
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		sculpt_lock(s, wool, root, Vector3(0.35 * sx, -0.6, -0.8).normalized(), Vector3(0.4 * sx, 1.0, -0.2).normalized(),
			0.13, 0.20, 0.05)
	sculpt_lock(s, wool, Vector3(0, 1.20, 0.62), Vector3(0, -1.0, 0.25).normalized(), Vector3(0, -0.2, 1), 0.16, 0.26, 0.06)
	# skull (the face canvas) and the long dark muzzle, a dark nose, a goat beard
	sculpt_put(s, sphere(SKULL_R, 8, 5), dark, SKULL_C, Vector3.ZERO, SKULL_S)
	sculpt_add(s, tube_mesh("rh_muzzle_v1", PackedVector3Array([Vector3(0, 1.70, 1.00), Vector3(0, 1.62, 1.14),
		Vector3(0, 1.56, 1.22)]), PackedFloat32Array([0.11, 0.085, 0.06]), 6, true), Transform3D.IDENTITY, dark)
	sculpt_lock(s, wool, Vector3(0, 1.58, 1.10), Vector3(0, -1.0, -0.25).normalized(), Vector3(0, -0.2, 1), 0.10, 0.22, 0.06)
	# ears: small leaf cones out sideways under the horns
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, spike_mesh(4), dark, Vector3(0.11 * sx, 1.80, 0.84), Vector3(0, 0, -80.0 * sx), Vector3(0.045, 0.16, 0.03))
	# THE HORNS: two curls (pale steel-blue horn, ridged by their taper) ending in cyan ice crystals
	for sx: float in [-1.0, 1.0]:
		var pts := PackedVector3Array()
		var rad := PackedFloat32Array()
		for i: int in HORN.size():
			pts.append(Vector3(HORN[i].x * sx, HORN[i].y, HORN[i].z))
			rad.append(HORN_R[i])
		sculpt_add(s, tube_mesh("rh_horn_%s_v1" % sx, pts, rad, 5, true), Transform3D.IDENTITY, horn)
		var tip := pts[pts.size() - 1]
		var d := (tip - pts[pts.size() - 2]).normalized()
		sculpt_crystal(s, ice, tip - d * 0.02, d, 0.045, 0.20, 0.55)


## Eyes (CreatureFaceRig, host mode): glowing ice-blue eyes on the sides of the long skull, under the horn roots.
static func face_spec() -> Dictionary:
	var dir := Vector3(0.72, 0.30, 0.62).normalized()
	var eye := SKULL_C + Vector3(dir.x * SKULL_R * SKULL_S.x, dir.y * SKULL_R * SKULL_S.y, dir.z * SKULL_R * SKULL_S.z)
	var out := Vector3(dir.x / SKULL_S.x, dir.y / SKULL_S.y, dir.z / SKULL_S.z).normalized()
	return CreatureFaceRig.side_eye_spec(eye, out, 0.034, Color(0.22, 0.25, 0.33), Color(0.52, 0.88, 1.0), 0.8)


static func face_style() -> Dictionary:
	var spec := face_spec()
	var st := FaceKit.style_from(spec)
	var r: float = spec["radius"]
	st["canvas"] = FaceKit.canvas(spec["center"], r, spec["head_mesh"], spec.get("head_scale", Vector3.ONE), Vector3.INF,
		Basis.IDENTITY, float(spec["lift"]))
	st["density"] = 6.0
	return st


# ================================================================ legs

## A long slim leg rooted at the pivot p (model space): wool thigh into a dark shank, a dark split hoof.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var wool := m("rh_wool")
	var dark := m("rh_hide")
	var hoof := m("ice_fur")
	var front: bool = p.z > 0.0
	var x := p.x
	var z := p.z
	var knee := Vector3(0, 0.50, 0.04) if front else Vector3(0, 0.52, -0.10)
	sculpt_add(s, tube_mesh("rh_leg_up_%s_v1" % front, PackedVector3Array([Vector3(0, 0.98, 0), knee]),
		PackedFloat32Array([0.13, 0.075]), 6, false), Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), wool)
	sculpt_add(s, tube_mesh("rh_leg_lo_%s_v1" % front, PackedVector3Array([knee, Vector3(0, 0.10, 0.02)]),
		PackedFloat32Array([0.072, 0.055]), 5, false), Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), dark)
	sculpt_put(s, cyl(0.05, 0.075, 0.11, 5), hoof, Vector3(x, 0.055, z + 0.03))
	# a wool tuft over the hoof (fetlock feathering)
	sculpt_lock(s, wool, Vector3(x, 0.24, z - 0.02), Vector3(0, -1.0, -0.3).normalized(), Vector3(0, 0, -1), 0.10, 0.12, 0.05)


# ================================================================ motion (on top of MountModel)

func _mount_ready() -> void:
	_frost_v = 0.0
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))
		_update_tier()
		_face.auto_any(self)


func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


# rear_throw (play_attack with the rider's javelin throw, 0.55 s): the ram rears half-up as its rider throws (body
# pitched nose-up, the fore legs folded up, the head high), then lands. Keyframe tracks [t, v, ease, ...] (MountModel._mkf).
static var RT_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.07, -8.0, 1, 0.13, -17.0, 1, 0.30, -10.0, 0, 0.55, 0.0, 2])
static var RT_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.13, 0.07, 1, 0.30, 0.04, 0, 0.55, 0.0, 2])
static var RT_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.08, -30.0, 1, 0.14, -52.0, 1, 0.32, -30.0, 0, 0.55, 0.0, 2])
static var RT_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.13, 10.0, 1, 0.55, 0.0, 0])
static var RT_HEAD := PackedFloat32Array([0.0, 0.0, 0, 0.08, -10.0, 1, 0.14, -24.0, 1, 0.34, -8.0, 0, 0.55, 0.0, 0])


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"rear_throw":
		return super(prev, t)
	var k: float = 1.0 - 0.5 * _walk_w   # on the move the rear stays smaller (the gallop keeps its legs)
	rot(P_MOUNT, Vector3(_mkf(t, RT_PITCH) * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, _mkf(t, RT_ROOT_Y) * k, 0))
	var f := _mkf(t, RT_LEG_F) * DEG * k
	rot(P_LEG_FL, Vector3(f, 0, 0)); rot(P_LEG_FR, Vector3(f * 0.85, 0, 0))
	var b := _mkf(t, RT_LEG_B) * DEG * k
	rot(P_LEG_BL, Vector3(b, 0, 0)); rot(P_LEG_BR, Vector3(b, 0, 0))
	rot(P_MOUNT_HEAD, Vector3(_mkf(t, RT_HEAD) * DEG, 0, 0))
	if prev < 0.12 and t >= 0.12:
		_on_action_event(&"release")
	return t < 0.55


## The horn toss: a front hoof stamps twice, then the head drops and tosses the horns up (the eyes flare).
func _pose_fidget(t: float) -> float:
	var stamp: float = maxf(sin((t - 0.1) / 0.7 * TAU * 2.0), 0.0) if t > 0.1 and t < 0.8 else 0.0
	rot(P_LEG_FL, Vector3(-26.0 * DEG * stamp, 0, 0))
	pos(P_LEG_FL, Vector3(0, 0.07 * stamp, 0))
	var toss := _k3(t, 0.85, 1.05, 1.25, 1.7, 1.0, -1.0)
	rot(P_MOUNT_HEAD, Vector3(24.0 * DEG * toss, 10.0 * DEG * sin(t * TAU * 1.5) * absf(toss), 0))
	if _fidget_prev < 1.2 and t >= 1.2:
		_flare = maxf(_flare, 0.6)
		_on_mount_event(&"fidget_snort")
	return 1.7


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
