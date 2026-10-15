extends MountModel
## Thornback elk (stables.md 2 slot C, the Nature tier-2 line breaker "heavy stag charger"): the mount half of
## thornback_charger.tscn. A massive moose-like forest stag, ~3.1 m nose to rump, withers ~1.85 m: a DARK BARK-BROWN
## coat, a heavy shoulder hump, pale straw socks and a pale bulbous muzzle, a throat bell, and the 40 m reads: a RIDGE
## OF BIG BARK THORNS along the spine (in front of and behind the rider: the "thornback") and a short, thick BATTERING
## RACK of pale antler swept FORWARD over the face round a bark boss studded with thorns. A woven bark breastplate with
## thorn studs, the team saddle blanket (nature_cloth, a dark team band, a straw hem). Apart from the Grove Stag (wide
## low palmate antlers, blossoms) by the forward rack, the thorn ridge and the hump.
## Palette (Nature in-game fix, under_90.md B): bark-brown / straw / pale antler; green only on the team blanket.
## Glow: the eyes (CreatureFaceRig irises, amber-sap, host mode inside the merged head).
## Motion: MountModel's heavy walk and a pounding gallop from 3.2 m/s, `mount_toss` (with the rider's thrust: the rack
## dips and tosses), the charge (the rack levelled, lunge, toss), a "rack rub" fidget, the hit; death: stumbles, rolls
## onto its side and withers (an ochre tint).
## Budget (with the rider: <= 12 draw instances): 7 draw instances (Body, Head, 4 legs, blob), 0 lights, 0 particles.

const OWN := "res://art/units/nature/thornback_charger/materials/"
const NAT := "res://art/units/nature/materials/"
const ANTLER := "res://art/units/mounts/grove_stag/materials/grove_stag_antler.tres"
const BLOB_TINT := Color(0.05, 0.04, 0.02, 0.55)
const WITHER := Vector3(0.42, 0.30, 0.08)

const BC := Vector3(0, 1.12, -0.12)
const SY := 1.08
const BARREL_Z: Array[float] = [-0.92, -0.86, -0.68, -0.30, 0.18, 0.56, 0.78, 0.86]
const BARREL_R: Array[float] = [0.00, 0.30, 0.44, 0.49, 0.50, 0.46, 0.32, 0.00]
const HUMP_C := Vector3(0, 1.52, 0.36)
const HUMP_R := Vector3(0.40, 0.32, 0.46)
const RUMP_C := Vector3(0, 1.30, -0.70)
const RUMP_R := Vector3(0.40, 0.34, 0.36)
const SKULL_C := Vector3(0, 1.52, 1.08)
const SKULL_S := Vector3(0.85, 0.92, 1.18)
const SKULL_R := 0.20
## The right half of the battering rack (x mirrored): the beam swept forward and the two tines.
const RACK: Array[Vector3] = [Vector3(0.10, 1.66, 1.00), Vector3(0.32, 1.78, 1.04), Vector3(0.50, 1.78, 1.22),
	Vector3(0.48, 1.70, 1.46)]
const RACK_R: Array[float] = [0.085, 0.08, 0.068, 0.0]

var _wither_v: float = 0.0
var _face: CreatureFaceRig


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "thornback_elk", face_style())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	ensure_shadow_blob(0.75, BLOB_TINT)
	_shadow.scale = Vector3(2.2, 1.0, 4.2)
	_shadow.position = Vector3(0, 0.02, 0.05)


static func m(name: String) -> Material:
	if name == "antler":
		return material_at(ANTLER)
	return material_at((OWN if name.begins_with("tb_") else NAT) + name + ".tres")


# ================================================================ mesh helpers (one-sided, cheap)

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


## A big curved bark thorn from `base` along `dir` (4 faces, 12 vertices), `w` wide at the base, `h` long.
static func _thorn(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, w: float, h: float) -> void:
	sculpt_add(s, spike_mesh(4), Transform3D(Basis(Quaternion(Vector3.UP, dir.normalized())).scaled_local(Vector3(w, h, w * 0.7)),
		base), mat)


# ================================================================ body

func _body_sculpt(s: Dictionary) -> void:
	var coat := m("tb_coat")
	var bark := m("nature_bark")
	var dark := m("nature_bark_dark")
	var thorn := m("nature_thorn")
	var cloth := m("nature_cloth")
	var cdark := m("nature_cloth_dark")
	var straw := m("nature_bell_cloth")
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	# G-C leftovers: the barrel turned on 16 sides (was 9: the boxy read at zoom 30), rounder hump / rump masses,
	# shoulder and haunch muscles over the leg roots, a woven breastplate with a rolled rim
	sculpt_add(s, lathe_mesh("tb_barrel_v2", prof, 16), Transform3D(Basis(Vector3.RIGHT, PI * 0.5) *
		Basis.from_scale(Vector3(1, 1, SY)), BC), coat)
	_blob(s, coat, HUMP_C, HUMP_R, 14, 7)
	_blob(s, coat, RUMP_C, RUMP_R, 14, 6)
	for sx: float in [-1.0, 1.0]:
		MountShapes.muscle(s, coat, Vector3(0.34 * sx, 1.15, 0.55), Vector3(0.15, 0.32, 0.2), Vector3(0.0, 1.0, -0.4))
		MountShapes.muscle(s, coat, Vector3(0.34 * sx, 1.18, -0.62), Vector3(0.16, 0.3, 0.24), Vector3(0.0, 1.0, 0.3))
	# the woven bark breastplate over the chest front, a dark rim and thorn studs
	_blob(s, bark, Vector3(0, 1.14, 0.64), Vector3(0.42, 0.40, 0.20), 14, 6)
	RiderShapes.lame(s, dark, 0.41, 0.4, -0.03, 0.03, 0.0, TAU, 16, 0.02, Transform3D(Basis(Vector3.RIGHT, PI * 0.5) *
		Basis.from_scale(Vector3(1.0, 1.0, 0.95)), Vector3(0, 1.12, 0.66)))
	for k: int in 3:
		var u: float = float(k) - 1.0
		_thorn(s, thorn, Vector3(u * 0.20, 1.20 - absf(u) * 0.06, 0.82), Vector3(u * 0.3, 0.2, 1.0), 0.04, 0.14)
	# THE THORN RIDGE: big bark thorns along the spine, three on the hump (leaning forward), three on the rump (back)
	var hump_top := HUMP_C + Vector3(0, HUMP_R.y, 0)
	_thorn(s, thorn, hump_top + Vector3(0, -0.04, 0.22), Vector3(0, 1.0, 0.45), 0.075, 0.34)
	_thorn(s, thorn, hump_top + Vector3(0, -0.01, 0.02), Vector3(0, 1.0, 0.25), 0.085, 0.42)
	_thorn(s, thorn, hump_top + Vector3(0, -0.06, -0.20), Vector3(0, 1.0, 0.05), 0.07, 0.30)
	var rump_top := RUMP_C + Vector3(0, RUMP_R.y, 0)
	_thorn(s, thorn, rump_top + Vector3(0, -0.02, 0.10), Vector3(0, 1.0, -0.20), 0.07, 0.30)
	_thorn(s, thorn, rump_top + Vector3(0, -0.03, -0.10), Vector3(0, 1.0, -0.45), 0.08, 0.36)
	_thorn(s, thorn, rump_top + Vector3(0, -0.10, -0.30), Vector3(0, 0.8, -0.8), 0.065, 0.28)
	for sx: float in [-1.0, 1.0]:
		_thorn(s, thorn, HUMP_C + Vector3(0.28 * sx, 0.18, 0.10), Vector3(0.8 * sx, 1.0, 0.3), 0.05, 0.20)
		_thorn(s, thorn, RUMP_C + Vector3(0.28 * sx, 0.20, -0.08), Vector3(0.8 * sx, 1.0, -0.4), 0.05, 0.20)
	# team saddle blanket (a dark team band, a straw hem each side), a bark cantle
	var at := Transform3D(Basis.IDENTITY, BC)
	sculpt_add(s, drape_mesh("tb_blanket_v1", 0.52, 0.56, -100.0, 100.0, -0.52, 0.12, 8, 2, 1.0, 0.1), at, cloth)
	sculpt_add(s, drape_mesh("tb_band_v1", 0.525, 0.565, -100.0, 100.0, -0.46, -0.36, 8, 1, 1.0, 0.1), at, cdark)
	for sx: float in [-1.0, 1.0]:
		var a0 := 90.0 * sx
		var a1 := 106.0 * sx
		sculpt_add(s, drape_mesh("tb_hem_%s_v1" % sx, 0.525, 0.565, minf(a0, a1), maxf(a0, a1), -0.53, 0.13, 1, 2, 1.0, 0.1),
			at, straw)
	RiderShapes.plate(s, bark, PackedVector2Array([Vector2(-0.2, -0.08), Vector2(0.2, -0.08), Vector2(0.19, 0.03),
		Vector2(0.12, 0.08), Vector2(-0.12, 0.08), Vector2(-0.19, 0.03)]), 0.07, 0.018,
		Transform3D(Basis.from_euler(Vector3(-14, 0, 0) * DEG), Vector3(0, 1.74, -0.50)), true)
	# a short tail tuft
	sculpt_put(s, spike_mesh(4), dark, Vector3(0, 1.36, -1.02), Vector3(-130, 0, 0), Vector3(0.08, 0.22, 0.07))


# ================================================================ head (neck, skull, rack, bell)

func _head_sculpt(s: Dictionary) -> void:
	var coat := m("tb_coat")
	var pale := m("tb_pale")
	var dark := m("nature_bark_dark")
	var bark := m("nature_bark")
	var thorn := m("nature_thorn")
	var ant := m("antler")
	# G-C leftovers: a 12-sided neck with a dewlap swell, a rounder skull and muzzle (were 8 / 7 sides)
	sculpt_add(s, tube_mesh("tb_neck_v2", PackedVector3Array([Vector3(0, 1.30, 0.58), Vector3(0, 1.37, 0.72),
		Vector3(0, 1.42, 0.84), Vector3(0, 1.48, 1.00)]), PackedFloat32Array([0.32, 0.29, 0.25, 0.20]), 12, false),
		Transform3D.IDENTITY, coat)
	# the long moose skull (face canvas), the pale bulbous muzzle, dark nostrils, the throat bell
	sculpt_put(s, sphere(SKULL_R, 12, 7), coat, SKULL_C, Vector3.ZERO, SKULL_S)
	sculpt_add(s, tube_mesh("tb_muzzle_v2", PackedVector3Array([Vector3(0, 1.49, 1.18), Vector3(0, 1.48, 1.22),
		Vector3(0, 1.42, 1.38), Vector3(0, 1.385, 1.46), Vector3(0, 1.37, 1.49)]),
		PackedFloat32Array([0.13, 0.15, 0.145, 0.12, 0.08]), 10, true), Transform3D.IDENTITY, pale)
	sculpt_put(s, sphere(0.05, 7, 4), dark, Vector3(0.05, 1.40, 1.52))
	sculpt_put(s, sphere(0.05, 7, 4), dark, Vector3(-0.05, 1.40, 1.52))
	sculpt_lock(s, dark, Vector3(0, 1.30, 0.98), Vector3(0, -1.0, 0.1).normalized(), Vector3(0, -0.2, 1.0), 0.12, 0.30, 0.06)
	# ears: broad leaf cones out sideways under the rack
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, spike_mesh(3), coat, Vector3(0.14 * sx, 1.64, 0.96), Vector3(0, 0, -72.0 * sx), Vector3(0.07, 0.20, 0.035))
	# THE BATTERING RACK: two thick pale beams swept forward over the face, a tine up on each, a bark boss between
	# them studded with thorns
	for sx: float in [-1.0, 1.0]:
		var pts := PackedVector3Array()
		var rad := PackedFloat32Array()
		for i: int in RACK.size():
			pts.append(Vector3(RACK[i].x * sx, RACK[i].y, RACK[i].z))
			rad.append(RACK_R[i])
		sculpt_add(s, tube_mesh("tb_rack_%s_v3" % sx, pts, rad, 9, true), Transform3D.IDENTITY, ant)
		sculpt_add(s, tube_mesh("tb_tine_%s_v2" % sx, PackedVector3Array([Vector3(0.34 * sx, 1.78, 1.08),
			Vector3(0.38 * sx, 1.95, 1.10), Vector3(0.40 * sx, 2.05, 1.17)]), PackedFloat32Array([0.05, 0.038, 0.0]), 5, true),
			Transform3D.IDENTITY, ant)
		sculpt_add(s, tube_mesh("tb_tine2_%s_v2" % sx, PackedVector3Array([Vector3(0.48 * sx, 1.78, 1.20),
			Vector3(0.62 * sx, 1.86, 1.24), Vector3(0.68 * sx, 1.95, 1.28)]), PackedFloat32Array([0.04, 0.03, 0.0]), 5, true),
			Transform3D.IDENTITY, ant)
	sculpt_put(s, sphere(0.14, 10, 5), bark, Vector3(0, 1.68, 1.10), Vector3(-20, 0, 0), Vector3(1.2, 0.6, 1.0))
	for k: int in 3:
		var u: float = float(k) - 1.0
		_thorn(s, thorn, Vector3(u * 0.08, 1.73, 1.14 + 0.02 * (1.0 - absf(u))), Vector3(u * 0.3, 0.6, 1.0), 0.035, 0.14)


static func face_spec() -> Dictionary:
	var dir := Vector3(0.70, 0.40, 0.58).normalized()
	var eye := SKULL_C + Vector3(dir.x * SKULL_R * SKULL_S.x, dir.y * SKULL_R * SKULL_S.y, dir.z * SKULL_R * SKULL_S.z)
	var out := Vector3(dir.x / SKULL_S.x, dir.y / SKULL_S.y, dir.z / SKULL_S.z).normalized()
	return CreatureFaceRig.side_eye_spec(eye, out, 0.044, Color(0.30, 0.21, 0.13), Color(0.78, 0.62, 0.20), 0.6,
		{"eye": {"top": 0.034, "bot": 0.026, "ir": 0.028}})


static func face_style() -> Dictionary:
	var spec := face_spec()
	var st := FaceKit.style_from(spec)
	var r: float = spec["radius"]
	st["canvas"] = FaceKit.canvas(spec["center"], r, spec["head_mesh"], spec.get("head_scale", Vector3.ONE), Vector3.INF,
		Basis.IDENTITY, float(spec["lift"]))
	st["density"] = 6.0
	return st


# ================================================================ legs

## Long heavy legs rooted at the pivot p: a thick coat thigh, a slimmer shank with a pale straw sock, a dark split hoof.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var coat := m("tb_coat")
	var pale := m("tb_pale")
	var dark := m("nature_bark_dark")
	# G-C leftovers: MountShapes jointed legs (the horse templates made heavier for a moose: forearm into a bony knee,
	# a long cannon, fetlock, pastern; hind stifle, gaskin back to the hock) in two bands (coat, pale straw sock), a
	# forearm / gaskin muscle mass, a rounded split hoof (was a straight 7-sided thigh on a 6-sided shank and a can)
	var front: bool = p.z > 0.0
	var x := p.x
	var z := p.z
	if front:
		var rows := MountShapes.scaled(MountShapes.HORSE_FORE, 0.2, 0.948, 1.0, 1.55)
		MountShapes.leg_bands(s, "tb_leg_f_v2", p, rows, [4], [coat, pale], 1.0, 0.8, 9)
		MountShapes.muscle(s, coat, Vector3(x, 0.92, z - 0.02), Vector3(0.15, 0.2, 0.17), Vector3(0, 1.0, 0.05))
	else:
		var rows := MountShapes.scaled(MountShapes.HORSE_HIND, 0.2, 0.948, 1.1, 1.5)
		MountShapes.leg_bands(s, "tb_leg_b_v2", p, rows, [5], [coat, pale], 1.0, 0.8, 9)
		MountShapes.muscle(s, coat, Vector3(x, 0.88, z - 0.04), Vector3(0.15, 0.22, 0.17), Vector3(0, 1.0, -0.35))
	var dz: float = 0.05 if front else -0.05
	# the split hoof: a rounded dark lathe with a cleft line down the front
	RiderShapes.lathe(s, dark, PackedVector2Array([Vector2(0.09, 0.0), Vector2(0.094, 0.02), Vector2(0.085, 0.07),
		Vector2(0.07, 0.11), Vector2(0.0, 0.118)]), 10, Transform3D(Basis.IDENTITY, Vector3(x, 0.0, z + dz)), 1.0, 1.15)
	RiderShapes.box_plate(s, pale, Vector3(0.012, 0.08, 0.02), Vector3(x, 0.05, z + dz + 0.1), Vector3(-10, 0, 0))


# ================================================================ motion (on top of MountModel)

func _mount_ready() -> void:
	_wither_v = 0.0
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))
		_update_tier()
		_face.auto_any(self)


func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


## The rack rub: the head drops and scrubs the rack side to side against the air, a stamp, a snort (the eyes flare).
func _pose_fidget(t: float) -> float:
	var down := _k3(t, 0.0, 0.3, 1.2, 1.5, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3(22.0 * DEG * down, 18.0 * DEG * sin(t * TAU * 2.0) * down, 8.0 * DEG * sin(t * TAU * 2.0) * down))
	var stamp: float = maxf(sin((t - 1.2) / 0.5 * TAU), 0.0) if t > 1.2 and t < 1.7 else 0.0
	rot(P_LEG_FR, Vector3(-22.0 * DEG * stamp, 0, 0))
	pos(P_LEG_FR, Vector3(0, 0.06 * stamp, 0))
	if _fidget_prev < 1.3 and t >= 1.3:
		_flare = maxf(_flare, 0.6)
		_on_mount_event(&"fidget_snort")
	return 1.8


## Death: the coat withers (a faint ochre tint that stays).
func _mount_process(_dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if not _dead:
		return
	var v: float = snappedf(0.12 * smoothstep(0.15, 0.85, _death_t), 0.02)
	if v == _wither_v:
		return
	_wither_v = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", WITHER)


func _mount_revive() -> void:
	if _face:
		_face.reset()
	_wither_v = 0.0
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", 0.0)
		gi.set_instance_shader_parameter(&"flash_color", WHITE)
