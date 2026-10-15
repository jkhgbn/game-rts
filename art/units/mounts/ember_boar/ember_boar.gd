extends MountModel
## Ember Boar (cavalry-mounts.md 6.1 / 10, task 13.V2): the Fire mount (Vessa riding 13.V11, the Blaze Rider refresh
## 13.V10). The Blaze Rider's flame-maned war boar (art/units/fire/build_fire_units.gd "4.4 Blaze Rider") extracted
## into a MountModel and taken to hero quality: a 2.5 m sooty maroon war boar with a towering shoulder hump, a hide
## seamed with slow-pulsing ember cracks, dark bristled socks and split hooves, a wedge head with small slanted ember
## eyes under an angry brow and ivory tusks curling out and up. THE READ at 40 m: a crest of streaming flame tongues
## (orange, yellow-hot at the roots) from the brow over the neck and hump, and again over the rump, leaning back like a
## mane in the wind. Team caparison (fire_cloth) from the Blaze Rider: a blanket over the back whose side drapes end
## in a flame-cut hem under a dark stripe, a bronze sun-disc badge with a flame sigil; leather saddle with a bronze
## pommel horn and cantle, stirrups.
## Barding (set_barded): a bronze face plate (chanfron) with a central ridge, a forehead spike and a leather strap,
## bronze rings and caps on the tusks, overlapping bronze flank plates on the shoulders (with a team flame sigil) and
## the haunches, leather rims and bronze bosses, bronze knee cops on the fore legs.
## Reads apart from the neutral Bristleback (small russet mud boar, pale spike ridge, no tack, no glow) and the Tusker
## (huge steel-grey plated boar, rust bristles): flames + team cloth + bronze.
## Motion: a quick short-stepping walk, a bounding gallop from 3.3 m/s (the tail snaps straight up), the kit charge
## (head drops to level the tusks, lunge, gore toss, the flames flare), a "root and toss" fidget (nose down snuffling,
## then a head toss that flares the mane), hit; death: stumbles, rolls onto its side and smoulders (an ember glow that
## dies away).
## Budget (section 10 mount): 12 authored meshes incl. the blob (7 sculpts + 4 barding sculpts + blob), 8 draw
## instances (Body, Head, 4 legs, Tail, blob) plain and barded, 0 lights, 0 particle systems (the flames are glow
## meshes: they pulse in the shader and flare with the kit's glow_boost).

const OWN := "res://art/units/mounts/ember_boar/materials/"
const KIT := "res://art/units/kit/materials/"
const BLOB_TINT := Color(0.05, 0.02, 0.01, 0.5)
const EMBER := Vector3(1.0, 0.30, 0.05)

## Barrel (body) of revolution along z, centred on BC, vertical squash SY, lateral squash LX. Profile [z offset, r].
const BC := Vector3(0, 0.74, -0.02)
const SY := 0.95
const LX := 0.86
const BARREL_Z: Array[float] = [-0.95, -0.91, -0.78, -0.55, -0.20, 0.15, 0.45, 0.66, 0.80, 0.87]
const BARREL_R: Array[float] = [0.00, 0.20, 0.33, 0.42, 0.45, 0.47, 0.46, 0.40, 0.28, 0.00]
## Shoulder hump and rump ellipsoids (centre, radii).
const HUMP_C := Vector3(0, 1.06, 0.40)
const HUMP_R := Vector3(0.36, 0.30, 0.44)
const RUMP_C := Vector3(0, 0.90, -0.55)
const RUMP_R := Vector3(0.36, 0.26, 0.40)
## Skull: axis from SK_B along SK_D; lathe profile [s along the axis (m), radius], lateral squash SK_X.
const SK_B := Vector3(0, 1.04, 0.70)
const SK_F := Vector3(0, 0.60, 1.42)
const SK_S: Array[float] = [-0.02, 0.0, 0.10, 0.26, 0.44, 0.60, 0.72, 0.80, 0.81]
const SK_R: Array[float] = [0.0, 0.29, 0.34, 0.32, 0.265, 0.205, 0.17, 0.16, 0.0]
const SK_X := 0.86
## Caparison: z range, columns (even = notch, odd = flame tip), barrel angles of its rows.
const DRAPE_Z0 := -0.40
const DRAPE_Z1 := 0.06
const DRAPE_COLS := 10
const DRAPE_A: Array[float] = [0.0, 32.0, 64.0, 94.0]
## G-C legs (MountShapes.leg rows: y, z offset, radius), top to the coronet; the sock (fire_hair) starts at row 4.
const FORE_ROWS: Array[Vector3] = [Vector3(0.80, 0.0, 0.16), Vector3(0.66, -0.02, 0.152), Vector3(0.54, 0.0, 0.122),
	Vector3(0.45, 0.018, 0.098), Vector3(0.385, 0.03, 0.086), Vector3(0.335, 0.036, 0.09), Vector3(0.285, 0.036, 0.078),
	Vector3(0.19, 0.04, 0.07), Vector3(0.12, 0.045, 0.074), Vector3(0.075, 0.05, 0.07)]
const HIND_ROWS: Array[Vector3] = [Vector3(0.78, 0.0, 0.15), Vector3(0.64, 0.03, 0.138), Vector3(0.52, -0.02, 0.11),
	Vector3(0.44, -0.058, 0.09), Vector3(0.38, -0.075, 0.08), Vector3(0.345, -0.08, 0.083), Vector3(0.30, -0.062, 0.074),
	Vector3(0.20, -0.02, 0.07), Vector3(0.12, 0.012, 0.072), Vector3(0.075, 0.028, 0.07)]

var _smoulder_v: float = 0.0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "ember_boar", face_spec())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	add_sculpt($Root/Mount/Tail, _tail_sculpt)
	# Barding: bronze plates merged into barded variants of Body, Head and the two fore legs.
	add_barding_sculpt(body, _body_barding)
	add_barding_sculpt(head, _head_barding)
	for leg: Node3D in [legs[0], legs[1]]:
		var p := model_origin(leg)
		add_barding_sculpt(leg, func(s: Dictionary) -> void: _knee_barding(s, p))
	ensure_shadow_blob(0.6, BLOB_TINT)
	_shadow.scale = Vector3(2.0, 1.0, 3.6)
	_shadow.position = Vector3(0, 0.02, 0.12)


static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("ember_boar") else KIT) + name + ".tres")


# ================================================================ shape helpers

static func _barrel_r(zl: float) -> float:
	if zl <= BARREL_Z[0] or zl >= BARREL_Z[BARREL_Z.size() - 1]:
		return 0.0
	for i: int in range(1, BARREL_Z.size()):
		if zl < BARREL_Z[i]:
			return lerpf(BARREL_R[i - 1], BARREL_R[i], (zl - BARREL_Z[i - 1]) / (BARREL_Z[i] - BARREL_Z[i - 1]))
	return 0.0


## [point, outward normal] on the barrel at model z, angle a (deg from the top toward +x), pushed out by `off`.
static func _bp(z: float, a_deg: float, off: float = 0.0) -> Array:
	var r := _barrel_r(z - BC.z)
	var a := deg_to_rad(a_deg)
	var n := Vector3(sin(a) / maxf(r * LX, 0.05), cos(a) / maxf(r * SY, 0.05), 0.0).normalized()
	return [Vector3(r * LX * sin(a), BC.y + r * SY * cos(a), z) + n * off, n]


## [point, outward normal] on an ellipsoid at azimuth theta (deg from +z toward +x) and elevation phi (deg).
static func _ell_pt(c: Vector3, r: Vector3, theta_deg: float, phi_deg: float) -> Array:
	var th := deg_to_rad(theta_deg)
	var ph := deg_to_rad(phi_deg)
	var u := Vector3(cos(ph) * sin(th), sin(ph), cos(ph) * cos(th))
	return [c + u * r, (u / r).normalized()]


## Flame tongue: a blade-like tongue along +Y (length 1, width ~0.8) whose tip curls toward +Z.
static func flame_mesh() -> Mesh:
	return tube_mesh("ember_boar_flame_v1", PackedVector3Array([Vector3(0, -0.04, 0), Vector3(0, 0.28, -0.05),
		Vector3(0, 0.58, 0.02), Vector3(0, 0.82, 0.16), Vector3(0, 1.0, 0.34)]),
		PackedFloat32Array([0.36, 0.40, 0.28, 0.13, 0.0]), 7, true, 0.5)


## Hot core at a tongue's root: a round teardrop, fatter than the flattened tongue so it shows from every side.
static func core_mesh() -> Mesh:
	return tube_mesh("ember_boar_core_v1", PackedVector3Array([Vector3(0, -0.06, 0), Vector3(0, 0.22, 0.0),
		Vector3(0, 0.5, 0.06), Vector3(0, 0.78, 0.16)]), PackedFloat32Array([0.30, 0.34, 0.20, 0.0]), 6, true, 1.0)


## One flame of the mane: root (model), rising along dir, curling back (-Z model), width w, height h.
static func _flame(s: Dictionary, root: Vector3, dir: Vector3, w: float, h: float) -> void:
	var f := frame(root, dir, Vector3.FORWARD)
	sculpt_add(s, flame_mesh(), Transform3D(Basis(f.basis.x * w, f.basis.y * h, f.basis.z * w), root), m("fire_flame"))
	sculpt_add(s, core_mesh(), Transform3D(Basis(f.basis.x * w * 0.95, f.basis.y * h * 0.5, f.basis.z * w * 0.8), root),
		m("ember_boar_flame_core"))


## Caparison side (sx -1 / +1) following the barrel from the spine down to its widest point, then hanging: part 0 =
## the team cloth (blanket + side drape + the flame-cut hem teeth), part 1 = the dark stripe above the teeth.
static func _drape_mesh(sx: float, part: int) -> Mesh:
	var key := "ember_boar_drape_%s_%d_v1" % [sx, part]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []   # [row] -> Array of Vector3 per column (plain Arrays: packed arrays are copied by value)
	var nrm: Array = []
	for k: int in 6:
		pts.append([])
		nrm.append([])
	var nh := Vector3(sx, -0.12, 0.0).normalized()
	for i: int in DRAPE_COLS + 1:
		var z := lerpf(DRAPE_Z0, DRAPE_Z1, float(i) / float(DRAPE_COLS))
		for k: int in 4:
			var e := _bp(z, DRAPE_A[k] * sx, 0.035)
			(pts[k] as Array).append(e[0])
			(nrm[k] as Array).append(e[1])
		var r3: Vector3 = (pts[3] as Array)[i]
		var r4 := r3 + Vector3(0, -0.075, 0) + nh * 0.012
		(pts[4] as Array).append(r4)
		(nrm[4] as Array).append(nh)
		var tip: bool = i % 2 == 1
		var rnd: float = fposmod(sin(float(i) * 12.9898 + sx * 4.1) * 43758.5453, 1.0)
		var drop: float = 0.10 + (0.13 * (0.8 + 0.4 * rnd) if tip else 0.0)
		var r5 := r4 + Vector3(0, -drop, -0.05 if tip else 0.0) + nh * (0.03 if tip else 0.015)
		(pts[5] as Array).append(r5)
		(nrm[5] as Array).append(nh)
	var pairs: Array = [[0, 1], [1, 2], [2, 3], [4, 5]] if part == 0 else [[3, 4]]
	for pr: Array in pairs:
		var ra := PackedVector3Array(pts[pr[0]])
		var rb := PackedVector3Array(pts[pr[1]])
		var na := PackedVector3Array(nrm[pr[0]])
		var nb := PackedVector3Array(nrm[pr[1]])
		for i: int in DRAPE_COLS:
			var j := i + 1
			_emit(st, ra[i], ra[j], rb[j], na[i], na[j], nb[j])
			_emit(st, ra[i], rb[j], rb[i], na[i], nb[j], nb[i])
			var t := 0.014
			_emit(st, ra[i] - na[i] * t, rb[j] - nb[j] * t, ra[j] - na[j] * t, -na[i], -nb[j], -na[j])
			_emit(st, ra[i] - na[i] * t, rb[i] - nb[i] * t, rb[j] - nb[j] * t, -na[i], -nb[i], -nb[j])
	st.index()
	return _cached(key, st.commit())


# ================================================================ body

func _body_sculpt(s: Dictionary) -> void:
	var hide := m("ember_boar_hide")
	var hair := m("fire_hair")
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var leather := m("fire_leather")
	var bronze := m("fire_bronze")
	# ---- mass: barrel, shoulder hump, rump, deep chest, dark belly
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	sculpt_add(s, lathe_mesh("ember_boar_barrel_v1", prof, 12),
		Transform3D(Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(LX, 1, SY)), BC), hide)
	sculpt_put(s, sphere(0.40, 12, 6), hide, HUMP_C, Vector3.ZERO, HUMP_R / 0.40)
	sculpt_put(s, sphere(0.40, 10, 5), hide, RUMP_C, Vector3.ZERO, RUMP_R / 0.40)
	sculpt_put(s, sphere(0.34, 10, 5), hide, Vector3(0, 0.74, 0.60), Vector3(-10, 0, 0), Vector3(1.0, 1.05, 0.9))
	sculpt_put(s, sphere(0.30, 10, 4), hair, Vector3(0, 0.40, 0.04), Vector3.ZERO, Vector3(1.0, 0.42, 2.0))
	# ---- the mane: dark bristles along the hump, flame tongues streaming back from the hump crest
	for i: int in 6:
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		var t: float = floorf(float(i) * 0.5) / 2.0
		var root := Vector3(0.09 * sx, lerpf(1.33, 1.30, t), lerpf(0.30, 0.62, t))
		var nn := Vector3(0.8 * sx, 0.55, 0.0).normalized()
		sculpt_lock(s, hair, root, (nn * 0.6 + Vector3.DOWN).normalized(), nn, 0.2, 0.30, 0.06)
	var hf: Array = [[0.66, 0.56, 0.27, 0.10], [0.53, 0.72, 0.31, -0.10], [0.40, 0.68, 0.31, 0.10], [0.29, 0.42, 0.23, -0.08]]
	for f: Array in hf:
		var z: float = f[0]
		var dz: float = (z - HUMP_C.z) / HUMP_R.z
		var y: float = HUMP_C.y + HUMP_R.y * sqrt(maxf(1.0 - dz * dz, 0.0)) - 0.04
		_flame(s, Vector3(0, y, z), Vector3(f[3], 1.0, -0.42), f[2], f[1])
	# rump: a bristle ridge and three flames behind the saddle
	for i: int in 4:
		var z: float = -0.46 - 0.12 * float(i)
		var dz: float = (z - RUMP_C.z) / RUMP_R.z
		var y: float = RUMP_C.y + RUMP_R.y * sqrt(maxf(1.0 - dz * dz, 0.0)) - 0.03
		sculpt_lock(s, hair, Vector3(0, y, z), Vector3(0, 0.7, -1.0).normalized(), Vector3.UP, 0.13, 0.18, 0.05)
	var rf: Array = [[-0.58, 0.36, 0.22, 0.08], [-0.71, 0.30, 0.20, -0.08], [-0.83, 0.22, 0.16, 0.0]]
	for f: Array in rf:
		var z: float = f[0]
		var dz: float = (z - RUMP_C.z) / RUMP_R.z
		var y: float = RUMP_C.y + RUMP_R.y * sqrt(maxf(1.0 - dz * dz, 0.0)) - 0.03
		_flame(s, Vector3(0, y, z), Vector3(f[3], 1.0, -0.7), f[2], f[1])
	# ---- team caparison: blanket + side drapes with the flame-cut hem under a dark stripe, bronze sun-disc badges
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, _drape_mesh(sx, 0), Transform3D.IDENTITY, cloth)
		sculpt_add(s, _drape_mesh(sx, 1), Transform3D.IDENTITY, cdark)
		var e := _bp(-0.29, 76.0 * sx, 0.05)
		var p: Vector3 = e[0]
		var n: Vector3 = e[1]
		var fb := frame(p, n, Vector3.UP).basis
		sculpt_add(s, cyl(0.11, 0.11, 0.025, 12), Transform3D(fb, p), bronze)
		sculpt_add(s, torus(0.085, 0.125, 12), Transform3D(fb, p + n * 0.006), bronze)
		var up := (Vector3.UP - n * n.dot(Vector3.UP)).normalized()
		var sb := frame(p + n * 0.02, up, n).basis
		sculpt_add(s, cyl(0.0, 0.055, 0.15, 5), Transform3D(Basis(sb.x, sb.y, sb.z * 0.4), p + n * 0.02 + up * 0.005), cdark)
	# ---- saddle: seat, cantle, bronze pommel horn, stirrups, girth
	sculpt_put(s, sphere(0.24, 10, 4), leather, Vector3(0, 1.215, -0.17), Vector3.ZERO, Vector3(0.95, 0.2, 1.1))
	sculpt_put(s, box(Vector3(0.40, 0.05, 0.44)), leather, Vector3(0, 1.20, -0.17), Vector3(-2, 0, 0))
	sculpt_add(s, shell_mesh("ember_boar_cantle_v2", 0.19, 0.13, -84.0, 84.0, -0.04, 0.04, 0.08, 6, 1),
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-15.0)), Vector3(0, 1.235, -0.40)), leather)
	sculpt_put(s, cyl(0.035, 0.06, 0.16, 8), bronze, Vector3(0, 1.30, 0.04), Vector3(14, 0, 0))
	sculpt_put(s, sphere(0.055, 8, 4), bronze, Vector3(0, 1.385, 0.06))
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, box(Vector3(0.03, 0.40, 0.06)), leather, Vector3(0.47 * sx, 0.99, -0.07), Vector3(0, 0, -8.0 * sx))
		sculpt_put(s, torus(0.03, 0.075, 10), bronze, Vector3(0.50 * sx, 0.76, -0.07), Vector3(0, 0, 90))
		sculpt_put(s, box(Vector3(0.05, 0.03, 0.12)), bronze, Vector3(0.50 * sx, 0.69, -0.07))
	sculpt_add(s, shell_mesh("ember_boar_girth_v1", 0.425, 0.465, -180.0, 180.0, 0.12, 0.19, 0.025, 14, 1),
		Transform3D(Basis.IDENTITY, BC), leather)


# ================================================================ head (neck, skull, tusks, head mane)

## Tusk core points (model space) for side sx: from the lip corner out, up and back.
static func _tusk_pts(sx: float) -> PackedVector3Array:
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var b := SK_B + sd * 0.66 - up * 0.10 + Vector3(0.14 * sx, 0, 0)
	return PackedVector3Array([b, b + Vector3(0.09 * sx, 0.0, 0.08), b + Vector3(0.155 * sx, 0.12, 0.10),
		b + Vector3(0.165 * sx, 0.27, 0.03)])


func _head_sculpt(s: Dictionary) -> void:
	var hide := m("ember_boar_hide")
	var hair := m("fire_hair")
	var tusk := m("fire_skin")
	var dark := m("unit_eye_dark")
	var glow := m("fire_glow")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	# ---- neck: a thick short trunk from the hump into the skull
	var neck := lathe_mesh("ember_boar_neck_v1", PackedVector2Array([Vector2(0.40, 0.0), Vector2(0.42, 0.14),
		Vector2(0.38, 0.30), Vector2(0.31, 0.42)]), 12, false)
	var nf := frame(Vector3(0, 0.98, 0.40), Vector3(0, 0.15, 1.0), Vector3.UP)
	sculpt_add(s, neck, Transform3D(Basis(nf.basis.x * 0.9, nf.basis.y, nf.basis.z * 0.78), nf.origin), hide)
	# ---- skull (a wedge sloping down to the snout), jaw, jowls, snout disc, nostrils
	var prof := PackedVector2Array()
	for i: int in SK_S.size():
		prof.append(Vector2(SK_R[i], SK_S[i]))
	var sf := frame(SK_B, sd, Vector3.UP)
	sculpt_add(s, lathe_mesh("ember_boar_skull_v1", prof, 12), Transform3D(Basis(sf.basis.x * SK_X, sf.basis.y, sf.basis.z),
		SK_B), hide)
	sculpt_add(s, sphere(0.18, 10, 5), Transform3D(Basis(sf.basis.x * 0.95, sf.basis.y * 1.5, sf.basis.z * 0.6),
		SK_B + sd * 0.50 - up * 0.14), hide)
	var snout := SK_B + sd * 0.80
	sculpt_add(s, cyl(0.165, 0.17, 0.07, 12), Transform3D(Basis(Quaternion(Vector3.UP, sd)), snout), hair)
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, sphere(0.04, 6, 3), dark, snout + sd * 0.035 + up * 0.02 + Vector3(0.065 * sx, 0, 0), Vector3.ZERO,
			Vector3(1.0, 1.2, 0.5))
		sculpt_put(s, sphere(0.16, 8, 4), hide, SK_B + sd * 0.30 - up * 0.07 + Vector3(0.20 * sx, 0, 0), Vector3.ZERO,
			Vector3(0.75, 0.95, 1.25))
		# eyes: a dark socket, a slanted ember slit, an angry brow ridge (inner end low)
		var eye := SK_B + sd * 0.24 + up * 0.10 + Vector3(0.245 * sx, 0, 0)
		var eb := Basis(Vector3.UP, 0.42 * sx) * Basis(Vector3.BACK, -0.45 * sx)
		# (the socket, the ember slit and the brow bump: the CreatureFaceRig eyes, faces pass 2026-09-28)
		# ears: pointed, laid back, a dark bristle tuft on the tip
		var ear := SK_B + up * 0.25 + Vector3(0.18 * sx, 0, 0) - sd * 0.03
		var ed := Vector3(0.6 * sx, 0.85, -0.55).normalized()
		sculpt_add(s, cyl(0.0, 0.085, 0.22, 5), Transform3D(Basis(Quaternion(Vector3.UP, ed)).scaled_local(Vector3(1.0, 1.0,
			0.5)), ear + ed * 0.10), hide)
		sculpt_lock(s, hair, ear + ed * 0.19, Vector3(0.3 * sx, 1.0, -0.8).normalized(), Vector3(sx, 0, 0), 0.08, 0.12, 0.04)
		# tusks: ivory, curling out, up and back
		sculpt_add(s, tube_mesh("ember_boar_tusk_%s_v1" % sx, _tusk_pts(sx), PackedFloat32Array([0.052, 0.044, 0.032, 0.0]),
			7), Transform3D.IDENTITY, tusk)
	# chin bristles
	for i: int in 3:
		var x: float = -0.09 + 0.09 * float(i)
		sculpt_lock(s, hair, SK_B + sd * 0.40 - up * 0.26 + Vector3(x, 0, 0), Vector3(x, -1.0, -0.25).normalized(),
			Vector3(0, -0.3, 1).normalized(), 0.12, 0.16, 0.045)
	# ---- head mane: bristles down the neck sides, flame tongues from the brow back over the neck
	for i: int in 6:
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		var t: float = floorf(float(i) * 0.5) / 2.0
		var root := Vector3(0.10 * sx, lerpf(1.31, 1.25, t), lerpf(0.62, 0.86, t))
		var nn := Vector3(0.8 * sx, 0.5, 0.1).normalized()
		sculpt_lock(s, hair, root, (nn * 0.6 + Vector3.DOWN).normalized(), nn, 0.19, lerpf(0.30, 0.20, t), 0.06)
	_flame(s, Vector3(0, 1.30, 0.64), Vector3(-0.08, 1.0, -0.5), 0.29, 0.60)
	_flame(s, Vector3(0, 1.29, 0.77), Vector3(0.08, 1.0, -0.5), 0.26, 0.50)
	_flame(s, Vector3(0, 1.25, 0.89), Vector3(0.0, 1.0, -0.6), 0.19, 0.30)


# ================================================================ legs + tail

## A short thick leg rooted at the pivot p (model space): hide upper leg, knee / hock, dark bristled sock, split hoof.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var hide := m("ember_boar_hide")
	var hair := m("fire_hair")
	var hoof := m("unit_eye_dark")
	var front: bool = p.z > 0.0
	# G-C: one continuous jointed leg in two bands (hide, then the dark bristled sock): a heavy forearm into a knobbly
	# knee; hind: the ham, a gaskin sloping back to the hock point, a short cannon leaning forward to the hoof.
	var bands: Array[Material] = [hide, hair]
	if front:
		MountShapes.leg_bands(s, "ember_boar_fleg_v2", p, FORE_ROWS, [4], bands, 1.0, 0.86, 7)
		MountShapes.muscle(s, hide, Vector3(p.x, 0.66, p.z - 0.04), Vector3(0.14, 0.15, 0.15), Vector3(0, 1, 0.2), 6, 3)
	else:
		sculpt_put(s, sphere(0.20, 10, 5), hide, Vector3(p.x, 0.74, p.z - 0.02), Vector3.ZERO, Vector3(0.75, 1.05, 1.05))
		MountShapes.leg_bands(s, "ember_boar_bleg_v2", p, HIND_ROWS, [4], bands, 1.0, 0.86, 7)
	# bristle cuff over the sock, then the split hoof (two dark toes)
	var cz: float = 0.035 if front else -0.03
	sculpt_fringe(s, hair, fringe_mesh("ember_boar_cuff_v1", 0.10, 0.10, 0.125, 0.125, 0.08, 0.0, 360.0, 6, 0.06, 0.02),
		Vector3(p.x, 0.40 if front else 0.37, p.z + cz))
	var tz: float = 0.05 if front else 0.03
	# hind hooves 1.1 cm higher (2026-09-28): the idle pose sank their soles ~1 cm under the ground (test 13.v2)
	var hy: float = 0.045 if front else 0.056
	for k: int in 2:
		var dx: float = -0.042 if k == 0 else 0.042
		sculpt_put(s, sphere(0.062, 6, 3), hoof, Vector3(p.x + dx, hy, p.z + tz + 0.03), Vector3(0, dx * 180.0, 0),
			Vector3(0.75, 0.75, 1.35))


func _tail_sculpt(s: Dictionary) -> void:
	var hide := m("ember_boar_hide")
	var hair := m("fire_hair")
	var tp := PackedVector3Array([Vector3(0, 1.01, -0.90), Vector3(0, 0.96, -0.99), Vector3(0, 0.84, -1.03),
		Vector3(0, 0.72, -1.03)])
	sculpt_add(s, tube_mesh("ember_boar_tail_v1", tp, PackedFloat32Array([0.045, 0.036, 0.028, 0.02]), 6), Transform3D.IDENTITY,
		hide)
	for i: int in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		var out := Vector3(sin(a), 0.0, cos(a) * 0.6 - 0.3).normalized()
		sculpt_lock(s, hair, tp[3] + Vector3(0, 0.03, 0) + out * 0.015, (out * 0.25 + Vector3.DOWN).normalized(), out, 0.08,
			0.16, 0.035)
	sculpt_put(s, sphere(0.035, 6, 3), m("ember_boar_flame_core"), tp[3] + Vector3(0, -0.02, 0))


# ================================================================ barding (bronze)

func _body_barding(s: Dictionary) -> void:
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	var cloth := m("fire_cloth")
	for sx: float in [-1.0, 1.0]:
		# shoulder: three articulated lames overlapping backward (each rear one outermost), leather lower rims, rivets,
		# a team flame sigil on the middle lame
		var sh: Array = [[0.44, 0.68, 0.055], [0.30, 0.50, 0.067], [0.16, 0.36, 0.079]]
		for li: int in sh.size():
			var ln: Array = sh[li]
			_lame(s, "ember_boar_sh_%s_%d_v2" % [sx, li], ln[0], ln[1], 58.0, 110.0, ln[2], sx, bronze, leather)
		var e := _bp(0.43, 84.0 * sx, 0.067 + 0.034)
		_sigil(s, e[0], e[1], 0.24, 0.27, cloth)
		# haunch: two lames over the hindquarters and a bronze boss
		var hq: Array = [[-0.70, -0.46, 0.07], [-0.90, -0.66, 0.082]]
		for li: int in hq.size():
			var ln: Array = hq[li]
			_lame(s, "ember_boar_hq_%s_%d_v2" % [sx, li], ln[0], ln[1], 70.0, 112.0, ln[2], sx, bronze, leather)
		var hb := _bp(-0.60, 88.0 * sx, 0.07 + 0.03)
		sculpt_put(s, sphere(0.045, 8, 4), bronze, hb[0])


## One bronze lame on the barrel side sx between model z0..z1 and angles a0..a1 (deg), `off` above the hide: the plate
## (tapered with the barrel), a leather rim along its lower edge and a rivet at its top.
static func _lame(s: Dictionary, key: String, z0: float, z1: float, a0: float, a1: float, off: float, sx: float,
		bronze: Material, leather: Material) -> void:
	var at := Transform3D(Basis.IDENTITY, BC)
	var l0: float = z0 - BC.z
	var l1: float = z1 - BC.z
	var rx0: float = _barrel_r(l0) * LX + off
	var ry0: float = _barrel_r(l0) * SY + off
	var tap: float = (_barrel_r(l1) * LX + off) / rx0
	sculpt_add(s, shell_mesh(key, rx0, ry0, minf(a0 * sx, a1 * sx), maxf(a0 * sx, a1 * sx), l0, l1, 0.03, 4, 1, tap, 0.0),
		at, bronze)
	var e0: float = (a1 - 5.0) * sx
	var e1: float = (a1 + 1.0) * sx
	sculpt_add(s, shell_mesh(key + "_rim", rx0 + 0.012, ry0 + 0.012, minf(e0, e1), maxf(e0, e1), l0 - 0.005, l1 + 0.005, 0.045,
		1, 1, tap, 0.0), at, leather)
	var r := _bp(lerpf(z0, z1, 0.5), (a0 + 5.0) * sx, off + 0.03)
	sculpt_put(s, sphere(0.026, 5, 2), leather, r[0])


## A flame sigil lying flat on a surface (point p, normal n): the mane's flame shape, curling backward.
static func _sigil(s: Dictionary, p: Vector3, n: Vector3, w: float, h: float, mat: Material) -> void:
	var up := (Vector3.UP - n * n.dot(Vector3.UP)).normalized()
	var back := up.cross(n).normalized()
	if back.z > 0.0:
		back = -back
	var xa := n * 0.08
	if xa.cross(up).dot(back) < 0.0:
		xa = -xa   # keep a right-handed basis (the thin axis is symmetric)
	sculpt_add(s, flame_mesh(), Transform3D(Basis(xa, up * h, back * w), p - up * h * 0.45), mat)

func _head_barding(s: Dictionary) -> void:
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var sf := frame(SK_B, sd, Vector3.UP)
	# shell z along the skull axis, shell y = up, shell x = lateral
	var hb := Basis(-sf.basis.x, sf.basis.z, sf.basis.y)
	var at := Transform3D(hb, SK_B)
	sculpt_add(s, shell_mesh("ember_boar_chanfron_v1", 0.327, 0.375, -52.0, 52.0, 0.10, 0.68, 0.03, 6, 3, 0.56, 0.03), at, bronze)
	sculpt_add(s, shell_mesh("ember_boar_chanfron_rim_v1", 0.335, 0.385, -54.0, 54.0, 0.08, 0.13, 0.035, 6, 1), at, leather)
	# head strap behind the ears
	sculpt_add(s, shell_mesh("ember_boar_headstrap_v1", 0.265, 0.31, -180.0, 180.0, 0.0, 0.05, 0.02, 12, 1), at, leather)
	# central ridge and a forehead spike
	var rp := PackedVector3Array()
	var rr := PackedFloat32Array()
	for i: int in 4:
		var sv: float = lerpf(0.14, 0.62, float(i) / 3.0)
		var rad: float = lerpf(0.34, 0.19, (sv - 0.10) / 0.58) + 0.045
		rp.append(SK_B + sd * sv + up * rad)
		rr.append(lerpf(0.035, 0.018, float(i) / 3.0))
	sculpt_add(s, tube_mesh("ember_boar_ridge_v1", rp, rr, 5, true, 0.6), Transform3D.IDENTITY, bronze)
	var sp := (up + sd * 0.9).normalized()
	sculpt_add(s, cyl(0.0, 0.06, 0.22, 6), Transform3D(Basis(Quaternion(Vector3.UP, sp)), SK_B + sd * 0.20 + up * 0.38 + sp * 0.08),
		bronze)
	for sx: float in [-1.0, 1.0]:
		for k: int in 2:
			var sv: float = 0.22 + 0.26 * float(k)
			var rad: float = lerpf(0.34, 0.19, (sv - 0.10) / 0.58)
			var a := deg_to_rad(48.0)
			sculpt_put(s, sphere(0.022, 5, 2), leather, SK_B + sd * sv + up * (rad * cos(a) + 0.04)
				+ Vector3(sx * (rad * SK_X * sin(a) + 0.03), 0, 0))
		# bronze tusk ring and cap
		var tp := _tusk_pts(sx)
		var t1 := (tp[2] - tp[0]).normalized()
		sculpt_add(s, torus(0.035, 0.062, 10), Transform3D(Basis(Quaternion(Vector3.UP, t1)), tp[1]), bronze)
		var t3 := (tp[3] - tp[2]).normalized()
		sculpt_add(s, cyl(0.0, 0.036, 0.11, 6), Transform3D(Basis(Quaternion(Vector3.UP, t3)), tp[3] - t3 * 0.035), bronze)


func _knee_barding(s: Dictionary, p: Vector3) -> void:
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	sculpt_put(s, sphere(0.12, 10, 5), bronze, Vector3(p.x, 0.40, p.z + 0.11), Vector3(-10, 0, 0), Vector3(1.1, 1.3, 0.55))
	sculpt_add(s, cyl(0.135, 0.135, 0.045, 10, false), Transform3D(Basis.IDENTITY, Vector3(p.x, 0.52, p.z + 0.02)), leather)


# ================================================================ motion (on top of MountModel)

func _mount_ready() -> void:
	_smoulder_v = 0.0
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))


## Root and toss: the nose drops to the ground and snuffles side to side, then a head toss that flares the mane,
## a snort, a quick warthog tail wiggle.
func _pose_fidget(t: float) -> float:
	var root_k := _k3(t, 0.0, 0.35, 1.1, 1.35, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3((26.0 + 5.0 * sin(t * TAU * 4.0)) * DEG * root_k, 10.0 * DEG * sin(t * TAU * 1.4) * root_k, 0))
	rot(P_MOUNT, Vector3(4.0 * DEG * root_k, 0, 0))
	pos(P_ROOT, Vector3(0, -0.02 * root_k, 0))
	var toss := _k3(t, 1.25, 1.42, 1.58, 1.95, 1.0, 0.6)
	rot(P_MOUNT_HEAD, Vector3(-22.0 * DEG * toss, 0, 12.0 * DEG * sin(t * TAU * 3.0) * toss))
	var wig := _k3(t, 1.3, 1.4, 1.8, 2.0, 1.0, 1.0)
	xrot(X_TAIL, Vector3(40.0 * DEG * wig, 30.0 * DEG * sin(t * TAU * 7.0) * wig, 0))
	if _fidget_prev < 1.42 and t >= 1.42:
		_flare = maxf(_flare, 0.8)
		_on_mount_event(&"fidget_snort")
	return 2.0


## Death: the hide smoulders (an ember glow rising as it goes down, then dying away).
func _mount_process(_dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if not _dead:
		return
	var v: float = snappedf(0.17 * smoothstep(0.1, 0.45, _death_t) * (1.0 - 0.85 * smoothstep(0.55, 1.0, _death_t)), 0.01)
	if v == _smoulder_v:
		return
	_smoulder_v = v
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", EMBER)


func _mount_revive() -> void:
	if _face:
		_face.reset()
	_smoulder_v = 0.0
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"hit_flash", 0.0)
		gi.set_instance_shader_parameter(&"flash_color", WHITE)


## The eyes (faces pass 2026-09-28; the Fire / Ice pass skipped this mount): slanted glowing ember eyes (the old ember
## slits: the irises glow) under an angry dark brow ridge (fierce by default when attacking, inner end low). Drawn
## inside the merged head (CreatureFaceRig host mode: no extra draw instance).
static func face_spec() -> Dictionary:
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var eye := SK_B + sd * 0.24 + up * 0.10 + Vector3(0.245, 0, 0)
	return CreatureFaceRig.side_eye_spec(eye + Vector3(0.02, 0, 0), Vector3(0.90, 0.14, 0.42), 0.062, Color(0.25, 0.105, 0.068),
		Color(1.0, 0.62, 0.20), 0.85, {"eye": {"tilt": 0.010}, "palette": {"brow": Color(0.10, 0.04, 0.03)},
		"brow": {"w": Vector3(0.013, 0.015, 0.006)}, "x": {&"neutral": {"brow": [-0.008, -0.002, 0.004]}}, "lift": 0.03})


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)
