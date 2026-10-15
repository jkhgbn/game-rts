extends NatureWarModel
## Bramblehorn (kingdom-nature.md 7.2; 8.V4, polish A2.2), Nature heavy bruiser, 2.2 m, radius 0.7, pop 2.
## A huge bison-like forest beast built to read HEAVY at 40 m: a towering shoulder hump carrying a shaggy mane of
## overlapping team leaves (with dark team locks hanging below), the back sloping down to a lower rump, a massive low
## head thrust forward under a heavy brow, and two enormous pale horns sweeping out, up and forward (a 2 m span)
## wrapped in dark brambles and thorns. Pillar front legs with moss-feathered hooves, a hocked rear.
## Glow points: the eye slits under the brow and the hearts of the 3 blossoms growing in the mane (nature_glow 1.5,
## the top view). The eyes flare on the charge.
## Motion: slow heavy breathing; a ground-shaking trot (a dip and dirt at each front footfall, head nodding, body
## rolling); `horn_gore` (own timeline, 0.85 s): coils low, weight back (0-0.09), explodes forward +0.55 m tossing the
## horns up at 0.12 (strike: splinters at the horns, a dirt burst on the ground), a head shake in the recovery;
## hits knock splinters off; fidget: paws the ground and snorts; death: front knees buckle, a last bellow, it rolls
## onto its side and sinks back into the moss (the Nature bloom rises).
## Parts: 30 meshes incl. the blob; 7 draw instances after the merge + 6 pre-built emitters.

const GORE_LEN := 0.85
const GORE_HIT := 0.12
# horn_gore tracks: [t, value, ease] (NatureWarModel._kf). Head x: + = nose down. Legs x: - = foot forward.
static var G_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.09, -0.20, 1, 0.12, 0.55, 2, 0.32, 0.46, 1, 0.85, 0.0, 0])
static var G_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.09, -0.09, 1, 0.12, 0.07, 2, 0.26, -0.05, 1, 0.45, 0.0, 0])
static var G_ROOT_X := PackedFloat32Array([0.0, 0.0, 0, 0.09, -5.0, 1, 0.12, 7.0, 2, 0.30, 3.0, 0, 0.85, 0.0, 0])
static var G_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.09, 30.0, 1, 0.12, -38.0, 2, 0.30, -22.0, 1, 0.60, 4.0, 0, 0.85, 0.0, 0])
static var G_HEAD_Y := PackedFloat32Array([0.0, 0.0, 0, 0.30, 0.0, 0, 0.42, 14.0, 0, 0.54, -12.0, 0, 0.66, 6.0, 0, 0.85, 0.0, 0])
static var G_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.09, -12.0, 1, 0.12, -34.0, 1, 0.34, -10.0, 0, 0.85, 0.0, 0])
static var G_LEG_B := PackedFloat32Array([0.0, 0.0, 0, 0.09, -14.0, 1, 0.12, 30.0, 1, 0.34, 8.0, 0, 0.85, 0.0, 0])
# death extras (the kit rolls the body onto its side from 0.25 s and sinks it from 0.55 s)
static var D_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.28, 72.0, 2, 1.0, 60.0, 0])
static var D_ROOT_X := PackedFloat32Array([0.0, 0.0, 0, 0.28, 16.0, 2, 0.55, 6.0, 0, 1.0, 6.0, 0])
static var D_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.28, -0.28, 2, 1.0, -0.28, 0])
static var D_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.12, -32.0, 1, 0.34, -24.0, 0, 0.55, 20.0, 2, 1.0, 20.0, 0])

var _gore_fx: GPUParticles3D
var _dirt_fx: GPUParticles3D
var _step_fx: GPUParticles3D
var _snort_fx: GPUParticles3D
var _head_mi: GeometryInstance3D
var _eye_flare: float = 0.0
var _eye_written: float = -1.0
var _last_half: float = 0.0
var _fidget_prev: float = 0.0


func _build_parts() -> void:
	var mount: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	var cloth := nature(&"nature_cloth")
	var cdark := nature(&"nature_cloth_dark")
	var hide := nature(&"nature_bark")
	var bdark := nature(&"nature_bark_dark")
	var horn := nature(&"nature_skin")
	var moss := nature(&"nature_moss")
	var ldark := nature(&"nature_leaf_dark")
	var thorn := nature(&"nature_thorn")
	var glow := nature(&"nature_glow")
	# ---- Body: deep chest, towering shoulder hump, barrel, smaller lower rump (the back slopes down: a bison line).
	add_part(mount, sphere(0.62, 10, 6), hide, Vector3(0, 1.30, 0.40), Vector3.ZERO, Vector3(1.28, 1.12, 1.2))
	add_part(mount, sphere(0.58, 10, 6), hide, Vector3(0, 1.80, 0.24), Vector3(-10, 0, 0), Vector3(1.2, 0.85, 1.12))
	add_part(mount, cyl(0.48, 0.55, 1.1, 10, false), hide, Vector3(0, 1.20, -0.34), Vector3(90, 0, 0))
	add_part(mount, sphere(0.50, 10, 5), hide, Vector3(0, 1.20, -0.88), Vector3.ZERO, Vector3(1.1, 1.0, 1.0))
	# Team: the dense leaf mane over hump and shoulders (team) over a lower dark-team layer, the girth band.
	add_part(mount, _mane_mesh(), cloth, Vector3.ZERO)
	add_part(mount, _mane_low_mesh(), cdark, Vector3.ZERO)
	# Art Lab R3 (green on the meadow): the girth band is team-dark and the rump saddle russet dry fern, so the big
	# back reads warm brown + team mane instead of one green mass.
	add_part(mount, cyl(0.545, 0.575, 0.26, 12, false), cdark, Vector3(0, 1.19, -0.42), Vector3(90, 0, 0))
	# Russet fern saddle on the rump, bramble spine down the back, moss tufts on the hump with 3 blossoms whose hearts glow.
	add_part(mount, sphere(0.48, 10, 4), nature(&"nature_hair"), Vector3(0, 1.50, -0.80), Vector3(10, 0, 0),
		Vector3(1.02, 0.45, 0.95))
	add_part(mount, _spine_mesh(), thorn, Vector3.ZERO)
	add_part(mount, _tufts_mesh(), moss, Vector3.ZERO)
	add_part(mount, _petals_mesh(), nature(&"nature_blossom"), Vector3.ZERO)
	add_part(mount, _hearts_mesh(), glow, Vector3.ZERO)
	# Tail: short bark whip with a moss tuft.
	add_part(mount, cyl(0.05, 0.11, 0.46, 6), hide, Vector3(0, 1.26, -1.42), Vector3(-50, 0, 0))
	add_part(mount, sphere(0.15, 6, 3), moss, Vector3(0, 1.08, -1.58), Vector3.ZERO, Vector3(1.0, 1.4, 1.0))
	# ---- Legs: pillar fronts, hocked rears, moss cuffs, dark split hooves.
	for leg: Node3D in legs:
		var p := model_origin(leg)
		var front: bool = p.z > 0.0
		var sx: float = signf(p.x)
		if front:
			add_part(leg, sphere(0.32, 8, 4), hide, p + Vector3(0.03 * sx, 0.0, 0.0), Vector3.ZERO, Vector3(1.0, 1.25, 1.05))
			add_part(leg, cyl(0.21, 0.26, 0.90, 8, false), hide, Vector3(p.x, 0.62, p.z + 0.03))
		else:
			add_part(leg, sphere(0.36, 8, 4), hide, p + Vector3(0.03 * sx, 0.04, 0.0), Vector3.ZERO, Vector3(0.9, 1.2, 1.1))
			add_part(leg, _hock_mesh(), hide, Vector3(p.x, 0, p.z))
		add_part(leg, sphere(0.28, 8, 3), moss, Vector3(p.x, 0.30, p.z + 0.03), Vector3.ZERO, Vector3(1.0, 0.6, 1.0))
		add_part(leg, _hoof_mesh(), bdark, Vector3(p.x, 0, p.z + 0.05))
	# ---- Head: heavy skull and dark muzzle, a pale bony boss across the forehead joining the horns (a battering
	# ram), two glowing slits under it, a moss beard, huge horns wrapped in dark brambles and thorns.
	var hc := Vector3(0, 1.10, 1.12)
	add_part(head, sphere(0.46, 10, 6), hide, hc, Vector3(-8, 0, 0), Vector3(1.1, 0.9, 1.05))
	# Eyes (FaceKit beast face, was two glowing slits): sap-glowing eyes under the bony boss with lids that narrow into
	# a glare on the charge (fierce) and droop when it falls (worried); the mouth hides under the muzzle.
	_face = FaceKit.attach(self, head, "bramblehorn", NatureFaces.style({
		"center": hc, "radius": 0.45, "head_mesh": sphere(0.46, 10, 6), "head_scale": Vector3(1.1, 0.9, 1.05), "head_at": hc,
		"preset": &"stern", "skin": NatureFaces.BARK, "eyes": Color(0.75, 1.0, 0.40), "detail": &"low",
		"x": NatureFaces.lean_x(1.2, {&"neutral": {"cut_in": 0.35}}),
		"palette": NatureFaces.beast_palette(NatureFaces.BARK, Color(0.60, 0.95, 0.25), 1.0),
		"eye": {"c": Vector2(0.20, 0.115), "hw": 0.075, "top": 0.042, "bot": 0.030, "ir": 0.032, "tilt": 0.02},
		"brow": {"inner": Vector2(0.12, 0.175), "mid": Vector2(0.20, 0.19), "outer": Vector2(0.28, 0.17),
			"w": Vector3(0.016, 0.015, 0.006)},
		"mouth": NatureFaces.beast_mouth(Vector2(0, -0.36)),
	}, Vector3(-8, 0, 0), 0.006))
	_face.set_meta(&"own_glow", true)
	add_part(head, sphere(0.30, 10, 5), hide, Vector3(0, 0.92, 1.42), Vector3(12, 0, 0), Vector3(1.2, 0.78, 1.0))
	add_part(head, _nostrils_mesh(), bdark, Vector3.ZERO)
	add_part(head, sphere(0.30, 10, 5), horn, Vector3(0, 1.40, 1.30), Vector3(-20, 0, 0), Vector3(1.5, 0.45, 1.0))
	add_part(head, _tusks_mesh(), horn, Vector3.ZERO)
	add_part(head, cyl(0.26, 0.0, 0.50, 7), moss, Vector3(0, 0.72, 1.28), Vector3(12, 0, 0))
	for sx: float in [-1.0, 1.0]:
		add_part(head, _horn_mesh(sx), horn, Vector3.ZERO)
		add_part(head, _bramble_mesh(sx), ldark, Vector3.ZERO)
		add_part(head, _horn_thorns_mesh(sx), thorn, Vector3.ZERO)
		add_leaf(head, Vector3(0.62 * sx, 1.56, 1.12), Vector3(0.18, 0.05, 0.30), ldark, Vector3(-30, 70.0 * sx, 0))
	# ---- Fx (all pre-built one-shots)
	_gore_fx = make_petals(Color(0.55, 0.42, 0.24), 12, 0.7, 0.35, 5.0, 0.15, true)
	_gore_fx.name = "GoreSplinters"
	_gore_fx.position = Vector3(0, 1.55, 1.75) - model_origin(head)
	head.add_child(_gore_fx)
	_dirt_fx = make_dust(Color(0.42, 0.33, 0.20), 10, 0.9, 0.45, 0.7, 1.1)
	_dirt_fx.name = "GoreDirt"
	_dirt_fx.position = Vector3(0, 0.1, 1.5)
	$Fx.add_child(_dirt_fx)
	_step_fx = make_dust(Color(0.45, 0.37, 0.24), 5, 0.7, 0.18, 0.55, 0.6)
	_step_fx.name = "StepDust"
	$Fx.add_child(_step_fx)
	_snort_fx = make_dust(Color(0.78, 0.80, 0.70), 5, 0.8, 0.06, 0.4, 1.4, 25.0)
	_snort_fx.name = "Snort"
	_snort_fx.position = Vector3(0, 0.92, 1.80) - model_origin(head)
	_snort_fx.rotation = Vector3(deg_to_rad(105.0), 0, 0)
	head.add_child(_snort_fx)
	add_hit_burst(Vector3(0, 1.6, 0.4), Color(0.55, 0.42, 0.24), 9)
	add_death_bloom(Vector3(0, 1.4, 0.0), 0.8, 14, 16)
	ensure_shadow_blob(0.7)
	_shadow.scale = Vector3(2.3, 1.0, 3.6)


# ================================================================ meshes (cached per type, model space)

const MANE_C := Vector3(0, 0, 0.30)


## Mane: two rows of big overlapping team leaves shingled over the hump and shoulders (tips out and down).
static func _mane_mesh() -> Mesh:
	var xs: Array[Transform3D] = []
	for i: int in 6:
		var a := TAU * float(i) / 6.0 + 0.3
		var out := Vector3(sin(a) * 1.1, 0, cos(a))
		xs.append(leaf_xform(MANE_C + Vector3(out.x * 0.16, 2.24, out.z * 0.16 - 0.04), out, Vector3(0.56, 0.09, 0.66), -24.0))
	for i: int in 11:
		var a := TAU * float(i) / 11.0 + 0.31
		var out := Vector3(sin(a) * 1.12, 0, cos(a))
		xs.append(leaf_xform(MANE_C + Vector3(out.x * 0.52, 2.00, out.z * 0.50 - 0.04), out, Vector3(0.56, 0.09, 0.70), -52.0))
	return cluster_mesh("bramblehorn_mane_a22", leaf_mesh(), xs)


## Lower mane layer (team dark) hanging over the shoulders, chest and flanks down to the elbows; none over the rump.
static func _mane_low_mesh() -> Mesh:
	var xs: Array[Transform3D] = []
	for i: int in 13:
		var a := TAU * float(i) / 13.0
		if cos(a) < -0.45:
			continue
		var out := Vector3(sin(a) * 1.08, 0, cos(a))
		var len: float = 0.66 if i % 2 == 0 else 0.58
		xs.append(leaf_xform(MANE_C + Vector3(out.x * 0.68, 1.66, out.z * 0.66 + 0.02), out, Vector3(0.48, 0.08, len), -74.0))
	return cluster_mesh("bramblehorn_manelow_a22", leaf_mesh(), xs)


## Bramble spine: 5 thorns raking back along the back behind the hump.
static func _spine_mesh() -> Mesh:
	const KEY := "bramblehorn_spine_a22"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	var cone := thorn_cone()   # G-C: UV-tagged (dark root, pale point)
	var ys: Array[float] = [1.98, 1.90, 1.80, 1.74, 1.68]
	var zs: Array[float] = [-0.18, -0.42, -0.66, -0.88, -1.08]
	var hs: Array[float] = [0.56, 0.54, 0.46, 0.38, 0.30]
	for i: int in 5:
		var dir := Vector3(0.16 * (1.0 if i % 2 == 0 else -1.0), 0.9, -0.42).normalized()
		var b := Basis(Quaternion(Vector3.UP, dir)).scaled_local(Vector3(0.09, hs[i], 0.09))
		st.append_from(cone, 0, Transform3D(b, Vector3(0, ys[i], zs[i]) + dir * hs[i] * 0.4))
	return _cached(KEY, _indexed(st))


const BLOSSOMS: Array[Vector3] = [Vector3(0.22, 2.30, 0.50), Vector3(-0.24, 2.33, 0.20), Vector3(0.10, 2.22, -0.10)]


static func _tufts_mesh() -> Mesh:
	const KEY := "bramblehorn_tufts_a22"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for i: int in BLOSSOMS.size():
		st.append_from(sphere(0.22, 8, 3), 0, Transform3D(Basis().scaled(Vector3(1.1, 0.5, 1.2)),
			BLOSSOMS[i] + Vector3(-0.04, -0.08, 0)))
	return _cached(KEY, _indexed(st))


## 3 open blossoms: pink five-sided disks facing up (the top view), cheap.
static func _petals_mesh() -> Mesh:
	const KEY := "bramblehorn_petals_a22"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for i: int in BLOSSOMS.size():
		st.append_from(sphere(0.18, 5, 3), 0, Transform3D(Basis(Vector3.UP, float(i)).scaled(Vector3(1.0, 0.32, 1.0)),
			BLOSSOMS[i]))
	return _cached(KEY, _indexed(st))


static func _hearts_mesh() -> Mesh:
	const KEY := "bramblehorn_hearts_a22"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for i: int in BLOSSOMS.size():
		st.append_from(sphere(0.075, 6, 3), 0, Transform3D(Basis(), BLOSSOMS[i] + Vector3(0, 0.05, 0)))
	return _cached(KEY, _indexed(st))


## Rear leg below the thigh: shin angled back to the hock, cannon down to the hoof (local x = 0, z = 0).
static func _hock_mesh() -> Mesh:
	return tapered_path_mesh("bramblehorn_hock_a22", PackedVector3Array([Vector3(0, 0.98, 0.02), Vector3(0, 0.52, -0.16),
		Vector3(0, 0.12, -0.02)]), PackedFloat32Array([0.24, 0.16, 0.17]))


## Split hoof: two dark rounded blocks (local x = 0).
static func _hoof_mesh() -> Mesh:
	const KEY := "bramblehorn_hoof_a22"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [-1.0, 1.0]:
		st.append_from(sphere(0.13, 6, 3), 0, Transform3D(Basis().scaled(Vector3(1.0, 0.8, 1.35)), Vector3(0.09 * s, 0.10, 0.02)))
	return _cached(KEY, _indexed(st))


static func _nostrils_mesh() -> Mesh:
	const KEY := "bramblehorn_nostrils_a22"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	for s: float in [-1.0, 1.0]:
		st.append_from(sphere(0.07, 6, 3), 0, Transform3D(Basis().scaled(Vector3(1.0, 0.7, 0.6)), Vector3(0.12 * s, 0.97, 1.69)))
	return _cached(KEY, _indexed(st))


## Two short pale tusks curling up out of the lower jaw.
static func _tusks_mesh() -> Mesh:
	if _mesh_cache.has("bramblehorn_tusks_a22"):
		return _mesh_cache["bramblehorn_tusks_a22"]
	var st := SurfaceTool.new()
	for s: float in [-1.0, 1.0]:
		st.append_from(tapered_path_mesh("bramblehorn_tusk_a22_%s" % s, PackedVector3Array([Vector3(0.24 * s, 0.82, 1.50),
			Vector3(0.31 * s, 0.96, 1.62), Vector3(0.30 * s, 1.10, 1.64)]), PackedFloat32Array([0.06, 0.045, 0.0])), 0,
			Transform3D.IDENTITY)
	return _cached("bramblehorn_tusks_a22", _indexed(st))


const HORN_PTS: Array[Vector3] = [Vector3(0.34, 1.42, 1.20), Vector3(0.70, 1.47, 1.08), Vector3(1.00, 1.63, 1.12),
	Vector3(1.12, 1.89, 1.32), Vector3(1.00, 2.12, 1.60)]
const HORN_R: Array[float] = [0.23, 0.19, 0.14, 0.085, 0.0]


static func _horn_pts(side: float) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for p: Vector3 in HORN_PTS:
		pts.append(Vector3(p.x * side, p.y, p.z))
	return pts


static func _horn_mesh(side: float) -> Mesh:
	var pts := _horn_pts(side)
	# G-C: thorn UV tag: the horn darkens to its root and pales to a bone point.
	return thorn_tagged("bramblehorn_horn_gc_%s" % side, tapered_path_mesh("bramblehorn_horn_a22_%s" % side, pts,
		PackedFloat32Array(HORN_R)), pts[0], pts[pts.size() - 1])


const VINE_N := 7


## Point k (0..VINE_N-1) of the bramble vine spiralling 1.6 turns up the horn, and its outward direction.
static func _vine_at(side: float, k: int) -> Array:
	var pts := _horn_pts(side)
	var f: float = 0.18 + 2.1 * float(k) / float(VINE_N - 1)
	var i: int = mini(int(f), pts.size() - 2)
	var u: float = f - float(i)
	var at := pts[i].lerp(pts[i + 1], u)
	var r: float = lerpf(HORN_R[i], HORN_R[i + 1], u)
	var d := (pts[i + 1] - pts[i]).normalized()
	var a := Vector3.UP.cross(d).normalized()
	var b := d.cross(a).normalized()
	var ang: float = float(k) / float(VINE_N - 1) * TAU * 1.6 * side
	var out := (a * cos(ang) + b * sin(ang)).normalized()
	return [at + out * (r + 0.015), out]


## Dark bramble vine wrapped in a spiral around the horn (one thin tapered path).
static func _bramble_mesh(side: float) -> Mesh:
	var pts := PackedVector3Array()
	var radii := PackedFloat32Array()
	for k: int in VINE_N:
		pts.append(_vine_at(side, k)[0])
		radii.append(0.045 if k < VINE_N - 1 else 0.02)
	return tapered_path_mesh("bramblehorn_vine_a22_%s" % side, pts, radii, 4, false)


## Thorns growing out of the vine (outward, leaning toward the horn tip).
static func _horn_thorns_mesh(side: float) -> Mesh:
	var key := "bramblehorn_hthorns_a22_%s" % side
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	var cone := thorn_cone()   # G-C: UV-tagged
	for k: int in [1, 2, 4, 5]:
		var v: Array = _vine_at(side, k)
		var n := (v[1] as Vector3 + Vector3(0, 0.25, 0.2)).normalized()
		var h: float = 0.22 if k < 4 else 0.16
		var b := Basis(Quaternion(Vector3.UP, n)).scaled_local(Vector3(0.055, h, 0.055))
		st.append_from(cone, 0, Transform3D(b, (v[0] as Vector3) + n * h * 0.4))
	return _cached(key, _indexed(st))


# ================================================================ kit hooks

func _war_ready() -> void:
	# The kit flashes the merged Chest / Head / ArmR on hits; a quadruped has none of those: add the body and head.
	for i: int in [P_MOUNT, P_MOUNT_HEAD]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m and not _flash_hit_targets.has(m):
			_flash_hit_targets.append(m)
	_head_mi = _merged_nodes.get(P_MOUNT_HEAD)


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"horn_gore":
		return super._pose_attack(prev, t)
	pos(P_ROOT, Vector3(0, _kf(t, G_ROOT_Y), _kf(t, G_ROOT_Z)))
	rot(P_ROOT, Vector3(_kf(t, G_ROOT_X) * DEG, 0, 0))
	rot(P_MOUNT_HEAD, Vector3(_kf(t, G_HEAD_X) * DEG, _kf(t, G_HEAD_Y) * DEG, 0))
	var f := _kf(t, G_LEG_F) * DEG
	var bk := _kf(t, G_LEG_B) * DEG
	rot(P_LEG_FL, Vector3(f, 0, 0)); rot(P_LEG_FR, Vector3(f * 0.8, 0, 0))
	rot(P_LEG_BL, Vector3(bk, 0, 0)); rot(P_LEG_BR, Vector3(bk * 0.85, 0, 0))
	_eye_flare = maxf(_eye_flare, clampf(t / 0.1, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.6, t)))
	if prev < GORE_HIT and t >= GORE_HIT:
		_on_action_event(&"release")
	return t < GORE_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"release" and _tier < 2:
		_gore_fx.restart()
		_dirt_fx.restart()


## Heavy trot: the kit's leg cycle, reined in (a big beast does not swing its legs wide), a body roll, the head
## nodding with each step, a dip and a puff of dirt at every front footfall.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var s: float = sin(TAU * _walk_p)
	var q: float = -6.0 * DEG * s * w
	rot(P_LEG_FL, Vector3(q, 0, 0)); rot(P_LEG_BR, Vector3(q, 0, 0))
	rot(P_LEG_FR, Vector3(-q, 0, 0)); rot(P_LEG_BL, Vector3(-q, 0, 0))
	var foot: float = pow(1.0 - absf(s), 5.0)
	pos(P_ROOT, Vector3(0, -0.06 * foot * w, 0))
	rot(P_ROOT, Vector3(0, 0, 2.5 * DEG * s * w))
	if _action != &"attack":
		rot(P_MOUNT_HEAD, Vector3((10.0 + 5.0 * sin(TAU * _walk_p * 2.0 + 0.6)) * DEG * w, 4.0 * DEG * s * w, 0))
	if _tier == 0 and _step_fx:
		var half: float = fmod(_walk_p, 0.5)
		if half < _last_half:
			var sx: float = -1.0 if _walk_p < 0.5 else 1.0
			_step_fx.position = Vector3(0.44 * sx, 0.06, 0.66)
			_step_fx.restart()
		_last_half = half


func _pose_death(dt: float) -> void:
	super(dt)
	var t: float = _death_t
	var f: float = _kf(t, D_LEG_F) * DEG
	rot(P_LEG_FL, Vector3(f, 0, 0)); rot(P_LEG_FR, Vector3(f * 0.9, 0, 0))
	rot(P_ROOT, Vector3(_kf(t, D_ROOT_X) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _kf(t, D_ROOT_Y), 0))
	rot(P_MOUNT_HEAD, Vector3(_kf(t, D_HEAD_X) * DEG, 0, 0))
	# The kit sinks 0.6 x body_height: a 2.2 m beast would drop 1.3 m through the floor; keep it to ~0.9 m.
	var g: float = _ease_in(clampf((t - 0.55) / 0.45, 0.0, 1.0))
	pos(P_ROOT, Vector3(0, 0.35 * g, 0))


## Fidget: paws the ground twice with a front hoof, head low, then a snort.
func _pose_fidget(t: float) -> float:
	var low := _k3(t, 0.0, 0.3, 1.5, 2.0, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3(18.0 * DEG * low, -8.0 * DEG * low, 0))
	var paw: float = 0.0
	if t > 0.25 and t < 1.35:
		paw = sin((t - 0.25) / 1.1 * TAU * 2.0)
	rot(P_LEG_FR, Vector3((-26.0 * maxf(paw, 0.0) + 14.0 * maxf(-paw, 0.0)) * DEG * low, 0, 0))
	pos(P_ROOT, Vector3(0, -0.03 * low, -0.04 * low))
	for k: float in [0.72, 1.28]:
		if _fidget_prev < k and t >= k and _step_fx:
			_step_fx.position = Vector3(0.44, 0.06, 0.78)
			_step_fx.restart()
	if _fidget_prev < 1.55 and t >= 1.55 and _snort_fx:
		_snort_fx.restart()
		_eye_flare = 0.6
	_fidget_prev = t
	return 2.0


func _war_process(dt: float) -> void:
	# Eye flare (charge / snort): written on the face rig (the glowing eyes, own_glow).
	if _face == null:
		return
	if _action != &"attack":
		_eye_flare = maxf(0.0, _eye_flare - dt / 0.35)
	if _action != &"fidget":
		_fidget_prev = 0.0
	var b: float = glow_level() * (1.0 + 1.6 * _eye_flare)
	if absf(b - _eye_written) > 0.02 or (_eye_flare == 0.0 and b != _eye_written):
		_eye_written = b
		_face.set_instance_shader_parameter(&"glow_boost", b)


func _war_revive() -> void:
	_eye_flare = 0.0
	_eye_written = -1.0
	_fidget_prev = 0.0
