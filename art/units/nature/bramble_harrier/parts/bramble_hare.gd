extends MountModel
## Bramble hare (stables.md 2 slot X, the Nature mounted skirmisher): the mount half of bramble_harrier.tscn. A giant
## forest hare, ~1.9 m long, back ~1.3 m: a hunched STRAW-BROWN coat (warm tan, never meadow green) with a pale cream
## belly, chin and cotton tail, HUGE HIND LEGS with long flat feet, slim fore legs, and the 40 m read: TWO TALL EARS
## (dark-tipped, cream inside) standing up behind the rider's pale hat. A collar of BRAMBLE THORNS round the neck, the
## team saddle blanket (nature_cloth, a straw hem) over the back. Apart from the stags (antlers), the Mossback (a shell)
## and the wolves by the ears, the hunched back and the long hind feet.
## Palette (Nature in-game fix, under_90.md B): straw / bark-brown / cream, the pale cap = the ears' cream insides and the
## rider's straw hat; green only on the team blanket.
## Glow: the eyes (CreatureFaceRig irises, amber, host mode inside the merged head).
## Motion: MountModel's walk and a BOUNDING gallop from 2.8 m/s (a big bounce, the body rocking), the `dart_hop`
## attack (with the rider's throw: a crouch and a short hop), a "wash and listen" fidget (it rubs its face, the ears
## swivel), the generic charge and hit; death: stumbles, rolls onto its side, the coat withers (an ochre tint).
## Budget (with the rider: <= 12 draw instances, ~3000 vertices): 7 draw instances (Body, Head, 4 legs, blob),
## one-sided drapes, 0 lights, 0 particles.

const OWN := "res://art/units/nature/bramble_harrier/materials/"
const NAT := "res://art/units/nature/materials/"
const BLOB_TINT := Color(0.05, 0.04, 0.02, 0.5)
const WITHER := Vector3(0.42, 0.30, 0.08)

const BC := Vector3(0, 0.80, -0.08)
const BARREL_Z: Array[float] = [-0.66, -0.58, -0.38, -0.02, 0.30, 0.48, 0.58, 0.62]
const BARREL_R: Array[float] = [0.00, 0.28, 0.39, 0.41, 0.37, 0.30, 0.18, 0.00]
const RUMP_C := Vector3(0, 0.89, -0.42)
const RUMP_R := Vector3(0.40, 0.40, 0.38)
const CHEST_C := Vector3(0, 0.76, 0.32)
const CHEST_R := Vector3(0.27, 0.31, 0.27)
const SKULL_C := Vector3(0, 1.24, 0.72)
const SKULL_S := Vector3(0.92, 0.95, 1.12)
const SKULL_R := 0.165

var _wither_v: float = 0.0
var _face: CreatureFaceRig


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "bramble_hare", face_style())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	ensure_shadow_blob(0.6, BLOB_TINT)
	_shadow.scale = Vector3(1.9, 1.0, 3.2)
	_shadow.position = Vector3(0, 0.02, -0.05)


static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("bh_") else NAT) + name + ".tres")


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


## A flat leaf-lens (NatureModel.leaf_mesh) from `base` along `dir`, its face toward `nrm`; size = (width, thickness, length).
static func _lens(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, nrm: Vector3, size: Vector3) -> void:
	var z := dir.normalized()
	var y := (nrm - z * nrm.dot(z)).normalized()
	var x := y.cross(z)
	sculpt_add(s, NatureModel.leaf_mesh(), Transform3D(Basis(x * size.x, y * size.y, z * size.z), base + z * size.z * 0.5), mat)


# ================================================================ body

func _body_sculpt(s: Dictionary) -> void:
	var coat := m("bh_coat")
	var pale := m("bh_pale")
	var cloth := m("nature_cloth")
	var straw := m("nature_bell_cloth")
	var bark := m("nature_bark")
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	# G-C leftovers: the barrel on 16 sides (was 8: the boxy read at zoom 30), rounder rump / chest masses, a fluffy
	# cotton tail of locks
	sculpt_add(s, lathe_mesh("bh_barrel_v2", prof, 16), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), BC), coat)
	_blob(s, coat, RUMP_C, RUMP_R, 14, 7)
	_blob(s, pale, CHEST_C + Vector3(0, -0.04, 0.03), CHEST_R, 12, 6)
	# the cotton tail
	var tc := Vector3(0, 0.98, -0.82)
	_blob(s, pale, tc, Vector3(0.13, 0.12, 0.1), 10, 5)
	for k: int in 6:
		var a := TAU * float(k) / 6.0
		var out := Vector3(cos(a), sin(a) * 0.9, -0.6).normalized()
		sculpt_lock(s, pale, tc + out * 0.06, out, Vector3(0, 0, -1), 0.08, 0.1, 0.05)
	# team saddle blanket over the back, a straw hem each side, a bark saddle
	var at := Transform3D(Basis.IDENTITY, BC)
	sculpt_add(s, drape_mesh("bh_blanket_v2", 0.43, 0.44, -80.0, 80.0, -0.32, 0.10, 6, 2, 1.0, 0.1), at, cloth)
	sculpt_add(s, drape_mesh("bh_band_v2", 0.435, 0.445, -80.0, 80.0, -0.28, -0.20, 6, 1, 1.0, 0.1), at, m("nature_cloth_dark"))
	for sx: float in [-1.0, 1.0]:
		var a0 := 72.0 * sx
		var a1 := 88.0 * sx
		sculpt_add(s, drape_mesh("bh_hem_%s_v2" % sx, 0.435, 0.445, minf(a0, a1), maxf(a0, a1), -0.33, 0.11, 1, 2, 1.0, 0.1),
			at, straw)
	RiderShapes.plate(s, bark, PackedVector2Array([Vector2(-0.15, -0.05), Vector2(0.15, -0.05), Vector2(0.14, 0.02),
		Vector2(0.09, 0.05), Vector2(-0.09, 0.05), Vector2(-0.14, 0.02)]), 0.07, 0.016,
		Transform3D(Basis.from_euler(Vector3(-14, 0, 0) * DEG), Vector3(0, 1.28, -0.36)), true)


# ================================================================ head (neck, skull, ears, bramble collar)

func _head_sculpt(s: Dictionary) -> void:
	var coat := m("bh_coat")
	var pale := m("bh_pale")
	var dark := m("bh_dark")
	var thorn := m("nature_thorn")
	var bark := m("nature_bark_dark")
	sculpt_add(s, tube_mesh("bh_neck_v2", PackedVector3Array([Vector3(0, 0.84, 0.38), Vector3(0, 1.00, 0.52),
		Vector3(0, 1.14, 0.64)]), PackedFloat32Array([0.20, 0.17, 0.14]), 12, false), Transform3D.IDENTITY, coat)
	# the bramble collar: a dark bark band with thorns (a rolled band, was a 7-sided can)
	RiderShapes.band(s, bark, 0.185, 0.07, 0.02, 12, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(38.0)), Vector3(0, 0.94, 0.47)))
	sculpt_add(s, NatureModel.thorn_ring_mesh(6, 0.19, 0.03, 0.10, 60.0, 0.0), Transform3D(Basis(Vector3.RIGHT,
		deg_to_rad(38.0)), Vector3(0, 0.94, 0.47)), thorn)
	# skull (face canvas), a pale muzzle and chin, a dark nose
	sculpt_put(s, sphere(SKULL_R, 12, 7), coat, SKULL_C, Vector3.ZERO, SKULL_S)
	sculpt_put(s, sphere(0.10, 10, 5), pale, Vector3(0, 1.17, 0.86), Vector3.ZERO, Vector3(1.0, 0.8, 0.9))
	sculpt_put(s, spike_mesh(3), dark, Vector3(0, 1.22, 0.94), Vector3(-70, 0, 0), Vector3(0.03, 0.045, 0.025))
	# the two tall ears: a straw-brown back, a cream inside, dark tips
	for sx: float in [-1.0, 1.0]:
		var base := Vector3(0.07 * sx, 1.36, 0.66)
		var dir := Vector3(0.20 * sx, 1.0, -0.30).normalized()
		var face := Vector3(0.35 * sx, 0.0, 1.0).normalized()
		_lens(s, coat, base, dir, face, Vector3(0.16, 0.05, 0.70))
		_lens(s, pale, base + face * 0.012 + dir * 0.07, dir, face, Vector3(0.095, 0.03, 0.54))
		sculpt_add(s, spike_mesh(3), Transform3D(Basis(Quaternion(Vector3.UP, dir)).scaled_local(Vector3(0.05, 0.12, 0.03)),
			base + dir * 0.60), dark)


static func face_spec() -> Dictionary:
	var dir := Vector3(0.78, 0.30, 0.55).normalized()
	var eye := SKULL_C + Vector3(dir.x * SKULL_R * SKULL_S.x, dir.y * SKULL_R * SKULL_S.y, dir.z * SKULL_R * SKULL_S.z)
	var out := Vector3(dir.x / SKULL_S.x, dir.y / SKULL_S.y, dir.z / SKULL_S.z).normalized()
	return CreatureFaceRig.side_eye_spec(eye, out, 0.042, Color(0.52, 0.40, 0.26), Color(0.62, 0.36, 0.10), 0.0,
		{"eye": {"top": 0.034, "bot": 0.026, "ir": 0.030},
		"palette": {"sclera": Color(0.10, 0.07, 0.05), "brow": Color(0.26, 0.18, 0.10), "lash": Color(0.08, 0.05, 0.03)}})


static func face_style() -> Dictionary:
	var spec := face_spec()
	var st := FaceKit.style_from(spec)
	var r: float = spec["radius"]
	st["canvas"] = FaceKit.canvas(spec["center"], r, spec["head_mesh"], spec.get("head_scale", Vector3.ONE), Vector3.INF,
		Basis.IDENTITY, float(spec["lift"]))
	st["density"] = 6.0
	return st


# ================================================================ legs

## Slim fore legs with small paws; huge hind legs: a round thigh, a shank and a LONG FLAT FOOT on the ground.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var coat := m("bh_coat")
	var pale := m("bh_pale")
	var x := p.x
	var z := p.z
	# G-C leftovers: MountShapes jointed legs (one flattened tube through the joints, swelling at the elbow / hock) in
	# place of the 6-sided straight tubes; a rounder thigh mass, a long padded foot with toes, rounder paws
	if p.z > 0.0:
		var rows: Array[Vector3] = [Vector3(0.72, 0.0, 0.12), Vector3(0.6, -0.02, 0.105), Vector3(0.5, -0.016, 0.082),
			Vector3(0.42, -0.004, 0.074), Vector3(0.3, 0.014, 0.064), Vector3(0.2, 0.03, 0.058), Vector3(0.12, 0.044, 0.056),
			Vector3(0.07, 0.05, 0.05)]
		MountShapes.leg(s, "bh_leg_f_v2", p, rows, coat, 1.0, 0.82, 9)
		MountShapes.muscle(s, coat, Vector3(x, 0.6, z - 0.01), Vector3(0.1, 0.13, 0.1), Vector3(0, 1.0, 0.1), 9, 5)
		sculpt_put(s, sphere(0.075, 10, 5), pale, Vector3(x, 0.05, z + 0.08), Vector3.ZERO, Vector3(1.0, 0.6, 1.4))
		for k: int in 3:
			sculpt_put(s, sphere(0.026, 6, 3), pale, Vector3(x + 0.03 * float(k - 1), 0.035, z + 0.17), Vector3.ZERO,
				Vector3(1.0, 0.8, 1.3))
	else:
		var hp := Vector3(x * 1.06, 0, z)
		_blob(s, coat, Vector3(x * 1.04, 0.64, z - 0.02), Vector3(0.16, 0.27, 0.28), 13, 7)
		var rows: Array[Vector3] = [Vector3(0.52, -0.05, 0.12), Vector3(0.42, -0.11, 0.1), Vector3(0.32, -0.17, 0.082),
			Vector3(0.24, -0.215, 0.074), Vector3(0.17, -0.245, 0.074), Vector3(0.11, -0.26, 0.07)]
		MountShapes.leg(s, "bh_leg_b_v2", hp, rows, coat, 1.0, 0.82, 9)
		# the long flat foot, heel at the back, toes forward (pale sole tuft)
		sculpt_add(s, tube_mesh("bh_foot_v2", PackedVector3Array([Vector3(0, 0.09, -0.29), Vector3(0, 0.07, -0.2),
			Vector3(0, 0.055, -0.02), Vector3(0, 0.05, 0.12), Vector3(0, 0.045, 0.18)]),
			PackedFloat32Array([0.07, 0.074, 0.067, 0.055, 0.036]), 9, true, 0.75), Transform3D(Basis.IDENTITY, hp), coat)
		sculpt_put(s, sphere(0.06, 10, 5), pale, Vector3(x * 1.06, 0.045, z + 0.16), Vector3.ZERO, Vector3(1.0, 0.7, 1.3))
		for k: int in 3:
			sculpt_put(s, sphere(0.028, 6, 3), pale, Vector3(x * 1.06 + 0.032 * float(k - 1), 0.035, z + 0.215), Vector3.ZERO,
				Vector3(1.0, 0.8, 1.3))


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


# dart_hop (play_attack with the rider's throw, 0.5 s): a crouch (0.08 s), a short hop that lifts the fore quarters
# as the dart flies (0.12-0.25 s), the landing. Keyframe tracks [t, v, ease, ...] (MountModel._mkf).
static var DH_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.07, 1, 0.16, 0.16, 1, 0.30, 0.02, 2, 0.40, -0.04, 1,
	0.5, 0.0, 0])
static var DH_PITCH := PackedFloat32Array([0.0, 0.0, 0, 0.08, 5.0, 1, 0.16, -12.0, 1, 0.32, 4.0, 2, 0.5, 0.0, 0])
static var DH_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.08, 10.0, 1, 0.16, -38.0, 1, 0.34, -6.0, 0, 0.5, 0.0, 0])
static var DH_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.08, -14.0, 1, 0.16, 28.0, 1, 0.34, 4.0, 0, 0.5, 0.0, 0])
static var DH_HEAD := PackedFloat32Array([0.0, 0.0, 0, 0.08, 8.0, 1, 0.16, -14.0, 1, 0.5, 0.0, 0])


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"dart_hop":
		return super(prev, t)
	var k: float = 1.0 - 0.5 * _walk_w
	pos(P_ROOT, Vector3(0, _mkf(t, DH_ROOT_Y) * k, 0))
	rot(P_MOUNT, Vector3(_mkf(t, DH_PITCH) * DEG * k, 0, 0))
	var f := _mkf(t, DH_LEG_F) * DEG * k
	rot(P_LEG_FL, Vector3(f, 0, 0)); rot(P_LEG_FR, Vector3(f * 0.9, 0, 0))
	var b := _mkf(t, DH_LEG_B) * DEG * k
	rot(P_LEG_BL, Vector3(b, 0, 0)); rot(P_LEG_BR, Vector3(b, 0, 0))
	rot(P_MOUNT_HEAD, Vector3(_mkf(t, DH_HEAD) * DEG, 0, 0))
	return t < 0.5


## Wash and listen: the hare sits back, rubs its face with a fore paw, then lifts its head, listening (the ears swivel
## with the head).
func _pose_fidget(t: float) -> float:
	var sit := _k3(t, 0.0, 0.3, 1.3, 1.7, 1.0, 1.0)
	rot(P_MOUNT, Vector3(-7.0 * DEG * sit, 0, 0))
	pos(P_ROOT, Vector3(0, -0.03 * sit, 0))
	var rub: float = sin(clampf((t - 0.3) / 0.8, 0.0, 1.0) * TAU * 3.0) * _k3(t, 0.3, 0.4, 1.0, 1.1, 1.0, 1.0)
	rot(P_LEG_FL, Vector3((-48.0 * _k3(t, 0.2, 0.35, 1.0, 1.2, 1.0, 1.0) + 10.0 * rub) * DEG, 0, 0))
	rot(P_MOUNT_HEAD, Vector3((12.0 * sit - 6.0 * rub) * DEG, 0, 0))
	var listen := _k3(t, 1.2, 1.4, 1.9, 2.2, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3(-16.0 * DEG * listen, 22.0 * DEG * sin((t - 1.2) * TAU * 1.2) * listen, 0))
	if _fidget_prev < 1.5 and t >= 1.5:
		_on_mount_event(&"fidget_snort")
	return 2.2


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
