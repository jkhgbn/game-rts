extends MountModel
## Snowdrift cat (stables.md 2 slot Z, the Ice tier-1 raider): the mount half of snowdrift_rider.tscn. A big frost
## leopard, ~2.4 m nose to rump plus a 1.2 m tail, shoulders ~1.2 m: a low, long, lithe body in a SLATE-BLUE coat with
## dark rosettes, a lighter slate chest / muzzle / snowshoe paws, a round head with triangular dark-tufted ears and
## cheek ruffs, and the 40 m read: the LONG THICK TAIL raised in an S-curve behind the rider (its own pivot: it swishes)
## ending in a dark tip. Team saddle-cloth (ice_cloth_dark, light team hem) over the back. Apart from the Rimehorn
## (a rhino), the Frostcrown bear (a hump of crystals) and the Rime ram (horns, stilt legs) by the low feline line and
## the tail curl.
## Palette (Ice in-game fix, under_90.md B): slate-blue mid-tones, a lighter (never white) slate on the chest / paws,
## cyan eyes; no near-white masses.
## Glow: the ice-blue eyes (CreatureFaceRig irises, host mode inside the merged head).
## Motion: MountModel's prowling walk and a long bounding gallop from 3.0 m/s (big pitch rock, the head low), a
## "stretch and swish" fidget, the `cat_swipe` attack (with the rider's slash: a fore paw rakes, the head snaps
## forward), the generic charge and hit; death: stumbles, rolls onto its side and frosts over.
## Budget (with the rider: <= 12 draw instances, ~3000 vertices): 8 draw instances (Body, Head, 4 legs, Tail, blob),
## one-sided drapes, 0 lights, 0 particles.

const OWN := "res://art/units/ice/snowdrift_rider/materials/"
const ICE := "res://art/units/ice/materials/"
const BLOB_TINT := Color(0.03, 0.05, 0.11, 0.55)
const FROST := Vector3(0.22, 0.52, 1.0)

const BC := Vector3(0, 0.92, -0.06)
const SY := 0.98
const BARREL_Z: Array[float] = [-0.78, -0.70, -0.50, -0.12, 0.26, 0.52, 0.68, 0.74]
const BARREL_R: Array[float] = [0.00, 0.23, 0.33, 0.355, 0.37, 0.34, 0.22, 0.00]
const CHEST_C := Vector3(0, 0.96, 0.44)
const CHEST_R := Vector3(0.31, 0.37, 0.31)
const RUMP_C := Vector3(0, 0.98, -0.54)
const RUMP_R := Vector3(0.34, 0.35, 0.31)
const SKULL_C := Vector3(0, 1.30, 0.94)
const SKULL_S := Vector3(1.05, 0.86, 1.0)
const SKULL_R := 0.20
## The tail (model space, from the Tail pivot at TAIL_ROOT): an S-curve up behind the rider.
const TAIL_ROOT := Vector3(0, 1.02, -0.78)
const TAIL: Array[Vector3] = [Vector3(0, 1.02, -0.78), Vector3(0, 0.94, -1.02), Vector3(0, 1.00, -1.30),
	Vector3(0, 1.22, -1.48), Vector3(0, 1.48, -1.50), Vector3(0, 1.64, -1.38)]
const TAIL_R: Array[float] = [0.085, 0.10, 0.11, 0.11, 0.10, 0.085]

var _frost_v: float = 0.0
var _face: CreatureFaceRig
var _swipe_prev: float = 0.0


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "snowdrift_cat", face_style())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	add_sculpt($Root/Mount/Tail, _tail_sculpt)
	ensure_shadow_blob(0.62, BLOB_TINT)
	_shadow.scale = Vector3(1.9, 1.0, 3.9)
	_shadow.position = Vector3(0, 0.02, -0.1)


static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("sd_") else ICE) + name + ".tres")


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


## A dark rosette lying on a surface point p with outward normal n (a flat lens: 18 vertices).
static func _rosette(s: Dictionary, mat: Material, p: Vector3, n: Vector3, size: float) -> void:
	var f := frame(p, n, Vector3.FORWARD if absf(n.z) < 0.8 else Vector3.RIGHT)
	sculpt_add(s, sphere(1.0, 5, 2), Transform3D(Basis(f.basis.x * size, f.basis.y * size * 0.22, f.basis.z * size * 0.8),
		p), mat)


# ================================================================ body

func _body_sculpt(s: Dictionary) -> void:
	var coat := m("sd_coat")
	var pale := m("sd_pale")
	var spot := m("sd_spot")
	var cloth := m("ice_cloth")
	var cdark := m("ice_cloth_dark")
	var leather := m("ice_leather")
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	sculpt_add(s, lathe_mesh("sd_barrel_v1", prof, 8), Transform3D(Basis(Vector3.RIGHT, PI * 0.5) *
		Basis.from_scale(Vector3(1, 1, SY)), BC), coat)
	_blob(s, coat, CHEST_C, CHEST_R)
	_blob(s, coat, RUMP_C, RUMP_R, 7, 3)
	# the lighter chest ruff hanging under the neck
	sculpt_fringe(s, pale, fringe_mesh("sd_ruff_v1", 0.26, 0.20, 0.30, 0.24, 0.16, -70.0, 70.0, 5, 0.09, 0.03, 0.6),
		CHEST_C + Vector3(0, -0.10, 0.12))
	# dark rosettes over the flanks and the haunches
	var spots: Array = [[-0.38, 62.0], [-0.12, 70.0], [0.18, 64.0], [-0.52, 36.0], [0.36, 40.0]]
	for sx: float in [-1.0, 1.0]:
		for sp: Array in spots:
			var z: float = float(sp[0])
			var a := deg_to_rad(float(sp[1]) * sx)
			var r: float = 0.36
			var n := Vector3(sin(a), cos(a), 0.0)
			_rosette(s, spot, BC + Vector3(0, 0, z) + Vector3(n.x * r, n.y * r * SY, 0) + n * 0.012, n, 0.075)
	# team saddle-cloth over the back, a light team hem each side, a leather cantle
	var at := Transform3D(Basis.IDENTITY, BC)
	sculpt_add(s, drape_mesh("sd_cloth_v1", 0.385, 0.39, -104.0, 104.0, -0.40, 0.16, 8, 2, 1.0, 0.1), at, cdark)
	for sx: float in [-1.0, 1.0]:
		var a0 := 94.0 * sx
		var a1 := 108.0 * sx
		sculpt_add(s, drape_mesh("sd_hem_%s_v1" % sx, 0.39, 0.395, minf(a0, a1), maxf(a0, a1), -0.41, 0.17, 1, 2, 1.0, 0.1),
			at, cloth)
	sculpt_put(s, box(Vector3(0.30, 0.12, 0.06)), leather, Vector3(0, 1.36, -0.34), Vector3(-14, 0, 0))


# ================================================================ head (neck, skull, ears)

func _head_sculpt(s: Dictionary) -> void:
	var coat := m("sd_coat")
	var pale := m("sd_pale")
	var spot := m("sd_spot")
	sculpt_add(s, tube_mesh("sd_neck_v1", PackedVector3Array([Vector3(0, 1.02, 0.56), Vector3(0, 1.14, 0.72),
		Vector3(0, 1.24, 0.86)]), PackedFloat32Array([0.23, 0.20, 0.17]), 7, false), Transform3D.IDENTITY, coat)
	# the round skull (face canvas), a short pale muzzle, a dark nose, a pale chin
	sculpt_put(s, sphere(SKULL_R, 8, 5), coat, SKULL_C, Vector3.ZERO, SKULL_S)
	sculpt_put(s, sphere(0.12, 6, 3), pale, Vector3(0, 1.22, 1.10), Vector3.ZERO, Vector3(1.0, 0.72, 0.85))
	sculpt_put(s, spike_mesh(3), spot, Vector3(0, 1.28, 1.19), Vector3(-65, 0, 0), Vector3(0.035, 0.05, 0.03))
	sculpt_put(s, sphere(0.08, 5, 2), pale, Vector3(0, 1.13, 1.02), Vector3.ZERO, Vector3(1.0, 0.6, 1.0))
	# triangular ears with dark tufts, a dark brow bar, pale cheek ruffs
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, spike_mesh(3), coat, Vector3(0.12 * sx, 1.43, 0.88), Vector3(-10, 0, -18.0 * sx), Vector3(0.075, 0.17, 0.04))
		sculpt_put(s, spike_mesh(3), spot, Vector3(0.155 * sx, 1.585, 0.875), Vector3(-10, 0, -22.0 * sx), Vector3(0.018, 0.08, 0.018))
		sculpt_lock(s, pale, Vector3(0.17 * sx, 1.22, 0.92), Vector3(0.6 * sx, -1.0, -0.3).normalized(),
			Vector3(sx, -0.2, 0.3).normalized(), 0.13, 0.17, 0.05)
		_rosette(s, spot, SKULL_C + Vector3(0.10 * sx, 0.15, -0.02), Vector3(0.45 * sx, 1.0, 0.1).normalized(), 0.05)


static func face_spec() -> Dictionary:
	var dir := Vector3(0.50, 0.28, 0.82).normalized()
	var eye := SKULL_C + Vector3(dir.x * SKULL_R * SKULL_S.x, dir.y * SKULL_R * SKULL_S.y, dir.z * SKULL_R * SKULL_S.z)
	var out := Vector3(dir.x / SKULL_S.x, dir.y / SKULL_S.y, dir.z / SKULL_S.z).normalized()
	return CreatureFaceRig.side_eye_spec(eye, out, 0.042, Color(0.30, 0.34, 0.43), Color(0.50, 0.90, 1.0), 0.85)


static func face_style() -> Dictionary:
	var spec := face_spec()
	var st := FaceKit.style_from(spec)
	var r: float = spec["radius"]
	st["canvas"] = FaceKit.canvas(spec["center"], r, spec["head_mesh"], spec.get("head_scale", Vector3.ONE), Vector3.INF,
		Basis.IDENTITY, float(spec["lift"]))
	st["density"] = 6.0
	return st


# ================================================================ legs + tail

## Lithe legs rooted at the pivot p: fronts straight, hinds with a hock; big pale snowshoe paws.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var coat := m("sd_coat")
	var pale := m("sd_pale")
	var front: bool = p.z > 0.0
	var x := p.x
	var z := p.z
	if front:
		sculpt_add(s, tube_mesh("sd_leg_f_v1", PackedVector3Array([Vector3(0, 0.95, 0), Vector3(0, 0.50, 0.03),
			Vector3(0, 0.13, 0.05)]), PackedFloat32Array([0.16, 0.115, 0.095]), 6, false),
			Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), coat)
	else:
		sculpt_add(s, tube_mesh("sd_leg_b_v1", PackedVector3Array([Vector3(0, 0.98, 0.02), Vector3(0, 0.62, -0.16),
			Vector3(0, 0.32, -0.08), Vector3(0, 0.13, 0.02)]), PackedFloat32Array([0.21, 0.13, 0.09, 0.09]), 6, false),
			Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), coat)
	sculpt_put(s, sphere(0.13, 6, 2), pale, Vector3(x, 0.07, z + 0.08), Vector3.ZERO, Vector3(1.0, 0.55, 1.3))


func _tail_sculpt(s: Dictionary) -> void:
	var coat := m("sd_coat")
	var spot := m("sd_spot")
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	for i: int in TAIL.size():
		pts.append(TAIL[i])
		rad.append(TAIL_R[i])
	sculpt_add(s, tube_mesh("sd_tail_v1", pts, rad, 6, false), Transform3D.IDENTITY, coat)
	# the dark tip and two dark rings
	var tip := TAIL[TAIL.size() - 1]
	var d := (tip - TAIL[TAIL.size() - 2]).normalized()
	sculpt_add(s, sphere(1.0, 6, 3), Transform3D(Basis(Quaternion(Vector3.UP, d)).scaled_local(Vector3(0.09, 0.13, 0.09)),
		tip), spot)
	for i: int in [2, 4]:
		var t := (TAIL[i + 1] - TAIL[i - 1]).normalized()
		sculpt_add(s, cyl(TAIL_R[i] + 0.012, TAIL_R[i] + 0.012, 0.05, 6, false), Transform3D(Basis(Quaternion(Vector3.UP, t)),
			TAIL[i]), spot)


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


# cat_swipe (play_attack with the rider's slash, 0.5 s): the right fore paw rakes forward, the head snaps forward and
# low, a small lunge. Keyframe tracks [t, v, ease, ...] (MountModel._mkf).
static var CS_PAW := PackedFloat32Array([0.0, 0.0, 0, 0.08, -48.0, 1, 0.14, -8.0, 2, 0.30, -4.0, 0, 0.5, 0.0, 0])
static var CS_PAW_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 0.20, 1, 0.14, 0.06, 2, 0.30, 0.02, 0, 0.5, 0.0, 0])
static var CS_HEAD := PackedFloat32Array([0.0, 0.0, 0, 0.08, -12.0, 1, 0.14, 16.0, 2, 0.30, 6.0, 0, 0.5, 0.0, 0])
static var CS_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.04, 1, 0.14, 0.16, 2, 0.30, 0.06, 0, 0.5, 0.0, 0])
static var CS_BODY := PackedFloat32Array([0.0, 0.0, 0, 0.08, -6.0, 1, 0.14, 4.0, 2, 0.5, 0.0, 0])


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"cat_swipe":
		return super(prev, t)
	var k: float = 1.0 - 0.5 * _walk_w
	rot(P_LEG_FR, Vector3(_mkf(t, CS_PAW) * DEG * k, 0, -8.0 * DEG * k * signf(_mkf(t, CS_PAW_Y))))
	pos(P_LEG_FR, Vector3(0, _mkf(t, CS_PAW_Y) * k, 0))
	rot(P_MOUNT_HEAD, Vector3(_mkf(t, CS_HEAD) * DEG, 0, 0))
	rot(P_MOUNT, Vector3(_mkf(t, CS_BODY) * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, 0, _mkf(t, CS_ROOT_Z) * k))
	xrot(X_TAIL, Vector3(-_mkf(t, CS_HEAD) * DEG, 0, 0))
	_swipe_prev = t
	return t < 0.5


## Stretch and swish: the cat stretches forward (fronts out, rump up), then its tail lashes side to side.
func _pose_fidget(t: float) -> float:
	var st := _k3(t, 0.0, 0.35, 0.8, 1.1, 1.0, 1.0)
	rot(P_MOUNT, Vector3(8.0 * DEG * st, 0, 0))
	rot(P_LEG_FL, Vector3(-22.0 * DEG * st, 0, 0))
	rot(P_LEG_FR, Vector3(-22.0 * DEG * st, 0, 0))
	rot(P_MOUNT_HEAD, Vector3(10.0 * DEG * st, 0, 0))
	var sw := _k3(t, 0.9, 1.1, 1.8, 2.1, 1.0, 1.0)
	xrot(X_TAIL, Vector3(10.0 * DEG * sw, 40.0 * DEG * sin((t - 0.9) * TAU * 1.6) * sw, 0))
	if _fidget_prev < 1.2 and t >= 1.2:
		_flare = maxf(_flare, 0.5)
		_on_mount_event(&"fidget_snort")
	return 2.1


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
	_swipe_prev = 0.0
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", 0.0)
		gi.set_instance_shader_parameter(&"flash_color", WHITE)
