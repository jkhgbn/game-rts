extends MountModel
## Rimehorn (cavalry-mounts.md 6.1 / 10, task 13.V4): the Ice mount (Rimehorn Rider 13.V8, Torvald riding 13.V11).
## A woolly war rhino, 2.9 m long: a low heavy barrel on stubby pillar legs with shaggy fur boots, a towering shaggy
## shoulder hump in front of the saddle, and ONE huge horn (1.3 m) sweeping forward and up from the muzzle, plated in
## ice that ends in a luminous crystal point = the read at 40 m. Frost grows on its back: pale rimed wool and ice
## crystals on the hump crest and the rump. Team saddle-cloth (ice_cloth) with a dark hem and a snowflake emblem,
## leather saddle, steel stirrups. Barding (set_barded): silver-blue plates (ice_metal) on the hump, flanks, chest,
## a chanfron + cheek plates on the head (the horn stays bare) and knee cops, steel rivets, ice studs.
## Glow points: the horn tip (ice_glow_unit) and the glowing eyes (CreatureFaceRig irises, faces pass 2026-09-28).
## Motion: heavy 4-beat walk, a thundering gallop from 3.4 m/s (head low: the horn leads), a "frost shake" fidget,
## generic charge (horn levelled, lunge, gore toss) and hit; death: stumbles, rolls onto its side and frosts over.
## Budget (section 10 mount): 12 authored meshes incl. the blob (7 sculpts + 4 barding sculpts + blob), 8 draw
## instances (Body, Head, 4 legs, Tail, blob), 0 lights, 0 particle systems.

const OWN := "res://art/units/mounts/rimehorn/materials/"
const ICE := "res://art/units/ice/materials/"
const BLOB_TINT := Color(0.03, 0.05, 0.11, 0.5)
const FROST := Vector3(0.40, 0.72, 1.0)

## Barrel (body) of revolution along z, centred on BC, vertical squash SY. Profile [z offset, radius].
const BC := Vector3(0, 0.88, -0.05)
const SY := 0.84
const BARREL_Z: Array[float] = [-1.00, -0.97, -0.86, -0.66, -0.32, 0.05, 0.40, 0.66, 0.86, 0.94]
const BARREL_R: Array[float] = [0.00, 0.26, 0.42, 0.53, 0.575, 0.585, 0.565, 0.50, 0.36, 0.00]
## Shoulder hump ellipsoid (centre, radii) and rump ellipsoid.
const HUMP_C := Vector3(0, 1.26, 0.46)
const HUMP_R := Vector3(0.504, 0.378, 0.525)
const RUMP_C := Vector3(0, 1.06, -0.62)
const RUMP_R := Vector3(0.50, 0.32, 0.46)
## Skull: axis from SK_B (back of the skull) along SK_D; lathe profile [s along the axis, radius], lateral squash.
const SK_B := Vector3(0, 0.98, 0.92)
const SK_F := Vector3(0, 0.60, 1.60)
const SK_S: Array[float] = [-0.02, 0.0, 0.10, 0.26, 0.44, 0.60, 0.70, 0.77, 0.80]
const SK_R: Array[float] = [0.0, 0.30, 0.35, 0.345, 0.30, 0.25, 0.225, 0.19, 0.0]
const SK_X := 0.82
## The horn (core points and radii); the last point is the glowing tip.
## It sweeps FORWARD like a couched lance, then curls up at the tip: from the 55 deg game camera a vertical horn
## foreshortens into the head, a forward one reads.
const HORN_P: Array[Vector3] = [Vector3(0, 0.84, 1.54), Vector3(0, 0.95, 1.77), Vector3(0, 1.08, 1.99),
	Vector3(0, 1.25, 2.18), Vector3(0, 1.45, 2.31), Vector3(0, 1.67, 2.37)]
const HORN_R: Array[float] = [0.19, 0.16, 0.125, 0.09, 0.058, 0.0]

var _frost_v: float = 0.0
## Eyes + expression (CreatureFaceRig, faces pass 2026-09-28).
var _face: CreatureFaceRig


func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	_face = CreatureFaceRig.attach(self, head, "rimehorn", face_spec())
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	add_sculpt($Root/Mount/Tail, _tail_sculpt)
	# Barding: plates merged into barded variants of Body, Head and the two front legs.
	add_barding_sculpt(body, _body_barding)
	add_barding_sculpt(head, _head_barding)
	for leg: Node3D in [legs[0], legs[1]]:
		var p := model_origin(leg)
		add_barding_sculpt(leg, func(s: Dictionary) -> void: _knee_barding(s, p))
	ensure_shadow_blob(0.7, BLOB_TINT)
	_shadow.scale = Vector3(2.3, 1.0, 4.2)
	_shadow.position = Vector3(0, 0.02, 0.1)


static func m(name: String) -> Material:
	return material_at((OWN if name.begins_with("rimehorn") else ICE) + name + ".tres")


# ================================================================ body

## Barrel radius at a z offset from BC (linear in the profile).
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


## [point, outward normal] on an ellipsoid (centre c, radii r) at azimuth theta (deg from +z toward +x) and
## elevation phi (deg).
static func _ell_pt(c: Vector3, r: Vector3, theta_deg: float, phi_deg: float) -> Array:
	var th := deg_to_rad(theta_deg)
	var ph := deg_to_rad(phi_deg)
	var u := Vector3(cos(ph) * sin(th), sin(ph), cos(ph) * cos(th))
	return [c + u * r, (u / r).normalized()]


func _body_sculpt(s: Dictionary) -> void:
	var hide := m("rimehorn_hide")
	var wool := m("rimehorn_wool")
	var pale := m("ice_fur_pale")
	var ice := m("ice_frost_crystal")
	var cloth := m("ice_cloth")
	var cdark := m("ice_cloth_dark")
	var leather := m("ice_leather")
	var steel := m("ice_steel")
	# ---- mass: barrel, shoulder hump, rump
	var prof := PackedVector2Array()
	for i: int in BARREL_Z.size():
		prof.append(Vector2(BARREL_R[i], BARREL_Z[i]))
	var barrel := lathe_mesh("rimehorn_barrel_v1", prof, 12)
	sculpt_add(s, barrel, Transform3D(Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(1, 1, SY)), BC), hide)
	sculpt_put(s, sphere(0.42, 12, 6), hide, HUMP_C, Vector3.ZERO, HUMP_R / 0.42)
	sculpt_put(s, sphere(0.40, 10, 5), hide, RUMP_C, Vector3.ZERO, RUMP_R / 0.40)
	# ---- shaggy wool: a rimed frost cap and a flaring wool cape over the shoulder hump (open behind, where the rider
	# sits), a toothed skirt of long fur all around the belly, a chest beard
	sculpt_fringe(s, pale, fringe_mesh("rimehorn_cap_v1", 0.13, 0.15, 0.46, 0.48, 0.18, -128.0, 128.0, 11, 0.10, 0.03),
		HUMP_C + Vector3(0, 0.37, 0.02))
	sculpt_fringe(s, wool, fringe_mesh("rimehorn_cape_v1", 0.44, 0.46, 0.62, 0.64, 0.30, -122.0, 122.0, 15, 0.14, 0.03),
		HUMP_C + Vector3(0, 0.20, 0.0))
	sculpt_fringe(s, wool, fringe_mesh("rimehorn_skirt_v2", 0.53, 0.93, 0.62, 1.01, 0.11, 0.0, 360.0, 26, 0.10, 0.03),
		Vector3(0, 0.72, -0.08))
	for i: int in 5:
		var x: float = -0.28 + 0.14 * float(i)
		var root := Vector3(x, 0.78 - absf(x) * 0.3, 0.82 - absf(x) * 0.25)
		sculpt_lock(s, wool, root, Vector3(x * 0.4, -1.0, 0.25).normalized(), Vector3(x, -0.2, 1.0).normalized(),
			0.24, 0.44 - absf(x) * 0.25, 0.08)
	# rump: rimed patch, locks over the thighs, a short frost fringe over the tail root
	sculpt_put(s, sphere(0.30, 10, 5), pale, RUMP_C + Vector3(0, 0.27, -0.04), Vector3(-6, 0, 0), Vector3(1.25, 0.36, 1.15))
	for i: int in 6:
		var th: float = 180.0 + (float(i) - 2.5) * 26.0
		var e := _ell_pt(RUMP_C, RUMP_R, th, 26.0)
		var nn: Vector3 = e[1]
		sculpt_lock(s, pale if i == 2 or i == 3 else wool, (e[0] as Vector3) - nn * 0.04,
			(nn * 0.5 + Vector3.DOWN).normalized(), nn, 0.22, 0.30, 0.07)
	# ---- frost on the back: ice crystals growing out of the hump crest (leaning forward, clear of the rider) and the
	# rump (leaning back)
	var hump_top := HUMP_C + Vector3(0, HUMP_R.y, 0)
	var hc: Array = [[Vector3(0.0, -0.03, 0.10), Vector3(0.0, 1.0, 0.55), 0.080, 0.46],
		[Vector3(0.15, -0.06, 0.02), Vector3(0.45, 1.0, 0.35), 0.068, 0.34],
		[Vector3(-0.15, -0.06, 0.04), Vector3(-0.45, 1.0, 0.40), 0.068, 0.36],
		[Vector3(0.08, -0.08, 0.26), Vector3(0.25, 0.8, 0.9), 0.060, 0.26],
		[Vector3(-0.09, -0.09, 0.24), Vector3(-0.3, 0.8, 0.9), 0.058, 0.24]]
	for c: Array in hc:
		sculpt_crystal(s, ice, hump_top + (c[0] as Vector3), c[1], c[2], c[3], 0.45, 12.0)
	var rump_top := RUMP_C + Vector3(0, RUMP_R.y - 0.02, -0.06)
	var rc: Array = [[Vector3(0.0, 0.0, -0.10), Vector3(0.0, 1.0, -0.7), 0.066, 0.30],
		[Vector3(0.16, -0.04, 0.02), Vector3(0.5, 1.0, -0.5), 0.056, 0.22],
		[Vector3(-0.16, -0.04, 0.0), Vector3(-0.5, 1.0, -0.5), 0.056, 0.24]]
	for c: Array in rc:
		sculpt_crystal(s, ice, rump_top + (c[0] as Vector3), c[1], c[2], c[3], 0.5, 20.0)
	# ---- team saddle-cloth: a blanket draped over the back from the hump to the rump, hem, snowflake emblems
	var at := Transform3D(Basis.IDENTITY, BC)
	sculpt_add(s, shell_mesh("rimehorn_cloth_v1", 0.615, 0.54, -122.0, 122.0, -0.52, 0.13, 0.03, 14, 3, 1.0, 0.02),
		at, cloth)
	for sx: float in [-1.0, 1.0]:
		var a0: float = 112.0 * sx
		var a1: float = 124.0 * sx
		sculpt_add(s, shell_mesh("rimehorn_hem_%s" % sx, 0.625, 0.55, minf(a0, a1), maxf(a0, a1), -0.53, 0.14, 0.035, 2,
			3, 1.0, 0.02), at, cdark)
		var e := _barrel_pt(-0.21, 96.0 * sx)
		var nn: Vector3 = e[1]
		var ep: Vector3 = (e[0] as Vector3) + nn * 0.045
		var eb := frame(ep, Vector3.UP, nn).basis
		# emblem: a dark diamond with a pale-team 6-point snowflake (cloth) on it
		sculpt_add(s, box(Vector3(0.26, 0.26, 0.02)), Transform3D(eb * Basis(Vector3.BACK, PI * 0.25), ep), cdark)
		for k: int in 3:
			sculpt_add(s, box(Vector3(0.035, 0.24, 0.02)), Transform3D(eb * Basis(Vector3.BACK, PI / 3.0 * float(k)),
				ep + nn * 0.012), cloth)
	sculpt_add(s, shell_mesh("rimehorn_hemback_v1", 0.63, 0.555, -124.0, 124.0, -0.56, -0.50, 0.035, 14, 1), at, cdark)
	# ---- saddle: seat, cantle, pommel, side skirts, girth strap, stirrups
	sculpt_put(s, box(Vector3(0.46, 0.08, 0.50)), leather, Vector3(0, 1.445, -0.21), Vector3(-3, 0, 0))
	sculpt_put(s, sphere(0.25, 10, 4), leather, Vector3(0, 1.47, -0.22), Vector3.ZERO, Vector3(0.9, 0.18, 1.0))
	sculpt_add(s, shell_mesh("rimehorn_cantle_v1", 0.21, 0.13, -84.0, 84.0, -0.035, 0.035, 0.06, 6, 1),
		Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-15.0)), Vector3(0, 1.43, -0.44)), leather)
	sculpt_put(s, cyl(0.045, 0.07, 0.16, 8), steel, Vector3(0, 1.56, 0.03), Vector3(10, 0, 0))
	sculpt_put(s, sphere(0.065, 8, 4), steel, Vector3(0, 1.645, 0.045))
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, box(Vector3(0.04, 0.22, 0.32)), leather, Vector3(0.58 * sx, 1.32, -0.21), Vector3(0, 0, -22.0 * sx))
		sculpt_put(s, box(Vector3(0.04, 0.36, 0.06)), leather, Vector3(0.67 * sx, 1.02, -0.13), Vector3(0, 0, -6.0 * sx))
		sculpt_put(s, torus(0.035, 0.085, 10), steel, Vector3(0.69 * sx, 0.80, -0.13), Vector3(0, 0, 90))
		sculpt_put(s, box(Vector3(0.05, 0.03, 0.13)), steel, Vector3(0.69 * sx, 0.73, -0.13))
	sculpt_add(s, shell_mesh("rimehorn_girth_v1", 0.63, 0.555, -180.0, 180.0, 0.14, 0.24, 0.025, 14, 1), at, leather)


# ================================================================ head (neck, skull, horn)

func _head_sculpt(s: Dictionary) -> void:
	var hide := m("rimehorn_hide")
	var wool := m("rimehorn_wool")
	var pale := m("ice_fur_pale")
	var ice := m("ice_frost_crystal")
	var horn := m("ice_stone")
	var dark := m("ice_fur")
	var glow := m("ice_glow_unit")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)          # perpendicular to the skull axis, pointing up
	# ---- neck: a thick short trunk from the hump front into the skull
	var neck := lathe_mesh("rimehorn_neck_v1", PackedVector2Array([Vector2(0.40, 0.0), Vector2(0.44, 0.14),
		Vector2(0.40, 0.34), Vector2(0.33, 0.50)]), 12, false)
	var nf := frame(Vector3(0, 1.02, 0.52), Vector3(0, -0.28, 1.0), Vector3.UP)
	sculpt_add(s, neck, Transform3D(Basis(nf.basis.x * 0.92, nf.basis.y, nf.basis.z), nf.origin), hide)
	# ---- skull (a long heavy wedge pointing down-forward), lips, nostrils, brows, eye slits, ears
	var prof := PackedVector2Array()
	for i: int in SK_S.size():
		prof.append(Vector2(SK_R[i], SK_S[i]))
	var skull := lathe_mesh("rimehorn_skull_v1", prof, 12)
	var sf := frame(SK_B, sd, Vector3.UP)
	sculpt_add(s, skull, Transform3D(Basis(sf.basis.x * SK_X, sf.basis.y, sf.basis.z), SK_B), hide)
	var lip := SK_B + sd * 0.70 - up * 0.07
	sculpt_add(s, sphere(0.20, 10, 5), Transform3D(Basis(sf.basis.x * 1.2, sf.basis.y * 0.62, sf.basis.z * 0.72), lip), hide)
	for sx: float in [-1.0, 1.0]:
		var nos := SK_B + sd * 0.78 + up * 0.02 + Vector3(0.085 * sx, 0, 0)
		sculpt_put(s, sphere(0.05, 6, 3), dark, nos, Vector3.ZERO, Vector3(1.0, 0.7, 0.6))
		# (the eyes, their glow and the brow ridges are the CreatureFaceRig: faces pass 2026-09-28; the old dark eye
		# lumps, glowing slit boxes and 3D brow bumps are gone)
		# ears: small leaf cones with a wool tip
		var ear := SK_B + up * 0.26 + Vector3(0.19 * sx, 0, -0.05)
		var ed := Vector3(0.55 * sx, 1.0, -0.45).normalized()
		sculpt_add(s, cyl(0.0, 0.075, 0.20, 6), Transform3D(Basis(Quaternion(Vector3.UP, ed)).scaled_local(Vector3(1.0,
			1.0, 0.55)), ear + ed * 0.09), hide)
		sculpt_lock(s, wool, ear + ed * 0.16, Vector3(0.4 * sx, 1.0, -0.6).normalized(), Vector3(sx, 0, 0), 0.12, 0.14, 0.05)
	# ---- wool: a shaggy mane over the top of the neck and cheeks, a beard under the jaw
	for i: int in 9:
		var t: float = float(i) / 8.0
		var sx: float = -1.0 if i % 2 == 0 else 1.0
		var root := Vector3(0.10 * sx, lerpf(1.40, 1.20, t), lerpf(0.66, 1.00, t))
		var nn := Vector3(0.75 * sx, 0.6, 0.15).normalized()
		sculpt_lock(s, pale if i < 2 else wool, root, (nn * 0.5 + Vector3.DOWN).normalized(), nn, 0.22,
			lerpf(0.40, 0.26, t), 0.07)
	for sx: float in [-1.0, 1.0]:
		for k: int in 1:
			var root := SK_B + sd * (0.18 + 0.12 * float(k)) - up * 0.18 + Vector3(0.24 * sx, 0, 0)
			sculpt_lock(s, wool, root, Vector3(0.3 * sx, -1.0, -0.1).normalized(), Vector3(sx, -0.3, 0).normalized(), 0.18,
				0.24, 0.06)
	for i: int in 3:
		var x: float = -0.12 + 0.12 * float(i)
		sculpt_lock(s, wool, SK_B + sd * 0.36 - up * 0.26 + Vector3(x, 0, 0), Vector3(x, -1.0, -0.3).normalized(),
			Vector3(0, -0.4, 1).normalized(), 0.17, 0.26, 0.06)
	# ---- THE HORN: a pale horn root, a deep-ice core sheathed in overlapping crystal plates, a faceted ice tip with a
	# glowing point, frost spikes along its crest
	var deep := m("ice_frost_deep")
	var core_p := PackedVector3Array()
	var core_r := PackedFloat32Array()
	for i: int in 5:
		core_p.append(HORN_P[i])
		core_r.append(HORN_R[i])
	sculpt_add(s, tube_mesh("rimehorn_horn_v2", core_p, core_r, 8, true, 0.74), Transform3D.IDENTITY, deep)
	sculpt_put(s, sphere(0.23, 8, 4), hide, HORN_P[0] + Vector3(0, -0.02, -0.02), Vector3(-40, 0, 0), Vector3(0.80, 0.50, 1.0))
	sculpt_put(s, sphere(0.19, 6, 3), horn, HORN_P[0] + Vector3(0, 0.03, 0.04), Vector3(-50, 0, 0), Vector3(0.74, 0.55, 0.9))
	for i: int in [1, 2, 3]:
		var t := (HORN_P[i + 1] - HORN_P[i - 1]).normalized()
		var b := Basis(Quaternion(Vector3.UP, t)).scaled_local(Vector3(0.8, 1.0, 1.0))
		var r: float = HORN_R[i]
		var seg: float = (HORN_P[i + 1] - HORN_P[i]).length()
		# a crystal sheath plate covering most of the segment (wide at its root: the plates overlap like scales)
		sculpt_add(s, cyl(r * 0.98, r * 1.38, seg * 0.8, 6), Transform3D(b * Basis(Vector3.UP, 0.5 * float(i)),
			HORN_P[i] + t * seg * 0.32), deep if i == 1 else ice)
		var hu := (Vector3.UP - t * Vector3.UP.dot(t)).normalized()
		sculpt_crystal(s, ice, HORN_P[i] + hu * r * 0.9 + t * 0.03, (t * 0.6 + hu).normalized(), maxf(r * 0.45, 0.04),
			0.12 + r * 1.2, 0.55)
	var tip_d := (HORN_P[5] - HORN_P[3]).normalized()
	var tip_len: float = (HORN_P[5] - HORN_P[3]).length()
	sculpt_crystal(s, ice, HORN_P[3] + tip_d * 0.02, tip_d, 0.105, tip_len - 0.12, 0.42, 30.0)
	sculpt_add(s, cyl(0.0, 0.052, 0.20, 6), Transform3D(Basis(Quaternion(Vector3.UP, tip_d)), HORN_P[5] - tip_d * 0.10), glow)


# ================================================================ legs + tail

## A stubby pillar leg rooted at the pivot p (model space): thick upper leg into the body, knee, shaggy fur boot,
## a round dark sole pad with 3 toenails.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var hide := m("rimehorn_hide")
	var wool := m("rimehorn_wool")
	var dark := m("ice_fur")
	var nail := dark
	var front: bool = p.z > 0.0
	var x := p.x
	var z := p.z
	sculpt_add(s, tube_mesh("rimehorn_leg_upper_v2", PackedVector3Array([Vector3(0, 0.86, 0), Vector3(0, 0.62, 0.01),
		Vector3(0, 0.44, 0.03)]), PackedFloat32Array([0.21, 0.20, 0.17]), 6, false), Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), hide)
	sculpt_add(s, tube_mesh("rimehorn_leg_lower_v2", PackedVector3Array([Vector3(0, 0.46, 0.03), Vector3(0.01, 0.26, 0.035),
		Vector3(0, 0.08, 0.05)]), PackedFloat32Array([0.165, 0.148, 0.165]), 8, false), Transform3D(Basis.IDENTITY, Vector3(x, 0, z)), hide)
	sculpt_put(s, sphere(0.15, 6, 3), hide, Vector3(x, 0.44 if front else 0.46, z + (0.06 if front else -0.03)),
		Vector3.ZERO, Vector3(1.0, 0.9, 1.0))
	# fur boot: a toothed fringe around the lower leg (fronts longer)
	var boot := fringe_mesh("rimehorn_boot_f_v1" if front else "rimehorn_boot_b_v1", 0.16, 0.16, 0.215, 0.215,
		0.18 if front else 0.15, 0.0, 360.0, 7, 0.09, 0.025)
	sculpt_fringe(s, wool, boot, Vector3(x, 0.42 if front else 0.38, z + 0.035))
	# sole pad + 3 toenails (forward)
	sculpt_put(s, sphere(0.17, 8, 3), dark, Vector3(x, 0.066, z + 0.05), Vector3.ZERO, Vector3(1.0, 0.36, 1.08))
	for k: int in 3:
		var dx: float = (float(k) - 1.0) * 0.095
		sculpt_put(s, sphere(0.068, 6, 3), nail, Vector3(x + dx, 0.055, z + 0.19 - absf(dx) * 0.5),
			Vector3(0, dx * 150.0, 0), Vector3(1.0, 0.8, 1.15))


func _tail_sculpt(s: Dictionary) -> void:
	var hide := m("rimehorn_hide")
	var wool := m("rimehorn_wool")
	var pale := m("ice_fur_pale")
	var tp := PackedVector3Array([Vector3(0, 1.13, -1.00), Vector3(0, 1.03, -1.13), Vector3(0, 0.86, -1.19)])
	sculpt_add(s, tube_mesh("rimehorn_tail_v1", tp, PackedFloat32Array([0.08, 0.06, 0.045]), 6), Transform3D.IDENTITY, hide)
	for i: int in 5:
		var a := TAU * float(i) / 5.0
		var out := Vector3(sin(a), 0.0, cos(a) * 0.6 - 0.4).normalized()
		sculpt_lock(s, pale if i == 0 else wool, tp[2] + Vector3(0, 0.04, 0) + out * 0.03, (out * 0.3 + Vector3.DOWN).normalized(),
			out, 0.13, 0.26, 0.05)


# ================================================================ barding (silver-blue plates)

func _body_barding(s: Dictionary) -> void:
	var plate := m("ice_metal")
	var steel := m("ice_steel")
	var ice := m("ice_frost_crystal")
	var at := Transform3D(Basis.IDENTITY, BC)
	# flank lamellar: 2 rows x (front, rear) per side, leaving the team saddle-cloth free in the middle
	var segs: Array = [[0.20, 0.64, 0.90], [-0.92, -0.56, 1.3]]   # [l0, l1 (model z), taper]
	for sx: float in [-1.0, 1.0]:
		for seg: Array in segs:
			var l0: float = float(seg[0]) - BC.z
			var l1: float = float(seg[1]) - BC.z
			var base: float = 0.66 if float(seg[2]) < 1.0 else 0.66 / float(seg[2])
			for row: int in 2:
				var a0: float = 50.0 if row == 0 else 88.0
				var a1: float = 94.0 if row == 0 else 130.0
				var key := "rimehorn_lam_%s_%s_%d" % [sx, seg[0], row]
				var rr: float = base + 0.02 * float(row)
				sculpt_add(s, shell_mesh(key, rr, rr * 0.86, minf(a0 * sx, a1 * sx), maxf(a0 * sx, a1 * sx), l0, l1, 0.03, 4, 2,
					float(seg[2]), 0.04), at, plate)
				# a dark steel rim along the plate's lower edge (reads as segmented armour, not a pale blanket)
				var e0: float = (a1 - 7.0) * sx
				var e1: float = (a1 + 1.0) * sx
				sculpt_add(s, shell_mesh(key + "_rim", rr + 0.012, (rr + 0.012) * 0.86, minf(e0, e1), maxf(e0, e1), l0 - 0.01,
					l1 + 0.01, 0.045, 1, 2, float(seg[2]), 0.04), at, steel)
				# an ice stud in the middle of the upper row
				if row == 0:
					var e := _barrel_pt(BC.z + (l0 + l1) * 0.5, 75.0 * sx)
					sculpt_crystal(s, ice, (e[0] as Vector3) + (e[1] as Vector3) * 0.07, e[1], 0.045, 0.14, 0.55)
	# chest guard wrapping under the throat
	sculpt_add(s, shell_mesh("rimehorn_peytral_v1", 0.63, 0.55, 100.0, 260.0, 0.48, 0.84, 0.035, 10, 2, 0.66, 0.05), at, plate)
	sculpt_add(s, shell_mesh("rimehorn_peytral_rim_v1", 0.645, 0.565, 100.0, 260.0, 0.46, 0.50, 0.04, 10, 1), at, steel)
	# hump guard: a big curved plate over the front of the hump (the frost crystals grow through its top edge)
	var hb := Basis(Vector3.UP, PI * 0.5)       # shell z -> model +x; angle 0 = up, negative = toward the front
	sculpt_add(s, shell_mesh("rimehorn_hump_plate_v1", 0.40, 0.31, -104.0, -30.0, -0.42, 0.42, 0.035, 6, 4, 1.0, 0.44),
		Transform3D(hb, HUMP_C), plate)
	sculpt_add(s, shell_mesh("rimehorn_hump_rim_v1", 0.405, 0.315, -34.0, -26.0, -0.40, 0.40, 0.04, 1, 4, 1.0, 0.44),
		Transform3D(hb, HUMP_C), steel)
	for sx: float in [-1.0, 1.0]:
		var e := _ell_pt(HUMP_C, HUMP_R, 40.0 * sx, 18.0)
		sculpt_crystal(s, ice, (e[0] as Vector3) + (e[1] as Vector3) * 0.07, (e[1] as Vector3) + Vector3(0, 0.3, 0), 0.05, 0.16, 0.55)


func _head_barding(s: Dictionary) -> void:
	var plate := m("ice_metal")
	var steel := m("ice_steel")
	var ice := m("ice_frost_crystal")
	var sd := (SK_F - SK_B).normalized()
	var sf := frame(SK_B, sd, Vector3.UP)
	# shell z along the skull axis, shell y = up, shell x = lateral (right-handed: -x)
	var hb := Basis(-sf.basis.x, sf.basis.z, sf.basis.y)
	var at := Transform3D(hb, SK_B)
	sculpt_add(s, shell_mesh("rimehorn_chanfron_v1", 0.31, 0.385, -62.0, 62.0, 0.06, 0.54, 0.03, 6, 2, 0.74, 0.03), at, plate)
	sculpt_add(s, shell_mesh("rimehorn_chanfron_rim_v1", 0.315, 0.39, -64.0, 64.0, 0.52, 0.56, 0.035, 6, 1, 0.74), at, steel)
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, shell_mesh("rimehorn_cheek_%s" % sx, 0.305, 0.375, minf(66.0 * sx, 112.0 * sx), maxf(66.0 * sx, 112.0 * sx),
			0.12, 0.40, 0.03, 3, 1, 0.86), at, plate)
		sculpt_put(s, sphere(0.03, 6, 3), steel, SK_B + sd * 0.14 + Vector3(0.30 * sx, 0.06, 0))
	var up := Vector3(0, sd.z, -sd.y)
	sculpt_crystal(s, ice, SK_B + sd * 0.16 + up * 0.36, (up + Vector3(0, 0, -0.5)).normalized(), 0.06, 0.24, 0.5)
	sculpt_put(s, sphere(0.045, 8, 4), steel, SK_B + sd * 0.40 + up * 0.30)


func _knee_barding(s: Dictionary, p: Vector3) -> void:
	var plate := m("ice_metal")
	var steel := m("ice_steel")
	sculpt_put(s, sphere(0.14, 10, 5), plate, Vector3(p.x, 0.47, p.z + 0.16), Vector3(-12, 0, 0), Vector3(1.25, 1.35, 0.55))
	sculpt_add(s, cyl(0.19, 0.19, 0.05, 10, false), Transform3D(Basis.IDENTITY, Vector3(p.x, 0.58, p.z + 0.02)), steel)


# ================================================================ motion (on top of MountModel)

func _mount_ready() -> void:
	_frost_v = 0.0
	if _face:
		_face.set_host(_merged_nodes.get(P_MOUNT_HEAD))


## The eyes (faces pass 2026-09-28): glowing ice-blue eyes under heavy grey brow ridges (the old eye slits were a glow
## point: the irises glow now), drawn inside the merged head mesh (CreatureFaceRig host mode: no extra draw instance).
static func face_spec() -> Dictionary:
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var eye := SK_B + sd * 0.27 + up * 0.10 + Vector3(0.262, 0, 0)
	return CreatureFaceRig.side_eye_spec(eye, Vector3(0.86, 0.10, 0.50), 0.060, Color(0.46, 0.51, 0.57),
		Color(0.55, 0.88, 1.0), 0.85)


## Cinematic / UI hook: FaceKit.EXPRESSIONS (the eyes and brows: neutral / smile / fierce / worried / shout).
func set_expression(id: StringName) -> void:
	if _face:
		_face.set_expression(id)


## The frost shake: a hard shiver runs through the body, the horn sweeps low side to side, a snort (eyes flare).
func _pose_fidget(t: float) -> float:
	var env := _k3(t, 0.0, 0.15, 0.75, 0.95, 1.0, 1.0)
	rot(P_MOUNT, Vector3(0, 0, 3.2 * DEG * sin(t * TAU * 8.5) * env))
	pos(P_ROOT, Vector3(0, -0.025 * env, 0))
	var sweep := _k3(t, 0.7, 0.95, 1.55, 1.9, 1.0, 1.0)
	rot(P_MOUNT_HEAD, Vector3(10.0 * DEG * sweep, 20.0 * DEG * sin((t - 0.7) * TAU * 1.1) * sweep, 0))
	xrot(X_TAIL, Vector3(10.0 * DEG * env, 26.0 * DEG * sin(t * TAU * 5.0) * env, 0))
	if _fidget_prev < 1.6 and t >= 1.6:
		_flare = maxf(_flare, 0.6)
		_on_mount_event(&"fidget_snort")
	return 1.9


## Death: the body frosts over as it goes down (Ice idiom; the mount stays lying there, no shatter).
func _mount_process(_dt: float) -> void:
	if _face:
		_face.auto_any(self)
	if not _dead:
		return
	var v: float = snappedf(0.28 * smoothstep(0.15, 0.85, _death_t), 0.02)
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
