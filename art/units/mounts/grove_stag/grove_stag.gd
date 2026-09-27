extends MountModel
## Grove Stag (cavalry-mounts.md 6.1 / 10, task 13.V5): the Nature mount (Stagrunner 13.V9, Ysolde riding 13.V11).
## A giant, heavy forest stag (withers 1.6 m, ~2.9 m nose to tail): a deep olive-brown coat under a green moss shawl
## over the shoulders, a hanging moss mane under the throat, moss on the rump; long sturdy legs ending in BARK HOOVES
## (split wooden toes under a ragged bark collar). The read at 40 m: WIDE, LOW antlers (~2.4 m across) of pale
## bark-ivory, each beam ending in a broad palm with a crown of tines, hung with moss, carrying THREE GLOWING BLOSSOMS
## (one on each palm, one on the brow between the antlers; pink petals around a lime core).
## Team saddle-cloth (nature_cloth) with a dark hem and a leaf emblem, leather saddle with a bark cantle and a
## sprouting pommel, bark stirrups, leaf tassels.
## Barding (set_barded): woven bark plates (nature_bark weft over nature_bark_dark warp) on the chest, shoulders,
## haunches and rump, a crinet of overlapping bark scales on the neck and a bark chanfron on the face, thorn studs;
## the antlers and blossoms stay bare.
## Apart from the neutral Hollow Stag (huge, PALE, tall dark bare-branch antlers with small green leaves, open chest
## with a green heart) and the small red deer (slim, red-brown, white rump, upright pale tines, no glow): dark mossy
## coat, team saddle, the wide low palmed rack and the three pink blossoms.
## Motion: 4-beat walk, a bounding gallop from 3.5 m/s, generic charge (antlers levelled, lunge, toss) and hit; a
## "graze and toss" fidget (sniffs the ground, then tosses the rack, blossoms flare); death: stumbles, rolls onto its
## side with the head propped on the rack, the moss withers.
## Budget (section 10 mount): 11 authored meshes incl. the blob (7 sculpts + 3 barding sculpts + blob), 8 draw
## instances (Body, Neck, Head, 4 legs, blob; the short tail is part of the body), 0 lights, 0 particle systems.

const OWN := "res://art/units/mounts/grove_stag/materials/"
const NAT := "res://art/units/nature/materials/"
const BLOB_TINT := Color(0.04, 0.05, 0.02, 0.5)
const WITHER := Vector3(0.42, 0.30, 0.08)

## Barrel (body) of revolution along z, centred on BC, vertical stretch SY (deeper than wide). Profile [z offset, r].
const BC := Vector3(0, 1.14, -0.08)
const SY := 1.12
const BARREL_Z: Array[float] = [-0.92, -0.88, -0.74, -0.50, -0.15, 0.20, 0.48, 0.70, 0.84, 0.90]
const BARREL_R: Array[float] = [0.00, 0.22, 0.34, 0.39, 0.40, 0.40, 0.39, 0.34, 0.22, 0.00]
## Chest, withers and rump ellipsoids (centre, radii).
const CHEST_C := Vector3(0, 1.06, 0.56)
const CHEST_R := Vector3(0.34, 0.42, 0.34)
const WITHERS_C := Vector3(0, 1.42, 0.40)
const WITHERS_R := Vector3(0.28, 0.22, 0.36)
const RUMP_C := Vector3(0, 1.22, -0.74)
const RUMP_R := Vector3(0.35, 0.36, 0.32)
## Neck core (points, radii), from the withers up-forward into the skull.
const NECK_P: Array[Vector3] = [Vector3(0, 1.22, 0.58), Vector3(0, 1.52, 0.78), Vector3(0, 1.80, 0.94),
	Vector3(0, 2.02, 1.04)]
const NECK_R: Array[float] = [0.30, 0.24, 0.19, 0.16]
## Skull: axis from SK_B (back of the skull) toward SK_F (nose); lathe profile [s, r], lateral squash SK_X.
const SK_B := Vector3(0, 2.10, 0.98)
const SK_F := Vector3(0, 1.84, 1.48)
const SK_S: Array[float] = [-0.03, 0.0, 0.08, 0.20, 0.33, 0.45, 0.53, 0.575]
const SK_R: Array[float] = [0.0, 0.15, 0.18, 0.172, 0.14, 0.108, 0.09, 0.0]
const SK_X := 0.82
## Right antler beam (x mirrored for the left): pedicle -> palm; the palm centre sits past AB[3].
const AB: Array[Vector3] = [Vector3(0.08, 2.19, 1.00), Vector3(0.27, 2.29, 0.98), Vector3(0.52, 2.38, 0.92),
	Vector3(0.78, 2.47, 0.84), Vector3(0.96, 2.55, 0.76)]
const AB_R: Array[float] = [0.072, 0.064, 0.057, 0.052, 0.048]
const PALM_C := Vector3(0.92, 2.56, 0.78)
## The brow blossom (between the pedicles, on the moss cap).
const BROW_BLOOM := Vector3(0, 2.29, 1.03)

var _wither_v: float = 0.0


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var neck: Node3D = $Root/Mount/Neck
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(neck, _neck_sculpt)
	add_sculpt(head, _head_sculpt)
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	# Barding: woven bark merged into barded variants of Body, Neck and Head.
	add_barding_sculpt(body, _body_barding)
	add_barding_sculpt(neck, _neck_barding)
	add_barding_sculpt(head, _head_barding)
	ensure_shadow_blob(0.7, BLOB_TINT)
	_shadow.scale = Vector3(2.1, 1.0, 3.8)
	_shadow.position = Vector3(0, 0.02, 0.1)


static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("grove_stag") else NAT) + name + ".tres")


# ================================================================ shared helpers

static func _barrel_r(zl: float) -> float:
	if zl <= BARREL_Z[0] or zl >= BARREL_Z[BARREL_Z.size() - 1]:
		return 0.0
	for i: int in range(1, BARREL_Z.size()):
		if zl < BARREL_Z[i]:
			return lerpf(BARREL_R[i - 1], BARREL_R[i], (zl - BARREL_Z[i - 1]) / (BARREL_Z[i] - BARREL_Z[i - 1]))
	return 0.0


## [point, outward normal] on the barrel at model z and angle a (deg from the top toward +x).
static func _barrel_pt(z: float, a_deg: float) -> Array:
	var r := _barrel_r(z - BC.z)
	var a := deg_to_rad(a_deg)
	var p := BC + Vector3(r * sin(a), r * SY * cos(a), z - BC.z)
	var n := Vector3(sin(a) / maxf(r, 0.05), cos(a) / maxf(r * SY, 0.05), 0.0).normalized()
	return [p, n]


## [point, outward normal] on an ellipsoid at azimuth theta (deg from +z toward +x) and elevation phi (deg).
static func _ell_pt(c: Vector3, r: Vector3, theta_deg: float, phi_deg: float) -> Array:
	var th := deg_to_rad(theta_deg)
	var ph := deg_to_rad(phi_deg)
	var u := Vector3(cos(ph) * sin(th), sin(ph), cos(ph) * cos(th))
	return [c + u * r, (u / r).normalized()]


## A unit sphere stretched into an ellipsoid with axes (a, b, c) and half-lengths (ra, rb, rc).
static func _ellipsoid(s: Dictionary, mat: Material, at: Vector3, a: Vector3, b: Vector3, c: Vector3,
		r: Vector3, radial: int = 8, rings: int = 4) -> void:
	sculpt_add(s, sphere(1.0, radial, rings), Transform3D(Basis(a.normalized() * r.x, b.normalized() * r.y,
		c.normalized() * r.z), at), mat)


## Basis whose Z runs along `t` and whose Y is the part of `up` perpendicular to it (for shells along a bone).
static func _along(t: Vector3, up: Vector3) -> Basis:
	var z := t.normalized()
	var y := (up - z * up.dot(z)).normalized()
	return Basis(y.cross(z), y, z)


## A cone from `base` along `dir` (length len, base radius r) - tines, thorns, sprouts.
static func _cone(s: Dictionary, mat: Material, base: Vector3, dir: Vector3, r: float, len: float, seg: int = 6) -> void:
	var d := dir.normalized()
	sculpt_add(s, cyl(0.0, 1.0, 1.0, seg), Transform3D(Basis(Quaternion(Vector3.UP, d)).scaled_local(Vector3(r, len, r)),
		base + d * len * 0.5), mat)


## THE READ: a blossom facing `n` - five glowing pink petals around a lime core, on a cup of five leaves. sz 1 = 0.38 m.
static func _blossom(s: Dictionary, c: Vector3, n: Vector3, sz: float, spin: float = 0.0) -> void:
	var glow := m("grove_stag_bloom")
	var core := m("nature_glow")
	var leaf := m("nature_leaf")
	var nn := n.normalized()
	var f := frame(c, nn, Vector3(0.3, 0.1, 1.0) if absf(nn.z) < 0.9 else Vector3.RIGHT)
	var bx := f.basis.x
	var bz := f.basis.z
	for i: int in 5:
		var a := TAU * float(i) / 5.0 + spin
		var d := bx * cos(a) + bz * sin(a)
		# petals: tilted up 28 deg, cupped
		var pd := (d * cos(0.49) + nn * sin(0.49)).normalized()
		var side := nn.cross(pd).normalized()
		var pu := pd.cross(side).normalized()
		_ellipsoid(s, glow, c + pd * 0.085 * sz + nn * 0.01 * sz, side, pu, pd, Vector3(0.068, 0.026, 0.11) * sz, 6, 3)
		# leaves between the petals, flatter, reaching further, slightly down
		var a2 := a + TAU / 10.0
		var ld := ((bx * cos(a2) + bz * sin(a2)) * cos(0.12) - nn * sin(0.12)).normalized()
		var ls := nn.cross(ld).normalized()
		_ellipsoid(s, leaf, c + ld * 0.12 * sz - nn * 0.03 * sz, ls, ld.cross(ls), ld, Vector3(0.05, 0.016, 0.12) * sz, 4, 2)
	sculpt_put(s, sphere(0.05, 6, 3), core, c + nn * 0.035 * sz, Vector3.ZERO, Vector3.ONE * sz)


# ================================================================ body (barrel, moss, saddle, tail)

func _body_sculpt(s: Dictionary) -> void:
	var hide := m("grove_stag_hide")
	var moss := m("nature_moss")
	var leaf := m("nature_leaf")
	var leaf_d := m("nature_leaf_dark")
	var cloth := m("nature_cloth")
	var cdark := m("nature_cloth_dark")
	var leather := m("nature_bark_dark")
	var bark := m("nature_bark")
	var bark_d := m("nature_bark_dark")
	# ---- mass: barrel, deep chest, withers, rump
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	var barrel := lathe_mesh("grove_stag_barrel_v1", prof, 12)
	sculpt_add(s, barrel, Transform3D(Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(1, 1, SY)), BC), hide)
	sculpt_put(s, sphere(0.40, 12, 6), hide, CHEST_C, Vector3.ZERO, CHEST_R / 0.40)
	sculpt_put(s, sphere(0.40, 10, 5), hide, WITHERS_C, Vector3.ZERO, WITHERS_R / 0.40)
	sculpt_put(s, sphere(0.40, 10, 5), hide, RUMP_C, Vector3.ZERO, RUMP_R / 0.40)
	# ---- moss shawl: a ragged green collar round the neck root draping over the shoulders (open behind, where the
	# rider sits), bright moss tufts on its crest
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(30.0))
	sculpt_fringe(s, moss, fringe_mesh("grove_stag_shawl_v1", 0.25, 0.28, 0.46, 0.50, 0.24, -125.0, 125.0, 13, 0.13, 0.03,
		0.6), Vector3(0, 1.60, 0.56), tilt)
	sculpt_fringe(s, leaf_d, fringe_mesh("grove_stag_shawl_in_v1", 0.22, 0.25, 0.34, 0.38, 0.14, -110.0, 110.0, 9, 0.09,
		0.03, 0.6), Vector3(0, 1.68, 0.60), tilt)
	for i: int in 5:
		var th: float = -60.0 + 30.0 * float(i)
		var e := _ell_pt(WITHERS_C, WITHERS_R, th, 38.0)
		sculpt_put(s, sphere(0.10, 6, 3), leaf if i % 2 == 0 else moss, (e[0] as Vector3) + Vector3(0, 0.03, 0.04),
			Vector3.ZERO, Vector3(1.2, 0.55, 1.1))
	# ---- moss on the rump: a flat cap with a ragged fringe, three fern sprouts
	sculpt_put(s, sphere(0.30, 10, 5), moss, RUMP_C + Vector3(0, 0.30, -0.06), Vector3(-8, 0, 0), Vector3(1.05, 0.30, 1.0))
	sculpt_fringe(s, moss, fringe_mesh("grove_stag_rumpmoss_v1", 0.24, 0.24, 0.33, 0.32, 0.08, 0.0, 360.0, 11, 0.09, 0.025,
		0.7), RUMP_C + Vector3(0, 0.30, -0.06))
	for k: int in 3:
		var sx: float = float(k - 1)
		_cone(s, leaf, RUMP_C + Vector3(0.12 * sx, 0.36, -0.10 - 0.06 * absf(sx)), Vector3(0.5 * sx, 1.0, -0.5), 0.035,
			0.20 - 0.04 * absf(sx))
	# ---- short tail with a moss tuft (no white rump: that is the red deer)
	var tp := PackedVector3Array([Vector3(0, 1.40, -1.02), Vector3(0, 1.32, -1.12), Vector3(0, 1.18, -1.15)])
	sculpt_add(s, tube_mesh("grove_stag_tail_v1", tp, PackedFloat32Array([0.075, 0.07, 0.045]), 6), Transform3D.IDENTITY,
		hide)
	for i: int in 4:
		var a := TAU * float(i) / 4.0
		var out := Vector3(sin(a), 0.0, cos(a) * 0.6 - 0.4).normalized()
		sculpt_lock(s, moss, tp[2] + Vector3(0, 0.05, 0) + out * 0.03, (out * 0.3 + Vector3.DOWN).normalized(), out, 0.11,
			0.20, 0.05)
	# ---- team saddle-cloth draped over the back, dark hem, leaf emblems, leaf tassels
	var at := Transform3D(Basis.IDENTITY, BC)
	sculpt_add(s, shell_mesh("grove_stag_cloth_v1", 0.425, 0.465, -118.0, 118.0, -0.46, 0.14, 0.03, 14, 3, 1.0, 0.02),
		at, cloth)
	for sx: float in [-1.0, 1.0]:
		var a0: float = 108.0 * sx
		var a1: float = 121.0 * sx
		sculpt_add(s, shell_mesh("grove_stag_hem_%s" % sx, 0.435, 0.475, minf(a0, a1), maxf(a0, a1), -0.47, 0.15, 0.035,
			2, 3, 1.0, 0.02), at, cdark)
		var e := _barrel_pt(-0.25, 92.0 * sx)
		var nn: Vector3 = e[1]
		var ep: Vector3 = (e[0] as Vector3) + nn * 0.05
		var eb := frame(ep, Vector3.UP, nn).basis
		# emblem: a dark diamond with a team-green leaf (vein in dark cloth)
		sculpt_add(s, box(Vector3(0.24, 0.24, 0.02)), Transform3D(eb * Basis(Vector3.BACK, PI * 0.25), ep), cdark)
		sculpt_add(s, sphere(1.0, 8, 4), Transform3D(eb * Basis(Vector3.BACK, 0.5) * Basis.from_scale(Vector3(0.065, 0.14,
			0.018)), ep + nn * 0.012), cloth)
		sculpt_add(s, box(Vector3(0.018, 0.22, 0.02)), Transform3D(eb * Basis(Vector3.BACK, 0.5), ep + nn * 0.024), cdark)
		# leaf tassels at the hem corners
		for zc: float in [0.05, -0.53]:
			var tq := _barrel_pt(zc, 121.0 * sx)
			var tn: Vector3 = tq[1]
			sculpt_lock(s, leaf, (tq[0] as Vector3) + tn * 0.04, Vector3(0.15 * sx, -1.0, 0).normalized(), tn, 0.09, 0.18,
				0.03)
	sculpt_add(s, shell_mesh("grove_stag_hemback_v1", 0.44, 0.48, -121.0, 121.0, -0.50, -0.44, 0.035, 14, 1), at, cdark)
	# ---- saddle: leather seat, bark cantle, a bark pommel sprouting two leaves, straps, bark stirrups, girth
	sculpt_put(s, box(Vector3(0.40, 0.07, 0.46)), leather, Vector3(0, 1.605, -0.20), Vector3(-3, 0, 0))
	sculpt_put(s, sphere(0.23, 10, 4), leather, Vector3(0, 1.63, -0.21), Vector3.ZERO, Vector3(0.9, 0.18, 1.0))
	sculpt_add(s, shell_mesh("grove_stag_cantle_v1", 0.20, 0.13, -84.0, 84.0, -0.04, 0.04, 0.06, 6, 1),
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-15.0)), Vector3(0, 1.60, -0.43)), bark)
	sculpt_put(s, cyl(0.04, 0.065, 0.15, 7), bark, Vector3(0, 1.70, 0.03), Vector3(12, 0, 0))
	sculpt_put(s, sphere(0.06, 7, 3), bark_d, Vector3(0, 1.78, 0.05))
	for sx: float in [-1.0, 1.0]:
		_cone(s, leaf, Vector3(0.02 * sx, 1.82, 0.05), Vector3(0.8 * sx, 0.9, 0.3), 0.04, 0.13)
		sculpt_put(s, box(Vector3(0.04, 0.20, 0.30)), leather, Vector3(0.41 * sx, 1.49, -0.20), Vector3(0, 0, -24.0 * sx))
		sculpt_put(s, box(Vector3(0.035, 0.40, 0.055)), leather, Vector3(0.48 * sx, 1.16, -0.12), Vector3(0, 0, -5.0 * sx))
		sculpt_put(s, torus(0.035, 0.08, 10), bark, Vector3(0.50 * sx, 0.93, -0.12), Vector3(0, 0, 90))
		sculpt_put(s, box(Vector3(0.05, 0.03, 0.12)), bark_d, Vector3(0.50 * sx, 0.865, -0.12))
	sculpt_add(s, shell_mesh("grove_stag_girth_v1", 0.435, 0.475, -180.0, 180.0, 0.15, 0.24, 0.025, 14, 1), at, leather)


# ================================================================ neck (moss mane)

func _neck_sculpt(s: Dictionary) -> void:
	var hide := m("grove_stag_hide")
	var moss := m("nature_moss")
	var leaf := m("nature_leaf")
	var pts := PackedVector3Array(NECK_P)
	sculpt_add(s, tube_mesh("grove_stag_neck_v1", pts, PackedFloat32Array(NECK_R), 9, false, 0.8), Transform3D.IDENTITY,
		hide)
	# the hanging moss mane under the throat (a stag's neck ruff, in moss): long locks, longest at mid-neck
	for i: int in 8:
		var t: float = float(i) / 7.0
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		var root := Vector3(0.07 * sx, lerpf(1.32, 1.86, t), lerpf(0.86, 1.10, t))
		var out := Vector3(0.35 * sx, -0.2, 1.0).normalized()
		var ln: float = 0.30 + 0.16 * sin(PI * clampf(t * 1.1, 0.0, 1.0))
		sculpt_lock(s, leaf if i == 3 else moss, root, Vector3(0.1 * sx, -1.0, 0.25).normalized(), out, 0.19, ln, 0.06)
	# a short moss crest down the back of the neck
	for i: int in 5:
		var t: float = float(i) / 4.0
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		var root := Vector3(0.05 * sx, lerpf(2.10, 1.64, t), lerpf(0.94, 0.66, t))
		var nn := Vector3(0.6 * sx, 0.6, -0.5).normalized()
		sculpt_lock(s, moss, root, (nn * 0.6 + Vector3(0, -0.6, -0.4)).normalized(), nn, 0.17, 0.20, 0.05)


# ================================================================ head (skull, ears, antlers, blossoms)

func _head_sculpt(s: Dictionary) -> void:
	var hide := m("grove_stag_hide")
	var moss := m("nature_moss")
	var dark := m("nature_bark_dark")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var prof := PackedVector2Array()
	for i: int in SK_S.size():
		prof.append(Vector2(SK_R[i], SK_S[i]))
	var skull := lathe_mesh("grove_stag_skull_v1", prof, 12)
	var sf := frame(SK_B, sd, Vector3.UP)
	sculpt_add(s, skull, Transform3D(Basis(sf.basis.x * SK_X, sf.basis.y, sf.basis.z), SK_B), hide)
	# jaw, dark nose pad, brows, eyes
	_ellipsoid(s, hide, SK_B + sd * 0.30 - up * 0.08, Vector3.RIGHT, up, sd, Vector3(0.10, 0.075, 0.20))
	_ellipsoid(s, dark, SK_B + sd * 0.545 + up * 0.01, Vector3.RIGHT, up, sd, Vector3(0.075, 0.06, 0.05))
	for sx: float in [-1.0, 1.0]:
		var eye := SK_B + sd * 0.15 + up * 0.055 + Vector3(0.128 * sx, 0, 0)
		sculpt_put(s, sphere(0.042, 6, 3), dark, eye, Vector3.ZERO, Vector3(0.8, 0.9, 1.2))
		sculpt_put(s, sphere(0.06, 6, 3), hide, eye + up * 0.05 + Vector3(-0.01 * sx, 0, -0.01), Vector3.ZERO,
			Vector3(1.0, 0.5, 1.4))
		# ears: broad leaf-shaped, angled out under the antlers
		var ear := SK_B + up * 0.08 + Vector3(0.15 * sx, 0, -0.07)
		var ed := Vector3(1.0 * sx, 0.25, -0.35).normalized()
		_ellipsoid(s, hide, ear + ed * 0.11, Vector3(0, 1, 0).cross(ed), Vector3.UP, ed, Vector3(0.075, 0.025, 0.13), 8, 3)
		_ellipsoid(s, moss, ear + ed * 0.11 + Vector3(0, 0.012, 0), Vector3(0, 1, 0).cross(ed), Vector3.UP, ed,
			Vector3(0.05, 0.02, 0.09), 6, 3)
	# moss beard under the chin
	for i: int in 3:
		var x: float = -0.06 + 0.06 * float(i)
		sculpt_lock(s, moss, SK_B + sd * 0.26 - up * 0.15 + Vector3(x, 0, 0), Vector3(x, -1.0, -0.25).normalized(),
			Vector3(0, -0.3, 1).normalized(), 0.10, 0.18, 0.04)
	# moss cap on the brow between the pedicles, carrying the brow blossom
	sculpt_put(s, sphere(0.13, 8, 4), moss, Vector3(0, 2.21, 1.01), Vector3(-10, 0, 0), Vector3(1.35, 0.45, 1.15))
	_blossom(s, BROW_BLOOM, Vector3(0, 1.0, 0.45), 1.05, 0.3)
	# the rack
	for sx: float in [-1.0, 1.0]:
		_antler(s, sx)


## One antler (sx = +1 right, -1 left): a heavy beam sweeping OUT and back with a forward brow tine and a bez tine,
## ending in a broad palm with a crown of four tines; moss wraps, hanging moss; a blossom on the palm. The left
## antler also trails an ivy vine (the asymmetric secondary shape).
func _antler(s: Dictionary, sx: float) -> void:
	var ant := m("grove_stag_antler")
	var moss := m("nature_moss")
	var leaf := m("nature_leaf")
	var leaf_d := m("nature_leaf_dark")
	var mx := Vector3(sx, 1, 1)
	var beam := PackedVector3Array()
	for p: Vector3 in AB:
		beam.append(p * mx)
	sculpt_add(s, tube_mesh("grove_stag_beam_%s" % sx, beam, PackedFloat32Array(AB_R), 7), Transform3D.IDENTITY, ant)
	# burr (the ring at the pedicle), moss wrapped over it
	sculpt_put(s, sphere(0.095, 7, 3), moss, AB[0] * mx + Vector3(0.02 * sx, 0.03, 0), Vector3.ZERO, Vector3(1.0, 0.6, 1.0))
	# brow tine (forward, curling up) and bez tine (up)
	sculpt_add(s, tube_mesh("grove_stag_brow_%s" % sx, PackedVector3Array([AB[1] * mx, Vector3(0.32 * sx, 2.34, 1.16),
		Vector3(0.37 * sx, 2.45, 1.30)]), PackedFloat32Array([0.045, 0.035, 0.0]), 6), Transform3D.IDENTITY, ant)
	sculpt_add(s, tube_mesh("grove_stag_bez_%s" % sx, PackedVector3Array([AB[2] * mx, Vector3(0.56 * sx, 2.54, 0.98),
		Vector3(0.60 * sx, 2.66, 1.02)]), PackedFloat32Array([0.042, 0.032, 0.0]), 6), Transform3D.IDENTITY, ant)
	# the palm: a broad flat blade facing up-forward-in, across the end of the beam
	var u := ((AB[4] - AB[2]) * mx).normalized()                  # along the beam (outward)
	var up0 := Vector3(0, 1.0, -0.35)
	var v := (up0 - u * up0.dot(u)).normalized()                   # in the palm plane, up-back
	var nr := u.cross(v).normalized()                              # (u, v, nr) right-handed: no mirrored ellipsoids
	var n := nr if nr.y >= 0.0 else -nr                            # the palm's upper face normal (offsets)
	var pc := PALM_C * mx
	_ellipsoid(s, ant, pc, u, v, nr, Vector3(0.30, 0.19, 0.045), 10, 5)
	_ellipsoid(s, ant, pc - u * 0.20 - v * 0.02, u, v, nr, Vector3(0.14, 0.10, 0.05), 8, 4)
	# crown of tines along the palm's upper / outer edge, fanning out
	var tines: Array = [[-0.16, 0.20, 0.10], [-0.02, 0.26, 0.25], [0.12, 0.26, 0.45], [0.25, 0.20, 0.75]]
	for t: Array in tines:
		var k: float = t[0]
		var base: Vector3 = pc + u * k + v * (0.15 - absf(k) * 0.25)
		var dir: Vector3 = (v * (1.0 - float(t[2]) * 0.5) + u * float(t[2]) + n * 0.15).normalized()
		_cone(s, ant, base, dir, 0.038, float(t[1]))
	# the outer point beyond the palm
	_cone(s, ant, pc + u * 0.26 - v * 0.04, (u + v * 0.1).normalized(), 0.04, 0.16)
	# moss draped on the palm base and hanging under it
	_ellipsoid(s, moss, pc - u * 0.14 + n * 0.035, u, v, nr, Vector3(0.13, 0.10, 0.03), 8, 3)
	for i: int in 3:
		var root: Vector3 = pc + u * (-0.20 + 0.16 * float(i)) - v * 0.14
		sculpt_lock(s, moss, root, Vector3(0.1 * sx, -1.0, 0.0).normalized(), -v, 0.12, 0.20 + 0.06 * float(i % 2), 0.035)
	# THE BLOSSOM on the palm
	_blossom(s, pc - u * 0.02 + n * 0.06, (n + Vector3(0, 0.6, 0.2)).normalized(), 1.25, 0.9 * sx)
	if sx < 0.0:
		# ivy vine trailing from the left palm, a few leaves on it
		var vp := PackedVector3Array([pc + u * 0.05 - v * 0.12, pc + u * 0.12 - v * 0.30 + Vector3(0, 0, 0.04),
			pc + u * 0.08 - v * 0.46 + Vector3(0, 0, 0.02)])
		sculpt_add(s, tube_mesh("grove_stag_vine_v1", vp, PackedFloat32Array([0.018, 0.015, 0.0]), 4), Transform3D.IDENTITY,
			leaf_d)
		for i: int in 3:
			var lp: Vector3 = vp[i] if i < 2 else (vp[1] + vp[2]) * 0.5
			var ld := Vector3(-0.6 + 0.6 * float(i), -0.5, 0.6).normalized()
			_ellipsoid(s, leaf, lp + ld * 0.05, Vector3.UP.cross(ld).normalized(), Vector3.UP, ld, Vector3(0.045, 0.012,
				0.07), 6, 3)


# ================================================================ legs (bark hooves)

## A long sturdy leg rooted at the pivot p: forearm / thigh, knee or hock, slim cannon, a ragged bark collar at the
## fetlock and a split BARK HOOF (two wooden toes with dark tips).
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var hide := m("grove_stag_hide")
	var bark := m("nature_bark")
	var bark_d := m("nature_bark_dark")
	var moss := m("nature_moss")
	var front: bool = p.z > 0.0
	var x := p.x
	var z := p.z
	var o := Transform3D(Basis.IDENTITY, Vector3(x, 0, z))
	if front:
		sculpt_add(s, tube_mesh("grove_stag_fore_v1", PackedVector3Array([Vector3(0, 1.10, 0), Vector3(0, 0.80, 0.02),
			Vector3(0, 0.54, 0.03)]), PackedFloat32Array([0.16, 0.125, 0.085]), 7, false), o, hide)
		sculpt_put(s, sphere(0.078, 6, 3), hide, Vector3(x, 0.54, z + 0.035))
		sculpt_add(s, tube_mesh("grove_stag_cannon_f_v1", PackedVector3Array([Vector3(0, 0.54, 0.03), Vector3(0, 0.32, 0.035),
			Vector3(0, 0.15, 0.05)]), PackedFloat32Array([0.07, 0.06, 0.068]), 7, false), o, hide)
	else:
		sculpt_put(s, sphere(0.20, 8, 4), hide, Vector3(x, 0.98, z - 0.02), Vector3.ZERO, Vector3(0.85, 1.35, 1.15))
		sculpt_add(s, tube_mesh("grove_stag_thigh_v1", PackedVector3Array([Vector3(0, 1.02, 0), Vector3(0, 0.74, 0.10),
			Vector3(0, 0.50, -0.10)]), PackedFloat32Array([0.17, 0.125, 0.08]), 7, false), o, hide)
		sculpt_put(s, sphere(0.072, 6, 3), hide, Vector3(x, 0.50, z - 0.10))
		sculpt_add(s, tube_mesh("grove_stag_cannon_b_v1", PackedVector3Array([Vector3(0, 0.50, -0.10), Vector3(0, 0.30, -0.05),
			Vector3(0, 0.15, -0.02)]), PackedFloat32Array([0.068, 0.06, 0.068]), 7, false), o, hide)
	var hz: float = z + (0.05 if front else -0.01)
	# bark collar (ragged strips) over the fetlock, a moss wisp at its back
	sculpt_fringe(s, bark, fringe_mesh("grove_stag_collar_v2", 0.078, 0.078, 0.112, 0.112, 0.08, 0.0, 360.0, 6, 0.06, 0.02, 0.7),
		Vector3(x, 0.27, hz))
	sculpt_lock(s, moss, Vector3(x, 0.24, hz - 0.07), Vector3(0, -1.0, -0.4).normalized(), Vector3.BACK, 0.07, 0.10, 0.03)
	# the split bark hoof: two wooden toes (bark, dark tips) leaning forward
	for side: float in [-1.0, 1.0]:
		var tx := x + 0.036 * side
		sculpt_put(s, cyl(0.042, 0.058, 0.14, 6), bark, Vector3(tx, 0.095, hz + 0.02), Vector3(-14, 0, 0), Vector3(1.0, 1.0, 1.35))
		sculpt_put(s, cyl(0.03, 0.052, 0.05, 6), bark_d, Vector3(tx, 0.028, hz + 0.05), Vector3.ZERO, Vector3(1.0, 1.0, 1.45))


# ================================================================ barding (woven bark plates)

## Woven plate: `rows` weft strips (bark, alternately proud) across the angle range, over dark warp bands.
static func _weave(s: Dictionary, key: String, xf: Transform3D, rx: float, ry: float, a0: float, a1: float, l0: float,
		l1: float, rows: int, taper: float = 1.0) -> void:
	var bark := m("nature_bark")
	var bark_d := m("nature_bark_dark")
	# dark backing / warp
	sculpt_add(s, shell_mesh(key + "_back", rx, ry, a0, a1, l0, l1, 0.03, 4, 1, taper), xf, bark_d)
	# weft strips across the length (split along the angle) - over / under by a small radius offset
	var da: float = (a1 - a0) / float(rows)
	for i: int in rows:
		var proud: float = 0.022 if i % 2 == 0 else 0.012
		sculpt_add(s, shell_mesh(key + "_w%d" % i, rx + proud, ry + proud, a0 + da * float(i) + 1.0,
			a0 + da * float(i + 1) - 1.0, l0 + 0.015, l1 - 0.015, 0.03, 2, 1, taper), xf, bark)
	# a warp band over the weft at mid length (the basket read)
	var lk: float = (l0 + l1) * 0.5
	sculpt_add(s, shell_mesh(key + "_p", rx + 0.035, ry + 0.035, a0, a1, lk - 0.03, lk + 0.03, 0.02, 6, 1, taper), xf, bark_d)


func _body_barding(s: Dictionary) -> void:
	var thorn := m("nature_thorn")
	var leaf := m("nature_leaf")
	var at := Transform3D(Basis.IDENTITY, BC)
	# shoulder plates (in front of the saddle-cloth) and haunch plates (behind it), each side
	for sx: float in [-1.0, 1.0]:
		var a0: float = 48.0 if sx > 0.0 else -122.0
		var a1: float = 122.0 if sx > 0.0 else -48.0
		_weave(s, "grove_stag_sh_%s" % sx, at, 0.44, 0.50, a0, a1, 0.17, 0.52, 4, 0.92)
		_weave(s, "grove_stag_ha_%s" % sx, at, 0.44, 0.49, a0, a1, -0.92, -0.52, 4, 0.86)
		var e := _barrel_pt(BC.z + 0.36, 70.0 * sx)
		_cone(s, thorn, (e[0] as Vector3) + (e[1] as Vector3) * 0.08, (e[1] as Vector3) + Vector3(0, 0.2, 0.3), 0.035, 0.14)
		var e2 := _barrel_pt(BC.z - 0.72, 70.0 * sx)
		_cone(s, thorn, (e2[0] as Vector3) + (e2[1] as Vector3) * 0.08, (e2[1] as Vector3) + Vector3(0, 0.2, -0.3), 0.035,
			0.14)
	# crupper over the rump top (the moss cap and sprouts poke through a gap in the middle)
	for sx: float in [-1.0, 1.0]:
		var a0: float = 12.0 if sx > 0.0 else -46.0
		var a1: float = 46.0 if sx > 0.0 else -12.0
		_weave(s, "grove_stag_cr_%s" % sx, at, 0.45, 0.50, a0, a1, -0.94, -0.54, 2, 0.84)
	# peytral: a woven guard across the front of the chest (shell axis vertical, angle 0 = forward)
	var cb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))
	_weave(s, "grove_stag_pey", Transform3D(cb, CHEST_C), 0.37, 0.37, -74.0, 74.0, -0.30, 0.20, 5)
	sculpt_add(s, shell_mesh("grove_stag_pey_rim", 0.405, 0.405, -76.0, 76.0, 0.18, 0.23, 0.03, 8, 1),
		Transform3D(cb, CHEST_C), m("nature_bark_dark"))
	_cone(s, thorn, CHEST_C + Vector3(0, 0.02, 0.40), Vector3(0, 0.1, 1.0), 0.045, 0.16)
	for sx: float in [-1.0, 1.0]:
		_cone(s, thorn, CHEST_C + Vector3(0.22 * sx, 0.10, 0.33), Vector3(0.5 * sx, 0.2, 1.0), 0.035, 0.12)
		# leaf sprig tucked in the peytral rim
		_cone(s, leaf, CHEST_C + Vector3(0.28 * sx, 0.20, 0.28), Vector3(0.7 * sx, 0.7, 0.4), 0.035, 0.14)


func _neck_barding(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var bark_d := m("nature_bark_dark")
	# crinet: four overlapping bark scales down the crest of the neck
	for i: int in 4:
		var t: float = 0.12 + 0.22 * float(i)
		var i0: int = mini(int(t * 3.0), 2)
		var f: float = t * 3.0 - float(i0)
		var c: Vector3 = NECK_P[i0].lerp(NECK_P[i0 + 1], f)
		var tan: Vector3 = (NECK_P[i0 + 1] - NECK_P[i0]).normalized()
		var r: float = lerpf(NECK_R[i0], NECK_R[i0 + 1], f)
		var xf := Transform3D(_along(-tan, Vector3(0, 1, -0.6)), c)
		sculpt_add(s, shell_mesh("grove_stag_crinet_%d" % i, r * 0.86 + 0.05, r + 0.05, -62.0, 62.0, -0.14, 0.12, 0.03, 6, 1,
			0.82, 0.08), xf, bark if i % 2 == 0 else bark_d)
	# a throat band
	var tb := Transform3D(_along((NECK_P[1] - NECK_P[0]).normalized(), Vector3(0, 1, -0.6)), NECK_P[0].lerp(NECK_P[1], 0.55))
	sculpt_add(s, shell_mesh("grove_stag_throat_v1", 0.25, 0.27, 100.0, 260.0, -0.05, 0.05, 0.03, 8, 1), tb, bark_d)


func _head_barding(s: Dictionary) -> void:
	var bark := m("nature_bark")
	var bark_d := m("nature_bark_dark")
	var thorn := m("nature_thorn")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var hb := _along(sd, up)
	var at := Transform3D(hb, SK_B)
	# chanfron down the face (between the eyes to the nose), rim, cheek plates
	sculpt_add(s, shell_mesh("grove_stag_chanfron_v1", 0.155, 0.20, -58.0, 58.0, 0.10, 0.50, 0.03, 6, 2, 0.62, 0.05), at, bark)
	sculpt_add(s, shell_mesh("grove_stag_chanfron_w_v1", 0.165, 0.21, -58.0, 58.0, 0.22, 0.26, 0.02, 6, 1, 0.9), at, bark_d)
	sculpt_add(s, shell_mesh("grove_stag_chanfron_r_v1", 0.16, 0.205, -60.0, 60.0, 0.08, 0.12, 0.035, 6, 1), at, bark_d)
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, shell_mesh("grove_stag_cheek_%s" % sx, 0.15, 0.19, minf(68.0 * sx, 112.0 * sx), maxf(68.0 * sx, 112.0 * sx),
			0.16, 0.36, 0.03, 3, 1, 0.8), at, bark)
	_cone(s, thorn, SK_B + sd * 0.30 + up * 0.17, (up + sd * 0.6).normalized(), 0.04, 0.14)


# ================================================================ motion (on top of MountModel)

func _mount_ready() -> void:
	_wither_v = 0.0


## Graze and toss: the head goes down to sniff / crop the ground (neck low, a few chews), then comes up with a proud
## toss of the rack (a shake side to side), a snort (the blossoms flare).
func _pose_fidget(t: float) -> float:
	var down := _k3(t, 0.0, 0.35, 1.05, 1.35, 1.0, 1.0)
	xrot(X_NECK, Vector3(34.0 * DEG * down, 0, 0))
	var chew: float = sin(t * TAU * 3.2) * down * smoothstep(0.35, 0.5, t)
	rot(P_MOUNT_HEAD, Vector3((26.0 * down + 4.0 * chew) * DEG, 0, 0))
	rot(P_MOUNT, Vector3(3.0 * DEG * down, 0, 0))
	var toss := _k3(t, 1.25, 1.45, 1.9, 2.2, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3(-14.0 * DEG * toss, 0, 16.0 * DEG * sin((t - 1.25) * TAU * 2.4) * toss))
	xrot(X_NECK, Vector3(-6.0 * DEG * toss, 0, 0))
	if t > 0.5 and t < 1.0:
		rot(P_LEG_FL, Vector3(-10.0 * DEG * sin((t - 0.5) / 0.5 * PI), 0, 0))
	if _fidget_prev < 1.5 and t >= 1.5:
		_flare = maxf(_flare, 0.7)
		_on_mount_event(&"fidget_snort")
	return 2.2


## Death: the moss withers (a faint ochre tint that stays); the head is propped on the rack instead of burying it.
func _mount_process(_dt: float) -> void:
	if not _dead:
		return
	var roll: float = clampf(_death_t / 0.62, 0.0, 1.0)
	# counter-roll the neck / head so the uppermost antler points up and the lower one rests on the ground
	xrot(X_NECK, Vector3(-18.0 * DEG * roll, 0, 0))
	rot(P_MOUNT_HEAD, Vector3(-10.0 * DEG * roll, 0, -52.0 * DEG * roll * _fall_side))
	var v: float = snappedf(0.12 * smoothstep(0.15, 0.85, _death_t), 0.02)
	if v == _wither_v:
		return
	_wither_v = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", WITHER)


func _mount_revive() -> void:
	_wither_v = 0.0
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", 0.0)
		gi.set_instance_shader_parameter(&"flash_color", WHITE)
